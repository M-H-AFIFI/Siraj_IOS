import Foundation

public struct PaletteBaseRoles: Sendable, Equatable {
    public let primary: UInt32
    public let onPrimary: UInt32
    public let primaryContainer: UInt32
    public let onPrimaryContainer: UInt32
    public let background: UInt32
    public let surface: UInt32
    public let surfaceVariant: UInt32
    public let onBackground: UInt32
    public let onSurface: UInt32

    public init(
        primary: UInt32, onPrimary: UInt32, primaryContainer: UInt32, onPrimaryContainer: UInt32,
        background: UInt32, surface: UInt32, surfaceVariant: UInt32, onBackground: UInt32, onSurface: UInt32
    ) {
        self.primary = primary
        self.onPrimary = onPrimary
        self.primaryContainer = primaryContainer
        self.onPrimaryContainer = onPrimaryContainer
        self.background = background
        self.surface = surface
        self.surfaceVariant = surfaceVariant
        self.onBackground = onBackground
        self.onSurface = onSurface
    }
}

public struct PaletteDefinition: Sendable, Equatable, Identifiable {
    public let id: String
    public let light: PaletteBaseRoles
    public let dark: PaletteBaseRoles
}

public enum SirajPalettes {
    public static let sirajGoldDark: UInt32 = 0xFFD4AF37
    public static let sirajGoldLight: UInt32 = 0xFF8A6A16

    public static let activeIds: [String] = [
        "Emerald", "Lime", "Olive", "TealCaspian", "OceanBlue", "RoyalIndigo", "Slate", "Silver", "White", "Rose", "Red", "Burgundy", "Coffee", "Sand", "Gold"
    ]

