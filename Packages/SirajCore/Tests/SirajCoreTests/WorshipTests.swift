import Foundation
import XCTest
@testable import SirajCore

final class WorshipTests: XCTestCase {
    func testQiblaBearingAndDistanceForMajorCities() {
        let cairo = Coordinates(latitude: 30.0444, longitude: 31.2357)
        let cairoBearing = QiblaMath.bearing(from: cairo)
        XCTAssertEqual(cairoBearing, 136.1, accuracy: 0.6)
        XCTAssertEqual(QiblaMath.distanceKm(from: cairo), 1286, accuracy: 15)

        let nyc = Coordinates(latitude: 40.7128, longitude: -74.0060)
        XCTAssertEqual(QiblaMath.bearing(from: nyc), 58.5, accuracy: 0.6)

        let tokyo = Coordinates(latitude: 35.6762, longitude: 139.6503)
        XCTAssertEqual(QiblaMath.bearing(from: tokyo), 293.0, accuracy: 0.8)
    }

    func testQiblaAlignmentHysteresisAndUnwrapping() {
        XCTAssertEqual(QiblaAlignment.shortestDelta(from: 350, to: 10), 20, accuracy: 0.001)
        XCTAssertEqual(QiblaAlignment.shortestDelta(from: 10, to: 350), -20, accuracy: 0.001)

        // Unwrapped azimuth far negative still normalizes cleanly into [-180, 180].
        let rb = QiblaAlignment.relativeBearing(qiblaBearing: 135, unwrappedAzimuth: -855)
        XCTAssertEqual(rb, 0, accuracy: 0.001)

        XCTAssertTrue(QiblaAlignment.isAligned(relativeBearing: 2.5, wasAligned: false))
        XCTAssertFalse(QiblaAlignment.isAligned(relativeBearing: 4.0, wasAligned: false))
        XCTAssertTrue(QiblaAlignment.isAligned(relativeBearing: 4.5, wasAligned: true))
        XCTAssertFalse(QiblaAlignment.isAligned(relativeBearing: 6.5, wasAligned: true))
    }

