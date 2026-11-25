import Foundation

public enum WidgetQuoteBook: String, Sendable, Equatable {
    case bukhari
    case muslim
    case tirmidhi
    case abuDawud
    case ibnMajah
    case hisn
    case quran

    public func name(language: String) -> String {
        let base = SirajLocalizer.baseLanguage(language)
        switch self {
        case .bukhari:
            switch base {
            case "ar": return "البخاري"
            case "tr": return "Buhârî"
            case "ur": return "بخاری"
            default: return "Bukhari"
            }
        case .muslim:
            switch base {
            case "ar": return "مسلم"
            case "tr": return "Müslim"
            case "ur": return "مسلم"
            default: return "Muslim"
            }
        case .tirmidhi:
            switch base {
            case "ar": return "الترمذي"
            case "tr": return "Tirmizî"
            case "ur": return "ترمذی"
            default: return "Tirmidhi"
            }
        case .abuDawud:
            switch base {
            case "ar": return "أبو داود"
            case "tr": return "Ebû Dâvûd"
            case "ur": return "ابو داود"
            default: return "Abu Dawud"
            }
        case .ibnMajah:
            switch base {
            case "ar": return "ابن ماجه"
            case "tr": return "İbn Mâce"
            case "ur": return "ابن ماجہ"
            default: return "Ibn Majah"
            }
        case .hisn:
            switch base {
            case "ar": return "حصن المسلم"
            case "tr": return "Hısnü'l-Müslim"
            case "ur": return "حصن المسلم"
            default: return "Hisn al-Muslim"
            }
        case .quran:
            switch base {
            case "ar": return "القرآن"
            case "tr": return "Kur'an"
            case "ur": return "قرآن"
            default: return "Quran"
            }
        }
    }
}

public struct WidgetQuoteRef: Sendable, Equatable {
    public let book: WidgetQuoteBook
    public let number: Int
    public let ayah: Int

    public init(_ book: WidgetQuoteBook, _ number: Int, ayah: Int = 0) {
        self.book = book
        self.number = number
        self.ayah = ayah
    }

    public func label(language: String, numeralSystem: String) -> String {
        let raw = book == .quran ? "\(number):\(ayah)" : "\(number)"
        let localized = DigitFormatter.localizeDigits(raw, numeralSystem: numeralSystem, lang: language)
        return "\(book.name(language: language)) \(localized)"
    }
}

public enum WidgetDhikrOccasion: String, Sendable, Equatable {
    case morningEvening
    case morning
    case evening
    case waking
    case afterPrayer
    case sleep
    case any

    public func name(language: String) -> String {
        let base = SirajLocalizer.baseLanguage(language)
        switch self {
        case .morningEvening:
            switch base {
            case "ar": return "أذكار الصباح والمساء"
            case "tr": return "Sabah ve akşam"
            case "ur": return "صبح و شام"
            default: return "Morning and evening"
            }
        case .morning:
            switch base {
            case "ar": return "أذكار الصباح"
            case "tr": return "Sabah"
            case "ur": return "صبح"
            default: return "Morning"
            }
        case .evening:
            switch base {
            case "ar": return "أذكار المساء"
            case "tr": return "Akşam"
            case "ur": return "شام"
            default: return "Evening"
            }
        case .waking:
            switch base {
            case "ar": return "عند الاستيقاظ"
            case "tr": return "Uyanınca"
            case "ur": return "جاگنے پر"
            default: return "On waking"
            }
        case .afterPrayer:
            switch base {
            case "ar": return "بعد الصلاة"
            case "tr": return "Namazdan sonra"
            case "ur": return "نماز کے بعد"
            default: return "After the prayer"
            }
        case .sleep:
            switch base {
            case "ar": return "عند النوم"
            case "tr": return "Uyumadan önce"
            case "ur": return "سونے سے پہلے"
            default: return "Before sleep"
            }
        case .any:
            switch base {
            case "ar": return "في كل وقت"
            case "tr": return "Her zaman"
            case "ur": return "ہر وقت"
            default: return "Any time"
            }
        }
    }

    public func fits(category: AzkarCategory) -> Bool {
        switch self {
        case .any: return true
        case .morningEvening: return category == .morning || category == .evening
        case .morning, .waking: return category == .morning
        case .evening: return category == .evening
        case .afterPrayer: return category == .afterPrayer
        case .sleep: return category == .sleep
        }
    }
}

