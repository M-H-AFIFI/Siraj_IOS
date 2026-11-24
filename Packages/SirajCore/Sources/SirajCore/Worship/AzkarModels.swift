import Foundation

public enum AzkarCategory: String, CaseIterable, Codable, Sendable, Identifiable {
    case morning = "MORNING"
    case evening = "EVENING"
    case sleep = "SLEEP"
    case wakeUp = "WAKE_UP"
    case afterPrayer = "AFTER_PRAYER"
    case travel = "TRAVEL"
    case ruqiya = "RUQIYA"
    case hajj = "HAJJ"
    case essential = "ESSENTIAL"
    case rabbana = "RABBANA"
    case grief = "GRIEF"
    case debt = "DEBT"
    case mosque = "MOSQUE"
    case missedRakah = "MISSED_RAKAH"

    public var id: String { rawValue }

    public var titleEn: String {
        switch self {
        case .morning: return "Morning"
        case .evening: return "Evening"
        case .sleep: return "Sleep"
        case .wakeUp: return "Wake up"
        case .afterPrayer: return "After Prayer"
        case .travel: return "Travel"
        case .ruqiya: return "Ruqiya"
        case .hajj: return "Hajj & Umrah"
        case .essential: return "Essential"
        case .rabbana: return "40 Rabbana"
        case .grief: return "Grief"
        case .debt: return "Debt"
        case .mosque: return "Masjid"
        case .missedRakah: return "Missed Rakah"
        }
    }

    public var titleAr: String {
        switch self {
        case .morning: return "أذكار الصباح"
        case .evening: return "أذكار المساء"
        case .sleep: return "أذكار النوم"
        case .wakeUp: return "أذكار الاستيقاظ"
        case .afterPrayer: return "أذكار بعد الصلاة"
        case .travel: return "أذكار السفر"
        case .ruqiya: return "الرقية الشرعية"
        case .hajj: return "الحج والعمرة"
        case .essential: return "أدعية مختارة"
        case .rabbana: return "ربنا"
        case .grief: return "الهم والحزن"
        case .debt: return "قضاء الدين"
        case .mosque: return "المسجد"
        case .missedRakah: return "المسبوق في الصلاة"
        }
    }

    public var titleTr: String {
        switch self {
        case .morning: return "Sabah Zikirleri"
        case .evening: return "Akşam Zikirleri"
        case .sleep: return "Uyku Zikirleri"
        case .wakeUp: return "Uyanma Zikirleri"
        case .afterPrayer: return "Namaz Sonrası Zikirler"
        case .travel: return "Sefer Zikirleri"
        case .ruqiya: return "Rukye"
        case .hajj: return "Hac ve Umre"
        case .essential: return "Temel Dualar"
        case .rabbana: return "Rabbana Duaları"
        case .grief: return "Keder ve Üzüntü"
        case .debt: return "Borç Ödeme"
        case .mosque: return "Mescid"
        case .missedRakah: return "Mesbuk Namazı"
        }
    }

    public var titleUr: String {
        switch self {
        case .morning: return "صبح کے اذکار"
        case .evening: return "شام کے اذکار"
        case .sleep: return "سونے کے اذکار"
        case .wakeUp: return "بیدار ہونے کے اذکار"
        case .afterPrayer: return "نماز کے بعد کے اذکار"
        case .travel: return "سفر کے اذکار"
        case .ruqiya: return "شرعی دم اور رقیہ"
        case .hajj: return "حج اور عمرہ"
        case .essential: return "منتخب مسنون دعائیں"
        case .rabbana: return "ربنا قرآنی دعائیں"
        case .grief: return "غم اور پریشانی کی دعائیں"
        case .debt: return "قرض کی ادائیگی کی دعا"
        case .mosque: return "مسجد کے اذکار"
        case .missedRakah: return "مسبوق کی نماز"
        }
    }

    public func title(language: String) -> String {
        if language.hasPrefix("ur") { return titleUr }
        if language.hasPrefix("ar") { return titleAr }
        if language.hasPrefix("tr") { return titleTr }
        return titleEn
    }

