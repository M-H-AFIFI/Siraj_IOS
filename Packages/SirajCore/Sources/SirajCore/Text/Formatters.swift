import Foundation

public enum DigitFormatter {
    private static let arabicDigits: [Character] = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]
    private static let urduDigits: [Character] = ["۰", "۱", "۲", "۳", "۴", "۵", "۶", "۷", "۸", "۹"]

    public static func useEastern(numeralSystem: String, lang: String, isQuran: Bool = false, quranException: Bool = true) -> Bool {
        if isQuran && quranException { return true }
        switch numeralSystem {
        case "Arabic": return true
        case "Western": return false
        default:
            let base = SirajLocalizer.baseLanguage(lang)
            return base == "ar" || base == "ur"
        }
    }

    public static func localizeDigits(
        _ input: String,
        numeralSystem: String,
        lang: String,
        isQuran: Bool = false,
        quranException: Bool = true
    ) -> String {
        let eastern = useEastern(numeralSystem: numeralSystem, lang: lang, isQuran: isQuran, quranException: quranException)
        return localizeDigits(input, eastern: eastern, lang: lang)
    }

    public static func localizeDigits(_ input: String, eastern: Bool, lang: String = "ar") -> String {
        guard eastern, !input.isEmpty else { return input }
        let table = SirajLocalizer.baseLanguage(lang) == "ur" ? urduDigits : arabicDigits
        var out = ""
        out.reserveCapacity(input.count)
        for ch in input {
            if let ascii = ch.asciiValue, ascii >= 48 && ascii <= 57 {
                out.append(table[Int(ascii - 48)])
            } else {
                out.append(ch)
            }
        }
        return out
    }

    public static func toWestern(_ input: String) -> String {
        var out = ""
        out.reserveCapacity(input.count)
        for ch in input {
            if let idx = arabicDigits.firstIndex(of: ch) {
                out.append(String(idx))
            } else if let idx = urduDigits.firstIndex(of: ch) {
                out.append(String(idx))
            } else {
                out.append(ch)
            }
        }
        return out
    }
}

public enum TimeFormatter {
    private static let nbsp = "\u{00A0}"

    public static func is24Hour(hourFormat: String, locale: Locale = .current) -> Bool {
        switch hourFormat {
        case "24", "24h": return true
        case "12", "12h": return false
        default:
            let format = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: locale) ?? ""
            return !format.contains("a")
        }
    }

    public static func amPm(isPM: Bool, lang: String) -> String {
        switch SirajLocalizer.baseLanguage(lang) {
        case "ar": return isPM ? "م" : "ص"
        case "ur": return isPM ? "شام" : "صبح"
        case "tr": return isPM ? "ÖS" : "ÖÖ"
        default: return isPM ? "PM" : "AM"
        }
    }

    public static func formatTime(
        hour: Int,
        minute: Int,
        hourFormat: String,
        numeralSystem: String,
        lang: String
    ) -> String {
        let eastern = DigitFormatter.useEastern(numeralSystem: numeralSystem, lang: lang)
        if is24Hour(hourFormat: hourFormat) {
            return DigitFormatter.localizeDigits(String(format: "%02d:%02d", hour, minute), eastern: eastern, lang: lang)
        }
        let hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        let body = DigitFormatter.localizeDigits(String(format: "%02d:%02d", hour12, minute), eastern: eastern, lang: lang)
        return body + nbsp + amPm(isPM: hour >= 12, lang: lang)
    }

    public static func formatTime(
        _ date: Date,
        timeZone: TimeZone,
        hourFormat: String,
        numeralSystem: String,
        lang: String
    ) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let comps = cal.dateComponents([.hour, .minute], from: date)
        return formatTime(hour: comps.hour ?? 0, minute: comps.minute ?? 0, hourFormat: hourFormat, numeralSystem: numeralSystem, lang: lang)
    }

    public static func formatCountdown(
        seconds: TimeInterval,
        withHours: Bool = true,
        numeralSystem: String,
        lang: String
    ) -> String {
        let total = max(0, Int(seconds))
        let raw: String
        if withHours {
            raw = String(format: "%02d:%02d:%02d", total / 3600, (total / 60) % 60, total % 60)
        } else {
            raw = String(format: "%02d:%02d", total / 60, total % 60)
        }
        let eastern = DigitFormatter.useEastern(numeralSystem: numeralSystem, lang: lang)
        return DigitFormatter.localizeDigits(raw, eastern: eastern, lang: lang)
    }
}

