import Foundation

public struct Coordinates: Sendable, Hashable, Codable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public enum Madhab: String, CaseIterable, Codable, Sendable {
    case shafi = "Shafi"
    case hanafi = "Hanafi"
}

public enum HighLatitudeRule: String, CaseIterable, Codable, Sendable {
    case middleOfTheNight = "MiddleOfTheNight"
    case seventhOfTheNight = "SeventhOfTheNight"
    case twilightAngle = "TwilightAngle"
}

public enum AdhanCalculationMethod: String, CaseIterable, Sendable {
    case muslimWorldLeague
    case egyptian
    case karachi
    case ummAlQura
    case dubai
    case moonSightingCommittee
    case northAmerica
    case kuwait
    case qatar
    case singapore
    case other
}

public struct PrayerAdjustments: Sendable, Equatable {
    public var fajr: Int
    public var sunrise: Int
    public var dhuhr: Int
    public var asr: Int
    public var maghrib: Int
    public var isha: Int

    public init(fajr: Int = 0, sunrise: Int = 0, dhuhr: Int = 0, asr: Int = 0, maghrib: Int = 0, isha: Int = 0) {
        self.fajr = fajr
        self.sunrise = sunrise
        self.dhuhr = dhuhr
        self.asr = asr
        self.maghrib = maghrib
        self.isha = isha
    }
}

public struct CalculationParameters: Sendable, Equatable {
    public var method: AdhanCalculationMethod
    public var fajrAngle: Double
    public var ishaAngle: Double
    public var ishaInterval: Int
    public var madhab: Madhab
    public var highLatitudeRule: HighLatitudeRule
    public var adjustments: PrayerAdjustments
    public var methodAdjustments: PrayerAdjustments

    public init(
        fajrAngle: Double,
        ishaAngle: Double,
        method: AdhanCalculationMethod = .other,
        ishaInterval: Int = 0,
        madhab: Madhab = .shafi,
        highLatitudeRule: HighLatitudeRule = .middleOfTheNight,
        adjustments: PrayerAdjustments = PrayerAdjustments(),
        methodAdjustments: PrayerAdjustments = PrayerAdjustments()
    ) {
        self.method = method
        self.fajrAngle = fajrAngle
        self.ishaAngle = ishaAngle
        self.ishaInterval = ishaInterval
        self.madhab = madhab
        self.highLatitudeRule = highLatitudeRule
        self.adjustments = adjustments
        self.methodAdjustments = methodAdjustments
    }

    public static func withInterval(fajrAngle: Double, ishaInterval: Int, method: AdhanCalculationMethod) -> CalculationParameters {
        CalculationParameters(fajrAngle: fajrAngle, ishaAngle: 0.0, method: method, ishaInterval: ishaInterval)
    }

    public func nightPortions() -> (fajr: Double, isha: Double) {
        switch highLatitudeRule {
        case .middleOfTheNight: return (0.5, 0.5)
        case .seventhOfTheNight: return (1.0 / 7.0, 1.0 / 7.0)
        case .twilightAngle: return (fajrAngle / 60.0, ishaAngle / 60.0)
        }
    }

    public static func `for`(_ method: AdhanCalculationMethod) -> CalculationParameters {
        switch method {
        case .muslimWorldLeague:
            return CalculationParameters(fajrAngle: 18.0, ishaAngle: 17.0, method: method, methodAdjustments: PrayerAdjustments(dhuhr: 1))
        case .egyptian:
            return CalculationParameters(fajrAngle: 19.5, ishaAngle: 17.5, method: method, methodAdjustments: PrayerAdjustments(dhuhr: 1))
        case .karachi:
            return CalculationParameters(fajrAngle: 18.0, ishaAngle: 18.0, method: method, methodAdjustments: PrayerAdjustments(dhuhr: 1))
        case .ummAlQura:
            return withInterval(fajrAngle: 18.5, ishaInterval: 90, method: method)
        case .dubai:
            return CalculationParameters(fajrAngle: 18.2, ishaAngle: 18.2, method: method, methodAdjustments: PrayerAdjustments(sunrise: -3, dhuhr: 3, asr: 3, maghrib: 3))
        case .moonSightingCommittee:
            return CalculationParameters(fajrAngle: 18.0, ishaAngle: 18.0, method: method, methodAdjustments: PrayerAdjustments(dhuhr: 5, maghrib: 3))
        case .northAmerica:
            return CalculationParameters(fajrAngle: 15.0, ishaAngle: 15.0, method: method, methodAdjustments: PrayerAdjustments(dhuhr: 1))
        case .kuwait:
            return CalculationParameters(fajrAngle: 18.0, ishaAngle: 17.5, method: method)
        case .qatar:
            return withInterval(fajrAngle: 18.0, ishaInterval: 90, method: method)
        case .singapore:
            return CalculationParameters(fajrAngle: 20.0, ishaAngle: 18.0, method: method, methodAdjustments: PrayerAdjustments(dhuhr: 1))
        case .other:
            return CalculationParameters(fajrAngle: 0.0, ishaAngle: 0.0, method: .other)
        }
    }
}

