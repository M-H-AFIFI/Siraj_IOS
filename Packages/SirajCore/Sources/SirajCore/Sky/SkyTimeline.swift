import Foundation

/// Framework-independent ARGB colour for sky math and palettes.
public struct ArgbColor: Sendable, Hashable, Equatable {
    public let a: UInt8
    public let r: UInt8
    public let g: UInt8
    public let b: UInt8

    public init(a: UInt8, r: UInt8, g: UInt8, b: UInt8) {
        self.a = a
        self.r = r
        self.g = g
        self.b = b
    }

    public static func hex(_ argb: UInt32) -> ArgbColor {
        ArgbColor(
            a: UInt8((argb >> 24) & 0xFF),
            r: UInt8((argb >> 16) & 0xFF),
            g: UInt8((argb >> 8) & 0xFF),
            b: UInt8(argb & 0xFF)
        )
    }

    public func withAlpha(_ alpha: Double) -> ArgbColor {
        let clamped = min(1.0, max(0.0, alpha))
        return ArgbColor(a: UInt8((clamped * 255.0).rounded()), r: r, g: g, b: b)
    }

    public var alpha: Double { Double(a) / 255.0 }
    public var red: Double { Double(r) / 255.0 }
    public var green: Double { Double(g) / 255.0 }
    public var blue: Double { Double(b) / 255.0 }

    public var luminance: Double {
        func linear(_ v: UInt8) -> Double {
            let s = Double(v) / 255.0
            return s <= 0.03928 ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
    }

    public static func lerp(_ c1: ArgbColor, _ c2: ArgbColor, _ t: Double) -> ArgbColor {
        let f = min(1.0, max(0.0, t))
        func mix(_ x: UInt8, _ y: UInt8) -> UInt8 {
            UInt8(min(255, max(0, Int((Double(x) + (Double(y) - Double(x)) * f).rounded()))))
        }
        return ArgbColor(a: mix(c1.a, c2.a), r: mix(c1.r, c2.r), g: mix(c1.g, c2.g), b: mix(c1.b, c2.b))
    }
}

public struct SkyColors: Sendable, Equatable {
    public let sky: [ArgbColor]
    public let arc: [ArgbColor]
    public let orbGlow: ArgbColor
    public let orbCore: ArgbColor
    public let cardBorderTop: ArgbColor
    public let cardBorderBottom: ArgbColor
    public let footerBg: ArgbColor
    public let cardBg: ArgbColor
    public let showCrescent: Bool
    public let isWarmGlow: Bool
    public let cloudLight: ArgbColor
    public let cloudDark: ArgbColor
    public let cloudAlpha: Double
    public let starAlpha: Double
    public let rayAlpha: Double

    public func with(
        sky: [ArgbColor]? = nil,
        cardBg: ArgbColor? = nil,
        starAlpha: Double? = nil
    ) -> SkyColors {
        SkyColors(
            sky: sky ?? self.sky,
            arc: arc,
            orbGlow: orbGlow,
            orbCore: orbCore,
            cardBorderTop: cardBorderTop,
            cardBorderBottom: cardBorderBottom,
            footerBg: footerBg,
            cardBg: cardBg ?? self.cardBg,
            showCrescent: showCrescent,
            isWarmGlow: isWarmGlow,
            cloudLight: cloudLight,
            cloudDark: cloudDark,
            cloudAlpha: cloudAlpha,
            starAlpha: starAlpha ?? self.starAlpha,
            rayAlpha: rayAlpha
        )
    }
}

public struct SkyTwilight: Sendable, Equatable {
    public let falseDawn: Double
    public let trueDawn: Double
    public let sunriseGlow: Double
    public let sunsetGlow: Double
    public let shafaq: Double
    public let milkyWay: Double
    public let birds: Double
    public let mist: Double
}

public struct SkyMoment: Sendable, Equatable {
    public let colors: SkyColors
    public let twilight: SkyTwilight
}

public enum SkyTimeline {
    private static let skyStops = 6
    private static let arcStops = 3
    private static let middayBirds = 0.4