    public static let all: [PaletteDefinition] = [
        PaletteDefinition(
            id: "Emerald",
            light: PaletteBaseRoles(primary: 0xFF059669, onPrimary: 0xFFFFFFFF, primaryContainer: 0xFFD1FAE5, onPrimaryContainer: 0xFF064E3B, background: 0xFFF9FAFB, surface: 0xFFFFFFFF, surfaceVariant: 0xFFF3F4F6, onBackground: 0xFF111827, onSurface: 0xFF111827),
            dark: PaletteBaseRoles(primary: 0xFF34D399, onPrimary: 0xFF064E3B, primaryContainer: 0xFF064E3B, onPrimaryContainer: 0xFFA7F3D0, background: 0xFF121212, surface: 0xFF1E1E1E, surfaceVariant: 0xFF282828, onBackground: 0xFFEDEAE5, onSurface: 0xFFEDEAE5)
        ),
        PaletteDefinition(
            id: "Lime",
            light: PaletteBaseRoles(primary: 0xFF4D7C0F, onPrimary: 0xFFFFFFFF, primaryContainer: 0xFFECFCCB, onPrimaryContainer: 0xFF1A2E05, background: 0xFFF9FAF6, surface: 0xFFFFFFFF, surfaceVariant: 0xFFEFF5E5, onBackground: 0xFF1C280D, onSurface: 0xFF1C280D),
            dark: PaletteBaseRoles(primary: 0xFFA3E635, onPrimary: 0xFF1A2E05, primaryContainer: 0xFF1A2E05, onPrimaryContainer: 0xFFD9F99D, background: 0xFF121212, surface: 0xFF1E1E1E, surfaceVariant: 0xFF282828, onBackground: 0xFFEDEAE5, onSurface: 0xFFEDEAE5)
        ),
        PaletteDefinition(
            id: "Olive",
            light: PaletteBaseRoles(primary: 0xFF5F6B1E, onPrimary: 0xFFFFFFFF, primaryContainer: 0xFFEEF0D9, onPrimaryContainer: 0xFF2A300D, background: 0xFFF9F9F3, surface: 0xFFFFFFFF, surfaceVariant: 0xFFEFF0E2, onBackground: 0xFF23260F, onSurface: 0xFF23260F),
            dark: PaletteBaseRoles(primary: 0xFFC5CB86, onPrimary: 0xFF2A300D, primaryContainer: 0xFF363C14, onPrimaryContainer: 0xFFEEF0D9, background: 0xFF121212, surface: 0xFF1E1E1E, surfaceVariant: 0xFF282828, onBackground: 0xFFEDEAE5, onSurface: 0xFFEDEAE5)
        ),
        PaletteDefinition(
            id: "TealCaspian",
            light: PaletteBaseRoles(primary: 0xFF0F766E, onPrimary: 0xFFFFFFFF, primaryContainer: 0xFFCCFBF1, onPrimaryContainer: 0xFF134E4A, background: 0xFFF6FAF9, surface: 0xFFFFFFFF, surfaceVariant: 0xFFE6F4F1, onBackground: 0xFF0D2825, onSurface: 0xFF0D2825),
            dark: PaletteBaseRoles(primary: 0xFF2DD4BF, onPrimary: 0xFF042F2E, primaryContainer: 0xFF042F2E, onPrimaryContainer: 0xFF99F6E4, background: 0xFF121212, surface: 0xFF1E1E1E, surfaceVariant: 0xFF282828, onBackground: 0xFFEDEAE5, onSurface: 0xFFEDEAE5)
        ),
        PaletteDefinition(
            id: "OceanBlue",
            light: PaletteBaseRoles(primary: 0xFF0284C7, onPrimary: 0xFFFFFFFF, primaryContainer: 0xFFE0F2FE, onPrimaryContainer: 0xFF0369A1, background: 0xFFF9FAFB, surface: 0xFFFFFFFF, surfaceVariant: 0xFFF3F4F6, onBackground: 0xFF111827, onSurface: 0xFF111827),
            dark: PaletteBaseRoles(primary: 0xFF38BDF8, onPrimary: 0xFF082F49, primaryContainer: 0xFF082F49, onPrimaryContainer: 0xFFBAE6FD, background: 0xFF121212, surface: 0xFF1E1E1E, surfaceVariant: 0xFF282828, onBackground: 0xFFEDEAE5, onSurface: 0xFFEDEAE5)
        ),
        PaletteDefinition(
            id: "RoyalIndigo",
            light: PaletteBaseRoles(primary: 0xFF4F46E5, onPrimary: 0xFFFFFFFF, primaryContainer: 0xFFEEF2FF, onPrimaryContainer: 0xFF1E1B4B, background: 0xFFF9FAFB, surface: 0xFFFFFFFF, surfaceVariant: 0xFFF3F4F6, onBackground: 0xFF111827, onSurface: 0xFF111827),
            dark: PaletteBaseRoles(primary: 0xFF818CF8, onPrimary: 0xFF1E1B4B, primaryContainer: 0xFF1E1B4B, onPrimaryContainer: 0xFFC7D2FE, background: 0xFF121212, surface: 0xFF1E1E1E, surfaceVariant: 0xFF282828, onBackground: 0xFFEDEAE5, onSurface: 0xFFEDEAE5)
        ),
        PaletteDefinition(
            id: "Slate",
            light: PaletteBaseRoles(primary: 0xFF475569, onPrimary: 0xFFFFFFFF, primaryContainer: 0xFFE2E8F0, onPrimaryContainer: 0xFF1E293B, background: 0xFFF8FAFC, surface: 0xFFFFFFFF, surfaceVariant: 0xFFEEF1F5, onBackground: 0xFF0F172A, onSurface: 0xFF0F172A),
            dark: PaletteBaseRoles(primary: 0xFFA8B5C7, onPrimary: 0xFF1E293B, primaryContainer: 0xFF334155, onPrimaryContainer: 0xFFE2E8F0, background: 0xFF121212, surface: 0xFF1E1E1E, surfaceVariant: 0xFF282828, onBackground: 0xFFEDEAE5, onSurface: 0xFFEDEAE5)
        ),
        PaletteDefinition(
            id: "Silver",
            light: PaletteBaseRoles(primary: 0xFF4B5563, onPrimary: 0xFFFFFFFF, primaryContainer: 0xFFE5E9F0, onPrimaryContainer: 0xFF1F242D, background: 0xFFF7F9FB, surface: 0xFFFFFFFF, surfaceVariant: 0xFFEDF1F6, onBackground: 0xFF14181F, onSurface: 0xFF14181F),
            dark: PaletteBaseRoles(primary: 0xFFD5DCE6, onPrimary: 0xFF1F242D, primaryContainer: 0xFF2A303B, onPrimaryContainer: 0xFFF1F5F9, background: 0xFF111316, surface: 0xFF1B1E23, surfaceVariant: 0xFF262A31, onBackground: 0xFFECEFF4, onSurface: 0xFFECEFF4)
        ),
        PaletteDefinition(
            id: "White",
            light: PaletteBaseRoles(primary: 0xFF27272A, onPrimary: 0xFFFFFFFF, primaryContainer: 0xFFF4F4F5, onPrimaryContainer: 0xFF18181B, background: 0xFFFCFCFD, surface: 0xFFFFFFFF, surfaceVariant: 0xFFF4F4F5, onBackground: 0xFF09090B, onSurface: 0xFF09090B),
            dark: PaletteBaseRoles(primary: 0xFFF4F4F5, onPrimary: 0xFF18181B, primaryContainer: 0xFF27272A, onPrimaryContainer: 0xFFFAFAFA, background: 0xFF121214, surface: 0xFF1C1C1F, surfaceVariant: 0xFF27272A, onBackground: 0xFFF4F4F5, onSurface: 0xFFF4F4F5)
        ),
        PaletteDefinition(
            id: "Rose",
            light: PaletteBaseRoles(primary: 0xFFDB2777, onPrimary: 0xFFFFFFFF, primaryContainer: 0xFFFCE7F3, onPrimaryContainer: 0xFF70073B, background: 0xFFF9FAFB, surface: 0xFFFFFFFF, surfaceVariant: 0xFFF3F4F6, onBackground: 0xFF111827, onSurface: 0xFF111827),
            dark: PaletteBaseRoles(primary: 0xFFF472B6, onPrimary: 0xFF500724, primaryContainer: 0xFF500724, onPrimaryContainer: 0xFFFBCFE8, background: 0xFF121212, surface: 0xFF1E1E1E, surfaceVariant: 0xFF282828, onBackground: 0xFFEDEAE5, onSurface: 0xFFEDEAE5)
        ),
        PaletteDefinition(
            id: "Red",
            light: PaletteBaseRoles(primary: 0xFFB91C1C, onPrimary: 0xFFFFFFFF, primaryContainer: 0xFFFEE2E2, onPrimaryContainer: 0xFF450A0A, background: 0xFFFCF8F8, surface: 0xFFFFFFFF, surfaceVariant: 0xFFF6ECEC, onBackground: 0xFF241212, onSurface: 0xFF241212),
            dark: PaletteBaseRoles(primary: 0xFFF87171, onPrimary: 0xFF450A0A, primaryContainer: 0xFF450A0A, onPrimaryContainer: 0xFFFECACA, background: 0xFF131111, surface: 0xFF1E1A1A, surfaceVariant: 0xFF292323, onBackground: 0xFFF3ECEC, onSurface: 0xFFF3ECEC)
        ),
        PaletteDefinition(
            id: "Burgundy",
            light: PaletteBaseRoles(primary: 0xFF8E2C3E, onPrimary: 0xFFFFFFFF, primaryContainer: 0xFFF8E1E4, onPrimaryContainer: 0xFF4A0F1C, background: 0xFFFBF7F7, surface: 0xFFFFFFFF, surfaceVariant: 0xFFF4E9EA, onBackground: 0xFF24161A, onSurface: 0xFF24161A),
            dark: PaletteBaseRoles(primary: 0xFFF2A7A9, onPrimary: 0xFF4A0F1C, primaryContainer: 0xFF5C1A26, onPrimaryContainer: 0xFFFADADD, background: 0xFF121212, surface: 0xFF1E1E1E, surfaceVariant: 0xFF282828, onBackground: 0xFFEDEAE5, onSurface: 0xFFEDEAE5)
        ),
        PaletteDefinition(
            id: "Coffee",
            light: PaletteBaseRoles(primary: 0xFF7B4F2F, onPrimary: 0xFFFFFFFF, primaryContainer: 0xFFF6EBE1, onPrimaryContainer: 0xFF3D2415, background: 0xFFFBF8F5, surface: 0xFFFFFFFF, surfaceVariant: 0xFFF3ECE5, onBackground: 0xFF231A14, onSurface: 0xFF231A14),
            dark: PaletteBaseRoles(primary: 0xFFD9A77C, onPrimary: 0xFF3D2415, primaryContainer: 0xFF4A2C1A, onPrimaryContainer: 0xFFF6EBE1, background: 0xFF121212, surface: 0xFF1E1E1E, surfaceVariant: 0xFF282828, onBackground: 0xFFEDEAE5, onSurface: 0xFFEDEAE5)
        ),
        PaletteDefinition(
            id: "Sand",
            light: PaletteBaseRoles(primary: 0xFF8C6A3C, onPrimary: 0xFFFFFFFF, primaryContainer: 0xFFF1E4C8, onPrimaryContainer: 0xFF3E2E14, background: 0xFFF7F1E5, surface: 0xFFFFFCF6, surfaceVariant: 0xFFEFE5D2, onBackground: 0xFF2A2318, onSurface: 0xFF2A2318),
            dark: PaletteBaseRoles(primary: 0xFFE2C793, onPrimary: 0xFF3A2B12, primaryContainer: 0xFF4A3A1F, onPrimaryContainer: 0xFFF3E3C2, background: 0xFF14120E, surface: 0xFF1F1C16, surfaceVariant: 0xFF2A261F, onBackground: 0xFFEDE6DA, onSurface: 0xFFEDE6DA)
        ),
        PaletteDefinition(
            id: "Gold",
            light: PaletteBaseRoles(primary: 0xFF946F00, onPrimary: 0xFFFFFFFF, primaryContainer: 0xFFFBEFC9, onPrimaryContainer: 0xFF3D2C00, background: 0xFFFBF8EE, surface: 0xFFFFFFFF, surfaceVariant: 0xFFF6EED8, onBackground: 0xFF2B2410, onSurface: 0xFF2B2410),
            dark: PaletteBaseRoles(primary: 0xFFF0C24B, onPrimary: 0xFF3D2C00, primaryContainer: 0xFF4A3800, onPrimaryContainer: 0xFFFBE7B0, background: 0xFF121212, surface: 0xFF1E1E1E, surfaceVariant: 0xFF282828, onBackground: 0xFFEDEAE5, onSurface: 0xFFEDEAE5)
        ),
    ]

    public static let byId: [String: PaletteDefinition] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    public static func canonicalId(_ raw: String) -> String {
        switch raw {
        case "RoyalIndigo", "ImperialOud", "RoyalAmethyst": return "RoyalIndigo"
        case "Emerald", "MedinaDawn", "Colorful": return "Emerald"
        case "Rose", "CrimsonVelvet", "SaharaDusk": return "Rose"
        case "OceanBlue", "BlueNile": return "OceanBlue"
        case "Coffee", "Violet", "GoldenAmber", "Daylight", "GoldenOasis": return "Coffee"
        case "TealCaspian", "Midnight": return "TealCaspian"
        case "Sand", "OliveSage", "AmoledBlack", "PureNight": return "Sand"
        case "Lime": return "Lime"
        case "Olive": return "Olive"
        case "Slate": return "Slate"
        case "Silver": return "Silver"
        case "White": return "White"
        case "Red": return "Red"
        case "Burgundy": return "Burgundy"
        case "Gold": return "Gold"
        default: return "Emerald"
        }
    }

    public static func definition(for name: String) -> PaletteDefinition {
        byId[canonicalId(name)] ?? all[0]
    }
}
