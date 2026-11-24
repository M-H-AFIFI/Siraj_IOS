import Foundation

public struct IslamicOccasion: Sendable, Equatable, Identifiable {
    public let id: String
    public let hijriMonth: Int
    public let hijriDay: Int
    public let titleAr: String
    public let titleEn: String
    public let titleTr: String
    public let titleUr: String
    public let descriptionAr: String
    public let descriptionEn: String
    public let descriptionTr: String
    public let descriptionUr: String

    public func title(language: String) -> String {
        switch language.prefix(2).lowercased() {
        case "ar": return titleAr
        case "ur": return titleUr
        case "tr": return titleTr
        default: return titleEn
        }
    }

    public func description(language: String) -> String {
        switch language.prefix(2).lowercased() {
        case "ar": return descriptionAr
        case "ur": return descriptionUr.isEmpty ? descriptionAr : descriptionUr
        case "tr": return descriptionTr.isEmpty ? descriptionEn : descriptionTr
        default: return descriptionEn
        }
    }

    public var iconAsset: String {
        switch id {
        case "islamic_new_year": return "ic_occasion_islamic_new_year"
        case "ashura": return "ic_occasion_ashura"
        case "isra_miraj": return "ic_occasion_isra_miraj"
        case "mid_shaban": return "ic_occasion_mid_shaban"
        case "ramadan", "ramadan_start": return "ic_occasion_ramadan"
        case "last_ten_ramadan": return "ic_occasion_laylat_qadr"
        case "eid_al_fitr": return "ic_occasion_eid_al_fitr"
        case "day_of_arafah": return "ic_occasion_day_of_arafah"
        case "eid_al_adha": return "ic_occasion_eid_al_adha"
        default: return "ic_occasion_default"
        }
    }
}

public struct DatedOccasion: Sendable, Equatable, Identifiable {
    public var id: String { "\(occasion.id)-\(hijriYear)" }
    public let occasion: IslamicOccasion
    public let date: CivilDate
    public let hijriYear: Int
    public let daysUntil: Int

    public var isToday: Bool { daysUntil == 0 }

    public init(occasion: IslamicOccasion, date: CivilDate, hijriYear: Int, daysUntil: Int) {
        self.occasion = occasion
        self.date = date
        self.hijriYear = hijriYear
        self.daysUntil = daysUntil
    }
}