    public static var nightColors: SkyColors { SkyPalettes.ishaNightfall }

    public static func at(_ now: Date, prayers: [PrayerTimeEntry]) -> SkyMoment {
        let day = DayTimes.from(now: now, prayers: prayers)
        var keyframes: [(Date, SkyColors)] = []
        keyframes.reserveCapacity(48)
        for shift in -1...1 {
            keyframes.append(contentsOf: keyframesFor(day.shifted(shift)))
        }
        keyframes.sort { $0.0 < $1.0 }
        var ordered: [(Date, SkyColors)] = []
        ordered.reserveCapacity(keyframes.count)
        for frame in keyframes {
            if ordered.isEmpty || frame.0 > ordered[ordered.count - 1].0 {
                ordered.append(frame)
            }
        }

        let colors: SkyColors
        if let after = ordered.firstIndex(where: { $0.0 > now }) {
            if after == 0 {
                colors = ordered[0].1
            } else {
                let (from, a) = ordered[after - 1]
                let (to, b) = ordered[after]
                let span = to.timeIntervalSince(from)
                let f = span <= 0 ? 1.0 : min(1.0, max(0.0, now.timeIntervalSince(from) / span))
                colors = blend(a, b, smooth(f))
            }
        } else {
            colors = ordered.last?.1 ?? SkyPalettes.isha
        }

        return SkyMoment(colors: colors, twilight: twilightAt(now, today: day))
    }

    private static func keyframesFor(_ d: DayTimes) -> [(Date, SkyColors)] {
        let night = d.nextFajr.timeIntervalSince(d.maghrib)
        let midnight = d.maghrib.addingTimeInterval(night / 2.0)
        let lastThird = d.maghrib.addingTimeInterval(night * 2.0 / 3.0)
        let goldenEnd = min(d.sunrise.addingTimeInterval(50 * 60), mid(d.sunrise, d.dhuhr))
        return [
            (d.fajr.addingTimeInterval(-50 * 60), SkyPalettes.preDawn),
            (d.fajr, SkyPalettes.fajr),
            (d.sunrise.addingTimeInterval(-18 * 60), SkyPalettes.blueHourDawn),
            (d.sunrise, SkyPalettes.sunrise),
            (goldenEnd, SkyPalettes.morning),
            (d.dhuhr, SkyPalettes.noon),
            (d.asr, SkyPalettes.afternoon),
            (max(d.maghrib.addingTimeInterval(-55 * 60), mid(d.asr, d.maghrib)), SkyPalettes.goldenHour),
            (d.maghrib.addingTimeInterval(-12 * 60), SkyPalettes.sunset),
            (d.maghrib.addingTimeInterval(4 * 60), SkyPalettes.afterglow),
            (d.isha, SkyPalettes.isha),
            (midnight, SkyPalettes.midnight),
            (lastThird, SkyPalettes.lastThird)
        ]
    }