public struct WidgetQuoteText: Sendable, Equatable {
    public let ar: String
    public let en: String
    public let tr: String
    public let ur: String

    public init(_ ar: String, _ en: String, _ tr: String, _ ur: String) {
        self.ar = ar
        self.en = en
        self.tr = tr
        self.ur = ur
    }

    public func meaning(language: String) -> String {
        switch SirajLocalizer.baseLanguage(language) {
        case "ar": return ar
        case "tr": return tr
        case "ur": return ur
        default: return en
        }
    }
}

public struct WidgetShortHadith: Sendable, Equatable {
    public let quote: WidgetQuoteText
    public let refs: [WidgetQuoteRef]

    public func source(language: String, numeralSystem: String) -> String {
        refs.map { $0.label(language: language, numeralSystem: numeralSystem) }.joined(separator: " · ")
    }
}

public struct WidgetShortDhikr: Sendable, Equatable {
    public let quote: WidgetQuoteText
    public let occasion: WidgetDhikrOccasion
    public let ref: WidgetQuoteRef

    public func source(language: String, numeralSystem: String) -> String {
        "\(occasion.name(language: language)) · \(ref.label(language: language, numeralSystem: numeralSystem))"
    }
}

public struct WidgetTasbihStep: Sendable, Equatable {
    public static let total = 100
    public static let phrases = ["سُبْحَانَ اللَّهِ", "الْحَمْدُ لِلَّهِ", "اللَّهُ أَكْبَرُ"]
    public static let meaningKeys = ["widget_tasbih_meaning_1", "widget_tasbih_meaning_2", "widget_tasbih_meaning_3"]

    public let phraseIndex: Int
    public let inPhrase: Int
    public let ofPhrase: Int
    public let isDone: Bool

    public var phraseArabic: String { Self.phrases[phraseIndex] }
    public var meaningKey: String { Self.meaningKeys[phraseIndex] }
    public var fraction: Double {
        isDone ? 1.0 : Double(inPhrase) / Double(max(1, ofPhrase))
    }

    public static func of(count: Int) -> WidgetTasbihStep {
        let clamped = max(0, min(total, count))
        if clamped >= total {
            return WidgetTasbihStep(phraseIndex: 2, inPhrase: 34, ofPhrase: 34, isDone: true)
        }
        if clamped <= 33 {
            return WidgetTasbihStep(phraseIndex: 0, inPhrase: clamped, ofPhrase: 33, isDone: false)
        }
        if clamped <= 66 {
            return WidgetTasbihStep(phraseIndex: 1, inPhrase: clamped - 33, ofPhrase: 33, isDone: false)
        }
        return WidgetTasbihStep(phraseIndex: 2, inPhrase: clamped - 66, ofPhrase: 34, isDone: false)
    }
}

public enum WidgetQuotesCatalog {
    public static func slot(for date: Date, rotation: QuoteRotation, prayerIndex: Int = 0) -> Int {
        let seconds = Int64(date.timeIntervalSince1970)
        switch rotation {
        case .hour:
            return Int(seconds / 3600)
        case .prayer:
            let day = Int(seconds / 86_400)
            return day * 6 + max(0, min(5, prayerIndex))
        case .day:
            return Int(seconds / 86_400)
        }
    }

    public static func hadith(forSlot slot: Int) -> WidgetShortHadith {
        hadiths[stepIndex(slot: slot, count: hadiths.count)]
    }

    public static func verse(forSlot slot: Int) -> OfflineDailyVerse {
        let list = DailyQuotesCatalog.verses
        return list[stepIndex(slot: slot, count: list.count)]
    }

    public static func dhikr(forSlot slot: Int, category: AzkarCategory) -> WidgetShortDhikr {
        let matching = dhikrs.filter { $0.occasion.fits(category: category) }
        let pool = matching.isEmpty ? dhikrs : matching
        let offset: Int = {
            switch category {
            case .morning: return 0
            case .afterPrayer: return 1
            case .evening: return 2
            case .sleep: return 3
            default: return 0
            }
        }()
        let idx = ((slot * 4 + offset) % pool.count + pool.count) % pool.count
        return pool[idx]
    }

