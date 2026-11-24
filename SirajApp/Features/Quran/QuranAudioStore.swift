import AVFoundation
import Foundation
import MediaPlayer
import Observation
import SirajCore
import UIKit

enum PlaybackScope: String, CaseIterable, Identifiable {
    case singleAyah
    case page
    case surah
    case continuous

    var id: String { rawValue }
}

enum ListeningRepeat: String, CaseIterable {
    case off
    case all
    case one
}

enum AmbientFetchState: Equatable {
    case absent
    case downloading
    case ready
    case failed
}

@MainActor
@Observable
final class QuranAudioStore {
    let audioRoot: URL
    private let surahsDir: URL
    private let rareDir: URL
    private let ambientDir: URL
    private let userStore: UserDataStore

    // MARK: - Reader Ayah/Surah Playback
    var readerActive = false
    var readerIsPlaying = false
    var readerReciterId = Reciter.defaultReciter.id
    var readerSurah = 1
    var readerAyah = 1
    var readerSurahName = ""
    var readerSurahAyahCount = 7
    var readerPageLastAyah: Int?
    var readerPositionSec: Double = 0
    var readerDurationSec: Double = 0
    var readerScope: PlaybackScope = .continuous
    var readerSpeed: Float = 1.0
    var readerRepeatTarget: Int = 1 // 0 = infinite
    var readerRepeatDone: Int = 0
    var readerIsOfflineSource = false
    var onReaderAyahChanged: ((Int, Int) -> Void)?

    // MARK: - Listening Library Playback
    var listeningQueue: [ListeningTrack] = []
    var listeningIndex: Int = -1
    var listeningIsPlaying = false
    var listeningIsBuffering = false
    var listeningPositionSec: Double = 0
    var listeningDurationSec: Double = 0
    var listeningIsLocal = false
    var listeningHasError = false
    var listeningRepeat: ListeningRepeat = .off
    var listeningShuffle = false
    var listeningSpeed: Float = 1.0
    var sleepEndDate: Date?
    var sleepAtEndOfTrack = false
    var lastSession: ListeningSession?

    // MARK: - Downloads
    var downloadedSurahs: [String: Set<Int>] = [:]
    var downloadedRare: [String: Set<String>] = [:]
    var activeDownloads: [String: Double] = [:]
    var failedDownloads: Set<String> = []
    var batchDownloadingSourceId: String?

    // MARK: - Ambient Mixer
    var activeAmbient: AmbientSound?
    var ambientVolume: Float = 0.35
    var ambientStates: [AmbientSound: AmbientFetchState] = [:]

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var failObserver: NSObjectProtocol?
    private var sleepTask: Task<Void, Never>?
    private var downloadTasks: [String: Task<Void, Never>] = [:]
    private var batchTask: Task<Void, Never>?
    private var ambientPlayer: AVAudioPlayer?
    private var ambientDownloadTasks: [AmbientSound: Task<Void, Never>] = [:]
    private var triedFallbackForTrackId: Set<String> = []
    private var activeModeIsListening = false

    init(userStore: UserDataStore) {
        self.userStore = userStore
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fm.temporaryDirectory
        let root = appSupport.appendingPathComponent("SirajAudio", isDirectory: true)
        self.audioRoot = root
        self.surahsDir = root.appendingPathComponent("surahs", isDirectory: true)
        self.rareDir = root.appendingPathComponent("rare", isDirectory: true)
        self.ambientDir = root.appendingPathComponent("ambient", isDirectory: true)
        try? fm.createDirectory(at: surahsDir, withIntermediateDirectories: true)
        try? fm.createDirectory(at: rareDir, withIntermediateDirectories: true)
        try? fm.createDirectory(at: ambientDir, withIntermediateDirectories: true)

        self.lastSession = userStore.loadListeningSession()
        scanOfflineFiles()
        scanAmbientFiles()
        configureRemoteCommands()
    }

    var currentListeningTrack: ListeningTrack? {
        guard listeningIndex >= 0 && listeningIndex < listeningQueue.count else { return nil }
        return listeningQueue[listeningIndex]
    }

    var hasActiveListening: Bool {
        currentListeningTrack != nil
    }

    var hasAnyMiniPlayer: Bool {
        readerActive || hasActiveListening
    }

    var hasSleepTimer: Bool {
        sleepEndDate != nil || sleepAtEndOfTrack
    }

    var isAnyPlaying: Bool {
        readerIsPlaying || listeningIsPlaying
    }

    var readerProgress: Double {
        guard readerDurationSec > 0 else { return 0 }
        return min(1, max(0, readerPositionSec / readerDurationSec))
    }