    private static func twilightAt(_ now: Date, today: DayTimes) -> SkyTwilight {
        var falseDawn = 0.0, trueDawn = 0.0, sunriseGlow = 0.0, sunsetGlow = 0.0
        var shafaq = 0.0, milkyWay = 0.0, birds = 0.0, mist = 0.0
        for shift in -1...1 {
            let d = today.shifted(shift)
            falseDawn = max(falseDawn, tent(now, d.fajr.addingTimeInterval(-70 * 60), d.fajr.addingTimeInterval(-20 * 60), d.fajr.addingTimeInterval(2 * 60)))
            trueDawn = max(trueDawn, plateau(now, d.fajr.addingTimeInterval(-4 * 60), d.sunrise.addingTimeInterval(-28 * 60), d.sunrise.addingTimeInterval(-6 * 60), d.sunrise.addingTimeInterval(14 * 60)))
            sunriseGlow = max(sunriseGlow, tent(now, d.sunrise.addingTimeInterval(-22 * 60), d.sunrise.addingTimeInterval(6 * 60), d.sunrise.addingTimeInterval(55 * 60)))
            sunsetGlow = max(sunsetGlow, tent(now, d.maghrib.addingTimeInterval(-70 * 60), d.maghrib.addingTimeInterval(-6 * 60), d.maghrib.addingTimeInterval(16 * 60)))
            shafaq = max(shafaq, tent(now, d.maghrib.addingTimeInterval(-6 * 60), d.maghrib.addingTimeInterval(6 * 60), d.isha))
            milkyWay = max(milkyWay, plateau(now, d.isha.addingTimeInterval(35 * 60), d.isha.addingTimeInterval(95 * 60), d.nextFajr.addingTimeInterval(-70 * 60), d.nextFajr.addingTimeInterval(-30 * 60)))
            let b1 = plateau(now, d.sunrise.addingTimeInterval(-5 * 60), d.sunrise.addingTimeInterval(15 * 60), d.sunrise.addingTimeInterval(100 * 60), d.sunrise.addingTimeInterval(150 * 60))
            let b2 = plateau(now, d.maghrib.addingTimeInterval(-110 * 60), d.maghrib.addingTimeInterval(-70 * 60), d.maghrib.addingTimeInterval(-4 * 60), d.maghrib.addingTimeInterval(20 * 60))
            let b3 = middayBirds * plateau(now, d.sunrise.addingTimeInterval(60 * 60), d.sunrise.addingTimeInterval(150 * 60), d.maghrib.addingTimeInterval(-110 * 60), d.maghrib.addingTimeInterval(-60 * 60))
            birds = max(birds, max(b1, max(b2, b3)))
            mist = max(mist, plateau(now, d.fajr.addingTimeInterval(5 * 60), d.sunrise.addingTimeInterval(-25 * 60), d.sunrise.addingTimeInterval(20 * 60), d.sunrise.addingTimeInterval(75 * 60)))
        }
        return SkyTwilight(falseDawn: falseDawn, trueDawn: trueDawn, sunriseGlow: sunriseGlow, sunsetGlow: sunsetGlow, shafaq: shafaq, milkyWay: milkyWay, birds: birds, mist: mist)
    }

    private static func blend(_ a: SkyColors, _ b: SkyColors, _ f: Double) -> SkyColors {
        let near = f < 0.5 ? a : b
        let sky = (0..<skyStops).map { ArgbColor.lerp(stop(a.sky, i: $0, count: skyStops), stop(b.sky, i: $0, count: skyStops), f) }
        let arc = (0..<arcStops).map { ArgbColor.lerp(stop(a.arc, i: $0, count: arcStops), stop(b.arc, i: $0, count: arcStops), f) }
        return SkyColors(
            sky: sky,
            arc: arc,
            orbGlow: ArgbColor.lerp(a.orbGlow, b.orbGlow, f),
            orbCore: ArgbColor.lerp(a.orbCore, b.orbCore, f),
            cardBorderTop: ArgbColor.lerp(a.cardBorderTop, b.cardBorderTop, f),
            cardBorderBottom: ArgbColor.lerp(a.cardBorderBottom, b.cardBorderBottom, f),
            footerBg: ArgbColor.lerp(a.footerBg, b.footerBg, f),
            cardBg: ArgbColor.lerp(a.cardBg, b.cardBg, f),
            showCrescent: near.showCrescent,
            isWarmGlow: near.isWarmGlow,
            cloudLight: ArgbColor.lerp(a.cloudLight, b.cloudLight, f),
            cloudDark: ArgbColor.lerp(a.cloudDark, b.cloudDark, f),
            cloudAlpha: a.cloudAlpha + (b.cloudAlpha - a.cloudAlpha) * f,
            starAlpha: a.starAlpha + (b.starAlpha - a.starAlpha) * f,
            rayAlpha: a.rayAlpha + (b.rayAlpha - a.rayAlpha) * f
        )
    }

