import Foundation

struct CrescentEvening: Sendable {
    let sunsetMillis: Int64
    let moonsetMillis: Int64?
    let lagMinutes: Double
    let centreLagMinutes: Double
    let conjunctionBeforeSunset: Bool
    let ageHours: Double
    let moonAltitude: Double
    let elongation: Double
    let odehV: Double?
}

enum Crescent {
    private static let deg = Double.pi / 180.0

    static func evening(date: CivilDate, timeZone: TimeZone, latitude: Double, longitude: Double) -> CrescentEvening? {
        let noonDate = Zones.atLocal(date: date, hour: 12, minute: 0, timeZone: timeZone)
        let noonJd = Ephemeris.julianDay(noonDate)
        guard let sunset = sunsetOn(noonJd: noonJd, latitude: latitude, longitude: longitude) else { return nil }
        return atSunset(sunset, latitude: latitude, longitude: longitude)
    }

    static func atSunset(_ sunset: Double, latitude: Double, longitude: Double) -> CrescentEvening {
        let moonset = setting(sunset: sunset, latitude: latitude, longitude: longitude, upperLimb: true)
        let centreSet = setting(sunset: sunset, latitude: latitude, longitude: longitude, upperLimb: false)
        let lagMinutes = (moonset - sunset) * 1440.0

        let conjunction = Ephemeris.previousConjunction(sunset)
        let sun = Ephemeris.sun(sunset)
        let moon = Ephemeris.moon(sunset)
        let topo = Ephemeris.topocentricMoon(sunset, moon: moon, latitude: latitude, longitude: longitude)
        let moonAltitude = Ephemeris.altitude(sunset, ra: topo.rightAscension, dec: topo.declination, latitude: latitude, longitude: longitude)

        return CrescentEvening(
            sunsetMillis: Ephemeris.epochMillis(julianDay: sunset),
            moonsetMillis: Ephemeris.epochMillis(julianDay: moonset),
            lagMinutes: lagMinutes,
            centreLagMinutes: (centreSet - sunset) * 1440.0,
            conjunctionBeforeSunset: conjunction < sunset && (sunset - conjunction) < 20.0,
            ageHours: (sunset - conjunction) * 24.0,
            moonAltitude: moonAltitude,
            elongation: Ephemeris.separation(sun, moon),
            odehV: lagMinutes > 0 ? odeh(sunset + lagMinutes * 4.0 / 9.0 / 1440.0, latitude: latitude, longitude: longitude) : nil
        )
    }

    static func sunsetOn(noonJd: Double, latitude: Double, longitude: Double) -> Double? {
        Ephemeris.sunAtAltitude(noonJd: noonJd, latitude: latitude, longitude: longitude, altitude: Ephemeris.sunsetAltitude)
    }

    private static func setting(sunset: Double, latitude: Double, longitude: Double, upperLimb: Bool) -> Double {
        let f: (Double) -> Double = { jd in
            moonSetFunction(jd, latitude: latitude, longitude: longitude, upperLimb: upperLimb)
        }
        if f(sunset) > 0 {
            return Ephemeris.descendingCrossing(from: sunset, to: sunset + 0.25, f) ?? (sunset + 0.25)
        } else {
            return Ephemeris.descendingCrossing(from: sunset - 0.25, to: sunset, f) ?? (sunset - 0.25)
        }
    }

    private static func moonSetFunction(_ jd: Double, latitude: Double, longitude: Double, upperLimb: Bool) -> Double {
        let moon = Ephemeris.moon(jd)
        let topo = Ephemeris.topocentricMoon(jd, moon: moon, latitude: latitude, longitude: longitude)
        let altitude = Ephemeris.altitude(jd, ra: topo.rightAscension, dec: topo.declination, latitude: latitude, longitude: longitude)
        let semiDiameter = upperLimb ? asin(Ephemeris.moonRadiusKm / topo.distance) / deg : 0.0
        return altitude + semiDiameter + Ephemeris.refractionAtHorizon
    }

    private static func odeh(_ jd: Double, latitude: Double, longitude: Double) -> Double {
        let sun = Ephemeris.sun(jd)
        let moon = Ephemeris.moon(jd)
        let topo = Ephemeris.topocentricMoon(jd, moon: moon, latitude: latitude, longitude: longitude)
        let sunAltitude = Ephemeris.altitude(jd, ra: sun.rightAscension, dec: sun.declination, latitude: latitude, longitude: longitude)
        let moonAltitude = Ephemeris.altitude(jd, ra: topo.rightAscension, dec: topo.declination, latitude: latitude, longitude: longitude)
        let arcv = moonAltitude - sunAltitude
        let arcl = Ephemeris.separation(sun, topo)
        let semiDiameterArcmin = asin(Ephemeris.moonRadiusKm / topo.distance) / deg * 60.0
        let width = semiDiameterArcmin * (1.0 - cos(arcl * deg))
        return arcv - (-0.1018 * width * width * width + 0.7319 * width * width - 6.3226 * width + 7.1651)
    }
}
