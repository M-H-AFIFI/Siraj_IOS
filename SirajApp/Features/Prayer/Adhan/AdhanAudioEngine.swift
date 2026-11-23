import AVFoundation
import Foundation
import Observation
import SirajCore

@MainActor
@Observable
final class AdhanAudioEngine: NSObject, AVAudioPlayerDelegate {
    var playingVoiceId: String?
    var isPlayingFullAdhan = false
    var adhanFinished = false
    var downloadingVoiceIds: Set<String> = []
    var failedVoiceIds: Set<String> = []
    var downloadError: String?
    var volume: Double = 0.85

    private var player: AVAudioPlayer?

    private var audioStorageDir: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("AdhanAudio", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // iOS UNNotificationSound only looks in the app bundle root and Library/Sounds.
    private var librarySoundsDir: URL {
        let base = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Sounds", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func localAudioURL(for voice: AdhanVoice) -> URL? {
        let cached = audioStorageDir.appendingPathComponent(voice.fileName)
        if FileManager.default.fileExists(atPath: cached.path) {
            return cached
        }
        let stem = (voice.fileName as NSString).deletingPathExtension
        let ext = (voice.fileName as NSString).pathExtension
        if let bundled = Bundle.main.url(forResource: stem, withExtension: ext, subdirectory: "Sounds")
            ?? Bundle.main.url(forResource: stem, withExtension: ext) {
            return bundled
        }
        return nil
    }

    func isDownloaded(_ voice: AdhanVoice) -> Bool {
        localAudioURL(for: voice) != nil
    }

    func availableNotificationSounds() -> Set<String> {
        var names = Set<String>()
        if let bundleUrls = Bundle.main.urls(forResourcesWithExtension: "caf", subdirectory: nil) {
            for u in bundleUrls { names.insert(u.lastPathComponent) }
        }
        if let subUrls = Bundle.main.urls(forResourcesWithExtension: "caf", subdirectory: "Sounds") {
            for u in subUrls { names.insert(u.lastPathComponent) }
        }
        if let libUrls = try? FileManager.default.contentsOfDirectory(at: librarySoundsDir, includingPropertiesForKeys: nil) {
            for u in libUrls where u.pathExtension.lowercased() == "caf" {
                names.insert(u.lastPathComponent)
            }
        }
        return names
    }

    func resolvedNotificationSound(for prayer: PrayerType, settings: SettingsSnapshot) -> String {
        AdhanVoiceResolver.notificationSoundName(
            voiceId: settings.azanSound,
            prayer: prayer,
            fajrAdhanEnabled: settings.fajrAdhanEnabled,
            preferredFajrId: settings.fajrAdhanVoice,
            availableSoundFiles: availableNotificationSounds()
        )
    }

    func playPreview(voiceId: String, volume: Double? = nil) {
        let voice = AdhanVoiceResolver.findVoice(voiceId)
        if playingVoiceId == voice.id && !isPlayingFullAdhan {
            stop()
            return
        }
        if let url = localAudioURL(for: voice) {
            startPlayback(url: url, voiceId: voice.id, isFullAdhan: false, volume: volume ?? self.volume)
        } else {
            Task {
                await downloadVoice(voice)
                if let url = localAudioURL(for: voice) {
                    startPlayback(url: url, voiceId: voice.id, isFullAdhan: false, volume: volume ?? self.volume)
                }
            }
        }
    }

    func playFullAdhan(for prayer: PrayerType, settings: SettingsSnapshot) {
        adhanFinished = false
        let voice: AdhanVoice
        if prayer == .fajr && settings.fajrAdhanEnabled {
            voice = AdhanVoiceResolver.fajrVoice(for: settings.azanSound, preferredFajrId: settings.fajrAdhanVoice)
        } else {
            voice = AdhanVoiceResolver.findVoice(settings.azanSound)
        }
        let fallback = AdhanVoiceResolver.findVoice(AdhanCatalog.defaultVoiceId)
        guard let url = localAudioURL(for: voice) ?? localAudioURL(for: fallback) else {
            adhanFinished = true
            return
        }
        startPlayback(url: url, voiceId: voice.id, isFullAdhan: true, volume: settings.adhanVolume)
    }

    func setVolume(_ newVolume: Double) {
        let clamped = min(1.0, max(0.1, newVolume))
        volume = clamped
        player?.volume = Float(clamped)
    }

    func stop() {
        player?.stop()
        player = nil
        playingVoiceId = nil
        isPlayingFullAdhan = false
        deactivateAudioSession()
    }

    func downloadVoice(_ voice: AdhanVoice) async {
        guard !downloadingVoiceIds.contains(voice.id) else { return }
        downloadingVoiceIds.insert(voice.id)
        failedVoiceIds.remove(voice.id)
        downloadError = nil
        defer { downloadingVoiceIds.remove(voice.id) }

        let urls = [voice.cdnUrl, voice.fallbackUrl].compactMap(URL.init(string:))
        var downloadedData: Data?
        for url in urls {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                if let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode), data.count > 4096 {
                    downloadedData = data
                    break
                }
            } catch {
                continue
            }
        }

