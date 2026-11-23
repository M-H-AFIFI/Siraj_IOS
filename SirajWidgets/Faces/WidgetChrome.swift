import SwiftUI
import WidgetKit
import SirajCore

extension Color {
    init(argb: ArgbColor) {
        self.init(.sRGB, red: argb.red, green: argb.green, blue: argb.blue, opacity: argb.alpha)
    }

    init(argbHex: UInt32) {
        self.init(argb: ArgbColor.hex(argbHex))
    }
}

struct WidgetPaletteStyle {
    let scheme: SirajColorSchemeSpec
    let backgroundStyle: WidgetBackgroundStyle

    var isFilled: Bool { backgroundStyle == .colour }

    var primaryText: Color {
        isFilled ? Color(argb: scheme.onPrimary) : Color(argb: scheme.onSurface)
    }

    var secondaryText: Color {
        isFilled ? Color(argb: scheme.onPrimary).opacity(0.76) : Color(argb: scheme.onSurfaceVariant)
    }

    var accent: Color {
        isFilled ? Color(argb: scheme.gold) : Color(argb: scheme.primary)
    }

    var subtleFill: Color {
        isFilled ? Color(argb: scheme.onPrimary).opacity(0.14) : Color(argb: scheme.primary).opacity(0.12)
    }

    var plateBackground: some View {
        Group {
            switch backgroundStyle {
            case .soft:
                LinearGradient(
                    colors: [Color(argb: scheme.surface), Color(argb: scheme.surfaceContainerHigh)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .colour:
                LinearGradient(
                    colors: [Color(argb: scheme.primary), Color(argb: scheme.primary).opacity(0.82)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .tintedGlass:
                LinearGradient(
                    colors: [
                        Color(argb: scheme.surface).opacity(0.78),
                        Color(argb: scheme.primaryContainer).opacity(0.45)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    static func resolve(
        paletteOverride: String?,
        background: WidgetBackgroundStyle,
        settings: SettingsSnapshot,
        colorScheme: ColorScheme
    ) -> WidgetPaletteStyle {
        let paletteId = paletteOverride ?? settings.themePalette
        let isDark: Bool
        switch settings.themeMode {
        case .light: isDark = false
        case .dark: isDark = true
        case .system: isDark = (colorScheme == .dark)
        }
        let spec = SirajColorSchemeSpec.resolve(
            palette: paletteId,
            isDark: isDark,
            isBlack: isDark && settings.isAmoled
        )
        return WidgetPaletteStyle(scheme: spec, backgroundStyle: background)
    }
}

struct SirajWidgetContainer<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let snapshot: SirajWidgetSnapshot
    let paletteOverride: String?
    let backgroundStyle: WidgetBackgroundStyle
    let content: (WidgetPaletteStyle) -> Content

    init(
        snapshot: SirajWidgetSnapshot,
        paletteOverride: String?,
        backgroundStyle: WidgetBackgroundStyle,
        @ViewBuilder content: @escaping (WidgetPaletteStyle) -> Content
    ) {
        self.snapshot = snapshot
        self.paletteOverride = paletteOverride
        self.backgroundStyle = backgroundStyle
        self.content = content
    }

    var body: some View {
        let style = WidgetPaletteStyle.resolve(
            paletteOverride: paletteOverride,
            background: backgroundStyle,
            settings: snapshot.settings,
            colorScheme: colorScheme
        )
        content(style)
            .environment(\.layoutDirection, snapshot.isRTL ? .rightToLeft : .leftToRight)
            .containerBackground(for: .widget) {
                style.plateBackground
            }
    }
}

enum PrayerArabicCalligraphy {
    static func label(for prayer: PrayerType) -> String {
        switch prayer {
        case .fajr: return "الفجر"
        case .sunrise: return "الشروق"
        case .dhuhr: return "الظهر"
        case .asr: return "العصر"
        case .maghrib: return "المغرب"
        case .isha: return "العشاء"
        }
    }

    static func weekdayArabic(sundayZero: Int) -> String {
        let names = ["الأحد", "الإثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت"]
        return names[((sundayZero % 7) + 7) % 7]
    }
}
