import Foundation

public enum SirajAssetURLs {
    public static let repository = "M-H-AFIFI/Siraj-assets"
    public static let releaseTag = "v1.0.0"
    public static let assetVersion = "2"
    public static let releaseBase = "https://github.com/\(repository)/releases/download/\(releaseTag)/"
    public static let cdnBase = "https://cdn.jsdelivr.net/gh/\(repository)@main"
    public static let rawBase = "https://raw.githubusercontent.com/\(repository)/main"

    public static func release(_ fileName: String) -> URL {
        URL(string: releaseBase + fileName)!
    }

    public static func cdn(_ path: String) -> URL {
        let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return URL(string: "\(cdnBase)/\(trimmed)")!
    }

    public static func raw(_ path: String) -> URL {
        let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return URL(string: "\(rawBase)/\(trimmed)")!
    }
}

public enum MushafEdition: String, CaseIterable, Codable, Sendable, Identifiable {
    case madinah = "kfgqpc_v1"
    case indopak = "indopak"
    case shamarly = "shamarly"

    public var id: String { rawValue }

    public var totalPages: Int {
        switch self {
        case .madinah: return 604
        case .indopak: return 610
        case .shamarly: return 521
        }
    }

    public var hasOwnPagination: Bool {
        self == .indopak || self == .shamarly
    }

    public var scriptType: String { rawValue }

    public static func resolve(_ stored: String?) -> MushafEdition {
        let value = (stored ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if value.contains("indo") || value.contains("nastaleeq") {
            return .indopak
        }
        if value.contains("shamarly") {
            return .shamarly
        }
        return .madinah
    }
}

public enum QuranPaperColor: String, CaseIterable, Codable, Sendable, Identifiable {
    case yellowish = "Yellowish"
    case white = "White"
    case sepia = "Sepia"

    public var id: String { rawValue }
}

public enum QuranDarkStyle: String, CaseIterable, Codable, Sendable, Identifiable {
    case dark = "Dark"
    case black = "Black"
    case navy = "Navy"

    public var id: String { rawValue }
}

public enum QuranReadingTheme: String, CaseIterable, Codable, Sendable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    public var id: String { rawValue }
}

public enum MushafColors {
    public static let paperLight = ArgbColor.hex(0xFFFAF6EB)
    public static let mushafGold = ArgbColor.hex(0xFF9E8047)
    public static let mushafGoldDark = ArgbColor.hex(0xFFD4AF37)
    public static let mushafGoldBlack = ArgbColor.hex(0xFFFFD700)
    public static let mushafInk = ArgbColor.hex(0xFF1E1B18)
    public static let mushafInkDark = ArgbColor.hex(0xFFF2EFE9)
    public static let mushafInkBlack = ArgbColor.hex(0xFFFFFFFF)

    public static func resolvePrinted(
        isDark: Bool,
        isBlackMode: Bool,
        paperColor: String = "Yellowish",
        darkStyle: String = "Dark"
    ) -> (paper: ArgbColor, ink: ArgbColor) {
        if isDark {
            let lower = darkStyle.lowercased()
            if isBlackMode || lower == "black" || lower == "amoled" {
                return (ArgbColor.hex(0xFF000000), mushafInkBlack)
            }
            if lower == "navy" {
                return (ArgbColor.hex(0xFF0B132B), ArgbColor.hex(0xFFE2E8F0))
            }
            return (ArgbColor.hex(0xFF1E1E22), ArgbColor.hex(0xFFE2E2E6))
        }
        let lowerPaper = paperColor.lowercased()
        if lowerPaper == "white" {
            return (ArgbColor.hex(0xFFFFFFFF), ArgbColor.hex(0xFF111111))
        }
        if lowerPaper == "sepia" {
            return (ArgbColor.hex(0xFFF4ECD8), ArgbColor.hex(0xFF2C241B))
        }
        return (paperLight, mushafInk)
    }
}

public struct Surah: Codable, Sendable, Equatable, Hashable, Identifiable {
    public var id: Int { number }
    public let number: Int
    public let name: String
    public let englishName: String
    public let englishNameTranslation: String
    public let numberOfAyahs: Int
    public let revelationType: String

