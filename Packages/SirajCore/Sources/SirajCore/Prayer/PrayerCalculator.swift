import Foundation

public enum PrayerType: String, CaseIterable, Codable, Sendable, Identifiable {
    case fajr = "FAJR"
    case sunrise = "SUNRISE"
    case dhuhr = "DHUHR"
    case asr = "ASR"
    case maghrib = "MAGHRIB"
    case isha = "ISHA"

    public var id: String { rawValue }

    public var lowercaseKey: String { rawValue.lowercased() }

    public var defaultIqamaMinutes: Int {
        switch self {
        case .fajr: return 25
        case .dhuhr, .asr, .isha: return 20
        case .maghrib: return 10
        case .sunrise: return 0
        }
    }

    public var stringKey: String {
        switch self {
        case .fajr: return "prayer_fajr"
        case .sunrise: return "prayer_sunrise"
        case .dhuhr: return "prayer_dhuhr"
        case .asr: return "prayer_asr"
        case .maghrib: return "prayer_maghrib"
        case .isha: return "prayer_isha"
        }
    }

    public var iconAssetName: String {
        switch self {
        case .fajr: return "widget_sun_fajr"
        case .sunrise: return "widget_sun_sunrise"
        case .dhuhr: return "widget_sun_dhuhr"
        case .asr: return "widget_sun_asr"
        case .maghrib: return "widget_sun_maghrib"
        case .isha: return "widget_sun_isha"
        }
    }
}

public struct PrayerTimeEntry: Sendable, Equatable, Identifiable {
    public var id: PrayerType { type }
    public let type: PrayerType
    public let time: Date
    public let isNext: Bool
    public let iqama: Date?

    public init(type: PrayerType, time: Date, isNext: Bool = false, iqama: Date? = nil) {
        self.type = type
        self.time = time
        self.isNext = isNext
        self.iqama = iqama
    }

    public var windowEnd: Date {
        let base = iqama ?? time.addingTimeInterval(20 * 60)
        return base.addingTimeInterval(15 * 60)
    }

    public func withIsNext(_ next: Bool) -> PrayerTimeEntry {
        PrayerTimeEntry(type: type, time: time, isNext: next, iqama: iqama)
    }
}

public struct PrayerDay: Sendable, Equatable {
    public let date: CivilDate
    public let entries: [PrayerTimeEntry]
    public let place: Place

    public init(date: CivilDate, entries: [PrayerTimeEntry], place: Place) {
        self.date = date
        self.entries = entries
        self.place = place
    }

    public subscript(type: PrayerType) -> PrayerTimeEntry {
        entries.first { $0.type == type } ?? entries[0]
    }

    public var next: PrayerTimeEntry? {
        entries.first { $0.isNext }
    }
}

public struct CalculationSettings: Codable, Sendable, Equatable {
    public var method: String
    public var madhab: String
    public var highLatitudeRule: String
    public var minuteOffsets: [String: Int]
    public var iqamaOffsets: [String: Int]

    public init(
        method: String = "MuslimWorldLeague",
        madhab: String = "Shafi",
        highLatitudeRule: String = "MiddleOfTheNight",
        minuteOffsets: [String: Int] = ["FAJR": 0, "DHUHR": 0, "ASR": 0, "MAGHRIB": 0, "ISHA": 0],
        iqamaOffsets: [String: Int] = [:]
    ) {
        self.method = CalculationMethods.canonicalId(method)
        self.madhab = madhab
        self.highLatitudeRule = highLatitudeRule
        self.minuteOffsets = minuteOffsets
        self.iqamaOffsets = iqamaOffsets
    }
}

