import AppIntents
import Foundation
import WidgetKit
import SirajCore

enum WidgetBackgroundOption: String, AppEnum {
    case soft = "SOFT"
    case colour = "COLOUR"
    case tintedGlass = "GLASS"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Background"
    static var caseDisplayRepresentations: [WidgetBackgroundOption: DisplayRepresentation] = [
        .soft: "Soft",
        .colour: "Filled",
        .tintedGlass: "Glass"
    ]

    var model: WidgetBackgroundStyle {
        WidgetBackgroundStyle(rawValue: rawValue) ?? .soft
    }
}

enum WidgetPaletteOption: String, AppEnum {
    case appDefault = "App"
    case emerald = "Emerald"
    case gold = "Gold"
    case sand = "Sand"
    case olive = "Olive"
    case tealCaspian = "TealCaspian"
    case oceanBlue = "OceanBlue"
    case royalIndigo = "RoyalIndigo"
    case rose = "Rose"
    case burgundy = "Burgundy"
    case red = "Red"
    case coffee = "Coffee"
    case lime = "Lime"
    case slate = "Slate"
    case silver = "Silver"
    case white = "White"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Palette"
    static var caseDisplayRepresentations: [WidgetPaletteOption: DisplayRepresentation] = [
        .appDefault: "Same as app",
        .emerald: "Classic",
        .gold: "Gold",
        .sand: "Sand",
        .olive: "Olive",
        .tealCaspian: "Ocean",
        .oceanBlue: "Sky",
        .royalIndigo: "Navy",
        .rose: "Rose",
        .burgundy: "Burgundy",
        .red: "Red",
        .coffee: "Coffee",
        .lime: "Lime",
        .slate: "Slate",
        .silver: "Silver",
        .white: "White"
    ]

    var overrideId: String? {
        self == .appDefault ? nil : rawValue
    }
}

enum PrayerWidgetFaceOption: String, AppEnum {
    case next = "NEXT"
    case today = "TODAY"
    case list = "LIST"
    case spot = "SPOT"
    case ring = "RING"
    case dual = "DUAL"
    case day = "DAY"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Prayer Face"
    static var caseDisplayRepresentations: [PrayerWidgetFaceOption: DisplayRepresentation] = [
        .next: "Next Prayer",
        .today: "Today's Prayers",
        .list: "Prayer List",
        .spot: "Calligraphy",
        .ring: "Prayer Ring",
        .dual: "Now & Next",
        .day: "Day & Prayers"
    ]
}

enum ClockWidgetStyleOption: String, AppEnum {
    case classic = "CLASSIC"
    case bold = "BOLD"
    case serif = "SERIF"
    case condensed = "CONDENSED"
    case handwritten = "HANDWRITTEN"
    case marker = "MARKER"
    case analog = "ANALOG"
    case ink = "INK"
    case star = "STAR"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Clock Style"
    static var caseDisplayRepresentations: [ClockWidgetStyleOption: DisplayRepresentation] = [
        .classic: "Classic",
        .bold: "Bold",
        .serif: "Serif",
        .condensed: "Narrow",
        .handwritten: "Handwritten",
        .marker: "Marker",
        .analog: "Analog",
        .ink: "Hand-drawn",
        .star: "Star"
    ]

    var model: ClockStyle {
        ClockStyle(rawValue: rawValue) ?? .classic
    }
}

enum HijriWidgetFaceOption: String, AppEnum {
    case hijri = "HIJRI"
    case month = "MONTH"
    case date = "DATE"
    case moon = "MOON"
    case countdown = "COUNTDOWN"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Calendar Face"
    static var caseDisplayRepresentations: [HijriWidgetFaceOption: DisplayRepresentation] = [
        .hijri: "Hijri Date",
        .month: "Hijri Month",
        .date: "Calligraphy Date",
        .moon: "Tonight's Moon",
        .countdown: "Next Occasion"
    ]
}

struct PrayerWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Prayer Times Widget"
    static var description = IntentDescription("Choose a prayer face, background, and color palette.")

    @Parameter(title: "Face", default: .next)
    var face: PrayerWidgetFaceOption

    @Parameter(title: "Background", default: .soft)
    var background: WidgetBackgroundOption

    @Parameter(title: "Palette", default: .appDefault)
    var palette: WidgetPaletteOption
}

struct ClockWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Prayer Clock Widget"
    static var description = IntentDescription("Choose a clock face, background, and color palette.")

    @Parameter(title: "Clock Style", default: .classic)
    var style: ClockWidgetStyleOption

    @Parameter(title: "Background", default: .soft)
    var background: WidgetBackgroundOption

    @Parameter(title: "Palette", default: .appDefault)
    var palette: WidgetPaletteOption
}