    public init(
        number: Int,
        name: String,
        englishName: String,
        englishNameTranslation: String,
        numberOfAyahs: Int,
        revelationType: String
    ) {
        self.number = number
        self.name = name
        self.englishName = SurahNames.transliteration(englishName)
        self.englishNameTranslation = englishNameTranslation
        self.numberOfAyahs = numberOfAyahs
        self.revelationType = revelationType
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.number = try c.decode(Int.self, forKey: .number)
        self.name = try c.decode(String.self, forKey: .name)
        let rawEnglish = try c.decode(String.self, forKey: .englishName)
        self.englishName = SurahNames.transliteration(rawEnglish)
        self.englishNameTranslation = try c.decodeIfPresent(String.self, forKey: .englishNameTranslation) ?? ""
        self.numberOfAyahs = try c.decode(Int.self, forKey: .numberOfAyahs)
        self.revelationType = try c.decodeIfPresent(String.self, forKey: .revelationType) ?? "Meccan"
    }

    public var isMeccan: Bool {
        let lower = revelationType.lowercased()
        return lower == "meccan" || lower == "makki" || lower == "مكية"
    }
}

public struct Ayah: Codable, Sendable, Equatable, Hashable, Identifiable {
    public var id: Int { number }
    public let number: Int
    public let surahNumber: Int
    public let numberInSurah: Int
    public let textUthmani: String
    public let textSimple: String
    public let textIndopak: String?
    public let textShamarly: String?
    public let juz: Int
    public let page: Int
    public let scriptPage: Int?
    public let hizb: Int
    public let rub: Int
    public let sajda: Bool
    public let translation: String?
    public let tafsir: String?

    public init(
        number: Int,
        surahNumber: Int,
        numberInSurah: Int,
        textUthmani: String,
        textSimple: String = "",
        textIndopak: String? = nil,
        textShamarly: String? = nil,
        juz: Int = 1,
        page: Int = 1,
        scriptPage: Int? = nil,
        hizb: Int = 1,
        rub: Int = 1,
        sajda: Bool = false,
        translation: String? = nil,
        tafsir: String? = nil
    ) {
        self.number = number
        self.surahNumber = surahNumber
        self.numberInSurah = numberInSurah
        self.textUthmani = textUthmani
        self.textSimple = textSimple
        self.textIndopak = textIndopak
        self.textShamarly = textShamarly
        self.juz = juz
        self.page = page
        self.scriptPage = scriptPage
        self.hizb = hizb
        self.rub = rub
        self.sajda = sajda
        self.translation = translation
        self.tafsir = tafsir
    }
}

public enum MushafLineType: String, Codable, Sendable, Equatable {
    case surahName = "surah_name"
    case basmallah = "basmallah"
    case ayah = "ayah"
    case empty = "empty"
}

public struct MushafWord: Codable, Sendable, Equatable, Hashable, Identifiable {
    public let id: Int
    public let glyphCode: Int
    public let text: String
    public let isMarker: Bool
    public let surahNumber: Int?
    public let ayahNumber: Int?
    public let wordPosition: Int?

    public init(
        id: Int,
        glyphCode: Int = 0,
        text: String,
        isMarker: Bool = false,
        surahNumber: Int? = nil,
        ayahNumber: Int? = nil,
        wordPosition: Int? = nil
    ) {
        self.id = id
        self.glyphCode = glyphCode
        self.text = text
        self.isMarker = isMarker
        self.surahNumber = surahNumber
        self.ayahNumber = ayahNumber
        self.wordPosition = wordPosition
    }
}

public struct MushafLine: Codable, Sendable, Equatable {
    public let lineNumber: Int
    public let lineType: MushafLineType
    public let words: [MushafWord]
    public let isCentered: Bool
    public let surahNumber: Int?
    public let surahName: String?
    public let fontFile: String?

    public init(
        lineNumber: Int,
        lineType: MushafLineType,
        words: [MushafWord] = [],
        isCentered: Bool = false,
        surahNumber: Int? = nil,
        surahName: String? = nil,
        fontFile: String? = nil
    ) {
        self.lineNumber = lineNumber
        self.lineType = lineType
        self.words = words
        self.isCentered = isCentered
        self.surahNumber = surahNumber
        self.surahName = surahName
        self.fontFile = fontFile
    }
}

public struct MushafPage: Codable, Sendable, Equatable {
    public let pageNumber: Int
    public let juzNumber: Int
    public let surahName: String
    public let ayahs: [Ayah]
    public let lines: [MushafLine]
    public let scriptType: String