    public static func stop(_ colors: [ArgbColor], i: Int, count: Int) -> ArgbColor {
        if colors.count <= 1 { return colors.first ?? ArgbColor.hex(0xFF000000) }
        let at = Double(i) / Double(count - 1) * Double(colors.count - 1)
        let lo = min(max(Int(at), 0), colors.count - 1)
        let hi = min(lo + 1, colors.count - 1)
        return ArgbColor.lerp(colors[lo], colors[hi], at - Double(lo))
    }

    private static func smooth(_ f: Double) -> Double { f * f * (3.0 - 2.0 * f) }

    private static func fraction(_ now: Date, _ from: Date, _ to: Date) -> Double {
        let span = to.timeIntervalSince(from)
        if span <= 0 { return now < to ? 0.0 : 1.0 }
        return min(1.0, max(0.0, now.timeIntervalSince(from) / span))
    }

    private static func tent(_ now: Date, _ start: Date, _ peak: Date, _ end: Date) -> Double {
        if now < start || now >= end { return 0.0 }
        return now < peak ? smooth(fraction(now, start, peak)) : 1.0 - smooth(fraction(now, peak, end))
    }

    private static func plateau(_ now: Date, _ start: Date, _ full: Date, _ fade: Date, _ end: Date) -> Double {
        if now < start || now >= end { return 0.0 }
        if now < full { return smooth(fraction(now, start, full)) }
        if now < fade { return 1.0 }
        return 1.0 - smooth(fraction(now, fade, end))
    }

    private static func mid(_ a: Date, _ b: Date) -> Date {
        a.addingTimeInterval(b.timeIntervalSince(a) / 2.0)
    }

    private struct DayTimes {
        let fajr: Date, sunrise: Date, dhuhr: Date, asr: Date, maghrib: Date, isha: Date
        var nextFajr: Date { fajr.addingTimeInterval(86_400) }

        func shifted(_ days: Int) -> DayTimes {
            guard days != 0 else { return self }
            let delta = TimeInterval(days * 86_400)
            return DayTimes(
                fajr: fajr.addingTimeInterval(delta),
                sunrise: sunrise.addingTimeInterval(delta),
                dhuhr: dhuhr.addingTimeInterval(delta),
                asr: asr.addingTimeInterval(delta),
                maghrib: maghrib.addingTimeInterval(delta),
                isha: isha.addingTimeInterval(delta)
            )
        }

        static func from(now: Date, prayers: [PrayerTimeEntry]) -> DayTimes {
            func find(_ type: PrayerType) -> Date? { prayers.first { $0.type == type }?.time }
            let dayStart = floor(now.timeIntervalSince1970 / 86_400.0) * 86_400.0
            let fallbackNoon = Date(timeIntervalSince1970: dayStart + 12.5 * 3600.0)
            let dhuhr = within(find(.dhuhr) ?? fallbackNoon, from: now.addingTimeInterval(-12 * 3600), until: now.addingTimeInterval(12 * 3600))
            let sunrise = within(find(.sunrise) ?? dhuhr.addingTimeInterval(-390 * 60), from: dhuhr.addingTimeInterval(-24 * 3600), until: dhuhr)
            let fajr = within(find(.fajr) ?? sunrise.addingTimeInterval(-90 * 60), from: sunrise.addingTimeInterval(-24 * 3600), until: sunrise)
            let asr = within(find(.asr) ?? dhuhr.addingTimeInterval(210 * 60), from: dhuhr, until: dhuhr.addingTimeInterval(24 * 3600))
            let maghrib = within(find(.maghrib) ?? dhuhr.addingTimeInterval(360 * 60), from: asr, until: asr.addingTimeInterval(24 * 3600))
            let isha = within(find(.isha) ?? maghrib.addingTimeInterval(90 * 60), from: maghrib, until: maghrib.addingTimeInterval(24 * 3600))
            return DayTimes(fajr: fajr, sunrise: sunrise, dhuhr: dhuhr, asr: asr, maghrib: maghrib, isha: isha)
        }