    var listeningProgress: Double {
        guard listeningDurationSec > 0 else { return 0 }
        return min(1, max(0, listeningPositionSec / listeningDurationSec))
    }

    var upcomingListeningTrack: ListeningTrack? {
        guard !listeningQueue.isEmpty, listeningIndex >= 0 else { return nil }
        if listeningIndex + 1 < listeningQueue.count {
            return listeningQueue[listeningIndex + 1]
        }
        if listeningRepeat == .all {
            return listeningQueue.first
        }
        return nil
    }

    // MARK: - Reader Playback

    func playReaderAyah(
        surah: Int,
        ayah: Int,
        reciterId: String,
        surahName: String,
        surahAyahCount: Int,
        pageLastAyah: Int? = nil
    ) {
        stopListeningInternal(clearQueue: false)
        activeModeIsListening = false
        readerActive = true
        readerReciterId = reciterId
        readerSurah = surah
        readerAyah = max(1, min(surahAyahCount, ayah))
        readerSurahName = surahName
        readerSurahAyahCount = max(1, surahAyahCount)
        readerPageLastAyah = pageLastAyah
        readerRepeatDone = 0

        let localSurah = localSurahURL(reciterId: reciterId, surah: surah)
        let url: URL?
        if FileManager.default.fileExists(atPath: localSurah.path) && !ReciterAudioURLs.hasAyahAudio(reciterId) {
            url = localSurah
            readerIsOfflineSource = true
        } else if ReciterAudioURLs.hasAyahAudio(reciterId) {
            url = URL(string: ReciterAudioURLs.ayahAudioURL(reciterId: reciterId, surah: surah, ayah: readerAyah))
            readerIsOfflineSource = false
        } else if FileManager.default.fileExists(atPath: localSurah.path) {
            url = localSurah
            readerIsOfflineSource = true
        } else {
            url = URL(string: ReciterAudioURLs.surahAudioURL(reciterId: reciterId, surah: surah))
            readerIsOfflineSource = false
        }

        guard let url else { return }
        startAVPlayer(url: url, rate: readerSpeed)
        readerIsPlaying = true
        onReaderAyahChanged?(readerSurah, readerAyah)
        updateNowPlaying()
        syncAmbientPlayback()
    }

    func toggleReaderPlayPause() {
        guard readerActive else { return }
        if readerIsPlaying {
            player?.pause()
            readerIsPlaying = false
        } else {
            configureAudioSession()
            player?.playImmediately(atRate: readerSpeed)
            readerIsPlaying = true
        }
        updateNowPlaying()
        syncAmbientPlayback()
    }

    func nextReaderAyah() {
        guard readerActive else { return }
        if readerAyah < readerSurahAyahCount {
            playReaderAyah(
                surah: readerSurah,
                ayah: readerAyah + 1,
                reciterId: readerReciterId,
                surahName: readerSurahName,
                surahAyahCount: readerSurahAyahCount,
                pageLastAyah: readerPageLastAyah
            )
        } else if readerSurah < 114 {
            let nextS = readerSurah + 1
            let nextCount = Surah.ayahCount(for: nextS)
            playReaderAyah(
                surah: nextS,
                ayah: 1,
                reciterId: readerReciterId,
                surahName: "",
                surahAyahCount: nextCount,
                pageLastAyah: nil
            )
        }
    }

    func previousReaderAyah() {
        guard readerActive else { return }
        if readerPositionSec > 3.5 {
            seekReader(toSeconds: 0)
            return
        }
        if readerAyah > 1 {
            playReaderAyah(
                surah: readerSurah,
                ayah: readerAyah - 1,
                reciterId: readerReciterId,
                surahName: readerSurahName,
                surahAyahCount: readerSurahAyahCount,
                pageLastAyah: readerPageLastAyah
            )
        } else if readerSurah > 1 {
            let prevS = readerSurah - 1
            let prevCount = Surah.ayahCount(for: prevS)
            playReaderAyah(
                surah: prevS,
                ayah: prevCount,
                reciterId: readerReciterId,
                surahName: "",
                surahAyahCount: prevCount,
                pageLastAyah: nil
            )
        }
    }

    func seekReader(toSeconds seconds: Double) {
        let target = max(0, min(readerDurationSec > 0 ? readerDurationSec : seconds, seconds))
        player?.seek(to: CMTime(seconds: target, preferredTimescale: 600))
        readerPositionSec = target
        updateNowPlaying()
    }

