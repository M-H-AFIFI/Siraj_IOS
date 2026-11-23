import Foundation

public enum WidgetFace: String, CaseIterable, Codable, Sendable, Identifiable {
    case next = "NEXT"
    case today = "TODAY"
    case list = "LIST"
    case clock = "CLOCK"
    case hijri = "HIJRI"
    case adhkar = "ADHKAR"
    case spot = "SPOT"
    case ring = "RING"
    case dual = "DUAL"
    case day = "DAY"
    case moon = "MOON"
    case tasbih = "TASBIH"
    case month = "MONTH"
    case countdown = "COUNTDOWN"
    case hadith = "HADITH"
    case dhikr = "DHIKR"
    case ayah = "AYAH"
    case fast = "FAST"
    case read = "READ"
    case date = "DATE"
    case verseCard = "VERSE_CARD"

    public var id: String { rawValue }

    public var needsLocation: Bool {
        switch self {
        case .next, .today, .list, .clock, .spot, .ring, .dual, .day, .fast:
            return true
        default:
            return false
        }
    }

    public var showsProgress: Bool {
        switch self {
        case .spot, .ring, .dual, .day, .fast:
            return true
        default:
            return false
        }
    }

    public static let milestone1PrayerFaces: [WidgetFace] = [.next, .today, .list, .spot, .ring, .dual, .day]
    public static let milestone1HijriMoonFaces: [WidgetFace] = [.hijri, .month, .date, .moon, .countdown]
}

public enum WidgetBackgroundStyle: String, CaseIterable, Codable, Sendable, Identifiable {
    case soft = "SOFT"
    case colour = "COLOUR"
    case tintedGlass = "GLASS"

    public var id: String { rawValue }
}

public enum ClockStyle: String, CaseIterable, Codable, Sendable, Identifiable {
    case classic = "CLASSIC"
    case bold = "BOLD"
    case serif = "SERIF"
    case condensed = "CONDENSED"
    case handwritten = "HANDWRITTEN"
    case marker = "MARKER"
    case analog = "ANALOG"
    case ink = "INK"
    case star = "STAR"

    public var id: String { rawValue }

    public var isDial: Bool {
        self == .analog || self == .ink || self == .star
    }
}

public enum QuoteRotation: String, CaseIterable, Codable, Sendable, Identifiable {
    case hour = "HOUR"
    case prayer = "PRAYER"
    case day = "DAY"

    public var id: String { rawValue }
}

/// Complete colour role set derived from any of Siraj's 15 palettes (matching Android's withDerivedNeutrals).
public struct SirajColorSchemeSpec: Sendable, Equatable {
    public let primary: ArgbColor
    public let onPrimary: ArgbColor
    public let primaryContainer: ArgbColor
    public let onPrimaryContainer: ArgbColor
    public let secondary: ArgbColor
    public let secondaryContainer: ArgbColor
    public let onSecondaryContainer: ArgbColor
    public let background: ArgbColor
    public let surface: ArgbColor
    public let surfaceVariant: ArgbColor
    public let onBackground: ArgbColor
    public let onSurface: ArgbColor
    public let onSurfaceVariant: ArgbColor
    public let outline: ArgbColor
    public let outlineVariant: ArgbColor
    public let surfaceContainerLow: ArgbColor
    public let surfaceContainer: ArgbColor
    public let surfaceContainerHigh: ArgbColor
    public let gold: ArgbColor
    public let isDark: Bool
    public let isBlack: Bool

    public static func resolve(palette: String, isDark: Bool, isBlack: Bool) -> SirajColorSchemeSpec {
        let def = SirajPalettes.definition(for: palette)
        let darkMode = isDark || isBlack
        let roles = darkMode ? def.dark : def.light
        let primary = ArgbColor.hex(roles.primary)
        let background = isBlack ? ArgbColor.hex(0xFF000000) : ArgbColor.hex(roles.background)
        let surface = isBlack ? ArgbColor.hex(0xFF000000) : ArgbColor.hex(roles.surface)
        let surfaceVariant = isBlack ? ArgbColor.hex(0xFF121212) : ArgbColor.hex(roles.surfaceVariant)
        let onSurface = ArgbColor.hex(roles.onSurface)
        let secondary = ArgbColor.lerp(primary, darkMode ? surfaceVariant : onSurface, 0.30)
        let secondaryContainer = ArgbColor.lerp(surface, primary, darkMode ? 0.30 : 0.15)
        let onSecondaryContainer = secondaryContainer.luminance > 0.45 ? ArgbColor.hex(0xFF1A1A1A) : ArgbColor.hex(0xFFFFFFFF)

        return SirajColorSchemeSpec(
            primary: primary,
            onPrimary: ArgbColor.hex(roles.onPrimary),
            primaryContainer: ArgbColor.hex(roles.primaryContainer),
            onPrimaryContainer: ArgbColor.hex(roles.onPrimaryContainer),
            secondary: secondary,
            secondaryContainer: secondaryContainer,
            onSecondaryContainer: onSecondaryContainer,
            background: background,
            surface: surface,
            surfaceVariant: surfaceVariant,
            onBackground: ArgbColor.hex(roles.onBackground),
            onSurface: onSurface,
            onSurfaceVariant: ArgbColor.lerp(surface, onSurface, 0.70),
            outline: ArgbColor.lerp(surface, onSurface, 0.50),
            outlineVariant: ArgbColor.lerp(surface, onSurface, 0.20),
            surfaceContainerLow: darkMode ? ArgbColor.lerp(background, surface, 0.50) : ArgbColor.lerp(surface, background, 0.55),
            surfaceContainer: darkMode ? surface : background,
            surfaceContainerHigh: darkMode ? ArgbColor.lerp(surface, surfaceVariant, 0.60) : ArgbColor.lerp(background, surfaceVariant, 0.70),
            gold: ArgbColor.hex(darkMode ? SirajPalettes.sirajGoldDark : SirajPalettes.sirajGoldLight),
            isDark: darkMode,
            isBlack: isBlack
        )
    }
}
