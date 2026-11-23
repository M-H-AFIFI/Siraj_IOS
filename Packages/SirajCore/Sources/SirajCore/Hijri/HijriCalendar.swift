import Foundation

public enum HijriMethod: String, CaseIterable, Codable, Sendable {
    case ummAlQura
    case egypt
    case turkey
    case sighting
    case nakedEye
    case mabims
}

public struct HijriRegion: Sendable, Equatable, Hashable, Codable {
    public let countryCode: String?
    public let method: HijriMethod
    public let latitude: Double
    public let longitude: Double
    public let zoneId: String

    public init(countryCode: String?, method: HijriMethod, latitude: Double = 0.0, longitude: Double = 0.0, zoneId: String = "UTC") {
        self.countryCode = countryCode
        self.method = method
        self.latitude = latitude
        self.longitude = longitude
        self.zoneId = zoneId
    }

    public static let saudi = HijriRegion(countryCode: "SA", method: .ummAlQura)

    private static let byCountry: [String: HijriRegion] = [
        "EG": HijriRegion(countryCode: "EG", method: .egypt, latitude: 30.0444, longitude: 31.2357, zoneId: "Africa/Cairo"),
        "TR": HijriRegion(countryCode: "TR", method: .turkey),
        "JO": HijriRegion(countryCode: "JO", method: .sighting, latitude: 31.9539, longitude: 35.9106, zoneId: "Asia/Amman"),
        "AE": HijriRegion(countryCode: "AE", method: .sighting, latitude: 24.4539, longitude: 54.3773, zoneId: "Asia/Dubai"),
        "OM": HijriRegion(countryCode: "OM", method: .sighting, latitude: 23.5880, longitude: 58.3829, zoneId: "Asia/Muscat"),
        "IQ": HijriRegion(countryCode: "IQ", method: .sighting, latitude: 33.3152, longitude: 44.3661, zoneId: "Asia/Baghdad"),
        "SY": HijriRegion(countryCode: "SY", method: .sighting, latitude: 33.5138, longitude: 36.2765, zoneId: "Asia/Damascus"),
        "MA": HijriRegion(countryCode: "MA", method: .sighting, latitude: 34.0209, longitude: -6.8416, zoneId: "Africa/Casablanca"),
        "DZ": HijriRegion(countryCode: "DZ", method: .sighting, latitude: 36.7538, longitude: 3.0588, zoneId: "Africa/Algiers"),
        "TN": HijriRegion(countryCode: "TN", method: .sighting, latitude: 36.8065, longitude: 10.1815, zoneId: "Africa/Tunis"),
        "LY": HijriRegion(countryCode: "LY", method: .sighting, latitude: 32.8872, longitude: 13.1913, zoneId: "Africa/Tripoli"),
        "IR": HijriRegion(countryCode: "IR", method: .sighting, latitude: 35.6892, longitude: 51.3890, zoneId: "Asia/Tehran"),
        "PK": HijriRegion(countryCode: "PK", method: .nakedEye, latitude: 24.8607, longitude: 67.0011, zoneId: "Asia/Karachi"),
        "IN": HijriRegion(countryCode: "IN", method: .nakedEye, latitude: 28.6139, longitude: 77.2090, zoneId: "Asia/Kolkata"),
        "BD": HijriRegion(countryCode: "BD", method: .nakedEye, latitude: 23.8103, longitude: 90.4125, zoneId: "Asia/Dhaka"),
        "MY": HijriRegion(countryCode: "MY", method: .mabims, latitude: 6.1184, longitude: 100.3685, zoneId: "Asia/Kuala_Lumpur"),
        "ID": HijriRegion(countryCode: "ID", method: .mabims, latitude: 5.5483, longitude: 95.3238, zoneId: "Asia/Jakarta"),
        "BN": HijriRegion(countryCode: "BN", method: .mabims, latitude: 4.9031, longitude: 114.9398, zoneId: "Asia/Brunei"),
        "SG": HijriRegion(countryCode: "SG", method: .mabims, latitude: 1.3521, longitude: 103.8198, zoneId: "Asia/Singapore")
    ]

    public static func forCountry(_ countryCode: String?) -> HijriRegion {
        let code = countryCode?.uppercased()
        if let code, let found = byCountry[code] { return found }
        return HijriRegion(countryCode: code, method: .ummAlQura)
    }
}

public struct HijriDate: Sendable, Hashable, Comparable, Codable {
    public let year: Int
    public let month: Int
    public let day: Int
    public let lengthOfMonth: Int

    public init(year: Int, month: Int, day: Int, lengthOfMonth: Int) {
        self.year = year
        self.month = month
        self.day = day
        self.lengthOfMonth = lengthOfMonth
    }

    public static func < (lhs: HijriDate, rhs: HijriDate) -> Bool {
        if lhs.year != rhs.year { return lhs.year < rhs.year }
        if lhs.month != rhs.month { return lhs.month < rhs.month }
        return lhs.day < rhs.day
    }
}

