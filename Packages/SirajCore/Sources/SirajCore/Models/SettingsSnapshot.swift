import Foundation

public enum GlassFinish: String, CaseIterable, Codable, Sendable, Identifiable {
    case clear = "CLEAR"
    case satin = "SATIN"
    case frosted = "FROSTED"

    public var id: String { rawValue }
    public var isFrosted: Bool { self == .frosted }
}

public enum LiveBackgroundIntensity: String, CaseIterable, Codable, Sendable, Identifiable {
    case subtle = "Subtle"
    case balanced = "Balanced"
    case vivid = "Vivid"

    public var id: String { rawValue }

    public var motionScale: Double {
        switch self {
        case .subtle: return 0.65
        case .balanced: return 1.0
        case .vivid: return 1.24
        }
    }

    public var detailAlphaScale: Double {
        switch self {
        case .subtle: return 0.68
        case .balanced: return 1.0
        case .vivid: return 1.26
        }
    }

    public var veilAdjustment: Double {
        switch self {
        case .subtle: return 0.10
        case .balanced: return 0.0
        case .vivid: return -0.09
        }
    }
}

public enum ThemeMode: String, CaseIterable, Codable, Sendable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    public var id: String { rawValue }
}

public enum NavBarStyle: String, CaseIterable, Codable, Sendable, Identifiable {
    case rounded = "Rounded"
    case compact = "Compact"

    public var id: String { rawValue }
}

public struct SettingsSnapshot: Codable, Sendable, Equatable {
    // Location & prayer calculation
    public var madhab: String
    public var calculationMethod: String
    public var highLatitudeRule: String
    public var minuteOffsets: [String: Int]
    public var iqamaOffsets: [String: Int]
    public var isManualLocation: Bool
    public var cachedLocation: Place?
    public var hijriMethod: String
    public var hijriAdjustment: Int

    // Appearance & navigation
    public var themeMode: ThemeMode
    public var themePalette: String
    public var isAmoled: Bool
    public var isGlassUi: Bool
    public var isGlassMesh: Bool
    public var glassFinish: GlassFinish
    public var isGlassPerformanceMode: Bool
    public var liveTheme: String
    public var isLiveBackgroundEnabled: Bool
    public var isWeatherBackgroundEnabled: Bool
    public var liveBackgroundIntensity: LiveBackgroundIntensity
    public var isLivePaletteSync: Bool
    public var selectedAppIcon: String
    public var isNavShrinkEnabled: Bool
    public var navBarStyle: NavBarStyle
    public var isNavAlwaysCompact: Bool
    public var isReduceMotionEnabled: Bool
    public var textScale: Double

    // Localization & formatting
    public var language: String
    public var numeralSystem: String
    public var isQuranNumeralException: Bool
    public var hourFormat: String
    public var isHapticEnabled: Bool
    public var isSoundEnabled: Bool

    // Adhan & reminders
    public var azanSound: String
    public var fajrAdhanEnabled: Bool
    public var fajrAdhanVoice: String
    public var azanReminderType: String // "azan", "notification", "silent"
    public var sunriseReminderType: String
    public var prayerReminders: [String: Bool]
    public var prePrayerReminderMinutes: Int
    public var suggestedReminders: [String: Bool]
    public var suggestedTimes: [String: String]
    public var customReminders: [CustomReminder]
    public var isAdhanScreenEnabled: Bool
    public var isAdhanScreenMatchPrayer: Bool
    public var adhanVolume: Double
    public var liveActivityEnabled: Bool

    // Reading & daily preferences
    public var isShowTranslation: Bool
    public var isShowTransliteration: Bool
    public var isShowVirtues: Bool

    // Quran & Mushaf reading preferences
    public var mushafEdition: String
    public var isQuranPageView: Bool
    public var quranScrollDirection: String
    public var quranLandscapeLayout: String
    public var quranTheme: String
    public var quranPaperColor: String
    public var quranDarkStyle: String
    public var quranFontSizeMultiplier: Double
    public var selectedTafsirEdition: String
    public var tafsirFontScale: Double
    public var isLastBookmarkOnDashboard: Bool
    public var quranAutoScroll: Bool
    public var quranHighlightMode: String
    public var isPlayerProgressBarEnabled: Bool
    public var selectedReciterId: String