    func seekReader(deltaSeconds: Double) {
        seekReader(toSeconds: readerPositionSec + deltaSeconds)
    }

    func setReaderSpeed(_ speed: Float) {
        readerSpeed = speed
        if readerIsPlaying {
            player?.rate = speed
        }
        updateNowPlaying()
    }

    func stopReader() {
        if !activeModeIsListening {
            teardownAVPlayer()
        }
        readerActive = false
        readerIsPlaying = false
        readerPositionSec = 0
        readerDurationSec = 0
        syncAmbientPlayback()
        updateNowPlaying()
    }

    // MARK: - Listening Library Playback

    func playReciter(
        _ reciterId: String,
        surahNumber: Int = 1,
        shuffle: Bool = false,
        surahs: [Surah],
        language: String
    ) {
        let queue = ListenTitles.reciterQueue(reciterId: reciterId, surahs: surahs, language: language)
        guard !queue.isEmpty else { return }
        let idx: Int
        if shuffle {
            idx = Int.random(in: 0..<queue.count)
        } else {
            idx = queue.firstIndex(where: { $0.surahNumber == surahNumber }) ?? 0
        }
        listeningShuffle = shuffle
        startListeningQueue(queue, startIndex: idx, seekMs: 0)
    }

    func playRare(
        _ collectionId: String,
        trackIndex: Int = 0,
        shuffle: Bool = false,
        surahs: [Surah],
        language: String
    ) {
        guard let col = ListeningCatalog.rare(id: collectionId) else { return }
        let queue = ListenTitles.rareQueue(collection: col, surahs: surahs, language: language)
        guard !queue.isEmpty else { return }
        let idx = shuffle ? Int.random(in: 0..<queue.count) : max(0, min(queue.count - 1, trackIndex))
        listeningShuffle = shuffle
        startListeningQueue(queue, startIndex: idx, seekMs: 0)
    }

    func resumeLastSession(surahs: [Surah], language: String) {
        guard let session = lastSession else { return }
        let queue: [ListeningTrack]
        switch session.kind {
        case .surah:
            queue = ListenTitles.reciterQueue(reciterId: session.sourceId, surahs: surahs, language: language)
        case .rare:
            guard let col = ListeningCatalog.rare(id: session.sourceId) else { return }
            queue = ListenTitles.rareQueue(collection: col, surahs: surahs, language: language)
        }
        let idx = queue.firstIndex(where: { $0.id == session.trackId }) ?? 0
        startListeningQueue(queue, startIndex: idx, seekMs: session.positionMs)
    }

    private func startListeningQueue(_ queue: [ListeningTrack], startIndex: Int, seekMs: Int64) {
        stopReader()
        activeModeIsListening = true
        listeningQueue = queue
        listeningIndex = max(0, min(queue.count - 1, startIndex))
        triedFallbackForTrackId.removeAll()
        loadCurrentListeningTrack(seekMs: seekMs)
    }

    private func loadCurrentListeningTrack(seekMs: Int64 = 0) {
        guard let track = currentListeningTrack else { return }
        listeningHasError = false
        listeningIsBuffering = true
        listeningPositionSec = Double(seekMs) / 1000.0
        listeningDurationSec = 0

        let localURL = localFileURL(for: track)
        let targetURL: URL?
        if let localURL, FileManager.default.fileExists(atPath: localURL.path) {
            targetURL = localURL
            listeningIsLocal = true
        } else {
            targetURL = URL(string: track.streamUrl)
            listeningIsLocal = false
        }

        guard let targetURL else {
            listeningHasError = true
            listeningIsBuffering = false
            return
        }

        startAVPlayer(url: targetURL, rate: listeningSpeed, initialSeekSec: seekMs > 0 ? Double(seekMs) / 1000.0 : 0)
        listeningIsPlaying = true
        persistListeningSession()
        updateNowPlaying()
        syncAmbientPlayback()
    }

    func toggleListeningPlayPause() {
        guard currentListeningTrack != nil else { return }
        if listeningHasError {
            loadCurrentListeningTrack(seekMs: Int64(listeningPositionSec * 1000))
            return
        }
        if listeningIsPlaying {
            player?.pause()
            listeningIsPlaying = false
            persistListeningSession()
        } else {
            configureAudioSession()
            player?.playImmediately(atRate: listeningSpeed)
            listeningIsPlaying = true
        }
        updateNowPlaying()
        syncAmbientPlayback()
    }

