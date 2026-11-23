import SwiftUI
import SirajCore

public extension Color {
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
}

public struct SirajResolvedTheme: Sendable {
    public let scheme: SirajColorSchemeSpec
    public let settings: SettingsSnapshot
    public let localizer: SirajLocalizer
    public let systemReduceMotion: Bool

    public init(
        scheme: SirajColorSchemeSpec,
        settings: SettingsSnapshot,
        localizer: SirajLocalizer,
        systemReduceMotion: Bool = false
    ) {
        self.scheme = scheme
        self.settings = settings
        self.localizer = localizer
        self.systemReduceMotion = systemReduceMotion
    }

    public var isDark: Bool { scheme.isDark }
    public var isBlack: Bool { scheme.isBlack }
    public var isGlass: Bool { settings.isGlassUi }
    public var glassFinish: GlassFinish { settings.glassFinish }
    public var isLiveBackground: Bool { settings.isLiveBackgroundEnabled }
    public var motionEnabled: Bool { !settings.isReduceMotionEnabled && !systemReduceMotion }
    public var textScale: CGFloat { CGFloat(settings.textScale) }
    public var language: String { settings.language }
    public var isRTL: Bool { localizer.isRTL(settings.language) }

    public var primary: Color { Color(argb: scheme.primary) }
    public var onPrimary: Color { Color(argb: scheme.onPrimary) }
    public var primaryContainer: Color { Color(argb: scheme.primaryContainer) }
    public var onPrimaryContainer: Color { Color(argb: scheme.onPrimaryContainer) }
    public var secondary: Color { Color(argb: scheme.secondary) }
    public var secondaryContainer: Color { Color(argb: scheme.secondaryContainer) }
    public var onSecondaryContainer: Color { Color(argb: scheme.onSecondaryContainer) }
    public var background: Color { Color(argb: scheme.background) }
    public var surface: Color { Color(argb: scheme.surface) }
    public var surfaceVariant: Color { Color(argb: scheme.surfaceVariant) }
    public var onBackground: Color { Color(argb: scheme.onBackground) }
    public var onSurface: Color { Color(argb: scheme.onSurface) }
    public var onSurfaceVariant: Color { Color(argb: scheme.onSurfaceVariant) }
    public var outline: Color { Color(argb: scheme.outline) }
    public var outlineVariant: Color { Color(argb: scheme.outlineVariant) }
    public var surfaceContainerLow: Color { Color(argb: scheme.surfaceContainerLow) }
    public var surfaceContainer: Color { Color(argb: scheme.surfaceContainer) }
    public var surfaceContainerHigh: Color { Color(argb: scheme.surfaceContainerHigh) }
    public var gold: Color { Color(argb: scheme.gold) }

    public func t(_ key: String) -> String {
        localizer.string(key, lang: settings.language)
    }

    public func tf(_ key: String, _ args: Any...) -> String {
        localizer.formatArray(key, lang: settings.language, args: args)
    }

    public func digits(_ raw: String, isQuran: Bool = false) -> String {
        DigitFormatter.localizeDigits(
            raw,
            numeralSystem: settings.numeralSystem,
            lang: settings.language,
            isQuran: isQuran,
            quranException: settings.isQuranNumeralException
        )
    }

    public func scaledFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        .system(size: size * textScale, weight: weight, design: design)
    }

    public func amiriFont(size: CGFloat) -> Font {
        .custom("Amiri-Regular", size: size * textScale)
    }

    public static let placeholder = SirajResolvedTheme(
        scheme: SirajColorSchemeSpec.resolve(palette: "Emerald", isDark: false, isBlack: false),
        settings: SettingsSnapshot(),
        localizer: SirajLocalizer(tables: [:])
    )
}

private struct SirajThemeKey: EnvironmentKey {
    static let defaultValue: SirajResolvedTheme = .placeholder
}

public extension EnvironmentValues {
    var sirajTheme: SirajResolvedTheme {
        get { self[SirajThemeKey.self] }
        set { self[SirajThemeKey.self] = newValue }
    }
}

public struct SirajThemeProvider<Content: View>: View {
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    let settings: SettingsSnapshot
    let localizer: SirajLocalizer
    let content: Content

    public init(settings: SettingsSnapshot, localizer: SirajLocalizer, @ViewBuilder content: () -> Content) {
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

    public var body: some View {
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
