import Foundation

public struct SirajAppIconDefinition: Sendable, Equatable, Identifiable {
    public let id: String
    public let titleKey: String
    public let alternateIconName: String?
    public let centerColor: UInt32
    public let midColor: UInt32
    public let edgeColor: UInt32
    public let emblemColor: UInt32
    public let isLightGround: Bool
}

public enum SirajAppIconCatalog {
    public static let all: [SirajAppIconDefinition] = [
        SirajAppIconDefinition(id: "Classic", titleKey: "app_icon_classic", alternateIconName: nil, centerColor: 0xFF0D4231, midColor: 0xFF082E22, edgeColor: 0xFF052219, emblemColor: 0xFFD4AF37, isLightGround: false),
        SirajAppIconDefinition(id: "Gold", titleKey: "app_icon_gold", alternateIconName: "AppIconGold", centerColor: 0xFF3D260A, midColor: 0xFF281805, edgeColor: 0xFF190E02, emblemColor: 0xFFFBBF24, isLightGround: false),
        SirajAppIconDefinition(id: "Desert", titleKey: "app_icon_desert", alternateIconName: "AppIconDesert", centerColor: 0xFF452210, midColor: 0xFF2F160A, edgeColor: 0xFF1F0E06, emblemColor: 0xFFFDE68A, isLightGround: false),
        SirajAppIconDefinition(id: "Olive", titleKey: "app_icon_olive", alternateIconName: "AppIconOlive", centerColor: 0xFF283A1B, midColor: 0xFF1B2811, edgeColor: 0xFF10190A, emblemColor: 0xFFE9EDC9, isLightGround: false),
        SirajAppIconDefinition(id: "Teal", titleKey: "app_icon_teal", alternateIconName: "AppIconTeal", centerColor: 0xFF093B40, midColor: 0xFF05282C, edgeColor: 0xFF03191C, emblemColor: 0xFF5EEAD4, isLightGround: false),
        SirajAppIconDefinition(id: "Ocean", titleKey: "app_icon_ocean", alternateIconName: "AppIconOcean", centerColor: 0xFF0A3742, midColor: 0xFF06252D, edgeColor: 0xFF04181E, emblemColor: 0xFF7DD3FC, isLightGround: false),
        SirajAppIconDefinition(id: "Indigo", titleKey: "app_icon_indigo", alternateIconName: "AppIconIndigo", centerColor: 0xFF1E1B4B, midColor: 0xFF141136, edgeColor: 0xFF0B0921, emblemColor: 0xFFA5B4FC, isLightGround: false),
        SirajAppIconDefinition(id: "Purple", titleKey: "app_icon_purple", alternateIconName: "AppIconPurple", centerColor: 0xFF35124E, midColor: 0xFF240B36, edgeColor: 0xFF160622, emblemColor: 0xFFE9D5FF, isLightGround: false),
        SirajAppIconDefinition(id: "Rose", titleKey: "app_icon_rose", alternateIconName: "AppIconRose", centerColor: 0xFF4A1228, midColor: 0xFF330B1B, edgeColor: 0xFF200610, emblemColor: 0xFFFCE7F3, isLightGround: false),
        SirajAppIconDefinition(id: "Ruby", titleKey: "app_icon_ruby", alternateIconName: "AppIconRuby", centerColor: 0xFF4C0519, midColor: 0xFF350311, edgeColor: 0xFF21020A, emblemColor: 0xFFFDA4AF, isLightGround: false),
        SirajAppIconDefinition(id: "Midnight", titleKey: "app_icon_midnight", alternateIconName: "AppIconMidnight", centerColor: 0xFF1A1A20, midColor: 0xFF111116, edgeColor: 0xFF09090C, emblemColor: 0xFFF8FAFC, isLightGround: false),
        SirajAppIconDefinition(id: "White", titleKey: "app_icon_white", alternateIconName: "AppIconWhite", centerColor: 0xFFF8FAFC, midColor: 0xFFEEF2F6, edgeColor: 0xFFE2E8F0, emblemColor: 0xFF0D4231, isLightGround: true),
    ]

    public static func definition(for id: String) -> SirajAppIconDefinition {
        all.first { $0.id.caseInsensitiveCompare(id) == .orderedSame } ?? all[0]
    }
}