    public init(
        pageNumber: Int,
        juzNumber: Int,
        surahName: String,
        ayahs: [Ayah],
        lines: [MushafLine],
        scriptType: String
    ) {
        self.pageNumber = pageNumber
        self.juzNumber = juzNumber
        self.surahName = surahName
        self.ayahs = ayahs
        self.lines = lines
        self.scriptType = scriptType
    }

    public var openingAyah: (surah: Int, ayah: Int)? {
        if let first = ayahs.filter({ $0.number > 0 }).min(by: { $0.number < $1.number }) {
            return (first.surahNumber, first.numberInSurah)
        }
        for line in lines.sorted(by: { $0.lineNumber < $1.lineNumber }) where line.lineType == .ayah {
            if let word = line.words.first(where: { $0.ayahNumber != nil }),
               let surah = word.surahNumber ?? line.surahNumber,
               let ayah = word.ayahNumber {
                return (surah, ayah)
            }
        }
        return ayahs.first.map { ($0.surahNumber, $0.numberInSurah) }
    }
}

public struct JuzSummary: Sendable, Equatable, Identifiable {
    public var id: Int { number }
    public let number: Int
    public let startPage: Int
    public let ayahCount: Int
    public let surahCount: Int
    public let startSurahNumber: Int
    public let startSurahName: String
    public let startSurahEnglishName: String
    public let startAyahInSurah: Int
    public let endSurahNumber: Int
    public let endSurahName: String
    public let endSurahEnglishName: String
    public let endAyahInSurah: Int

    public var isWithinOneSurah: Bool { startSurahNumber == endSurahNumber }

    public init(
        number: Int,
        startPage: Int,
        ayahCount: Int,
        surahCount: Int,
        startSurahNumber: Int,
        startSurahName: String,
        startSurahEnglishName: String,
        startAyahInSurah: Int,
        endSurahNumber: Int,
        endSurahName: String,
        endSurahEnglishName: String,
        endAyahInSurah: Int
    ) {
        self.number = number
        self.startPage = startPage
        self.ayahCount = ayahCount
        self.surahCount = surahCount
        self.startSurahNumber = startSurahNumber
        self.startSurahName = startSurahName
        self.startSurahEnglishName = startSurahEnglishName
        self.startAyahInSurah = startAyahInSurah
        self.endSurahNumber = endSurahNumber
        self.endSurahName = endSurahName
        self.endSurahEnglishName = endSurahEnglishName
        self.endAyahInSurah = endAyahInSurah
    }
}

public struct JuzInfo: Sendable, Equatable, Identifiable {
    public var id: Int { number }
    public let number: Int
    public let arabicOrdinal: String
    public let openingWords: String
    public let surahRange: String

