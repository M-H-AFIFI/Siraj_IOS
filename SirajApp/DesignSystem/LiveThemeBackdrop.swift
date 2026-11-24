import SwiftUI
import SirajCore

struct SceneRGB {
    let r: Double
    let g: Double
    let b: Double
    let a: Double

    init(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1.0) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    init(argb: ArgbColor) {
        self.r = argb.red
        self.g = argb.green
        self.b = argb.blue
        self.a = argb.alpha
    }

    init(hex: UInt32) {
        self.init(argb: ArgbColor.hex(hex))
    }

    static let white = SceneRGB(1, 1, 1, 1)
    static let black = SceneRGB(0, 0, 0, 1)

    func lerp(to other: SceneRGB, _ t: Double) -> SceneRGB {
        let u = min(1.0, max(0.0, t))
        return SceneRGB(
            r + (other.r - r) * u,
            g + (other.g - g) * u,
            b + (other.b - b) * u,
            a + (other.a - a) * u
        )
    }

    func color(alpha: Double = 1.0) -> Color {
        Color(.sRGB, red: r, green: g, blue: b, opacity: min(1.0, max(0.0, a * alpha)))
    }
}

struct LiveSceneDrawColors {
    let isDark: Bool
    let skyTop: SceneRGB
    let skyUpperMid: SceneRGB
    let skyLowerMid: SceneRGB
    let skyHorizon: SceneRGB
    let accent: SceneRGB
    let accent2: SceneRGB
    let highlight: SceneRGB
    let shade: SceneRGB
    let ink: SceneRGB
    let veil: SceneRGB

    static func resolve(
        scheme: SirajColorSchemeSpec,
        isTimeSyncEnabled: Bool = false,
        minutesOfDay: Int = LiveSkyTimeResolver.currentMinutesOfDay()
    ) -> LiveSceneDrawColors {
        let bg = SceneRGB(argb: scheme.background)
        let p = SceneRGB(argb: scheme.primary)
        let t = SceneRGB(argb: scheme.secondary)
        let isDark = scheme.isDark
        let isAmoled = scheme.isBlack

        let base: LiveSceneDrawColors
        if isDark {
            let night = isAmoled ? SceneRGB.black : bg.lerp(to: .black, 0.38)
            let lift = isAmoled ? 0.72 : 1.0
            base = LiveSceneDrawColors(
                isDark: true,
                skyTop: night,
                skyUpperMid: night.lerp(to: p, 0.07 * lift),
                skyLowerMid: night.lerp(to: p, 0.15 * lift),
                skyHorizon: night.lerp(to: p.lerp(to: t, 0.35), 0.27 * lift),
                accent: p,
                accent2: t,
                highlight: SceneRGB.white.lerp(to: p, 0.16),
                shade: night.lerp(to: p, 0.24 * lift),
                ink: night.lerp(to: p, 0.08 * lift),
                veil: night
            )
        } else {
            let paper = bg.lerp(to: .white, 0.45)
            base = LiveSceneDrawColors(
                isDark: false,
                skyTop: paper.lerp(to: p, 0.22),
                skyUpperMid: paper.lerp(to: p, 0.13),
                skyLowerMid: paper.lerp(to: p, 0.06),
                skyHorizon: paper.lerp(to: t, 0.03),
                accent: p,
                accent2: t,
                highlight: .white,
                shade: paper.lerp(to: p, 0.26),
                ink: paper.lerp(to: p, 0.50),
                veil: paper
            )
        }

        guard isTimeSyncEnabled else { return base }
        let tint = LiveSkyTimeResolver.timeTint(isDark: isDark, minutesOfDay: minutesOfDay)
        let w = (isAmoled && isDark) ? 0.20 : 0.30
        return LiveSceneDrawColors(
            isDark: base.isDark,
            skyTop: (isAmoled && isDark) ? .black : base.skyTop.lerp(to: tint.skyTop, w),
            skyUpperMid: base.skyUpperMid.lerp(to: tint.skyUpperMid, w),
            skyLowerMid: base.skyLowerMid.lerp(to: tint.skyLowerMid, w),
            skyHorizon: base.skyHorizon.lerp(to: tint.skyHorizon, w),
            accent: base.accent,
            accent2: base.accent2.lerp(to: tint.accentGlow, 0.35),
            highlight: base.highlight,
            shade: base.shade,
            ink: base.ink,
            veil: base.veil
        )
    }
}

