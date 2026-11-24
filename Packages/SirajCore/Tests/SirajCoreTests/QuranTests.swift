import XCTest
import SQLite3
import zlib
@testable import SirajCore

final class QuranTests: XCTestCase {
    func testMushafEditionResolutionAndPagination() {
        XCTAssertEqual(MushafEdition.resolve("kfgqpc_v1"), .madinah)
        XCTAssertEqual(MushafEdition.resolve("indopak"), .indopak)
        XCTAssertEqual(MushafEdition.resolve("nastaleeq"), .indopak)
        XCTAssertEqual(MushafEdition.resolve("shamarly"), .shamarly)
        XCTAssertEqual(MushafEdition.resolve("unknown"), .madinah)

        XCTAssertEqual(QuranTables.pageForSurah(1, edition: .madinah), 1)
        XCTAssertEqual(QuranTables.pageForSurah(114, edition: .madinah), 604)
        XCTAssertEqual(QuranTables.pageForSurah(114, edition: .indopak), 610)
        XCTAssertEqual(QuranTables.pageForSurah(114, edition: .shamarly), 521)

        XCTAssertEqual(QuranTables.juzForPage(1, edition: .madinah), 1)
        XCTAssertEqual(QuranTables.juzForPage(582, edition: .madinah), 30)
        XCTAssertEqual(QuranTables.juzForPage(586, edition: .indopak), 30)
        XCTAssertEqual(QuranTables.juzForPage(497, edition: .shamarly), 30)

        XCTAssertEqual(JuzBoundaries.juzOf(surah: 1, ayah: 1), 1)
        XCTAssertEqual(JuzBoundaries.juzOf(surah: 2, ayah: 255), 3)
        XCTAssertEqual(JuzBoundaries.juzOf(surah: 78, ayah: 1), 30)
        XCTAssertEqual(JuzBoundaries.juzOf(surah: 114, ayah: 6), 30)
    }

    func testArabicSearchNormalizationAndMatchRanges() {
        let uthmani = "بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِيمِ"
        let folded = ArabicSearchText.normalize(uthmani)
        XCTAssertEqual(folded, "بسم الله الرحمن الرحيم")

        let query = ArabicSearchText.normalizeQuery("  الرحمن  ")
        let ranges = ArabicSearchText.matchRanges(in: uthmani, normalizedQuery: query)
        XCTAssertEqual(ranges.count, 1)
        XCTAssertTrue(String(uthmani[ranges[0]]).contains("ٱلرَّحۡمَـٰنِ"))
    }

    func testSurahNamesAndSearchParser() {
        let fatiha = Surah(number: 1, name: "سُورَةُ ٱلْفَاتِحَةِ", englishName: "Al-Fātiĥah", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationType: "Meccan")
        let baqarah = Surah(number: 2, name: "سُورَةُ البَقَرَةِ", englishName: "Al-Baqarah", englishNameTranslation: "The Cow", numberOfAyahs: 286, revelationType: "Medinan")
        let imran = Surah(number: 3, name: "سُورَةُ آلِ عِمْرَانَ", englishName: "Āli `Imrān", englishNameTranslation: "Family of Imran", numberOfAyahs: 200, revelationType: "Medinan")

        XCTAssertEqual(fatiha.englishName, "Al-Fātiḥah")
        XCTAssertEqual(imran.englishName, "Āli ʿImrān")
        XCTAssertTrue(SurahNames.matches(imran, query: "imran"))
        XCTAssertTrue(SurahNames.matches(fatiha, query: "الفاتحه"))
        XCTAssertTrue(SurahNames.matches(baqarah, query: "2"))
        XCTAssertFalse(SurahNames.matches(baqarah, query: "20"))

        let surahs = [fatiha, baqarah, imran]
        let ref1 = QuranSearchParser.parseExactAyah("2:255", surahs: surahs)
        XCTAssertEqual(ref1?.surahNumber, 2)
        XCTAssertEqual(ref1?.ayahNumber, 255)

        let ref2 = QuranSearchParser.parseExactAyah("البقرة ٢٥٥", surahs: surahs)
        XCTAssertEqual(ref2?.surahNumber, 2)
        XCTAssertEqual(ref2?.ayahNumber, 255)

        XCTAssertEqual(QuranSearchParser.parseDirectPage("صفحة ٤٢", totalPages: 604), 42)
        XCTAssertEqual(QuranSearchParser.parseDirectPage("page 610", totalPages: 610), 610)
        XCTAssertNil(QuranSearchParser.parseDirectPage("999", totalPages: 604))
    }

