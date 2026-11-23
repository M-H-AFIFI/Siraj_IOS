import Foundation

/// A timezone-free proleptic Gregorian calendar date.
public struct CivilDate: Sendable, Hashable, Comparable, Codable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int

    /// Days from 0001-01-01 to 1970-01-01.
    public static let unixEpochDayNumber = 719_162

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// Days since 0001-01-01 (0001-01-01 is 0), matching JDK/UmmAlQura table indices.
    public var dayNumber: Int {
        Self.daysFromCivil(year: year, month: month, day: day) + Self.unixEpochDayNumber
    }

    public init(dayNumber: Int) {
        let (y, m, d) = Self.civilFromDays(dayNumber - Self.unixEpochDayNumber)
        self.year = y
        self.month = m
        self.day = d
    }

    public init?(isoString: String) {
        let parts = isoString.split(separator: "-")
        guard parts.count == 3,
              let y = Int(parts[0]),
              let m = Int(parts[1]),
              let d = Int(parts[2]) else {
            return nil
        }
        self.init(year: y, month: m, day: d)
    }

    public var isLeapYear: Bool {
        Self.isLeapYear(year)
    }

    public static func isLeapYear(_ year: Int) -> Bool {
        (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
    }

    public var dayOfYear: Int {
        let start = CivilDate(year: year, month: 1, day: 1).dayNumber
        return (dayNumber - start) + 1
    }

    /// 0 = Sunday, 1 = Monday, ..., 6 = Saturday.
    public var weekdaySundayZero: Int {
        let z = dayNumber - Self.unixEpochDayNumber
        let raw = (z + 4) % 7
        return raw >= 0 ? raw : raw + 7
    }

    public func addingDays(_ days: Int) -> CivilDate {
        CivilDate(dayNumber: dayNumber + days)
    }

    public var utcMidnight: Date {
        Date(timeIntervalSince1970: TimeInterval((dayNumber - Self.unixEpochDayNumber) * 86_400))
    }

    public var isoString: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    public var description: String { isoString }

    public static func < (lhs: CivilDate, rhs: CivilDate) -> Bool {
        lhs.dayNumber < rhs.dayNumber
    }

    public static func from(date: Date, timeZone: TimeZone) -> CivilDate {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        return CivilDate(year: comps.year ?? 2000, month: comps.month ?? 1, day: comps.day ?? 1)
    }

    // Howard Hinnant's civil date algorithms (days relative to 1970-01-01).
    private static func daysFromCivil(year y0: Int, month m: Int, day d: Int) -> Int {
        let y = y0 - (m <= 2 ? 1 : 0)
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let doy = (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era * 146_097 + doe - 719_468
    }

    private static func civilFromDays(_ z0: Int) -> (Int, Int, Int) {
        let z = z0 + 719_468
        let era = (z >= 0 ? z : z - 146_096) / 146_097
        let doe = z - era * 146_097
        let yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365
        let y = yoe + era * 400
        let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
        let mp = (5 * doy + 2) / 153
        let d = doy - (153 * mp + 2) / 5 + 1
        let m = mp + (mp < 10 ? 3 : -9)
        return (y + (m <= 2 ? 1 : 0), m, d)
    }
}

// Port of batoulapps Adhan 1.2.1 astronomical math (Jean Meeus, Astronomical Algorithms).

enum DoubleUtil {
    static func normalizeWithBound(_ value: Double, max: Double) -> Double {
        value - max * floor(value / max)
    }

    static func unwindAngle(_ value: Double) -> Double {
        normalizeWithBound(value, max: 360.0)
    }

    static func closestAngle(_ angle: Double) -> Double {
        if angle >= -180.0 && angle <= 180.0 { return angle }
        return angle - 360.0 * Double(javaRound(angle / 360.0))
    }

    static func javaRound(_ value: Double) -> Int64 {
        Int64(floor(value + 0.5))
    }

    static func toRadians(_ degrees: Double) -> Double {
        degrees * .pi / 180.0
    }

    static func toDegrees(_ radians: Double) -> Double {
        radians * 180.0 / .pi
    }
}

enum CalendricalHelper {
    static func julianDay(year: Int, month: Int, day: Int, hours: Double = 0.0) -> Double {
        let y = month > 2 ? year : year - 1
        let m = month > 2 ? month : month + 12
        let d = Double(day) + hours / 24.0
        let a = y / 100
        let b = 2 - a + a / 4
        let i0 = Int(365.25 * Double(y + 4716))
        let i1 = Int(30.6001 * Double(m + 1))
        return Double(i0) + Double(i1) + d + Double(b) - 1524.5
    }

    static func julianCentury(_ jd: Double) -> Double {
        (jd - 2_451_545.0) / 36_525.0
    }
}

enum Astronomical {
    static func meanSolarLongitude(_ t: Double) -> Double {
        let l0 = 280.4664567 + 36000.76983 * t + 0.0003032 * t * t
        return DoubleUtil.unwindAngle(l0)
    }

    static func meanLunarLongitude(_ t: Double) -> Double {
        let lp = 218.3165 + 481267.8813 * t
        return DoubleUtil.unwindAngle(lp)
    }

    static func apparentSolarLongitude(_ t: Double, _ l0: Double) -> Double {
        let longitude = l0 + solarEquationOfTheCenter(t, meanSolarAnomaly(t))
        let omega = 125.04 - 1934.136 * t
        let lambda = longitude - 0.00569 - 0.00478 * sin(DoubleUtil.toRadians(omega))
        return DoubleUtil.unwindAngle(lambda)
    }

    static func ascendingLunarNodeLongitude(_ t: Double) -> Double {
        let omega = 125.04452 - 1934.136261 * t + 0.0020708 * t * t + (t * t * t) / 450_000.0
        return DoubleUtil.unwindAngle(omega)
    }

    static func meanSolarAnomaly(_ t: Double) -> Double {
        let m = 357.52911 + 35999.05029 * t - 0.0001537 * t * t
        return DoubleUtil.unwindAngle(m)
    }

    static func solarEquationOfTheCenter(_ t: Double, _ m: Double) -> Double {
        let mrad = DoubleUtil.toRadians(m)
        let term1 = (1.914602 - 0.004817 * t - 0.000014 * t * t) * sin(mrad)
        let term2 = (0.019993 - 0.000101 * t) * sin(2.0 * mrad)
        let term3 = 0.000289 * sin(3.0 * mrad)
        return term1 + term2 + term3
    }

    static func meanObliquityOfTheEcliptic(_ t: Double) -> Double {
        23.439291 - 0.013004167 * t - 0.0000001639 * t * t + 0.0000005036 * t * t * t
    }

    static func apparentObliquityOfTheEcliptic(_ t: Double, _ epsilon0: Double) -> Double {
        let o = 125.04 - 1934.136 * t
        return epsilon0 + 0.00256 * cos(DoubleUtil.toRadians(o))
    }

    static func meanSiderealTime(_ t: Double) -> Double {
        let jd = t * 36_525.0 + 2_451_545.0
        let theta = 280.46061837 + 360.98564736629 * (jd - 2_451_545.0) + 0.000387933 * t * t - (t * t * t) / 38_710_000.0
        return DoubleUtil.unwindAngle(theta)
    }

    static func nutationInLongitude(_ t: Double, _ l0: Double, _ lp: Double, _ omega: Double) -> Double {
        let term1 = -17.2 / 3600.0 * sin(DoubleUtil.toRadians(omega))
        let term2 = 1.32 / 3600.0 * sin(2.0 * DoubleUtil.toRadians(l0))
        let term3 = 0.23 / 3600.0 * sin(2.0 * DoubleUtil.toRadians(lp))
        let term4 = 0.21 / 3600.0 * sin(2.0 * DoubleUtil.toRadians(omega))
        return term1 - term2 - term3 + term4
    }

    static func nutationInObliquity(_ t: Double, _ l0: Double, _ lp: Double, _ omega: Double) -> Double {
        let term1 = 9.2 / 3600.0 * cos(DoubleUtil.toRadians(omega))
        let term2 = 0.57 / 3600.0 * cos(2.0 * DoubleUtil.toRadians(l0))
        let term3 = 0.10 / 3600.0 * cos(2.0 * DoubleUtil.toRadians(lp))
        let term4 = 0.09 / 3600.0 * cos(2.0 * DoubleUtil.toRadians(omega))
        return term1 + term2 + term3 - term4
    }

    static func altitudeOfCelestialBody(phi: Double, delta: Double, h: Double) -> Double {
        let term1 = sin(DoubleUtil.toRadians(phi)) * sin(DoubleUtil.toRadians(delta))
        let term2 = cos(DoubleUtil.toRadians(phi)) * cos(DoubleUtil.toRadians(delta)) * cos(DoubleUtil.toRadians(h))
        return DoubleUtil.toDegrees(asin(term1 + term2))
    }

    static func approximateTransit(l: Double, theta0: Double, alpha2: Double) -> Double {
        let lw = l * -1.0
        return DoubleUtil.normalizeWithBound((alpha2 + lw - theta0) / 360.0, max: 1.0)
    }

    static func correctedTransit(
        m0: Double, l: Double, theta0: Double, alpha2: Double, alpha1: Double, alpha3: Double
    ) -> Double {
        let lw = l * -1.0
        let theta = DoubleUtil.unwindAngle(theta0 + 360.985647 * m0)
        let alpha = DoubleUtil.unwindAngle(interpolateAngles(y2: alpha2, y1: alpha1, y3: alpha3, n: m0))
        let h = DoubleUtil.closestAngle(theta - lw - alpha)
        let dm = h / -360.0
        return (m0 + dm) * 24.0
    }

    static func correctedHourAngle(
        m0: Double, h0: Double, coordinates: Coordinates, afterTransit: Bool,
        theta0: Double, alpha2: Double, alpha1: Double, alpha3: Double,
        delta2: Double, delta1: Double, delta3: Double
    ) -> Double {
        let lw = coordinates.longitude * -1.0
        let term1 = sin(DoubleUtil.toRadians(h0)) - sin(DoubleUtil.toRadians(coordinates.latitude)) * sin(DoubleUtil.toRadians(delta2))
        let term2 = cos(DoubleUtil.toRadians(coordinates.latitude)) * cos(DoubleUtil.toRadians(delta2))
        let bigH0 = DoubleUtil.toDegrees(acos(term1 / term2))
        let m = afterTransit ? m0 + bigH0 / 360.0 : m0 - bigH0 / 360.0
        let theta = DoubleUtil.unwindAngle(theta0 + 360.985647 * m)
        let alpha = DoubleUtil.unwindAngle(interpolateAngles(y2: alpha2, y1: alpha1, y3: alpha3, n: m))
        let delta = interpolate(y2: delta2, y1: delta1, y3: delta3, n: m)
        let hh = theta - lw - alpha
        let h = altitudeOfCelestialBody(phi: coordinates.latitude, delta: delta, h: hh)
        let term3 = h - h0
        let term4 = 360.0 * cos(DoubleUtil.toRadians(delta)) * cos(DoubleUtil.toRadians(coordinates.latitude)) * sin(DoubleUtil.toRadians(hh))
        let dm = term3 / term4
        return (m + dm) * 24.0
    }

    static func interpolate(y2: Double, y1: Double, y3: Double, n: Double) -> Double {
        let a = y2 - y1
        let b = y3 - y2
        let c = b - a
        return y2 + (n / 2.0) * (a + b + n * c)
    }

    static func interpolateAngles(y2: Double, y1: Double, y3: Double, n: Double) -> Double {
        let a = DoubleUtil.unwindAngle(y2 - y1)
        let b = DoubleUtil.unwindAngle(y3 - y2)
        let c = b - a
        return y2 + (n / 2.0) * (a + b + n * c)
    }
}

struct SolarCoordinates {
    let declination: Double
    let rightAscension: Double
    let apparentSiderealTime: Double

    init(julianDay: Double) {
        let t = CalendricalHelper.julianCentury(julianDay)
        let l0 = Astronomical.meanSolarLongitude(t)
        let lp = Astronomical.meanLunarLongitude(t)
        let omega = Astronomical.ascendingLunarNodeLongitude(t)
        let lambda = DoubleUtil.toRadians(Astronomical.apparentSolarLongitude(t, l0))
        let theta0 = Astronomical.meanSiderealTime(t)
        let dPsi = Astronomical.nutationInLongitude(t, l0, lp, omega)
        let dEpsilon = Astronomical.nutationInObliquity(t, l0, lp, omega)
        let epsilon0 = Astronomical.meanObliquityOfTheEcliptic(t)
        let epsilonApp = DoubleUtil.toRadians(Astronomical.apparentObliquityOfTheEcliptic(t, epsilon0))

        self.declination = DoubleUtil.toDegrees(asin(sin(epsilonApp) * sin(lambda)))
        self.rightAscension = DoubleUtil.unwindAngle(DoubleUtil.toDegrees(atan2(cos(epsilonApp) * sin(lambda), cos(lambda))))
        self.apparentSiderealTime = theta0 + dPsi * 3600.0 * cos(DoubleUtil.toRadians(epsilon0 + dEpsilon)) / 3600.0
    }
}

struct SolarTime {
    let transit: Double
    let sunrise: Double
    let sunset: Double

    private let observer: Coordinates
    private let solar: SolarCoordinates
    private let prevSolar: SolarCoordinates
    private let nextSolar: SolarCoordinates
    private let approximateTransit: Double

    init(today: CivilDate, coordinates: Coordinates) {
        let julianDate = CalendricalHelper.julianDay(year: today.year, month: today.month, day: today.day)
        let prev = SolarCoordinates(julianDay: julianDate - 1.0)
        let curr = SolarCoordinates(julianDay: julianDate)
        let next = SolarCoordinates(julianDay: julianDate + 1.0)
        let approx = Astronomical.approximateTransit(l: coordinates.longitude, theta0: curr.apparentSiderealTime, alpha2: curr.rightAscension)
        let solarAltitude = -50.0 / 60.0

        self.observer = coordinates
        self.prevSolar = prev
        self.solar = curr
        self.nextSolar = next
        self.approximateTransit = approx
        self.transit = Astronomical.correctedTransit(
            m0: approx, l: coordinates.longitude, theta0: curr.apparentSiderealTime,
            alpha2: curr.rightAscension, alpha1: prev.rightAscension, alpha3: next.rightAscension
        )
        self.sunrise = Astronomical.correctedHourAngle(
            m0: approx, h0: solarAltitude, coordinates: coordinates, afterTransit: false,
            theta0: curr.apparentSiderealTime, alpha2: curr.rightAscension, alpha1: prev.rightAscension, alpha3: next.rightAscension,
            delta2: curr.declination, delta1: prev.declination, delta3: next.declination
        )
        self.sunset = Astronomical.correctedHourAngle(
            m0: approx, h0: solarAltitude, coordinates: coordinates, afterTransit: true,
            theta0: curr.apparentSiderealTime, alpha2: curr.rightAscension, alpha1: prev.rightAscension, alpha3: next.rightAscension,
            delta2: curr.declination, delta1: prev.declination, delta3: next.declination
        )
    }

    func hourAngle(_ angle: Double, afterTransit: Bool) -> Double {
        Astronomical.correctedHourAngle(
            m0: approximateTransit, h0: angle, coordinates: observer, afterTransit: afterTransit,
            theta0: solar.apparentSiderealTime, alpha2: solar.rightAscension, alpha1: prevSolar.rightAscension, alpha3: nextSolar.rightAscension,
            delta2: solar.declination, delta1: prevSolar.declination, delta3: nextSolar.declination
        )
    }

    func afternoon(shadowLength: Double) -> Double {
        let tangent = abs(observer.latitude - solar.declination)
        let inverse = shadowLength + tan(DoubleUtil.toRadians(tangent))
        let angle = DoubleUtil.toDegrees(atan(1.0 / inverse))
        return hourAngle(angle, afterTransit: true)
    }
}