struct LiveSkyTint {
    let skyTop: SceneRGB
    let skyUpperMid: SceneRGB
    let skyLowerMid: SceneRGB
    let skyHorizon: SceneRGB
    let accentGlow: SceneRGB

    func blend(to other: LiveSkyTint, _ t: Double) -> LiveSkyTint {
        LiveSkyTint(
            skyTop: skyTop.lerp(to: other.skyTop, t),
            skyUpperMid: skyUpperMid.lerp(to: other.skyUpperMid, t),
            skyLowerMid: skyLowerMid.lerp(to: other.skyLowerMid, t),
            skyHorizon: skyHorizon.lerp(to: other.skyHorizon, t),
            accentGlow: accentGlow.lerp(to: other.accentGlow, t)
        )
    }
}

enum LiveSkyPhase {
    case fajrDawn, morningDuha, middayDhuhr, goldenAsr, maghribDusk, ishaNight

    var starVisibility: Double {
        switch self {
        case .fajrDawn: return 0.42
        case .morningDuha, .middayDhuhr: return 0.0
        case .goldenAsr: return 0.08
        case .maghribDusk: return 0.55
        case .ishaNight: return 1.0
        }
    }

    func tint(isDark: Bool) -> LiveSkyTint {
        switch (self, isDark) {
        case (.fajrDawn, false):
            return LiveSkyTint(skyTop: SceneRGB(hex: 0xFFC9D4EE), skyUpperMid: SceneRGB(hex: 0xFFDED8EC), skyLowerMid: SceneRGB(hex: 0xFFF2DFD9), skyHorizon: SceneRGB(hex: 0xFFFCEAD7), accentGlow: SceneRGB(hex: 0xFFE8A47C))
        case (.fajrDawn, true):
            return LiveSkyTint(skyTop: SceneRGB(hex: 0xFF090E1E), skyUpperMid: SceneRGB(hex: 0xFF161B33), skyLowerMid: SceneRGB(hex: 0xFF2B263D), skyHorizon: SceneRGB(hex: 0xFF4A333B), accentGlow: SceneRGB(hex: 0xFFE59A73))
        case (.morningDuha, false):
            return LiveSkyTint(skyTop: SceneRGB(hex: 0xFFC4E1F7), skyUpperMid: SceneRGB(hex: 0xFFD9EDFC), skyLowerMid: SceneRGB(hex: 0xFFEBF6FE), skyHorizon: SceneRGB(hex: 0xFFFFFBF2), accentGlow: SceneRGB(hex: 0xFFF2C46D))
        case (.morningDuha, true):
            return LiveSkyTint(skyTop: SceneRGB(hex: 0xFF0B1628), skyUpperMid: SceneRGB(hex: 0xFF132640), skyLowerMid: SceneRGB(hex: 0xFF1D3654), skyHorizon: SceneRGB(hex: 0xFF2B4763), accentGlow: SceneRGB(hex: 0xFFE8BE6B))
        case (.middayDhuhr, false):
            return LiveSkyTint(skyTop: SceneRGB(hex: 0xFFBDDDF7), skyUpperMid: SceneRGB(hex: 0xFFD3EAFB), skyLowerMid: SceneRGB(hex: 0xFFE7F4FD), skyHorizon: SceneRGB(hex: 0xFFF7FBFF), accentGlow: SceneRGB(hex: 0xFF4EA5E8))
        case (.middayDhuhr, true):
            return LiveSkyTint(skyTop: SceneRGB(hex: 0xFF0A1424), skyUpperMid: SceneRGB(hex: 0xFF11223B), skyLowerMid: SceneRGB(hex: 0xFF193252), skyHorizon: SceneRGB(hex: 0xFF234369), accentGlow: SceneRGB(hex: 0xFF68B5F2))
        case (.goldenAsr, false):
            return LiveSkyTint(skyTop: SceneRGB(hex: 0xFFD9D8EC), skyUpperMid: SceneRGB(hex: 0xFFEBE1D8), skyLowerMid: SceneRGB(hex: 0xFFF7E8CE), skyHorizon: SceneRGB(hex: 0xFFFFF3DC), accentGlow: SceneRGB(hex: 0xFFE8A248))
        case (.goldenAsr, true):
            return LiveSkyTint(skyTop: SceneRGB(hex: 0xFF101121), skyUpperMid: SceneRGB(hex: 0xFF1E1A2B), skyLowerMid: SceneRGB(hex: 0xFF33252B), skyHorizon: SceneRGB(hex: 0xFF4D3226), accentGlow: SceneRGB(hex: 0xFFE6A14C))
        case (.maghribDusk, false):
            return LiveSkyTint(skyTop: SceneRGB(hex: 0xFFC8C5E4), skyUpperMid: SceneRGB(hex: 0xFFE0C8DC), skyLowerMid: SceneRGB(hex: 0xFFF4D3CD), skyHorizon: SceneRGB(hex: 0xFFFCE2C9), accentGlow: SceneRGB(hex: 0xFFE27A68))
        case (.maghribDusk, true):
            return LiveSkyTint(skyTop: SceneRGB(hex: 0xFF0B0A1A), skyUpperMid: SceneRGB(hex: 0xFF1B132B), skyLowerMid: SceneRGB(hex: 0xFF331C31), skyHorizon: SceneRGB(hex: 0xFF52282E), accentGlow: SceneRGB(hex: 0xFFE8806B))
        case (.ishaNight, false):
            return LiveSkyTint(skyTop: SceneRGB(hex: 0xFFD0D8EE), skyUpperMid: SceneRGB(hex: 0xFFDDE4F5), skyLowerMid: SceneRGB(hex: 0xFFEAEEF9), skyHorizon: SceneRGB(hex: 0xFFF5F7FC), accentGlow: SceneRGB(hex: 0xFFD6AC54))
        case (.ishaNight, true):
            return LiveSkyTint(skyTop: SceneRGB(hex: 0xFF050812), skyUpperMid: SceneRGB(hex: 0xFF0A1021), skyLowerMid: SceneRGB(hex: 0xFF111A33), skyHorizon: SceneRGB(hex: 0xFF192647), accentGlow: SceneRGB(hex: 0xFFE6C16A))
        }
    }
}