        guard let data = downloadedData else {
            failedVoiceIds.insert(voice.id)
            downloadError = "adhan_voice_failed"
            return
        }

        let dest = audioStorageDir.appendingPathComponent(voice.fileName)
        do {
            try data.write(to: dest, options: .atomic)
            let cafDest = librarySoundsDir.appendingPathComponent(voice.cafFileName)
            try await Task.detached(priority: .utility) {
                try Self.exportNotificationClip(from: dest, to: cafDest)
            }.value
        } catch {
            failedVoiceIds.insert(voice.id)
            downloadError = "adhan_voice_failed"
        }
    }

    private func startPlayback(url: URL, voiceId: String, isFullAdhan: Bool, volume: Double) {
        player?.stop()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)

            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.delegate = self
            audioPlayer.volume = Float(min(1.0, max(0.1, volume)))
            audioPlayer.prepareToPlay()
            audioPlayer.play()

            self.volume = volume
            self.player = audioPlayer
            self.playingVoiceId = voiceId
            self.isPlayingFullAdhan = isFullAdhan
            self.adhanFinished = false
        } catch {
            self.playingVoiceId = nil
            self.isPlayingFullAdhan = false
            self.adhanFinished = isFullAdhan
        }
    }

    private func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            let wasFull = self.isPlayingFullAdhan
            self.player = nil
            self.playingVoiceId = nil
            self.isPlayingFullAdhan = false
            if wasFull { self.adhanFinished = true }
            self.deactivateAudioSession()
        }
    }

    // UNNotificationSound requires Linear PCM, IMA4, uLaw, or aLaw under 30 seconds.
    private nonisolated static func exportNotificationClip(from sourceURL: URL, to destURL: URL) throws {
        let inputFile = try AVAudioFile(forReading: sourceURL)
        let targetSampleRate: Double = 22_050
        let maxSeconds: Double = 29.0
        let fadeSeconds: Double = 1.5

        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: targetSampleRate,
            channels: 1,
            interleaved: true
        ) else {
            return
        }

        let processingFormat = inputFile.processingFormat
        guard let converter = AVAudioConverter(from: processingFormat, to: targetFormat) else {
            return
        }

        let tmpURL = destURL.appendingPathExtension("tmp.caf")
        try? FileManager.default.removeItem(at: tmpURL)

        let outFile = try AVAudioFile(
            forWriting: tmpURL,
            settings: targetFormat.settings,
            commonFormat: .pcmFormatInt16,
            interleaved: true
        )

        let maxOutFrames = AVAudioFramePosition(maxSeconds * targetSampleRate)
        let fadeFrames = AVAudioFramePosition(fadeSeconds * targetSampleRate)
        var writtenFrames: AVAudioFramePosition = 0
        let chunkFrames: AVAudioFrameCount = 4096

        while writtenFrames < maxOutFrames {
            let remaining = AVAudioFrameCount(min(AVAudioFramePosition(chunkFrames), maxOutFrames - writtenFrames))
            guard let outBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: remaining) else { break }

            var hitEOF = false
            var convertError: NSError?
            let status = converter.convert(to: outBuffer, error: &convertError) { inPacketCount, outStatus in
                guard let inBuf = AVAudioPCMBuffer(pcmFormat: processingFormat, frameCapacity: inPacketCount) else {
                    outStatus.pointee = .endOfStream
                    return nil
                }
                do {
                    try inputFile.read(into: inBuf)
                    if inBuf.frameLength == 0 {
                        hitEOF = true
                        outStatus.pointee = .endOfStream
                        return nil
                    }
                    outStatus.pointee = .haveData
                    return inBuf
                } catch {
                    hitEOF = true
                    outStatus.pointee = .endOfStream
                    return nil
                }
            }

            if status == .error || outBuffer.frameLength == 0 {
                break
            }

            if let samples = outBuffer.int16ChannelData?[0] {
                let count = Int(outBuffer.frameLength)
                let fadeStart = max(0, maxOutFrames - fadeFrames)
                for i in 0..<count {
                    let pos = writtenFrames + AVAudioFramePosition(i)
                    if pos >= fadeStart && fadeFrames > 0 {
                        let gain = max(0.0, Double(maxOutFrames - pos) / Double(fadeFrames))
                        samples[i] = Int16(Double(samples[i]) * gain)
                    }
                }
            }

            try outFile.write(from: outBuffer)
            writtenFrames += AVAudioFramePosition(outBuffer.frameLength)
            if hitEOF || status == .endOfStream { break }
        }

        try? FileManager.default.removeItem(at: destURL)
        try FileManager.default.moveItem(at: tmpURL, to: destURL)
    }
}
