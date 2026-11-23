import Foundation

struct CelestialPosition: Sendable {
    let rightAscension: Double
    let declination: Double
    let longitude: Double
    let distance: Double
}

enum Ephemeris {
    static let deg = Double.pi / 180.0
    static let j2000 = 2_451_545.0
    static let earthRadiusKm = 6378.14
    static let moonRadiusKm = 1737.4
    static let sunsetAltitude = -0.8333
    static let refractionAtHorizon = 0.5667

    static func sinD(_ x: Double) -> Double { sin(x * deg) }
    static func cosD(_ x: Double) -> Double { cos(x * deg) }
    static func norm360(_ x: Double) -> Double { x - 360.0 * floor(x / 360.0) }
    static func norm180(_ x: Double) -> Double { norm360(x + 180.0) - 180.0 }

    static func julianDay(epochMillis: Int64) -> Double {
        Double(epochMillis) / 86_400_000.0 + 2_440_587.5
    }

    static func julianDay(_ date: Date) -> Double {
        let ms = Int64((date.timeIntervalSince1970 * 1000.0).rounded())
        return julianDay(epochMillis: ms)
    }

    static func epochMillis(julianDay: Double) -> Int64 {
        Int64((julianDay - 2_440_587.5) * 86_400_000.0)
    }

    private static func centuries(_ jd: Double) -> Double {
        (jd - j2000) / 36_525.0
    }

    private static func obliquity(_ t: Double) -> Double {
        let omega = 125.04452 - 1934.136261 * t
        let eps0 = 23.0 + 26.0 / 60.0 + 21.448 / 3600.0 - (46.8150 * t + 0.00059 * t * t - 0.001813 * t * t * t) / 3600.0
        return eps0 + 0.00256 * cosD(omega)
    }

    private static func toEquatorial(longitude: Double, latitude: Double, epsilon: Double) -> (Double, Double) {
        let ra = atan2(sinD(longitude) * cosD(epsilon) - tan(latitude * deg) * sinD(epsilon), cosD(longitude)) / deg
        let dec = asin(sinD(latitude) * cosD(epsilon) + cosD(latitude) * sinD(epsilon) * sinD(longitude)) / deg
        return (norm360(ra), dec)
    }

    static func sun(_ jd: Double) -> CelestialPosition {
        let t = centuries(jd)
        let l0 = norm360(280.46646 + 36000.76983 * t + 0.0003032 * t * t)
        let m = norm360(357.52911 + 35999.05029 * t - 0.0001537 * t * t)
        let e = 0.016708634 - 0.000042037 * t - 0.0000001267 * t * t
        let c = (1.914602 - 0.004817 * t - 0.000014 * t * t) * sinD(m) +
                (0.019993 - 0.000101 * t) * sinD(2 * m) +
                0.000289 * sinD(3 * m)
        let trueLongitude = l0 + c
        let anomaly = m + c
        let r = 1.000001018 * (1 - e * e) / (1 + e * cosD(anomaly))
        let omega = 125.04 - 1934.136 * t
        let apparent = norm360(trueLongitude - 0.00569 - 0.00478 * sinD(omega))
        let (ra, dec) = toEquatorial(longitude: apparent, latitude: 0.0, epsilon: obliquity(t))
        return CelestialPosition(rightAscension: ra, declination: dec, longitude: apparent, distance: r)
    }