enum LiveSkyTimeResolver {
    static func currentMinutesOfDay() -> Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: Date())
        return (comps.hour ?? 12) * 60 + (comps.minute ?? 0)
    }

    static func phaseBlend(for minutesOfDay: Int) -> (LiveSkyPhase, LiveSkyPhase, Double) {
        let m = ((minutesOfDay % 1440) + 1440) % 1440
        switch m {
        case 255..<390:
            return (.fajrDawn, .morningDuha, smoothStep(Double(m - 255) / 135.0))
        case 390..<690:
            return (.morningDuha, .middayDhuhr, smoothStep(min(1.0, max(0.0, Double(m - 600) / 90.0))))
        case 690..<915:
            return (.middayDhuhr, .goldenAsr, smoothStep(min(1.0, max(0.0, Double(m - 840) / 75.0))))
        case 915..<1065:
            return (.goldenAsr, .maghribDusk, smoothStep(min(1.0, max(0.0, Double(m - 990) / 75.0))))
        case 1065..<1185:
            return (.maghribDusk, .ishaNight, smoothStep(Double(m - 1065) / 120.0))
        default:
            let t = (m >= 210 && m < 255) ? Double(m - 210) / 45.0 : 0.0
            return (.ishaNight, .fajrDawn, smoothStep(t))
        }
    }

    static func timeTint(isDark: Bool, minutesOfDay: Int = currentMinutesOfDay()) -> LiveSkyTint {
        let (a, b, t) = phaseBlend(for: minutesOfDay)
        return a.tint(isDark: isDark).blend(to: b.tint(isDark: isDark), t)
    }

    static func starVisibility(minutesOfDay: Int = currentMinutesOfDay()) -> Double {
        let (a, b, t) = phaseBlend(for: minutesOfDay)
        return a.starVisibility + (b.starVisibility - a.starVisibility) * t
    }

    private static func smoothStep(_ x: Double) -> Double {
        let c = min(1.0, max(0.0, x))
        return c * c * (3.0 - 2.0 * c)
    }
}

enum LiveSceneToolkit {
    static let restSeconds: Double = 4.2
    static let twoPi: Double = 2.0 * .pi
    private static let softStops: [Double] = [0.0, 0.15, 0.30, 0.46, 0.62, 0.76, 0.90, 1.0]

