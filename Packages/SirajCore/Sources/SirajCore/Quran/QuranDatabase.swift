import Foundation
import SQLite3

private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

public struct TafsirEntry: Sendable, Equatable {
    public let ayahNumber: Int
    public let text: String

    public init(ayahNumber: Int, text: String) {
        self.ayahNumber = ayahNumber
        self.text = text
    }
}

public enum TafsirPayloadParser {
    public static func parse(data: Data) -> [TafsirEntry] {
        guard let root = try? JSONSerialization.jsonObject(with: data) else { return [] }
        var entries: [TafsirEntry] = []

        if let dict = root as? [String: Any] {
            if let quranArray = dict["quran"] as? [[String: Any]] {
                var counter = 1
                for item in quranArray {
                    let text = (item["text"] as? String)
                        ?? (item["tafsir"] as? String)
                        ?? (item["translation"] as? String)
                        ?? ""
                    let num = intValue(item["ayah"]) ?? intValue(item["number"]) ?? counter
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        entries.append(TafsirEntry(ayahNumber: num, text: text))
                    }
                    counter += 1
                }
                return entries
            }

            let surahsArray = (dict["data"] as? [String: Any])?["surahs"] as? [[String: Any]]
                ?? dict["surahs"] as? [[String: Any]]
            if let surahsArray {
                var counter = 1
                for surah in surahsArray {
                    guard let ayahs = surah["ayahs"] as? [[String: Any]] else { continue }
                    for ayah in ayahs {
                        let text = (ayah["text"] as? String) ?? ""
                        let num = intValue(ayah["number"]) ?? intValue(ayah["ayah"]) ?? counter
                        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            entries.append(TafsirEntry(ayahNumber: num, text: text))
                        }
                        counter += 1
                    }
                }
                return entries
            }
        } else if let list = root as? [[String: Any]] {
            var counter = 1
            for item in list {
                let text = (item["text"] as? String)
                    ?? (item["tafsir"] as? String)
                    ?? (item["translation"] as? String)
                    ?? ""
                let num = intValue(item["ayah"]) ?? intValue(item["number"]) ?? intValue(item["verse"]) ?? counter
                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    entries.append(TafsirEntry(ayahNumber: num, text: text))
                }
                counter += 1
            }
        }
        return entries
    }

    private static func intValue(_ any: Any?) -> Int? {
        if let n = any as? Int { return n }
        if let n = any as? NSNumber { return n.intValue }
        if let s = any as? String { return Int(s) }
        return nil
    }
}

public enum QuranDatabaseError: Error, LocalizedError {
    case openFailed(String)
    case prepareFailed(String)
    case executeFailed(String)

    public var errorDescription: String? {
        switch self {
        case .openFailed(let m), .prepareFailed(let m), .executeFailed(let m):
            return m
        }
    }
}

public final class QuranDatabase: @unchecked Sendable {
    private static let tafsirBlockMaxLookBack = 15

    public let path: String
    private var db: OpaquePointer?
    private let lock = NSRecursiveLock()

    private struct FoldedAyahRow {
        let ayahNumber: Int
        let surahNumber: Int
        let numberInSurah: Int
        let page: Int
        let textUthmani: String
        let folded: String
    }

    private var cachedSurahs: [Surah]?
    private var searchIndex: [FoldedAyahRow]?
    private var ayahStartPagesCache: [String: [Int: Int]] = [:]

    public init(path: String) throws {
        self.path = path
        var handle: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        let status = sqlite3_open_v2(path, &handle, flags, nil)
        guard status == SQLITE_OK, let handle else {
            let msg = handle.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "SQLite open error \(status)"
            if let handle { sqlite3_close(handle) }
            throw QuranDatabaseError.openFailed(msg)
        }
        self.db = handle
        sqlite3_busy_timeout(handle, 3000)
    }

    deinit {
        if let db {
            sqlite3_close(db)
        }
    }

