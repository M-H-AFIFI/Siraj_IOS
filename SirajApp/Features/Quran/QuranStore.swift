import CoreGraphics
import CoreText
import Foundation
import Observation
import SirajCore
import UIKit

enum QuranAssetStage: Equatable {
    case database
    case fonts
}

enum QuranAssetState: Equatable {
    case checking
    case needsDownload
    case downloading(stage: QuranAssetStage, progress: Double, receivedBytes: Int64, totalBytes: Int64)
    case unpacking(stage: QuranAssetStage, progress: Double)
    case ready
    case failed(String)

    var isReady: Bool {
        if case .ready = self { return true }
        return false
    }

    var isBusy: Bool {
        switch self {
        case .downloading, .unpacking: return true
        default: return false
        }
    }
}

final class QcfFaceMetrics: @unchecked Sendable {
    let ctFont: CTFont
    let cgFont: CGFont
    let ascentEm: CGFloat
    let descentEm: CGFloat

    private let refSize: CGFloat = 512.0
    private let refFont: CTFont
    private let lock = NSLock()
    private var charAdvances: [UInt16: CGFloat] = [:]
    private var runAdvances: [String: CGFloat] = [:]
    private var inkBoxes: [String: (height: CGFloat, centre: CGFloat)] = [:]

    init(cgFont: CGFont) {
        self.cgFont = cgFont
        let rf = CTFontCreateWithGraphicsFont(cgFont, 512.0, nil, nil)
        self.refFont = rf
        self.ctFont = rf
        self.ascentEm = CTFontGetAscent(rf) / 512.0
        self.descentEm = CTFontGetDescent(rf) / 512.0
    }

    func font(size: CGFloat) -> CTFont {
        CTFontCreateWithGraphicsFont(cgFont, size, nil, nil)
    }

    func advance(codeUnit: UInt16) -> CGFloat {
        lock.lock()
        if let cached = charAdvances[codeUnit] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        var cu = codeUnit
        var glyph: CGGlyph = 0
        CTFontGetGlyphsForCharacters(refFont, &cu, &glyph, 1)
        var adv = CGSize.zero
        CTFontGetAdvancesForGlyphs(refFont, .horizontal, &glyph, &adv, 1)
        let em = adv.width / refSize

        lock.lock()
        charAdvances[codeUnit] = em
        lock.unlock()
        return em
    }

    func advance(glyphs: String) -> CGFloat {
        var total: CGFloat = 0
        for cu in glyphs.utf16 {
            total += advance(codeUnit: cu)
        }
        return total
    }

    func runAdvance(_ text: String, rtl: Bool = true) -> CGFloat {
        let key = (rtl ? "R:" : "L:") + text
        lock.lock()
        if let cached = runAdvances[key] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let attrs: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): refFont
        ]
        let attributed = NSAttributedString(string: text, attributes: attrs)
        let line = CTLineCreateWithAttributedString(attributed)
        let width = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil)) / refSize

        lock.lock()
        runAdvances[key] = width
        lock.unlock()
        return width
    }

    func inkBox(_ text: String) -> (height: CGFloat, centre: CGFloat) {
        lock.lock()
        if let cached = inkBoxes[text] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let attrs: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): refFont
        ]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attrs))
        let bounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds])
        // CoreText y points up from baseline; flip sign so centre is negative above baseline (y-down UIKit coords).
        let height = bounds.height / refSize
        let topDown = -bounds.maxY / refSize
        let bottomDown = -bounds.minY / refSize
        let result = (height: height, centre: (topDown + bottomDown) / 2.0)

        lock.lock()
        inkBoxes[text] = result
        lock.unlock()
        return result
    }
}

final class QcfFontCache: @unchecked Sendable {
    private let fontsDir: URL
    private let lock = NSLock()
    private var pageOrder: [Int] = []
    private var pageCache: [Int: QcfFaceMetrics] = [:]
    private var basmalahFace: QcfFaceMetrics?
    private var bannerFace: QcfFaceMetrics?
    private var indopakFace: QcfFaceMetrics?
    private var shamarlyFace: QcfFaceMetrics?
    private var madinahFallbackFace: QcfFaceMetrics?

    init(fontsDir: URL) {
        self.fontsDir = fontsDir
    }

    var hasPageFontsInstalled: Bool {
        FileManager.default.fileExists(atPath: fontsDir.appendingPathComponent("QCF_P001.ttf").path)
    }