    static func hash(_ index: Int, _ salt: Int) -> Double {
        var x = Int32(truncatingIfNeeded: index) &* Int32(bitPattern: 374_761_393)
            &+ Int32(truncatingIfNeeded: salt) &* Int32(bitPattern: 668_265_263)
        let u1 = UInt32(bitPattern: x) >> 13
        x = (x ^ Int32(bitPattern: u1)) &* Int32(bitPattern: 1_274_126_177)
        let u2 = UInt32(bitPattern: x) >> 16
        x = x ^ Int32(bitPattern: u2)
        return Double(x & 0x7FFF_FFFF) / 2_147_483_647.0
    }

    static func softAbs(_ v: Double, round: Double = 0.12) -> Double {
        (sqrt(v * v + round * round) - round) / (sqrt(1.0 + round * round) - round)
    }

    static func calmMask(yn: Double, center: Double = 0.48, halfSpan: Double = 0.22, dip: Double = 0.42) -> Double {
        let span = max(0.01, halfSpan)
        let dist = abs(yn - center) / span
        if dist >= 1.0 { return 1.0 }
        let t = 1.0 - dist
        let smooth = t * t * (3.0 - 2.0 * t)
        return min(1.0, max(0.0, 1.0 - min(1.0, max(0.0, dip)) * smooth))
    }

    static func softRadialGradient(
        color: SceneRGB,
        peakAlpha: Double,
        edgeTint: SceneRGB? = nil
    ) -> Gradient {
        let peak = min(1.0, max(0.0, peakAlpha))
        let edge = edgeTint ?? color
        let stops = softStops.map { r -> Gradient.Stop in
            let falloff = r >= 1.0 ? 0.0 : pow(1.0 - r * r, 2.4)
            let tint = edgeTint == nil ? color : color.lerp(to: edge, r)
            return Gradient.Stop(color: tint.color(alpha: peak * falloff), location: r)
        }
        return Gradient(stops: stops)
    }

    static func drawSoftDisc(
        ctx: inout GraphicsContext,
        color: SceneRGB,
        peakAlpha: Double,
        edgeTint: SceneRGB? = nil,
        cx: Double,
        cy: Double,
        radius: Double,
        scaleX: Double = 1.0,
        scaleY: Double = 1.0,
        rotationDeg: Double = 0.0,
        alpha: Double = 1.0
    ) {
        let a = min(1.0, max(0.0, alpha))
        guard a > 0.002, radius > 0.5 else { return }
        let grad = softRadialGradient(color: color, peakAlpha: peakAlpha * a, edgeTint: edgeTint)
        var copy = ctx
        copy.translateBy(x: cx, y: cy)
        if rotationDeg != 0 { copy.rotate(by: .degrees(rotationDeg)) }
        if scaleX != 1.0 || scaleY != 1.0 { copy.scaleBy(x: scaleX, y: scaleY) }
        let rect = CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2)
        copy.fill(
            Path(ellipseIn: rect),
            with: .radialGradient(grad, center: .zero, startRadius: 0, endRadius: radius)
        )
    }

    /// Quadratic B-spline through midpoints so sampled ridges, waves, and hems stay corner-free.
    static func smoothCurvePath(points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        if points.count == 1 { return path }
        for i in 1..<points.count {
            let prev = points[i - 1]
            let curr = points[i]
            let mid = CGPoint(x: (prev.x + curr.x) * 0.5, y: (prev.y + curr.y) * 0.5)
            if i == 1 {
                path.addLine(to: mid)
            } else {
                path.addQuadCurve(to: mid, control: prev)
            }
        }
        if let last = points.last {
            path.addLine(to: last)
        }
        return path
    }

    static func closedSmoothBlob(xs: [Double], ys: [Double]) -> Path {
        var path = Path()
        let n = min(xs.count, ys.count)
        guard n >= 3 else { return path }
        path.move(to: CGPoint(x: (xs[n - 1] + xs[0]) * 0.5, y: (ys[n - 1] + ys[0]) * 0.5))
        for i in 0..<n {
            let next = (i + 1) % n
            let mid = CGPoint(x: (xs[i] + xs[next]) * 0.5, y: (ys[i] + ys[next]) * 0.5)
            path.addQuadCurve(to: mid, control: CGPoint(x: xs[i], y: ys[i]))
        }
        path.closeSubpath()
        return path
    }

    static func buildRidgeAndRibbon(
        w: Double,
        h: Double,
        steps: Int,
        ribbonMaxDepth: Double,
        topLiftFactor: Double = 0.12,
        minEdgeTaper: Double = 0.15,
        elevationAt: (Double) -> Double
    ) -> (ridge: Path, ribbon: Path) {
        var topPoints: [CGPoint] = []
        var ribbonTop: [CGPoint] = []
        var ribbonBot: [CGPoint] = []
        topPoints.reserveCapacity(steps + 1)
        ribbonTop.reserveCapacity(steps + 1)
        ribbonBot.reserveCapacity(steps + 1)

        for i in 0...steps {
            let xn = Double(i) / Double(steps)
            let x = w * xn
            let y = elevationAt(xn)
            topPoints.append(CGPoint(x: x, y: y))
            ribbonTop.append(CGPoint(x: x, y: y - ribbonMaxDepth * topLiftFactor))
            let taper = min(1.0, max(minEdgeTaper, sin(xn * .pi)))
            ribbonBot.append(CGPoint(x: x, y: y + ribbonMaxDepth * taper))
        }

        var ridge = smoothCurvePath(points: topPoints)
        ridge.addLine(to: CGPoint(x: w, y: h))
        ridge.addLine(to: CGPoint(x: 0, y: h))
        ridge.closeSubpath()

        var ribbon = smoothCurvePath(points: ribbonTop)
        let rev = ribbonBot.reversed()
        var idx = 0
        var prev = CGPoint.zero
        for pt in rev {
            if idx == 0 {
                ribbon.addLine(to: pt)
            } else {
                let mid = CGPoint(x: (prev.x + pt.x) * 0.5, y: (prev.y + pt.y) * 0.5)
                if idx == 1 {
                    ribbon.addLine(to: mid)
                } else {
                    ribbon.addQuadCurve(to: mid, control: prev)
                }
            }
            prev = pt
            idx += 1
        }
        ribbon.addLine(to: prev)
        ribbon.closeSubpath()
        return (ridge, ribbon)
    }

    static func positiveMod(_ a: Double, _ m: Double) -> Double {
        let r = a.truncatingRemainder(dividingBy: m)
        return r < 0 ? r + m : r
    }
}

