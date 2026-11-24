import SwiftUI

enum LiveScenesNature {

    // MARK: - 1. Desert Dunes & Sky Lanterns

    private struct LanternFlight {
        let xBase: Double
        let phase: Double
        let speed: Double
        let scale: Double
        let swayAmp: Double
        let swayFreq: Double
        let flickerOffset: Double
        let layer: Int
    }

    private static let lanternFlights: [LanternFlight] = [
        LanternFlight(xBase: 0.18, phase: 0.84, speed: 0.0046, scale: 0.44, swayAmp: 0.012, swayFreq: 0.26, flickerOffset: 0.4, layer: 0),
        LanternFlight(xBase: 0.56, phase: 0.92, speed: 0.0052, scale: 0.40, swayAmp: 0.010, swayFreq: 0.24, flickerOffset: 1.9, layer: 0),
        LanternFlight(xBase: 0.84, phase: 0.72, speed: 0.0048, scale: 0.46, swayAmp: 0.014, swayFreq: 0.28, flickerOffset: 3.2, layer: 0),
        LanternFlight(xBase: 0.17, phase: 0.18, speed: 0.0068, scale: 0.78, swayAmp: 0.018, swayFreq: 0.31, flickerOffset: 1.1, layer: 1),
        LanternFlight(xBase: 0.83, phase: 0.34, speed: 0.0074, scale: 0.74, swayAmp: 0.019, swayFreq: 0.29, flickerOffset: 2.7, layer: 1),
        LanternFlight(xBase: 0.24, phase: 0.66, speed: 0.0064, scale: 0.70, swayAmp: 0.016, swayFreq: 0.33, flickerOffset: 4.4, layer: 1),
        LanternFlight(xBase: 0.76, phase: 0.10, speed: 0.0088, scale: 1.04, swayAmp: 0.021, swayFreq: 0.27, flickerOffset: 5.1, layer: 2)
    ]

    static func drawDesertDunes(
        ctx: inout GraphicsContext,
        size: CGSize,
        colors: LiveSceneDrawColors,
        t: Double,
        detail: Double
    ) {
        let w = Double(size.width)
        let h = Double(size.height)
        let minDim = min(w, h)
        let k = min(1.35, max(0.40, detail))
        let isDark = colors.isDark

        let lanternWarm = SceneRGB(hex: 0xFFFFB24D)
        let lanternAmber = lanternWarm.lerp(to: colors.accent, 0.22)
        let lanternCore = SceneRGB(hex: 0xFFFFEECB)
        let lanternSilkTop = SceneRGB(hex: 0xFFC85D2C).lerp(to: colors.accent, 0.20)
        let lanternSilkBottom = SceneRGB(hex: 0xFFFFD07B)

        // Subtle distant stars
        let starTint = colors.highlight.lerp(to: lanternCore, 0.18)
        let starAlphaScale = isDark ? 0.50 : 0.16
        for i in 0..<18 {
            let xn = 0.05 + 0.90 * LiveSceneToolkit.hash(i, 11)
            let yn = 0.04 + 0.34 * LiveSceneToolkit.hash(i, 23)
            let r = minDim * (0.0014 + 0.0018 * LiveSceneToolkit.hash(i, 37))
            let phase = LiveSceneToolkit.hash(i, 53) * LiveSceneToolkit.twoPi
            let twinkle = 0.48 + 0.52 * sin(t * 0.65 + phase)
            let calm = LiveSceneToolkit.calmMask(yn: yn, center: 0.48, halfSpan: 0.22, dip: 0.72)
            let a = starAlphaScale * twinkle * calm * k
            if a > 0.01 {
                ctx.fill(
                    Path(ellipseIn: CGRect(x: w * xn - r, y: h * yn - r, width: r * 2, height: r * 2)),
                    with: .color(starTint.color(alpha: a))
                )
            }
        }

        // High distant bokeh embers
        for i in 0..<4 {
            let baseX = 0.10 + 0.80 * LiveSceneToolkit.hash(i, 71)
            let phase = LiveSceneToolkit.hash(i, 89)
            let speed = 0.0020 + 0.0018 * LiveSceneToolkit.hash(i, 101)
            let rad = minDim * (0.016 + 0.022 * LiveSceneToolkit.hash(i, 113))
            let drift = LiveSceneToolkit.positiveMod(phase + t * speed, 1.15)
            let yn = 0.28 - drift * 0.26
            let xn = baseX + 0.014 * sin(t * 0.22 + Double(i) * 1.4)
            let pulse = 0.68 + 0.32 * sin(t * 0.35 + Double(i) * 2.1)
            LiveSceneToolkit.drawSoftDisc(
                ctx: &ctx,
                color: lanternAmber,
                peakAlpha: (isDark ? 0.16 : 0.12) * k,
                edgeTint: lanternSilkTop,
                cx: w * xn,
                cy: h * yn,
                radius: rad,
                alpha: pulse
            )
        }

        // Valley mist
        let mistGrad = Gradient(stops: [
            .init(color: .clear, location: 0.0),
            .init(color: lanternAmber.lerp(to: colors.skyHorizon, 0.55).color(alpha: (isDark ? 0.10 : 0.14) * k), location: 0.48),
            .init(color: .clear, location: 1.0)
        ])
        ctx.fill(
            Path(CGRect(x: 0, y: h * 0.68, width: w, height: h * 0.24)),
            with: .linearGradient(mistGrad, startPoint: CGPoint(x: 0, y: h * 0.68), endPoint: CGPoint(x: 0, y: h * 0.92))
        )

        // Far dune + tapered crest ribbon
        let far = LiveSceneToolkit.buildRidgeAndRibbon(w: w, h: h, steps: 72, ribbonMaxDepth: h * 0.012, topLiftFactor: 0.14) { xn in
            h * 0.77 + h * 0.036 * sin(xn * 3.1 + 0.45) + h * 0.016 * cos(xn * 6.4 + 1.15)
        }
        let farGrad = Gradient(colors: [
            colors.shade.lerp(to: lanternAmber, isDark ? 0.14 : 0.18).color(alpha: (isDark ? 0.78 : 0.40) * k),
            colors.ink.lerp(to: colors.shade, 0.35).color(alpha: (isDark ? 0.90 : 0.56) * k)
        ])
        ctx.fill(far.ridge, with: .linearGradient(farGrad, startPoint: CGPoint(x: 0, y: h * 0.71), endPoint: CGPoint(x: 0, y: h)))
        let crestTint = lanternAmber.lerp(to: colors.highlight, 0.35)
        ctx.fill(
            far.ribbon,
            with: .linearGradient(
                Gradient(colors: [crestTint.color(alpha: (isDark ? 0.18 : 0.22) * k), .clear]),
                startPoint: CGPoint(x: 0, y: h * 0.71),
                endPoint: CGPoint(x: 0, y: h * 0.84)
            )
        )

        // Rising sky lanterns
        for spec in lanternFlights {
            let cycle = LiveSceneToolkit.positiveMod(spec.phase + t * spec.speed, 1.24)
            let yn = 0.94 - cycle * 0.90
            let xn = spec.xBase + spec.swayAmp * sin(t * spec.swayFreq + spec.flickerOffset)
            let edgeFade: Double
            if yn > 0.88 {
                edgeFade = min(1.0, max(0.0, (0.95 - yn) / 0.07))
            } else if yn < 0.08 {
                edgeFade = min(1.0, max(0.0, (yn + 0.04) / 0.12))
            } else {
                edgeFade = 1.0
            }
            let calm = LiveSceneToolkit.calmMask(yn: yn, center: 0.48, halfSpan: 0.25, dip: 0.66)
            let masterAlpha = min(1.0, max(0.0, edgeFade * calm))
            if masterAlpha <= 0.015 { continue }

            let flicker = 0.88 + 0.12 * sin(t * 1.15 + spec.flickerOffset) * cos(t * 0.68 + spec.flickerOffset * 0.6)
            let tiltDeg = 2.4 * cos(t * spec.swayFreq + spec.flickerOffset)
            let lw = minDim * 0.032 * spec.scale
            let lh = lw * 1.44
            let topR = lw * 0.52
            let waistR = lw * 0.60
            let baseR = lw * 0.34
            let topY = -lh * 0.50
            let shoulderY = -lh * 0.28
            let waistY = lh * 0.04
            let botY = lh * 0.48

            var env = Path()
            env.move(to: CGPoint(x: 0, y: topY))
            env.addCurve(to: CGPoint(x: waistR, y: waistY), control1: CGPoint(x: topR * 0.88, y: topY), control2: CGPoint(x: waistR, y: shoulderY))
            env.addCurve(to: CGPoint(x: baseR, y: botY), control1: CGPoint(x: waistR, y: lh * 0.27), control2: CGPoint(x: baseR * 1.18, y: botY * 0.90))
            env.addLine(to: CGPoint(x: -baseR, y: botY))
            env.addCurve(to: CGPoint(x: -waistR, y: waistY), control1: CGPoint(x: -baseR * 1.18, y: botY * 0.90), control2: CGPoint(x: -waistR, y: lh * 0.27))
            env.addCurve(to: CGPoint(x: 0, y: topY), control1: CGPoint(x: -waistR, y: shoulderY), control2: CGPoint(x: -topR * 0.88, y: topY))
            env.closeSubpath()

            let envAlpha: Double = spec.layer == 0 ? 0.55 : (spec.layer == 1 ? 0.84 : 0.92)
            let haloPeak: Double = (spec.layer == 0 ? (isDark ? 0.22 : 0.16) : (spec.layer == 1 ? (isDark ? 0.34 : 0.24) : (isDark ? 0.40 : 0.28))) * k

            var lctx = ctx
            lctx.translateBy(x: w * xn, y: h * yn)
            lctx.rotate(by: .degrees(tiltDeg))

            LiveSceneToolkit.drawSoftDisc(
                ctx: &lctx,
                color: lanternAmber,
                peakAlpha: haloPeak,
                edgeTint: lanternSilkTop,
                cx: 0,
                cy: 0,
                radius: lw * 3.1,
                alpha: masterAlpha * flicker
            )

            let bodyGrad = Gradient(stops: [
                .init(color: lanternSilkTop.color(alpha: envAlpha * 0.72 * masterAlpha), location: 0.0),
                .init(color: lanternAmber.color(alpha: envAlpha * 0.90 * masterAlpha), location: 0.38),
                .init(color: lanternSilkBottom.color(alpha: envAlpha * masterAlpha), location: 0.78),
                .init(color: lanternCore.color(alpha: envAlpha * 0.95 * masterAlpha), location: 1.0)
            ])
            lctx.fill(env, with: .linearGradient(bodyGrad, startPoint: CGPoint(x: 0, y: topY), endPoint: CGPoint(x: 0, y: botY)))

            LiveSceneToolkit.drawSoftDisc(
                ctx: &lctx,
                color: lanternCore,
                peakAlpha: isDark ? 0.62 : 0.50,
                edgeTint: lanternWarm,
                cx: 0,
                cy: lh * 0.20,
                radius: lw * 0.78,
                alpha: masterAlpha * flicker
            )
            LiveSceneToolkit.drawSoftDisc(
                ctx: &lctx,
                color: lanternCore,
                peakAlpha: 0.52,
                edgeTint: lanternAmber,
                cx: 0,
                cy: botY * 0.96,
                radius: baseR * 1.45,
                scaleX: 1.35,
                scaleY: 0.52,
                alpha: masterAlpha * flicker
            )
            let fr = lw * 0.14
            lctx.fill(
                Path(ellipseIn: CGRect(x: -fr, y: botY * 0.96 * 0.86 - fr, width: fr * 2, height: fr * 2)),
                with: .color(lanternCore.color(alpha: masterAlpha * flicker * 0.78))
            )
        }

        // Near dune + tapered crest ribbon
        let near = LiveSceneToolkit.buildRidgeAndRibbon(w: w, h: h, steps: 72, ribbonMaxDepth: h * 0.014, topLiftFactor: 0.14) { xn in
            h * 0.855 + h * 0.032 * sin(xn * 2.5 + 2.35) + h * 0.015 * sin(xn * 5.7 - 0.55)
        }
        let nearGrad = Gradient(colors: [
            colors.ink.lerp(to: colors.shade, 0.42).color(alpha: (isDark ? 0.92 : 0.58) * k),
            colors.ink.color(alpha: (isDark ? 0.97 : 0.72) * k)
        ])
        ctx.fill(near.ridge, with: .linearGradient(nearGrad, startPoint: CGPoint(x: 0, y: h * 0.80), endPoint: CGPoint(x: 0, y: h)))
        ctx.fill(
            near.ribbon,
            with: .linearGradient(
                Gradient(colors: [crestTint.color(alpha: (isDark ? 0.14 : 0.18) * k), .clear]),
                startPoint: CGPoint(x: 0, y: h * 0.80),
                endPoint: CGPoint(x: 0, y: h * 0.92)
            )
        )

        // Twilight fireflies near the dune floor
        let ffHaloR = minDim * 0.017
        let ffCoreR = minDim * 0.0022
        for i in 0..<10 {
            let baseX = 0.07 + 0.86 * LiveSceneToolkit.hash(i, 131)
            let baseY = 0.68 + 0.22 * LiveSceneToolkit.hash(i, 149)
            let phase = LiveSceneToolkit.hash(i, 163) * LiveSceneToolkit.twoPi
            let fx = w * (baseX + 0.018 * sin(t * 0.24 + phase))
            let fy = h * (baseY + 0.014 * cos(t * 0.30 + phase * 1.2))
            let breath = 0.35 + 0.65 * (0.5 + 0.5 * sin(t * 0.72 + phase))
            let calm = LiveSceneToolkit.calmMask(yn: baseY, center: 0.48, halfSpan: 0.24, dip: 0.60)
            let a = min(1.0, max(0.0, breath * calm))
            if a > 0.02 {
                LiveSceneToolkit.drawSoftDisc(
                    ctx: &ctx,
                    color: lanternCore,
                    peakAlpha: (isDark ? 0.42 : 0.28) * k,
                    edgeTint: lanternWarm,
                    cx: fx,
                    cy: fy,
                    radius: ffHaloR,
                    alpha: a
                )
                ctx.fill(
                    Path(ellipseIn: CGRect(x: fx - ffCoreR, y: fy - ffCoreR, width: ffCoreR * 2, height: ffCoreR * 2)),
                    with: .color(lanternCore.color(alpha: a * 0.62 * k))
                )
            }
        }
    }

