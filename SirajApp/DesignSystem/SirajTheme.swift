import SwiftUI
import SirajCore

extension Color {
    init(argb: ArgbColor) {
        self.init(
            .sRGB,
            red: argb.red,
            green: argb.green,
            blue: argb.blue,
            opacity: argb.alpha
        )
    }

    init(argbHex: UInt32) {
        self.init(argb: ArgbColor.hex(argbHex))
    }

    init(hex: UInt32) {
        self.init(argbHex: hex)
    }
}

extension ArgbColor {
    var color: Color {
        Color(argb: self)
    }
}

struct QiblaAlignmentColors: Sendable {
    let hubFill: Color
    let border: Color
    let borderLight: Color
    let borderDark: Color
    let glow: Color
    let accent: Color
}

struct SirajResolvedTheme: Sendable {
    let scheme: SirajColorSchemeSpec
    let settings: SettingsSnapshot
    let localizer: SirajLocalizer
    var systemReduceMotion: Bool = false

    var isDark: Bool { scheme.isDark }
    var isBlack: Bool { scheme.isBlack }
    var isGlass: Bool { settings.isGlassUi }
    var glassFinish: GlassFinish { settings.glassFinish }
    var isLiveBackground: Bool { settings.isLiveBackgroundEnabled }
    var motionEnabled: Bool { !settings.isReduceMotionEnabled && !systemReduceMotion }
    var textScale: CGFloat { CGFloat(settings.textScale) }
    var language: String { settings.language }
    var isRTL: Bool { localizer.isRTL(settings.language) }

    var primary: Color { Color(argb: scheme.primary) }
    var onPrimary: Color { Color(argb: scheme.onPrimary) }
    var primaryContainer: Color { Color(argb: scheme.primaryContainer) }
    var onPrimaryContainer: Color { Color(argb: scheme.onPrimaryContainer) }
    var secondary: Color { Color(argb: scheme.secondary) }
    var secondaryContainer: Color { Color(argb: scheme.secondaryContainer) }
    var onSecondaryContainer: Color { Color(argb: scheme.onSecondaryContainer) }
    var background: Color { Color(argb: scheme.background) }
    var surface: Color { Color(argb: scheme.surface) }
    var surfaceVariant: Color { Color(argb: scheme.surfaceVariant) }
    var onBackground: Color { Color(argb: scheme.onBackground) }
    var onSurface: Color { Color(argb: scheme.onSurface) }
    var onSurfaceVariant: Color { Color(argb: scheme.onSurfaceVariant) }
    var outline: Color { Color(argb: scheme.outline) }
    var outlineVariant: Color { Color(argb: scheme.outlineVariant) }
    var surfaceContainerLow: Color { Color(argb: scheme.surfaceContainerLow) }
    var surfaceContainer: Color { Color(argb: scheme.surfaceContainer) }
    var surfaceContainerHigh: Color { Color(argb: scheme.surfaceContainerHigh) }
    var gold: Color { Color(argb: scheme.gold) }
    var tertiary: Color { Color(argb: scheme.secondary) }
    var error: Color { Color(argbHex: isDark ? 0xFFF2B8B5 : 0xFFB3261E) }

    var alignmentColors: QiblaAlignmentColors {
        let lightSpec = SirajColorSchemeSpec.resolve(palette: settings.themePalette, isDark: false, isBlack: false)
        let darkSpec = SirajColorSchemeSpec.resolve(palette: settings.themePalette, isDark: true, isBlack: false)
        let palette = SirajPalettes.canonicalId(settings.themePalette)
        let keepDeepHub = palette == "Sand" || palette == "Olive" || palette == "Gold"
        return QiblaAlignmentColors(
            hubFill: (isDark && !keepDeepHub) ? Color(argb: lightSpec.secondary) : Color(argb: lightSpec.primary),
            border: isDark ? Color(argb: darkSpec.primary) : Color(argb: lightSpec.secondary),
            borderLight: Color(argb: darkSpec.secondary),
            borderDark: Color(argb: lightSpec.primary),
            glow: Color(argb: darkSpec.primary),
            accent: isDark ? Color(argb: darkSpec.primary) : Color(argb: lightSpec.primary)
        )
    }

    func t(_ key: String) -> String {
        localizer.string(key, lang: settings.language)
    }

    func t(_ key: String, _ args: Any...) -> String {
        localizer.formatArray(key, lang: settings.language, args: args)
    }

    func tf(_ key: String, _ args: Any...) -> String {
        localizer.formatArray(key, lang: settings.language, args: args)
    }

    func plural(_ key: String, count: Int, _ args: Any...) -> String {
        localizer.pluralArray(key, count: count, lang: settings.language, args: args)
    }

    func digits(_ raw: String, isQuran: Bool = false) -> String {
        DigitFormatter.localizeDigits(
            raw,
            numeralSystem: settings.numeralSystem,
            lang: settings.language,
            isQuran: isQuran,
            quranException: settings.isQuranNumeralException
        )
    }

    func scaledFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        .system(size: size * textScale, weight: weight, design: design)
    }

    func amiriFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Amiri-Regular", size: size * textScale).weight(weight)
    }

    func hafsFont(size: CGFloat) -> Font {
        .custom("KFGQPCHAFSUthmanicScript-Regula", size: size * textScale)
    }

    func quranMadinahFont(size: CGFloat) -> Font {
        .custom("DigitalKhattOldMadinaRegular", size: size * textScale)
    }

    func quranIndopakFont(size: CGFloat) -> Font {
        .custom("DigitalKhattIndoPakRegular", size: size * textScale)
    }

    func quranShamarlyFont(size: CGFloat) -> Font {
        .custom("AmiriQuran-Regular", size: size * textScale)
    }

    static let placeholder = SirajResolvedTheme(
        scheme: SirajColorSchemeSpec.resolve(palette: "Emerald", isDark: false, isBlack: false),
        settings: SettingsSnapshot(),
        localizer: SirajLocalizer(tables: [:])
    )
}

private struct SirajThemeKey: EnvironmentKey {
    static let defaultValue: SirajResolvedTheme = .placeholder
}

extension EnvironmentValues {
    var sirajTheme: SirajResolvedTheme {
        get { self[SirajThemeKey.self] }
        set { self[SirajThemeKey.self] = newValue }
    }
}

struct SirajThemeProvider<Content: View>: View {
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    let settings: SettingsSnapshot
    let localizer: SirajLocalizer
    let content: Content

    init(settings: SettingsSnapshot, localizer: SirajLocalizer, @ViewBuilder content: () -> Content) {
        self.settings = settings
        self.localizer = localizer
        self.content = content()
    }

    private var effectiveDark: Bool {
        switch settings.themeMode {
        case .light: return false
        case .dark: return true
        case .system: return systemColorScheme == .dark
        }
    }

    private var effectiveBlack: Bool {
        effectiveDark && settings.isAmoled
    }

    private var preferredColorScheme: ColorScheme? {
        switch settings.themeMode {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    var body: some View {
        let scheme = SirajColorSchemeSpec.resolve(
            palette: settings.themePalette,
            isDark: effectiveDark,
            isBlack: effectiveBlack
        )
        let resolved = SirajResolvedTheme(
            scheme: scheme,
            settings: settings,
            localizer: localizer,
            systemReduceMotion: systemReduceMotion
        )
        content
            .environment(\.sirajTheme, resolved)
            .environment(\.layoutDirection, resolved.isRTL ? .rightToLeft : .leftToRight)
            .preferredColorScheme(preferredColorScheme)
            .tint(resolved.primary)
    }
}
