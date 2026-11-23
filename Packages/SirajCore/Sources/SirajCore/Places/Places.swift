import Foundation

extension City {
    public func displayName(language: String) -> String {
        switch language.prefix(2).lowercased() {
        case "ar": return nameAr
        case "ur": return nameUr
        default: return name
        }
    }

    public func displayCountry(language: String) -> String {
        switch language.prefix(2).lowercased() {
        case "ar": return countryAr
        case "ur": return countryUr
        default: return country
        }
    }
}

public struct Place: Codable, Sendable, Equatable, Hashable {
    public let latitude: Double
    public let longitude: Double
    public let cityName: String?
    public let cityNameAr: String?
    public let timeZoneId: String
    public let countryCode: String?

    public init(
        latitude: Double,
        longitude: Double,
        cityName: String? = nil,
        cityNameAr: String? = nil,
        timeZoneId: String = "UTC",
        countryCode: String? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.cityName = cityName
        self.cityNameAr = cityNameAr
        self.timeZoneId = timeZoneId
        self.countryCode = countryCode
    }

    public var timeZone: TimeZone {
        Zones.find(timeZoneId)
    }

    public var resolvedCountryCode: String? {
        countryCode ?? Zones.countryOf(timeZoneId)
    }

    public func displayName(language: String) -> String? {
        let lang = language.prefix(2).lowercased()
        if (lang == "ar" || lang == "ur"), let ar = cityNameAr, !ar.trimmingCharacters(in: .whitespaces).isEmpty {
            return ar
        }
        guard let en = cityName, !en.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return en
    }

    public func today(at now: Date) -> CivilDate {
        CivilDate.from(date: now, timeZone: timeZone)
    }

    public static func fromCity(_ city: City) -> Place {
        Place(
            latitude: city.latitude,
            longitude: city.longitude,
            cityName: city.name,
            cityNameAr: city.nameAr,
            timeZoneId: city.timeZoneId,
            countryCode: city.countryCode
        )
    }

    public static var cairoDefault: Place {
        if let cairo = Cities.search("Cairo").first {
            return .fromCity(cairo)
        }
        return Place(latitude: 30.0444, longitude: 31.2357, cityName: "Cairo", cityNameAr: "القاهرة", timeZoneId: "Africa/Cairo", countryCode: "EG")
    }
}

public enum Zones {
    public static func find(_ ianaId: String?) -> TimeZone {
        guard let id = ianaId?.trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty else {
            return .current
        }
        if id == "UTC" || id == "GMT" || id == "Etc/UTC" {
            return TimeZone(secondsFromGMT: 0)!
        }
        return TimeZone(identifier: id) ?? .current
    }

    public static func countryOf(_ ianaId: String?) -> String? {
        guard let id = ianaId?.trimmingCharacters(in: .whitespacesAndNewlines),
              !id.isEmpty, id != "UTC", id != "GMT" else {
            return nil
        }
        return ZoneCountries.byZone[id]
    }

    public static func atLocal(date: CivilDate, hour: Int, minute: Int, timeZone: TimeZone) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        var comps = DateComponents()
        comps.year = date.year
        comps.month = date.month
        comps.day = date.day
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        return cal.date(from: comps) ?? date.utcMidnight.addingTimeInterval(TimeInterval(hour * 3600 + minute * 60))
    }

    public static func plausibleZoneId(preferred: String?, latitude: Double, longitude: Double, now: Date) -> String {
        let candidate = (preferred == nil || preferred == "UTC" || preferred == "GMT") ? TimeZone.current.identifier : preferred!
        let tz = find(candidate)
        let offsetHours = Double(tz.secondsFromGMT(for: now)) / 3600.0
        var apart = (offsetHours - longitude / 15.0).truncatingRemainder(dividingBy: 24.0)
        if apart > 12.0 { apart -= 24.0 }
        if apart < -12.0 { apart += 24.0 }
        if abs(apart) <= 3.5 { return candidate }
        return Cities.nearest(latitude: latitude, longitude: longitude)?.timeZoneId ?? candidate
    }
}

public enum Cities {
    public static var all: [City] { CityCatalog.all }

    public static func search(_ query: String, limit: Int? = nil) -> [City] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return limit.map { Array(all.prefix($0)) } ?? all
        }
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        func matches(_ text: String) -> Bool {
            text.range(of: trimmed, options: options) != nil
        }
        func isPrefix(_ text: String) -> Bool {
            text.range(of: trimmed, options: [options, .anchored]) != nil
        }
        let filtered = all.filter {
            matches($0.name) || matches($0.nameAr) || matches($0.nameUr) ||
            matches($0.country) || matches($0.countryAr) || matches($0.countryUr)
        }.sorted { a, b in
            let aPref = isPrefix(a.name) || isPrefix(a.nameAr)
            let bPref = isPrefix(b.name) || isPrefix(b.nameAr)
            if aPref != bPref { return aPref }
            return a.name < b.name
        }
        return limit.map { Array(filtered.prefix($0)) } ?? filtered
    }

    public static func nearest(latitude: Double, longitude: Double) -> City? {
        all.min { a, b in
            squaredDist(latitude, longitude, a.latitude, a.longitude) <
            squaredDist(latitude, longitude, b.latitude, b.longitude)
        }
    }

    private static func squaredDist(_ lat1: Double, _ lon1: Double, _ lat2: Double, _ lon2: Double) -> Double {
        let dLat = lat1 - lat2
        let dLon = (lon1 - lon2) * cos(DoubleUtil.toRadians((lat1 + lat2) / 2.0))
        return dLat * dLat + dLon * dLon
    }
}