    public static let all: [JuzInfo] = [
        JuzInfo(number: 1, arabicOrdinal: "الجزء الأول", openingWords: "الم (١)", surahRange: "الفاتحة ١ ← البقرة ١٤١"),
        JuzInfo(number: 2, arabicOrdinal: "الجزء الثاني", openingWords: "سَيَقُولُ (٢)", surahRange: "البقرة ١٤٢ ← البقرة ٢٥٢"),
        JuzInfo(number: 3, arabicOrdinal: "الجزء الثالث", openingWords: "تِلْكَ الرُّسُلُ (٣)", surahRange: "البقرة ٢٥٣ ← آل عمران ٩٢"),
        JuzInfo(number: 4, arabicOrdinal: "الجزء الرابع", openingWords: "لَنْ تَنَالُوا (٤)", surahRange: "آل عمران ٩٣ ← النساء ٢٣"),
        JuzInfo(number: 5, arabicOrdinal: "الجزء الخامس", openingWords: "وَالْمُحْصَنَاتُ (٥)", surahRange: "النساء ٢٤ ← النساء ١٤٧"),
        JuzInfo(number: 6, arabicOrdinal: "الجزء السادس", openingWords: "لَا يُحِبُّ اللَّـهُ (٦)", surahRange: "النساء ١٤٨ ← المائدة ٨١"),
        JuzInfo(number: 7, arabicOrdinal: "الجزء السابع", openingWords: "وَإِذَا سَمِعُوا (٧)", surahRange: "المائدة ٨٢ ← الأنعام ١١٠"),
        JuzInfo(number: 8, arabicOrdinal: "الجزء الثامن", openingWords: "وَلَوْ أَنَّنَا (٨)", surahRange: "الأنعام ١١١ ← الأعراف ٨٧"),
        JuzInfo(number: 9, arabicOrdinal: "الجزء التاسع", openingWords: "قَالَ الْمَلَأُ (٩)", surahRange: "الأعراف ٨٨ ← الأنفال ٤٠"),
        JuzInfo(number: 10, arabicOrdinal: "الجزء العاشر", openingWords: "وَاعْلَمُوا (١٠)", surahRange: "الأنفال ٤١ ← التوبة ٩٢"),
        JuzInfo(number: 11, arabicOrdinal: "الجزء الحادي عشر", openingWords: "يَعْتَذِرُونَ (١١)", surahRange: "التوبة ٩٣ ← هود ٥"),
        JuzInfo(number: 12, arabicOrdinal: "الجزء الثاني عشر", openingWords: "وَمَا مِنْ دَابَّةٍ (١٢)", surahRange: "هود ٦ ← يوسف ٥٢"),
        JuzInfo(number: 13, arabicOrdinal: "الجزء الثالث عشر", openingWords: "وَمَا أُبَرِّئُ (١٣)", surahRange: "يوسف ٥٣ ← إبراهيم ٥٢"),
        JuzInfo(number: 14, arabicOrdinal: "الجزء الرابع عشر", openingWords: "رُبَمَا (١٤)", surahRange: "الحجر ١ ← النحل ١٢٨"),
        JuzInfo(number: 15, arabicOrdinal: "الجزء الخامس عشر", openingWords: "سُبْحَانَ الَّذِي (١٥)", surahRange: "الإسراء ١ ← الكهف ٧٤"),
        JuzInfo(number: 16, arabicOrdinal: "الجزء السادس عشر", openingWords: "قَالَ أَلَمْ (١٦)", surahRange: "الكهف ٧٥ ← طه ١٣٥"),
        JuzInfo(number: 17, arabicOrdinal: "الجزء السابع عشر", openingWords: "اقْتَرَبَ لِلنَّاسِ (١٧)", surahRange: "الأنبياء ١ ← الحج ٧٨"),
        JuzInfo(number: 18, arabicOrdinal: "الجزء الثامن عشر", openingWords: "قَدْ أَفْلَحَ (١٨)", surahRange: "المؤمنون ١ ← الفرقان ٢٠"),
        JuzInfo(number: 19, arabicOrdinal: "الجزء التاسع عشر", openingWords: "وَقَالَ الَّذِينَ (١٩)", surahRange: "الفرقان ٢١ ← النمل ٥٥"),
        JuzInfo(number: 20, arabicOrdinal: "الجزء العشرون", openingWords: "أَمَّنْ خَلَقَ (٢٠)", surahRange: "النمل ٥٦ ← العنكبوت ٤٥"),
        JuzInfo(number: 21, arabicOrdinal: "الجزء الحادي والعشرون", openingWords: "اتْلُ مَا أُوحِيَ (٢١)", surahRange: "العنكبوت ٤٦ ← الأحزاب ٣٠"),
        JuzInfo(number: 22, arabicOrdinal: "الجزء الثاني والعشرون", openingWords: "وَمَنْ يَقْنُتْ (٢٢)", surahRange: "الأحزاب ٣١ ← يس ٢٧"),
        JuzInfo(number: 23, arabicOrdinal: "الجزء الثالث والعشرون", openingWords: "وَمَا لِيَ (٢٣)", surahRange: "يس ٢٨ ← الزمر ٣١"),
        JuzInfo(number: 24, arabicOrdinal: "الجزء الرابع والعشرون", openingWords: "فَمَنْ أَظْلَمُ (٢٤)", surahRange: "الزمر ٣٢ ← فصلت ٤٦"),
        JuzInfo(number: 25, arabicOrdinal: "الجزء الخامس والعشرون", openingWords: "إِلَيْهِ يُرَدُّ (٢٥)", surahRange: "فصلت ٤٧ ← الجاثية ٣٧"),
        JuzInfo(number: 26, arabicOrdinal: "الجزء السادس والعشرون", openingWords: "حم • تَنْزِيلُ (٢٦)", surahRange: "الأحقاف ١ ← الذاريات ٣٠"),
        JuzInfo(number: 27, arabicOrdinal: "الجزء السابع والعشرون", openingWords: "قَالَ فَمَا خَطْبُكُمْ (٢٧)", surahRange: "الذاريات ٣١ ← الحديد ٢٩"),
        JuzInfo(number: 28, arabicOrdinal: "الجزء الثامن والعشرون", openingWords: "قَدْ سَمِعَ اللَّـهُ (٢٨)", surahRange: "المجادلة ١ ← التحريم ١٢"),
        JuzInfo(number: 29, arabicOrdinal: "الجزء التاسع والعشرون", openingWords: "تَبَارَكَ الَّذِي (٢٩)", surahRange: "الملك ١ ← المرسلات ٥٠"),
        JuzInfo(number: 30, arabicOrdinal: "الجزء الثلاثون (جزء عم)", openingWords: "عَمَّ يَتَسَاءَلُونَ (٣٠)", surahRange: "النبأ ١ ← الناس ٦")
    ]
}

