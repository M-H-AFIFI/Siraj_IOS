import AVFoundation
import Foundation
import MediaPlayer
import Observation
import SirajCore
import UIKit

private final class RadioRedirectResolver: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    private var resolvedURL: URL?

    func resolve(_ url: URL) async -> URL {
        // RadioJar endpoints redirect to an http:// edge stream, which iOS ATS blocks unless upgraded.
        guard url.host?.contains("radiojar.com") == true else { return url }
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 6
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        _ = try? await session.data(for: request)
        guard let redirected = resolvedURL else { return url }
        if redirected.scheme == "http",
           var comps = URLComponents(url: redirected, resolvingAgainstBaseURL: false) {
            comps.scheme = "https"
            return comps.url ?? redirected
        }
        return redirected
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        resolvedURL = request.url
        completionHandler(nil)
    }
}

private final class RadioMetadataDelegate: NSObject, AVPlayerItemMetadataOutputPushDelegate {
    var onTitle: (@Sendable (String?) -> Void)?

    func metadataOutput(
        _ output: AVPlayerItemMetadataOutput,
        didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup],
        from track: AVPlayerItemTrack?
    ) {
        for group in groups {
            for item in group.items {
                if item.commonKey == .commonKeyTitle || item.key as? String == "StreamTitle" {
                    Task {
                        if let raw = try? await item.load(.stringValue) {
                            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                            self.onTitle?(trimmed.isEmpty ? nil : trimmed)
                        }
                    }
                    return
                }
            }
        }
    }
}

@MainActor
@Observable
final class QuranRadioStore {
    private let userStore: UserDataStore
    private let metadataDelegate = RadioMetadataDelegate()

    var activeStation: QuranRadioStation?
    var lastStationId: String?
    var pinnedStationIds: [String] = []
    var isPlaying = false
    var isBuffering = false
    var isReconnecting = false
    var hasError = false
    var nowPlaying: String?
    var sleepEndDate: Date?

    var onWillStartPlaying: (() -> Void)?

    private var player: AVPlayer?
    private var metadataOutput: AVPlayerItemMetadataOutput?
    private var statusObservation: NSKeyValueObservation?
    private var timeControlObservation: NSKeyValueObservation?
    private var failObserver: NSObjectProtocol?
    private var stallObserver: NSObjectProtocol?
    private var loadTask: Task<Void, Never>?
    private var sleepTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var reconnectAttempts = 0

    init(userStore: UserDataStore) {
        self.userStore = userStore
        let prefs = userStore.loadRadioPrefs()
        self.lastStationId = prefs.lastStationId
        self.pinnedStationIds = prefs.pinnedStationIds
        metadataDelegate.onTitle = { [weak self] title in
            Task { @MainActor [weak self] in
                guard let self, self.activeStation != nil else { return }
                self.nowPlaying = title
                self.updateNowPlayingInfo()
            }
        }
    }

    var lastStation: QuranRadioStation? {
        QuranRadioStation.byId(lastStationId)
    }

    var hasMiniPlayer: Bool {
        activeStation != nil
    }

    var hasSleepTimer: Bool {
        sleepEndDate != nil
    }

    var upNextStation: QuranRadioStation? {
        guard let active = activeStation else { return nil }
        let list = orderedStations
        guard let idx = list.firstIndex(where: { $0.id == active.id }), list.count > 1 else { return nil }
        return list[(idx + 1) % list.count]
    }

    var orderedStations: [QuranRadioStation] {
        let pinnedSet = Set(pinnedStationIds)
        let pinned = pinnedStationIds.compactMap { QuranRadioStation.byId($0) }
        let rest = QuranRadioStation.stations.filter { !pinnedSet.contains($0.id) }
        return pinned + rest
    }

    func isPinned(_ stationId: String) -> Bool {
        pinnedStationIds.contains(stationId)
    }

    func togglePin(_ stationId: String) {
        if let idx = pinnedStationIds.firstIndex(of: stationId) {
            pinnedStationIds.remove(at: idx)
        } else {
            pinnedStationIds.append(stationId)
        }
        persistPrefs()
    }

    func togglePlayPause(_ station: QuranRadioStation) {
        if activeStation?.id == station.id {
            if isPlaying || isBuffering || isReconnecting {
                pause()
            } else {
                playStation(station)
            }
        } else {
            playStation(station)
        }
    }

    func toggleActivePlayPause() {
        guard let station = activeStation ?? lastStation else { return }
        togglePlayPause(station)
    }

    func playStation(_ station: QuranRadioStation) {
        onWillStartPlaying?()
        reconnectTask?.cancel()
        loadTask?.cancel()
        reconnectAttempts = 0

        activeStation = station
        lastStationId = station.id
        persistPrefs()

        hasError = false
        isReconnecting = false
        isBuffering = true
        isPlaying = false
        nowPlaying = nil
        updateNowPlayingInfo()

        startStream(for: station)
    }

    func retryActive() {
        guard let station = activeStation else { return }
        playStation(station)
    }

    func skip(delta: Int) {
        let list = orderedStations
        guard !list.isEmpty else { return }
        let currentIndex = activeStation.flatMap { cur in list.firstIndex(where: { $0.id == cur.id }) } ?? 0
        let nextIndex = ((currentIndex + delta) % list.count + list.count) % list.count
        playStation(list[nextIndex])
    }