    func testAzkarPickLocalizedAndQuranicDetection() {
        let tagged = "[ar]فضل الذكر\n[en]Virtue of remembrance\n[tr]Zikrin fazileti"
        XCTAssertEqual(AzkarItem.pickLocalized(tagged, language: "ar"), "فضل الذكر")
        XCTAssertEqual(AzkarItem.pickLocalized(tagged, language: "en"), "Virtue of remembrance")
        XCTAssertEqual(AzkarItem.pickLocalized(tagged, language: "tr"), "Zikrin fazileti")
        XCTAssertEqual(AzkarItem.pickLocalized(tagged, language: "ur"), "فضل الذكر")

        let quranItem = AzkarItem(id: 1, category: "الصباح", text: "ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ")
        let sunnahItem = AzkarItem(id: 2, category: "الصباح", text: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ")
        XCTAssertTrue(quranItem.isQuranic)
        XCTAssertFalse(sunnahItem.isQuranic)
    }

    func testAzkarCatalogParsingAndFiltering() {
        let sampleJSON = """
        [
          {
            "title": "أذكار الصباح",
            "azkar": [
              {"text": "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ", "count": 1, "reward": "[ar]مسلم[en]Muslim"},
              {"text": "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ", "count": 100}
            ]
          },
          {
            "title": "دعاء لبس الثوب",
            "azkar": [
              {"text": "الْحَمْدُ لِلَّهِ الَّذِي كَسَانِي هَذَا", "count": 1}
            ]
          }
        ]
        """.data(using: .utf8)!
        let titlesJSON = """
        {
          "دعاء لبس الثوب": {"en": "Supplication for Wearing Clothes", "tr": "Elbise Duası", "ur": "لباس کی دعا"}
        }
        """.data(using: .utf8)!

        let catalog = AzkarCatalog.parse(azkarData: sampleJSON, hisnTitlesData: titlesJSON)
        XCTAssertEqual(catalog.chapters.count, 2)
        XCTAssertEqual(catalog.items.count, 3)
        XCTAssertEqual(catalog.items(forCategoryKey: "MORNING").count, 2)
        XCTAssertEqual(catalog.items(forCategoryKey: "دعاء لبس الثوب").count, 1)
        XCTAssertEqual(catalog.localizedChapterTitle("دعاء لبس الثوب", language: "en"), "Supplication for Wearing Clothes")
        XCTAssertEqual(catalog.localizedChapterTitle("دعاء لبس الثوب", language: "ar"), "دعاء لبس الثوب")
        XCTAssertTrue(AzkarFilterTab.daily.matches(category: .morning))
        XCTAssertTrue(AzkarFilterTab.daily.matches(chapterTitle: "دعاء لبس الثوب"))
    }

    func testArabicTransliteratorHandlesSunLettersAndAllah() {
        let out = ArabicTransliterator.transliterate("بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ")
        XCTAssertTrue(out.contains("Bismillahi") || out.contains("Bismillah"))
        XCTAssertTrue(out.lowercased().contains("rahim"))
        XCTAssertFalse(ArabicTransliterator.transliterate("سُبْحَانَ اللَّهِ").isEmpty)
    }

    func testTasbihPresetsAndDailyPersistence() {
        XCTAssertEqual(TasbihDhikr.presets.count, 8)
        XCTAssertEqual(TasbihDhikr.goalPresets, [33, 99, 100, 1000])

        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("siraj_worship_test_\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: tmp) }
        let store = UserDataStore(appGroupId: nil, fallbackDirectory: tmp)

        store.saveAzkarProgress(["MORNING": [1: 1, 2: 3]], for: "2026-11-24")
        XCTAssertEqual(store.loadAzkarProgress(for: "2026-11-24")["MORNING"]?[2], 3)
        // New day resets progress automatically.
        XCTAssertTrue(store.loadAzkarProgress(for: "2026-11-25").isEmpty)

        var snap = TasbihSnapshot(count: 15, goal: 33, todayTotal: 48, currentDhikrIndex: 1, lastDateISO: "2026-11-24")
        snap.customDhikrs = [TasbihDhikr(arabic: "يَا حَيُّ يَا قَيُّومُ", defaultGoal: 33, isCustom: true)]
        store.saveTasbihSnapshot(snap)
        let loaded = store.loadTasbihSnapshot()
        XCTAssertEqual(loaded, snap)
        XCTAssertEqual(store.loadTasbihCount(), 48)
    }

    func testSearchFoldingAndAllahNamesDayIndex() {
        XCTAssertTrue(SearchFolding.matchesFolded(query: "الرحمن", fields: ["الرَّحْمَٰنُ"]))
        XCTAssertTrue(SearchFolding.matchesFolded(query: "rahman", fields: ["Ar-Rahman"]))
        let sample = [
            AllahName(number: 1, nameAr: "الرَّحْمَنُ", transliteration: "Ar-Rahman", meaningEn: "The Most Gracious", descriptionEn: "Desc", meaningAr: "الرحمن", descriptionAr: "وصف", meaningTr: "Rahman", descriptionTr: "", meaningUr: "", descriptionUr: ""),
            AllahName(number: 2, nameAr: "الرَّحِيمُ", transliteration: "Ar-Rahim", meaningEn: "The Most Merciful", descriptionEn: "Desc", meaningAr: "الرحيم", descriptionAr: "وصف", meaningTr: "Rahim", descriptionTr: "", meaningUr: "", descriptionUr: "")
        ]
        XCTAssertEqual(AllahNamesCatalog.nameOfTheDay(from: sample, dayOfYear: 1)?.number, 1)
        XCTAssertEqual(AllahNamesCatalog.nameOfTheDay(from: sample, dayOfYear: 2)?.number, 2)
        XCTAssertEqual(AllahNamesCatalog.nameOfTheDay(from: sample, dayOfYear: 3)?.number, 1)
    }
}