    // MARK: - 2. Sea & Waves

    private struct OceanSwell {
        let depthFraction: Double
        let ampRatio: Double
        let freqA: Double
        let speedA: Double
        let freqB: Double
        let speedB: Double
        let phaseOffset: Double
    }

    private static let oceanSwells: [OceanSwell] = [
        OceanSwell(depthFraction: 0.00, ampRatio: 0.0040, freqA: 3.4, speedA: 0.24, freqB: 6.2, speedB: -0.16, phaseOffset: 0.2),
        OceanSwell(depthFraction: 0.11, ampRatio: 0.0058, freqA: 3.0, speedA: 0.30, freqB: 5.5, speedB: -0.20, phaseOffset: 1.3),
        OceanSwell(depthFraction: 0.24, ampRatio: 0.0078, freqA: 2.6, speedA: 0.36, freqB: 4.9, speedB: -0.24, phaseOffset: 2.6),
        OceanSwell(depthFraction: 0.39, ampRatio: 0.0102, freqA: 2.3, speedA: 0.42, freqB: 4.3, speedB: -0.28, phaseOffset: 3.9),
        OceanSwell(depthFraction: 0.56, ampRatio: 0.0128, freqA: 2.0, speedA: 0.48, freqB: 3.8, speedB: -0.32, phaseOffset: 0.9),
        OceanSwell(depthFraction: 0.74, ampRatio: 0.0150, freqA: 1.75, speedA: 0.54, freqB: 3.3, speedB: -0.36, phaseOffset: 2.2),
        OceanSwell(depthFraction: 0.90, ampRatio: 0.0168, freqA: 1.50, speedA: 0.60, freqB: 2.9, speedB: -0.40, phaseOffset: 4.4)
    ]

    static func drawSeaWaves(
        ctx: inout GraphicsContext,
        size: CGSize,
        colors: LiveSceneDrawColors,
        t: Double,
        detail: Double
    ) {
        let w = Double(size.width)
        let h = Double(size.height)
        let minDim = min(w, h)
        let k = min(1.35, max(0.40, detail))
        let isDark = colors.isDark

        let horizonY = h * 0.58
        let waterDepth = h - horizonY
        let orbDriftX = w * 0.52 + w * 0.015 * sin(t * 0.22)
        let orbRestY = h * 0.42
        let orbRadius = minDim * 0.115
        let orbColor = colors.highlight.lerp(to: colors.accent, 0.32)

        LiveSceneToolkit.drawSoftDisc(
            ctx: &ctx,
            color: orbColor,
            peakAlpha: (isDark ? 0.16 : 0.24) * k,
            edgeTint: colors.skyLowerMid,
            cx: orbDriftX,
            cy: orbRestY,
            radius: minDim * 0.36
        )

        let diskGrad = Gradient(stops: [
            .init(color: colors.highlight.color(alpha: (isDark ? 0.24 : 0.36) * k), location: 0.0),
            .init(color: colors.accent.lerp(to: colors.highlight, 0.45).color(alpha: (isDark ? 0.12 : 0.20) * k), location: 0.65),
            .init(color: .clear, location: 1.0)
        ])
        ctx.fill(
            Path(ellipseIn: CGRect(x: orbDriftX - orbRadius, y: orbRestY - orbRadius, width: orbRadius * 2, height: orbRadius * 2)),
            with: .linearGradient(diskGrad, startPoint: CGPoint(x: 0, y: orbRestY - orbRadius), endPoint: CGPoint(x: 0, y: orbRestY + orbRadius * 0.9))
        )

        let mistGrad = Gradient(stops: [
            .init(color: .clear, location: 0.0),
            .init(color: colors.skyHorizon.lerp(to: orbColor, 0.25).color(alpha: (isDark ? 0.14 : 0.22) * k), location: 0.45),
            .init(color: .clear, location: 1.0)
        ])
        ctx.fill(
            Path(CGRect(x: 0, y: horizonY - h * 0.07, width: w, height: h * 0.15)),
            with: .linearGradient(mistGrad, startPoint: CGPoint(x: 0, y: horizonY - h * 0.07), endPoint: CGPoint(x: 0, y: horizonY + h * 0.08))
        )

        LiveSceneToolkit.drawSoftDisc(
            ctx: &ctx,
            color: colors.highlight.lerp(to: colors.accent, 0.36),
            peakAlpha: (isDark ? 0.14 : 0.20) * k,
            edgeTint: colors.skyHorizon,
            cx: orbDriftX,
            cy: horizonY + waterDepth * 0.30,
            radius: minDim * 0.32,
            scaleX: 0.72,
            scaleY: 1.15,
            alpha: 0.88 + 0.12 * sin(t * 0.72)
        )

        func swellY(_ spec: OceanSwell, _ xn: Double) -> Double {
            let baseY = horizonY + waterDepth * spec.depthFraction
            let amp = h * spec.ampRatio
            let p1 = sin(xn * LiveSceneToolkit.twoPi * spec.freqA + t * spec.speedA + spec.phaseOffset)
            let p2 = cos(xn * LiveSceneToolkit.twoPi * spec.freqB - t * spec.speedB + spec.phaseOffset * 0.6)
            return baseY + amp * (0.68 * p1 + 0.32 * p2)
        }

        let farTint = colors.accent.lerp(to: colors.skyHorizon, 0.38)
        let midTint = colors.shade.lerp(to: colors.accent, 0.44)
        let deepTint = colors.ink.lerp(to: colors.shade, 0.28)
        let steps = 56

        for (idx, spec) in oceanSwells.enumerated() {
            var pts: [CGPoint] = []
            pts.reserveCapacity(steps + 1)
            for s in 0...steps {
                let x = -w * 0.03 + w * 1.06 * (Double(s) / Double(steps))
                pts.append(CGPoint(x: x, y: swellY(spec, x / w)))
            }
            var path = LiveSceneToolkit.smoothCurvePath(points: pts)
            path.addLine(to: CGPoint(x: pts[steps].x, y: h))
            path.addLine(to: CGPoint(x: pts[0].x, y: h))
            path.closeSubpath()

            let f = spec.depthFraction
            let crestY = horizonY + waterDepth * f - h * spec.ampRatio * 1.4
            let fadeBot = idx >= oceanSwells.count - 2 ? h : min(h, horizonY + waterDepth * (f + 0.32))
            let topC = farTint.lerp(to: deepTint, f * 0.72)
            let midC = midTint.lerp(to: deepTint, f * 0.85)
            let topA = min(0.72, (isDark ? 0.16 + f * 0.22 : 0.20 + f * 0.22) * k)
            let botA = min(0.90, (isDark ? 0.34 + f * 0.34 : 0.30 + f * 0.32) * k)
            let grad = Gradient(stops: [
                .init(color: topC.color(alpha: topA), location: 0.0),
                .init(color: midC.color(alpha: min(0.82, (topA + botA) * 0.55)), location: 0.45),
                .init(color: deepTint.color(alpha: botA), location: 1.0)
            ])
            ctx.fill(path, with: .linearGradient(grad, startPoint: CGPoint(x: 0, y: crestY), endPoint: CGPoint(x: 0, y: fadeBot)))
        }

        let sparkleTint = colors.highlight.lerp(to: colors.accent, 0.22)
        let sparkleR = minDim * 0.0026
        for i in 0..<12 {
            let spec = oceanSwells[min(oceanSwells.count - 1, 2 + (i % 4))]
            let xn = 0.14 + LiveSceneToolkit.hash(i, 97) * 0.72
            let phase = LiveSceneToolkit.hash(i, 103) * LiveSceneToolkit.twoPi
            let cy = swellY(spec, xn)
            let flash = LiveSceneToolkit.softAbs(sin(t * 1.15 + phase))
            let a = min(0.48, max(0.0, flash * flash * 0.42 * k))
            if a > 0.03 {
                let r = sparkleR * (0.7 + 0.5 * flash)
                ctx.fill(
                    Path(ellipseIn: CGRect(x: xn * w - r, y: cy - r, width: r * 2, height: r * 2)),
                    with: .color(sparkleTint.color(alpha: a))
                )
            }
        }
    }