/// Raw UTC instants for the day's six prayer markers. Nil when the sun never rises or sets.
public struct AdhanPrayerTimes: Sendable, Equatable {
    public let fajr: Date?
    public let sunrise: Date?
    public let dhuhr: Date?
    public let asr: Date?
    public let maghrib: Date?
    public let isha: Date?

    public init(coordinates: Coordinates, date: CivilDate, parameters: CalculationParameters) {
        let dayOfYear = date.dayOfYear
        let tomorrow = date.addingDays(1)

        let solarTime = SolarTime(today: date, coordinates: coordinates)
        let transit = Self.atTime(solarTime.transit, date: date)
        let sunriseComponents = Self.atTime(solarTime.sunrise, date: date)
        let sunsetComponents = Self.atTime(solarTime.sunset, date: date)
        let tomorrowSolarTime = SolarTime(today: tomorrow, coordinates: coordinates)
        let tomorrowSunrise = Self.atTime(tomorrowSolarTime.sunrise, date: tomorrow)

        guard let transit, let sunriseComponents, let sunsetComponents, let tomorrowSunrise else {
            self.fajr = nil; self.sunrise = nil; self.dhuhr = nil; self.asr = nil; self.maghrib = nil; self.isha = nil
            return
        }

        let tempDhuhr = transit
        let tempSunrise = sunriseComponents
        let tempMaghrib = sunsetComponents

        guard let tempAsr = Self.atTime(solarTime.afternoon(shadowLength: parameters.madhab == .hanafi ? 2.0 : 1.0), date: date) else {
            self.fajr = nil; self.sunrise = nil; self.dhuhr = nil; self.asr = nil; self.maghrib = nil; self.isha = nil
            return
        }

        let nightMs = Int64((tomorrowSunrise.timeIntervalSince(sunsetComponents)) * 1000.0)

        var tempFajr = Self.atTime(solarTime.hourAngle(-parameters.fajrAngle, afterTransit: false), date: date)
        if parameters.method == .moonSightingCommittee && coordinates.latitude >= 55.0 {
            tempFajr = sunriseComponents.addingTimeInterval(TimeInterval(-1 * Int(nightMs / 7000)))
        }

        let portions = parameters.nightPortions()
        let safeFajr: Date
        if parameters.method == .moonSightingCommittee {
            safeFajr = Self.seasonAdjustedMorningTwilight(latitude: coordinates.latitude, day: dayOfYear, year: date.year, sunrise: sunriseComponents)
        } else {
            let nightFraction = Int(Int64(portions.fajr * Double(nightMs) / 1000.0))
            safeFajr = sunriseComponents.addingTimeInterval(TimeInterval(-nightFraction))
        }
        if tempFajr == nil || tempFajr! < safeFajr {
            tempFajr = safeFajr
        }

        var tempIsha: Date?
        if parameters.ishaInterval > 0 {
            tempIsha = tempMaghrib.addingTimeInterval(TimeInterval(parameters.ishaInterval * 60))
        } else {
            tempIsha = Self.atTime(solarTime.hourAngle(-parameters.ishaAngle, afterTransit: true), date: date)
            if parameters.method == .moonSightingCommittee && coordinates.latitude >= 55.0 {
                tempIsha = sunsetComponents.addingTimeInterval(TimeInterval(Int(nightMs / 7000)))
            }

            let safeIsha: Date
            if parameters.method == .moonSightingCommittee {
                safeIsha = Self.seasonAdjustedEveningTwilight(latitude: coordinates.latitude, day: dayOfYear, year: date.year, sunset: sunsetComponents)
            } else {
                let nightFraction = Int(Int64(portions.isha * Double(nightMs) / 1000.0))
                safeIsha = sunsetComponents.addingTimeInterval(TimeInterval(nightFraction))
            }
            if tempIsha == nil || tempIsha! > safeIsha {
                tempIsha = safeIsha
            }
        }

        let a = parameters.adjustments
        let m = parameters.methodAdjustments
        self.fajr = Self.finalTime(tempFajr!, adjustment: a.fajr, methodAdjustment: m.fajr)
        self.sunrise = Self.finalTime(tempSunrise, adjustment: a.sunrise, methodAdjustment: m.sunrise)
        self.dhuhr = Self.finalTime(tempDhuhr, adjustment: a.dhuhr, methodAdjustment: m.dhuhr)
        self.asr = Self.finalTime(tempAsr, adjustment: a.asr, methodAdjustment: m.asr)
        self.maghrib = Self.finalTime(tempMaghrib, adjustment: a.maghrib, methodAdjustment: m.maghrib)
        self.isha = Self.finalTime(tempIsha!, adjustment: a.isha, methodAdjustment: m.isha)
    }