    public func isValidDatabase() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return scalarInt("SELECT COUNT(*) FROM quran_surahs") >= 114
            && scalarInt("SELECT COUNT(*) FROM quran_ayahs") >= 6236
    }

    public func getAllSurahs() -> [Surah] {
        lock.lock()
        defer { lock.unlock() }
        if let cachedSurahs { return cachedSurahs }
        guard let db else { return [] }
        let sql = "SELECT number, name, englishName, englishNameTranslation, numberOfAyahs, revelationType FROM quran_surahs ORDER BY number ASC"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else { return [] }
        defer { sqlite3_finalize(stmt) }
        var result: [Surah] = []
        result.reserveCapacity(114)
        while sqlite3_step(stmt) == SQLITE_ROW {
            result.append(Surah(
                number: Int(sqlite3_column_int(stmt, 0)),
                name: colText(stmt, 1),
                englishName: colText(stmt, 2),
                englishNameTranslation: colText(stmt, 3),
                numberOfAyahs: Int(sqlite3_column_int(stmt, 4)),
                revelationType: colText(stmt, 5)
            ))
        }
        if result.count == 114 {
            cachedSurahs = result
        }
        return result
    }

    public func getAyahsForSurah(
        _ surahNumber: Int,
        edition: MushafEdition = .madinah,
        translationEdition: String? = nil
    ) -> [Ayah] {
        lock.lock()
        defer { lock.unlock() }
        guard let db else { return [] }
        let sql = """
            SELECT ayahNumber, surahNumber, numberInSurah, textUthmani, textSimple, textIndopak, juz, page, hizb, rub, sajda
            FROM quran_ayahs WHERE surahNumber = ? ORDER BY numberInSurah ASC
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else { return [] }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(surahNumber))

        var rows: [Ayah] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            rows.append(readAyah(stmt))
        }
        guard !rows.isEmpty else { return [] }

        let editionTexts: [Int: (text: String, page: Int)]
        if edition.hasOwnPagination {
            editionTexts = loadEditionAyahTexts(surahNumber: surahNumber, edition: edition)
        } else {
            editionTexts = [:]
        }

        var translations: [Int: String] = [:]
        if let translationEdition, !translationEdition.isEmpty {
            translations = loadTranslationsForSurah(surahNumber: surahNumber, edition: translationEdition)
        }

        return rows.map { ayah in
            let extra = editionTexts[ayah.numberInSurah]
            return Ayah(
                number: ayah.number,
                surahNumber: ayah.surahNumber,
                numberInSurah: ayah.numberInSurah,
                textUthmani: ayah.textUthmani,
                textSimple: ayah.textSimple,
                textIndopak: edition == .indopak ? (extra?.text ?? ayah.textIndopak) : ayah.textIndopak,
                textShamarly: edition == .shamarly ? extra?.text : nil,
                juz: JuzBoundaries.juzOf(surah: ayah.surahNumber, ayah: ayah.numberInSurah),
                page: ayah.page,
                scriptPage: extra?.page ?? ayah.page,
                hizb: ayah.hizb,
                rub: ayah.rub,
                sajda: ayah.sajda,
                translation: translations[ayah.number],
                tafsir: nil
            )
        }
    }

    public func getAyah(surah: Int, ayah: Int, edition: MushafEdition = .madinah) -> Ayah? {
        lock.lock()
        defer { lock.unlock() }
        guard let db else { return nil }
        let sql = """
            SELECT ayahNumber, surahNumber, numberInSurah, textUthmani, textSimple, textIndopak, juz, page, hizb, rub, sajda
            FROM quran_ayahs WHERE surahNumber = ? AND numberInSurah = ? LIMIT 1
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else { return nil }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(surah))
        sqlite3_bind_int(stmt, 2, Int32(ayah))
        guard sqlite3_step(stmt) == SQLITE_ROW else { return nil }
        let base = readAyah(stmt)
        let editionPage = edition.hasOwnPagination ? getPageForAyah(surah: surah, ayah: ayah, edition: edition) : base.page
        let shamarlyText = edition == .shamarly ? loadEditionAyahText(surah: surah, ayah: ayah, edition: .shamarly) : nil
        let indopakText = edition == .indopak ? (loadEditionAyahText(surah: surah, ayah: ayah, edition: .indopak) ?? base.textIndopak) : base.textIndopak
        return Ayah(
            number: base.number,
            surahNumber: base.surahNumber,
            numberInSurah: base.numberInSurah,
            textUthmani: base.textUthmani,
            textSimple: base.textSimple,
            textIndopak: indopakText,
            textShamarly: shamarlyText,
            juz: JuzBoundaries.juzOf(surah: base.surahNumber, ayah: base.numberInSurah),
            page: base.page,
            scriptPage: editionPage,
            hizb: base.hizb,
            rub: base.rub,
            sajda: base.sajda
        )
    }

    public func getAyahByGlobalNumber(_ globalNumber: Int, edition: MushafEdition = .madinah) -> Ayah? {
        lock.lock()
        defer { lock.unlock() }
        guard let db else { return nil }
        let sql = """
            SELECT ayahNumber, surahNumber, numberInSurah, textUthmani, textSimple, textIndopak, juz, page, hizb, rub, sajda
            FROM quran_ayahs WHERE ayahNumber = ? LIMIT 1
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else { return nil }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(globalNumber))
        guard sqlite3_step(stmt) == SQLITE_ROW else { return nil }
        let base = readAyah(stmt)
        if edition.hasOwnPagination {
            return getAyah(surah: base.surahNumber, ayah: base.numberInSurah, edition: edition) ?? base
        }
        return base
    }

    public func getPageForAyah(surah: Int, ayah: Int, edition: MushafEdition) -> Int {
        lock.lock()
        defer { lock.unlock() }
        guard let db else { return QuranTables.pageForSurah(surah, edition: edition) }
        if !edition.hasOwnPagination {
            let sql = "SELECT page FROM quran_ayahs WHERE surahNumber = ? AND numberInSurah = ? LIMIT 1"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt {
                defer { sqlite3_finalize(stmt) }
                sqlite3_bind_int(stmt, 1, Int32(surah))
                sqlite3_bind_int(stmt, 2, Int32(ayah))
                if sqlite3_step(stmt) == SQLITE_ROW {
                    let p = Int(sqlite3_column_int(stmt, 0))
                    if p > 0 { return p }
                }
            }
        }
        let sql = "SELECT MIN(pageNumber) FROM quran_mushaf_words WHERE scriptType = ? AND surahNumber = ? AND ayahNumber = ?"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt {
            defer { sqlite3_finalize(stmt) }
            sqlite3_bind_text(stmt, 1, edition.scriptType, -1, sqliteTransient)
            sqlite3_bind_int(stmt, 2, Int32(surah))
            sqlite3_bind_int(stmt, 3, Int32(ayah))
            if sqlite3_step(stmt) == SQLITE_ROW && sqlite3_column_type(stmt, 0) != SQLITE_NULL {
                let p = Int(sqlite3_column_int(stmt, 0))
                if p > 0 { return p }
            }
        }
        return QuranTables.pageForSurah(surah, edition: edition)
    }

    public func getMushafPage(
        pageNumber: Int,
        edition: MushafEdition,
        shamarlyBreaks: MushafLineBreaksTable = .empty
    ) -> MushafPage {
        lock.lock()
        defer { lock.unlock() }

        let script = edition.scriptType
        let surahs = getAllSurahs()
        let surahMap = Dictionary(uniqueKeysWithValues: surahs.map { ($0.number, $0) })

        var layouts = loadLayoutRows(pageNumber: pageNumber, scriptType: script)
        var words = loadWordRows(pageNumber: pageNumber, scriptType: script)
        if layouts.isEmpty && edition == .madinah {
            layouts = loadLayoutRows(pageNumber: pageNumber, scriptType: "digital_khatt")
        }
        if words.isEmpty && edition == .madinah {
            words = loadWordRows(pageNumber: pageNumber, scriptType: "digital_khatt")
        }

        let wordsByLine = Dictionary(grouping: words, by: { $0.lineNumber })
        let totalLines = max(15, layouts.map(\.lineNumber).max() ?? 15)
        let layoutByLine = Dictionary(uniqueKeysWithValues: layouts.map { ($0.lineNumber, $0) })

        var mushafLines: [MushafLine] = []
        mushafLines.reserveCapacity(totalLines)

        for i in 1...totalLines {
            guard let row = layoutByLine[i] else {
                mushafLines.append(MushafLine(lineNumber: i, lineType: .empty))
                continue
            }
            let lineType: MushafLineType
            switch row.lineType {
            case "surah_name", "sura": lineType = .surahName
            case "basmallah", "bismillah": lineType = .basmallah
            case "ayah": lineType = .ayah
            default: lineType = .empty
            }
            let lineWords: [MushafWord]
            if lineType == .surahName {
                lineWords = []
            } else {
                lineWords = (wordsByLine[i] ?? []).map { raw in
                    let isMarker = raw.isMarker != 0 || (edition == .indopak && QuranTables.isIndopakAyahEndMarker(raw.text))
                    return MushafWord(
                        id: raw.positionInLine,
                        glyphCode: raw.glyphCode,
                        text: raw.text,
                        isMarker: isMarker,
                        surahNumber: raw.surahNumber,
                        ayahNumber: raw.ayahNumber,
                        wordPosition: raw.wordPosition
                    )
                }
            }
            let surahName = lineType == .surahName ? row.surahNumber.flatMap { surahMap[$0]?.name } : nil
            mushafLines.append(MushafLine(
                lineNumber: i,
                lineType: lineType,
                words: lineWords,
                isCentered: row.isCentered != 0,
                surahNumber: row.surahNumber,
                surahName: surahName,
                fontFile: row.fontFile ?? String(format: "QCF_P%03d.ttf", pageNumber)
            ))
        }

        if edition == .shamarly {
            let end = shamarlyBreaks.ends[pageNumber]
            let prevEnd = shamarlyBreaks.ends[pageNumber - 1]
            let edged: [MushafLine]?
            if end == nil && prevEnd == nil {
                edged = mushafLines
            } else {
                let prevLine = prevEnd != nil ? loadStoredEdgeLine(pageNumber: pageNumber - 1, scriptType: script, last: true) : nil
                let nextLine = end != nil ? loadStoredEdgeLine(pageNumber: pageNumber + 1, scriptType: script, last: false) : nil
                edged = MushafLineBreaksTable.moveEdges(
                    lines: mushafLines,
                    previousEnd: prevEnd,
                    previousLastLine: prevLine,
                    end: end,
                    nextFirstLine: nextLine
                )
            }
            if let edged, let printed = shamarlyBreaks.pages[pageNumber],
               let reflowed = MushafLineBreaksTable.reflow(lines: edged, counts: printed.counts, centred: printed.centred) {
                mushafLines = reflowed
            } else if let edged {
                mushafLines = edged
            }
        }

        var seenKeys = Set<Int>()
        var orderedPairs: [(Int, Int)] = []
        for line in mushafLines {
            for w in line.words {
                if let s = w.surahNumber, let a = w.ayahNumber, s > 0, a > 0 {
                    let key = s * 1000 + a
                    if seenKeys.insert(key).inserted {
                        orderedPairs.append((s, a))
                    }
                }
            }
        }

        var pageAyahs: [Ayah] = orderedPairs.compactMap { (s, a) in
            getAyah(surah: s, ayah: a, edition: edition) ?? Ayah(
                number: 0,
                surahNumber: s,
                numberInSurah: a,
                textUthmani: "",
                juz: QuranTables.juzForPage(pageNumber, edition: edition),
                page: pageNumber,
                scriptPage: pageNumber
            )
        }
        if pageAyahs.isEmpty {
            pageAyahs = loadAyahsForMadinahPage(pageNumber)
        }

        let primarySurahNum = mushafLines.flatMap(\.words).compactMap(\.surahNumber).first(where: { $0 > 0 })
            ?? layouts.compactMap(\.surahNumber).first(where: { $0 > 0 })
            ?? QuranTables.surahForPage(pageNumber, edition: edition)
        let primarySurahName = surahMap[primarySurahNum]?.name ?? ""
        let juz = QuranTables.juzForPage(pageNumber, edition: edition)

        return MushafPage(
            pageNumber: pageNumber,
            juzNumber: juz,
            surahName: primarySurahName,
            ayahs: pageAyahs,
            lines: mushafLines,
            scriptType: edition.scriptType
        )
    }

    public func getJuzSummaries(edition: MushafEdition) -> [JuzSummary] {
        lock.lock()
        defer { lock.unlock() }
        let surahs = getAllSurahs()
        guard surahs.count == 114 else { return [] }
        let surahMap = Dictionary(uniqueKeysWithValues: surahs.map { ($0.number, $0) })

        var summaries: [JuzSummary] = []
        summaries.reserveCapacity(30)

        for juzIndex in 0..<JuzBoundaries.count {
            let juzNumber = juzIndex + 1
            let start = JuzBoundaries.starts[juzIndex]
            let endSurah: Int
            let endAyah: Int
            if juzIndex + 1 < JuzBoundaries.count {
                let next = JuzBoundaries.starts[juzIndex + 1]
                if next.ayah > 1 {
                    endSurah = next.surah
                    endAyah = next.ayah - 1
                } else {
                    endSurah = max(1, next.surah - 1)
                    endAyah = surahMap[endSurah]?.numberOfAyahs ?? 1
                }
            } else {
                endSurah = 114
                endAyah = surahMap[114]?.numberOfAyahs ?? 6
            }

            var ayahCount = 0
            for s in start.surah...endSurah {
                let total = surahMap[s]?.numberOfAyahs ?? 0
                let fromA = (s == start.surah) ? start.ayah : 1
                let toA = (s == endSurah) ? endAyah : total
                ayahCount += max(0, toA - fromA + 1)
            }

            let startSurah = surahMap[start.surah]
            let endSurahObj = surahMap[endSurah]
            summaries.append(JuzSummary(
                number: juzNumber,
                startPage: QuranTables.pageForJuz(juzNumber, edition: edition),
                ayahCount: ayahCount,
                surahCount: endSurah - start.surah + 1,
                startSurahNumber: start.surah,
                startSurahName: startSurah?.name ?? "",
                startSurahEnglishName: startSurah?.englishName ?? "",
                startAyahInSurah: start.ayah,
                endSurahNumber: endSurah,
                endSurahName: endSurahObj?.name ?? "",
                endSurahEnglishName: endSurahObj?.englishName ?? "",
                endAyahInSurah: endAyah
            ))
        }
        return summaries
    }

    public func searchAyahsNormalized(rawQuery: String, limit: Int = 50) -> [Ayah] {
        let normalized = ArabicSearchText.normalizeQuery(rawQuery)
        guard normalized.count >= ArabicSearchText.minQueryLength else { return [] }
        let index = loadSearchIndex()
        var matches: [Ayah] = []
        matches.reserveCapacity(min(limit, 32))
        for row in index {
            if row.folded.contains(normalized) {
                matches.append(Ayah(
                    number: row.ayahNumber,
                    surahNumber: row.surahNumber,
                    numberInSurah: row.numberInSurah,
                    textUthmani: row.textUthmani,
                    juz: JuzBoundaries.juzOf(surah: row.surahNumber, ayah: row.numberInSurah),
                    page: row.page
                ))
                if matches.count >= limit { break }
            }
        }
        return matches
    }

    public func getTafsir(globalAyahNumber: Int, edition: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        if let exact = querySingleText("SELECT text FROM quran_tafsirs WHERE ayahNumber = ? AND edition = ? LIMIT 1", intParam: globalAyahNumber, textParam: edition) {
            return HtmlSanitizer.sanitize(exact)
        }
        if let translation = querySingleText("SELECT text FROM quran_translations WHERE ayahNumber = ? AND edition = ? LIMIT 1", intParam: globalAyahNumber, textParam: edition) {
            return HtmlSanitizer.sanitize(translation)
        }
        // Classical tafsirs group consecutive verses under the first ayah of the block.
        guard let db else { return nil }
        let sql = """
            SELECT text FROM quran_tafsirs
            WHERE edition = ?
              AND ayahNumber <= ?
              AND ayahNumber >= ?
              AND ayahNumber >= (
                  SELECT MIN(inner_surah.ayahNumber) FROM quran_ayahs inner_surah
                  WHERE inner_surah.surahNumber = (
                      SELECT target.surahNumber FROM quran_ayahs target WHERE target.ayahNumber = ?
                  )
              )
            ORDER BY ayahNumber DESC LIMIT 1
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else { return nil }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, edition, -1, sqliteTransient)
        sqlite3_bind_int(stmt, 2, Int32(globalAyahNumber))
        sqlite3_bind_int(stmt, 3, Int32(globalAyahNumber - Self.tafsirBlockMaxLookBack))
        sqlite3_bind_int(stmt, 4, Int32(globalAyahNumber))
        guard sqlite3_step(stmt) == SQLITE_ROW else { return nil }
        return HtmlSanitizer.sanitize(colText(stmt, 0))
    }

    public func getDownloadedTafsirEditions() -> Set<String> {
        lock.lock()
        defer { lock.unlock() }
        var result: Set<String> = [TafsirBook.builtInId]
        guard let db else { return result }
        let sql = "SELECT DISTINCT edition FROM quran_tafsirs"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt {
            defer { sqlite3_finalize(stmt) }
            while sqlite3_step(stmt) == SQLITE_ROW {
                let ed = colText(stmt, 0)
                if !ed.isEmpty { result.insert(ed) }
            }
        }
        return result
    }

    public func replaceEdition(edition: String, entries: [TafsirEntry]) throws {
        lock.lock()
        defer { lock.unlock() }
        guard let db else { throw QuranDatabaseError.executeFailed("Database closed") }

        try exec("BEGIN IMMEDIATE TRANSACTION")
        do {
            try deleteRows(table: "quran_tafsirs", edition: edition)
            try deleteRows(table: "quran_translations", edition: edition)

            let insertTafsirSQL = "INSERT OR REPLACE INTO quran_tafsirs (ayahNumber, edition, text) VALUES (?, ?, ?)"
            let insertTransSQL = "INSERT OR REPLACE INTO quran_translations (ayahNumber, edition, text) VALUES (?, ?, ?)"
            var tStmt: OpaquePointer?
            var trStmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, insertTafsirSQL, -1, &tStmt, nil) == SQLITE_OK, let tStmt,
                  sqlite3_prepare_v2(db, insertTransSQL, -1, &trStmt, nil) == SQLITE_OK, let trStmt else {
                if let tStmt { sqlite3_finalize(tStmt) }
                if let trStmt { sqlite3_finalize(trStmt) }
                throw QuranDatabaseError.prepareFailed(String(cString: sqlite3_errmsg(db)))
            }
            defer {
                sqlite3_finalize(tStmt)
                sqlite3_finalize(trStmt)
            }

            for entry in entries {
                sqlite3_reset(tStmt)
                sqlite3_bind_int(tStmt, 1, Int32(entry.ayahNumber))
                sqlite3_bind_text(tStmt, 2, edition, -1, sqliteTransient)
                sqlite3_bind_text(tStmt, 3, entry.text, -1, sqliteTransient)
                if sqlite3_step(tStmt) != SQLITE_DONE {
                    throw QuranDatabaseError.executeFailed(String(cString: sqlite3_errmsg(db)))
                }

                sqlite3_reset(trStmt)
                sqlite3_bind_int(trStmt, 1, Int32(entry.ayahNumber))
                sqlite3_bind_text(trStmt, 2, edition, -1, sqliteTransient)
                sqlite3_bind_text(trStmt, 3, entry.text, -1, sqliteTransient)
                if sqlite3_step(trStmt) != SQLITE_DONE {
                    throw QuranDatabaseError.executeFailed(String(cString: sqlite3_errmsg(db)))
                }
            }
            try exec("COMMIT")
        } catch {
            try? exec("ROLLBACK")
            throw error
        }
    }

    public func deleteTafsirEdition(_ edition: String) throws {
        guard edition != TafsirBook.builtInId else { return }
        lock.lock()
        defer { lock.unlock() }
        try exec("BEGIN IMMEDIATE TRANSACTION")
        do {
            try deleteRows(table: "quran_tafsirs", edition: edition)
            try deleteRows(table: "quran_translations", edition: edition)
            try exec("COMMIT")
        } catch {
            try? exec("ROLLBACK")
            throw error
        }
    }

    public func getAyahStartPages(edition: MushafEdition) -> [Int: Int] {
        lock.lock()
        defer { lock.unlock() }
        guard edition.hasOwnPagination else { return [:] }
        if let cached = ayahStartPagesCache[edition.scriptType] { return cached }
        guard let db else { return [:] }

        let sql = """
            SELECT a.ayahNumber, MIN(w.pageNumber)
            FROM quran_mushaf_words w
            JOIN quran_ayahs a ON a.surahNumber = w.surahNumber AND a.numberInSurah = w.ayahNumber
            WHERE w.scriptType = ? AND w.surahNumber > 0 AND w.ayahNumber > 0
            GROUP BY a.ayahNumber
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else { return [:] }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, edition.scriptType, -1, sqliteTransient)

        var map: [Int: Int] = [:]
        map.reserveCapacity(6236)
        while sqlite3_step(stmt) == SQLITE_ROW {
            map[Int(sqlite3_column_int(stmt, 0))] = Int(sqlite3_column_int(stmt, 1))
        }
        ayahStartPagesCache[edition.scriptType] = map
        return map
    }

    // MARK: - Private SQLite helpers

    private struct LayoutRow {
        let pageNumber: Int
        let lineNumber: Int
        let lineType: String
        let isCentered: Int
        let surahNumber: Int?
        let fontFile: String?
    }

    private struct WordRow {
        let pageNumber: Int
        let lineNumber: Int
        let positionInLine: Int
        let glyphCode: Int
        let text: String
        let isMarker: Int
        let surahNumber: Int?
        let ayahNumber: Int?
        let wordPosition: Int?
    }

    private func loadSearchIndex() -> [FoldedAyahRow] {
        lock.lock()
        if let searchIndex {
            lock.unlock()
            return searchIndex
        }
        guard let db else {
            lock.unlock()
            return []
        }
        let sql = "SELECT ayahNumber, surahNumber, numberInSurah, page, textUthmani FROM quran_ayahs ORDER BY ayahNumber ASC"
        var stmt: OpaquePointer?
        var built: [FoldedAyahRow] = []
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt {
            defer { sqlite3_finalize(stmt) }
            built.reserveCapacity(6236)
            while sqlite3_step(stmt) == SQLITE_ROW {
                let uthmani = colText(stmt, 4)
                built.append(FoldedAyahRow(
                    ayahNumber: Int(sqlite3_column_int(stmt, 0)),
                    surahNumber: Int(sqlite3_column_int(stmt, 1)),
                    numberInSurah: Int(sqlite3_column_int(stmt, 2)),
                    page: Int(sqlite3_column_int(stmt, 3)),
                    textUthmani: uthmani,
                    folded: ArabicSearchText.normalize(uthmani)
                ))
            }
        }
        searchIndex = built
        lock.unlock()
        return built
    }

    private func loadLayoutRows(pageNumber: Int, scriptType: String) -> [LayoutRow] {
        guard let db else { return [] }
        let sql = "SELECT pageNumber, lineNumber, lineType, isCentered, surahNumber, fontFile FROM quran_mushaf_lines WHERE pageNumber = ? AND scriptType = ? ORDER BY lineNumber ASC"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else { return [] }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(pageNumber))
        sqlite3_bind_text(stmt, 2, scriptType, -1, sqliteTransient)
        var rows: [LayoutRow] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            rows.append(LayoutRow(
                pageNumber: Int(sqlite3_column_int(stmt, 0)),
                lineNumber: Int(sqlite3_column_int(stmt, 1)),
                lineType: colText(stmt, 2),
                isCentered: Int(sqlite3_column_int(stmt, 3)),
                surahNumber: colOptionalInt(stmt, 4),
                fontFile: colOptionalText(stmt, 5)
            ))
        }
        return rows
    }

    private func loadWordRows(pageNumber: Int, scriptType: String) -> [WordRow] {
        guard let db else { return [] }
        let sql = """
            SELECT pageNumber, lineNumber, positionInLine, glyphCode, text, isMarker, surahNumber, ayahNumber, wordPosition
            FROM quran_mushaf_words WHERE pageNumber = ? AND scriptType = ?
            ORDER BY lineNumber ASC, positionInLine ASC
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else { return [] }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(pageNumber))
        sqlite3_bind_text(stmt, 2, scriptType, -1, sqliteTransient)
        var rows: [WordRow] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            rows.append(WordRow(
                pageNumber: Int(sqlite3_column_int(stmt, 0)),
                lineNumber: Int(sqlite3_column_int(stmt, 1)),
                positionInLine: Int(sqlite3_column_int(stmt, 2)),
                glyphCode: Int(sqlite3_column_int(stmt, 3)),
                text: colText(stmt, 4),
                isMarker: Int(sqlite3_column_int(stmt, 5)),
                surahNumber: colOptionalInt(stmt, 6),
                ayahNumber: colOptionalInt(stmt, 7),
                wordPosition: colOptionalInt(stmt, 8)
            ))
        }
        return rows
    }

    private func loadStoredEdgeLine(pageNumber: Int, scriptType: String, last: Bool) -> MushafLine? {
        guard pageNumber >= 1 else { return nil }
        let words = loadWordRows(pageNumber: pageNumber, scriptType: scriptType)
        guard !words.isEmpty else { return nil }
        let grouped = Dictionary(grouping: words, by: \.lineNumber)
        let targetLineNum = last ? grouped.keys.max() : grouped.keys.min()
        guard let targetLineNum, let lineWords = grouped[targetLineNum] else { return nil }
        return MushafLine(
            lineNumber: targetLineNum,
            lineType: .ayah,
            words: lineWords.map { raw in
                MushafWord(
                    id: raw.positionInLine,
                    glyphCode: raw.glyphCode,
                    text: raw.text,
                    isMarker: raw.isMarker != 0,
                    surahNumber: raw.surahNumber,
                    ayahNumber: raw.ayahNumber,
                    wordPosition: raw.wordPosition
                )
            }
        )
    }

    private func loadEditionAyahTexts(surahNumber: Int, edition: MushafEdition) -> [Int: (text: String, page: Int)] {
        guard let db else { return [:] }
        let fromPage = QuranTables.pageForSurah(surahNumber, edition: edition)
        let toPage = surahNumber < 114 ? QuranTables.pageForSurah(surahNumber + 1, edition: edition) : edition.totalPages
        let sql = """
            SELECT ayahNumber, pageNumber, text FROM quran_mushaf_words
            WHERE scriptType = ? AND surahNumber = ? AND pageNumber BETWEEN ? AND ?
            ORDER BY pageNumber ASC, lineNumber ASC, positionInLine ASC
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else { return [:] }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, edition.scriptType, -1, sqliteTransient)
        sqlite3_bind_int(stmt, 2, Int32(surahNumber))
        sqlite3_bind_int(stmt, 3, Int32(fromPage))
        sqlite3_bind_int(stmt, 4, Int32(toPage))

        var wordsByAyah: [Int: [String]] = [:]
        var firstPageByAyah: [Int: Int] = [:]
        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let aNum = colOptionalInt(stmt, 0), aNum > 0 else { continue }
            let pNum = Int(sqlite3_column_int(stmt, 1))
            let txt = colText(stmt, 2)
            if firstPageByAyah[aNum] == nil { firstPageByAyah[aNum] = pNum }
            wordsByAyah[aNum, default: []].append(txt)
        }
        var out: [Int: (text: String, page: Int)] = [:]
        for (aNum, list) in wordsByAyah {
            out[aNum] = (list.joined(separator: " "), firstPageByAyah[aNum] ?? fromPage)
        }
        return out
    }

    private func loadEditionAyahText(surah: Int, ayah: Int, edition: MushafEdition) -> String? {
        guard let db else { return nil }
        let sql = """
            SELECT text FROM quran_mushaf_words
            WHERE scriptType = ? AND surahNumber = ? AND ayahNumber = ?
            ORDER BY pageNumber ASC, lineNumber ASC, positionInLine ASC
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else { return nil }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, edition.scriptType, -1, sqliteTransient)
        sqlite3_bind_int(stmt, 2, Int32(surah))
        sqlite3_bind_int(stmt, 3, Int32(ayah))
        var words: [String] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            words.append(colText(stmt, 0))
        }
        return words.isEmpty ? nil : words.joined(separator: " ")
    }

    private func loadTranslationsForSurah(surahNumber: Int, edition: String) -> [Int: String] {
        guard let db else { return [:] }
        let sql = """
            SELECT t.ayahNumber, t.text FROM quran_translations t
            JOIN quran_ayahs a ON a.ayahNumber = t.ayahNumber
            WHERE a.surahNumber = ? AND t.edition = ?
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else { return [:] }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(surahNumber))
        sqlite3_bind_text(stmt, 2, edition, -1, sqliteTransient)
        var map: [Int: String] = [:]
        while sqlite3_step(stmt) == SQLITE_ROW {
            map[Int(sqlite3_column_int(stmt, 0))] = HtmlSanitizer.sanitize(colText(stmt, 1))
        }
        return map
    }

    private func loadAyahsForMadinahPage(_ pageNumber: Int) -> [Ayah] {
        guard let db else { return [] }
        let sql = """
            SELECT ayahNumber, surahNumber, numberInSurah, textUthmani, textSimple, textIndopak, juz, page, hizb, rub, sajda
            FROM quran_ayahs WHERE page = ? ORDER BY ayahNumber ASC
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else { return [] }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(pageNumber))
        var rows: [Ayah] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            rows.append(readAyah(stmt))
        }
        return rows
    }

    private func readAyah(_ stmt: OpaquePointer) -> Ayah {
        let sNum = Int(sqlite3_column_int(stmt, 1))
        let aNum = Int(sqlite3_column_int(stmt, 2))
        let page = Int(sqlite3_column_int(stmt, 7))
        return Ayah(
            number: Int(sqlite3_column_int(stmt, 0)),
            surahNumber: sNum,
            numberInSurah: aNum,
            textUthmani: colText(stmt, 3),
            textSimple: colOptionalText(stmt, 4) ?? "",
            textIndopak: colOptionalText(stmt, 5),
            juz: JuzBoundaries.juzOf(surah: sNum, ayah: aNum),
            page: page,
            scriptPage: page,
            hizb: colOptionalInt(stmt, 8) ?? 1,
            rub: colOptionalInt(stmt, 9) ?? 1,
            sajda: (colOptionalInt(stmt, 10) ?? 0) != 0
        )
    }

    private func querySingleText(_ sql: String, intParam: Int, textParam: String) -> String? {
        guard let db else { return nil }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else { return nil }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(intParam))
        sqlite3_bind_text(stmt, 2, textParam, -1, sqliteTransient)
        guard sqlite3_step(stmt) == SQLITE_ROW else { return nil }
        return colOptionalText(stmt, 0)
    }

    private func deleteRows(table: String, edition: String) throws {
        guard let db else { return }
        let sql = "DELETE FROM \(table) WHERE edition = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else {
            throw QuranDatabaseError.prepareFailed(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, edition, -1, sqliteTransient)
        if sqlite3_step(stmt) != SQLITE_DONE {
            throw QuranDatabaseError.executeFailed(String(cString: sqlite3_errmsg(db)))
        }
    }

    private func exec(_ sql: String) throws {
        guard let db else { return }
        var errMsg: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &errMsg) != SQLITE_OK {
            let msg = errMsg.map { String(cString: $0) } ?? "SQLite error"
            sqlite3_free(errMsg)
            throw QuranDatabaseError.executeFailed(msg)
        }
    }

    private func scalarInt(_ sql: String) -> Int {
        guard let db else { return 0 }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else { return 0 }
        defer { sqlite3_finalize(stmt) }
        return sqlite3_step(stmt) == SQLITE_ROW ? Int(sqlite3_column_int(stmt, 0)) : 0
    }

    private func colText(_ stmt: OpaquePointer, _ idx: Int32) -> String {
        guard let cStr = sqlite3_column_text(stmt, idx) else { return "" }
        return String(cString: cStr)
    }

    private func colOptionalText(_ stmt: OpaquePointer, _ idx: Int32) -> String? {
        guard sqlite3_column_type(stmt, idx) != SQLITE_NULL,
              let cStr = sqlite3_column_text(stmt, idx) else { return nil }
        return String(cString: cStr)
    }

    private func colOptionalInt(_ stmt: OpaquePointer, _ idx: Int32) -> Int? {
        guard sqlite3_column_type(stmt, idx) != SQLITE_NULL else { return nil }
        return Int(sqlite3_column_int(stmt, idx))
    }
}