public enum IslamicOccasions {
    public static let all: [IslamicOccasion] = [
        IslamicOccasion(
            id: "islamic_new_year",
            hijriMonth: 1,
            hijriDay: 1,
            titleAr: "رأس السنة الهجرية",
            titleEn: "Islamic New Year",
            titleTr: "Hicri Yılbaşı",
            titleUr: "نیا اسلامی سال",
            descriptionAr: "بداية العام الهجري الجديد واستذكار هجرة النبي صلى الله عليه وسلم من مكة إلى المدينة المنورة.",
            descriptionEn: "The first day of the Islamic lunar calendar, marking the migration (Hijrah) of Prophet Muhammad (PBUH) from Mecca to Medina.",
            descriptionTr: "Hicri takvimin başlangıcı ve Peygamber Efendimiz'in (s.a.v.) Mekke'den Medine'ye kutlu hicretinin hatırası.",
            descriptionUr: "نئے ہجری سال کا آغاز اور رسول اللہ صلی اللہ علیہ وسلم کی مکہ سے مدینہ ہجرت کی یاد۔"
        ),
        IslamicOccasion(
            id: "ashura",
            hijriMonth: 1,
            hijriDay: 10,
            titleAr: "يوم عاشوراء",
            titleEn: "Day of Ashura",
            titleTr: "Aşure Günü",
            titleUr: "یومِ عاشورہ",
            descriptionAr: "اليوم الذي نجى الله فيه موسى عليه السلام وقومه من فرعون، ويسن صيامه وصيام يوم قبله أو بعده.",
            descriptionEn: "The day Allah saved Prophet Musa (AS) and Bani Israel from Pharaoh. Fasting on this day expiates sins of the previous year.",
            descriptionTr: "Allah Teala'nın Hz. Musa (a.s.) ve kavmini Firavun'dan kurtardığı gün; bu günde oruç tutmak geçmiş bir yıllık günahlara kefarettir.",
            descriptionUr: "وہ دن جس میں اللہ تعالیٰ نے حضرت موسیٰ علیہ السلام اور ان کی قوم کو فرعون سے نجات دی، اس دن کا روزہ پچھلے ایک سال کے گناہوں کا کفارہ ہے۔"
        ),
        IslamicOccasion(
            id: "isra_miraj",
            hijriMonth: 7,
            hijriDay: 27,
            titleAr: "الإسراء والمعراج",
            titleEn: "Al-Isra' wal-Mi'raj",
            titleTr: "Miraç Kandili",
            titleUr: "اسراء و معراج",
            descriptionAr: "رحلة الإسراء من المسجد الحرام إلى المسجد الأقصى والمعراج إلى السماوات العلى حيث فرضت الصلوات الخمس.",
            descriptionEn: "The miraculous night journey of Prophet Muhammad (PBUH) to Jerusalem and ascension to the Heavens, where the five daily prayers were ordained.",
            descriptionTr: "Peygamber Efendimiz'in (s.a.v.) Mescid-i Haram'dan Mescid-i Aksa'ya gece yolculuğu ve beş vakit namazın farz kılındığı semaya yükselişi.",
            descriptionUr: "مسجدِ حرام سے مسجدِ اقصی اور آسمانوں کی معجزاتی سیر جہاں پانچ وقت کی نمازیں فرض کی گئیں۔"
        ),
        IslamicOccasion(
            id: "mid_shaban",
            hijriMonth: 8,
            hijriDay: 15,
            titleAr: "ليلة النصف من شعبان",
            titleEn: "Mid-Sha'ban",
            titleTr: "Berat Kandili",
            titleUr: "شبِ برات",
            descriptionAr: "ليلة مباركة يغفر الله فيها لخلقه إلا لمشرك أو مشاحن، وهي مقدمة لشهر رمضان المبارك.",
            descriptionEn: "A blessed night of forgiveness and spiritual renewal preceding the holy month of Ramadan.",
            descriptionTr: "Kulların af ve mağfirete nail olduğu, duaların kabul edildiği mübarek gece ve Ramazan'ın müjdecisi.",
            descriptionUr: "مغفرت، رحمت اور دعاؤں کی قبولیت کی برکت والی رات اور ماہِ رمضان کا پیش خیمہ۔"
        ),
        IslamicOccasion(
            id: "ramadan_start",
            hijriMonth: 9,
            hijriDay: 1,
            titleAr: "أول أيام شهر رمضان",
            titleEn: "First Day of Ramadan",
            titleTr: "Ramazan-ı Şerif'in Başlangıcı",
            titleUr: "رمضان المبارک کا آغاز",
            descriptionAr: "بداية شهر الصيام والقيام ونزول القرآن الكريم، شهر الرحمة والمغفرة والعتق من النيران.",
            descriptionEn: "Beginning of the holy month of fasting, intense worship, charity, and the revelation of the Holy Quran.",
            descriptionTr: "Oruç, teravih ve Kur'an ayı olan Ramazan'ın başlangıcı; rahmet, mağfiret ve cehennemden kurtuluş mevsimi.",
            descriptionUr: "روزہ، تراویح اور تلاوتِ قرآن کے مبارک مہینے کا آغاز، جو رحمت، مغفرت اور جہنم سے آزادی کا موسم ہے۔"
        ),
        IslamicOccasion(
            id: "last_ten_ramadan",
            hijriMonth: 9,
            hijriDay: 21,
            titleAr: "العشر الأواخر من رمضان",
            titleEn: "Last Ten Days of Ramadan",
            titleTr: "Ramazan'ın Son On Günü",
            titleUr: "رمضان کے آخری دس دن",
            descriptionAr: "أفضل عشر ليالٍ في العام، تُطلب فيها ليلة القدر في أوتارها، وتُشدّ فيها الأحزمة للعبادة والاعتكاف والدعاء.",
            descriptionEn: "The most blessed ten nights of the year. Seek Laylat al-Qadr in their odd nights, and fill them with prayer, remembrance, and du'a.",
            descriptionTr: "Yılın en bereketli on gecesi; Kadir Gecesi'ni tek gecelerde ara, ibadete, zikre ve duaya yoğunlaş.",
            descriptionUr: "سال کی سب سے بابرکت دس راتیں جن میں شبِ قدر طاق راتوں میں تلاش کی جاتی ہے، اور عبادت، اعتکاف اور دعا کا خاص اہتمام ہوتا ہے۔"
        ),
        IslamicOccasion(
            id: "eid_al_fitr",
            hijriMonth: 10,
            hijriDay: 1,
            titleAr: "عيد الفطر المبارك",
            titleEn: "Eid al-Fitr",
            titleTr: "Ramazan Bayramı",
            titleUr: "عید الفطر",
            descriptionAr: "يوم الجائزة والفرح بإتمام صيام شهر رمضان المبارك، وإخراج زكاة الفطر وصلة الرحم.",
            descriptionEn: "The joyous festival celebrating the completion of Ramadan fasting, accompanied by charity and congregational prayers.",
            descriptionTr: "Ramazan orucunu tamamlamanın şükrü, sevinci ve yardımlaşma günü.",
            descriptionUr: "رمضان المبارک کے روزے مکمل ہونے پر شکر، خوشی اور فطرانہ ادا کرنے کا پرمسرت دن۔"
        ),
        IslamicOccasion(
            id: "day_of_arafah",
            hijriMonth: 12,
            hijriDay: 9,
            titleAr: "يوم عرفة",
            titleEn: "Day of Arafah",
            titleTr: "Arefe Günü",
            titleUr: "یومِ عرفہ",
            descriptionAr: "أعظم أيام السنة، ركن الحج الأعظم، وصيامه لغير الحاج يكفر ذنوب سنتين.",
            descriptionEn: "The pinnacle day of the Hajj pilgrimage. Fasting on this day for non-pilgrims expiates sins for two full years.",
            descriptionTr: "Haccın en önemli rüknü olan vakfenin yapıldığı gün; hacda olmayanlar için orucu iki yıllık günaha kefarettir.",
            descriptionUr: "حج کا عظیم ترین رکن اور سال کا افضل ترین دن، غیر حاجیوں کے لیے اس کا روزہ دو سال کے گناہوں کا کفارہ ہے۔"
        ),
        IslamicOccasion(
            id: "eid_al_adha",
            hijriMonth: 12,
            hijriDay: 10,
            titleAr: "عيد الأضحى المبارك",
            titleEn: "Eid al-Adha",
            titleTr: "Kurban Bayramı",
            titleUr: "عید الاضحیٰ",
            descriptionAr: "عيد النحر الأكبر، وإحياء سنة إبراهيم وإسماعيل عليهما السلام بالأضاحي والتكبير.",
            descriptionEn: "The Feast of Sacrifice honoring Prophet Ibrahim's (AS) devotion, marked by animal sacrifice and community feasts.",
            descriptionTr: "Hz. İbrahim ve Hz. İsmail'in teslimiyetinin hatırası olan kurban ibadeti ve tekbirlerle kutlanan bayram.",
            descriptionUr: "حضرت ابراہیم اور حضرت اسماعیل علیہما السلام کی تسلیم و رضا کی یاد اور قربانی کا عظیم تہوار۔"
        )
    ]