    private static func stepIndex(slot: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let stride = count % 7 == 0 ? 1 : 7
        return ((slot * stride) % count + count) % count
    }

    public static let hadiths: [WidgetShortHadith] = [
        WidgetShortHadith(
            quote: WidgetQuoteText(
                "إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى",
                "Actions are only by intentions, and every person will have only what they intended.",
                "Ameller ancak niyetlere göredir. Herkese ancak niyet ettiği şey vardır.",
                "اعمال کا دارومدار نیتوں پر ہے، اور ہر شخص کو وہی ملے گا جس کی اس نے نیت کی۔"
            ),
            refs: [WidgetQuoteRef(.bukhari, 1)]
        ),
        WidgetShortHadith(
            quote: WidgetQuoteText(
                "لا يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ",
                "None of you truly believes until he loves for his brother what he loves for himself.",
                "Sizden biri, kendisi için istediğini kardeşi için de istemedikçe gerçekten iman etmiş olmaz.",
                "تم میں سے کوئی مومن نہیں ہو سکتا جب تک اپنے بھائی کے لیے وہی پسند نہ کرے جو اپنے لیے پسند کرتا ہے۔"
            ),
            refs: [WidgetQuoteRef(.bukhari, 13)]
        ),
        WidgetShortHadith(
            quote: WidgetQuoteText(
                "خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ",
                "The best of you are those who learn the Quran and teach it.",
                "Sizin en hayırlınız, Kur'an'ı öğrenen ve öğretendir.",
                "تم میں سب سے بہتر وہ ہے جو قرآن سیکھے اور سکھائے۔"
            ),
            refs: [WidgetQuoteRef(.bukhari, 5027)]
        ),
        WidgetShortHadith(
            quote: WidgetQuoteText(
                "أَحَبُّ الأَعْمَالِ إِلَى اللَّهِ تَعَالَى أَدْوَمُهَا وَإِنْ قَلَّ",
                "The deeds most loved by Allah are those done regularly, even if they are small.",
                "Allah'a en sevimli gelen amel, az da olsa devamlı olanıdır.",
                "اللہ کو سب سے زیادہ وہ عمل پسند ہے جو ہمیشہ کیا جائے، چاہے تھوڑا ہو۔"
            ),
            refs: [WidgetQuoteRef(.muslim, 783)]
        ),
        WidgetShortHadith(
            quote: WidgetQuoteText(
                "إِنَّ اللَّهَ رَفِيقٌ يُحِبُّ الرِّفْقَ فِي الأَمْرِ كُلِّهِ",
                "Allah is gentle, and He loves gentleness in every matter.",
                "Allah yumuşak davranandır ve her işte yumuşaklığı sever.",
                "اللہ نرمی کرنے والا ہے اور ہر معاملے میں نرمی کو پسند کرتا ہے۔"
            ),
            refs: [WidgetQuoteRef(.bukhari, 6927)]
        ),
        WidgetShortHadith(
            quote: WidgetQuoteText(
                "الْمُسْلِمُ مَنْ سَلِمَ الْمُسْلِمُونَ مِنْ لِسَانِهِ وَيَدِهِ",
                "A Muslim is one from whose tongue and hand other Muslims are safe.",
                "Müslüman, dilinden ve elinden Müslümanların emin olduğu kimsedir.",
                "مسلمان وہ ہے جس کی زبان اور ہاتھ سے دوسرے مسلمان محفوظ رہیں۔"
            ),
            refs: [WidgetQuoteRef(.bukhari, 10), WidgetQuoteRef(.muslim, 41)]
        ),
        WidgetShortHadith(
            quote: WidgetQuoteText(
                "لَيْسَ الشَّدِيدُ بِالصُّرَعَةِ، إِنَّمَا الشَّدِيدُ الَّذِي يَمْلِكُ نَفْسَهُ عِنْدَ الْغَضَبِ",
                "The strong one is not the one who wrestles others down, but the one who keeps hold of himself when angry.",
                "Güçlü kimse, güreşte rakibini yenen değildir. Asıl güçlü, öfkelendiğinde kendine hâkim olandır.",
                "طاقتور وہ نہیں جو کشتی میں پچھاڑ دے، طاقتور وہ ہے جو غصے کے وقت اپنے آپ پر قابو رکھے۔"
            ),
            refs: [WidgetQuoteRef(.bukhari, 6114), WidgetQuoteRef(.muslim, 2609)]
        ),
        WidgetShortHadith(
            quote: WidgetQuoteText(
                "يَسِّرُوا وَلاَ تُعَسِّرُوا، وَبَشِّرُوا وَلاَ تُنَفِّرُوا",
                "Make things easy, not hard. Give good news, and do not drive people away.",
                "Kolaylaştırın, zorlaştırmayın. Müjdeleyin, nefret ettirmeyin.",
                "آسانی پیدا کرو، مشکل نہ بناؤ؛ خوشخبری دو، نفرت نہ دلاؤ۔"
            ),
            refs: [WidgetQuoteRef(.bukhari, 69)]
        ),
        WidgetShortHadith(
            quote: WidgetQuoteText(
                "مَنْ لاَ يَرْحَمُ لاَ يُرْحَمُ",
                "Whoever shows no mercy will be shown no mercy.",
                "Merhamet etmeyene merhamet edilmez.",
                "جو رحم نہیں کرتا اس پر رحم نہیں کیا جاتا۔"
            ),
            refs: [WidgetQuoteRef(.bukhari, 5997), WidgetQuoteRef(.muslim, 2318)]
        ),
        WidgetShortHadith(
            quote: WidgetQuoteText(
                "إِنَّ اللَّهَ لاَ يَنْظُرُ إِلَى صُوَرِكُمْ وَأَمْوَالِكُمْ وَلَكِنْ يَنْظُرُ إِلَى قُلُوبِكُمْ وَأَعْمَالِكُمْ",
                "Allah does not look at your looks or your wealth. He looks at your hearts and your deeds.",
                "Allah sizin suretlerinize ve mallarınıza bakmaz; kalplerinize ve amellerinize bakar.",
                "اللہ تمہاری صورتوں اور مالوں کو نہیں دیکھتا، بلکہ تمہارے دلوں اور اعمال کو دیکھتا ہے۔"
            ),
            refs: [WidgetQuoteRef(.muslim, 2564)]
        ),
        WidgetShortHadith(
            quote: WidgetQuoteText(
                "مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقًا إِلَى الْجَنَّةِ",
                "Whoever sets out on a path seeking knowledge, Allah makes easy for him a path to Paradise.",
                "Kim ilim öğrenmek için bir yola girerse, Allah ona cennete giden yolu kolaylaştırır.",
                "جو علم کی تلاش میں کسی راستے پر چلے، اللہ اس کے لیے جنت کا راستہ آسان کر دیتا ہے۔"
            ),
            refs: [WidgetQuoteRef(.muslim, 2699)]
        ),
        WidgetShortHadith(
            quote: WidgetQuoteText(
                "لاَ يَشْكُرُ اللَّهَ مَنْ لاَ يَشْكُرُ النَّاسَ",
                "Whoever does not thank people has not thanked Allah.",
                "İnsanlara teşekkür etmeyen, Allah'a da şükretmiş olmaz.",
                "جو لوگوں کا شکریہ ادا نہیں کرتا وہ اللہ کا بھی شکر ادا نہیں کرتا۔"
            ),
            refs: [WidgetQuoteRef(.abuDawud, 4811)]
        ),
        WidgetShortHadith(
            quote: WidgetQuoteText(
                "أَقْرَبُ مَا يَكُونُ الْعَبْدُ مِنْ رَبِّهِ وَهُوَ سَاجِدٌ فَأَكْثِرُوا الدُّعَاءَ",
                "A servant is never nearer to his Lord than when he is in prostration, so pray much then.",
                "Kulun Rabbine en yakın olduğu an secdede olduğu andır. Öyleyse secdede çok dua edin.",
                "بندہ اپنے رب کے سب سے زیادہ قریب سجدے میں ہوتا ہے، لہٰذا اس میں کثرت سے دعا کرو۔"
            ),
            refs: [WidgetQuoteRef(.muslim, 482)]
        ),
        WidgetShortHadith(
            quote: WidgetQuoteText(
                "الدُّعَاءُ هُوَ الْعِبَادَةُ",
                "Supplication is worship.",
                "Dua ibadetin ta kendisidir.",
                "دعا ہی عبادت ہے۔"
            ),
            refs: [WidgetQuoteRef(.abuDawud, 1479), WidgetQuoteRef(.tirmidhi, 2969)]
        ),
        WidgetShortHadith(
            quote: WidgetQuoteText(
                "مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ",
                "Whoever believes in Allah and the Last Day, let him say something good or stay silent.",
                "Allah'a ve ahiret gününe iman eden, ya hayır söylesin ya da sussun.",
                "جو اللہ اور آخرت کے دن پر ایمان رکھتا ہے، وہ اچھی بات کہے یا خاموش رہے۔"
            ),
            refs: [WidgetQuoteRef(.bukhari, 6018), WidgetQuoteRef(.muslim, 47)]
        ),
        WidgetShortHadith(
            quote: WidgetQuoteText(
                "نِعْمَتَانِ مَغْبُونٌ فِيهِمَا كَثِيرٌ مِنَ النَّاسِ، الصِّحَّةُ وَالْفَرَاغُ",
                "Two blessings that many people waste: health and free time.",
                "İki nimet vardır ki insanların çoğu onların kıymetini bilmez: sağlık ve boş vakit.",
                "دو نعمتیں ایسی ہیں جن کی قدر بہت سے لوگ نہیں کرتے: صحت اور فراغت۔"
            ),
            refs: [WidgetQuoteRef(.bukhari, 6412)]
        ),
        WidgetShortHadith(
            quote: WidgetQuoteText(
                "الطُّهُورُ شَطْرُ الإِيمَانِ",
                "Cleanliness is half of faith.",
                "Abdest imanın yarısıdır.",
                "پاکیزگی نصف ایمان ہے۔"
            ),
            refs: [WidgetQuoteRef(.muslim, 223)]
        ),
        WidgetShortHadith(
            quote: WidgetQuoteText(
                "تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ لَكَ صَدَقَةٌ",
                "Your smiling in the face of your brother is charity.",
                "Kardeşinizin yüzüne gülmeniz size sadaka sevâbı kazandırır.",
                "اپنے بھائی کے سامنے تمہارا مسکرانا تمہارے لیے صدقہ ہے۔"
            ),
            refs: [WidgetQuoteRef(.tirmidhi, 1956)]
        ),
        WidgetShortHadith(
            quote: WidgetQuoteText(
                "الدِّينُ النَّصِيحَةُ",
                "The religion is sincerity.",
                "Din nasihattir.",
                "دین خیر خواہی کا نام ہے۔"
            ),
            refs: [WidgetQuoteRef(.muslim, 55)]
        ),
        WidgetShortHadith(
            quote: WidgetQuoteText(
                "مَنْ صَلَّى عَلَىَّ وَاحِدَةً صَلَّى اللَّهُ عَلَيْهِ عَشْرًا",
                "He who blesses me once, Allah blesses him ten times.",
                "Her kim bana bir salavât getirirse Allah ona on salât eyler.",
                "جس نے مجھ پر ایک بار درود بھیجا اللہ تعالیٰ اس پر دس بار رحمت نازل فرمائے گا۔"
            ),
            refs: [WidgetQuoteRef(.muslim, 408)]
        ),
        WidgetShortHadith(
            quote: WidgetQuoteText(
                "إِنَّ اللَّهَ جَمِيلٌ يُحِبُّ الْجَمَالَ",
                "Allah is Beautiful and He loves beauty.",
                "Şüphesiz Allah güzeldir, güzeli sever.",
                "اللہ خود جمیل ہے، وہ جمال کو پسند فرماتا ہے۔"
            ),
            refs: [WidgetQuoteRef(.muslim, 91)]
        ),
        WidgetShortHadith(
            quote: WidgetQuoteText(
                "الْبِرُّ حُسْنُ الْخُلُقِ",
                "Virtue is good character.",
                "Birr, ahlakın güzelliğidir.",
                "نیکی اچھا خلق ہے۔"
            ),
            refs: [WidgetQuoteRef(.muslim, 2553)]
        ),
        WidgetShortHadith(
            quote: WidgetQuoteText(
                "لَيْسَ الْغِنَى عَنْ كَثْرَةِ الْعَرَضِ، وَلَكِنَّ الْغِنَى غِنَى النَّفْسِ",
                "Wealth is not in having many possessions, rather true wealth is richness of the soul.",
                "Zenginlik mal çokluğundan meydana gelmez. Asıl zenginlik gönül zenginliğidir.",
                "تونگری یہ نہیں ہے کہ سامان زیادہ ہو، بلکہ امیری یہ ہے کہ دل غنی ہو۔"
            ),
            refs: [WidgetQuoteRef(.bukhari, 6446), WidgetQuoteRef(.muslim, 1051)]
        ),
        WidgetShortHadith(
            quote: WidgetQuoteText(
                "الْمَرْءُ مَعَ مَنْ أَحَبَّ",
                "A person will be with those whom he loves.",
                "Kişi sevdiği ile beraberdir.",
                "انسان اس کے ساتھ ہے جس سے وہ محبت رکھتا ہے۔"
            ),
            refs: [WidgetQuoteRef(.bukhari, 6168), WidgetQuoteRef(.muslim, 2640)]
        ),
        WidgetShortHadith(
            quote: WidgetQuoteText(
                "إِنَّ الصِّدْقَ يَهْدِي إِلَى الْبِرِّ، وَإِنَّ الْبِرَّ يَهْدِي إِلَى الْجَنَّةِ",
                "Truthfulness leads to righteousness, and righteousness leads to Paradise.",
                "Şüphesiz doğruluk iyiliğe götürür, iyilik de cennete götürür.",
                "بلاشبہ سچ آدمی کو نیکی کی طرف بلاتا ہے اور نیکی جنت کی طرف لے جاتی ہے۔"
            ),
            refs: [WidgetQuoteRef(.bukhari, 6094), WidgetQuoteRef(.muslim, 2607)]
        )
    ]