    public func detailTitle(language: String) -> String {
        let lang = SirajLocalizer.baseLanguage(language)
        switch self {
        case .morning:
            return ["ar": "أذكار الصباح", "ur": "صبح کے اذکار", "tr": "Sabah Zikirleri", "en": "Morning Remembrances"][lang] ?? titleEn
        case .evening:
            return ["ar": "أذكار المساء", "ur": "شام کے اذکار", "tr": "Akşam Zikirleri", "en": "Evening Remembrances"][lang] ?? titleEn
        case .sleep:
            return ["ar": "أذكار النوم", "ur": "سونے کے اذکار", "tr": "Uyku Zikirleri", "en": "Sleep Remembrances"][lang] ?? titleEn
        case .wakeUp:
            return ["ar": "أذكار الاستيقاظ", "ur": "جاگنے کے اذکار", "tr": "Uyanma Zikirleri", "en": "Waking Up Remembrances"][lang] ?? titleEn
        case .afterPrayer:
            return ["ar": "أذكار بعد الصلاة", "ur": "نماز کے بعد کے اذکار", "tr": "Namaz Sonrası Zikirler", "en": "After Prayer Remembrances"][lang] ?? titleEn
        case .travel:
            return ["ar": "أذكار السفر", "ur": "سفر کی دعائیں", "tr": "Sefer Duaları", "en": "Travel Supplications"][lang] ?? titleEn
        case .grief:
            return ["ar": "أدعية الهم والحزن وتفريج الكرب", "ur": "غم اور پریشانی سے نجات کی دعائیں", "tr": "Keder ve Sıkıntı Duaları", "en": "Relief from Grief & Distress"][lang] ?? titleEn
        case .debt:
            return ["ar": "أدعية قضاء الدين", "ur": "قرض کی ادائیگی کی دعائیں", "tr": "Borç Ödeme Duaları", "en": "Debt Relief Supplications"][lang] ?? titleEn
        case .mosque:
            return ["ar": "أذكار المسجد", "ur": "مسجد کے اذکار", "tr": "Mescid Duaları", "en": "Masjid Supplications"][lang] ?? titleEn
        case .missedRakah:
            return ["ar": "أحكام وأدعية المسبوق", "ur": "مسبوق کی نماز اور دعائیں", "tr": "Mesbuk Namazı Rehberi", "en": "Missed Rakah Guide"][lang] ?? titleEn
        case .rabbana:
            return ["ar": "أدعية قرآنية (40 ربنا)", "ur": "قرآنی ربنا دعائیں", "tr": "Kur'an'dan Rabbena Duaları", "en": "Quranic Rabbana Duas"][lang] ?? titleEn
        case .ruqiya:
            return ["ar": "الرقية الشرعية", "ur": "مسنون رقیہ شرعیہ", "tr": "Şifa ve Rukye Duaları", "en": "Ruqyah Shari'ah"][lang] ?? titleEn
        case .essential:
            return ["ar": "أدعية جامعة ومختارة", "ur": "جامع دعائیں", "tr": "Temel Dualar", "en": "Essential Duas"][lang] ?? titleEn
        case .hajj:
            return ["ar": "أدعية الحج والعمرة", "ur": "حج اور عمرہ کی دعائیں", "tr": "Hac ve Umre Duaları", "en": "Hajj & Umrah Duas"][lang] ?? titleEn
        }
    }

    public var chapterFragment: String {
        switch self {
        case .morning: return "الصباح"
        case .evening: return "المساء"
        case .sleep: return "أذكار النوم"
        case .wakeUp: return "الاستيقاظ"
        case .afterPrayer: return "بعد السلام من الصلاة"
        case .travel: return "السفر"
        case .ruqiya: return "الرقية الشرعية"
        case .hajj: return "الحج"
        case .essential: return "أدعية جامعة ومختارة"
        case .rabbana: return "ربنا"
        case .grief: return "الهم والحزن"
        case .debt: return "قضاء الدين"
        case .mosque: return "المسجد"
        case .missedRakah: return "المسبوق"
        }
    }