    // MARK: - 3. Aurora

    private struct AuroraCurtain {
        let baseHemY: Double
        let waveAmp: Double
        let freqA: Double
        let speedA: Double
        let freqB: Double
        let speedB: Double
        let phase: Double
        let alphaScale: Double
    }

    private static let auroraCurtains: [AuroraCurtain] = [
        AuroraCurtain(baseHemY: 0.28, waveAmp: 0.042, freqA: 1.6, speedA: 0.14, freqB: 3.1, speedB: -0.09, phase: 0.2, alphaScale: 1.00),
        AuroraCurtain(baseHemY: 0.37, waveAmp: 0.036, freqA: 2.0, speedA: -0.11, freqB: 3.7, speedB: 0.13, phase: 1.8, alphaScale: 0.82)
    ]

    static func drawAurora(
        ctx: inout GraphicsContext,
        size: CGSize,
        colors: LiveSceneDrawColors,
        t: Double,
        detail: Double
    ) {
        let w = Double(size.width)
        let h = Double(size.height)
        let minDim = min(w, h)
        let k = min(1.35, max(0.40, detail))
        let isDark = colors.isDark

        let emerald = SceneRGB(hex: 0xFF3EF0B4).lerp(to: colors.accent, 0.24)
        let cyan = SceneRGB(hex: 0xFF42D6E8).lerp(to: colors.highlight, 0.20)
        let violet = SceneRGB(hex: 0xFF9664F0).lerp(to: colors.accent2, 0.30)

        // Quiet northern stars
        let starTint = colors.highlight.lerp(to: cyan, 0.22)
        let starBase = isDark ? 0.56 : 0.14
        for i in 0..<24 {
            let xn = 0.04 + 0.92 * LiveSceneToolkit.hash(i, 101)
            let yn = 0.03 + 0.44 * LiveSceneToolkit.hash(i, 113)
            let r = minDim * (0.0014 + 0.0018 * LiveSceneToolkit.hash(i, 127))
            let phase = LiveSceneToolkit.hash(i, 139) * LiveSceneToolkit.twoPi
            let twinkle = 0.45 + 0.55 * sin(t * 0.60 + phase)
            let calm = LiveSceneToolkit.calmMask(yn: yn, center: 0.48, halfSpan: 0.22, dip: 0.70)
            let a = starBase * twinkle * calm * k
            if a > 0.01 {
                ctx.fill(
                    Path(ellipseIn: CGRect(x: w * xn - r, y: h * yn - r, width: r * 2, height: r * 2)),
                    with: .color(starTint.color(alpha: a))
                )
            }
        }

        // Upper-sky bloom
        LiveSceneToolkit.drawSoftDisc(
            ctx: &ctx,
            color: violet,
            peakAlpha: (isDark ? 0.15 : 0.12) * k,
            edgeTint: emerald,
            cx: w * (0.48 + 0.04 * sin(t * 0.07)),
            cy: h * 0.18,
            radius: minDim * 0.65,
            scaleX: 1.4,
            scaleY: 0.72,
            alpha: 0.88 + 0.12 * cos(t * 0.11)
        )

        // 2 curtains with 4 bell-weighted feather passes
        let samples = 44
        let featherOffsets = [-h * 0.016, -h * 0.0053, h * 0.0053, h * 0.016]
        let featherWeights = [0.16, 0.34, 0.34, 0.16]
        var hemYs: [[Double]] = [[], []]
        let offTop = -h * 0.12

        for c in 0..<2 {
            let spec = auroraCurtains[c]
            var pts: [CGPoint] = []
            var ys: [Double] = []
            pts.reserveCapacity(samples + 1)
            ys.reserveCapacity(samples + 1)

            for s in 0...samples {
                let xn = Double(s) / Double(samples)
                let w1 = sin(xn * LiveSceneToolkit.twoPi * spec.freqA + t * spec.speedA + spec.phase)
                let w2 = cos(xn * LiveSceneToolkit.twoPi * spec.freqB + t * spec.speedB + spec.phase * 1.3)
                let arch = -h * 0.024 * sin(xn * .pi)
                let y = h * spec.baseHemY + arch + h * spec.waveAmp * (0.64 * w1 + 0.36 * w2)
                ys.append(y)
                pts.append(CGPoint(x: w * xn, y: y))
            }
            hemYs[c] = ys

            var path = LiveSceneToolkit.smoothCurvePath(points: pts)
            path.addLine(to: CGPoint(x: w, y: offTop))
            path.addLine(to: CGPoint(x: 0, y: offTop))
            path.closeSubpath()

            let grad: Gradient
            let startY: Double
            let endY: Double
            if c == 0 {
                grad = Gradient(stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: violet.color(alpha: (isDark ? 0.14 : 0.10) * k), location: 0.26),
                    .init(color: cyan.color(alpha: (isDark ? 0.24 : 0.16) * k), location: 0.68),
                    .init(color: emerald.color(alpha: (isDark ? 0.34 : 0.22) * k), location: 1.0)
                ])
                startY = h * 0.02
                endY = h * 0.36
            } else {
                grad = Gradient(stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: violet.color(alpha: (isDark ? 0.12 : 0.08) * k), location: 0.30),
                    .init(color: emerald.color(alpha: (isDark ? 0.22 : 0.14) * k), location: 0.72),
                    .init(color: cyan.color(alpha: (isDark ? 0.30 : 0.18) * k), location: 1.0)
                ])
                startY = h * 0.08
                endY = h * 0.45
            }

            for p in 0..<4 {
                var pctx = ctx
                pctx.opacity = min(1.0, max(0.0, featherWeights[p] * spec.alphaScale))
                pctx.translateBy(x: 0, y: featherOffsets[p])
                pctx.fill(path, with: .linearGradient(grad, startPoint: CGPoint(x: 0, y: startY), endPoint: CGPoint(x: 0, y: endY)))
            }
        }

        // 12 vertical radial aurora rays
        for i in 0..<12 {
            let cIdx = i % 2
            let baseXn = 0.06 + 0.88 * (Double(i) / 11.0) + (LiveSceneToolkit.hash(i, 19) - 0.5) * 0.05
            let halfW = w * (0.048 + 0.042 * LiveSceneToolkit.hash(i, 31))
            let halfH = h * (0.095 + 0.065 * LiveSceneToolkit.hash(i, 43))
            let phase = LiveSceneToolkit.hash(i, 61) * LiveSceneToolkit.twoPi
            let speed = 0.28 + 0.22 * LiveSceneToolkit.hash(i, 79)

            let xn = min(0.98, max(0.02, baseXn + 0.022 * sin(t * 0.09 + phase)))
            let pos = xn * Double(samples)
            let s0 = min(samples - 1, max(0, Int(pos)))
            let frac = pos - Double(s0)
            let hemY = hemYs[cIdx][s0] * (1.0 - frac) + hemYs[cIdx][s0 + 1] * frac
            let cy = hemY - halfH * 0.58
            let calm = LiveSceneToolkit.calmMask(yn: cy / h, center: 0.50, halfSpan: 0.22, dip: 0.65)
            let shimmer = 0.45 + 0.55 * (0.5 + 0.5 * sin(t * speed + phase))
            let a = min(1.0, max(0.0, shimmer * calm * 0.85))
            if a > 0.015 {
                LiveSceneToolkit.drawSoftDisc(
                    ctx: &ctx,
                    color: i % 2 == 0 ? emerald : cyan,
                    peakAlpha: (i % 2 == 0 ? (isDark ? 0.20 : 0.14) : (isDark ? 0.17 : 0.12)) * k,
                    edgeTint: i % 2 == 0 ? violet : emerald,
                    cx: w * xn,
                    cy: cy,
                    radius: 80.0,
                    scaleX: halfW / 80.0,
                    scaleY: halfH / 80.0,
                    alpha: a
                )
            }
        }

        // Alpine mountains + peak highlight ribbons
        let farM = LiveSceneToolkit.buildRidgeAndRibbon(w: w, h: h, steps: 96, ribbonMaxDepth: h * 0.011) { xn in
            let pA = h * 0.070 * exp(-pow(xn - 0.24, 2) / 0.016)
            let pB = h * 0.085 * exp(-pow(xn - 0.72, 2) / 0.022)
            return h * 0.81 - pA - pB + h * 0.018 * sin(xn * 5.2 + 0.7) + h * 0.008 * cos(xn * 11.4)
        }
        let nearM = LiveSceneToolkit.buildRidgeAndRibbon(w: w, h: h, steps: 96, ribbonMaxDepth: h * 0.013) { xn in
            let pC = h * 0.058 * exp(-pow(xn - 0.48, 2) / 0.020)
            let shL = h * 0.042 * exp(-pow(xn - 0.08, 2) / 0.018)
            return h * 0.88 - pC - shL + h * 0.014 * sin(xn * 4.4 + 2.1)
        }
        let peakHi = emerald.lerp(to: cyan, 0.45)

        ctx.fill(
            farM.ridge,
            with: .linearGradient(
                Gradient(colors: [
                    colors.shade.lerp(to: cyan, isDark ? 0.10 : 0.14).color(alpha: (isDark ? 0.78 : 0.42) * k),
                    colors.ink.lerp(to: colors.shade, 0.3).color(alpha: (isDark ? 0.92 : 0.58) * k)
                ]),
                startPoint: CGPoint(x: 0, y: h * 0.70),
                endPoint: CGPoint(x: 0, y: h)
            )
        )
        ctx.fill(
            farM.ribbon,
            with: .linearGradient(
                Gradient(colors: [peakHi.color(alpha: (isDark ? 0.19 : 0.22) * k), .clear]),
                startPoint: CGPoint(x: 0, y: h * 0.69),
                endPoint: CGPoint(x: 0, y: h * 0.83)
            )
        )
        ctx.fill(
            nearM.ridge,
            with: .linearGradient(
                Gradient(colors: [
                    colors.ink.lerp(to: colors.shade, 0.35).color(alpha: (isDark ? 0.92 : 0.56) * k),
                    colors.ink.color(alpha: (isDark ? 0.98 : 0.72) * k)
                ]),
                startPoint: CGPoint(x: 0, y: h * 0.80),
                endPoint: CGPoint(x: 0, y: h)
            )
        )
        ctx.fill(
            nearM.ribbon,
            with: .linearGradient(
                Gradient(colors: [peakHi.lerp(to: colors.highlight, 0.25).color(alpha: (isDark ? 0.14 : 0.18) * k), .clear]),
                startPoint: CGPoint(x: 0, y: h * 0.79),
                endPoint: CGPoint(x: 0, y: h * 0.92)
            )
        )

        // Quiet ice motes
        let moteR = minDim * 0.013
        let moteColor = cyan.lerp(to: colors.highlight, 0.45)
        for i in 0..<8 {
            let phase = LiveSceneToolkit.hash(i, 181) * LiveSceneToolkit.twoPi
            let mx = w * (0.08 + 0.84 * LiveSceneToolkit.hash(i, 151) + 0.012 * sin(t * 0.20 + phase))
            let yn = 0.66 + 0.22 * LiveSceneToolkit.hash(i, 167) + 0.010 * cos(t * 0.18 + phase * 1.1)
            let breath = 0.40 + 0.60 * (0.5 + 0.5 * sin(t * 0.45 + phase))
            let calm = LiveSceneToolkit.calmMask(yn: yn, center: 0.48, halfSpan: 0.24, dip: 0.65)
            let a = min(1.0, max(0.0, breath * calm * 0.78))
            if a > 0.015 {
                LiveSceneToolkit.drawSoftDisc(
                    ctx: &ctx,
                    color: moteColor,
                    peakAlpha: (isDark ? 0.18 : 0.15) * k,
                    edgeTint: emerald,
                    cx: mx,
                    cy: h * yn,
                    radius: moteR,
                    alpha: a
                )
            }
        }
    }

    // MARK: - 4. Night Stars

    static func drawNightStars(
        ctx: inout GraphicsContext,
        size: CGSize,
        colors: LiveSceneDrawColors,
        t: Double,
        detail: Double
    ) {
        let w = Double(size.width)
        let h = Double(size.height)
        let minDim = min(w, h)
        let k = min(1.35, max(0.40, detail))
        let isDark = colors.isDark

        let starWhite = colors.highlight.lerp(to: .white, 0.40)
        let starWarm = colors.highlight.lerp(to: SceneRGB(hex: 0xFFFFDFB0), 0.35)
        let starCool = colors.highlight.lerp(to: colors.accent, 0.32)
        let nebula = colors.accent.lerp(to: colors.accent2, 0.42)

        // Milky Way radial haze clouds
        let milkyXn = [0.14, 0.32, 0.50, 0.68, 0.85]
        let milkyYn = [0.32, 0.26, 0.20, 0.14, 0.09]
        let milkySX = [1.45, 1.65, 1.55, 1.40, 1.30]
        let milkySY = [0.62, 0.68, 0.60, 0.56, 0.52]
        let milkyR = minDim * 0.24
        let milkyBreath = 0.92 + 0.08 * sin(t * 0.09)
        for i in 0..<5 {
            let cx = w * (milkyXn[i] + 0.008 * sin(t * 0.06 + Double(i) * 1.1))
            let cy = h * milkyYn[i]
            LiveSceneToolkit.drawSoftDisc(
                ctx: &ctx,
                color: i % 2 == 0 ? nebula : colors.highlight.lerp(to: nebula, 0.55),
                peakAlpha: (i % 2 == 0 ? (isDark ? 0.11 : 0.08) : (isDark ? 0.09 : 0.06)) * k,
                edgeTint: i % 2 == 0 ? colors.skyUpperMid : nebula,
                cx: cx,
                cy: cy,
                radius: milkyR,
                scaleX: milkySX[i],
                scaleY: milkySY[i],
                rotationDeg: -22,
                alpha: milkyBreath
            )
        }

        // Far stars
        let baseSkyA = isDark ? 0.64 : 0.18
        for i in 0..<42 {
            let xn = 0.03 + 0.94 * LiveSceneToolkit.hash(i, 13)
            let yn = 0.02 + 0.68 * LiveSceneToolkit.hash(i, 29)
            let r = minDim * (0.0011 + 0.0013 * LiveSceneToolkit.hash(i, 41))
            let phase = LiveSceneToolkit.hash(i, 59) * LiveSceneToolkit.twoPi
            let speed = 0.30 + 0.35 * LiveSceneToolkit.hash(i, 73)
            let depthAtten = yn > 0.48 ? min(1.0, max(0.0, 1.0 - (yn - 0.48) / 0.24)) : 1.0
            let calm = LiveSceneToolkit.calmMask(yn: yn, center: 0.50, halfSpan: 0.24, dip: 0.74)
            let twinkle = 0.52 + 0.48 * sin(t * speed + phase)
            let a = baseSkyA * twinkle * depthAtten * calm * k
            if a > 0.01 {
                ctx.fill(
                    Path(ellipseIn: CGRect(x: w * xn - r, y: h * yn - r, width: r * 2, height: r * 2)),
                    with: .color(starWhite.color(alpha: a))
                )
            }
        }

        // Mid stars
        for i in 0..<22 {
            let xn = 0.04 + 0.92 * LiveSceneToolkit.hash(i, 97)
            let yn = 0.03 + 0.62 * LiveSceneToolkit.hash(i, 113)
            let r = minDim * (0.0018 + 0.0016 * LiveSceneToolkit.hash(i, 131))
            let phase = LiveSceneToolkit.hash(i, 149) * LiveSceneToolkit.twoPi
            let speed = 0.38 + 0.40 * LiveSceneToolkit.hash(i, 163)
            let warmth = LiveSceneToolkit.hash(i, 179)
            let calm = LiveSceneToolkit.calmMask(yn: yn, center: 0.50, halfSpan: 0.24, dip: 0.76)
            let twinkle = 0.45 + 0.55 * sin(t * speed + phase)
            let a = baseSkyA * 1.15 * twinkle * calm * k
            if a > 0.01 {
                let tint = starCool.lerp(to: starWarm, warmth)
                ctx.fill(
                    Path(ellipseIn: CGRect(x: w * xn - r, y: h * yn - r, width: r * 2, height: r * 2)),
                    with: .color(tint.color(alpha: a))
                )
            }
        }

        // 7 hero halo stars
        let heroHaloR = minDim * 0.022
        let heroCoreR = minDim * 0.0024
        for i in 0..<7 {
            let xn = 0.08 + 0.72 * LiveSceneToolkit.hash(i, 193)
            let yn = 0.05 + 0.36 * LiveSceneToolkit.hash(i, 211)
            let phase = LiveSceneToolkit.hash(i, 229) * LiveSceneToolkit.twoPi
            let warm = LiveSceneToolkit.hash(i, 241) > 0.5
            let calm = LiveSceneToolkit.calmMask(yn: yn, center: 0.50, halfSpan: 0.24, dip: 0.70)
            let pulse = 0.58 + 0.42 * sin(t * 0.48 + phase)
            let px = w * xn
            let py = h * yn
            LiveSceneToolkit.drawSoftDisc(
                ctx: &ctx,
                color: warm ? starWarm : starCool,
                peakAlpha: (warm ? (isDark ? 0.42 : 0.24) : (isDark ? 0.40 : 0.22)) * k,
                edgeTint: warm ? colors.accent : nebula,
                cx: px,
                cy: py,
                radius: heroHaloR,
                scaleX: 0.85 + 0.25 * pulse,
                scaleY: 0.85 + 0.25 * pulse,
                alpha: pulse * calm
            )
            let coreA = (isDark ? 0.82 : 0.40) * pulse * calm * k
            if coreA > 0.01 {
                ctx.fill(
                    Path(ellipseIn: CGRect(x: px - heroCoreR, y: py - heroCoreR, width: heroCoreR * 2, height: heroCoreR * 2)),
                    with: .color(starWhite.color(alpha: coreA))
                )
            }
        }

        // Crescent moon with corona + earthshine
        let moonX = w * 0.78
        let moonY = h * 0.15
        let moonR = minDim * 0.044
        let moonPulse = 0.94 + 0.06 * sin(t * 0.16)
        LiveSceneToolkit.drawSoftDisc(
            ctx: &ctx,
            color: starWarm,
            peakAlpha: (isDark ? 0.16 : 0.18) * k,
            edgeTint: colors.skyUpperMid,
            cx: moonX,
            cy: moonY,
            radius: moonR * 5.6,
            alpha: moonPulse
        )
        LiveSceneToolkit.drawSoftDisc(
            ctx: &ctx,
            color: starWhite,
            peakAlpha: (isDark ? 0.24 : 0.26) * k,
            edgeTint: starWarm,
            cx: moonX,
            cy: moonY,
            radius: moonR * 2.2,
            alpha: moonPulse
        )
        var mctx = ctx
        mctx.translateBy(x: moonX, y: moonY)
        mctx.rotate(by: .degrees(22))
        let esR = moonR * 0.98
        mctx.fill(
            Path(ellipseIn: CGRect(x: -esR, y: -esR, width: esR * 2, height: esR * 2)),
            with: .color(starWhite.color(alpha: (isDark ? 0.035 : 0.040) * k))
        )
        let crescent = moonLimbPath(center: .zero, radius: moonR, phaseFraction: 0.88)
        let kc = min(1.0, max(0.6, k))
        mctx.fill(
            crescent,
            with: .linearGradient(
                Gradient(colors: [
                    starWhite.color(alpha: (isDark ? 0.92 : 0.85) * kc),
                    starWarm.color(alpha: (isDark ? 0.72 : 0.68) * kc)
                ]),
                startPoint: CGPoint(x: -moonR, y: -moonR * 0.5),
                endPoint: CGPoint(x: 0, y: moonR)
            )
        )

        // Rare shooting star every 18s
        let meteorEvery = 18.0
        let meteorDur = 1.15
        let slot = Int(t / meteorEvery)
        let localT = LiveSceneToolkit.positiveMod(t, meteorEvery)
        if localT >= 0.2 && localT <= 0.2 + meteorDur {
            let u = (localT - 0.2) / meteorDur
            let fade = min(1.0, max(0.0, sin(u * .pi)))
            let sx = w * (0.14 + 0.42 * LiveSceneToolkit.hash(slot, 307))
            let sy = h * (0.06 + 0.16 * LiveSceneToolkit.hash(slot, 313))
            let dx = w * 0.22
            let dy = h * 0.10
            let hx = sx + dx * u
            let hy = sy + dy * u
            let tailU = max(0.0, u - 0.34)
            let tx = sx + dx * tailU
            let ty = sy + dy * tailU
            var mp = Path()
            mp.move(to: CGPoint(x: tx, y: ty))
            mp.addLine(to: CGPoint(x: hx, y: hy))
            let peakA = (isDark ? 0.58 : 0.28) * k * fade
            ctx.stroke(
                mp,
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: starCool.color(alpha: peakA * 0.35), location: 0.55),
                        .init(color: starWhite.color(alpha: peakA), location: 1.0)
                    ]),
                    startPoint: CGPoint(x: tx, y: ty),
                    endPoint: CGPoint(x: hx, y: hy)
                ),
                style: StrokeStyle(lineWidth: minDim * 0.0022, lineCap: .round)
            )
        }

        // Rolling hills + soft crest ribbons
        let farH = LiveSceneToolkit.buildRidgeAndRibbon(w: w, h: h, steps: 72, ribbonMaxDepth: h * 0.011) { xn in
            h * 0.80 + h * 0.030 * sin(xn * 3.4 + 0.7) + h * 0.014 * cos(xn * 7.1 - 0.4)
        }
        let nearH = LiveSceneToolkit.buildRidgeAndRibbon(w: w, h: h, steps: 72, ribbonMaxDepth: h * 0.013) { xn in
            h * 0.875 + h * 0.025 * sin(xn * 2.8 + 2.2) + h * 0.010 * sin(xn * 6.2 + 0.9)
        }
        let crestTint = starCool.lerp(to: starWhite, 0.45)

        ctx.fill(
            farH.ridge,
            with: .linearGradient(
                Gradient(colors: [
                    colors.shade.lerp(to: colors.skyHorizon, 0.35).color(alpha: (isDark ? 0.78 : 0.40) * k),
                    colors.ink.color(alpha: (isDark ? 0.92 : 0.58) * k)
                ]),
                startPoint: CGPoint(x: 0, y: h * 0.74),
                endPoint: CGPoint(x: 0, y: h)
            )
        )
        ctx.fill(
            farH.ribbon,
            with: .linearGradient(
                Gradient(colors: [crestTint.color(alpha: (isDark ? 0.16 : 0.18) * k), .clear]),
                startPoint: CGPoint(x: 0, y: h * 0.74),
                endPoint: CGPoint(x: 0, y: h * 0.86)
            )
        )
        ctx.fill(
            nearH.ridge,
            with: .linearGradient(
                Gradient(colors: [
                    colors.ink.lerp(to: colors.shade, 0.32).color(alpha: (isDark ? 0.92 : 0.56) * k),
                    colors.ink.color(alpha: (isDark ? 0.98 : 0.72) * k)
                ]),
                startPoint: CGPoint(x: 0, y: h * 0.82),
                endPoint: CGPoint(x: 0, y: h)
            )
        )
        ctx.fill(
            nearH.ribbon,
            with: .linearGradient(
                Gradient(colors: [crestTint.color(alpha: (isDark ? 0.12 : 0.15) * k), .clear]),
                startPoint: CGPoint(x: 0, y: h * 0.82),
                endPoint: CGPoint(x: 0, y: h * 0.93)
            )
        )
    }

    // MARK: - 5. Rose Petals

    private static let roseBokehX = [0.16, 0.52, 0.88, 0.30, 0.70]
    private static let roseBokehY = [0.09, 0.20, 0.13, 0.30, 0.27]

    private static func roseHedgeProfile(_ a: Double, layer: Int) -> Double {
        0.55 * LiveSceneToolkit.softAbs(sin(1.5 * a + Double(layer) * 1.3))
            + 0.30 * LiveSceneToolkit.softAbs(sin(3.5 * a + 0.8 + Double(layer) * 2.1))
            + 0.15 * sin(2.0 * a + Double(layer) * 0.9)
    }

    private static func rosePetalCalm(_ yn: Double) -> Double {
        let d = (yn - 0.45) / 0.20
        return 1.0 - 0.40 * max(0.0, 1.0 - d * d)
    }

    static func drawRosePetals(
        ctx: inout GraphicsContext,
        size: CGSize,
        colors: LiveSceneDrawColors,
        t: Double,
        detail: Double
    ) {
        let w = Double(size.width)
        let h = Double(size.height)
        let minDim = min(w, h)
        let k = min(1.4, max(0.35, detail))
        let ka = min(1.15, k)
        let dark = colors.isDark

        // Sunlight haze from top-right corner
        let light = CGPoint(x: w * 0.82, y: h * 0.07)
        let hazeR = max(w, h * 0.5) * 0.80
        let hazeTint = colors.accent.lerp(to: colors.highlight, dark ? 0.30 : 0.70)
        let breathe = 0.93 + 0.07 * sin(t * 0.19)
        ctx.fill(
            Path(ellipseIn: CGRect(x: light.x - hazeR, y: light.y - hazeR, width: hazeR * 2, height: hazeR * 2)),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: hazeTint.color(alpha: (dark ? 0.22 : 0.50) * ka * breathe), location: 0.0),
                    .init(color: hazeTint.color(alpha: (dark ? 0.08 : 0.16) * ka * breathe), location: 0.40),
                    .init(color: .clear, location: 1.0)
                ]),
                center: light,
                startRadius: 0,
                endRadius: hazeR
            )
        )

        // 5 soft bokeh discs
        for i in 0..<5 {
            let tint = (i % 2 == 0 ? colors.accent : colors.accent2).lerp(to: colors.highlight, dark ? 0.12 : 0.40)
            let rad = max(0.5, minDim * (0.15 + 0.12 * LiveSceneToolkit.hash(i, 5)))
            let peak = (dark ? 0.16 : 0.26) * ka * (0.72 + 0.28 * sin(t * 0.16 + Double(i) * 1.37))
            let dx = sin(t * 0.07 + Double(i) * 2.1) * w * 0.022
            let dy = sin(t * 0.05 + Double(i) * 1.3 + 1.1) * h * 0.012
            let cx = w * roseBokehX[i] + dx
            let cy = h * roseBokehY[i] + dy
            ctx.fill(
                Path(ellipseIn: CGRect(x: cx - rad, y: cy - rad, width: rad * 2, height: rad * 2)),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: tint.color(alpha: peak), location: 0.0),
                        .init(color: tint.color(alpha: peak * 0.62), location: 0.62),
                        .init(color: tint.color(alpha: peak * 0.10), location: 0.90),
                        .init(color: .clear, location: 1.0)
                    ]),
                    center: CGPoint(x: cx, y: cy),
                    startRadius: 0,
                    endRadius: rad
                )
            )
        }

        // Unit rose petal outline & crease
        let unit = max(0.5, minDim * 0.043)
        var petal = Path()
        petal.move(to: CGPoint(x: 0, y: unit))
        petal.addCurve(to: CGPoint(x: -unit * 0.24, y: -unit * 0.93), control1: CGPoint(x: -unit * 0.95, y: unit * 0.45), control2: CGPoint(x: -unit * 1.05, y: -unit * 0.62))
        petal.addCurve(to: CGPoint(x: 0, y: -unit * 0.72), control1: CGPoint(x: -unit * 0.10, y: -unit * 0.99), control2: CGPoint(x: -unit * 0.04, y: -unit * 0.78))
        petal.addCurve(to: CGPoint(x: unit * 0.24, y: -unit * 0.93), control1: CGPoint(x: unit * 0.04, y: -unit * 0.78), control2: CGPoint(x: unit * 0.10, y: -unit * 0.99))
        petal.addCurve(to: CGPoint(x: 0, y: unit), control1: CGPoint(x: unit * 1.05, y: -unit * 0.62), control2: CGPoint(x: unit * 0.95, y: unit * 0.45))
        petal.closeSubpath()

        var crease = Path()
        crease.move(to: CGPoint(x: 0, y: unit * 0.86))
        crease.addCurve(to: CGPoint(x: 0, y: -unit * 0.50), control1: CGPoint(x: -unit * 0.10, y: unit * 0.40), control2: CGPoint(x: unit * 0.08, y: -unit * 0.10))
        let creaseColor = colors.accent.lerp(to: .black, dark ? 0.24 : 0.20)

        let farBody = colors.accent.lerp(to: colors.skyUpperMid, dark ? 0.36 : 0.30)
        let farGrad = Gradient(colors: [farBody.lerp(to: colors.highlight, 0.42).color(), farBody.color()])
        let nearBody = dark ? colors.accent.lerp(to: colors.highlight, 0.10) : colors.accent
        let nearGrad = Gradient(stops: [
            .init(color: colors.accent.lerp(to: colors.highlight, dark ? 0.58 : 0.46).color(), location: 0.0),
            .init(color: nearBody.color(), location: 0.55),
            .init(color: nearBody.lerp(to: .black, 0.10).color(), location: 1.0)
        ])

        let countScale = min(1.0, k)
        let farCount = min(9, max(5, Int(9.0 * countScale + 0.5)))
        let nearCount = min(6, max(4, Int(6.0 * countScale + 0.5)))
        let farAlpha = min(0.80, (dark ? 0.44 : 0.56) * k)
        let nearAlpha = min(0.95, (dark ? 0.78 : 0.90) * k)

        // Far petals behind hedge
        for i in 0..<farCount {
            let prog = LiveSceneToolkit.positiveMod(LiveSceneToolkit.hash(i, 101) + t * (0.014 + 0.010 * LiveSceneToolkit.hash(i, 103)), 1.0)
            let yn = prog * 1.16 - 0.08
            let phase = LiveSceneToolkit.hash(i, 107) * LiveSceneToolkit.twoPi
            let sway = sin(t * (0.36 + 0.22 * LiveSceneToolkit.hash(i, 109)) + phase)
            let xn = 0.03 + 0.90 * LiveSceneToolkit.hash(i, 113) + 0.040 * sway + 0.05 * prog
            let edge = min(1.0, prog * 9.0) * min(1.0, (1.0 - prog) * 9.0)
            let tumble = 0.675 + 0.325 * sin(t * (0.55 + 0.35 * LiveSceneToolkit.hash(i, 127)) + phase * 1.7)
            let spin = (i % 2 == 0 ? 1.0 : -1.0) * (4.0 + 5.0 * LiveSceneToolkit.hash(i, 131))
            let angle = LiveSceneToolkit.hash(i, 137) * 360.0 + 26.0 * sin(t * 0.41 + phase) + t * spin
            let s = 0.34 + 0.14 * LiveSceneToolkit.hash(i, 139)
            let a = min(1.0, max(0.0, farAlpha * edge * rosePetalCalm(yn)))
            var pctx = ctx
            pctx.opacity = a
            pctx.translateBy(x: xn * w, y: yn * h)
            pctx.rotate(by: .degrees(angle))
            pctx.scaleBy(x: s * tumble, y: s)
            pctx.fill(petal, with: .linearGradient(farGrad, startPoint: CGPoint(x: -unit * 0.5, y: -unit), endPoint: CGPoint(x: unit * 0.4, y: unit)))
        }

        // Two scrolling hedges with blooms on the near row
        let bloomR = max(0.6, minDim * 0.008)
        let bloomColor = colors.accent.lerp(to: colors.highlight, dark ? 0.30 : 0.20)
        let bloomAlpha = min(0.92, (dark ? 0.55 : 0.80) * k)
        for layer in 0..<2 {
            let depth = Double(layer)
            let baseY = h * (0.860 + 0.065 * depth)
            let amp = h * (0.022 + 0.008 * depth)
            let speed = 0.003 + 0.004 * depth
            let shift = LiveSceneToolkit.positiveMod(t * speed * w, w)
            let steps = 48
            var pts: [CGPoint] = []
            pts.reserveCapacity(steps + 3)
            for s in -1...(steps + 1) {
                let x = w * Double(s) / Double(steps)
                let a = LiveSceneToolkit.twoPi * ((x + shift) / w)
                pts.append(CGPoint(x: x, y: baseY - amp * roseHedgeProfile(a, layer: layer)))
            }
            var hPath = LiveSceneToolkit.smoothCurvePath(points: pts)
            hPath.addLine(to: CGPoint(x: w * 1.05, y: h))
            hPath.addLine(to: CGPoint(x: -w * 0.05, y: h))
            hPath.closeSubpath()

            let body = colors.shade.lerp(to: colors.ink, 0.80 * depth)
            let lit = body.lerp(to: colors.accent, dark ? 0.16 : 0.10)
            ctx.fill(
                hPath,
                with: .linearGradient(
                    Gradient(colors: [lit.color(alpha: 0.52 + 0.40 * depth), body.color(alpha: 0.78 + 0.20 * depth)]),
                    startPoint: CGPoint(x: 0, y: baseY - amp),
                    endPoint: CGPoint(x: 0, y: h)
                )
            )
            if layer == 1 {
                for j in 0..<6 {
                    let fx = (Double(j) + 0.2 + 0.6 * LiveSceneToolkit.hash(j, 71)) / 6.0
                    let cx = LiveSceneToolkit.positiveMod(fx * w - shift, w)
                    let cy = baseY - amp * roseHedgeProfile(LiveSceneToolkit.twoPi * fx, layer: 1) + bloomR * (1.2 + 2.4 * LiveSceneToolkit.hash(j, 73))
                    let r = bloomR * (0.7 + 0.6 * LiveSceneToolkit.hash(j, 79))
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)),
                        with: .color(bloomColor.color(alpha: bloomAlpha))
                    )
                }
            }
        }

        // Light motes
        let moteColor = dark ? colors.highlight.lerp(to: colors.accent, 0.25) : colors.accent.lerp(to: colors.highlight, 0.35)
        let moteAlpha = (dark ? 0.34 : 0.46) * k
        let moteR = min(1.2, minDim * 0.012)
        for i in 0..<10 {
            let lane = LiveSceneToolkit.hash(i, 31)
            let yn = lane < 0.55 ? 0.03 + lane * 0.50 : 0.64 + (lane - 0.55) * 0.62
            let xn = LiveSceneToolkit.positiveMod(LiveSceneToolkit.hash(i, 17) + t * (0.004 + 0.007 * LiveSceneToolkit.hash(i, 43)), 1.0) * 1.06 - 0.03
            let bob = sin(t * 0.33 + Double(i) * 2.1) * h * 0.010
            let shimmer = 0.25 + 0.75 * (0.5 + 0.5 * sin(t * 0.8 + Double(i) * 1.9))
            let r = moteR * (0.7 + 0.8 * LiveSceneToolkit.hash(i, 59))
            ctx.fill(
                Path(ellipseIn: CGRect(x: xn * w - r, y: yn * h + bob - r, width: r * 2, height: r * 2)),
                with: .color(moteColor.color(alpha: min(0.8, moteAlpha * shimmer)))
            )
        }

        // Near petals with center crease
        for i in 0..<nearCount {
            let n = i + 40
            let prog = LiveSceneToolkit.positiveMod(LiveSceneToolkit.hash(n, 101) + t * (0.026 + 0.014 * LiveSceneToolkit.hash(n, 103)), 1.0)
            let yn = prog * 1.16 - 0.08
            let phase = LiveSceneToolkit.hash(n, 107) * LiveSceneToolkit.twoPi
            let sway = sin(t * (0.48 + 0.26 * LiveSceneToolkit.hash(n, 109)) + phase)
            let xn = 0.02 + 0.88 * LiveSceneToolkit.hash(n, 113) + 0.060 * sway + 0.08 * prog
            let edge = min(1.0, prog * 9.0) * min(1.0, (1.0 - prog) * 9.0)
            let tumble = 0.675 + 0.325 * sin(t * (0.70 + 0.40 * LiveSceneToolkit.hash(n, 127)) + phase * 1.7)
            let spin = (i % 2 == 0 ? -1.0 : 1.0) * (6.0 + 6.0 * LiveSceneToolkit.hash(n, 131))
            let angle = LiveSceneToolkit.hash(n, 137) * 360.0 + 32.0 * sin(t * 0.52 + phase) + t * spin
            let s = 0.70 + 0.30 * LiveSceneToolkit.hash(n, 139)
            let a = min(1.0, max(0.0, nearAlpha * edge * rosePetalCalm(yn)))
            var pctx = ctx
            pctx.opacity = a
            pctx.translateBy(x: xn * w, y: yn * h)
            pctx.rotate(by: .degrees(angle))
            pctx.scaleBy(x: s * tumble, y: s)
            pctx.fill(petal, with: .linearGradient(nearGrad, startPoint: CGPoint(x: -unit * 0.5, y: -unit), endPoint: CGPoint(x: unit * 0.4, y: unit)))
            pctx.stroke(crease, with: .color(creaseColor.color(alpha: 0.55)), style: StrokeStyle(lineWidth: max(0.5, unit * 0.07), lineCap: .round))
        }
    }

    // MARK: - 6. Snow

    static func drawSnow(
        ctx: inout GraphicsContext,
        size: CGSize,
        colors: LiveSceneDrawColors,
        t: Double,
        detail: Double
    ) {
        let w = Double(size.width)
        let h = Double(size.height)
        let minDim = min(w, h)
        let k = min(1.35, max(0.40, detail))
        let isDark = colors.isDark

        let frostWhite = SceneRGB(hex: 0xFFF6FAFF)
        let iceTint = frostWhite.lerp(to: colors.accent, 0.18)
        let coolMist = colors.skyHorizon.lerp(to: iceTint, 0.45)

        // Overcast winter sky wash
        LiveSceneToolkit.drawSoftDisc(
            ctx: &ctx,
            color: iceTint,
            peakAlpha: (isDark ? 0.11 : 0.18) * k,
            edgeTint: colors.skyUpperMid,
            cx: w * (0.46 + 0.03 * sin(t * 0.06)),
            cy: h * 0.14,
            radius: minDim * 0.62,
            scaleX: 1.25,
            scaleY: 1.25,
            alpha: 0.90 + 0.10 * cos(t * 0.10)
        )

        // Far pinpoint snow
        let farBase = (isDark ? 0.42 : 0.56) * k
        for i in 0..<28 {
            let phase = LiveSceneToolkit.hash(i, 31)
            let speed = 0.011 + 0.007 * LiveSceneToolkit.hash(i, 47)
            let yn = -0.04 + LiveSceneToolkit.positiveMod(phase + t * speed, 1.08)
            let swayPhase = LiveSceneToolkit.hash(i, 73) * LiveSceneToolkit.twoPi
            let xn = LiveSceneToolkit.positiveMod(0.03 + 0.94 * LiveSceneToolkit.hash(i, 17) + 0.012 * sin(t * 0.25 + swayPhase) + t * 0.0018, 1.0)
            let calm = LiveSceneToolkit.calmMask(yn: yn, center: 0.48, halfSpan: 0.25, dip: 0.65)
            let edge: Double = yn < 0.04 ? min(1.0, max(0.0, (yn + 0.04) / 0.08)) : (yn > 0.92 ? min(1.0, max(0.0, (1.04 - yn) / 0.12)) : 1.0)
            let a = farBase * calm * edge
            if a > 0.01 {
                let r = minDim * (0.0014 + 0.0014 * LiveSceneToolkit.hash(i, 61))
                ctx.fill(
                    Path(ellipseIn: CGRect(x: w * xn - r, y: h * yn - r, width: r * 2, height: r * 2)),
                    with: .color(frostWhite.color(alpha: a))
                )
            }
        }

        // Winter ridges + valley mist
        let farR = LiveSceneToolkit.buildRidgeAndRibbon(w: w, h: h, steps: 80, ribbonMaxDepth: h * 0.015, topLiftFactor: 0.10, minEdgeTaper: 0.18) { xn in
            h * 0.81 - h * 0.044 * exp(-pow(xn - 0.22, 2) / 0.032) - h * 0.052 * exp(-pow(xn - 0.78, 2) / 0.036) + h * 0.014 * sin(xn * 3.8 + 0.6)
        }
        let nearR = LiveSceneToolkit.buildRidgeAndRibbon(w: w, h: h, steps: 80, ribbonMaxDepth: h * 0.016, topLiftFactor: 0.10, minEdgeTaper: 0.18) { xn in
            h * 0.885 + h * 0.022 * sin(xn * 2.9 + 2.0) + h * 0.009 * cos(xn * 5.6)
        }
        let rimC = isDark ? iceTint : frostWhite

        ctx.fill(
            farR.ridge,
            with: .linearGradient(
                Gradient(colors: [
                    colors.shade.lerp(to: coolMist, isDark ? 0.26 : 0.40).color(alpha: (isDark ? 0.72 : 0.42) * k),
                    colors.ink.lerp(to: colors.shade, 0.35).color(alpha: (isDark ? 0.88 : 0.56) * k)
                ]),
                startPoint: CGPoint(x: 0, y: h * 0.74),
                endPoint: CGPoint(x: 0, y: h)
            )
        )
        ctx.fill(
            farR.ribbon,
            with: .linearGradient(
                Gradient(colors: [rimC.color(alpha: (isDark ? 0.22 : 0.36) * k), .clear]),
                startPoint: CGPoint(x: 0, y: h * 0.74),
                endPoint: CGPoint(x: 0, y: h * 0.85)
            )
        )
        ctx.fill(
            Path(CGRect(x: 0, y: h * 0.70, width: w, height: h * 0.22)),
            with: .linearGradient(
                Gradient(stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: coolMist.color(alpha: (isDark ? 0.11 : 0.20) * k), location: 0.5),
                    .init(color: .clear, location: 1.0)
                ]),
                startPoint: CGPoint(x: 0, y: h * 0.70),
                endPoint: CGPoint(x: 0, y: h * 0.92)
            )
        )
        ctx.fill(
            nearR.ridge,
            with: .linearGradient(
                Gradient(colors: [
                    colors.ink.lerp(to: coolMist, isDark ? 0.22 : 0.34).color(alpha: (isDark ? 0.88 : 0.54) * k),
                    colors.ink.color(alpha: (isDark ? 0.96 : 0.70) * k)
                ]),
                startPoint: CGPoint(x: 0, y: h * 0.83),
                endPoint: CGPoint(x: 0, y: h)
            )
        )
        ctx.fill(
            nearR.ribbon,
            with: .linearGradient(
                Gradient(colors: [rimC.color(alpha: (isDark ? 0.18 : 0.30) * k), .clear]),
                startPoint: CGPoint(x: 0, y: h * 0.83),
                endPoint: CGPoint(x: 0, y: h * 0.93)
            )
        )

        // Mid soft optical snow motes
        let midR = minDim * 0.011
        for i in 0..<20 {
            let phase = LiveSceneToolkit.hash(i, 103)
            let speed = 0.017 + 0.009 * LiveSceneToolkit.hash(i, 117)
            let yn = -0.05 + LiveSceneToolkit.positiveMod(phase + t * speed, 1.10)
            let swayAmp = 0.014 + 0.016 * LiveSceneToolkit.hash(i, 149)
            let swayFreq = 0.28 + 0.24 * LiveSceneToolkit.hash(i, 163)
            let swayPhase = LiveSceneToolkit.hash(i, 179) * LiveSceneToolkit.twoPi
            let xn = LiveSceneToolkit.positiveMod(0.04 + 0.92 * LiveSceneToolkit.hash(i, 89) + swayAmp * sin(t * swayFreq + swayPhase) + t * 0.0028, 1.06) - 0.03
            let calm = LiveSceneToolkit.calmMask(yn: yn, center: 0.48, halfSpan: 0.25, dip: 0.72)
            let edge: Double = yn < 0.04 ? min(1.0, max(0.0, (yn + 0.05) / 0.09)) : (yn > 0.90 ? min(1.0, max(0.0, (1.05 - yn) / 0.15)) : 1.0)
            let a = calm * edge
            if a > 0.02 {
                let s = 0.65 + 0.60 * LiveSceneToolkit.hash(i, 131)
                LiveSceneToolkit.drawSoftDisc(
                    ctx: &ctx,
                    color: frostWhite,
                    peakAlpha: (isDark ? 0.42 : 0.56) * k,
                    edgeTint: iceTint,
                    cx: w * xn,
                    cy: h * yn,
                    radius: midR,
                    scaleX: s,
                    scaleY: s,
                    alpha: a
                )
            }
        }

        // Near bokeh snow orbs
        let nearRUnit = minDim * 0.032
        for i in 0..<10 {
            let phase = LiveSceneToolkit.hash(i, 211)
            let speed = 0.025 + 0.013 * LiveSceneToolkit.hash(i, 227)
            let yn = -0.07 + LiveSceneToolkit.positiveMod(phase + t * speed, 1.14)
            let swayAmp = 0.020 + 0.018 * LiveSceneToolkit.hash(i, 257)
            let swayPhase = LiveSceneToolkit.hash(i, 271) * LiveSceneToolkit.twoPi
            let xn = LiveSceneToolkit.positiveMod(0.06 + 0.88 * LiveSceneToolkit.hash(i, 193) + swayAmp * sin(t * 0.24 + swayPhase) + t * 0.0036, 1.08) - 0.04
            let calm = LiveSceneToolkit.calmMask(yn: yn, center: 0.48, halfSpan: 0.25, dip: 0.78)
            let edge: Double = yn < 0.06 ? min(1.0, max(0.0, (yn + 0.07) / 0.13)) : (yn > 0.88 ? min(1.0, max(0.0, (1.07 - yn) / 0.19)) : 1.0)
            let a = calm * edge
            if a > 0.02 {
                let s = 0.72 + 0.50 * LiveSceneToolkit.hash(i, 241)
                LiveSceneToolkit.drawSoftDisc(
                    ctx: &ctx,
                    color: frostWhite,
                    peakAlpha: (isDark ? 0.18 : 0.28) * k,
                    edgeTint: iceTint,
                    cx: w * xn,
                    cy: h * yn,
                    radius: nearRUnit,
                    scaleX: s,
                    scaleY: s,
                    alpha: a
                )
            }
        }
    }

    // MARK: - 7. Butterflies over Meadow

    private struct ButterflyFlight {
        let cx: Double
        let cy: Double
        let ax: Double
        let ay: Double
        let speed: Double
        let size: Double
        let phase: Double
        let flapRate: Double
        let second: Bool
    }

    private static let butterflyFlights: [ButterflyFlight] = [
        ButterflyFlight(cx: 0.28, cy: 0.74, ax: 0.20, ay: 0.060, speed: -0.24, size: 1.00, phase: 4.8, flapRate: 6.4, second: false),
        ButterflyFlight(cx: 0.30, cy: 0.17, ax: 0.22, ay: 0.070, speed: 0.21, size: 0.62, phase: 0.0, flapRate: 7.1, second: false),
        ButterflyFlight(cx: 0.72, cy: 0.70, ax: 0.18, ay: 0.050, speed: 0.19, size: 0.78, phase: 2.6, flapRate: 6.8, second: true),
        ButterflyFlight(cx: 0.70, cy: 0.12, ax: 0.20, ay: 0.055, speed: -0.16, size: 0.44, phase: 1.9, flapRate: 7.6, second: true),
        ButterflyFlight(cx: 0.50, cy: 0.79, ax: 0.34, ay: 0.035, speed: 0.11, size: 0.52, phase: 5.7, flapRate: 7.3, second: false),
        ButterflyFlight(cx: 0.52, cy: 0.25, ax: 0.30, ay: 0.050, speed: 0.13, size: 0.36, phase: 3.4, flapRate: 8.0, second: false)
    ]

    private static let bfBokehX = [0.68, 0.34, 0.90, 0.14, 0.62]
    private static let bfBokehY = [0.10, 0.22, 0.27, 0.72, 0.78]

    private static func bfGroundY(_ xn: Double, layer: Int, h: Double) -> Double {
        let base = 0.855 + 0.085 * Double(layer)
        let amp = 0.012 + 0.004 * Double(layer)
        return h * (base - amp * (0.6 * sin(xn * 4.2 + Double(layer) * 1.7) + 0.4 * sin(xn * 9.1 + Double(layer) * 2.9 + 0.6)))
    }

    private static func bfAddBlade(into path: inout Path, x: Double, baseY: Double, height: Double, halfW: Double, lean: Double) {
        path.move(to: CGPoint(x: x - halfW, y: baseY))
        path.addCurve(
            to: CGPoint(x: x + lean, y: baseY - height),
            control1: CGPoint(x: x - halfW * 0.7, y: baseY - height * 0.50),
            control2: CGPoint(x: x + lean * 0.35 - halfW * 0.2, y: baseY - height * 0.86)
        )
        path.addCurve(
            to: CGPoint(x: x + halfW, y: baseY),
            control1: CGPoint(x: x + lean * 0.45 + halfW * 0.3, y: baseY - height * 0.80),
            control2: CGPoint(x: x + halfW * 0.9, y: baseY - height * 0.45)
        )
        path.closeSubpath()
    }

    static func drawButterflies(
        ctx: inout GraphicsContext,
        size: CGSize,
        colors: LiveSceneDrawColors,
        t: Double,
        detail: Double
    ) {
        let w = Double(size.width)
        let h = Double(size.height)
        let minDim = min(w, h)
        let k = min(1.4, max(0.35, detail))
        let ka = min(1.15, k)
        let dark = colors.isDark

        // Corner sun haze
        let sun = CGPoint(x: w * 0.16, y: h * 0.07)
        let hazeR = max(w, h * 0.5) * 0.78
        let hazeTint = colors.accent2.lerp(to: colors.highlight, dark ? 0.30 : 0.70)
        let breathe = 0.93 + 0.07 * sin(t * 0.19)
        ctx.fill(
            Path(ellipseIn: CGRect(x: sun.x - hazeR, y: sun.y - hazeR, width: hazeR * 2, height: hazeR * 2)),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: hazeTint.color(alpha: (dark ? 0.22 : 0.50) * ka * breathe), location: 0.0),
                    .init(color: hazeTint.color(alpha: (dark ? 0.08 : 0.16) * ka * breathe), location: 0.40),
                    .init(color: .clear, location: 1.0)
                ]),
                center: sun,
                startRadius: 0,
                endRadius: hazeR
            )
        )

        // 5 bokeh discs
        for i in 0..<5 {
            let tint = (i % 2 == 0 ? colors.accent : colors.accent2).lerp(to: colors.highlight, dark ? 0.12 : 0.40)
            let rad = max(0.5, minDim * (0.13 + 0.11 * LiveSceneToolkit.hash(i, 9)))
            let peak = (dark ? 0.15 : 0.24) * ka * (bfBokehY[i] > 0.5 ? 0.70 : 1.0) * (0.72 + 0.28 * sin(t * 0.15 + Double(i) * 1.61))
            let cx = w * bfBokehX[i] + sin(t * 0.06 + Double(i) * 2.3) * w * 0.024
            let cy = h * bfBokehY[i] + sin(t * 0.05 + Double(i) * 1.1 + 0.7) * h * 0.012
            ctx.fill(
                Path(ellipseIn: CGRect(x: cx - rad, y: cy - rad, width: rad * 2, height: rad * 2)),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: tint.color(alpha: peak), location: 0.0),
                        .init(color: tint.color(alpha: peak * 0.62), location: 0.62),
                        .init(color: tint.color(alpha: peak * 0.10), location: 0.90),
                        .init(color: .clear, location: 1.0)
                    ]),
                    center: CGPoint(x: cx, y: cy),
                    startRadius: 0,
                    endRadius: rad
                )
            )
        }

        // Two meadow ground strips + swaying grass tufts & small flowers
        let farBody = colors.skyHorizon.lerp(to: colors.shade.lerp(to: colors.ink, 0.15), 0.86)
        let farLit = farBody.lerp(to: colors.accent, dark ? 0.16 : 0.07)
        let nearBody = colors.shade.lerp(to: colors.ink, 0.88)
        let nearLit = nearBody.lerp(to: colors.accent, dark ? 0.10 : 0.06)
        let flowerColor = colors.accent2.lerp(to: colors.highlight, dark ? 0.30 : 0.15)
        let grassScale = min(h, w * 2.4)
        let sink = max(h * 0.008, w * 0.006)
        let flowerR = max(0.8, minDim * 0.0085)

        for layer in 0..<2 {
            var pts: [CGPoint] = []
            for s in 0...40 {
                let xn = -0.02 + 1.04 * Double(s) / 40.0
                pts.append(CGPoint(x: xn * w, y: bfGroundY(xn, layer: layer, h: h)))
            }
            var gPath = LiveSceneToolkit.smoothCurvePath(points: pts)
            gPath.addLine(to: CGPoint(x: w * 1.02, y: h))
            gPath.addLine(to: CGPoint(x: -w * 0.02, y: h))
            gPath.closeSubpath()
            let lit = layer == 0 ? farLit : nearLit
            let body = layer == 0 ? farBody : nearBody
            ctx.fill(
                gPath,
                with: .linearGradient(
                    Gradient(colors: [lit.color(), body.color()]),
                    startPoint: CGPoint(x: 0, y: h * (layer == 0 ? 0.876 : 0.965)),
                    endPoint: CGPoint(x: 0, y: h)
                )
            )

            let tuftCount = layer == 0 ? 6 : 8
            let span = 1.0 / Double(tuftCount)
            let bladeH = grassScale * (layer == 0 ? 0.032 : 0.056)
            let bladeHalf = w * (layer == 0 ? 0.0065 : 0.0095)
            let swayAmp = layer == 0 ? 1.6 : 2.6

            for j in 0..<tuftCount {
                let index = layer == 0 ? j : (6 + j)
                let x0 = Double(j) * span
                var blades = Path()
                var flowers = Path()
                for b in 0..<7 {
                    let seed = index * 16 + b
                    let xn = x0 + span * (Double(b) + 0.5 + 0.7 * (LiveSceneToolkit.hash(seed, 211) - 0.5)) / 7.0
                    let bh = bladeH * (0.45 + 0.55 * LiveSceneToolkit.hash(seed, 223))
                    bfAddBlade(
                        into: &blades,
                        x: xn * w,
                        baseY: bfGroundY(xn, layer: layer, h: h) + sink,
                        height: bh + sink,
                        halfW: bladeHalf * (0.7 + 0.6 * LiveSceneToolkit.hash(seed, 227)),
                        lean: bh * 0.8 * (LiveSceneToolkit.hash(seed, 229) - 0.5)
                    )
                }
                if (layer == 0 && j % 3 == 1) || (layer == 1 && j % 2 == 0) {
                    let stems = (layer == 1 && j % 4 == 0) ? 2 : 1
                    for q in 0..<stems {
                        let seed = index * 16 + 9 + q
                        let xn = x0 + span * (0.2 + 0.6 * (Double(q) + LiveSceneToolkit.hash(seed, 233)) / Double(stems))
                        let bh = bladeH * (1.0 + 0.25 * LiveSceneToolkit.hash(seed, 239))
                        let lean = bh * 0.25 * (LiveSceneToolkit.hash(seed, 241) - 0.5)
                        let baseY = bfGroundY(xn, layer: layer, h: h) + sink
                        bfAddBlade(into: &blades, x: xn * w, baseY: baseY, height: bh + sink, halfW: bladeHalf * 0.45, lean: lean)
                        let fr = flowerR * (layer == 0 ? 0.65 : 1.0) * (0.8 + 0.4 * LiveSceneToolkit.hash(seed, 251))
                        flowers.addEllipse(in: CGRect(x: xn * w + lean - fr, y: baseY - bh - sink - fr, width: fr * 2, height: fr * 2))
                    }
                }
                let centre = x0 + span * 0.5
                let px = centre * w
                let py = bfGroundY(centre, layer: layer, h: h) + sink
                let phase = Double(j) * 0.75 + Double(layer) * 1.9
                let swing = swayAmp * (sin(t * 0.85 + phase) + 0.35 * sin(t * 1.9 + phase * 2.3))

                var tctx = ctx
                tctx.translateBy(x: px, y: py)
                tctx.rotate(by: .degrees(swing))
                tctx.translateBy(x: -px, y: -py)
                tctx.fill(blades, with: .color(lit.color()))
                if !flowers.isEmpty {
                    let fa = min(0.95, (layer == 0 ? 0.62 : 0.88) * k)
                    tctx.fill(flowers, with: .color(flowerColor.color(alpha: fa)))
                }
            }
        }

        // Pollen specks
        let pollenC = dark ? colors.highlight.lerp(to: colors.accent2, 0.25) : colors.accent2.lerp(to: colors.highlight, 0.25)
        let pollenA = (dark ? 0.40 : 0.52) * k
        let pollenR = min(1.2, minDim * 0.012)
        for i in 0..<14 {
            let lane = LiveSceneToolkit.hash(i, 37)
            let yn = lane < 0.5 ? 0.04 + lane * 0.56 : 0.62 + (lane - 0.5) * 0.52
            let xn = LiveSceneToolkit.positiveMod(LiveSceneToolkit.hash(i, 19) + t * (0.003 + 0.006 * LiveSceneToolkit.hash(i, 47)), 1.0) * 1.06 - 0.03
            let bob = sin(t * 0.31 + Double(i) * 2.3) * h * 0.012
            let shimmer = 0.25 + 0.75 * (0.5 + 0.5 * sin(t * 0.7 + Double(i) * 1.7))
            let r = pollenR * (0.7 + 0.8 * LiveSceneToolkit.hash(i, 61))
            ctx.fill(
                Path(ellipseIn: CGRect(x: xn * w - r, y: yn * h + bob - r, width: r * 2, height: r * 2)),
                with: .color(pollenC.color(alpha: min(0.8, pollenA * shimmer)))
            )
        }

        // Butterflies
        let unit = max(0.5, minDim * 0.050)
        var wing = Path()
        wing.move(to: CGPoint(x: 0, y: -unit * 0.20))
        wing.addCurve(to: CGPoint(x: unit * 1.04, y: -unit * 0.44), control1: CGPoint(x: unit * 0.28, y: -unit * 1.06), control2: CGPoint(x: unit * 1.12, y: -unit * 1.02))
        wing.addCurve(to: CGPoint(x: 0, y: unit * 0.04), control1: CGPoint(x: unit * 1.00, y: -unit * 0.12), control2: CGPoint(x: unit * 0.46, y: unit * 0.06))
        wing.closeSubpath()
        wing.move(to: CGPoint(x: 0, y: -unit * 0.02))
        wing.addCurve(to: CGPoint(x: unit * 0.74, y: unit * 0.64), control1: CGPoint(x: unit * 0.56, y: 0), control2: CGPoint(x: unit * 0.94, y: unit * 0.28))
        wing.addCurve(to: CGPoint(x: 0, y: unit * 0.34), control1: CGPoint(x: unit * 0.58, y: unit * 0.92), control2: CGPoint(x: unit * 0.16, y: unit * 0.72))
        wing.closeSubpath()

        var antennae = Path()
        antennae.move(to: CGPoint(x: 0, y: -unit * 0.30))
        antennae.addCurve(to: CGPoint(x: unit * 0.26, y: -unit * 0.66), control1: CGPoint(x: unit * 0.04, y: -unit * 0.48), control2: CGPoint(x: unit * 0.14, y: -unit * 0.60))
        antennae.move(to: CGPoint(x: 0, y: -unit * 0.30))
        antennae.addCurve(to: CGPoint(x: -unit * 0.26, y: -unit * 0.66), control1: CGPoint(x: -unit * 0.04, y: -unit * 0.48), control2: CGPoint(x: -unit * 0.14, y: -unit * 0.60))

        func edgeFor(_ tint: SceneRGB) -> SceneRGB {
            dark ? tint.lerp(to: colors.ink, 0.60) : tint.lerp(to: colors.ink, 0.15).lerp(to: .black, 0.22)
        }
        func wingGrad(_ tint: SceneRGB) -> Gradient {
            Gradient(stops: [
                .init(color: tint.lerp(to: colors.highlight, dark ? 0.70 : 0.62).color(), location: 0.0),
                .init(color: tint.lerp(to: colors.highlight, 0.22).color(), location: 0.34),
                .init(color: (dark ? tint.lerp(to: colors.highlight, 0.10) : tint).color(), location: 0.78),
                .init(color: edgeFor(tint).color(), location: 1.0)
            ])
        }

        let wingMain = wingGrad(colors.accent)
        let wingSecond = wingGrad(colors.accent2)
        let edgeMain = edgeFor(colors.accent)
        let edgeSecond = edgeFor(colors.accent2)
        let count = k < 0.8 ? butterflyFlights.count - 1 : butterflyFlights.count

        for i in 0..<count {
            let f = butterflyFlights[i]
            let theta = t * f.speed + f.phase
            let beat = t * f.flapRate + f.phase * 3.0
            let s = f.size
            let x = (f.cx + f.ax * sin(theta)) * w
            let y = (f.cy + f.ay * sin(2.0 * theta)) * h - sin(beat) * unit * s * 0.10
            let vx = f.ax * cos(theta) * f.speed * w
            let vy = 2.0 * f.ay * cos(2.0 * theta) * f.speed * h
            let heading = atan2(vy, vx) * (180.0 / .pi) + 90.0
            let open = 0.5 + 0.5 * sin(beat)
            let depth = 0.50 + 0.35 * (0.5 + 0.5 * sin(t * 0.47 + f.phase * 1.7))
            let flap = 1.0 - depth * (1.0 - open)
            let a = min(0.96, max(0.0, (0.50 + 0.45 * s) * (dark ? 0.92 : 1.0) * ka))
            let grad = f.second ? wingSecond : wingMain
            let edge = f.second ? edgeSecond : edgeMain
            let outlined = s > 0.5

            var bctx = ctx
            bctx.opacity = a
            bctx.translateBy(x: x, y: y)
            bctx.rotate(by: .degrees(heading))
            bctx.scaleBy(x: s, y: s)

            for dir in [1.0, -1.0] {
                var wctx = bctx
                wctx.scaleBy(x: dir * flap, y: 1.0)
                wctx.fill(
                    wing,
                    with: .radialGradient(grad, center: CGPoint(x: unit * 0.06, y: -unit * 0.06), startRadius: 0, endRadius: unit * 1.16)
                )
                if outlined {
                    wctx.stroke(wing, with: .color(edge.color(alpha: 0.75)), style: StrokeStyle(lineWidth: max(0.4, unit * 0.055), lineJoin: .round))
                }
            }

            var body = Path()
            body.move(to: CGPoint(x: 0, y: -unit * 0.30))
            body.addLine(to: CGPoint(x: 0, y: unit * 0.40))
            bctx.stroke(body, with: .color(edge.color()), style: StrokeStyle(lineWidth: max(0.6, unit * 0.13), lineCap: .round))
            if outlined {
                bctx.stroke(antennae, with: .color(edge.color(alpha: 0.8)), style: StrokeStyle(lineWidth: max(0.4, unit * 0.045), lineCap: .round))
            }
        }
    }
}
