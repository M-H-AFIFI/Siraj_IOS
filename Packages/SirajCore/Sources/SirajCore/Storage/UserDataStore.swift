import Foundation

public struct UserProgressSnapshot: Codable, Sendable, Equatable {
    public var onboardingComplete: Bool
    public var tasbihCount: Int
    public var lastReadPage: Int?
    public var khatmasCompleted: Int

    public init(onboardingComplete: Bool = false, tasbihCount: Int = 0, lastReadPage: Int? = nil, khatmasCompleted: Int = 0) {
        self.onboardingComplete = onboardingComplete
        self.tasbihCount = tasbihCount
        self.lastReadPage = lastReadPage
        self.khatmasCompleted = khatmasCompleted
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.onboardingComplete = try c.decodeIfPresent(Bool.self, forKey: .onboardingComplete) ?? false
        self.tasbihCount = try c.decodeIfPresent(Int.self, forKey: .tasbihCount) ?? 0
        self.lastReadPage = try c.decodeIfPresent(Int.self, forKey: .lastReadPage)
        self.khatmasCompleted = try c.decodeIfPresent(Int.self, forKey: .khatmasCompleted) ?? 0
    }
}

/// Isolated user persistence store (App Group when available, Application Support fallback for sideload builds).
/// Kept strictly separate from any downloaded Mushaf database so asset refreshes never risk user records.
public final class UserDataStore: @unchecked Sendable {
    public static let defaultAppGroupId = "group.com.siiraj.app"

    public let directoryURL: URL
    public let isUsingFallbackContainer: Bool

    private let lock = NSLock()
    private let settingsURL: URL
    private let progressURL: URL
    private let readingPositionURL: URL
    private let bookmarksURL: URL
    private let notesURL: URL
    private let khatmaURL: URL
    private let listeningSessionURL: URL

    public init(appGroupId: String? = UserDataStore.defaultAppGroupId, fallbackDirectory: URL? = nil) {
        let fm = FileManager.default
        if let appGroupId, !appGroupId.isEmpty,
           let groupURL = fm.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) {
            self.directoryURL = groupURL.appendingPathComponent("SirajUserData", isDirectory: true)
            self.isUsingFallbackContainer = false
        } else {
            let base = fallbackDirectory
                ?? fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? fm.temporaryDirectory
            self.directoryURL = base.appendingPathComponent("SirajUserData", isDirectory: true)
            self.isUsingFallbackContainer = true
        }
        self.settingsURL = directoryURL.appendingPathComponent("settings.json")
        self.progressURL = directoryURL.appendingPathComponent("progress.json")
        self.readingPositionURL = directoryURL.appendingPathComponent("reading_position.json")
        self.bookmarksURL = directoryURL.appendingPathComponent("quran_bookmarks.json")
        self.notesURL = directoryURL.appendingPathComponent("quran_notes.json")
        self.khatmaURL = directoryURL.appendingPathComponent("khatma_record.json")
        self.listeningSessionURL = directoryURL.appendingPathComponent("listening_session.json")
        try? fm.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    public func loadSettings() -> SettingsSnapshot {
        lock.lock()
        defer { lock.unlock() }
        return readJSON(SettingsSnapshot.self, from: settingsURL) ?? SettingsSnapshot()
    }

    public func saveSettings(_ snapshot: SettingsSnapshot) {
        lock.lock()
        defer { lock.unlock() }
        writeJSON(snapshot, to: settingsURL)
    }

    public func loadProgress() -> UserProgressSnapshot {
        lock.lock()
        defer { lock.unlock() }
        return readJSON(UserProgressSnapshot.self, from: progressURL) ?? UserProgressSnapshot()
    }

    public func saveProgress(_ progress: UserProgressSnapshot) {
        lock.lock()
        defer { lock.unlock() }
        writeJSON(progress, to: progressURL)
    }

    public func loadOnboardingComplete() -> Bool {
        loadProgress().onboardingComplete
    }

    public func saveOnboardingComplete(_ complete: Bool) {
        lock.lock()
        defer { lock.unlock() }
        var p = readJSON(UserProgressSnapshot.self, from: progressURL) ?? UserProgressSnapshot()
        p.onboardingComplete = complete
        writeJSON(p, to: progressURL)
    }

    public func loadTasbihCount() -> Int {
        loadProgress().tasbihCount
    }

    public func saveTasbihCount(_ count: Int) {
        lock.lock()
        defer { lock.unlock() }
        var p = readJSON(UserProgressSnapshot.self, from: progressURL) ?? UserProgressSnapshot()
        p.tasbihCount = max(0, count)
        writeJSON(p, to: progressURL)
    }

    public func loadReadingPosition() -> ReadingPosition? {
        lock.lock()
        defer { lock.unlock() }
        return readJSON(ReadingPosition.self, from: readingPositionURL)
    }

    public func saveReadingPosition(_ position: ReadingPosition) {
        lock.lock()
        defer { lock.unlock() }
        writeJSON(position, to: readingPositionURL)
    }

    public func loadBookmarks() -> [QuranBookmark] {
        lock.lock()
        defer { lock.unlock() }
        return readJSON([QuranBookmark].self, from: bookmarksURL) ?? []
    }

    public func saveBookmarks(_ bookmarks: [QuranBookmark]) {
        lock.lock()
        defer { lock.unlock() }
        writeJSON(bookmarks, to: bookmarksURL)
    }

    public func loadNotes() -> [QuranNote] {
        lock.lock()
        defer { lock.unlock() }
        return readJSON([QuranNote].self, from: notesURL) ?? []
    }

    public func saveNotes(_ notes: [QuranNote]) {
        lock.lock()
        defer { lock.unlock() }
        writeJSON(notes, to: notesURL)
    }

    public func loadKhatmaRecord() -> KhatmaRecord? {
        lock.lock()
        defer { lock.unlock() }
        return readJSON(KhatmaRecord.self, from: khatmaURL)
    }

    public func saveKhatmaRecord(_ record: KhatmaRecord?) {
        lock.lock()
        defer { lock.unlock() }
        if let record {
            writeJSON(record, to: khatmaURL)
        } else {
            try? FileManager.default.removeItem(at: khatmaURL)
        }
    }

    public func loadKhatmasCompleted() -> Int {
        loadProgress().khatmasCompleted
    }

    public func saveKhatmasCompleted(_ count: Int) {
        lock.lock()
        defer { lock.unlock() }
        var p = readJSON(UserProgressSnapshot.self, from: progressURL) ?? UserProgressSnapshot()
        p.khatmasCompleted = max(0, count)
        writeJSON(p, to: progressURL)
    }

    public func loadListeningSession() -> ListeningSession? {
        lock.lock()
        defer { lock.unlock() }
        return readJSON(ListeningSession.self, from: listeningSessionURL)
    }

    public func saveListeningSession(_ session: ListeningSession?) {
        lock.lock()
        defer { lock.unlock() }
        if let session {
            writeJSON(session, to: listeningSessionURL)
        } else {
            try? FileManager.default.removeItem(at: listeningSessionURL)
        }
    }

    private func readJSON<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(type, from: data)
        } catch {
            let badURL = url.deletingPathExtension().appendingPathExtension("bad.json")
            try? FileManager.default.removeItem(at: badURL)
            try? FileManager.default.copyItem(at: url, to: badURL)
            return nil
        }
    }

    private func writeJSON<T: Encodable>(_ value: T, to url: URL) {
        let fm = FileManager.default
        try? fm.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