        private static func within(_ time: Date, from: Date, until: Date) -> Date {
            var t = time
            var guardCount = 0
            while t < from && guardCount < 4 { t = t.addingTimeInterval(86_400); guardCount += 1 }
            while t >= until && guardCount < 8 { t = t.addingTimeInterval(-86_400); guardCount += 1 }
            return t
        }
    }
}

public enum SkyPalettes {
    private static func c(_ argb: UInt32) -> ArgbColor { .hex(argb) }
    private static func c(_ argb: UInt32, _ alpha: Double) -> ArgbColor { ArgbColor.hex(argb).withAlpha(alpha) }

    private static func sky(
        _ sky: [ArgbColor], _ arc: [ArgbColor], _ orbGlow: ArgbColor, _ orbCore: ArgbColor,
        _ borderTop: ArgbColor, _ borderBottom: ArgbColor, _ footer: ArgbColor, _ card: ArgbColor,
        stars: Bool, rays: Bool, crescent: Bool, warm: Bool,
        _ cloudLight: ArgbColor, _ cloudDark: ArgbColor, _ cloudAlpha: Double, starAlpha: Double? = nil
    ) -> SkyColors {
        SkyColors(
            sky: sky, arc: arc, orbGlow: orbGlow, orbCore: orbCore,
            cardBorderTop: borderTop, cardBorderBottom: borderBottom, footerBg: footer, cardBg: card,
            showCrescent: crescent, isWarmGlow: warm, cloudLight: cloudLight, cloudDark: cloudDark,
            cloudAlpha: cloudAlpha, starAlpha: starAlpha ?? (stars ? 1.0 : 0.0), rayAlpha: rays ? 1.0 : 0.0
        )
    }

    public static let deepNight = sky(
        [c(0xFF02050E), c(0xFF060B1E), c(0xFF09142E), c(0xFF0D1D40), c(0xFF122854)],
        [c(0xFFD4AF37, 0.20), c(0xFFFFD54F, 0.85), c(0xFFD4AF37, 0.20)],
        c(0xFFE2E8F0), c(0xFFFFFFFF), c(0xFFD4AF37, 0.55), c(0xFF0A1530, 0.25), c(0xFF02040A), c(0xFF040816),
        stars: true, rays: false, crescent: true, warm: false, c(0xFFD6E4FA), c(0xFF141D32), 0.42
    )

    public static let tahajjudVigil = sky(
        [c(0xFF02040D), c(0xFF050A1A), c(0xFF081228), c(0xFF0B1936), c(0xFF102246)],
        [c(0xFFE5B558, 0.25), c(0xFFFFD54F, 0.90), c(0xFFE5B558, 0.25)],
        c(0xFFE2E8F0), c(0xFFFFFFFF), c(0xFFE5B558, 0.65), c(0xFF0A142E, 0.25), c(0xFF020308), c(0xFF030714),
        stars: true, rays: false, crescent: true, warm: false, c(0xFFD4E2F8), c(0xFF121B30), 0.42
    )

    public static let preDawnSahur = sky(
        [c(0xFF030612), c(0xFF080D22), c(0xFF101432), c(0xFF1C1942), c(0xFF2E204E)],
        [c(0xFFE5B558, 0.30), c(0xFFFFD166), c(0xFFE5B558, 0.30)],
        c(0xFFFED7AA), c(0xFFFFF7ED), c(0xFFFFD166, 0.65), c(0xFF121532, 0.30), c(0xFF03050E), c(0xFF060A1C),
        stars: true, rays: false, crescent: true, warm: false, c(0xFFDCD6F4), c(0xFF1C1838), 0.48
    )

    public static let fajrSubhSadiq = sky(
        [c(0xFF050816), c(0xFF0D122B), c(0xFF181B3E), c(0xFF28244E), c(0xFF422E58), c(0xFF6B4268)],
        [c(0xFFF4A261, 0.30), c(0xFFFFD166), c(0xFFE76F51, 0.40)],
        c(0xFFFFD166), c(0xFFFFF6D6), c(0xFFF4A261, 0.65), c(0xFF161B3D, 0.35), c(0xFF050816), c(0xFF080D22),
        stars: true, rays: false, crescent: true, warm: true, c(0xFFFFE0D4), c(0xFF38294B), 0.65
    )

