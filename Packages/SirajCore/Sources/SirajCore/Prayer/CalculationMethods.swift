import Foundation

public struct CalculationMethodInfo: Sendable, Equatable, Identifiable {
    public let id: String
    public let names: [String: String]
    public let usedIn: [String: String]

    public func name(language: String) -> String {
        names[String(language.prefix(2)).lowercased()] ?? names["en"] ?? id
    }

    public func whereUsed(language: String) -> String {
        usedIn[String(language.prefix(2)).lowercased()] ?? usedIn["en"] ?? ""
    }
}

public enum CalculationMethods {
    public static let fallbackMethod = "MuslimWorldLeague"

    private static let aliases: [String: String] = [
        "MWL": "MuslimWorldLeague",
        "ISNA": "NorthAmerica",
        "Egypt": "Egyptian",
        "Moonsighting": "MoonsightingCommittee",
        "Diyanet": "Turkey"
    ]

    public static func canonicalId(_ id: String) -> String {
        aliases[id] ?? id
    }

    public static func byId(_ id: String) -> CalculationMethodInfo? {
        let canonical = canonicalId(id)
        return all.first { $0.id == canonical }
    }

    public static let all: [CalculationMethodInfo] = [
        make("MuslimWorldLeague",
             en: "Muslim World League", ar: "رابطة العالم الإسلامي", tr: "Dünya İslam Birliği", ur: "رابطۃ العالم الاسلامی",
             usedEn: "Europe, the Far East and much of the world", usedAr: "أوروبا والشرق الأقصى ومعظم أنحاء العالم",
             usedTr: "Avrupa, Uzak Doğu ve dünyanın çoğu", usedUr: "یورپ، مشرقِ بعید اور دنیا کے بیشتر حصے"),
        make("UmmAlQura",
             en: "Umm Al-Qura, Makkah", ar: "أم القرى، مكة المكرمة", tr: "Ümmü'l-Kura, Mekke", ur: "ام القریٰ، مکہ مکرمہ",
             usedEn: "Saudi Arabia", usedAr: "المملكة العربية السعودية", usedTr: "Suudi Arabistan", usedUr: "سعودی عرب"),
        make("Egyptian",
             en: "Egyptian General Authority of Survey", ar: "الهيئة المصرية العامة للمساحة", tr: "Mısır Genel Araştırma Kurumu", ur: "مصری جنرل اتھارٹی برائے مساحت",
             usedEn: "Egypt, Africa, Syria and Lebanon", usedAr: "مصر وأفريقيا وسوريا ولبنان",
             usedTr: "Mısır, Afrika, Suriye ve Lübnan", usedUr: "مصر، افریقہ، شام اور لبنان"),
        make("Karachi",
             en: "University of Islamic Sciences, Karachi", ar: "جامعة العلوم الإسلامية بكراتشي", tr: "Karaçi İslami İlimler Üniversitesi", ur: "جامعہ علوم اسلامیہ، کراچی",
             usedEn: "Pakistan, India, Bangladesh and Afghanistan", usedAr: "باكستان والهند وبنغلاديش وأفغانستان",
             usedTr: "Pakistan, Hindistan, Bangladeş ve Afganistan", usedUr: "پاکستان، بھارت، بنگلہ دیش اور افغانستان"),
        make("NorthAmerica",
             en: "Islamic Society of North America (ISNA)", ar: "الجمعية الإسلامية لأمريكا الشمالية", tr: "Kuzey Amerika İslam Cemiyeti (ISNA)", ur: "اسلامک سوسائٹی آف نارتھ امریکہ",
             usedEn: "United States and Canada", usedAr: "الولايات المتحدة وكندا", usedTr: "ABD ve Kanada", usedUr: "امریکہ اور کینیڈا"),
        make("Turkey",
             en: "Diyanet (Turkey)", ar: "رئاسة الشؤون الدينية التركية", tr: "Diyanet İşleri Başkanlığı", ur: "دیانت، ترکی",
             usedEn: "Turkey", usedAr: "تركيا", usedTr: "Türkiye", usedUr: "ترکی"),
        make("Dubai",
             en: "Dubai Islamic Affairs", ar: "دائرة الشؤون الإسلامية بدبي", tr: "Dubai İslami İşler Dairesi", ur: "دبئی محکمۂ اسلامی امور",
             usedEn: "United Arab Emirates", usedAr: "الإمارات العربية المتحدة", usedTr: "Birleşik Arap Emirlikleri", usedUr: "متحدہ عرب امارات"),
        make("Qatar",
             en: "Ministry of Awqaf, Qatar", ar: "وزارة الأوقاف القطرية", tr: "Katar Evkaf Bakanlığı", ur: "وزارتِ اوقاف، قطر",
             usedEn: "Qatar", usedAr: "قطر", usedTr: "Katar", usedUr: "قطر"),
        make("Kuwait",
             en: "Ministry of Awqaf, Kuwait", ar: "وزارة الأوقاف الكويتية", tr: "Kuveyt Evkaf Bakanlığı", ur: "وزارتِ اوقاف، کویت",
             usedEn: "Kuwait", usedAr: "الكويت", usedTr: "Kuveyt", usedUr: "کویت"),
        make("Singapore",
             en: "MUIS, Singapore", ar: "المجلس الإسلامي في سنغافورة", tr: "Singapur İslam Konseyi (MUIS)", ur: "مجلسِ اسلامی، سنگاپور",
             usedEn: "Singapore, Malaysia and Indonesia", usedAr: "سنغافورة وماليزيا وإندونيسيا",
             usedTr: "Singapur, Malezya ve Endonezya", usedUr: "سنگاپور، ملائیشیا اور انڈونیشیا"),
        make("MoonsightingCommittee",
             en: "Moonsighting Committee Worldwide", ar: "لجنة رؤية الهلال العالمية", tr: "Dünya Hilal Gözlem Heyeti", ur: "عالمی رویتِ ہلال کمیٹی",
             usedEn: "Many mosques in the UK and North America", usedAr: "كثير من مساجد بريطانيا وأمريكا الشمالية",
             usedTr: "İngiltere ve Kuzey Amerika'daki birçok cami", usedUr: "برطانیہ اور شمالی امریکہ کی بہت سی مساجد"),
        make("Tehran",
             en: "Institute of Geophysics, Tehran", ar: "معهد الجيوفيزياء بطهران", tr: "Tahran Jeofizik Enstitüsü", ur: "انسٹی ٹیوٹ آف جیو فزکس، تہران",
             usedEn: "Iran", usedAr: "إيران", usedTr: "İran", usedUr: "ایران")
    ]

