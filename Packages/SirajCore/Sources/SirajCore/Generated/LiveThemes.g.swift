import Foundation

public struct LiveSceneColors: Sendable, Equatable {
    public let skyTop: UInt32
    public let skyUpperMid: UInt32
    public let skyLowerMid: UInt32
    public let skyHorizon: UInt32
    public let accentGlow: UInt32
    public let secondaryGlow: UInt32
    public let veilColor: UInt32
}

public struct LiveThemeDefinition: Sendable, Equatable, Identifiable {
    public let id: String
    public let titleKey: String
    public let subtitleKey: String
    public let pairedPaletteId: String
    public let swatchPrimary: UInt32
    public let swatchSecondary: UInt32
    public let light: LiveSceneColors
    public let dark: LiveSceneColors
    public let amoled: LiveSceneColors
}

public enum LiveThemeCatalog {
    public static let all: [LiveThemeDefinition] = [
        LiveThemeDefinition(
            id: "DesertDunes", titleKey: "live_theme_desert", subtitleKey: "live_theme_desert_sub", pairedPaletteId: "Sand",
            swatchPrimary: 0xFFD69A52, swatchSecondary: 0xFF8C5327,
            light: LiveSceneColors(skyTop: 0xFFE7D3B7, skyUpperMid: 0xFFF1DEC2, skyLowerMid: 0xFFF6E7CF, skyHorizon: 0xFFFDF3E4, accentGlow: 0xFFE59E49, secondaryGlow: 0xFFC97B36, veilColor: 0xFFFFFAF2),
            dark: LiveSceneColors(skyTop: 0xFF0E0B14, skyUpperMid: 0xFF1A1320, skyLowerMid: 0xFF2B1D24, skyHorizon: 0xFF432A22, accentGlow: 0xFFE09F54, secondaryGlow: 0xFF9C5E31, veilColor: 0xFF0D0A10),
            amoled: LiveSceneColors(skyTop: 0xFF000000, skyUpperMid: 0xFF050408, skyLowerMid: 0xFF130D12, skyHorizon: 0xFF281914, accentGlow: 0xFFD49248, secondaryGlow: 0xFF804B24, veilColor: 0xFF000000)
        ),
        LiveThemeDefinition(
            id: "SeaWaves", titleKey: "live_theme_sea", subtitleKey: "live_theme_sea_sub", pairedPaletteId: "TealCaspian",
            swatchPrimary: 0xFF1E9BB0, swatchSecondary: 0xFF66D4DF,
            light: LiveSceneColors(skyTop: 0xFFC2E7EE, skyUpperMid: 0xFFD5EFF4, skyLowerMid: 0xFFE6F6F9, skyHorizon: 0xFFF3FBFC, accentGlow: 0xFF209CB0, secondaryGlow: 0xFF5BC8D4, veilColor: 0xFFF4FCFD),
            dark: LiveSceneColors(skyTop: 0xFF06131C, skyUpperMid: 0xFF0A1F2C, skyLowerMid: 0xFF0F2E3F, skyHorizon: 0xFF164154, accentGlow: 0xFF38C0D4, secondaryGlow: 0xFF1E7E96, veilColor: 0xFF061118),
            amoled: LiveSceneColors(skyTop: 0xFF000000, skyUpperMid: 0xFF02090E, skyLowerMid: 0xFF071924, skyHorizon: 0xFF0E2B3A, accentGlow: 0xFF2FB3C7, secondaryGlow: 0xFF17667A, veilColor: 0xFF000000)
        ),
        LiveThemeDefinition(
            id: "Aurora", titleKey: "live_theme_aurora", subtitleKey: "live_theme_aurora_sub", pairedPaletteId: "Emerald",
            swatchPrimary: 0xFF28C997, swatchSecondary: 0xFF6A7FDB,
            light: LiveSceneColors(skyTop: 0xFFCCEBE3, skyUpperMid: 0xFFDDF3ED, skyLowerMid: 0xFFEAF7F5, skyHorizon: 0xFFF6FCFA, accentGlow: 0xFF23B88A, secondaryGlow: 0xFF6D83E0, veilColor: 0xFFF5FCFA),
            dark: LiveSceneColors(skyTop: 0xFF061017, skyUpperMid: 0xFF091B24, skyLowerMid: 0xFF0E2830, skyHorizon: 0xFF15343A, accentGlow: 0xFF35DEA8, secondaryGlow: 0xFF7B6CF0, veilColor: 0xFF060E14),
            amoled: LiveSceneColors(skyTop: 0xFF000000, skyUpperMid: 0xFF02080C, skyLowerMid: 0xFF07161C, skyHorizon: 0xFF0D2328, accentGlow: 0xFF2CC997, secondaryGlow: 0xFF6758D4, veilColor: 0xFF000000)
        ),
        LiveThemeDefinition(
            id: "NightStars", titleKey: "live_theme_night", subtitleKey: "live_theme_night_sub", pairedPaletteId: "Gold",
            swatchPrimary: 0xFFE3BC63, swatchSecondary: 0xFF3E5282,
            light: LiveSceneColors(skyTop: 0xFFD4DCF0, skyUpperMid: 0xFFE1E7F6, skyLowerMid: 0xFFEDF1FA, skyHorizon: 0xFFF7F8FC, accentGlow: 0xFFD4A446, secondaryGlow: 0xFF6B7EB8, veilColor: 0xFFF7F8FC),
            dark: LiveSceneColors(skyTop: 0xFF060913, skyUpperMid: 0xFF0B1122, skyLowerMid: 0xFF121B34, skyHorizon: 0xFF1B2748, accentGlow: 0xFFEAC56E, secondaryGlow: 0xFF5D76B5, veilColor: 0xFF060811),
            amoled: LiveSceneColors(skyTop: 0xFF000000, skyUpperMid: 0xFF02040A, skyLowerMid: 0xFF080D1B, skyHorizon: 0xFF111930, accentGlow: 0xFFE2BC64, secondaryGlow: 0xFF4C639C, veilColor: 0xFF000000)
        ),
        LiveThemeDefinition(
            id: "RosePetals", titleKey: "live_theme_rose", subtitleKey: "live_theme_rose_sub", pairedPaletteId: "Rose",
            swatchPrimary: 0xFFDE718C, swatchSecondary: 0xFFF5B5C5,
            light: LiveSceneColors(skyTop: 0xFFF4D6DF, skyUpperMid: 0xFFF8E3E9, skyLowerMid: 0xFFFBEFF2, skyHorizon: 0xFFFFF8FA, accentGlow: 0xFFD96884, secondaryGlow: 0xFFF0A1B5, veilColor: 0xFFFFF8FA),
            dark: LiveSceneColors(skyTop: 0xFF140910, skyUpperMid: 0xFF210F1B, skyLowerMid: 0xFF301726, skyHorizon: 0xFF422133, accentGlow: 0xFFE67A96, secondaryGlow: 0xFFB5516D, veilColor: 0xFF12080E),
            amoled: LiveSceneColors(skyTop: 0xFF000000, skyUpperMid: 0xFF080306, skyLowerMid: 0xFF180A12, skyHorizon: 0xFF29121F, accentGlow: 0xFFDB708C, secondaryGlow: 0xFF9E445D, veilColor: 0xFF000000)
        ),
        LiveThemeDefinition(
            id: "Snow", titleKey: "live_theme_snow", subtitleKey: "live_theme_snow_sub", pairedPaletteId: "Silver",
            swatchPrimary: 0xFF8AB8DC, swatchSecondary: 0xFFEAF4FC,
            light: LiveSceneColors(skyTop: 0xFFD5E4F0, skyUpperMid: 0xFFE2EDF6, skyLowerMid: 0xFFEEF5FA, skyHorizon: 0xFFF8FBFE, accentGlow: 0xFF75A9D4, secondaryGlow: 0xFFB5D4EE, veilColor: 0xFFF8FBFE),
            dark: LiveSceneColors(skyTop: 0xFF0A1018, skyUpperMid: 0xFF111B28, skyLowerMid: 0xFF192738, skyHorizon: 0xFF24364B, accentGlow: 0xFF9AC5E8, secondaryGlow: 0xFF5D84A8, veilColor: 0xFF090E15),
            amoled: LiveSceneColors(skyTop: 0xFF000000, skyUpperMid: 0xFF04070B, skyLowerMid: 0xFF0C131D, skyHorizon: 0xFF162231, accentGlow: 0xFF8EBBE0, secondaryGlow: 0xFF4A6D8C, veilColor: 0xFF000000)
        ),
        LiveThemeDefinition(
            id: "PurpleButterflies", titleKey: "live_theme_butterfly", subtitleKey: "live_theme_butterfly_sub", pairedPaletteId: "RoyalIndigo",
            swatchPrimary: 0xFF9F7AEA, swatchSecondary: 0xFFD6BCFA,
            light: LiveSceneColors(skyTop: 0xFFE1D5F5, skyUpperMid: 0xFFECE3FA, skyLowerMid: 0xFFF4EFFC, skyHorizon: 0xFFFAF8FF, accentGlow: 0xFF936CE0, secondaryGlow: 0xFFD49BE8, veilColor: 0xFFFAF8FF),
            dark: LiveSceneColors(skyTop: 0xFF0F091A, skyUpperMid: 0xFF19102B, skyLowerMid: 0xFF25183D, skyHorizon: 0xFF332252, accentGlow: 0xFFB28CFF, secondaryGlow: 0xFFE091C9, veilColor: 0xFF0D0817),
            amoled: LiveSceneColors(skyTop: 0xFF000000, skyUpperMid: 0xFF06030B, skyLowerMid: 0xFF130B21, skyHorizon: 0xFF201436, accentGlow: 0xFFA67FF5, secondaryGlow: 0xFFC97BB3, veilColor: 0xFF000000)
        ),
        LiveThemeDefinition(
            id: "Rings", titleKey: "live_theme_rings", subtitleKey: "live_theme_rings_sub", pairedPaletteId: "OceanBlue",
            swatchPrimary: 0xFF6B85C4, swatchSecondary: 0xFF3E5280,
            light: LiveSceneColors(skyTop: 0xFFE5ECF6, skyUpperMid: 0xFFEDF2FA, skyLowerMid: 0xFFF3F6FC, skyHorizon: 0xFFFAFBFD, accentGlow: 0xFF5372B8, secondaryGlow: 0xFF8AA4DB, veilColor: 0xFFFAFBFD),
            dark: LiveSceneColors(skyTop: 0xFF10131C, skyUpperMid: 0xFF141824, skyLowerMid: 0xFF181D2B, skyHorizon: 0xFF1E2434, accentGlow: 0xFF7B96D4, secondaryGlow: 0xFF4F679E, veilColor: 0xFF10131C),
            amoled: LiveSceneColors(skyTop: 0xFF000000, skyUpperMid: 0xFF06080E, skyLowerMid: 0xFF0B0E18, skyHorizon: 0xFF121724, accentGlow: 0xFF6E89C9, secondaryGlow: 0xFF42588A, veilColor: 0xFF000000)
        ),
        LiveThemeDefinition(
            id: "Circles", titleKey: "live_theme_circles", subtitleKey: "live_theme_circles_sub", pairedPaletteId: "RoyalIndigo",
            swatchPrimary: 0xFF7D78C9, swatchSecondary: 0xFF4E4B85,
            light: LiveSceneColors(skyTop: 0xFFE7E6F5, skyUpperMid: 0xFFEEEEF9, skyLowerMid: 0xFFF4F4FB, skyHorizon: 0xFFFAFAFE, accentGlow: 0xFF6863B8, secondaryGlow: 0xFF9C98DE, veilColor: 0xFFFAFAFE),
            dark: LiveSceneColors(skyTop: 0xFF11121B, skyUpperMid: 0xFF151722, skyLowerMid: 0xFF1A1C29, skyHorizon: 0xFF202333, accentGlow: 0xFF8C88D4, secondaryGlow: 0xFF5D599C, veilColor: 0xFF11121B),
            amoled: LiveSceneColors(skyTop: 0xFF000000, skyUpperMid: 0xFF07070D, skyLowerMid: 0xFF0D0E17, skyHorizon: 0xFF141623, accentGlow: 0xFF7F7BC7, secondaryGlow: 0xFF4E4B87, veilColor: 0xFF000000)
        ),
        LiveThemeDefinition(
            id: "Particles", titleKey: "live_theme_particles", subtitleKey: "live_theme_particles_sub", pairedPaletteId: "TealCaspian",
            swatchPrimary: 0xFF5FB0B7, swatchSecondary: 0xFF3E717A,
            light: LiveSceneColors(skyTop: 0xFFE2EFF1, skyUpperMid: 0xFFEAF4F5, skyLowerMid: 0xFFF2F8F9, skyHorizon: 0xFFFAFDFE, accentGlow: 0xFF3D9199, secondaryGlow: 0xFF7EC0C7, veilColor: 0xFFFAFDFE),
            dark: LiveSceneColors(skyTop: 0xFF0F1319, skyUpperMid: 0xFF131820, skyLowerMid: 0xFF181E27, skyHorizon: 0xFF1D2530, accentGlow: 0xFF7AC6CE, secondaryGlow: 0xFF4E838C, veilColor: 0xFF0F1319),
            amoled: LiveSceneColors(skyTop: 0xFF000000, skyUpperMid: 0xFF05080B, skyLowerMid: 0xFF0A1015, skyHorizon: 0xFF101921, accentGlow: 0xFF6DB8C0, secondaryGlow: 0xFF3F6F78, veilColor: 0xFF000000)
        ),
        LiveThemeDefinition(
            id: "LavaLamp", titleKey: "live_theme_lava_lamp", subtitleKey: "live_theme_lava_lamp_sub", pairedPaletteId: "Rose",
            swatchPrimary: 0xFFC27C98, swatchSecondary: 0xFF7A4B62,
            light: LiveSceneColors(skyTop: 0xFFF3E7EC, skyUpperMid: 0xFFF7EEF2, skyLowerMid: 0xFFFAF4F7, skyHorizon: 0xFFFFFAFC, accentGlow: 0xFFB36283, secondaryGlow: 0xFFD69CB4, veilColor: 0xFFFFFAFC),
            dark: LiveSceneColors(skyTop: 0xFF151218, skyUpperMid: 0xFF1A161F, skyLowerMid: 0xFF211B27, skyHorizon: 0xFF282130, accentGlow: 0xFFD18AA6, secondaryGlow: 0xFF8C5A70, veilColor: 0xFF151218),
            amoled: LiveSceneColors(skyTop: 0xFF000000, skyUpperMid: 0xFF09060B, skyLowerMid: 0xFF120C16, skyHorizon: 0xFF1B1321, accentGlow: 0xFFC47D99, secondaryGlow: 0xFF784B5F, veilColor: 0xFF000000)
        ),
        LiveThemeDefinition(
            id: "Space", titleKey: "live_theme_space", subtitleKey: "live_theme_space_sub", pairedPaletteId: "Gold",
            swatchPrimary: 0xFFD9BE7B, swatchSecondary: 0xFF6B7BA6,
            light: LiveSceneColors(skyTop: 0xFFEBE8DE, skyUpperMid: 0xFFF1EFE7, skyLowerMid: 0xFFF6F5F0, skyHorizon: 0xFFFCFCF9, accentGlow: 0xFFB59449, secondaryGlow: 0xFF6E7FA8, veilColor: 0xFFFCFCF9),
            dark: LiveSceneColors(skyTop: 0xFF0C0E14, skyUpperMid: 0xFF10131C, skyLowerMid: 0xFF151924, skyHorizon: 0xFF1B202E, accentGlow: 0xFFE0C88B, secondaryGlow: 0xFF7C8DB8, veilColor: 0xFF0C0E14),
            amoled: LiveSceneColors(skyTop: 0xFF000000, skyUpperMid: 0xFF040609, skyLowerMid: 0xFF090C12, skyHorizon: 0xFF10141E, accentGlow: 0xFFD4BC7F, secondaryGlow: 0xFF6A7AA3, veilColor: 0xFF000000)
        ),
        LiveThemeDefinition(
            id: "Silk", titleKey: "live_theme_silk", subtitleKey: "live_theme_silk_sub", pairedPaletteId: "Rose",
            swatchPrimary: 0xFFE07A86, swatchSecondary: 0xFF4AC2D4,
            light: LiveSceneColors(skyTop: 0xFFF4E9ED, skyUpperMid: 0xFFF8F0F3, skyLowerMid: 0xFFFBF6F8, skyHorizon: 0xFFFFFCFD, accentGlow: 0xFFD16674, secondaryGlow: 0xFF3EA8B8, veilColor: 0xFFFFFCFD),
            dark: LiveSceneColors(skyTop: 0xFF08090D, skyUpperMid: 0xFF0E1017, skyLowerMid: 0xFF151822, skyHorizon: 0xFF1B1F2B, accentGlow: 0xFFE07A86, secondaryGlow: 0xFF4AC2D4, veilColor: 0xFF08090D),
            amoled: LiveSceneColors(skyTop: 0xFF000000, skyUpperMid: 0xFF050609, skyLowerMid: 0xFF0B0D14, skyHorizon: 0xFF12151F, accentGlow: 0xFFD6727E, secondaryGlow: 0xFF42B3C4, veilColor: 0xFF000000)
        ),
        LiveThemeDefinition(
            id: "Contours", titleKey: "live_theme_contours", subtitleKey: "live_theme_contours_sub", pairedPaletteId: "TealCaspian",
            swatchPrimary: 0xFF4FA89C, swatchSecondary: 0xFFD4A259,
            light: LiveSceneColors(skyTop: 0xFFE3EFEF, skyUpperMid: 0xFFECF4F4, skyLowerMid: 0xFFF3F8F8, skyHorizon: 0xFFFAFDFD, accentGlow: 0xFF3E8E83, secondaryGlow: 0xFFC29048, veilColor: 0xFFFAFDFD),
            dark: LiveSceneColors(skyTop: 0xFF070C0D, skyUpperMid: 0xFF0B1315, skyLowerMid: 0xFF101C1E, skyHorizon: 0xFF162528, accentGlow: 0xFF56B3A6, secondaryGlow: 0xFFE0B066, veilColor: 0xFF070C0D),
            amoled: LiveSceneColors(skyTop: 0xFF000000, skyUpperMid: 0xFF030708, skyLowerMid: 0xFF081011, skyHorizon: 0xFF0E1A1C, accentGlow: 0xFF4BA397, secondaryGlow: 0xFFCF9F57, veilColor: 0xFF000000)
        ),
        LiveThemeDefinition(
            id: "Mosaic", titleKey: "live_theme_mosaic", subtitleKey: "live_theme_mosaic_sub", pairedPaletteId: "Rose",
            swatchPrimary: 0xFFAD5676, swatchSecondary: 0xFF514B7E,
            light: LiveSceneColors(skyTop: 0xFFF0E4EA, skyUpperMid: 0xFFF5ECF0, skyLowerMid: 0xFFF9F3F6, skyHorizon: 0xFFFEFAFC, accentGlow: 0xFF9C4B69, secondaryGlow: 0xFF5A548A, veilColor: 0xFFFEFAFC),
            dark: LiveSceneColors(skyTop: 0xFF120C14, skyUpperMid: 0xFF1B121D, skyLowerMid: 0xFF241727, skyHorizon: 0xFF2E1E32, accentGlow: 0xFFC76B8E, secondaryGlow: 0xFF69629E, veilColor: 0xFF120C14),
            amoled: LiveSceneColors(skyTop: 0xFF000000, skyUpperMid: 0xFF09050B, skyLowerMid: 0xFF120B15, skyHorizon: 0xFF1C1120, accentGlow: 0xFFB85E80, secondaryGlow: 0xFF5B558C, veilColor: 0xFF000000)
        ),
        LiveThemeDefinition(
            id: "Waves", titleKey: "live_theme_waves", subtitleKey: "live_theme_waves_sub", pairedPaletteId: "Gold",
            swatchPrimary: 0xFFC4A878, swatchSecondary: 0xFF7C664A,
            light: LiveSceneColors(skyTop: 0xFFF0EAE0, skyUpperMid: 0xFFF5F0E8, skyLowerMid: 0xFFF9F6F0, skyHorizon: 0xFFFEFCF9, accentGlow: 0xFFA6895A, secondaryGlow: 0xFF826B4E, veilColor: 0xFFFEFCF9),
            dark: LiveSceneColors(skyTop: 0xFF100E0C, skyUpperMid: 0xFF171411, skyLowerMid: 0xFF1F1B16, skyHorizon: 0xFF29241D, accentGlow: 0xFFCBB082, secondaryGlow: 0xFF8C7456, veilColor: 0xFF100E0C),
            amoled: LiveSceneColors(skyTop: 0xFF000000, skyUpperMid: 0xFF070605, skyLowerMid: 0xFF0F0D0A, skyHorizon: 0xFF181410, accentGlow: 0xFFBFA376, secondaryGlow: 0xFF7D674B, veilColor: 0xFF000000)
        ),
        LiveThemeDefinition(
            id: "Harvest", titleKey: "live_theme_harvest", subtitleKey: "live_theme_harvest_sub", pairedPaletteId: "Gold",
            swatchPrimary: 0xFFC97848, swatchSecondary: 0xFF7D4B34,
            light: LiveSceneColors(skyTop: 0xFFF2E6DC, skyUpperMid: 0xFFF6EDE5, skyLowerMid: 0xFFFAF4EF, skyHorizon: 0xFFFFFAF6, accentGlow: 0xFFB86639, secondaryGlow: 0xFF87533B, veilColor: 0xFFFFFAF6),
            dark: LiveSceneColors(skyTop: 0xFF110D09, skyUpperMid: 0xFF1A140E, skyLowerMid: 0xFF241B12, skyHorizon: 0xFF2F2318, accentGlow: 0xFFD68554, secondaryGlow: 0xFF945C42, veilColor: 0xFF110D09),
            amoled: LiveSceneColors(skyTop: 0xFF000000, skyUpperMid: 0xFF080604, skyLowerMid: 0xFF120D08, skyHorizon: 0xFF1D150D, accentGlow: 0xFFC77849, secondaryGlow: 0xFF825039, veilColor: 0xFF000000)
        ),
    ]

    public static func definition(for id: String) -> LiveThemeDefinition {
        all.first { $0.id.caseInsensitiveCompare(id) == .orderedSame } ?? all[0]
    }
}