    private static func finalTime(_ time: Date, adjustment: Int, methodAdjustment: Int) -> Date {
        let shifted = time.addingTimeInterval(TimeInterval((adjustment + methodAdjustment) * 60))
        return roundedMinute(shifted)
    }

    static func roundedMinute(_ when: Date) -> Date {
        let totalSeconds = Int64(floor(when.timeIntervalSince1970))
        let rem = ((totalSeconds % 60) + 60) % 60
        let minuteFloor = totalSeconds - rem
        let rounded = rem >= 30 ? minuteFloor + 60 : minuteFloor
        return Date(timeIntervalSince1970: TimeInterval(rounded))
    }

    static func atTime(_ value: Double, date: CivilDate) -> Date? {
        if value.isInfinite || value.isNaN { return nil }
        let hours = floor(value)
        let minutes = floor((value - hours) * 60.0)
        let seconds = floor((value - (hours + minutes / 60.0)) * 3600.0)
        let offsetSeconds = Int(hours) * 3600 + Int(minutes) * 60 + Int(seconds)
        return date.utcMidnight.addingTimeInterval(TimeInterval(offsetSeconds))
    }

    private static func seasonAdjustedMorningTwilight(latitude: Double, day: Int, year: Int, sunrise: Date) -> Date {
        let a = 75.0 + 28.65 / 55.0 * abs(latitude)
        let b = 75.0 + 19.44 / 55.0 * abs(latitude)
        let c = 75.0 + 32.74 / 55.0 * abs(latitude)
        let d = 75.0 + 48.10 / 55.0 * abs(latitude)
        let adj = seasonCurve(a: a, b: b, c: c, d: d, dyy: daysSinceSolstice(dayOfYear: day, year: year, latitude: latitude))
        return sunrise.addingTimeInterval(TimeInterval(-Int(DoubleUtil.javaRound(adj * 60.0))))
    }

    private static func seasonAdjustedEveningTwilight(latitude: Double, day: Int, year: Int, sunset: Date) -> Date {
        let a = 75.0 + 25.60 / 55.0 * abs(latitude)
        let b = 75.0 + 2.050 / 55.0 * abs(latitude)
        let c = 75.0 - 9.210 / 55.0 * abs(latitude)
        let d = 75.0 + 6.140 / 55.0 * abs(latitude)
        let adj = seasonCurve(a: a, b: b, c: c, d: d, dyy: daysSinceSolstice(dayOfYear: day, year: year, latitude: latitude))
        return sunset.addingTimeInterval(TimeInterval(Int(DoubleUtil.javaRound(adj * 60.0))))
    }

    private static func seasonCurve(a: Double, b: Double, c: Double, d: Double, dyy: Int) -> Double {
        if dyy < 91 { return a + (b - a) / 91.0 * Double(dyy) }
        if dyy < 137 { return b + (c - b) / 46.0 * Double(dyy - 91) }
        if dyy < 183 { return c + (d - c) / 46.0 * Double(dyy - 137) }
        if dyy < 229 { return d + (c - d) / 46.0 * Double(dyy - 183) }
        if dyy < 275 { return c + (b - c) / 46.0 * Double(dyy - 229) }
        return b + (a - b) / 91.0 * Double(dyy - 275)
    }

    static func daysSinceSolstice(dayOfYear: Int, year: Int, latitude: Double) -> Int {
        let isLeap = CivilDate.isLeapYear(year)
        let northernOffset = 10
        let southernOffset = isLeap ? 173 : 172
        let daysInYear = isLeap ? 366 : 365
        var days: Int
        if latitude >= 0 {
            days = dayOfYear + northernOffset
            if days >= daysInYear { days -= daysInYear }
        } else {
            days = dayOfYear - southernOffset
            if days < 0 { days += daysInYear }
        }
        return days
    }
}