public final class SirajHijriCalendar: @unchecked Sendable {
    private static let minYear = 1301
    private static let maxYear = 1599
    private static let chainMonths = 8

    private static let minDate = ummAlQuraFirst(year: minYear, month: 1)
    private static let maxDate = ummAlQuraFirst(year: maxYear, month: 12)

    public static let ummAlQura = SirajHijriCalendar(region: .saudi)

    public let region: HijriRegion
    public let adjustment: Int

    private let lock = NSLock()
    private var starts: [Int: CivilDate] = [:]
    private let timeZone: TimeZone

    public init(region: HijriRegion, adjustment: Int = 0) {
        self.region = region
        self.adjustment = adjustment
        self.timeZone = Zones.find(region.zoneId)
    }

    public static func forSettings(method: String, countryCode: String?, adjustment: Int) -> SirajHijriCalendar {
        let region: HijriRegion
        switch method.lowercased() {
        case "umm_al_qura", "ummalqura":
            region = .saudi
        case "egypt":
            region = .forCountry("EG")
        case "turkey", "diyanet":
            region = .forCountry("TR")
        case "mabims":
            region = .forCountry("MY")
        default:
            region = .forCountry(countryCode)
        }
        return SirajHijriCalendar(region: region, adjustment: adjustment)
    }

    public func toHijri(_ date: CivilDate) -> HijriDate {
        let shifted = date.addingDays(adjustment)
        let uq = Self.ummAlQuraDate(Self.clamp(shifted))
        if region.method == .ummAlQura { return uq }

        var index = Self.indexOf(year: uq.year, month: uq.month)
        while start(index) > shifted { index -= 1 }
        while start(index + 1) <= shifted { index += 1 }
        let first = start(index)
        let length = start(index + 1).dayNumber - first.dayNumber
        return HijriDate(year: Self.yearOf(index), month: Self.monthOf(index), day: shifted.dayNumber - first.dayNumber + 1, lengthOfMonth: length)
    }

    public func toGregorian(year: Int, month: Int, day: Int) -> CivilDate {
        let index = Self.indexOf(year: year, month: month)
        let length = lengthOfMonth(year: year, month: month)
        let clampedDay = min(max(day, 1), length)
        return start(index).addingDays(clampedDay - 1).addingDays(-adjustment)
    }

    public func firstDayOf(year: Int, month: Int) -> CivilDate {
        toGregorian(year: year, month: month, day: 1)
    }

    public func lengthOfMonth(year: Int, month: Int) -> Int {
        let index = Self.indexOf(year: year, month: month)
        return start(index + 1).dayNumber - start(index).dayNumber
    }

    private static func ummAlQuraFirst(year: Int, month: Int) -> CivilDate {
        CivilDate(dayNumber: UmmAlQuraTable.monthStarts[(year - UmmAlQuraTable.firstYear) * 12 + month - 1])
    }

    private static func ummAlQuraDate(_ date: CivilDate) -> HijriDate {
        let table = UmmAlQuraTable.monthStarts
        let target = date.dayNumber
        var lo = 0
        var hi = table.count - 1
        while lo <= hi {
            let mid = (lo + hi) / 2
            if table[mid] == target {
                lo = mid
                break
            } else if table[mid] < target {
                lo = mid + 1
            } else {
                hi = mid - 1
            }
        }
        var idx = (lo < table.count && table[lo] == target) ? lo : lo - 1
        idx = min(max(idx, 0), table.count - 2)
        return HijriDate(
            year: UmmAlQuraTable.firstYear + idx / 12,
            month: idx % 12 + 1,
            day: target - table[idx] + 1,
            lengthOfMonth: table[idx + 1] - table[idx]
        )
    }

    private static func indexOf(year: Int, month: Int) -> Int { year * 12 + (month - 1) }
    private static func yearOf(_ index: Int) -> Int { index / 12 }
    private static func monthOf(_ index: Int) -> Int { index % 12 + 1 }

    private static func ummAlQuraStart(_ index: Int) -> CivilDate {
        let y = min(max(yearOf(index), minYear), maxYear)
        return ummAlQuraFirst(year: y, month: monthOf(index))
    }

    private func start(_ index: Int) -> CivilDate {
        lock.lock()
        defer { lock.unlock() }
        if let cached = starts[index] { return cached }
        if region.method == .ummAlQura || Self.yearOf(index) <= Self.minYear || Self.yearOf(index) >= Self.maxYear {
            let value = Self.ummAlQuraStart(index)
            starts[index] = value
            return value
        }
        if region.method == .turkey {
            let value = Self.turkishStart(index)
            starts[index] = value
            return value
        }

        var known: Int?
        for i in stride(from: index - 1, through: index - Self.chainMonths, by: -1) {
            if starts[i] != nil {
                known = i
                break
            }
        }
        var cursorIdx: Int
        var date: CivilDate
        if let known {
            cursorIdx = known
            date = starts[known]!
        } else {
            cursorIdx = index - Self.chainMonths
            date = Self.ummAlQuraStart(cursorIdx)
            starts[cursorIdx] = date
        }

        while cursorIdx < index {
            let day29 = date.addingDays(28)
            date = crescentAccepted(day29) ? day29.addingDays(1) : day29.addingDays(2)
            cursorIdx += 1
            starts[cursorIdx] = date
        }
        return date
    }