struct HijriWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Hijri & Moon Widget"
    static var description = IntentDescription("Choose a Hijri calendar or moon face, background, and palette.")

    @Parameter(title: "Face", default: .hijri)
    var face: HijriWidgetFaceOption

    @Parameter(title: "Background", default: .soft)
    var background: WidgetBackgroundOption

    @Parameter(title: "Palette", default: .appDefault)
    var palette: WidgetPaletteOption
}

enum QuoteWidgetFaceOption: String, AppEnum {
    case ayah = "AYAH"
    case verseCard = "VERSE_CARD"
    case hadith = "HADITH"
    case dhikr = "DHIKR"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Quote Face"
    static var caseDisplayRepresentations: [QuoteWidgetFaceOption: DisplayRepresentation] = [
        .ayah: "Quran Verse",
        .verseCard: "Floral Verse Card",
        .hadith: "Prophetic Hadith",
        .dhikr: "Dhikr"
    ]
}

enum QuoteRotationOption: String, AppEnum {
    case prayer = "PRAYER"
    case hour = "HOUR"
    case day = "DAY"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Updates"
    static var caseDisplayRepresentations: [QuoteRotationOption: DisplayRepresentation] = [
        .prayer: "Each prayer",
        .hour: "Every hour",
        .day: "Every day"
    ]

    var model: QuoteRotation {
        QuoteRotation(rawValue: rawValue) ?? .prayer
    }
}

struct QuoteWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Verse, Hadith & Dhikr"
    static var description = IntentDescription("Show a rotating Quran verse, floral verse card, hadith, or dhikr.")

    @Parameter(title: "Face", default: .verseCard)
    var face: QuoteWidgetFaceOption

    @Parameter(title: "Updates", default: .prayer)
    var rotation: QuoteRotationOption

    @Parameter(title: "Show meaning", default: true)
    var showMeaning: Bool

    @Parameter(title: "Background", default: .soft)
    var background: WidgetBackgroundOption

    @Parameter(title: "Palette", default: .appDefault)
    var palette: WidgetPaletteOption
}

enum WorshipWidgetFaceOption: String, AppEnum {
    case adhkar = "ADHKAR"
    case fast = "FAST"
    case read = "READ"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Worship Face"
    static var caseDisplayRepresentations: [WorshipWidgetFaceOption: DisplayRepresentation] = [
        .adhkar: "Adhkar for now",
        .fast: "Suhoor & Iftar",
        .read: "Continue Reading"
    ]
}

struct WorshipWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Worship & Reading"
    static var description = IntentDescription("Adhkar for the current time, Suhoor & Iftar fasting timer, or Continue Reading.")

    @Parameter(title: "Face", default: .adhkar)
    var face: WorshipWidgetFaceOption

    @Parameter(title: "Background", default: .soft)
    var background: WidgetBackgroundOption

    @Parameter(title: "Palette", default: .appDefault)
    var palette: WidgetPaletteOption
}

struct TasbihWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Tasbih Counter"
    static var description = IntentDescription("Interactive after-prayer tasbih counter right on your Home Screen.")

    @Parameter(title: "Background", default: .soft)
    var background: WidgetBackgroundOption

    @Parameter(title: "Palette", default: .appDefault)
    var palette: WidgetPaletteOption
}

struct TapWidgetTasbihIntent: AppIntent {
    static var title: LocalizedStringResource = "Count Tasbih"
    static var description = IntentDescription("Increment the Home Screen tasbih counter by one.")

    func perform() async throws -> some IntentResult {
        let appGroup = Bundle.main.object(forInfoDictionaryKey: "SirajAppGroupID") as? String
        _ = UserDataStore(appGroupId: appGroup).tapWidgetTasbih()
        WidgetCenter.shared.reloadTimelines(ofKind: "SirajTasbihWidget")
        return .result()
    }
}

struct ResetWidgetTasbihIntent: AppIntent {
    static var title: LocalizedStringResource = "Reset Tasbih"
    static var description = IntentDescription("Reset the Home Screen tasbih counter to zero.")

    func perform() async throws -> some IntentResult {
        let appGroup = Bundle.main.object(forInfoDictionaryKey: "SirajAppGroupID") as? String
        UserDataStore(appGroupId: appGroup).resetWidgetTasbih()
        WidgetCenter.shared.reloadTimelines(ofKind: "SirajTasbihWidget")
        return .result()
    }
}