    func nextListeningTrack() {
        guard !listeningQueue.isEmpty else { return }
        if listeningShuffle && listeningQueue.count > 1 {
            var next = listeningIndex
            while next == listeningIndex {
                next = Int.random(in: 0..<listeningQueue.count)
            }
            listeningIndex = next
            loadCurrentListeningTrack()
        } else if listeningIndex + 1 < listeningQueue.count {
            listeningIndex += 1
            loadCurrentListeningTrack()
        } else if listeningRepeat == .all {
            listeningIndex = 0
            loadCurrentListeningTrack()
        }
    }

    func previousListeningTrack() {
        guard !listeningQueue.isEmpty else { return }
        if listeningPositionSec > 4.0 || listeningIndex <= 0 {
            seekListening(toSeconds: 0)
        } else {
            listeningIndex -= 1
            loadCurrentListeningTrack()
        }
    }

    func seekListening(toSeconds seconds: Double) {
        let clamped = max(0, min(listeningDurationSec > 0 ? listeningDurationSec : seconds, seconds))
        player?.seek(to: CMTime(seconds: clamped, preferredTimescale: 600))
        listeningPositionSec = clamped
        persistListeningSession()
        updateNowPlaying()
    }

    func seekListening(deltaSeconds: Double) {
        seekListening(toSeconds: listeningPositionSec + deltaSeconds)
    }

    func setListeningSpeed(_ speed: Float) {
        listeningSpeed = speed
        if listeningIsPlaying {
            player?.rate = speed
        }
        updateNowPlaying()
    }

    func cycleListeningRepeat() {
        switch listeningRepeat {
        case .off: listeningRepeat = .all
        case .all: listeningRepeat = .one
        case .one: listeningRepeat = .off
        }
    }

    func toggleListeningShuffle() {
        listeningShuffle.toggle()
    }