public enum JuzBoundaries {
    public static let starts: [(surah: Int, ayah: Int)] = [
        (1, 1), (2, 142), (2, 253), (3, 93), (4, 24),
        (4, 148), (5, 82), (6, 111), (7, 88), (8, 41),
        (9, 93), (11, 6), (12, 53), (15, 1), (17, 1),
        (18, 75), (21, 1), (23, 1), (25, 21), (27, 56),
        (29, 46), (33, 31), (36, 28), (39, 32), (41, 47),
        (46, 1), (51, 31), (58, 1), (67, 1), (78, 1)
    ]

    public static let count = 30
    public static let totalAyahs = 6236

    public static func juzOf(surah: Int, ayah: Int) -> Int {
        var idx = 0
        for (i, start) in starts.enumerated() {
            if start.surah < surah || (start.surah == surah && start.ayah <= ayah) {
                idx = i
            } else {
                break
            }
        }
        return min(count, max(1, idx + 1))
    }
}

public struct TafsirBook: Codable, Sendable, Equatable, Hashable, Identifiable {
    public let id: String
    public let title: String
    public let shortTitle: String
    public let author: String
    public let language: String

    public var isBuiltIn: Bool { id == Self.builtInId }
    public var isArabicScript: Bool { language == "ar" || language == "ur" }

    public static let builtInId = "ar.muyassar"

    public static let all: [TafsirBook] = [
        TafsirBook(id: "ar.muyassar", title: "التفسير الميسر", shortTitle: "الميسر", author: "مجمع الملك فهد لطباعة المصحف الشريف", language: "ar"),
        TafsirBook(id: "ar.kathir", title: "تفسير ابن كثير", shortTitle: "ابن كثير", author: "تفسير القرآن العظيم (٧٧٤ هـ)", language: "ar"),
        TafsirBook(id: "ar.qurtubi", title: "تفسير القرطبي", shortTitle: "القرطبي", author: "الجامع لأحكام القرآن (٦٧١ هـ)", language: "ar"),
        TafsirBook(id: "ar.jazairi", title: "أيسر التفاسير", shortTitle: "الجزائري", author: "أبو بكر جابر الجزائري", language: "ar"),
        TafsirBook(id: "ar.qayyim", title: "تفسير ابن القيم", shortTitle: "ابن القيم", author: "ابن قيم الجوزية", language: "ar"),
        TafsirBook(id: "ar.irab", title: "الإعراب الميسر", shortTitle: "الإعراب", author: "إعراب القرآن وبيانه", language: "ar"),
        TafsirBook(id: "en.mukhtasar", title: "Abridged Explanation", shortTitle: "Mukhtasar", author: "Tafsir Center / Mukhtasar", language: "en"),
        TafsirBook(id: "en.kathir", title: "Tafsir Ibn Kathir (En)", shortTitle: "Ibn Kathir", author: "Ibn Kathir English", language: "en"),
        TafsirBook(id: "en.jalalayn", title: "Tafsir al-Jalalayn", shortTitle: "Al-Jalalayn", author: "Jalal al-Din al-Mahalli & al-Suyuti", language: "en"),
        TafsirBook(id: "en.asad", title: "Muhammad Asad Translation", shortTitle: "Asad", author: "The Message of the Qur'an", language: "en"),
        TafsirBook(id: "tr.saadi", title: "Tefsiru's-Sa'di", shortTitle: "Sa'di", author: "Abdurrahman es-Sa'di", language: "tr"),
        TafsirBook(id: "tr.kathir", title: "İbn Kesir Tefsiri", shortTitle: "İbn Kesir", author: "İbn Kesir Türkçe", language: "tr"),
        TafsirBook(id: "tr.mukhtasar", title: "Muhtasar Tefsir", shortTitle: "Muhtasar", author: "Türkçe Muhtasar", language: "tr"),
        TafsirBook(id: "tr.shahin", title: "Müslim Şahin Meali", shortTitle: "Şahin", author: "Türkçe Meal", language: "tr"),
        TafsirBook(id: "ur.kathir", title: "تفسیر ابن کثیر (اردو)", shortTitle: "ابن کثیر", author: "علامہ عماد الدین ابن کثیر", language: "ur"),
        TafsirBook(id: "ur.saadi", title: "تفسیر السعدی (اردو)", shortTitle: "السعدی", author: "شیخ عبد الرحمن السعدی", language: "ur"),
        TafsirBook(id: "ur.wahiduddin", title: "مولانا وحید الدین خان", shortTitle: "وحید الدین", author: "آسان اردو ترجمہ", language: "ur")
    ]