    public init(
        madhab: String = "Shafi",
        calculationMethod: String = "MuslimWorldLeague",
        highLatitudeRule: String = "MiddleOfTheNight",
        minuteOffsets: [String: Int] = ["FAJR": 0, "DHUHR": 0, "ASR": 0, "MAGHRIB": 0, "ISHA": 0],
        iqamaOffsets: [String: Int] = [:],
        isManualLocation: Bool = false,
        cachedLocation: Place? = nil,
        hijriMethod: String = "auto",
        hijriAdjustment: Int = 0,
        themeMode: ThemeMode = .system,
        themePalette: String = "Emerald",
        isAmoled: Bool = false,
        isGlassUi: Bool = false,
        isGlassMesh: Bool = false,
        glassFinish: GlassFinish = .clear,
        isGlassPerformanceMode: Bool = false,
        liveTheme: String = "DesertDunes",
        isLiveBackgroundEnabled: Bool = false,
        isWeatherBackgroundEnabled: Bool = false,
        liveBackgroundIntensity: LiveBackgroundIntensity = .balanced,
        isLivePaletteSync: Bool = false,
        selectedAppIcon: String = "Classic",
        isNavShrinkEnabled: Bool = false,
        navBarStyle: NavBarStyle = .rounded,
        isNavAlwaysCompact: Bool = false,
        isReduceMotionEnabled: Bool = false,
        textScale: Double = 1.0,
        language: String = "en",
        numeralSystem: String = "Auto",
        isQuranNumeralException: Bool = true,
        hourFormat: String = "System",
        isHapticEnabled: Bool = true,
        isSoundEnabled: Bool = true,
        azanSound: String = AdhanCatalog.defaultVoiceId,
        fajrAdhanEnabled: Bool = true,
        fajrAdhanVoice: String = "",
        azanReminderType: String = "azan",
        sunriseReminderType: String = "notification",
        prayerReminders: [String: Bool] = ["fajr": true, "sunrise": false, "dhuhr": true, "asr": true, "maghrib": true, "isha": true],
        prePrayerReminderMinutes: Int = 0,
        suggestedReminders: [String: Bool] = [
            "duha": false, "qiyam": false, "surat_kahf": false, "morning_azkar": false,
            "evening_azkar": false, "fasting_days": false, "daily_reading": false, "verse_day": false
        ],
        suggestedTimes: [String: String] = [
            "duha": "09:00", "qiyam": "03:00", "surat_kahf": "11:00", "morning_azkar": "06:30",
            "evening_azkar": "17:00", "fasting_days": "04:30", "daily_reading": "20:00", "verse_day": "07:30"
        ],
        customReminders: [CustomReminder] = [],
        isAdhanScreenEnabled: Bool = true,
        isAdhanScreenMatchPrayer: Bool = true,
        adhanVolume: Double = 0.85,
        liveActivityEnabled: Bool = true,
        isShowTranslation: Bool = true,
        isShowTransliteration: Bool = true,
        isShowVirtues: Bool = true,
        mushafEdition: String = MushafEdition.madinah.rawValue,
        isQuranPageView: Bool = true,
        quranScrollDirection: String = "Horizontal",
        quranLandscapeLayout: String = "Single",
        quranTheme: String = "System",
        quranPaperColor: String = "Yellowish",
        quranDarkStyle: String = "Dark",
        quranFontSizeMultiplier: Double = 1.0,
        selectedTafsirEdition: String = TafsirBook.builtInId,
        tafsirFontScale: Double = 1.0,
        isLastBookmarkOnDashboard: Bool = true,
        quranAutoScroll: Bool = true,
        quranHighlightMode: String = "ayah",
        isPlayerProgressBarEnabled: Bool = true,
        selectedReciterId: String = "ar.alafasy"
    ) {
        self.madhab = madhab
        self.calculationMethod = CalculationMethods.canonicalId(calculationMethod)
        self.highLatitudeRule = highLatitudeRule
        self.minuteOffsets = minuteOffsets
        self.iqamaOffsets = iqamaOffsets
        self.isManualLocation = isManualLocation
        self.cachedLocation = cachedLocation
        self.hijriMethod = hijriMethod
        self.hijriAdjustment = min(2, max(-2, hijriAdjustment))
        self.themeMode = themeMode
        self.themePalette = SirajPalettes.canonicalId(themePalette)
        self.isAmoled = isAmoled
        self.isGlassUi = isGlassUi
        self.isGlassMesh = isGlassMesh
        self.glassFinish = glassFinish
        self.isGlassPerformanceMode = isGlassPerformanceMode
        self.liveTheme = liveTheme
        self.isLiveBackgroundEnabled = isLiveBackgroundEnabled
        self.isWeatherBackgroundEnabled = isWeatherBackgroundEnabled
        self.liveBackgroundIntensity = liveBackgroundIntensity
        self.isLivePaletteSync = isLivePaletteSync
        self.selectedAppIcon = selectedAppIcon
        self.isNavShrinkEnabled = isNavShrinkEnabled
        self.navBarStyle = navBarStyle
        self.isNavAlwaysCompact = isNavAlwaysCompact
        self.isReduceMotionEnabled = isReduceMotionEnabled
        self.textScale = min(1.4, max(0.85, textScale))
        self.language = language
        self.numeralSystem = numeralSystem
        self.isQuranNumeralException = isQuranNumeralException
        self.hourFormat = hourFormat
        self.isHapticEnabled = isHapticEnabled
        self.isSoundEnabled = isSoundEnabled
        self.azanSound = azanSound
        self.fajrAdhanEnabled = fajrAdhanEnabled
        self.fajrAdhanVoice = fajrAdhanVoice
        self.azanReminderType = azanReminderType
        self.sunriseReminderType = sunriseReminderType
        self.prayerReminders = prayerReminders
        self.prePrayerReminderMinutes = PrePrayerReminder.normalize(prePrayerReminderMinutes)
        self.suggestedReminders = suggestedReminders
        self.suggestedTimes = suggestedTimes
        self.customReminders = customReminders
        self.isAdhanScreenEnabled = isAdhanScreenEnabled
        self.isAdhanScreenMatchPrayer = isAdhanScreenMatchPrayer
        self.adhanVolume = min(1.0, max(0.1, adhanVolume))
        self.liveActivityEnabled = liveActivityEnabled
        self.isShowTranslation = isShowTranslation
        self.isShowTransliteration = isShowTransliteration
        self.isShowVirtues = isShowVirtues
        self.mushafEdition = MushafEdition.resolve(mushafEdition).rawValue
        self.isQuranPageView = isQuranPageView
        self.quranScrollDirection = quranScrollDirection
        self.quranLandscapeLayout = quranLandscapeLayout
        self.quranTheme = quranTheme
        self.quranPaperColor = quranPaperColor
        self.quranDarkStyle = quranDarkStyle
        self.quranFontSizeMultiplier = min(1.6, max(0.8, quranFontSizeMultiplier))
        self.selectedTafsirEdition = selectedTafsirEdition
        self.tafsirFontScale = min(1.6, max(0.8, tafsirFontScale))
        self.isLastBookmarkOnDashboard = isLastBookmarkOnDashboard
        self.quranAutoScroll = quranAutoScroll
        self.quranHighlightMode = quranHighlightMode
        self.isPlayerProgressBarEnabled = isPlayerProgressBarEnabled
        self.selectedReciterId = selectedReciterId
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let def = SettingsSnapshot()
        let rawMethod = try c.decodeIfPresent(String.self, forKey: .calculationMethod) ?? def.calculationMethod
        let rawPalette = try c.decodeIfPresent(String.self, forKey: .themePalette) ?? def.themePalette
        self.init(
            madhab: try c.decodeIfPresent(String.self, forKey: .madhab) ?? def.madhab,
            calculationMethod: CalculationMethods.canonicalId(rawMethod),
            highLatitudeRule: try c.decodeIfPresent(String.self, forKey: .highLatitudeRule) ?? def.highLatitudeRule,
            minuteOffsets: try c.decodeIfPresent([String: Int].self, forKey: .minuteOffsets) ?? def.minuteOffsets,
            iqamaOffsets: try c.decodeIfPresent([String: Int].self, forKey: .iqamaOffsets) ?? def.iqamaOffsets,
            isManualLocation: try c.decodeIfPresent(Bool.self, forKey: .isManualLocation) ?? def.isManualLocation,
            cachedLocation: try c.decodeIfPresent(Place.self, forKey: .cachedLocation),
            hijriMethod: try c.decodeIfPresent(String.self, forKey: .hijriMethod) ?? def.hijriMethod,
            hijriAdjustment: try c.decodeIfPresent(Int.self, forKey: .hijriAdjustment) ?? def.hijriAdjustment,
            themeMode: try c.decodeIfPresent(ThemeMode.self, forKey: .themeMode) ?? def.themeMode,
            themePalette: SirajPalettes.canonicalId(rawPalette),
            isAmoled: try c.decodeIfPresent(Bool.self, forKey: .isAmoled) ?? def.isAmoled,
            isGlassUi: try c.decodeIfPresent(Bool.self, forKey: .isGlassUi) ?? def.isGlassUi,
            isGlassMesh: try c.decodeIfPresent(Bool.self, forKey: .isGlassMesh) ?? def.isGlassMesh,
            glassFinish: try c.decodeIfPresent(GlassFinish.self, forKey: .glassFinish) ?? def.glassFinish,
            isGlassPerformanceMode: try c.decodeIfPresent(Bool.self, forKey: .isGlassPerformanceMode) ?? def.isGlassPerformanceMode,
            liveTheme: try c.decodeIfPresent(String.self, forKey: .liveTheme) ?? def.liveTheme,
            isLiveBackgroundEnabled: try c.decodeIfPresent(Bool.self, forKey: .isLiveBackgroundEnabled) ?? def.isLiveBackgroundEnabled,
            isWeatherBackgroundEnabled: try c.decodeIfPresent(Bool.self, forKey: .isWeatherBackgroundEnabled) ?? def.isWeatherBackgroundEnabled,
            liveBackgroundIntensity: try c.decodeIfPresent(LiveBackgroundIntensity.self, forKey: .liveBackgroundIntensity) ?? def.liveBackgroundIntensity,
            isLivePaletteSync: try c.decodeIfPresent(Bool.self, forKey: .isLivePaletteSync) ?? def.isLivePaletteSync,
            selectedAppIcon: try c.decodeIfPresent(String.self, forKey: .selectedAppIcon) ?? def.selectedAppIcon,
            isNavShrinkEnabled: try c.decodeIfPresent(Bool.self, forKey: .isNavShrinkEnabled) ?? def.isNavShrinkEnabled,
            navBarStyle: try c.decodeIfPresent(NavBarStyle.self, forKey: .navBarStyle) ?? def.navBarStyle,
            isNavAlwaysCompact: try c.decodeIfPresent(Bool.self, forKey: .isNavAlwaysCompact) ?? def.isNavAlwaysCompact,
            isReduceMotionEnabled: try c.decodeIfPresent(Bool.self, forKey: .isReduceMotionEnabled) ?? def.isReduceMotionEnabled,
            textScale: try c.decodeIfPresent(Double.self, forKey: .textScale) ?? def.textScale,
            language: try c.decodeIfPresent(String.self, forKey: .language) ?? def.language,
            numeralSystem: try c.decodeIfPresent(String.self, forKey: .numeralSystem) ?? def.numeralSystem,
            isQuranNumeralException: try c.decodeIfPresent(Bool.self, forKey: .isQuranNumeralException) ?? def.isQuranNumeralException,
            hourFormat: try c.decodeIfPresent(String.self, forKey: .hourFormat) ?? def.hourFormat,
            isHapticEnabled: try c.decodeIfPresent(Bool.self, forKey: .isHapticEnabled) ?? def.isHapticEnabled,
            isSoundEnabled: try c.decodeIfPresent(Bool.self, forKey: .isSoundEnabled) ?? def.isSoundEnabled,
            azanSound: try c.decodeIfPresent(String.self, forKey: .azanSound) ?? def.azanSound,
            fajrAdhanEnabled: try c.decodeIfPresent(Bool.self, forKey: .fajrAdhanEnabled) ?? def.fajrAdhanEnabled,
            fajrAdhanVoice: try c.decodeIfPresent(String.self, forKey: .fajrAdhanVoice) ?? def.fajrAdhanVoice,
            azanReminderType: try c.decodeIfPresent(String.self, forKey: .azanReminderType) ?? def.azanReminderType,
            sunriseReminderType: try c.decodeIfPresent(String.self, forKey: .sunriseReminderType) ?? def.sunriseReminderType,
            prayerReminders: try c.decodeIfPresent([String: Bool].self, forKey: .prayerReminders) ?? def.prayerReminders,
            prePrayerReminderMinutes: try c.decodeIfPresent(Int.self, forKey: .prePrayerReminderMinutes) ?? def.prePrayerReminderMinutes,
            suggestedReminders: try c.decodeIfPresent([String: Bool].self, forKey: .suggestedReminders) ?? def.suggestedReminders,
            suggestedTimes: try c.decodeIfPresent([String: String].self, forKey: .suggestedTimes) ?? def.suggestedTimes,
            customReminders: try c.decodeIfPresent([CustomReminder].self, forKey: .customReminders) ?? def.customReminders,
            isAdhanScreenEnabled: try c.decodeIfPresent(Bool.self, forKey: .isAdhanScreenEnabled) ?? def.isAdhanScreenEnabled,
            isAdhanScreenMatchPrayer: try c.decodeIfPresent(Bool.self, forKey: .isAdhanScreenMatchPrayer) ?? def.isAdhanScreenMatchPrayer,
            adhanVolume: try c.decodeIfPresent(Double.self, forKey: .adhanVolume) ?? def.adhanVolume,
            liveActivityEnabled: try c.decodeIfPresent(Bool.self, forKey: .liveActivityEnabled) ?? def.liveActivityEnabled,
            isShowTranslation: try c.decodeIfPresent(Bool.self, forKey: .isShowTranslation) ?? def.isShowTranslation,
            isShowTransliteration: try c.decodeIfPresent(Bool.self, forKey: .isShowTransliteration) ?? def.isShowTransliteration,
            isShowVirtues: try c.decodeIfPresent(Bool.self, forKey: .isShowVirtues) ?? def.isShowVirtues,
            mushafEdition: try c.decodeIfPresent(String.self, forKey: .mushafEdition) ?? def.mushafEdition,
            isQuranPageView: try c.decodeIfPresent(Bool.self, forKey: .isQuranPageView) ?? def.isQuranPageView,
            quranScrollDirection: try c.decodeIfPresent(String.self, forKey: .quranScrollDirection) ?? def.quranScrollDirection,
            quranLandscapeLayout: try c.decodeIfPresent(String.self, forKey: .quranLandscapeLayout) ?? def.quranLandscapeLayout,
            quranTheme: try c.decodeIfPresent(String.self, forKey: .quranTheme) ?? def.quranTheme,
            quranPaperColor: try c.decodeIfPresent(String.self, forKey: .quranPaperColor) ?? def.quranPaperColor,
            quranDarkStyle: try c.decodeIfPresent(String.self, forKey: .quranDarkStyle) ?? def.quranDarkStyle,
            quranFontSizeMultiplier: try c.decodeIfPresent(Double.self, forKey: .quranFontSizeMultiplier) ?? def.quranFontSizeMultiplier,
            selectedTafsirEdition: try c.decodeIfPresent(String.self, forKey: .selectedTafsirEdition) ?? def.selectedTafsirEdition,
            tafsirFontScale: try c.decodeIfPresent(Double.self, forKey: .tafsirFontScale) ?? def.tafsirFontScale,
            isLastBookmarkOnDashboard: try c.decodeIfPresent(Bool.self, forKey: .isLastBookmarkOnDashboard) ?? def.isLastBookmarkOnDashboard,
            quranAutoScroll: try c.decodeIfPresent(Bool.self, forKey: .quranAutoScroll) ?? def.quranAutoScroll,
            quranHighlightMode: try c.decodeIfPresent(String.self, forKey: .quranHighlightMode) ?? def.quranHighlightMode,
            isPlayerProgressBarEnabled: try c.decodeIfPresent(Bool.self, forKey: .isPlayerProgressBarEnabled) ?? def.isPlayerProgressBarEnabled,
            selectedReciterId: try c.decodeIfPresent(String.self, forKey: .selectedReciterId) ?? def.selectedReciterId
        )
    }

    public var calculationSettings: CalculationSettings {
        CalculationSettings(
            method: calculationMethod,
            madhab: madhab,
            highLatitudeRule: highLatitudeRule,
            minuteOffsets: minuteOffsets,
            iqamaOffsets: iqamaOffsets
        )
    }

    public var alertScheduleConfig: AlertScheduleConfig {
        AlertScheduleConfig(
            calculation: calculationSettings,
            prayerReminders: prayerReminders,
            prePrayerMinutes: prePrayerReminderMinutes,
            alertMode: azanReminderType,
            suggestedReminders: suggestedReminders,
            suggestedTimes: suggestedTimes,
            customReminders: customReminders
        )
    }
}

extension AlertPlanner {
    public static func plan(
        settings: SettingsSnapshot,
        place: Place,
        now: Date,
        horizonDays: Int = 12,
        resolvedSound: (PrayerType) -> String? = { _ in AdhanCatalog.defaultBundledCaf }
    ) -> [PlannedAlert] {
        plan(config: settings.alertScheduleConfig, place: place, now: now, horizonDays: horizonDays, resolvedSound: resolvedSound)
    }
}