    static func moon(_ jd: Double) -> CelestialPosition {
        let t = centuries(jd)
        let t2 = t * t
        let t3 = t2 * t
        let t4 = t3 * t
        let lp = norm360(218.3164477 + 481267.88123421 * t - 0.0015786 * t2 + t3 / 538841.0 - t4 / 65194000.0)
        let d = norm360(297.8501921 + 445267.1114034 * t - 0.0018819 * t2 + t3 / 545868.0 - t4 / 113065000.0)
        let m = norm360(357.5291092 + 35999.0502909 * t - 0.0001536 * t2 + t3 / 24490000.0)
        let mp = norm360(134.9633964 + 477198.8675055 * t + 0.0087414 * t2 + t3 / 69699.0 - t4 / 14712000.0)
        let f = norm360(93.2720950 + 483202.0175233 * t - 0.0036539 * t2 - t3 / 3526000.0 + t4 / 863310000.0)
        let a1 = norm360(119.75 + 131.849 * t)
        let a2 = norm360(53.09 + 479264.290 * t)
        let a3 = norm360(313.45 + 481266.484 * t)
        let e = 1.0 - 0.002516 * t - 0.0000074 * t2

        var sumL = 0.0
        var sumR = 0.0
        for row in lrTerms {
            let arg = row.0 * d + row.1 * m + row.2 * mp + row.3 * f
            let mAbs = abs(Int(row.1))
            let factor = mAbs == 1 ? e : (mAbs == 2 ? e * e : 1.0)
            sumL += row.4 * factor * sinD(arg)
            sumR += row.5 * factor * cosD(arg)
        }
        var sumB = 0.0
        for row in bTerms {
            let arg = row.0 * d + row.1 * m + row.2 * mp + row.3 * f
            let mAbs = abs(Int(row.1))
            let factor = mAbs == 1 ? e : (mAbs == 2 ? e * e : 1.0)
            sumB += row.4 * factor * sinD(arg)
        }
        sumL += 3958.0 * sinD(a1) + 1962.0 * sinD(lp - f) + 318.0 * sinD(a2)
        sumB += -2235.0 * sinD(lp) + 382.0 * sinD(a3) + 175.0 * sinD(a1 - f) + 175.0 * sinD(a1 + f) +
                127.0 * sinD(lp - mp) - 115.0 * sinD(lp + mp)

        let omega = 125.04452 - 1934.136261 * t
        let l0 = 280.4665 + 36000.7698 * t
        let dPsi = (-17.20 * sinD(omega) - 1.32 * sinD(2 * l0) - 0.23 * sinD(2 * lp) + 0.21 * sinD(2 * omega)) / 3600.0

        let longitude = norm360(lp + sumL / 1_000_000.0 + dPsi)
        let latitude = sumB / 1_000_000.0
        let distance = 385_000.56 + sumR / 1000.0
        let (ra, dec) = toEquatorial(longitude: longitude, latitude: latitude, epsilon: obliquity(t))
        return CelestialPosition(rightAscension: ra, declination: dec, longitude: longitude, distance: distance)
    }

    static func siderealTime(_ jd: Double) -> Double {
        let t = centuries(jd)
        return norm360(280.46061837 + 360.98564736629 * (jd - j2000) + 0.000387933 * t * t - (t * t * t) / 38_710_000.0)
    }

    static func altitude(_ jd: Double, ra: Double, dec: Double, latitude: Double, longitude: Double) -> Double {
        let hourAngle = siderealTime(jd) + longitude - ra
        return asin(sinD(latitude) * sinD(dec) + cosD(latitude) * cosD(dec) * cosD(hourAngle)) / deg
    }

    static func moonParallax(distanceKm: Double) -> Double {
        asin(earthRadiusKm / distanceKm) / deg
    }

    static func topocentricMoon(_ jd: Double, moon: CelestialPosition, latitude: Double, longitude: Double, elevationM: Double = 0.0) -> CelestialPosition {
        let parallax = moonParallax(distanceKm: moon.distance)
        let rho = 1.0 + elevationM / (earthRadiusKm * 1000.0)
        let rhoCos = rho * cosD(latitude)
        let rhoSin = rho * sinD(latitude)
        let hourAngle = siderealTime(jd) + longitude - moon.rightAscension
        let sinP = sinD(parallax)
        let dRa = atan2(-rhoCos * sinP * sinD(hourAngle), cosD(moon.declination) - rhoCos * sinP * cosD(hourAngle))
        let dec = atan2(
            (sinD(moon.declination) - rhoSin * sinP) * cos(dRa),
            cosD(moon.declination) - rhoCos * sinP * cosD(hourAngle)
        )
        let x = moon.distance * cosD(moon.declination) * cosD(hourAngle) - earthRadiusKm * rhoCos
        let y = moon.distance * cosD(moon.declination) * sinD(hourAngle)
        let z = moon.distance * sinD(moon.declination) - earthRadiusKm * rhoSin
        let distance = sqrt(x * x + y * y + z * z)
        return CelestialPosition(rightAscension: norm360(moon.rightAscension + dRa / deg), declination: dec / deg, longitude: moon.longitude, distance: distance)
    }