    func pageFace(for pageNumber: Int) -> QcfFaceMetrics? {
        guard pageNumber >= 1 && pageNumber <= QcfGlyphTable.pageCount else { return nil }
        lock.lock()
        if let hit = pageCache[pageNumber] {
            lock.unlock()
            return hit
        }
        lock.unlock()

        let url = fontsDir.appendingPathComponent(String(format: "QCF_P%03d.ttf", pageNumber))
        guard let loaded = loadFontFile(url) else { return nil }

        lock.lock()
        pageCache[pageNumber] = loaded
        pageOrder.removeAll { $0 == pageNumber }
        pageOrder.append(pageNumber)
        while pageOrder.count > 16 {
            let evicted = pageOrder.removeFirst()
            pageCache.removeValue(forKey: evicted)
        }
        lock.unlock()
        return loaded
    }

    func basmalah() -> QcfFaceMetrics? {
        lock.lock()
        if let f = basmalahFace { lock.unlock(); return f }
        lock.unlock()
        let url = fontsDir.appendingPathComponent("QCF_BSML.ttf")
        guard let loaded = loadFontFile(url) else { return nil }
        lock.lock()
        basmalahFace = loaded
        lock.unlock()
        return loaded
    }

    func surahBanner() -> QcfFaceMetrics? {
        cachedBundled(slot: \.bannerFace, postScript: "QCF_SurahHeader_COLOR", resource: "quran_surah_header", ext: "ttf")
    }

    func indopak() -> QcfFaceMetrics? {
        cachedBundled(slot: \.indopakFace, postScript: "AlQuranIndoPakbyQuranWBW", resource: "indopak", ext: "ttf")
    }

    func shamarly() -> QcfFaceMetrics? {
        cachedBundled(slot: \.shamarlyFace, postScript: "AmiriQuran-Regular", resource: "quran_amiri_quran", ext: "ttf")
    }

    func madinahFallback() -> QcfFaceMetrics? {
        cachedBundled(slot: \.madinahFallbackFace, postScript: "DigitalKhattOldMadinaRegular", resource: "quran_digitalkhatt_v1", ext: "otf")
    }

    private func cachedBundled(
        slot: ReferenceWritableKeyPath<QcfFontCache, QcfFaceMetrics?>,
        postScript: String,
        resource: String,
        ext: String
    ) -> QcfFaceMetrics? {
        lock.lock()
        if let existing = self[keyPath: slot] {
            lock.unlock()
            return existing
        }
        lock.unlock()

        let loaded: QcfFaceMetrics?
        if let url = Bundle.main.url(forResource: resource, withExtension: ext, subdirectory: "Fonts")
            ?? Bundle.main.url(forResource: resource, withExtension: ext) {
            loaded = loadFontFile(url)
        } else if let uiFont = UIFont(name: postScript, size: 24) {
            let cg = CTFontCopyGraphicsFont(uiFont as CTFont, nil)
            loaded = QcfFaceMetrics(cgFont: cg)
        } else {
            loaded = nil
        }

        if let loaded {
            lock.lock()
            self[keyPath: slot] = loaded
            lock.unlock()
        }
        return loaded
    }

    private func loadFontFile(_ url: URL) -> QcfFaceMetrics? {
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url, options: .mappedIfSafe),
              let provider = CGDataProvider(data: data as CFData),
              let cgFont = CGFont(provider) else { return nil }
        return QcfFaceMetrics(cgFont: cgFont)
    }
}