struct LiveSceneArtwork: View {
    @Environment(\.sirajTheme) private var theme
    @Environment(\.scenePhase) private var scenePhase

    let themeId: String
    var intensity: LiveBackgroundIntensity = .balanced
    var isTimeSyncEnabled: Bool = false
    var animate: Bool = true
    var fps: Double = 30.0
    var speedScale: Double = 1.0

    var body: some View {
        let def = LiveThemeCatalog.definition(for: themeId)
        let minutes = LiveSkyTimeResolver.currentMinutesOfDay()
        let colors = LiveSceneDrawColors.resolve(
            scheme: theme.scheme,
            isTimeSyncEnabled: isTimeSyncEnabled,
            minutesOfDay: minutes
        )
        let paused = !animate || !theme.motionEnabled || scenePhase != .active
        let ownsStars = def.id == "NightStars" || def.id == "Aurora" || def.id == "Space"
        let syncedStars = (isTimeSyncEnabled && !ownsStars)
            ? LiveSkyTimeResolver.starVisibility(minutesOfDay: minutes) * (colors.isDark ? 0.55 : 0.10)
            : 0.0

        TimelineView(.animation(minimumInterval: 1.0 / max(5.0, fps), paused: paused)) { timeline in
            let t = paused
                ? LiveSceneToolkit.restSeconds
                : (timeline.date.timeIntervalSinceReferenceDate * intensity.motionScale * speedScale)
                    .truncatingRemainder(dividingBy: 36_000.0)
            Canvas { ctx, size in
                guard size.width >= 2, size.height >= 2 else { return }
                drawSky(ctx: &ctx, size: size, colors: colors, syncedStars: syncedStars, t: t, detail: intensity.detailAlphaScale)
                drawScene(ctx: &ctx, size: size, id: def.id, colors: colors, t: t, detail: intensity.detailAlphaScale)
            }
        }
    }