    public static let sunriseGolden = sky(
        [c(0xFF0C254C), c(0xFF174278), c(0xFF286498), c(0xFF5A8EBE), c(0xFFECA060), c(0xFFFFD266)],
        [c(0xFFFFB74D, 0.35), c(0xFFFFE082), c(0xFFFF9800, 0.45)],
        c(0xFFFFD54F), c(0xFFFFFDE7), c(0xFFFFD54F, 0.70), c(0xFF1E6091, 0.35), c(0xFF071F3E), c(0xFF09254C),
        stars: false, rays: true, crescent: false, warm: true, c(0xFFFFF2D8), c(0xFF784856), 0.78
    )

    public static let duhaMorning = sky(
        [c(0xFF0A2E5C), c(0xFF144D8A), c(0xFF2170AE), c(0xFF4C9ED2), c(0xFF8CD2F6)],
        [c(0xFFFFC107, 0.35), c(0xFFFFE082), c(0xFFFF9800, 0.45)],
        c(0xFFFFE082), c(0xFFFFFFFF), c(0xFFFFD54F, 0.70), c(0xFF1E6091, 0.35), c(0xFF072142), c(0xFF092950),
        stars: false, rays: true, crescent: false, warm: true, c(0xFFFFFFFF), c(0xFFBCD8EE), 0.80
    )

    public static let dhuhrZenith = sky(
        [c(0xFF072440), c(0xFF0E4373), c(0xFF176096), c(0xFF2F85B8), c(0xFF78BCE0)],
        [c(0xFFFFD54F, 0.35), c(0xFFFFF59D), c(0xFFFFB74D, 0.35)],
        c(0xFFFFF59D), c(0xFFFFFFFF), c(0xFFFFD54F, 0.65), c(0xFF0E4373, 0.30), c(0xFF051B30), c(0xFF07223C),
        stars: false, rays: true, crescent: false, warm: true, c(0xFFFFFFFF), c(0xFFAED0EA), 0.82
    )

    public static let sunsetTwilight = sky(
        [c(0xFF0F0B24), c(0xFF26123A), c(0xFF541C44), c(0xFF942F3C), c(0xFFDC602A), c(0xFFFAA434)],
        [c(0xFFE76F51, 0.35), c(0xFFFF9800), c(0xFFD35400, 0.40)],
        c(0xFFF39C12), c(0xFFFFF0D4), c(0xFFFF9800, 0.75), c(0xFF26123A, 0.35), c(0xFF0B071A), c(0xFF110826),
        stars: false, rays: true, crescent: false, warm: true, c(0xFFFFD6AA), c(0xFF58223E), 0.82
    )

    public static let maghribDusk = sky(
        [c(0xFF0B061A), c(0xFF1C0D2E), c(0xFF35143E), c(0xFF581D40), c(0xFF882C36), c(0xFFB84C2A)],
        [c(0xFFE76F51, 0.35), c(0xFFF39C12), c(0xFFD35400, 0.40)],
        c(0xFFF39C12), c(0xFFFFF0D4), c(0xFFF39C12, 0.75), c(0xFF260B33, 0.35), c(0xFF0A0414), c(0xFF110722),
        stars: true, rays: false, crescent: true, warm: true, c(0xFFE89E80), c(0xFF361839), 0.72
    )

    public static let ishaNightfall = sky(
        [c(0xFF030610), c(0xFF060E22), c(0xFF0B1736), c(0xFF102048), c(0xFF152A5C)],
        [c(0xFFE5B558, 0.25), c(0xFFFFD54F, 0.90), c(0xFFE5B558, 0.25)],
        c(0xFFE2E8F0), c(0xFFFFFFFF), c(0xFFE5B558, 0.65), c(0xFF102048, 0.25), c(0xFF030610), c(0xFF050B1C),
        stars: true, rays: false, crescent: true, warm: false, c(0xFFD4E2F8), c(0xFF131D32), 0.45
    )