    public static func byId(_ id: String) -> TafsirBook? {
        all.first { $0.id == id }
    }

    public static func mirrorURLs(for edition: String) -> [URL] {
        var urls: [URL] = [SirajAssetURLs.release("\(edition).json")]
        switch edition {
        case "ar.qurtubi":
            if let u = URL(string: "https://api.alquran.cloud/v1/quran/ar.qurtubi") { urls.append(u) }
        case "en.asad":
            if let u = URL(string: "https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions/eng-muhammadasad.min.json") { urls.append(u) }
            if let u = URL(string: "https://api.alquran.cloud/v1/quran/en.asad") { urls.append(u) }
        default:
            break
        }
        return urls
    }
}

public struct QuranBookmark: Codable, Sendable, Equatable, Hashable, Identifiable {
    public let id: String
    public let surahNumber: Int
    public let ayahNumber: Int
    public let surahName: String
    public let pageNumber: Int?
    public let name: String?
    public let timestamp: TimeInterval

    public var isPageBookmark: Bool { pageNumber != nil }

    public init(
        id: String = UUID().uuidString,
        surahNumber: Int,
        ayahNumber: Int,
        surahName: String,
        pageNumber: Int? = nil,
        name: String? = nil,
        timestamp: TimeInterval = Date().timeIntervalSince1970
    ) {
        self.id = id
        self.surahNumber = surahNumber
        self.ayahNumber = ayahNumber
        self.surahName = surahName
        self.pageNumber = pageNumber
        self.name = name
        self.timestamp = timestamp
    }
}

public struct QuranNote: Codable, Sendable, Equatable, Hashable, Identifiable {
    public let id: String
    public let surahNumber: Int
    public let ayahNumber: Int
    public var content: String
    public var timestamp: TimeInterval

    public init(
        id: String = UUID().uuidString,
        surahNumber: Int,
        ayahNumber: Int,
        content: String,
        timestamp: TimeInterval = Date().timeIntervalSince1970
    ) {
        self.id = id
        self.surahNumber = surahNumber
        self.ayahNumber = ayahNumber
        self.content = content
        self.timestamp = timestamp
    }
}

public struct ReadingPosition: Codable, Sendable, Equatable {
    public let surahNumber: Int
    public let ayahNumber: Int
    public let page: Int
    public let juz: Int
    public let pageCount: Int
    public let edition: String
    public let updatedAt: TimeInterval

    public init(
        surahNumber: Int,
        ayahNumber: Int,
        page: Int,
        juz: Int,
        pageCount: Int = 604,
        edition: String = MushafEdition.madinah.rawValue,
        updatedAt: TimeInterval = Date().timeIntervalSince1970
    ) {
        self.surahNumber = surahNumber
        self.ayahNumber = ayahNumber
        self.page = page
        self.juz = juz
        self.pageCount = pageCount
        self.edition = edition
        self.updatedAt = updatedAt
    }
}