    public var purposeKey: String {
        switch self {
        case .morning: return "azkar_purpose_morning"
        case .evening: return "azkar_purpose_evening"
        case .sleep: return "azkar_purpose_sleep"
        case .wakeUp: return "azkar_purpose_wake_up"
        case .afterPrayer: return "azkar_purpose_after_prayer"
        case .mosque: return "azkar_purpose_mosque"
        case .ruqiya: return "azkar_purpose_ruqiya"
        case .grief: return "azkar_purpose_grief"
        case .debt: return "azkar_purpose_debt"
        case .travel: return "azkar_purpose_travel"
        case .hajj: return "azkar_purpose_hajj"
        case .rabbana: return "azkar_purpose_rabbana"
        case .essential: return "azkar_purpose_essential"
        case .missedRakah: return "azkar_purpose_missed_rakah"
        }
    }

    public static func suggested(forHour hour: Int) -> AzkarCategory {
        switch hour {
        case 4...11: return .morning
        case 12...16: return .afterPrayer
        case 17...21: return .evening
        default: return .sleep
        }
    }
}

public enum AzkarFilterTab: String, CaseIterable, Sendable, Identifiable {
    case all
    case daily
    case prayer
    case protection
    case quranic

    public var id: String { rawValue }

    public func label(language: String) -> String {
        if language.hasPrefix("ar") {
            switch self {
            case .all: return "الكل"
            case .daily: return "اليومية"
            case .prayer: return "الصلوات"
            case .protection: return "الحفظ والرقية"
            case .quranic: return "الأدعية"
            }
        }
        if language.hasPrefix("ur") {
            switch self {
            case .all: return "سب"
            case .daily: return "روزمرہ"
            case .prayer: return "نمازیں"
            case .protection: return "حفاظت اور رقیہ"
            case .quranic: return "دعائیں"
            }
        }
        if language.hasPrefix("tr") {
            switch self {
            case .all: return "Tümü"
            case .daily: return "Günlük"
            case .prayer: return "Namazlar"
            case .protection: return "Koruma & Rukye"
            case .quranic: return "Dualar"
            }
        }
        switch self {
        case .all: return "All"
        case .daily: return "Daily"
        case .prayer: return "Prayers"
        case .protection: return "Protection"
        case .quranic: return "Supplications"
        }
    }

    public func matches(category: AzkarCategory) -> Bool {
        switch self {
        case .all: return true
        case .daily: return [.morning, .evening, .sleep, .wakeUp].contains(category)
        case .prayer: return [.afterPrayer, .missedRakah, .mosque].contains(category)
        case .protection: return [.ruqiya, .grief, .debt].contains(category)
        case .quranic: return [.rabbana, .essential, .hajj, .travel].contains(category)
        }
    }

    public func matches(chapterTitle title: String) -> Bool {
        switch self {
        case .all:
            return true
        case .daily:
            return ["صباح", "مساء", "نوم", "استيقاظ", "طعام", "لباس", "الثوب", "منزل", "خروج", "دخول"]
                .contains { title.contains($0) }
        case .prayer:
            return ["أذان", "اذان", "وضوء", "مسجد", "صلاة", "ركوع", "سجود", "تشهد", "قنوت", "استفتاح", "السلام من", "الوتر"]
                .contains { title.contains($0) }
        case .protection:
            return ["وسوسة", "كرب", "الهم", "حزن", "عدو", "شيطان", "عين", "سحر", "مرض", "المريض", "فزع", "الدين", "يعوذ", "الدجال", "الشرك"]
                .contains { title.contains($0) }
        case .quranic:
            return ["دعاء", "استغفار", "الاستغفار", "توبة", "سفر", "حج", "عمرة", "صوم", "الصائم", "مطر", "ريح", "رعد", "ربنا"]
                .contains { title.contains($0) }
        }
    }
}

public struct AzkarChapter: Sendable, Equatable, Identifiable {
    public let number: Int
    public let title: String
    public let count: Int

    public var id: Int { number }

    public init(number: Int, title: String, count: Int) {
        self.number = number
        self.title = title
        self.count = count
    }
}

public struct AzkarCompletion: Sendable, Equatable {
    public let done: Int
    public let total: Int

    public static let none = AzkarCompletion(done: 0, total: 0)

    public var isStarted: Bool { done > 0 }
    public var isComplete: Bool { total > 0 && done >= total }
    public var fraction: Double {
        guard total > 0 else { return 0 }
        return min(1, max(0, Double(done) / Double(total)))
    }

