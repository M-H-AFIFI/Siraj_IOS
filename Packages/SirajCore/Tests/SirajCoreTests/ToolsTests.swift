import Foundation
import XCTest
@testable import SirajCore

final class ToolsTests: XCTestCase {
    func testZakatCalculatorSilverGoldAndZeroGuard() {
        // Above silver nisab (595 * 1.0 = 595)
        let eligible = ZakatCalculator.calculate(ZakatAssets(cash: 1000, goldPricePerGram: 75, silverPricePerGram: 1.0))
        XCTAssertTrue(eligible.isEligible)
        XCTAssertEqual(eligible.nisabValue, 595.0, accuracy: 0.001)
        XCTAssertEqual(eligible.zakatDue, 25.0, accuracy: 0.001)

        // Below nisab
        let below = ZakatCalculator.calculate(ZakatAssets(cash: 500, goldPricePerGram: 75, silverPricePerGram: 1.0))
        XCTAssertFalse(below.isEligible)
        XCTAssertEqual(below.zakatDue, 0.0, accuracy: 0.001)

        // Gold fallback when silver price is zero (85 * 75 = 6375)
        let goldOnly = ZakatCalculator.calculate(ZakatAssets(cash: 7000, goldPricePerGram: 75, silverPricePerGram: 0))
        XCTAssertTrue(goldOnly.isEligible)
        XCTAssertEqual(goldOnly.nisabValue, 6375.0, accuracy: 0.001)
        XCTAssertEqual(goldOnly.zakatDue, 175.0, accuracy: 0.001)

        // Zero prices never trigger eligibility
        let noPrice = ZakatCalculator.calculate(ZakatAssets(cash: 100_000, goldPricePerGram: 0, silverPricePerGram: 0))
        XCTAssertFalse(noPrice.isEligible)
        XCTAssertEqual(noPrice.zakatDue, 0.0, accuracy: 0.001)

        // Arabic-Indic digit & decimal sanitization
        XCTAssertEqual(ZakatCalculator.sanitizeAmount("١٢٬٥٠٠٫٧٥"), "12500.75")
        XCTAssertEqual(ZakatCalculator.supportedCurrencies.count, 36)
    }

    func testFastingStreakAndUpcomingSunnah() {
        let today = CivilDate(year: 2026, month: 11, day: 24)
        let logs = [
            FastingLogEntry(dateISO: "2026-11-24", isFasting: true),
            FastingLogEntry(dateISO: "2026-11-23", isFasting: true),
            FastingLogEntry(dateISO: "2026-11-22", isFasting: true),
            FastingLogEntry(dateISO: "2026-11-20", isFasting: true)
        ]
        XCTAssertEqual(FastingPlanner.calculateStreak(logs: logs, today: today), 3)

        let upcoming = FastingPlanner.computeUpcoming(from: today, calendar: .ummAlQura)
        XCTAssertTrue(upcoming.contains { $0.type == .monday })
        XCTAssertTrue(upcoming.contains { $0.type == .thursday })
        XCTAssertTrue(upcoming.contains { $0.type == .ramadan })
        XCTAssertTrue(upcoming.contains { $0.type == .whiteDays })
        // Sorted by daysAway ascending
        XCTAssertEqual(upcoming.map(\.daysAway), upcoming.map(\.daysAway).sorted())
    }

    func testQuranRadioCatalogAndFilters() {
        XCTAssertEqual(QuranRadioStation.stations.count, 24)
        XCTAssertFalse(QuranRadioStation.filter(.broadcasts, query: "").isEmpty)
        XCTAssertFalse(QuranRadioStation.filter(.reciters, query: "").isEmpty)
        XCTAssertEqual(QuranRadioStation.filter(.tafsirAndSunnah, query: "").count, 3)
        XCTAssertEqual(QuranRadioStation.filter(.all, query: "القاهرة").first?.id, "quran_cairo")
        XCTAssertEqual(QuranRadioStation.byId("quran_nablus")?.artworkAsset, "img_alaqsa")
        XCTAssertEqual(QuranRadioStation.byId("sunnah")?.artworkAsset, "img_madinah")
    }

    func testOccasionsDescriptionsAndWhiteDays() {
        XCTAssertEqual(IslamicOccasions.all.count, 9)
        XCTAssertEqual(IslamicOccasions.on(month: 9, day: 1)?.id, "ramadan_start")
        XCTAssertFalse(IslamicOccasions.all.first!.description(language: "ar").isEmpty)
        XCTAssertFalse(IslamicOccasions.all.first!.description(language: "en").isEmpty)
        XCTAssertTrue(IslamicOccasions.isWhiteDay(month: 7, day: 14))
        XCTAssertFalse(IslamicOccasions.isWhiteDay(month: 9, day: 14))
        XCTAssertFalse(IslamicOccasions.isWhiteDay(month: 12, day: 13))
        XCTAssertTrue(IslamicOccasions.isFastingForbidden(month: 10, day: 1))
        XCTAssertTrue(IslamicOccasions.isFastingForbidden(month: 12, day: 11))
    }

    func testWidgetQuotesTasbihAndSurahNames() {
        XCTAssertEqual(WidgetFace.allGalleryFaces.count, 21)
        XCTAssertFalse(WidgetQuotesCatalog.hadiths.isEmpty)
        XCTAssertFalse(WidgetQuotesCatalog.dhikrs.isEmpty)

        let h0 = WidgetQuotesCatalog.hadith(forSlot: 0)
        let h1 = WidgetQuotesCatalog.hadith(forSlot: 1)
        XCTAssertNotEqual(h0.quote.ar, h1.quote.ar)
        XCTAssertFalse(h0.source(language: "en", numeralSystem: "Western").isEmpty)

        let morningDhikr = WidgetQuotesCatalog.dhikr(forSlot: 3, category: .morning)
        XCTAssertTrue(morningDhikr.occasion.fits(category: .morning))

        XCTAssertEqual(WidgetTasbihStep.of(count: 0).phraseIndex, 0)
        XCTAssertEqual(WidgetTasbihStep.of(count: 33).inPhrase, 33)
        XCTAssertEqual(WidgetTasbihStep.of(count: 34).phraseIndex, 1)
        XCTAssertEqual(WidgetTasbihStep.of(count: 34).inPhrase, 1)
        XCTAssertEqual(WidgetTasbihStep.of(count: 67).phraseIndex, 2)
        XCTAssertEqual(WidgetTasbihStep.of(count: 67).ofPhrase, 34)
        XCTAssertTrue(WidgetTasbihStep.of(count: 100).isDone)

        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("siraj_widget_test_\(UUID().uuidString)")
        let store = UserDataStore(appGroupId: nil, fallbackDirectory: tmp)
        XCTAssertEqual(store.loadWidgetTasbihCount(), 0)
        XCTAssertEqual(store.tapWidgetTasbih(), 1)
        XCTAssertEqual(store.tapWidgetTasbih(), 2)
        store.resetWidgetTasbih()
        XCTAssertEqual(store.loadWidgetTasbihCount(), 0)
        try? FileManager.default.removeItem(at: tmp)

        XCTAssertEqual(ShamarlyBanners.arabicName(forSurah: 1), "الفاتحة")
        XCTAssertEqual(ShamarlyBanners.arabicName(forSurah: 3), "آل عمران")
        XCTAssertEqual(ShamarlyBanners.arabicName(forSurah: 18), "الكهف")
        XCTAssertEqual(ShamarlyBanners.arabicName(forSurah: 114), "الناس")
    }
}