    func testShamarlyAndLineBreaksAndTafsirParser() {
        XCTAssertEqual(ShamarlyText.openTanween("هُد\u{0657}ى"), "هُد\u{08F0}ى")
        XCTAssertEqual(ShamarlyText.dotlessFinalYa("فِي"), "فِى")
        let qWord = ShamarlyText.word("\u{06DE}وَقَالَ")
        XCTAssertTrue(qWord.opensQuarter)
        XCTAssertTrue(qWord.text.hasPrefix("* "))

        let breaks = MushafLineBreaksTable.parse("""
            1 3,2c
            2 ends 1:2:4
            """)
        XCTAssertEqual(breaks.pages[1]?.counts, [3, 2])
        XCTAssertEqual(breaks.pages[1]?.centred, [false, true])
        XCTAssertEqual(breaks.ends[2], MushafLineBreaksTable.WordKey(surah: 1, ayah: 2, word: 4))

        let fawazJSON = Data(#"{"quran":[{"chapter":1,"verse":1,"ayah":1,"text":"In the name of Allah"}]}"#.utf8)
        XCTAssertEqual(TafsirPayloadParser.parse(data: fawazJSON).first?.text, "In the name of Allah")

        let cloudJSON = Data(#"{"code":200,"data":{"surahs":[{"number":1,"ayahs":[{"number":1,"text":"Praise be to Allah"}]}]}}"#.utf8)
        XCTAssertEqual(TafsirPayloadParser.parse(data: cloudJSON).first?.text, "Praise be to Allah")

        let flatJSON = Data(#"[{"ayah":7,"text":"Flat commentary"}]"#.utf8)
        XCTAssertEqual(TafsirPayloadParser.parse(data: flatJSON).first?.ayahNumber, 7)
    }

    func testGzipAndZipUnpackerRoundTripAndZipSlipRejection() throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("siraj-unpack-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        // 1. Gzip compress + gunzipFile round-trip
        let original = Data(String(repeating: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\n", count: 200).utf8)
        let gzURL = tmp.appendingPathComponent("sample.txt.gz")
        let outURL = tmp.appendingPathComponent("sample.txt")
        let gzData = try gzipCompress(original)
        try gzData.write(to: gzURL)

        try QuranArchiveUnpacker.gunzipFile(source: gzURL, destination: outURL)
        let unpacked = try Data(contentsOf: outURL)
        XCTAssertEqual(unpacked, original)

        // 2. Stored ZIP unpack round-trip
        let zipURL = tmp.appendingPathComponent("fonts.zip")
        let extractDir = tmp.appendingPathComponent("extracted", isDirectory: true)
        try makeMinimalZip(entries: [("nested/QCF_P001.ttf", Data("FAKE_TTF_DATA".utf8))]).write(to: zipURL)
        try QuranArchiveUnpacker.unzipDirectory(source: zipURL, destination: extractDir, flattenBasename: true)
        XCTAssertEqual(try Data(contentsOf: extractDir.appendingPathComponent("QCF_P001.ttf")), Data("FAKE_TTF_DATA".utf8))

        // 3. Zip-slip rejection
        let evilZipURL = tmp.appendingPathComponent("evil.zip")
        try makeMinimalZip(entries: [("../escape.txt", Data("bad".utf8))]).write(to: evilZipURL)
        XCTAssertThrowsError(try QuranArchiveUnpacker.unzipDirectory(source: evilZipURL, destination: extractDir)) { err in
            XCTAssertEqual(err as? QuranArchiveError, .unsafeZipPath("../escape.txt"))
        }
    }

    func testQuranDatabaseQueriesAndTafsirFallback() throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("siraj-db-\(UUID().uuidString).db")
        defer { try? FileManager.default.removeItem(at: tmp) }

        var rawDB: OpaquePointer?
        XCTAssertEqual(sqlite3_open(tmp.path, &rawDB), SQLITE_OK)
        let schema = """
            CREATE TABLE quran_surahs (number INTEGER PRIMARY KEY, name TEXT, englishName TEXT, englishNameTranslation TEXT, numberOfAyahs INTEGER, revelationType TEXT);
            CREATE TABLE quran_ayahs (ayahNumber INTEGER PRIMARY KEY, surahNumber INTEGER, numberInSurah INTEGER, textUthmani TEXT, textSimple TEXT, textIndopak TEXT, juz INTEGER, page INTEGER, hizb INTEGER, rub INTEGER, sajda INTEGER);
            CREATE TABLE quran_mushaf_lines (pageNumber INTEGER, lineNumber INTEGER, scriptType TEXT, lineType TEXT, isCentered INTEGER, surahNumber INTEGER, fontFile TEXT);
            CREATE TABLE quran_mushaf_words (pageNumber INTEGER, lineNumber INTEGER, positionInLine INTEGER, scriptType TEXT, glyphCode INTEGER, text TEXT, isMarker INTEGER, surahNumber INTEGER, ayahNumber INTEGER, wordPosition INTEGER);
            CREATE TABLE quran_tafsirs (ayahNumber INTEGER, edition TEXT, text TEXT, PRIMARY KEY (ayahNumber, edition));
            CREATE TABLE quran_translations (ayahNumber INTEGER, edition TEXT, text TEXT, PRIMARY KEY (ayahNumber, edition));
            INSERT INTO quran_surahs VALUES (1, 'سُورَةُ ٱلْفَاتِحَةِ', 'Al-Faatiha', 'The Opening', 7, 'Meccan');
            INSERT INTO quran_ayahs VALUES (1, 1, 1, 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِيمِ', 'بسم الله الرحمن الرحيم', NULL, 1, 1, 1, 1, 0);
            INSERT INTO quran_ayahs VALUES (2, 1, 2, 'ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَـٰلَمِينَ', 'الحمد لله رب العالمين', NULL, 1, 1, 1, 1, 0);
            INSERT INTO quran_mushaf_lines VALUES (1, 1, 'kfgqpc_v1', 'surah_name', 1, 1, 'QCF_P001.ttf');
            INSERT INTO quran_mushaf_lines VALUES (1, 2, 'kfgqpc_v1', 'ayah', 1, 1, 'QCF_P001.ttf');
            INSERT INTO quran_mushaf_words VALUES (1, 2, 1, 'kfgqpc_v1', 1, 'بِسۡمِ', 0, 1, 1, 1);
            INSERT INTO quran_mushaf_words VALUES (1, 2, 2, 'kfgqpc_v1', 2, '١', 1, 1, 1, 2);
            INSERT INTO quran_tafsirs VALUES (1, 'ar.muyassar', '<p>تفسير البسملة</p>');
            """
        XCTAssertEqual(sqlite3_exec(rawDB, schema, nil, nil, nil), SQLITE_OK)
        sqlite3_close(rawDB)

        let db = try QuranDatabase(path: tmp.path)
        XCTAssertEqual(db.getAllSurahs().count, 1)
        XCTAssertEqual(db.getAyahsForSurah(1).count, 2)

        let page = db.getMushafPage(pageNumber: 1, edition: .madinah)
        XCTAssertEqual(page.pageNumber, 1)
        XCTAssertEqual(page.lines.first?.lineType, .surahName)
        XCTAssertEqual(page.lines[1].words.count, 2)

        // Exact tafsir strips HTML tags, and ayah 2 falls back to ayah 1's covering block in the same surah.
        XCTAssertEqual(db.getTafsir(globalAyahNumber: 1, edition: "ar.muyassar"), "تفسير البسملة")
        XCTAssertEqual(db.getTafsir(globalAyahNumber: 2, edition: "ar.muyassar"), "تفسير البسملة")

        try db.replaceEdition(edition: "en.asad", entries: [TafsirEntry(ayahNumber: 1, text: "In the name of God")])
        XCTAssertTrue(db.getDownloadedTafsirEditions().contains("en.asad"))
        XCTAssertEqual(db.getTafsir(globalAyahNumber: 1, edition: "en.asad"), "In the name of God")

        let hits = db.searchAyahsNormalized(rawQuery: "الرحمن")
        XCTAssertEqual(hits.count, 1)
        XCTAssertEqual(hits.first?.number, 1)
    }

    // MARK: - Test Archive Builders

    private func gzipCompress(_ input: Data) throws -> Data {
        var stream = z_stream()
        let status = deflateInit2_(&stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, 15 + 16, 8, Z_DEFAULT_STRATEGY, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
        XCTAssertEqual(status, Z_OK)
        defer { deflateEnd(&stream) }

        var output = Data()
        let bufSize = 16384
        var buffer = [UInt8](repeating: 0, count: bufSize)
        input.withUnsafeBytes { rawIn in
            stream.next_in = UnsafeMutablePointer(mutating: rawIn.bindMemory(to: Bytef.self).baseAddress)
            stream.avail_in = uInt(input.count)
            var ret: Int32 = Z_OK
            repeat {
                buffer.withUnsafeMutableBytes { rawOut in
                    stream.next_out = rawOut.bindMemory(to: Bytef.self).baseAddress
                    stream.avail_out = uInt(bufSize)
                    ret = deflate(&stream, Z_FINISH)
                }
                let produced = bufSize - Int(stream.avail_out)
                if produced > 0 { output.append(contentsOf: buffer[0..<produced]) }
            } while ret == Z_OK
            XCTAssertEqual(ret, Z_STREAM_END)
        }
        return output
    }

    private func makeMinimalZip(entries: [(String, Data)]) -> Data {
        var out = Data()
        var cd = Data()

        func appendU16(_ d: inout Data, _ v: UInt16) {
            d.append(UInt8(v & 0xFF))
            d.append(UInt8((v >> 8) & 0xFF))
        }
        func appendU32(_ d: inout Data, _ v: UInt32) {
            d.append(UInt8(v & 0xFF))
            d.append(UInt8((v >> 8) & 0xFF))
            d.append(UInt8((v >> 16) & 0xFF))
            d.append(UInt8((v >> 24) & 0xFF))
        }

        for (name, payload) in entries {
            let localOffset = UInt32(out.count)
            let nameData = Data(name.utf8)
            let crc = QuranArchiveUnpacker.crc32Checksum(payload)

            appendU32(&out, 0x04034b50)
            appendU16(&out, 20)
            appendU16(&out, 0)
            appendU16(&out, 0) // stored
            appendU16(&out, 0)
            appendU16(&out, 0)
            appendU32(&out, crc)
            appendU32(&out, UInt32(payload.count))
            appendU32(&out, UInt32(payload.count))
            appendU16(&out, UInt16(nameData.count))
            appendU16(&out, 0)
            out.append(nameData)
            out.append(payload)

            appendU32(&cd, 0x02014b50)
            appendU16(&cd, 20)
            appendU16(&cd, 20)
            appendU16(&cd, 0)
            appendU16(&cd, 0)
            appendU16(&cd, 0)
            appendU16(&cd, 0)
            appendU32(&cd, crc)
            appendU32(&cd, UInt32(payload.count))
            appendU32(&cd, UInt32(payload.count))
            appendU16(&cd, UInt16(nameData.count))
            appendU16(&cd, 0)
            appendU16(&cd, 0)
            appendU16(&cd, 0)
            appendU16(&cd, 0)
            appendU32(&cd, 0)
            appendU32(&cd, localOffset)
            cd.append(nameData)
        }

        let cdOffset = UInt32(out.count)
        let cdSize = UInt32(cd.count)
        out.append(cd)

        appendU32(&out, 0x06054b50)
        appendU16(&out, 0)
        appendU16(&out, 0)
        appendU16(&out, UInt16(entries.count))
        appendU16(&out, UInt16(entries.count))
        appendU32(&out, cdSize)
        appendU32(&out, cdOffset)
        appendU16(&out, 0)
        return out
    }
}