    public init(done: Int, total: Int) {
        self.done = done
        self.total = total
    }
}

public struct AzkarItem: Sendable, Equatable, Identifiable {
    public let id: Int
    public let category: String
    public let text: String
    public let transliterationEn: String?
    public let transliterationTr: String?
    public let translationEn: String?
    public let translationTr: String?
    public let count: Int
    public let reference: String?
    public let commentary: String?

    public init(
        id: Int,
        category: String,
        text: String,
        transliterationEn: String? = nil,
        transliterationTr: String? = nil,
        translationEn: String? = nil,
        translationTr: String? = nil,
        count: Int = 1,
        reference: String? = nil,
        commentary: String? = nil
    ) {
        self.id = id
        self.category = category
        self.text = text
        self.transliterationEn = transliterationEn
        self.transliterationTr = transliterationTr
        self.translationEn = translationEn
        self.translationTr = translationTr
        self.count = max(1, count)
        self.reference = reference
        self.commentary = commentary
    }

    // Uthmani script markers identify Quran passages so they render in the Mushaf Hafs face.
    private static let uthmaniMarkers: Set<Unicode.Scalar> = ["\u{0671}", "\u{06E1}", "\u{06E5}", "\u{06E6}"]

    public var isQuranic: Bool {
        text.unicodeScalars.contains { Self.uthmaniMarkers.contains($0) }
    }

    public func localizedCommentary(language: String) -> String? {
        Self.pickLocalized(commentary, language: language)
    }

    public func localizedReference(language: String) -> String? {
        Self.pickLocalized(reference, language: language)
    }