    private static let methodByCountry: [String: String] = [
        "SA": "UmmAlQura", "YE": "UmmAlQura", "BH": "UmmAlQura", "OM": "UmmAlQura",
        "AE": "Dubai", "QA": "Qatar", "KW": "Kuwait",
        "EG": "Egyptian", "SD": "Egyptian", "LY": "Egyptian", "SY": "Egyptian",
        "LB": "Egyptian", "JO": "Egyptian", "PS": "Egyptian", "IQ": "Egyptian",
        "PK": "Karachi", "IN": "Karachi", "BD": "Karachi", "AF": "Karachi",
        "TR": "Turkey", "IR": "Tehran",
        "SG": "Singapore", "MY": "Singapore", "ID": "Singapore", "BN": "Singapore",
        "US": "NorthAmerica", "CA": "NorthAmerica"
    ]

    private static let hanafiCountries: Set<String> = ["PK", "IN", "BD", "AF"]

    public static func recommended(forCountryCode code: String?) -> String {
        guard let code else { return fallbackMethod }
        return methodByCountry[code.uppercased()] ?? fallbackMethod
    }

    public static func recommendedMadhab(forCountryCode code: String?) -> String {
        guard let code else { return "Shafi" }
        return hanafiCountries.contains(code.uppercased()) ? "Hanafi" : "Shafi"
    }

    public static func needsHighLatitudeRule(latitude: Double?) -> Bool {
        guard let latitude else { return false }
        return abs(latitude) >= 48.0
    }

    private static func make(
        _ id: String,
        en: String, ar: String, tr: String, ur: String,
        usedEn: String, usedAr: String, usedTr: String, usedUr: String
    ) -> CalculationMethodInfo {
        CalculationMethodInfo(
            id: id,
            names: ["en": en, "ar": ar, "tr": tr, "ur": ur],
            usedIn: ["en": usedEn, "ar": usedAr, "tr": usedTr, "ur": usedUr]
        )
    }
}