    private func crescentAccepted(_ day29: CivilDate) -> Bool {
        guard let e = Crescent.evening(date: day29, timeZone: timeZone, latitude: region.latitude, longitude: region.longitude),
              e.conjunctionBeforeSunset else {
            return false
        }
        switch region.method {
        case .egypt:
            return e.centreLagMinutes >= 5.0
        case .sighting:
            return (e.odehV ?? -.infinity) >= -0.96
        case .nakedEye:
            return (e.odehV ?? -.infinity) >= 2.0
        case .mabims:
            return e.moonAltitude >= 3.0 && e.elongation >= 6.4
        default:
            return e.lagMinutes > 0.0
        }
    }

    private static func turkishStart(_ index: Int) -> CivilDate {
        let uq = ummAlQuraStart(index)
        let conj = Ephemeris.previousConjunction(Ephemeris.julianDay(epochMillis: utcMillis(uq.addingDays(1), hour: 0)))
        let conjDayOffset = Int(floor(Double(Ephemeris.epochMillis(julianDay: conj)) / 86_400_000.0))
        let conjunctionDate = CivilDate(dayNumber: CivilDate.unixEpochDayNumber + conjDayOffset)
        for offset in 0...2 {
            let evening = conjunctionDate.addingDays(offset)
            if globalCrescent(evening, conjunction: conj) {
                return evening.addingDays(1)
            }
        }
        return conjunctionDate.addingDays(3)
    }

    private static func utcMillis(_ date: CivilDate, hour: Int) -> Int64 {
        Int64(date.dayNumber - CivilDate.unixEpochDayNumber) * 86_400_000 + Int64(hour) * 3_600_000
    }

    private static func globalCrescent(_ date: CivilDate, conjunction: Double) -> Bool {
        let midnight = Ephemeris.julianDay(epochMillis: utcMillis(date.addingDays(1), hour: 0))
        var latitude = -60.0
        while latitude <= 60.0 {
            var longitude = -60.0
            for _ in 0..<4 {
                if let sunset = sunsetAt(date, latitude: latitude, longitude: longitude) {
                    longitude = min(180.0, max(-180.0, longitude + (sunset - midnight) * 360.0 + 0.5))
                }
            }
            if let s = sunsetAt(date, latitude: latitude, longitude: longitude),
               s < midnight, conjunction < s,
               meetsIstanbulCriterion(sunset: s, latitude: latitude, longitude: longitude) {
                return true
            }
            latitude += 5.0
        }

        let auckland = Zones.find("Pacific/Auckland")
        let nzNoon = Zones.atLocal(date: date.addingDays(1), hour: 12, minute: 0, timeZone: auckland)
        guard let nzDawn = Ephemeris.sunAtAltitude(noonJd: Ephemeris.julianDay(nzNoon), latitude: -41.2865, longitude: 174.7762, altitude: -18.0, evening: false),
              conjunction < nzDawn else {
            return false
        }
        latitude = -55.0
        while latitude <= 60.0 {
            for longitude in [-70.0, -90.0, -110.0, -125.0] {
                if let s = sunsetAt(date, latitude: latitude, longitude: longitude),
                   conjunction < s,
                   meetsIstanbulCriterion(sunset: s, latitude: latitude, longitude: longitude) {
                    return true
                }
            }
            latitude += 5.0
        }
        return false
    }

    private static func meetsIstanbulCriterion(sunset: Double, latitude: Double, longitude: Double) -> Bool {
        let sun = Ephemeris.sun(sunset)
        let moon = Ephemeris.moon(sunset)
        let topo = Ephemeris.topocentricMoon(sunset, moon: moon, latitude: latitude, longitude: longitude)
        let altitude = Ephemeris.altitude(sunset, ra: topo.rightAscension, dec: topo.declination, latitude: latitude, longitude: longitude)
        return altitude >= 5.0 && Ephemeris.separation(sun, moon) >= 8.0
    }

    private static func sunsetAt(_ date: CivilDate, latitude: Double, longitude: Double) -> Double? {
        let rawOffset = Int(floor(longitude / 15.0 * 3600.0 + 0.5))
        let offsetSeconds = min(18 * 3600, max(-18 * 3600, rawOffset))
        let noonMillis = utcMillis(date, hour: 12) - Int64(offsetSeconds) * 1000
        return Crescent.sunsetOn(noonJd: Ephemeris.julianDay(epochMillis: noonMillis), latitude: latitude, longitude: longitude)
    }

    private static func clamp(_ date: CivilDate) -> CivilDate {
        if date < minDate { return minDate }
        if date > maxDate { return maxDate }
        return date
    }
}