public enum HijriFormatter {
    private static let monthsAr = [
        "محرم", "صفر", "ربيع الأول", "ربيع الآخر", "جمادى الأولى", "جمادى الآخرة",
        "رجب", "شعبان", "رمضان", "شوال", "ذو القعدة", "ذو الحجة"
    ]
    private static let monthsEn = [
        "Muharram", "Safar", "Rabi' al-Awwal", "Rabi' al-Thani", "Jumada al-Ula", "Jumada al-Akhirah",
        "Rajab", "Sha'ban", "Ramadan", "Shawwal", "Dhu al-Qi'dah", "Dhu al-Hijjah"
    ]
    private static let monthsTr = [
        "Muharrem", "Safer", "Rebiülevvel", "Rebiülahir", "Cemaziyelevvel", "Cemaziyelahir",
        "Recep", "Şaban", "Ramazan", "Şevval", "Zilkade", "Zilhicce"
    ]

    public static func monthName(_ month: Int, lang: String) -> String {
        let base = SirajLocalizer.baseLanguage(lang)
        let idx = min(max(month, 1), 12) - 1
        switch base {
        case "ar", "ur": return monthsAr[idx]
        case "tr": return monthsTr[idx]
        default: return monthsEn[idx]
        }
    }

    public static func yearString(_ year: Int, lang: String, numeralSystem: String) -> String {
        let base = SirajLocalizer.baseLanguage(lang)
        let y = DigitFormatter.localizeDigits(String(year), numeralSystem: numeralSystem, lang: base)
        switch base {
        case "ar": return "\(y) هـ"
        case "ur": return "\(y) ھ"
        case "tr": return y
        default: return "\(y) AH"
        }
    }

    public static func format(_ hijri: HijriDate, lang: String, numeralSystem: String) -> String {
        let d = DigitFormatter.localizeDigits(String(hijri.day), numeralSystem: numeralSystem, lang: lang)
        return "\(d) \(monthName(hijri.month, lang: lang)) \(yearString(hijri.year, lang: lang, numeralSystem: numeralSystem))"
    }

    private static let gregorianLock = NSLock()
    private static var gregorianFormatters: [String: DateFormatter] = [:]

    public static func formatGregorian(_ date: CivilDate, lang: String, numeralSystem: String) -> String {
        formatGregorianCached(date, lang: lang, numeralSystem: numeralSystem, compact: false)
    }

    public static func formatGregorianCompact(_ date: CivilDate, lang: String, numeralSystem: String) -> String {
        formatGregorianCached(date, lang: lang, numeralSystem: numeralSystem, compact: true)
    }

    private static func formatGregorianCached(_ date: CivilDate, lang: String, numeralSystem: String, compact: Bool) -> String {
        let base = SirajLocalizer.baseLanguage(lang)
        let cacheKey = "\(base)_\(compact ? "c" : "f")"
        let text: String = {
            gregorianLock.lock()
            defer { gregorianLock.unlock() }
            let df: DateFormatter
            if let cached = gregorianFormatters[cacheKey] {
                df = cached
            } else {
                df = DateFormatter()
                df.calendar = Calendar(identifier: .gregorian)
                df.timeZone = TimeZone(secondsFromGMT: 0)
                switch base {
                case "ar":
                    df.locale = Locale(identifier: "ar_EG")
                    df.dateFormat = compact ? "d MMMM yyyy" : "EEEE، d MMMM yyyy"
                case "tr":
                    df.locale = Locale(identifier: "tr_TR")
                    df.dateFormat = compact ? "d MMMM yyyy" : "EEEE, d MMMM yyyy"
                case "ur":
                    df.locale = Locale(identifier: "ur_PK")
                    df.dateFormat = compact ? "d MMMM yyyy" : "EEEE، d MMMM yyyy"
                default:
                    df.locale = Locale(identifier: "en_US")
                    df.dateFormat = compact ? "MMM d, yyyy" : "EEEE, MMMM d, yyyy"
                }
                gregorianFormatters[cacheKey] = df
            }
            return df.string(from: date.utcMidnight)
        }()
        let eastern = DigitFormatter.useEastern(numeralSystem: numeralSystem, lang: base)
        return DigitFormatter.localizeDigits(DigitFormatter.toWestern(text), eastern: eastern, lang: base)
    }
}
