import Foundation

public struct IslamicOccasion: Sendable, Equatable, Identifiable {
    public let id: String
    public let hijriMonth: Int
    public let hijriDay: Int
    public let titleAr: String
    public let titleEn: String
    public let titleTr: String
    public let titleUr: String

    public func title(language: String) -> String {
        switch language.prefix(2).lowercased() {
        case "ar": return titleAr
        case "ur": return titleUr
        case "tr": return titleTr
        default: return titleEn
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
}

public enum IslamicOccasions {
    public static let all: [IslamicOccasion] = [
        IslamicOccasion(id: "islamic_new_year", hijriMonth: 1, hijriDay: 1, titleAr: "رأس السنة الهجرية", titleEn: "Islamic New Year", titleTr: "Hicri Yılbaşı", titleUr: "نیا اسلامی سال"),
        IslamicOccasion(id: "ashura", hijriMonth: 1, hijriDay: 10, titleAr: "يوم عاشوراء", titleEn: "Day of Ashura", titleTr: "Aşure Günü", titleUr: "یومِ عاشورہ"),
        IslamicOccasion(id: "isra_miraj", hijriMonth: 7, hijriDay: 27, titleAr: "الإسراء والمعراج", titleEn: "Al-Isra' wal-Mi'raj", titleTr: "Miraç Kandili", titleUr: "اسراء و معراج"),
        IslamicOccasion(id: "mid_shaban", hijriMonth: 8, hijriDay: 15, titleAr: "ليلة النصف من شعبان", titleEn: "Mid-Sha'ban", titleTr: "Berat Kandili", titleUr: "شبِ برات"),
        IslamicOccasion(id: "ramadan_start", hijriMonth: 9, hijriDay: 1, titleAr: "أول أيام شهر رمضان", titleEn: "First Day of Ramadan", titleTr: "Ramazan-ı Şerif'in Başlangıcı", titleUr: "رمضان المبارک کا آغاز"),
        IslamicOccasion(id: "last_ten_ramadan", hijriMonth: 9, hijriDay: 21, titleAr: "العشر الأواخر من رمضان", titleEn: "Last Ten Days of Ramadan", titleTr: "Ramazan'ın Son On Günü", titleUr: "رمضان کے آخری دس دن"),
        IslamicOccasion(id: "eid_al_fitr", hijriMonth: 10, hijriDay: 1, titleAr: "عيد الفطر المبارك", titleEn: "Eid al-Fitr", titleTr: "Ramazan Bayramı", titleUr: "عید الفطر"),
        IslamicOccasion(id: "day_of_arafah", hijriMonth: 12, hijriDay: 9, titleAr: "يوم عرفة", titleEn: "Day of Arafah", titleTr: "Arefe Günü", titleUr: "یومِ عرفہ"),
        IslamicOccasion(id: "eid_al_adha", hijriMonth: 12, hijriDay: 10, titleAr: "عيد الأضحى المبارك", titleEn: "Eid al-Adha", titleTr: "Kurban Bayramı", titleUr: "عید الاضحیٰ")
    ]

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
