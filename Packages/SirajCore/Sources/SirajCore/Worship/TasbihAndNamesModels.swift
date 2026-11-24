import Foundation

public struct TasbihDhikr: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let arabic: String
    public let transliteration: String
    public let translationEn: String
    public let translationTr: String
    public let translationUr: String
    public let defaultGoal: Int
    public let isCustom: Bool

    public init(
        id: String = UUID().uuidString,
        arabic: String,
        transliteration: String = "",
        translationEn: String = "",
        translationTr: String = "",
        translationUr: String = "",
        defaultGoal: Int = 33,
        isCustom: Bool = false
    ) {
        self.id = id
        self.arabic = arabic
        self.transliteration = transliteration
        self.translationEn = translationEn
        self.translationTr = translationTr
        self.translationUr = translationUr
        self.defaultGoal = defaultGoal
        self.isCustom = isCustom
    }

    public func translation(language: String) -> String {
        if language.hasPrefix("ar") { return "" }
        if language.hasPrefix("tr") { return translationTr.isEmpty ? translationEn : translationTr }
        if language.hasPrefix("ur") { return translationUr.isEmpty ? translationEn : translationUr }
        return translationEn
    }

    public static let goalPresets: [Int] = [33, 99, 100, 1000]

    public static let presets: [TasbihDhikr] = [
        TasbihDhikr(
            id: "subhanallah",
            arabic: "سُبْحَانَ اللَّهِ",
            transliteration: "SubhanAllah",
            translationEn: "Glory be to Allah",
            translationTr: "Allah'ı tenzih ederim",
            translationUr: "اللہ پاک ہے",
            defaultGoal: 33
        ),
        TasbihDhikr(
            id: "alhamdulillah",
            arabic: "الْحَمْدُ لِلهِ",
            transliteration: "Alhamdulillah",
            translationEn: "Praise be to Allah",
            translationTr: "Hamd Allah'adır",
            translationUr: "تمام تعریفیں اللہ کے لیے ہیں",
            defaultGoal: 33
        ),
        TasbihDhikr(
            id: "allahu_akbar",
            arabic: "اللهُ أَكْبَرُ",
            transliteration: "Allahu Akbar",
            translationEn: "Allah is the Greatest",
            translationTr: "Allah en büyüktür",
            translationUr: "اللہ سب سے بڑا ہے",
            defaultGoal: 34
        ),
        TasbihDhikr(
            id: "tahlil",
            arabic: "لَا إِلَهَ إِلَّا اللهُ",
            transliteration: "La ilaha illa Allah",
            translationEn: "There is no god but Allah",
            translationTr: "Allah'tan başka ilah yoktur",
            translationUr: "اللہ کے سوا کوئی معبود نہیں",
            defaultGoal: 100
        ),
        TasbihDhikr(
            id: "istighfar",
            arabic: "أَسْتَغْفِرُ اللَّهَ",
            transliteration: "Astaghfirullah",
            translationEn: "I seek forgiveness from Allah",
            translationTr: "Allah'tan bağışlanma dilerim",
            translationUr: "میں اللہ سے معافی مانگتا ہوں",
            defaultGoal: 100
        ),
        TasbihDhikr(
            id: "salawat",
            arabic: "اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ",
            transliteration: "Allahumma salli ala Muhammad",
            translationEn: "O Allah, bless Muhammad",
            translationTr: "Allah'ım, Muhammed'e salat eyle",
            translationUr: "اے اللہ، محمد صلی اللہ علیہ وسلم پر درود بھیج",
            defaultGoal: 100
        ),
        TasbihDhikr(
            id: "subhanallahi_wabihamdihi",
            arabic: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ",
            transliteration: "SubhanAllahi wa bihamdihi",
            translationEn: "Glory and praise be to Allah",
            translationTr: "Allah'ı hamd ile tesbih ederim",
            translationUr: "اللہ اپنی تعریف کے ساتھ پاک ہے",
            defaultGoal: 100
        ),
        TasbihDhikr(
            id: "hawqala",
            arabic: "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ",
            transliteration: "La hawla wa la quwwata illa billah",
            translationEn: "There is no power nor might except with Allah",
            translationTr: "Güç ve kuvvet ancak Allah'tandır",
            translationUr: "نیکی کرنے کی طاقت اور برائی سے بچنے کی ہمت اللہ ہی کی طرف سے ہے",
            defaultGoal: 100
        )
    ]
}

public struct TasbihSnapshot: Codable, Sendable, Equatable {
    public var count: Int
    public var goal: Int
    public var todayTotal: Int
    public var currentDhikrIndex: Int
    public var customDhikrs: [TasbihDhikr]
    public var lastDateISO: String

    public init(
        count: Int = 0,
        goal: Int = 33,
        todayTotal: Int = 0,
        currentDhikrIndex: Int = 0,
        customDhikrs: [TasbihDhikr] = [],
        lastDateISO: String = ""
    ) {
        self.count = count
        self.goal = goal
        self.todayTotal = todayTotal
        self.currentDhikrIndex = currentDhikrIndex
        self.customDhikrs = customDhikrs
        self.lastDateISO = lastDateISO
    }
}

public struct AllahName: Codable, Sendable, Equatable, Identifiable {
    public let number: Int
    public let nameAr: String
    public let transliteration: String
    public let meaningEn: String
    public let descriptionEn: String
    public let meaningAr: String
    public let descriptionAr: String
    public let meaningTr: String
    public let descriptionTr: String
    public let meaningUr: String
    public let descriptionUr: String

    public var id: Int { number }

    public func meaning(language: String) -> String {
        if language.hasPrefix("ar") { return descriptionAr }
        if language.hasPrefix("ur") { return meaningUr.isEmpty ? meaningEn : meaningUr }
        if language.hasPrefix("tr") { return meaningTr.isEmpty ? meaningEn : meaningTr }
        return meaningEn
    }

    public func description(language: String) -> String {
        if language.hasPrefix("ar") { return descriptionAr }
        if language.hasPrefix("ur") { return descriptionUr.isEmpty ? descriptionEn : descriptionUr }
        if language.hasPrefix("tr") { return descriptionTr.isEmpty ? descriptionEn : descriptionTr }
        return descriptionEn
    }
}

public enum AllahNamesCatalog {
    public static func parse(_ data: Data) -> [AllahName] {
        (try? JSONDecoder().decode([AllahName].self, from: data)) ?? []
    }

    public static func nameOfTheDay(from names: [AllahName], dayOfYear: Int) -> AllahName? {
        guard !names.isEmpty else { return nil }
        let idx = max(0, (dayOfYear - 1)) % names.count
        return names[idx]
    }
}

public enum SearchFolding {
    public static func matchesFolded(query: String, fields: [String]) -> Bool {
        let needle = ArabicSearchText.normalizeQuery(query)
        guard !needle.isEmpty else { return true }
        return fields.contains { field in
            !field.isEmpty && ArabicSearchText.normalize(field).contains(needle)
        }
    }
}