    public static let preDawn = preDawnSahur.with(starAlpha: 0.9)
    public static let fajr = fajrSubhSadiq.with(starAlpha: 0.45)

    public static let blueHourDawn = sky(
        [c(0xFF0F2349), c(0xFF1D3B6B), c(0xFF3E5C8E), c(0xFF8A7DA6), c(0xFFE0A08E), c(0xFFFFC489)],
        [c(0xFFFFB38A, 0.32), c(0xFFFFD9A0), c(0xFFFF9E80, 0.40)],
        c(0xFFFFC27A), c(0xFFFFF3E0), c(0xFFFFC27A, 0.66), c(0xFF1D3B6B, 0.32), c(0xFF0A1A38), c(0xFF0E2143),
        stars: false, rays: false, crescent: true, warm: true, c(0xFFFFD4C2), c(0xFF45365A), 0.72, starAlpha: 0.12
    )

    public static let sunrise = sunriseGolden

    public static let morning = duhaMorning.with(
        sky: [c(0xFF1A4C8E), c(0xFF2565AA), c(0xFF3884C4), c(0xFF5FA6D8), c(0xFF9CCDEB), c(0xFFDDE6DA)],
        cardBg: c(0xFF123C70)
    )

    public static let noon = dhuhrZenith.with(
        sky: [c(0xFF15457F), c(0xFF205E9E), c(0xFF337DBA), c(0xFF62A2D1), c(0xFFA3CCE4), c(0xFFE9D8AE)],
        cardBg: c(0xFF0F3666)
    )

    public static let afternoon = sky(
        [c(0xFF2F5E8C), c(0xFF4D7FAA), c(0xFF8AA6B8), c(0xFFD2B48C), c(0xFFE8A35C), c(0xFFE08A3E)],
        [c(0xFFFFCA7A, 0.35), c(0xFFFFE0A0), c(0xFFFFA94D, 0.40)],
        c(0xFFFFD27A), c(0xFFFFF6DD), c(0xFFFFC870, 0.70), c(0xFF2F5E8C, 0.32), c(0xFF16293F), c(0xFF1C3350),
        stars: false, rays: true, crescent: false, warm: true, c(0xFFFFF2DD), c(0xFF8A6B75), 0.82
    )

    public static let goldenHour = sky(
        [c(0xFF203458), c(0xFF3F5079), c(0xFF86697D), c(0xFFD58A5E), c(0xFFF2A048), c(0xFFFFBE5C)],
        [c(0xFFFF9E5E, 0.35), c(0xFFFFC870), c(0xFFE8743B, 0.40)],
        c(0xFFFFB04A), c(0xFFFFEBC6), c(0xFFFFB04A, 0.74), c(0xFF3F5079, 0.34), c(0xFF141D33), c(0xFF1A2440),
        stars: false, rays: true, crescent: false, warm: true, c(0xFFFFD89E), c(0xFF6B384A), 0.80
    )

    public static let sunset = sunsetTwilight
    public static let afterglow = maghribDusk.with(starAlpha: 0.30)
    public static let isha = ishaNightfall.with(starAlpha: 0.90)
    public static let midnight = deepNight
    public static let lastThird = tahajjudVigil
}

/// Shifts cool sky tones toward the active palette accent while leaving warm dawn, sunset, and sun tones intact.
public enum SkyPalette {
    private static let skyAmount = 0.50
    private static let cardAmount = 0.55
    private static let arcAmount = 0.30