    func setSleepTimer(minutes: Int) {
        sleepAtEndOfTrack = false
        let end = Date().addingTimeInterval(TimeInterval(minutes * 60))
        sleepEndDate = end
        sleepTask?.cancel()
        sleepTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(minutes * 60))
            guard let self, !Task.isCancelled else { return }
            self.pauseForSleepTimer()
        }
    }

    func setSleepAtEndOfTrack() {
        sleepTask?.cancel()
        sleepEndDate = nil
        sleepAtEndOfTrack = true
    }

    func cancelSleepTimer() {
        sleepTask?.cancel()
        sleepEndDate = nil
        sleepAtEndOfTrack = false
    }

    func stopListening() {
        stopListeningInternal(clearQueue: true)
    }

    private func stopListeningInternal(clearQueue: Bool) {
        cancelSleepTimer()
        if activeModeIsListening {
            persistListeningSession()
            teardownAVPlayer()
        }
        listeningIsPlaying = false
        listeningIsBuffering = false
        if clearQueue {
            listeningQueue = []
            listeningIndex = -1
            listeningPositionSec = 0
            listeningDurationSec = 0
        }
        syncAmbientPlayback()
        updateNowPlaying()
    }

    func pauseForAdhan() {
        if readerIsPlaying {
            player?.pause()
            readerIsPlaying = false
        }
        if listeningIsPlaying {
            player?.pause()
            listeningIsPlaying = false
        }
        syncAmbientPlayback()
        updateNowPlaying()
    }

    private func pauseForSleepTimer() {
        sleepEndDate = nil
        sleepAtEndOfTrack = false
        if listeningIsPlaying {
            player?.pause()
            listeningIsPlaying = false
            persistListeningSession()
        }
        if readerIsPlaying {
            player?.pause()
            readerIsPlaying = false
        }
        syncAmbientPlayback()
        updateNowPlaying()
    }

    // MARK: - AVPlayer Plumbing

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [])
        try? session.setActive(true)
    }

    private func teardownAVPlayer() {
        if let obs = timeObserver {
            player?.removeTimeObserver(obs)
            timeObserver = nil
        }
        if let endObs = endObserver {
            NotificationCenter.default.removeObserver(endObs)
            endObserver = nil
        }
        if let failObs = failObserver {
            NotificationCenter.default.removeObserver(failObs)
            failObserver = nil
        }
        player?.pause()
        player = nil
    }

    private func startAVPlayer(url: URL, rate: Float, initialSeekSec: Double = 0) {
        teardownAVPlayer()
        configureAudioSession()

        let item = AVPlayerItem(url: url)
        let av = AVPlayer(playerItem: item)
        self.player = av

        if initialSeekSec > 0 {
            av.seek(to: CMTime(seconds: initialSeekSec, preferredTimescale: 600))
        }

        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserver = av.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            let sec = time.seconds.isFinite ? max(0, time.seconds) : 0
            Task { @MainActor [weak self] in
                guard let self, let activePlayer = self.player else { return }
                let durRaw = activePlayer.currentItem?.duration.seconds ?? 0
                let dur = (durRaw.isFinite && durRaw > 0) ? durRaw : 0
                if self.activeModeIsListening {
                    self.listeningPositionSec = sec
                    if dur > 0 { self.listeningDurationSec = dur }
                    if activePlayer.timeControlStatus == .playing {
                        self.listeningIsBuffering = false
                    }
                } else {
                    self.readerPositionSec = sec
                    if dur > 0 { self.readerDurationSec = dur }
                }
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleItemEnded()
            }
        }

        failObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleItemFailed()
            }
        }

        av.playImmediately(atRate: rate)
    }

    private func handleItemEnded() {
        if activeModeIsListening {
            if sleepAtEndOfTrack {
                pauseForSleepTimer()
                return
            }
            if listeningRepeat == .one {
                seekListening(toSeconds: 0)
                player?.playImmediately(atRate: listeningSpeed)
                listeningIsPlaying = true
                return
            }
            if listeningShuffle || listeningIndex + 1 < listeningQueue.count || listeningRepeat == .all {
                nextListeningTrack()
            } else {
                listeningIsPlaying = false
                listeningPositionSec = 0
                syncAmbientPlayback()
                updateNowPlaying()
            }
        } else {
            // Reader Ayah-by-Ayah scope & repeat handling
            if !ReciterAudioURLs.hasAyahAudio(readerReciterId) {
                readerIsPlaying = false
                syncAmbientPlayback()
                return
            }
            readerRepeatDone += 1
            if readerRepeatTarget == 0 || readerRepeatDone < readerRepeatTarget {
                seekReader(toSeconds: 0)
                player?.playImmediately(atRate: readerSpeed)
                readerIsPlaying = true
                return
            }
            readerRepeatDone = 0
            switch readerScope {
            case .singleAyah:
                readerIsPlaying = false
                syncAmbientPlayback()
            case .page:
                if let lastOnPage = readerPageLastAyah, readerAyah >= lastOnPage {
                    readerIsPlaying = false
                    syncAmbientPlayback()
                } else if readerAyah < readerSurahAyahCount {
                    nextReaderAyah()
                } else {
                    readerIsPlaying = false
                    syncAmbientPlayback()
                }
            case .surah:
                if readerAyah < readerSurahAyahCount {
                    nextReaderAyah()
                } else {
                    readerIsPlaying = false
                    syncAmbientPlayback()
                }
            case .continuous:
                if readerAyah < readerSurahAyahCount || readerSurah < 114 {
                    nextReaderAyah()
                } else {
                    readerIsPlaying = false
                    syncAmbientPlayback()
                }
            }
        }
    }

    private func handleItemFailed() {
        if activeModeIsListening, let track = currentListeningTrack {
            if let mirror = track.fallbackUrl,
               mirror != track.streamUrl,
               !triedFallbackForTrackId.contains(track.id),
               let mirrorURL = URL(string: mirror) {
                triedFallbackForTrackId.insert(track.id)
                startAVPlayer(url: mirrorURL, rate: listeningSpeed, initialSeekSec: listeningPositionSec)
                return
            }
            listeningHasError = true
            listeningIsPlaying = false
            listeningIsBuffering = false
        } else {
            readerIsPlaying = false
        }
        syncAmbientPlayback()
        updateNowPlaying()
    }

    private func persistListeningSession() {
        guard let track = currentListeningTrack else { return }
        let session = ListeningSession(
            kind: track.kind,
            sourceId: track.sourceId,
            trackId: track.id,
            title: track.title,
            artist: track.artist,
            positionMs: Int64(max(0, listeningPositionSec) * 1000),
            durationMs: Int64(max(0, listeningDurationSec) * 1000)
        )
        lastSession = session
        userStore.saveListeningSession(session)
    }

    // MARK: - Lock Screen / Control Center

    private func configureRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.activeModeIsListening {
                    if !self.listeningIsPlaying { self.toggleListeningPlayPause() }
                } else if self.readerActive {
                    if !self.readerIsPlaying { self.toggleReaderPlayPause() }
                }
            }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.activeModeIsListening {
                    if self.listeningIsPlaying { self.toggleListeningPlayPause() }
                } else if self.readerActive {
                    if self.readerIsPlaying { self.toggleReaderPlayPause() }
                }
            }
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.activeModeIsListening {
                    self.toggleListeningPlayPause()
                } else if self.readerActive {
                    self.toggleReaderPlayPause()
                }
            }
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.activeModeIsListening {
                    self.nextListeningTrack()
                } else if self.readerActive {
                    self.nextReaderAyah()
                }
            }
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.activeModeIsListening {
                    self.previousListeningTrack()
                } else if self.readerActive {
                    self.previousReaderAyah()
                }
            }
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let posEvent = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.activeModeIsListening {
                    self.seekListening(toSeconds: posEvent.positionTime)
                } else if self.readerActive {
                    self.seekReader(toSeconds: posEvent.positionTime)
                }
            }
            return .success
        }
    }

    private func updateNowPlaying() {
        var info: [String: Any] = [:]
        if activeModeIsListening, let track = currentListeningTrack {
            info[MPMediaItemPropertyTitle] = track.title
            info[MPMediaItemPropertyArtist] = track.artist
            info[MPMediaItemPropertyPlaybackDuration] = listeningDurationSec
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = listeningPositionSec
            info[MPNowPlayingInfoPropertyPlaybackRate] = listeningIsPlaying ? Double(listeningSpeed) : 0.0
            if let asset = track.artworkAsset, let img = UIImage(named: asset) {
                info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: img.size) { _ in img }
            }
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        } else if readerActive {
            let reciter = Reciter.byId(readerReciterId)
            info[MPMediaItemPropertyTitle] = readerSurahName.isEmpty ? "Surah \(readerSurah)" : readerSurahName
            info[MPMediaItemPropertyArtist] = reciter.englishName
            info[MPMediaItemPropertyPlaybackDuration] = readerDurationSec
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = readerPositionSec
            info[MPNowPlayingInfoPropertyPlaybackRate] = readerIsPlaying ? Double(readerSpeed) : 0.0
            if let asset = reciter.photoAssetName, let img = UIImage(named: asset) {
                info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: img.size) { _ in img }
            }
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        } else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        }
    }

    // MARK: - Ambient Sound Mixer

    func chooseAmbient(_ sound: AmbientSound?) {
        if activeAmbient == sound {
            activeAmbient = nil
            ambientPlayer?.stop()
            ambientPlayer = nil
            return
        }
        activeAmbient = sound
        guard let sound else {
            ambientPlayer?.stop()
            ambientPlayer = nil
            return
        }
        let fileURL = ambientDir.appendingPathComponent(sound.fileName)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            ambientStates[sound] = .ready
            prepareAndSyncAmbient(sound: sound, url: fileURL)
        } else {
            downloadAmbient(sound)
        }
    }

    func downloadAmbient(_ sound: AmbientSound) {
        ambientDownloadTasks[sound]?.cancel()
        ambientStates[sound] = .downloading
        ambientDownloadTasks[sound] = Task { [weak self] in
            guard let self else { return }
            let dest = self.ambientDir.appendingPathComponent(sound.fileName)
            let ok = await self.downloadFile(urls: [sound.cdnURL, sound.rawURL], to: dest, expectedMinBytes: 50_000, key: nil)
            guard !Task.isCancelled else { return }
            if ok {
                self.ambientStates[sound] = .ready
                if self.activeAmbient == sound {
                    self.prepareAndSyncAmbient(sound: sound, url: dest)
                }
            } else {
                self.ambientStates[sound] = .failed
            }
        }
    }

    func setAmbientVolume(_ value: Float) {
        ambientVolume = min(1, max(0, value))
        ambientPlayer?.volume = ambientVolume * 0.45
    }

    private func prepareAndSyncAmbient(sound: AmbientSound, url: URL) {
        do {
            let ap = try AVAudioPlayer(contentsOf: url)
            ap.numberOfLoops = -1
            ap.volume = ambientVolume * 0.45
            ap.prepareToPlay()
            ambientPlayer = ap
            syncAmbientPlayback()
        } catch {
            ambientStates[sound] = .failed
        }
    }

    private func syncAmbientPlayback() {
        guard let ap = ambientPlayer else { return }
        if activeAmbient != nil && isAnyPlaying {
            if !ap.isPlaying { ap.play() }
        } else {
            if ap.isPlaying { ap.pause() }
        }
    }

    private func scanAmbientFiles() {
        let fm = FileManager.default
        for s in AmbientSound.allCases {
            let path = ambientDir.appendingPathComponent(s.fileName).path
            ambientStates[s] = fm.fileExists(atPath: path) ? .ready : .absent
        }
    }

    // MARK: - Offline Downloads

    func localSurahURL(reciterId: String, surah: Int) -> URL {
        let dir = surahsDir.appendingPathComponent(reciterId, isDirectory: true)
        return dir.appendingPathComponent(String(format: "%03d.mp3", surah))
    }

    func localRareURL(fileName: String) -> URL {
        rareDir.appendingPathComponent(fileName)
    }

    func localFileURL(for track: ListeningTrack) -> URL? {
        switch track.kind {
        case .surah:
            return localSurahURL(reciterId: track.sourceId, surah: track.surahNumber)
        case .rare:
            guard let fn = track.fileName else { return nil }
            return localRareURL(fileName: fn)
        }
    }

    func isSurahDownloaded(reciterId: String, surah: Int) -> Bool {
        downloadedSurahs[reciterId]?.contains(surah) ?? false
    }

    func isRareDownloaded(collectionId: String, fileName: String) -> Bool {
        downloadedRare[collectionId]?.contains(fileName) ?? false
    }

    func downloadKey(reciterId: String, surah: Int) -> String {
        "surah/\(reciterId)/\(surah)"
    }

    func downloadKey(rare: RareTrack) -> String {
        rare.id
    }

    func downloadSurah(reciterId: String, surah: Int) {
        let key = downloadKey(reciterId: reciterId, surah: surah)
        guard activeDownloads[key] == nil, !isSurahDownloaded(reciterId: reciterId, surah: surah) else { return }
        failedDownloads.remove(key)
        activeDownloads[key] = 0.02
        let urls = ReciterAudioURLs.listeningSurahURLs(reciterId: reciterId, surah: surah)
        let dest = localSurahURL(reciterId: reciterId, surah: surah)
        downloadTasks[key] = Task { [weak self] in
            guard let self else { return }
            let ok = await self.downloadFile(urls: urls, to: dest, expectedMinBytes: 4096, key: key)
            self.activeDownloads.removeValue(forKey: key)
            self.downloadTasks.removeValue(forKey: key)
            if ok {
                var set = self.downloadedSurahs[reciterId] ?? []
                set.insert(surah)
                self.downloadedSurahs[reciterId] = set
            } else if !Task.isCancelled {
                self.failedDownloads.insert(key)
            }
        }
    }

    func downloadAllSurahs(reciterId: String) {
        stopDownloads()
        batchDownloadingSourceId = reciterId
        batchTask = Task { [weak self] in
            guard let self else { return }
            for s in 1...114 {
                if Task.isCancelled { break }
                if self.isSurahDownloaded(reciterId: reciterId, surah: s) { continue }
                let key = self.downloadKey(reciterId: reciterId, surah: s)
                self.activeDownloads[key] = 0.02
                let urls = ReciterAudioURLs.listeningSurahURLs(reciterId: reciterId, surah: s)
                let dest = self.localSurahURL(reciterId: reciterId, surah: s)
                let ok = await self.downloadFile(urls: urls, to: dest, expectedMinBytes: 4096, key: key)
                self.activeDownloads.removeValue(forKey: key)
                if ok {
                    var set = self.downloadedSurahs[reciterId] ?? []
                    set.insert(s)
                    self.downloadedSurahs[reciterId] = set
                } else if !Task.isCancelled {
                    self.failedDownloads.insert(key)
                }
            }
            if self.batchDownloadingSourceId == reciterId {
                self.batchDownloadingSourceId = nil
            }
        }
    }

    func downloadRareTrack(_ track: RareTrack) {
        let key = downloadKey(rare: track)
        guard activeDownloads[key] == nil, !isRareDownloaded(collectionId: track.collectionId, fileName: track.fileName) else { return }
        failedDownloads.remove(key)
        activeDownloads[key] = 0.02
        let dest = localRareURL(fileName: track.fileName)
        downloadTasks[key] = Task { [weak self] in
            guard let self else { return }
            let ok = await self.downloadFile(urls: [track.url, track.fallbackUrl], to: dest, expectedMinBytes: 4096, key: key)
            self.activeDownloads.removeValue(forKey: key)
            self.downloadTasks.removeValue(forKey: key)
            if ok {
                var set = self.downloadedRare[track.collectionId] ?? []
                set.insert(track.fileName)
                self.downloadedRare[track.collectionId] = set
            } else if !Task.isCancelled {
                self.failedDownloads.insert(key)
            }
        }
    }

    func downloadAllRare(_ collection: RareCollection) {
        stopDownloads()
        batchDownloadingSourceId = collection.id
        batchTask = Task { [weak self] in
            guard let self else { return }
            for track in collection.tracks {
                if Task.isCancelled { break }
                if self.isRareDownloaded(collectionId: collection.id, fileName: track.fileName) { continue }
                let key = self.downloadKey(rare: track)
                self.activeDownloads[key] = 0.02
                let dest = self.localRareURL(fileName: track.fileName)
                let ok = await self.downloadFile(urls: [track.url, track.fallbackUrl], to: dest, expectedMinBytes: 4096, key: key)
                self.activeDownloads.removeValue(forKey: key)
                if ok {
                    var set = self.downloadedRare[collection.id] ?? []
                    set.insert(track.fileName)
                    self.downloadedRare[collection.id] = set
                } else if !Task.isCancelled {
                    self.failedDownloads.insert(key)
                }
            }
            if self.batchDownloadingSourceId == collection.id {
                self.batchDownloadingSourceId = nil
            }
        }
    }

    func stopDownload(key: String) {
        downloadTasks[key]?.cancel()
        downloadTasks.removeValue(forKey: key)
        activeDownloads.removeValue(forKey: key)
    }

    func stopDownloads() {
        batchTask?.cancel()
        batchTask = nil
        batchDownloadingSourceId = nil
        for (_, t) in downloadTasks { t.cancel() }
        downloadTasks.removeAll()
        activeDownloads.removeAll()
    }

    func removeDownloads(forReciter reciterId: String) {
        let dir = surahsDir.appendingPathComponent(reciterId, isDirectory: true)
        try? FileManager.default.removeItem(at: dir)
        downloadedSurahs.removeValue(forKey: reciterId)
    }

    func removeDownloads(forCollection collection: RareCollection) {
        for track in collection.tracks {
            try? FileManager.default.removeItem(at: localRareURL(fileName: track.fileName))
        }
        downloadedRare.removeValue(forKey: collection.id)
    }

    var offlineSurahCounts: [String: Int] {
        downloadedSurahs.mapValues(\.count)
    }

    var offlineRareCounts: [String: Int] {
        downloadedRare.mapValues(\.count)
    }

    private func scanOfflineFiles() {
        let fm = FileManager.default
        var surahMap: [String: Set<Int>] = [:]
        if let reciterDirs = try? fm.contentsOfDirectory(at: surahsDir, includingPropertiesForKeys: nil) {
            for dir in reciterDirs {
                let recId = dir.lastPathComponent
                if let files = try? fm.contentsOfDirectory(atPath: dir.path) {
                    var nums: Set<Int> = []
                    for f in files where f.hasSuffix(".mp3") {
                        if let n = Int(f.dropLast(4)) { nums.insert(n) }
                    }
                    if !nums.isEmpty { surahMap[recId] = nums }
                }
            }
        }
        downloadedSurahs = surahMap

        var rareMap: [String: Set<String>] = [:]
        if let files = try? fm.contentsOfDirectory(atPath: rareDir.path) {
            let fileSet = Set(files)
            for col in ListeningCatalog.rareCollections {
                let present = Set(col.tracks.map(\.fileName).filter { fileSet.contains($0) })
                if !present.isEmpty { rareMap[col.id] = present }
            }
        }
        downloadedRare = rareMap
    }

    private func downloadFile(urls: [String], to destination: URL, expectedMinBytes: Int64, key: String?) async -> Bool {
        let fm = FileManager.default
        try? fm.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)

        for raw in urls {
            guard let url = URL(string: raw) else { continue }
            do {
                let (tempURL, resp) = try await URLSession.shared.download(from: url)
                if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    try? fm.removeItem(at: tempURL)
                    continue
                }
                let size = (try? fm.attributesOfItem(atPath: tempURL.path)[.size] as? NSNumber)?.int64Value ?? 0
                guard size >= expectedMinBytes else {
                    try? fm.removeItem(at: tempURL)
                    continue
                }
                if fm.fileExists(atPath: destination.path) {
                    try? fm.removeItem(at: destination)
                }
                try fm.moveItem(at: tempURL, to: destination)
                if let key { activeDownloads[key] = 1.0 }
                return true
            } catch {
                if Task.isCancelled { return false }
            }
        }
        return false
    }
}

private extension Surah {
    static let ayahCounts: [Int] = [
        0,
        7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128, 111, 110, 98, 135,
        112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73, 54, 45, 83, 182, 88, 75, 85,
        54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13,
        14, 11, 11, 18, 12, 12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42,
        29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11,
        11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6
    ]

    static func ayahCount(for surah: Int) -> Int {
        guard surah >= 1 && surah < ayahCounts.count else { return 7 }
        return ayahCounts[surah]
    }
}
