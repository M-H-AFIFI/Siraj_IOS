import XCTest
@testable import SirajCore

final class AudioAndKhatmaTests: XCTestCase {
    func testReciterCatalogAndURLs() {
        XCTAssertEqual(Reciter.readerReciters.count, 34)
        XCTAssertEqual(Reciter.allListeningReciters.count, 75)
        XCTAssertEqual(Reciter.byId("ar.alafasy").englishName, "Mishary Rashid Alafasy")
        XCTAssertEqual(Reciter.byId("unknown").id, "ar.alafasy")

        XCTAssertTrue(ReciterAudioURLs.hasAyahAudio("ar.alafasy"))
        XCTAssertFalse(ReciterAudioURLs.hasAyahAudio("ar.khalidaljalil"))
        XCTAssertEqual(
            ReciterAudioURLs.ayahAudioURL(reciterId: "ar.alafasy", surah: 2, ayah: 255),
            "https://everyayah.com/data/Alafasy_128kbps/002255.mp3"
        )
        // qdc/ folders use unpadded surah filenames.
        XCTAssertEqual(
            ReciterAudioURLs.surahAudioURL(reciterId: "ar.khalidaljalil", surah: 1),
            "https://download.quranicaudio.com/qdc/khalid_jalil/murattal/mp3/1.mp3"
        )
        XCTAssertEqual(
            ReciterAudioURLs.surahAudioURL(reciterId: "ar.alafasy", surah: 1),
            "https://audio-cdn.tarteel.ai/quran/surah/alafasy/murattal/mp3/001.mp3"
        )
        // Listening library uses continuous Alafasy recordings instead of stitched reader tracks.
        let listeningUrls = ReciterAudioURLs.listeningSurahURLs(reciterId: "ar.alafasy", surah: 18)
        XCTAssertEqual(listeningUrls.count, 2)
        XCTAssertTrue(listeningUrls[0].contains("mishaari_raashid_al_3afaasee/018.mp3"))
    }

    func testListeningCatalogAndReciterGrouping() {
        XCTAssertEqual(ListeningCatalog.rareCollections.count, 6)
        XCTAssertEqual(ListeningCatalog.abdulAzimZaher.tracks.count, 13)
        XCTAssertEqual(ListeningCatalog.islamSobhi.tracks.count, 109)

        let groups = ListenTitles.buildReciterGroups(language: "ar")
        let husaryGroup = groups.first { $0.key == "ar.husary" }
        XCTAssertNotNil(husaryGroup)
        XCTAssertEqual(husaryGroup?.versions.count, 4) // Hafs, Mujawwad, Warsh, Qalun

        let basitGroup = groups.first { $0.key == "ar.abdulbasitmurattal" }
        XCTAssertEqual(basitGroup?.versions.count, 3)

        XCTAssertEqual(ListenTitles.letterOf("أحمد العجمي", language: "ar"), "ا")
        XCTAssertEqual(ListenTitles.letterOf("الشيخ عبد الباسط", language: "ar"), "ع")
    }

    func testKhatmaPlannerDistributionAndRescheduling() {
        var covered = 0
        var prevEnd = 0
        for day in 0..<30 {
            let range = KhatmaPlanner.pagesForDay(dayIndex: day, spanDays: 30)
            XCTAssertNotNil(range)
            if let range {
                XCTAssertEqual(range.lowerBound, prevEnd + 1)
                XCTAssertTrue(range.count == 20 || range.count == 21)
                prevEnd = range.upperBound
                covered += range.count
            }
        }
        XCTAssertEqual(covered, 604)
        XCTAssertEqual(prevEnd, 604)
        XCTAssertNil(KhatmaPlanner.pagesForDay(dayIndex: 30, spanDays: 30))

        let startDay: Int64 = 20_500
        let record = KhatmaRecord(
            startEpochDay: startDay,
            anchorEpochDay: startDay,
            anchorPages: 0,
            endEpochDay: startDay + 29,
            pagesCompleted: 20,
            lastReadEpochDay: startDay,
            streak: 1
        )
        let planOnDay3 = KhatmaPlanner.buildPlan(
            record: record,
            todayEpochDay: startDay + 2,
            khatmasCompleted: 0,
            surahs: []
        )
        // By the end of day 2 (index 1), expectedPages = 40 -> 20 pages behind.
        XCTAssertEqual(planOnDay3.expectedPages, 40)
        XCTAssertEqual(planOnDay3.pagesBehind, 20)
        XCTAssertTrue(planOnDay3.isBehind)

        let rescheduled = KhatmaPlanner.rescheduled(record: record, todayEpochDay: startDay + 2)
        let newPlan = KhatmaPlanner.buildPlan(
            record: rescheduled,
            todayEpochDay: startDay + 2,
            khatmasCompleted: 0,
            surahs: []
        )
        XCTAssertEqual(newPlan.pagesBehind, 0)
        XCTAssertFalse(newPlan.isBehind)
        XCTAssertEqual(newPlan.today?.startPage, 21)

        let progressed = KhatmaPlanner.applyProgress(record: record, newPagesCompleted: 42, todayEpochDay: startDay + 1)
        XCTAssertEqual(progressed.streak, 2)
        XCTAssertEqual(progressed.pagesCompleted, 42)
    }

    func testQuranVideoRecitationPartsAndSizing() {
        XCTAssertEqual(VideoShape.story.pixelSize(quality: .hd).width, 720)
        XCTAssertEqual(VideoShape.story.pixelSize(quality: .hd).height, 1280)
        XCTAssertEqual(VideoShape.square.pixelSize(quality: .fullHd).width, 1080)
        XCTAssertEqual(VideoShape.wide.pixelSize(quality: .fullHd).width, 1920)

        let basmala = Ayah(number: 1, surahNumber: 1, numberInSurah: 1, textUthmani: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ", page: 1)
        let s112a1 = Ayah(number: 6222, surahNumber: 112, numberInSurah: 1, textUthmani: "قُلْ هُوَ اللَّهُ أَحَدٌ", page: 604)
        let parts = QuranVideoPlanner.recitationParts(surah: 112, from: 1, to: 1, ayahs: [s112a1], opening: basmala)
        XCTAssertEqual(parts.count, 2)
        XCTAssertEqual(parts[0].number, 0)
        XCTAssertEqual(parts[1].number, 1)

        // At-Tawbah (surah 9) never prepends basmala.
        let s9a1 = Ayah(number: 1236, surahNumber: 9, numberInSurah: 1, textUthmani: "بَرَاءَةٌ مِنَ اللَّهِ", page: 187)
        let tawbahParts = QuranVideoPlanner.recitationParts(surah: 9, from: 1, to: 1, ayahs: [s9a1], opening: basmala)
        XCTAssertEqual(tawbahParts.count, 1)
        XCTAssertEqual(tawbahParts[0].number, 1)
    }
}