public enum PrayerCalculator {
    public static func parameters(for settings: CalculationSettings) -> CalculationParameters {
        var params: CalculationParameters
        switch settings.method {
        case "MWL", "MuslimWorldLeague":
            params = CalculationParameters.for(.muslimWorldLeague)
        case "ISNA", "NorthAmerica":
            params = CalculationParameters.for(.northAmerica)
        case "Egypt", "Egyptian":
            params = CalculationParameters.for(.egyptian)
        case "Karachi":
            params = CalculationParameters.for(.karachi)
        case "UmmAlQura":
            params = CalculationParameters.for(.ummAlQura)
        case "Dubai":
            params = CalculationParameters.for(.dubai)
        case "Moonsighting", "MoonsightingCommittee":
            params = CalculationParameters.for(.moonSightingCommittee)
        case "Singapore":
            params = CalculationParameters.for(.singapore)
        case "Kuwait":
            params = CalculationParameters.for(.kuwait)
        case "Qatar":
            params = CalculationParameters.for(.qatar)
        case "Other":
            params = CalculationParameters.for(.other)
        case "Turkey", "Diyanet":
            params = CalculationParameters(
                fajrAngle: 18.0, ishaAngle: 17.0, method: .other,
                methodAdjustments: PrayerAdjustments(sunrise: -7, dhuhr: 5, asr: 4, maghrib: 7)
            )
        case "Tehran":
            params = CalculationParameters(fajrAngle: 17.7, ishaAngle: 14.0, method: .other)
        default:
            params = CalculationParameters.for(.muslimWorldLeague)
        }

        params.madhab = settings.madhab == "Hanafi" ? .hanafi : .shafi
        switch settings.highLatitudeRule {
        case "SeventhOfTheNight": params.highLatitudeRule = .seventhOfTheNight
        case "TwilightAngle", "AngleBased": params.highLatitudeRule = .twilightAngle
        default: params.highLatitudeRule = .middleOfTheNight
        }

        for (key, offset) in settings.minuteOffsets {
            switch key.uppercased() {
            case "FAJR": params.adjustments.fajr = offset
            case "SUNRISE": params.adjustments.sunrise = offset
            case "DHUHR": params.adjustments.dhuhr = offset
            case "ASR": params.adjustments.asr = offset
            case "MAGHRIB": params.adjustments.maghrib = offset
            case "ISHA": params.adjustments.isha = offset
            default: break
            }
        }
        return params
    }

    public static func raw(place: Place, date: CivilDate, settings: CalculationSettings) -> [PrayerTimeEntry] {
        let params = parameters(for: settings)
        let times = AdhanPrayerTimes(
            coordinates: Coordinates(latitude: place.latitude, longitude: place.longitude),
            date: date,
            parameters: params
        )
        let zone = place.timeZone

        func make(_ type: PrayerType, _ utc: Date?, _ fallbackHour: Int) -> PrayerTimeEntry {
            let instant = utc ?? Zones.atLocal(date: date, hour: fallbackHour, minute: 0, timeZone: zone)
            let iqamaMins = settings.iqamaOffsets[type.rawValue] ?? type.defaultIqamaMinutes
            let iqamaDate = iqamaMins > 0 ? instant.addingTimeInterval(TimeInterval(iqamaMins * 60)) : nil
            return PrayerTimeEntry(type: type, time: instant, isNext: false, iqama: iqamaDate)
        }

        return [
            make(.fajr, times.fajr, 5),
            make(.sunrise, times.sunrise, 6),
            make(.dhuhr, times.dhuhr, 12),
            make(.asr, times.asr, 15),
            make(.maghrib, times.maghrib, 18),
            make(.isha, times.isha, 20)
        ]
    }

    public static func day(place: Place, date: CivilDate, settings: CalculationSettings, now: Date) -> PrayerDay {
        let entries = raw(place: place, date: date, settings: settings)
        var nextIndex: Int?
        for (idx, entry) in entries.enumerated() {
            let activeEnd = entry.type == .sunrise ? entry.time.addingTimeInterval(15 * 60) : entry.windowEnd
            if entry.time > now || now < activeEnd {
                nextIndex = idx
                break
            }
        }
        if let nextIndex {
            let marked = entries.enumerated().map { idx, entry in entry.withIsNext(idx == nextIndex) }
            return PrayerDay(date: date, entries: marked, place: place)
        }

        let tomorrowFajr = raw(place: place, date: date.addingDays(1), settings: settings)[0]
        let rolled = entries.map { entry in
            entry.type == .fajr ? tomorrowFajr.withIsNext(true) : entry.withIsNext(false)
        }
        return PrayerDay(date: date, entries: rolled, place: place)
    }

    public static func today(place: Place, settings: CalculationSettings, now: Date) -> PrayerDay {
        day(place: place, date: place.today(at: now), settings: settings, now: now)
    }

    public static func nextUpcoming(place: Place, settings: CalculationSettings, now: Date) -> PrayerTimeEntry {
        let todayDate = place.today(at: now)
        let entries = raw(place: place, date: todayDate, settings: settings)
        if let upcoming = entries.first(where: { $0.time > now }) {
            return upcoming.withIsNext(true)
        }
        return raw(place: place, date: todayDate.addingDays(1), settings: settings)[0].withIsNext(true)
    }
}