    public static func tint(_ sky: SkyColors, accent: ArgbColor) -> SkyColors {
        guard accent.a > 0 else { return sky }
        let accentHsl = Hsl.of(accent)
        if accentHsl.s < 0.12 { return sky }
        return SkyColors(
            sky: sky.sky.map { towards($0, accent: accentHsl, amount: skyAmount) },
            arc: sky.arc.map { towards($0, accent: accentHsl, amount: arcAmount) },
            orbGlow: sky.orbGlow,
            orbCore: sky.orbCore,
            cardBorderTop: towards(sky.cardBorderTop, accent: accentHsl, amount: cardAmount),
            cardBorderBottom: towards(sky.cardBorderBottom, accent: accentHsl, amount: cardAmount),
            footerBg: towards(sky.footerBg, accent: accentHsl, amount: cardAmount),
            cardBg: towards(sky.cardBg, accent: accentHsl, amount: cardAmount),
            showCrescent: sky.showCrescent,
            isWarmGlow: sky.isWarmGlow,
            cloudLight: sky.cloudLight,
            cloudDark: towards(sky.cloudDark, accent: accentHsl, amount: skyAmount * 0.5),
            cloudAlpha: sky.cloudAlpha,
            starAlpha: sky.starAlpha,
            rayAlpha: sky.rayAlpha
        )
    }

    private static func towards(_ color: ArgbColor, accent: Hsl, amount: Double) -> ArgbColor {
        let hsl = Hsl.of(color)
        let dark = 1.0 - hsl.l
        let weight = amount * coolness(hsl) * (0.15 + 0.85 * dark * dark)
        if weight <= 0.001 { return color }
        let target = Hsl(
            h: accent.h,
            s: min(accent.s, max(hsl.s, 0.35)),
            l: hsl.l
        ).toArgb(alpha: color.alpha)
        return ArgbColor.lerp(color, target, min(1.0, max(0.0, weight)))
    }

    private static func coolness(_ hsl: Hsl) -> Double {
        if hsl.s < 0.10 { return 1.0 }
        var d = abs(hsl.h - 230.0)
        if d > 180.0 { d = 360.0 - d }
        if d <= 60.0 { return 1.0 }
        if d >= 120.0 { return 0.0 }
        return 1.0 - (d - 60.0) / 60.0
    }

    private struct Hsl {
        let h: Double
        let s: Double
        let l: Double

        static func of(_ c: ArgbColor) -> Hsl {
            let r = c.red, g = c.green, b = c.blue
            let maxC = max(r, max(g, b))
            let minC = min(r, min(g, b))
            let l = (maxC + minC) / 2.0
            let delta = maxC - minC
            if delta < 1e-5 { return Hsl(h: 0, s: 0, l: l) }
            let s = delta / (1.0 - abs(2.0 * l - 1.0))
            let rawH: Double
            if maxC == r {
                rawH = 60.0 * ((g - b) / delta).truncatingRemainder(dividingBy: 6.0)
            } else if maxC == g {
                rawH = 60.0 * (((b - r) / delta) + 2.0)
            } else {
                rawH = 60.0 * (((r - g) / delta) + 4.0)
            }
            return Hsl(h: rawH < 0 ? rawH + 360.0 : rawH, s: min(1.0, max(0.0, s)), l: l)
        }

        func toArgb(alpha: Double) -> ArgbColor {
            let c = (1.0 - abs(2.0 * l - 1.0)) * s
            let hp = (h / 60.0).truncatingRemainder(dividingBy: 6.0)
            let x = c * (1.0 - abs(hp.truncatingRemainder(dividingBy: 2.0) - 1.0))
            let r1, g1, b1: Double
            if hp < 1 { (r1, g1, b1) = (c, x, 0) }
            else if hp < 2 { (r1, g1, b1) = (x, c, 0) }
            else if hp < 3 { (r1, g1, b1) = (0, c, x) }
            else if hp < 4 { (r1, g1, b1) = (0, x, c) }
            else if hp < 5 { (r1, g1, b1) = (x, 0, c) }
            else { (r1, g1, b1) = (c, 0, x) }
            let m = l - c / 2.0
            func byte(_ v: Double) -> UInt8 {
                UInt8(min(255, max(0, Int((min(1.0, max(0.0, v)) * 255.0).rounded()))))
            }
            return ArgbColor(a: byte(alpha), r: byte(r1 + m), g: byte(g1 + m), b: byte(b1 + m))
        }
    }
}