    private func drawSky(
        ctx: inout GraphicsContext,
        size: CGSize,
        colors: LiveSceneDrawColors,
        syncedStars: Double,
        t: Double,
        detail: Double
    ) {
        let grad = Gradient(stops: [
            .init(color: colors.skyTop.color(), location: 0.00),
            .init(color: colors.skyTop.lerp(to: colors.skyUpperMid, 0.50).color(), location: 0.17),
            .init(color: colors.skyUpperMid.color(), location: 0.34),
            .init(color: colors.skyUpperMid.lerp(to: colors.skyLowerMid, 0.50).color(), location: 0.51),
            .init(color: colors.skyLowerMid.color(), location: 0.68),
            .init(color: colors.skyLowerMid.lerp(to: colors.skyHorizon, 0.50).color(), location: 0.84),
            .init(color: colors.skyHorizon.color(), location: 1.00)
        ])
        ctx.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(grad, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height))
        )

        if syncedStars > 0.02 {
            let w = Double(size.width)
            let h = Double(size.height)
            for i in 0..<22 {
                let sx = LiveSceneToolkit.hash(i, 11) * w
                let sy = LiveSceneToolkit.hash(i, 23) * h * 0.55
                let twinkle = 0.4 + 0.6 * (0.5 + 0.5 * sin(t * 0.85 + Double(i) * 1.6))
                let r: Double = i % 5 == 0 ? 1.8 : 1.15
                let a = min(0.75, max(0.0, syncedStars * twinkle * detail))
                ctx.fill(
                    Path(ellipseIn: CGRect(x: sx - r, y: sy - r, width: r * 2, height: r * 2)),
                    with: .color(colors.highlight.color(alpha: a))
                )
            }
        }
    }

    private func drawScene(
        ctx: inout GraphicsContext,
        size: CGSize,
        id: String,
        colors: LiveSceneDrawColors,
        t: Double,
        detail: Double
    ) {
        switch id {
        case "DesertDunes": LiveScenesNature.drawDesertDunes(ctx: &ctx, size: size, colors: colors, t: t, detail: detail)
        case "SeaWaves": LiveScenesNature.drawSeaWaves(ctx: &ctx, size: size, colors: colors, t: t, detail: detail)
        case "Aurora": LiveScenesNature.drawAurora(ctx: &ctx, size: size, colors: colors, t: t, detail: detail)
        case "NightStars": LiveScenesNature.drawNightStars(ctx: &ctx, size: size, colors: colors, t: t, detail: detail)
        case "RosePetals": LiveScenesNature.drawRosePetals(ctx: &ctx, size: size, colors: colors, t: t, detail: detail)
        case "Snow": LiveScenesNature.drawSnow(ctx: &ctx, size: size, colors: colors, t: t, detail: detail)
        case "PurpleButterflies": LiveScenesNature.drawButterflies(ctx: &ctx, size: size, colors: colors, t: t, detail: detail)
        case "Rings": LiveScenesAmbient.drawRings(ctx: &ctx, size: size, colors: colors, t: t, detail: detail)
        case "Circles": LiveScenesAmbient.drawCircles(ctx: &ctx, size: size, colors: colors, t: t, detail: detail)
        case "Particles": LiveScenesAmbient.drawParticles(ctx: &ctx, size: size, colors: colors, t: t, detail: detail)
        case "LavaLamp": LiveScenesAmbient.drawLavaLamp(ctx: &ctx, size: size, colors: colors, t: t, detail: detail)
        case "Space": LiveScenesAmbient.drawSpace(ctx: &ctx, size: size, colors: colors, t: t, detail: detail)
        case "Silk": LiveScenesStudio.drawSilk(ctx: &ctx, size: size, colors: colors, t: t, detail: detail)
        case "Contours": LiveScenesStudio.drawContours(ctx: &ctx, size: size, colors: colors, t: t, detail: detail)
        case "Mosaic": LiveScenesStudio.drawMosaic(ctx: &ctx, size: size, colors: colors, t: t, detail: detail)
        case "Waves": LiveScenesStudio.drawWaves(ctx: &ctx, size: size, colors: colors, t: t, detail: detail)
        case "Harvest": LiveScenesStudio.drawHarvest(ctx: &ctx, size: size, colors: colors, t: t, detail: detail)
        default: LiveScenesNature.drawDesertDunes(ctx: &ctx, size: size, colors: colors, t: t, detail: detail)
        }
    }
}