    public func localizedTranslation(language: String) -> String? {
        if language.hasPrefix("ar") { return nil }
        let value = language.hasPrefix("tr") ? (translationTr ?? translationEn) : translationEn
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    public func localizedTransliteration(language: String) -> String? {
        if language.hasPrefix("ar") { return nil }
        let stored = language.hasPrefix("tr") ? (transliterationTr ?? transliterationEn) : transliterationEn
        if let stored {
            let trimmed = stored.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        let generated = ArabicTransliterator.transliterate(text)
        return generated.isEmpty ? nil : generated
    }

    public static func pickLocalized(_ value: String?, language: String) -> String? {
        guard let comm = value else { return nil }
        let hasTags = comm.contains("[ar]") || comm.contains("[en]")
        if !hasTags {
            if comm.contains("\n") {
                let lines = comm.split(separator: "\n", omittingEmptySubsequences: true)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                let arLines = lines.filter { line in
                    var ar = 0
                    var latin = 0
                    for s in line.unicodeScalars {
                        if (0x0600...0x06FF).contains(s.value) || (0xFB50...0xFDFF).contains(s.value) || (0xFE70...0xFEFF).contains(s.value) {
                            ar += 1
                        } else if (0x0041...0x005A).contains(s.value) || (0x0061...0x007A).contains(s.value) {
                            latin += 1
                        }
                    }
                    return ar > 0 && ar > latin
                }
                let latinLines = lines.filter { line in
                    var ar = 0
                    var latin = 0
                    for s in line.unicodeScalars {
                        if (0x0600...0x06FF).contains(s.value) {
                            ar += 1
                        } else if (0x0041...0x005A).contains(s.value) || (0x0061...0x007A).contains(s.value) {
                            latin += 1
                        }
                    }
                    return latin > 0 && latin >= ar
                }
                if !arLines.isEmpty && !latinLines.isEmpty {
                    let chosen = (language.hasPrefix("ar") || language.hasPrefix("ur")) ? arLines : latinLines
                    let joined = chosen.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                    return joined.isEmpty ? nil : joined
                }
            }
            let trimmed = comm.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        let prefix: String
        if language.hasPrefix("ar") {
            prefix = "[ar]"
        } else if language.hasPrefix("ur") {
            prefix = comm.contains("[ur]") ? "[ur]" : "[ar]"
        } else if language.hasPrefix("tr") {
            prefix = comm.contains("[tr]") ? "[tr]" : (comm.contains("[en]") ? "[en]" : "[ar]")
        } else {
            prefix = comm.contains("[en]") ? "[en]" : "[ar]"
        }

        guard let range = comm.range(of: prefix) else {
            let head = comm.split(separator: "[", maxSplits: 1).first.map(String.init) ?? comm
            let trimmed = head.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        let after = comm[range.upperBound...]
        let body: Substring
        if let nextTag = after.firstIndex(of: "[") {
            body = after[..<nextTag]
        } else {
            body = after
        }
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

public struct HisnChapterTitles: Codable, Sendable, Equatable {
    public let en: String
    public let tr: String
    public let ur: String

    public init(en: String, tr: String, ur: String) {
        self.en = en
        self.tr = tr
        self.ur = ur
    }
}

public struct AzkarCatalog: Sendable {
    public static let seedVersion = 6

    public let items: [AzkarItem]
    public let chapters: [AzkarChapter]
    public let chapterTitles: [String: HisnChapterTitles]

    public static let empty = AzkarCatalog(items: [], chapters: [], chapterTitles: [:])

    public init(items: [AzkarItem], chapters: [AzkarChapter], chapterTitles: [String: HisnChapterTitles]) {
        self.items = items
        self.chapters = chapters
        self.chapterTitles = chapterTitles
    }

    private struct RawChapter: Decodable {
        let title: String
        let azkar: [RawDhikr]
    }

    private struct RawDhikr: Decodable {
        let text: String
        let count: Int?
        let reward: String?
        let reference: String?
        let commentary: String?
        let transliterationEn: String?
        let transliterationTr: String?
        let translationEn: String?
        let translationTr: String?
    }

    public static func parse(azkarData: Data, hisnTitlesData: Data?) -> AzkarCatalog {
        guard let rawChapters = try? JSONDecoder().decode([RawChapter].self, from: azkarData) else {
            return .empty
        }
        let titles: [String: HisnChapterTitles]
        if let hisnTitlesData,
           let decoded = try? JSONDecoder().decode([String: HisnChapterTitles].self, from: hisnTitlesData) {
            titles = decoded
        } else {
            titles = [:]
        }

        var items: [AzkarItem] = []
        var chapters: [AzkarChapter] = []
        var nextId = 1

        for (index, chapter) in rawChapters.enumerated() {
            chapters.append(AzkarChapter(number: index + 1, title: chapter.title, count: chapter.azkar.count))
            for entry in chapter.azkar {
                let reward = entry.reward?.trimmingCharacters(in: .whitespacesAndNewlines)
                let ref = (reward?.isEmpty == false ? reward : nil) ?? entry.reference
                items.append(AzkarItem(
                    id: nextId,
                    category: chapter.title,
                    text: entry.text,
                    transliterationEn: entry.transliterationEn,
                    transliterationTr: entry.transliterationTr,
                    translationEn: entry.translationEn,
                    translationTr: entry.translationTr,
                    count: max(1, entry.count ?? 1),
                    reference: ref,
                    commentary: entry.commentary
                ))
                nextId += 1
            }
        }

        return AzkarCatalog(items: items, chapters: chapters, chapterTitles: titles)
    }

    public func items(forCategoryKey key: String) -> [AzkarItem] {
        let upper = key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let resolvedKey = upper == "MASJID" ? "MOSQUE" : upper
        if let cat = AzkarCategory(rawValue: resolvedKey) {
            let fragment = cat.chapterFragment
            return items.filter { $0.category.contains(fragment) }
        }
        let exact = key.trimmingCharacters(in: .whitespacesAndNewlines)
        return items.filter { $0.category == exact }
    }

    public func localizedChapterTitle(_ arabicTitle: String, language: String) -> String {
        guard let titles = chapterTitles[arabicTitle] else { return arabicTitle }
        if language.hasPrefix("en") { return titles.en }
        if language.hasPrefix("tr") { return titles.tr }
        if language.hasPrefix("ur") { return titles.ur }
        return arabicTitle
    }

    public func title(forCategoryKey key: String, language: String) -> String {
        let upper = key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let resolvedKey = upper == "MASJID" ? "MOSQUE" : upper
        if let cat = AzkarCategory(rawValue: resolvedKey) {
            return cat.detailTitle(language: language)
        }
        return localizedChapterTitle(key.trimmingCharacters(in: .whitespacesAndNewlines), language: language)
    }
}