    public static func on(month: Int, day: Int) -> IslamicOccasion? {
        all.first { $0.hijriMonth == month && $0.hijriDay == day }
    }

    public static func isWhiteDay(month: Int, day: Int) -> Bool {
        (13...15).contains(day) && month != 9 && !(month == 12 && day == 13)
    }

    public static func isFastingForbidden(month: Int, day: Int) -> Bool {
        (month == 10 && day == 1) || (month == 12 && (10...13).contains(day))
    }

    public static func next(_ occasion: IslamicOccasion, from today: CivilDate, calendar: SirajHijriCalendar) -> DatedOccasion {
        var year = calendar.toHijri(today).year
        var date = calendar.toGregorian(year: year, month: occasion.hijriMonth, day: occasion.hijriDay)
        if date < today {
            year += 1
            date = calendar.toGregorian(year: year, month: occasion.hijriMonth, day: occasion.hijriDay)
        }
        return DatedOccasion(occasion: occasion, date: date, hijriYear: year, daysUntil: date.dayNumber - today.dayNumber)
    }

    public static func upcoming(from today: CivilDate, calendar: SirajHijriCalendar) -> [DatedOccasion] {
        all.map { next($0, from: today, calendar: calendar) }
            .sorted { $0.daysUntil < $1.daysUntil }
    }
}