    func pause() {
        reconnectTask?.cancel()
        loadTask?.cancel()
        player?.pause()
        isPlaying = false
        isBuffering = false
        isReconnecting = false
        updateNowPlayingInfo()
    }

    func pauseForOtherAudio() {
        guard isPlaying || isBuffering || isReconnecting else { return }
        pause()
    }

    func stop() {
        cancelSleepTimer()
        reconnectTask?.cancel()
        loadTask?.cancel()
        teardownPlayer()
        activeStation = nil
        isPlaying = false
        isBuffering = false
        isReconnecting = false
        hasError = false
        nowPlaying = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    func setSleepTimer(minutes: Int) {
        let end = Date().addingTimeInterval(TimeInterval(minutes * 60))
        sleepEndDate = end
        sleepTask?.cancel()
        sleepTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(minutes * 60))
            guard let self, !Task.isCancelled else { return }
            self.sleepEndDate = nil
            self.pause()
        }
    }

    func cancelSleepTimer() {
        sleepTask?.cancel()
        sleepTask = nil
        sleepEndDate = nil
    }

    func sleepRemainingMinutes(at now: Date = Date()) -> Int? {
        guard let end = sleepEndDate else { return nil }
        let remaining = end.timeIntervalSince(now)
        if remaining <= 0 { return nil }
        return max(1, Int(ceil(remaining / 60.0)))
    }

    // MARK: - AVPlayer Streaming

    private func startStream(for station: QuranRadioStation) {
        guard let baseURL = URL(string: station.streamUrl) else {
            markStreamFailed()
            return
        }

        loadTask = Task { [weak self] in
            let resolver = RadioRedirectResolver()
            let finalURL = await resolver.resolve(baseURL)
            guard let self, !Task.isCancelled, self.activeStation?.id == station.id else { return }
            self.attachAndPlay(url: finalURL, station: station)
        }
    }

    private func attachAndPlay(url: URL, station: QuranRadioStation) {
        teardownPlayer()
        configureAudioSession()

        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        item.preferredForwardBufferDuration = 6

        let output = AVPlayerItemMetadataOutput(identifiers: nil)
        output.setDelegate(metadataDelegate, queue: .main)
        item.add(output)
        self.metadataOutput = output

        let av = AVPlayer(playerItem: item)
        av.automaticallyWaitsToMinimizeStalling = true
        self.player = av

        statusObservation = item.observe(\.status, options: [.new]) { [weak self] observed, _ in
            let status = observed.status
            Task { @MainActor [weak self] in
                guard let self, self.activeStation?.id == station.id else { return }
                if status == .failed {
                    self.handleStreamInterruption(for: station)
                }
            }
        }

        timeControlObservation = av.observe(\.timeControlStatus, options: [.new]) { [weak self] observed, _ in
            let state = observed.timeControlStatus
            Task { @MainActor [weak self] in
                guard let self, self.activeStation?.id == station.id else { return }
                switch state {
                case .playing:
                    self.reconnectAttempts = 0
                    self.isPlaying = true
                    self.isBuffering = false
                    self.isReconnecting = false
                    self.hasError = false
                    self.updateNowPlayingInfo()
                case .waitingToPlayAtSpecifiedRate:
                    if !self.hasError {
                        self.isBuffering = true
                    }
                case .paused:
                    self.isPlaying = false
                    self.updateNowPlayingInfo()
                @unknown default:
                    break
                }
            }
        }

        failObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleStreamInterruption(for: station)
            }
        }

        stallObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemPlaybackStalled,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleStreamInterruption(for: station)
            }
        }

        av.play()
    }

    private func handleStreamInterruption(for station: QuranRadioStation) {
        guard activeStation?.id == station.id else { return }
        if reconnectAttempts < 2 {
            reconnectAttempts += 1
            isPlaying = false
            isBuffering = false
            isReconnecting = true
            hasError = false
            reconnectTask?.cancel()
            reconnectTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(2))
                guard let self, !Task.isCancelled, self.activeStation?.id == station.id else { return }
                self.startStream(for: station)
            }
        } else {
            markStreamFailed()
        }
    }

    private func markStreamFailed() {
        teardownPlayer()
        isPlaying = false
        isBuffering = false
        isReconnecting = false
        hasError = true
        updateNowPlayingInfo()
    }

    private func teardownPlayer() {
        statusObservation?.invalidate()
        statusObservation = nil
        timeControlObservation?.invalidate()
        timeControlObservation = nil
        if let obs = failObserver {
            NotificationCenter.default.removeObserver(obs)
            failObserver = nil
        }
        if let obs = stallObserver {
            NotificationCenter.default.removeObserver(obs)
            stallObserver = nil
        }
        if let output = metadataOutput {
            player?.currentItem?.remove(output)
            metadataOutput = nil
        }
        player?.pause()
        player = nil
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [])
        try? session.setActive(true)
    }

    private func persistPrefs() {
        userStore.saveRadioPrefs(QuranRadioPrefs(lastStationId: lastStationId, pinnedStationIds: pinnedStationIds))
    }

    private func updateNowPlayingInfo() {
        guard let station = activeStation else { return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: station.nameEn,
            MPMediaItemPropertyArtist: nowPlaying ?? station.locationEn,
            MPNowPlayingInfoPropertyIsLiveStream: true,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        if let uiImage = UIImage(named: station.artworkAsset) {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: uiImage.size) { _ in uiImage }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