private final class DownloadProgressDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    var onProgress: ((Int64, Int64) -> Void)?
    private var continuation: CheckedContinuation<URL, Error>?
    private let lock = NSLock()

    func awaitDownload(task: URLSessionDownloadTask) async throws -> URL {
        try await withCheckedThrowingContinuation { cont in
            lock.lock()
            self.continuation = cont
            lock.unlock()
            task.resume()
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        onProgress?(totalBytesWritten, totalBytesExpectedToWrite)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let http = downloadTask.response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            finish(with: .failure(NSError(domain: "SirajDownload", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"])))
            return
        }
        let tempCopy = FileManager.default.temporaryDirectory.appendingPathComponent("siraj-dl-\(UUID().uuidString)")
        do {
            try FileManager.default.moveItem(at: location, to: tempCopy)
            finish(with: .success(tempCopy))
        } catch {
            finish(with: .failure(error))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            finish(with: .failure(error))
        }
    }

    private func finish(with result: Result<URL, Error>) {
        lock.lock()
        let cont = continuation
        continuation = nil
        lock.unlock()
        cont?.resume(with: result)
    }
}

@MainActor
@Observable
final class QuranStore {
    let assetsRoot: URL
    let databaseURL: URL
    let fontsDir: URL
    let versionFileURL: URL
    let fontCache: QcfFontCache

    var assetState: QuranAssetState = .checking
    var surahs: [Surah] = []
    var readingPosition: ReadingPosition?
    var bookmarks: [QuranBookmark] = []
    var notes: [QuranNote] = []
    var downloadedTafsirs: Set<String> = [TafsirBook.builtInId]

    let qcfTable: QcfGlyphTable?
    let shamarlyBreaks: MushafLineBreaksTable

    private var database: QuranDatabase?
    private var pageCache: [String: MushafPage] = [:]
    private var pageCacheOrder: [String] = []
    private var juzSummariesCache: [MushafEdition: [JuzSummary]] = [:]
    private var installTask: Task<Void, Never>?
    private let userStore: UserDataStore

    init(userStore: UserDataStore) {
        self.userStore = userStore
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fm.temporaryDirectory
        let root = appSupport.appendingPathComponent("SirajAssets", isDirectory: true)
        self.assetsRoot = root
        self.databaseURL = root.appendingPathComponent("quran_data.db")
        self.fontsDir = root.appendingPathComponent("fonts", isDirectory: true)
        self.versionFileURL = root.appendingPathComponent("asset_version.txt")
        self.fontCache = QcfFontCache(fontsDir: fontsDir)
        try? fm.createDirectory(at: root, withIntermediateDirectories: true)

        self.readingPosition = userStore.loadReadingPosition()
        self.bookmarks = userStore.loadBookmarks()
        self.notes = userStore.loadNotes()
        self.surahs = Self.loadBundledSurahs()
        self.qcfTable = Self.loadBundledQcfTable()
        self.shamarlyBreaks = Self.loadBundledShamarlyBreaks()

        checkExistingAssets()
    }

    var hasPageFonts: Bool {
        fontCache.hasPageFontsInstalled
    }

    func checkExistingAssets() {
        let fm = FileManager.default
        let version = (try? String(contentsOf: versionFileURL, encoding: .utf8))?.trimmingCharacters(in: .whitespacesAndNewlines)
        if fm.fileExists(atPath: databaseURL.path),
           version == SirajAssetURLs.assetVersion,
           let db = try? QuranDatabase(path: databaseURL.path),
           db.isValidDatabase() {
            self.database = db
            let dbSurahs = db.getAllSurahs()
            if dbSurahs.count == 114 { self.surahs = dbSurahs }
            self.downloadedTafsirs = db.getDownloadedTafsirEditions()
            self.assetState = .ready
        } else {
            self.database = nil
            self.assetState = .needsDownload
        }
    }

    func startInstall(includePageFonts: Bool = true) {
        guard !assetState.isBusy else { return }
        installTask?.cancel()
        installTask = Task { [weak self] in
            guard let self else { return }
            await self.runInstallPipeline(includePageFonts: includePageFonts)
        }
    }

    func cancelInstall() {
        installTask?.cancel()
        installTask = nil
        checkExistingAssets()
    }

    private func runInstallPipeline(includePageFonts: Bool) async {
        let fm = FileManager.default
        try? fm.createDirectory(at: assetsRoot, withIntermediateDirectories: true)
        try? fm.createDirectory(at: fontsDir, withIntermediateDirectories: true)

        do {
            // 1. Download & unpack quran_data.db.gz if missing or outdated
            let needsDB: Bool = {
                guard fm.fileExists(atPath: databaseURL.path),
                      let ver = try? String(contentsOf: versionFileURL, encoding: .utf8),
                      ver.trimmingCharacters(in: .whitespacesAndNewlines) == SirajAssetURLs.assetVersion,
                      let db = try? QuranDatabase(path: databaseURL.path) else { return true }
                return !db.isValidDatabase()
            }()

            if needsDB {
                assetState = .downloading(stage: .database, progress: 0, receivedBytes: 0, totalBytes: 42_200_000)
                let downloadedGz = try await downloadReleaseFile("quran_data.db.gz", stage: .database, fallbackBytes: 42_200_000)
                defer { try? fm.removeItem(at: downloadedGz) }

                try Task.checkCancellation()
                assetState = .unpacking(stage: .database, progress: 0)
                let stagedDB = assetsRoot.appendingPathComponent("quran_data.db.staged")
                try await Task.detached(priority: .userInitiated) {
                    try QuranArchiveUnpacker.gunzipFile(source: downloadedGz, destination: stagedDB) { fraction in
                        Task { @MainActor in
                            self.assetState = .unpacking(stage: .database, progress: fraction)
                        }
                    }
                }.value

                try Task.checkCancellation()
                let probe = try QuranDatabase(path: stagedDB.path)
                guard probe.isValidDatabase() else {
                    try? fm.removeItem(at: stagedDB)
                    throw QuranArchiveError.invalidZipFormat
                }
                if fm.fileExists(atPath: databaseURL.path) {
                    try fm.removeItem(at: databaseURL)
                }
                try fm.moveItem(at: stagedDB, to: databaseURL)
                try SirajAssetURLs.assetVersion.write(to: versionFileURL, atomically: true, encoding: .utf8)
            }

            // 2. Download & unpack 604 QCF Madinah page fonts if requested and missing
            if includePageFonts && !fontCache.hasPageFontsInstalled {
                assetState = .downloading(stage: .fonts, progress: 0, receivedBytes: 0, totalBytes: 57_100_000)
                let downloadedZip = try await downloadReleaseFile("quran-page-fonts.zip", stage: .fonts, fallbackBytes: 57_100_000)
                defer { try? fm.removeItem(at: downloadedZip) }

                try Task.checkCancellation()
                assetState = .unpacking(stage: .fonts, progress: 0)
                let stagedFonts = assetsRoot.appendingPathComponent("fonts.staged", isDirectory: true)
                try? fm.removeItem(at: stagedFonts)
                try await Task.detached(priority: .userInitiated) {
                    try QuranArchiveUnpacker.unzipDirectory(source: downloadedZip, destination: stagedFonts, flattenBasename: true) { fraction in
                        Task { @MainActor in
                            self.assetState = .unpacking(stage: .fonts, progress: fraction)
                        }
                    }
                }.value

                try Task.checkCancellation()
                if fm.fileExists(atPath: fontsDir.path) {
                    try fm.removeItem(at: fontsDir)
                }
                try fm.moveItem(at: stagedFonts, to: fontsDir)
            }

            let db = try QuranDatabase(path: databaseURL.path)
            self.database = db
            let dbSurahs = db.getAllSurahs()
            if dbSurahs.count == 114 { self.surahs = dbSurahs }
            self.downloadedTafsirs = db.getDownloadedTafsirEditions()
            self.pageCache.removeAll()
            self.pageCacheOrder.removeAll()
            self.juzSummariesCache.removeAll()
            self.assetState = .ready
        } catch is CancellationError {
            checkExistingAssets()
        } catch {
            self.assetState = .failed(error.localizedDescription)
        }
    }

    private func downloadReleaseFile(_ name: String, stage: QuranAssetStage, fallbackBytes: Int64) async throws -> URL {
        let url = SirajAssetURLs.release(name)
        var request = URLRequest(url: url)
        request.timeoutInterval = 120
        let delegate = DownloadProgressDelegate()
        delegate.onProgress = { [weak self] received, expected in
            let total = expected > 0 ? expected : fallbackBytes
            let frac = total > 0 ? min(1.0, Double(received) / Double(total)) : 0
            Task { @MainActor in
                self?.assetState = .downloading(stage: stage, progress: frac, receivedBytes: received, totalBytes: total)
            }
        }
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        defer { session.finishTasksAndInvalidate() }
        let task = session.downloadTask(with: request)
        return try await withTaskCancellationHandler {
            try await delegate.awaitDownload(task: task)
        } onCancel: {
            task.cancel()
        }
    }

    // MARK: - Queries

    func mushafPage(pageNumber: Int, edition: MushafEdition) -> MushafPage? {
        let key = "\(edition.scriptType)-\(pageNumber)"
        if let cached = pageCache[key] { return cached }
        guard let database else { return nil }
        let loaded = database.getMushafPage(pageNumber: pageNumber, edition: edition, shamarlyBreaks: shamarlyBreaks)
        pageCache[key] = loaded
        pageCacheOrder.removeAll { $0 == key }
        pageCacheOrder.append(key)
        while pageCacheOrder.count > 24 {
            let evicted = pageCacheOrder.removeFirst()
            pageCache.removeValue(forKey: evicted)
        }
        return loaded
    }

    func loadMushafPageAsync(pageNumber: Int, edition: MushafEdition) async -> MushafPage? {
        let key = "\(edition.scriptType)-\(pageNumber)"
        if let cached = pageCache[key] { return cached }
        guard let db = database else { return nil }
        let breaks = shamarlyBreaks
        let loaded = await Task.detached(priority: .userInitiated) {
            db.getMushafPage(pageNumber: pageNumber, edition: edition, shamarlyBreaks: breaks)
        }.value
        pageCache[key] = loaded
        pageCacheOrder.removeAll { $0 == key }
        pageCacheOrder.append(key)
        while pageCacheOrder.count > 24 {
            let evicted = pageCacheOrder.removeFirst()
            pageCache.removeValue(forKey: evicted)
        }
        return loaded
    }

    func ayahsForSurah(_ surahNumber: Int, edition: MushafEdition, translationEdition: String? = nil) async -> [Ayah] {
        guard let db = database else { return [] }
        return await Task.detached(priority: .userInitiated) {
            db.getAyahsForSurah(surahNumber, edition: edition, translationEdition: translationEdition)
        }.value
    }

    func ayah(surah: Int, ayah: Int, edition: MushafEdition) async -> Ayah? {
        guard let db = database else { return nil }
        return await Task.detached(priority: .userInitiated) {
            db.getAyah(surah: surah, ayah: ayah, edition: edition)
        }.value
    }

    func ayahByGlobalNumber(_ globalNumber: Int, edition: MushafEdition) async -> Ayah? {
        guard let db = database else { return nil }
        return await Task.detached(priority: .userInitiated) {
            db.getAyahByGlobalNumber(globalNumber, edition: edition)
        }.value
    }

    func pageForAyah(surah: Int, ayah: Int, edition: MushafEdition) -> Int {
        database?.getPageForAyah(surah: surah, ayah: ayah, edition: edition) ?? QuranTables.pageForSurah(surah, edition: edition)
    }

    func juzSummaries(for edition: MushafEdition) -> [JuzSummary] {
        if let cached = juzSummariesCache[edition] { return cached }
        guard let database else { return [] }
        let built = database.getJuzSummaries(edition: edition)
        if !built.isEmpty { juzSummariesCache[edition] = built }
        return built
    }

    func searchAyahs(_ query: String, limit: Int = 50) async -> [Ayah] {
        guard let db = database else { return [] }
        return await Task.detached(priority: .userInitiated) {
            db.searchAyahsNormalized(rawQuery: query, limit: limit)
        }.value
    }

    func ayahStartPages(for edition: MushafEdition) async -> [Int: Int] {
        guard let db = database, edition.hasOwnPagination else { return [:] }
        return await Task.detached(priority: .utility) {
            db.getAyahStartPages(edition: edition)
        }.value
    }

    // MARK: - Tafsir & Translations

    func tafsirText(globalAyah: Int, edition: String) async -> String? {
        guard let db = database else { return nil }
        return await Task.detached(priority: .userInitiated) {
            db.getTafsir(globalAyahNumber: globalAyah, edition: edition)
        }.value
    }

    func downloadTafsir(edition: String, onProgress: @escaping @MainActor (Double) -> Void) async throws {
        if edition == TafsirBook.builtInId {
            onProgress(1.0)
            return
        }
        guard let db = database else {
            throw QuranDatabaseError.openFailed("Quran database not installed")
        }
        onProgress(0.1)
        let urls = TafsirBook.mirrorURLs(for: edition)
        var rawData: Data?
        for url in urls {
            var req = URLRequest(url: url)
            req.timeoutInterval = 45
            if let (data, resp) = try? await URLSession.shared.data(for: req),
               let http = resp as? HTTPURLResponse,
               (200...299).contains(http.statusCode),
               data.count > 500 {
                if data.count >= 2 && data[0] == 0x1F && data[1] == 0x8B {
                    rawData = try? QuranArchiveUnpacker.gunzipData(data)
                } else {
                    rawData = data
                }
                if rawData != nil { break }
            }
        }
        guard let payload = rawData else {
            throw NSError(domain: "SirajTafsir", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not download tafsir \(edition)"])
        }
        onProgress(0.6)
        let entries = await Task.detached(priority: .userInitiated) {
            TafsirPayloadParser.parse(data: payload)
        }.value
        guard !entries.isEmpty else {
            throw NSError(domain: "SirajTafsir", code: -2, userInfo: [NSLocalizedDescriptionKey: "Tafsir file was empty"])
        }
        onProgress(0.85)
        try await Task.detached(priority: .userInitiated) {
            try db.replaceEdition(edition: edition, entries: entries)
        }.value
        downloadedTafsirs.insert(edition)
        onProgress(1.0)
    }

    func deleteTafsir(edition: String) async {
        guard edition != TafsirBook.builtInId, let db = database else { return }
        try? await Task.detached(priority: .userInitiated) {
            try db.deleteTafsirEdition(edition)
        }.value
        downloadedTafsirs.remove(edition)
    }

    // MARK: - Reading Position, Bookmarks, Notes

    func saveReadingPosition(surah: Int, ayah: Int, page: Int, edition: MushafEdition) {
        let pos = ReadingPosition(
            surahNumber: surah,
            ayahNumber: ayah,
            page: page,
            juz: QuranTables.juzForPage(page, edition: edition),
            pageCount: edition.totalPages,
            edition: edition.rawValue
        )
        readingPosition = pos
        userStore.saveReadingPosition(pos)
    }

    func isBookmarked(surah: Int, ayah: Int) -> Bool {
        bookmarks.contains { $0.surahNumber == surah && $0.ayahNumber == ayah }
    }

    @discardableResult
    func toggleBookmark(surah: Int, ayah: Int, surahName: String, pageNumber: Int? = nil, name: String? = nil) -> Bool {
        if let idx = bookmarks.firstIndex(where: { $0.surahNumber == surah && $0.ayahNumber == ayah }) {
            bookmarks.remove(at: idx)
            userStore.saveBookmarks(bookmarks)
            return false
        }
        let item = QuranBookmark(
            surahNumber: surah,
            ayahNumber: ayah,
            surahName: surahName,
            pageNumber: pageNumber,
            name: name
        )
        bookmarks.insert(item, at: 0)
        userStore.saveBookmarks(bookmarks)
        return true
    }

    func removeBookmark(_ bookmark: QuranBookmark) {
        bookmarks.removeAll { $0.id == bookmark.id }
        userStore.saveBookmarks(bookmarks)
    }

    func notesForAyah(surah: Int, ayah: Int) -> [QuranNote] {
        notes.filter { $0.surahNumber == surah && $0.ayahNumber == ayah }
    }

    func addNote(surah: Int, ayah: Int, content: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let note = QuranNote(surahNumber: surah, ayahNumber: ayah, content: trimmed)
        notes.insert(note, at: 0)
        userStore.saveNotes(notes)
    }

    func updateNote(_ note: QuranNote, content: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let idx = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[idx].content = trimmed
        notes[idx].timestamp = Date().timeIntervalSince1970
        userStore.saveNotes(notes)
    }

    func deleteNote(_ note: QuranNote) {
        notes.removeAll { $0.id == note.id }
        userStore.saveNotes(notes)
    }

    // MARK: - Bundled Data Loaders

    private static func loadBundledSurahs() -> [Surah] {
        guard let url = Bundle.main.url(forResource: "surahs", withExtension: "json", subdirectory: "Data")
            ?? Bundle.main.url(forResource: "surahs", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Surah].self, from: data) else { return [] }
        return decoded
    }

    private static func loadBundledQcfTable() -> QcfGlyphTable? {
        guard let url = Bundle.main.url(forResource: "qcf_v1_glyphs", withExtension: "txt", subdirectory: "Data")
            ?? Bundle.main.url(forResource: "qcf_v1_glyphs", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        return QcfGlyphTable.parse(text)
    }

    private static func loadBundledShamarlyBreaks() -> MushafLineBreaksTable {
        guard let url = Bundle.main.url(forResource: "shamarly_line_breaks", withExtension: "txt", subdirectory: "Data")
            ?? Bundle.main.url(forResource: "shamarly_line_breaks", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return .empty }
        return MushafLineBreaksTable.parse(text)
    }
}