struct LiveThemeBackdrop: View {
    @Environment(\.sirajTheme) private var theme

    let themeId: String
    let intensity: LiveBackgroundIntensity
    var isTimeSyncEnabled: Bool = false
    var activePrayer: PrayerType? = nil

    var body: some View {
        let colors = LiveSceneDrawColors.resolve(
            scheme: theme.scheme,
            isTimeSyncEnabled: isTimeSyncEnabled
        )
        let adj = intensity.veilAdjustment
        let topAlpha = theme.isGlass
            ? min(0.42, max(0.04, (theme.isDark ? 0.20 : 0.14) + adj))
            : min(0.52, max(0.08, (theme.isDark ? 0.30 : 0.24) + adj))
        let midAlpha = theme.isGlass
            ? min(0.26, max(0.00, (theme.isDark ? 0.06 : 0.05) + adj * 0.6))
            : min(0.38, max(0.03, (theme.isDark ? 0.16 : 0.14) + adj))
        let botAlpha = theme.isGlass
            ? min(0.46, max(0.06, (theme.isDark ? 0.24 : 0.16) + adj))
            : min(0.54, max(0.10, (theme.isDark ? 0.32 : 0.24) + adj))
        let upperMidAlpha = min(1.0, max(0.0, topAlpha * 0.44 + midAlpha * 0.56))
        let lowerMidAlpha = min(1.0, max(0.0, midAlpha * 0.52 + botAlpha * 0.48))

        ZStack {
            LiveSceneArtwork(
                themeId: themeId,
                intensity: intensity,
                isTimeSyncEnabled: isTimeSyncEnabled,
                animate: true,
                fps: 30.0
            )
            LinearGradient(
                stops: [
                    .init(color: colors.veil.color(alpha: topAlpha), location: 0.00),
                    .init(color: colors.veil.color(alpha: upperMidAlpha), location: 0.22),
                    .init(color: colors.veil.color(alpha: midAlpha), location: 0.46),
                    .init(color: colors.veil.color(alpha: lowerMidAlpha), location: 0.73),
                    .init(color: colors.veil.color(alpha: botAlpha), location: 1.00)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

struct LiveScenePicker: View {
    @Environment(\.sirajTheme) private var theme
    let selectedSceneId: String?
    let onSelect: (String?) -> Void

    var body: some View {
        let colors = LiveSceneDrawColors.resolve(scheme: theme.scheme)
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                sceneTile(
                    label: theme.t("looks_background_plain"),
                    isSelected: selectedSceneId == nil,
                    onTap: { onSelect(nil) }
                ) {
                    LinearGradient(
                        colors: [
                            colors.veil.lerp(to: colors.accent, colors.isDark ? 0.10 : 0.06).color(),
                            colors.veil.color()
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

                ForEach(LiveThemeCatalog.all) { scene in
                    let isSelected = selectedSceneId == scene.id
                    sceneTile(
                        label: theme.t(scene.titleKey),
                        isSelected: isSelected,
                        onTap: { onSelect(scene.id) }
                    ) {
                        LiveSceneArtwork(
                            themeId: scene.id,
                            intensity: .vivid,
                            isTimeSyncEnabled: false,
                            animate: true,
                            fps: 15.0
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func sceneTile<Artwork: View>(
        label: String,
        isSelected: Bool,
        onTap: @escaping () -> Void,
        @ViewBuilder artwork: () -> Artwork
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        return Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    artwork()
                        .frame(width: 82, height: 110)
                        .clipShape(shape)
                        .overlay {
                            shape.strokeBorder(
                                isSelected ? theme.primary : theme.outlineVariant.opacity(0.55),
                                lineWidth: isSelected ? 2 : 1
                            )
                        }
                        .scaleEffect(isSelected ? 1.0 : 0.96)

                    if isSelected {
                        ZStack {
                            Circle().fill(theme.primary).frame(width: 20, height: 20)
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(theme.onPrimary)
                        }
                        .padding(7)
                    }
                }

                Text(label)
                    .font(theme.scaledFont(size: 11.5, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? theme.onSurface : theme.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 82, height: 30, alignment: .top)
            }
            .padding(2)
        }
        .buttonStyle(.plain)
        .animation(theme.motionEnabled ? .easeOut(duration: 0.22) : nil, value: isSelected)
    }
}
