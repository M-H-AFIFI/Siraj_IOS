import Foundation
import XCTest
@testable import SirajCore

final class SettingsAndStorageTests: XCTestCase {
    func testFallsBackToLocalDirectoryWhenAppGroupUnavailableAndPersists() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = UserDataStore(appGroupId: nil, fallbackDirectory: tempDir)
        XCTAssertTrue(store.isUsingFallbackContainer)

        var settings = SettingsSnapshot()
        settings.themePalette = "OceanBlue"
        settings.language = "ar"
        settings.isAmoled = true
        settings.cachedLocation = .cairoDefault
        store.saveSettings(settings)
        store.saveOnboardingComplete(true)
        store.saveTasbihCount(33)

        let reopened = UserDataStore(appGroupId: nil, fallbackDirectory: tempDir)
        XCTAssertEqual(reopened.loadSettings().themePalette, "OceanBlue")
        XCTAssertEqual(reopened.loadSettings().language, "ar")
        XCTAssertTrue(reopened.loadSettings().isAmoled)
        XCTAssertEqual(reopened.loadSettings().cachedLocation?.cityName, "Cairo")
        XCTAssertTrue(reopened.loadOnboardingComplete())
        XCTAssertEqual(reopened.loadTasbihCount(), 33)
    }

    func testCorruptedSettingsJsonRecoversToDefaultsWithoutCrashing() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = UserDataStore(appGroupId: nil, fallbackDirectory: tempDir)
        let settingsFile = store.directoryURL.appendingPathComponent("settings.json")
        try Data("{ truncated json !!!".utf8).write(to: settingsFile)

        let loaded = store.loadSettings()
        XCTAssertEqual(loaded, SettingsSnapshot())
        let badBackup = store.directoryURL.appendingPathComponent("settings.bad.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: badBackup.path))
    }

    func testLegacyPaletteAndMethodNamesCanonicalizeOnDecode() throws {
        let legacyJSON = """
        {
          "themePalette": "MedinaDawn",
          "calculationMethod": "ISNA",
          "language": "tr"
        }
        """
        let decoded = try JSONDecoder().decode(SettingsSnapshot.self, from: Data(legacyJSON.utf8))
        XCTAssertEqual(decoded.themePalette, "Emerald")
        XCTAssertEqual(decoded.calculationMethod, "NorthAmerica")
        XCTAssertEqual(decoded.language, "tr")

        let scheme = SirajColorSchemeSpec.resolve(palette: "MedinaDawn", isDark: false, isBlack: false)
        XCTAssertEqual(scheme.primary, ArgbColor.hex(SirajPalettes.definition(for: "Emerald").light.primary))
        let amoled = SirajColorSchemeSpec.resolve(palette: "Gold", isDark: true, isBlack: true)
        XCTAssertEqual(amoled.background, ArgbColor.hex(0xFF000000))
        XCTAssertEqual(amoled.surface, ArgbColor.hex(0xFF000000))
    }

    func testLocalizerHandlesRtlArabicDigitsAndMalformedPlaceholdersSafely() {
        let loc = SirajLocalizer(tables: [
            "en": [
                "greeting": "Next: {0} in {1}",
                "float_fmt": "{0:.1f} km",
                "reordered": "{1} then {0}",
                "missing_arg": "Hello {0} and {5}",
                "only_en": "English fallback"
            ],
            "ar": [
                "greeting": "القادم: {0} بعد {1}"
            ]
        ])

        XCTAssertTrue(loc.isRTL("ar"))
        XCTAssertTrue(loc.isRTL("ur"))
        XCTAssertFalse(loc.isRTL("en"))
        XCTAssertFalse(loc.isRTL("tr"))

        XCTAssertEqual(loc.format("greeting", lang: "en", "Fajr", "12m"), "Next: Fajr in 12m")
        XCTAssertEqual(loc.format("float_fmt", lang: "en", 1285.34), "1285.3 km")
        XCTAssertEqual(loc.format("reordered", lang: "en", "A", "B"), "B then A")
        XCTAssertEqual(loc.format("missing_arg", lang: "en", "World"), "Hello World and ")
        XCTAssertEqual(loc.string("only_en", lang: "ar"), "English fallback")
    }

    func testDigitFormatterRespectsAutoWesternArabicIndicAndQuranException() {
        XCTAssertEqual(DigitFormatter.localizeDigits("12:45", numeralSystem: "Auto", lang: "ar"), "١٢:٤٥")
        XCTAssertEqual(DigitFormatter.localizeDigits("12:45", numeralSystem: "Auto", lang: "ur"), "۱۲:۴۵")
        XCTAssertEqual(DigitFormatter.localizeDigits("12:45", numeralSystem: "Auto", lang: "en"), "12:45")
        XCTAssertEqual(DigitFormatter.localizeDigits("12:45", numeralSystem: "Western", lang: "ar"), "12:45")
        XCTAssertEqual(DigitFormatter.localizeDigits("255", numeralSystem: "Western", lang: "en", isQuran: true, quranException: true), "٢٥٥")
        XCTAssertEqual(DigitFormatter.toWestern("١٢:٣٠"), "12:30")
    }
}