    public static let dhikrs: [WidgetShortDhikr] = [
        WidgetShortDhikr(
            quote: WidgetQuoteText(
                "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ",
                "Glory be to Allah and praise be to Him. Glory be to Allah, the Almighty.",
                "Allah'ı hamd ile tesbih ederim. Yüce Allah'ı tesbih ederim.",
                "اللہ پاک ہے اپنی تعریف کے ساتھ، اللہ پاک ہے جو عظمت والا ہے۔"
            ),
            occasion: .any,
            ref: WidgetQuoteRef(.bukhari, 7563)
        ),
        WidgetShortDhikr(
            quote: WidgetQuoteText(
                "لاَ حَوْلَ وَلاَ قُوَّةَ إِلاَّ بِاللَّهِ",
                "There is no power and no strength except through Allah.",
                "Güç ve kuvvet ancak Allah'tandır.",
                "اللہ کے سوا نہ کوئی طاقت ہے نہ قوت۔"
            ),
            occasion: .any,
            ref: WidgetQuoteRef(.hisn, 260)
        ),
        WidgetShortDhikr(
            quote: WidgetQuoteText(
                "أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ",
                "I ask Allah's forgiveness and turn back to Him.",
                "Allah'tan bağışlanma diler, O'na tövbe ederim.",
                "میں اللہ سے مغفرت مانگتا ہوں اور اسی کی طرف رجوع کرتا ہوں۔"
            ),
            occasion: .any,
            ref: WidgetQuoteRef(.hisn, 96)
        ),
        WidgetShortDhikr(
            quote: WidgetQuoteText(
                "سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلاَ إِلَهَ إِلاَّ اللَّهُ، وَاللَّهُ أَكْبَرُ",
                "Glory be to Allah, praise be to Allah, there is no god but Allah, and Allah is the Greatest.",
                "Allah'ı tesbih ederim, hamd Allah'adır, Allah'tan başka ilah yoktur, Allah en büyüktür.",
                "اللہ پاک ہے، سب تعریف اللہ کے لیے ہے، اللہ کے سوا کوئی معبود نہیں، اور اللہ سب سے بڑا ہے۔"
            ),
            occasion: .any,
            ref: WidgetQuoteRef(.hisn, 257)
        ),
        WidgetShortDhikr(
            quote: WidgetQuoteText(
                "اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ",
                "O Allah, send Your blessings and peace upon our Prophet Muhammad.",
                "Allah'ım, Peygamberimiz Muhammed'e salat ve selam eyle.",
                "اے اللہ! ہمارے نبی محمد پر رحمت اور سلامتی نازل فرما۔"
            ),
            occasion: .any,
            ref: WidgetQuoteRef(.hisn, 98)
        ),
        WidgetShortDhikr(
            quote: WidgetQuoteText(
                "يَا حَىُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ",
                "O Ever-Living, O Sustainer of all, in Your mercy I seek help.",
                "Ey Hayy, ey Kayyûm! Rahmetinle senden yardım dilerim.",
                "اے ہمیشہ زندہ، اے سب کو قائم رکھنے والے! تیری رحمت سے مدد مانگتا ہوں۔"
            ),
            occasion: .any,
            ref: WidgetQuoteRef(.tirmidhi, 3524)
        ),
        WidgetShortDhikr(
            quote: WidgetQuoteText(
                "اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي",
                "O Allah, You are Pardoning and You love to pardon, so pardon me.",
                "Allah'ım! Sen affedicisin, affetmeyi seversin; beni de affet.",
                "اے اللہ! تو بہت معاف کرنے والا ہے، معاف کرنے کو پسند کرتا ہے، پس مجھے معاف فرما۔"
            ),
            occasion: .any,
            ref: WidgetQuoteRef(.ibnMajah, 3850)
        ),
        WidgetShortDhikr(
            quote: WidgetQuoteText(
                "حَسْبِيَ اللَّهُ لاَ إِلَهَ إِلاَّ هُوَ عَلَيهِ تَوَكَّلتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ",
                "Allah is enough for me. There is no god but Him. In Him I put my trust, and He is Lord of the mighty Throne.",
                "Allah bana yeter, O'ndan başka ilah yoktur. Yalnız O'na güvendim; O, büyük Arş'ın Rabbidir.",
                "میرے لیے اللہ کافی ہے، اس کے سوا کوئی معبود نہیں، میں نے اسی پر بھروسہ کیا اور وہی عرشِ عظیم کا رب ہے۔"
            ),
            occasion: .morningEvening,
            ref: WidgetQuoteRef(.hisn, 83)
        ),
        WidgetShortDhikr(
            quote: WidgetQuoteText(
                "اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالآخِرَةِ",
                "O Allah, I ask You for pardon and well-being in this world and the next.",
                "Allah'ım, dünyada ve ahirette senden af ve afiyet dilerim.",
                "اے اللہ! میں تجھ سے دنیا اور آخرت میں معافی اور عافیت مانگتا ہوں۔"
            ),
            occasion: .morningEvening,
            ref: WidgetQuoteRef(.hisn, 84)
        ),
        WidgetShortDhikr(
            quote: WidgetQuoteText(
                "بِسْمِ اللَّهِ الَّذِي لاَ يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلاَ فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ",
                "In the name of Allah, with whose name nothing on earth or in the heavens can harm, and He is the All-Hearing, the All-Knowing.",
                "Adı anıldığında yerde ve gökte hiçbir şeyin zarar veremediği Allah'ın adıyla. O, işitendir, bilendir.",
                "اللہ کے نام سے، جس کے نام کے ساتھ زمین و آسمان میں کوئی چیز نقصان نہیں پہنچا سکتی، اور وہی سننے والا، جاننے والا ہے۔"
            ),
            occasion: .morningEvening,
            ref: WidgetQuoteRef(.hisn, 86)
        ),
        WidgetShortDhikr(
            quote: WidgetQuoteText(
                "اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ",
                "O Allah, help me to remember You, to thank You, and to worship You well.",
                "Allah'ım, seni anmak, sana şükretmek ve sana güzelce ibadet etmek için bana yardım et.",
                "اے اللہ! اپنے ذکر، اپنے شکر اور اپنی اچھی عبادت پر میری مدد فرما۔"
            ),
            occasion: .afterPrayer,
            ref: WidgetQuoteRef(.abuDawud, 1522)
        ),
        WidgetShortDhikr(
            quote: WidgetQuoteText(
                "اللَّهُمَّ أَنْتَ السَّلاَمُ، وَمِنْكَ السَّلاَمُ، تَبَارَكْتَ يَا ذَا الْجَلاَلِ وَالْإِكْرَامِ",
                "O Allah, You are Peace and from You comes peace. Blessed are You, Lord of majesty and honour.",
                "Allah'ım, sen Selam'sın, esenlik sendendir. Ey celal ve ikram sahibi, sen ne yücesin.",
                "اے اللہ! تو ہی سلامتی ہے اور تجھ ہی سے سلامتی ہے، تو بابرکت ہے اے جلال اور عزت والے۔"
            ),
            occasion: .afterPrayer,
            ref: WidgetQuoteRef(.hisn, 66)
        ),
        WidgetShortDhikr(
            quote: WidgetQuoteText(
                "بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا",
                "In Your name, O Allah, I die and I live.",
                "Allah'ım, senin adınla ölür ve dirilirim.",
                "اے اللہ! تیرے ہی نام سے مرتا ہوں اور جیتا ہوں۔"
            ),
            occasion: .sleep,
            ref: WidgetQuoteRef(.hisn, 105)
        ),
        WidgetShortDhikr(
            quote: WidgetQuoteText(
                "اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ",
                "O Allah, protect me from Your punishment on the day You raise Your servants.",
                "Allah'ım, kullarını dirilttiğin gün beni azabından koru.",
                "اے اللہ! جس دن تو اپنے بندوں کو اٹھائے گا، مجھے اپنے عذاب سے بچا لینا۔"
            ),
            occasion: .sleep,
            ref: WidgetQuoteRef(.hisn, 104)
        ),
        WidgetShortDhikr(
            quote: WidgetQuoteText(
                "اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْماً نَافِعاً، وَرِزْقاً طَيِّباً، وَعَمَلاً مُتَقَبَّلاً",
                "O Allah, I ask You for knowledge which is beneficial and sustenance which is good, and deeds which are acceptable.",
                "Allah'ım, senden faydalı ilim, temiz rızık ve kabul edilen amel dilerim.",
                "اے اللہ! میں تجھ سے نفع دینے والا علم، پاکیزہ رزق اور قبول ہونے والا عمل مانگتا ہوں۔"
            ),
            occasion: .morning,
            ref: WidgetQuoteRef(.hisn, 95)
        ),
        WidgetShortDhikr(
            quote: WidgetQuoteText(
                "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ",
                "I take refuge in Allah's perfect words from the evil He has created.",
                "Allah'ın eksiksiz kelimelerine, yarattıklarının şerrinden sığınırım.",
                "میں اللہ کے کامل کلمات کی پناہ لیتا ہوں اس کی مخلوق کے شر سے۔"
            ),
            occasion: .evening,
            ref: WidgetQuoteRef(.hisn, 97)
        ),
        WidgetShortDhikr(
            quote: WidgetQuoteText(
                "اللَّهُمَّ لاَ سَهْلَ إِلاَّ مَا جَعَلْتَهُ سَهْلاً، وَأَنْتَ تَجْعَلُ الْحَزْنَ إِذَا شِئْتَ سَهْلاً",
                "O Allah, there is no ease except in that which You have made easy, and You make the difficulty, if You wish, easy.",
                "Allah'ım, senin kolay kıldığından başka kolay yoktur. Sen dilersen zoru da kolay kılarsın.",
                "اے اللہ! کوئی کام آسان نہیں سوائے اس کے جسے تو آسان کر دے، اور تو جب چاہے مشکل کو آسان کر دیتا ہے۔"
            ),
            occasion: .any,
            ref: WidgetQuoteRef(.hisn, 139)
        ),
        WidgetShortDhikr(
            quote: WidgetQuoteText(
                "اللَّهُمَّ اغْفِرْ لِي، وَارْحَمْنِي، وَاهْدِنِي، وَارْزُقْنِي",
                "O Allah, forgive me, have mercy upon me, guide me and grant me sustenance.",
                "Allah'ım, beni bağışla, bana merhamet et, beni doğru yola ilet ve beni rızıklandır.",
                "اے اللہ! مجھے بخش دے، مجھ پر رحم فرما، مجھے ہدایت دے اور مجھے رزق عطا فرما۔"
            ),
            occasion: .any,
            ref: WidgetQuoteRef(.hisn, 262)
        )
    ]
}
