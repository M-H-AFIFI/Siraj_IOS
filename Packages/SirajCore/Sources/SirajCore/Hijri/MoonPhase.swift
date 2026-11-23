import Foundation

public enum MoonPhaseName: String, Sendable, Equatable, CaseIterable {
    case new
    case waxingCrescent
    case firstQuarter
    case waxingGibbous
    case full
    case waningGibbous
    case lastQuarter
    case waningCrescent

    public var stringKey: String {
        switch self {
        case .new: return "moon_new"
        case .waxingCrescent: return "moon_waxing_crescent"
        case .firstQuarter: return "moon_first_quarter"
        case .waxingGibbous: return "moon_waxing_gibbous"
        case .full: return "moon_full"
        case .waningGibbous: return "moon_waning_gibbous"
        case .lastQuarter: return "moon_last_quarter"
        case .waningCrescent: return "moon_waning_crescent"
        }
    }
}

public struct MoonPhaseInfo: Sendable, Equatable {
    public let illumination: Double
    public let waxing: Bool
    public let ageDays: Double

    public init(illumination: Double, waxing: Bool, ageDays: Double) {
        self.illumination = illumination
        self.waxing = waxing
        self.ageDays = ageDays
    }

    public var name: MoonPhaseName {
        if illumination < 0.03 { return .new }
        if illumination > 0.97 { return .full }
        if illumination >= 0.45 && illumination <= 0.55 {
            return waxing ? .firstQuarter : .lastQuarter
        }
        if illumination < 0.45 {
            return waxing ? .waxingCrescent : .waningCrescent
        }
        return waxing ? .waxingGibbous : .waningGibbous
    }
}

public enum MoonPhase {
    private static let deg = Double.pi / 180.0
    private static let kmPerAu = 149_597_870.7

    public static func at(_ date: Date) -> MoonPhaseInfo {
        let jd = Ephemeris.julianDay(date)
        return atJulianDay(jd)
    }

    public static func at(epochMillis: Int64) -> MoonPhaseInfo {
        let jd = Ephemeris.julianDay(epochMillis: epochMillis)
        return atJulianDay(jd)
    }

    private static func atJulianDay(_ jd: Double) -> MoonPhaseInfo {
        let sun = Ephemeris.sun(jd)
        let moon = Ephemeris.moon(jd)
        let psi = Ephemeris.separation(moon, sun) * deg
        let sunKm = sun.distance * kmPerAu
        let phaseAngle = atan2(sunKm * sin(psi), moon.distance - sunKm * cos(psi))
        let illumination = (1.0 + cos(phaseAngle)) / 2.0
        let ahead = moon.longitude - sun.longitude
        let waxing = ahead - 360.0 * floor(ahead / 360.0) < 180.0
        let age = jd - Ephemeris.previousConjunction(jd)
        return MoonPhaseInfo(illumination: min(1.0, max(0.0, illumination)), waxing: waxing, ageDays: age)
    }
}