    static func separation(_ a: CelestialPosition, _ b: CelestialPosition) -> Double {
        let cosSep = sinD(a.declination) * sinD(b.declination) +
                     cosD(a.declination) * cosD(b.declination) * cosD(a.rightAscension - b.rightAscension)
        return acos(min(1.0, max(-1.0, cosSep))) / deg
    }

    static func elongationInLongitude(_ jd: Double) -> Double {
        norm180(moon(jd).longitude - sun(jd).longitude)
    }

    static func previousConjunction(_ jd: Double) -> Double {
        var delta = elongationInLongitude(jd)
        var guess = jd - norm360(delta) / 12.190749
        for _ in 0..<8 {
            delta = elongationInLongitude(guess)
            guess -= delta / 12.190749
        }
        return guess
    }

    static func sunAtAltitude(noonJd: Double, latitude: Double, longitude: Double, altitude: Double, evening: Bool = true) -> Double? {
        var jd = noonJd
        for _ in 0..<4 {
            let s = sun(jd)
            let cosH0 = (sinD(altitude) - sinD(latitude) * sinD(s.declination)) / (cosD(latitude) * cosD(s.declination))
            if cosH0 < -1.0 || cosH0 > 1.0 { return nil }
            let h0 = acos(cosH0) / deg
            let hourAngle = norm180(siderealTime(jd) + longitude - s.rightAscension)
            let target = evening ? h0 : -h0
            jd += norm180(target - hourAngle) / 360.98564736629
        }
        return jd
    }

    static func descendingCrossing(from: Double, to: Double, step: Double = 10.0 / 1440.0, _ f: (Double) -> Double) -> Double? {
        var a = from
        var fa = f(a)
        while a < to {
            let b = min(a + step, to)
            let fb = f(b)
            if fa > 0 && fb <= 0 {
                var lo = a
                var hi = b
                for _ in 0..<12 {
                    let mid = (lo + hi) / 2.0
                    if f(mid) > 0 { lo = mid } else { hi = mid }
                }
                return (lo + hi) / 2.0
            }
            a = b
            fa = fb
        }
        return nil
    }

    private static let lrTerms: [(Double, Double, Double, Double, Double, Double)] = [
        (0, 0, 1, 0, 6288774, -20905355), (2, 0, -1, 0, 1274027, -3699111), (2, 0, 0, 0, 658314, -2955968),
        (0, 0, 2, 0, 213618, -569925), (0, 1, 0, 0, -185116, 48888), (0, 0, 0, 2, -114332, -3149),
        (2, 0, -2, 0, 58793, 246158), (2, -1, -1, 0, 57066, -152138), (2, 0, 1, 0, 53322, -170733),
        (2, -1, 0, 0, 45758, -204586), (0, 1, -1, 0, -40923, -129620), (1, 0, 0, 0, -34720, 108743),
        (0, 1, 1, 0, -30383, 104755), (2, 0, 0, -2, 15327, 10321), (0, 0, 1, 2, -12528, 0),
        (0, 0, 1, -2, 10980, 79661), (4, 0, -1, 0, 10675, -34782), (0, 0, 3, 0, 10034, -23210),
        (4, 0, -2, 0, 8548, -21636), (2, 1, -1, 0, -7888, 24208), (2, 1, 0, 0, -6766, 30824),
        (1, 0, -1, 0, -5163, -8379), (1, 1, 0, 0, 4987, -16675), (2, -1, 1, 0, 4036, -12831),
        (2, 0, 2, 0, 3994, -10445), (4, 0, 0, 0, 3861, -11650), (2, 0, -3, 0, 3665, 14403),
        (0, 1, -2, 0, -2689, -7003), (2, 0, -1, 2, -2602, 0), (2, -1, -2, 0, 2390, 10056),
        (1, 0, 1, 0, -2348, 6322), (2, -2, 0, 0, 2236, -9884), (0, 1, 2, 0, -2120, 5751),
        (0, 2, 0, 0, -2069, 0), (2, -2, -1, 0, 2048, -4950), (2, 0, 1, -2, -1773, 4130),
        (2, 0, 0, 2, -1595, 0), (4, -1, -1, 0, 1215, -3958), (0, 0, 2, 2, -1110, 0),
        (3, 0, -1, 0, -892, 3258), (2, 1, 1, 0, -810, 2616), (4, -1, -2, 0, 759, -1897),
        (0, 2, -1, 0, -713, -2117), (2, 2, -1, 0, -700, 2354), (2, 1, -2, 0, 691, 0),
        (2, -1, 0, -2, 596, 0), (4, 0, 1, 0, 549, -1423), (0, 0, 4, 0, 537, -1117),
        (4, -1, 0, 0, 520, -1571), (1, 0, -2, 0, -487, -1739), (2, 1, 0, -2, -399, 0),
        (0, 0, 2, -2, -381, -4421), (1, 1, 1, 0, 351, 0), (3, 0, -2, 0, -340, 0),
        (4, 0, -3, 0, 330, 0), (2, -1, 2, 0, 327, 0), (0, 2, 1, 0, -323, 1165),
        (1, 1, -1, 0, 299, 0), (2, 0, 3, 0, 294, 0), (2, 0, -1, -2, 0, 8752)
    ]

    private static let bTerms: [(Double, Double, Double, Double, Double)] = [
        (0, 0, 0, 1, 5128122), (0, 0, 1, 1, 280602), (0, 0, 1, -1, 277693), (2, 0, 0, -1, 173237),
        (2, 0, -1, 1, 55413), (2, 0, -1, -1, 46271), (2, 0, 0, 1, 32573), (0, 0, 2, 1, 17198),
        (2, 0, 1, -1, 9266), (0, 0, 2, -1, 8822), (2, -1, 0, -1, 8216), (2, 0, -2, -1, 4324),
        (2, 0, 1, 1, 4200), (2, 1, 0, -1, -3359), (2, -1, -1, 1, 2463), (2, -1, 0, 1, 2211),
        (2, -1, -1, -1, 2065), (0, 1, -1, -1, -1870), (4, 0, -1, -1, 1828), (0, 1, 0, 1, -1794),
        (0, 0, 0, 3, -1749), (0, 1, -1, 1, -1565), (1, 0, 0, 1, -1491), (0, 1, 1, 1, -1475),
        (0, 1, 1, -1, -1410), (0, 1, 0, -1, -1344), (1, 0, 0, -1, -1335), (0, 0, 3, 1, 1107),
        (4, 0, 0, -1, 1021), (4, 0, -1, 1, 833), (0, 0, 1, -3, 777), (4, 0, -2, 1, 671),
        (2, 0, 0, -3, 607), (2, 0, 2, -1, 596), (2, -1, 1, -1, 491), (2, 0, -2, 1, -451),
        (0, 0, 3, -1, 439), (2, 0, 2, 1, 422), (2, 0, -3, -1, 421), (2, 1, -1, 1, -366),
        (2, 1, 0, 1, -351), (4, 0, 0, 1, 331), (2, -1, 1, 1, 315), (2, -2, 0, -1, 302),
        (0, 0, 1, 3, -283), (2, 1, 1, -1, -229), (1, 1, 0, -1, 223), (1, 1, 0, 1, 223),
        (0, 1, -2, -1, -220), (2, 1, -1, -1, -220), (1, 0, 1, 1, -185), (2, -1, -2, -1, 181),
        (0, 1, 2, 1, -177), (4, 0, -2, -1, 176), (4, -1, -1, -1, 166), (1, 0, 1, -1, -164),
        (4, 0, 1, -1, 132), (1, 0, -1, -1, -119), (4, -1, 0, -1, 115), (2, -2, 0, 1, 107)
    ]
}
