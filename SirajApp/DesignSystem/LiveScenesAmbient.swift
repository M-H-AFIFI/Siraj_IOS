import SwiftUI

enum LiveScenesAmbient {

    // MARK: - 1. Rings ("Ripples")

    static func drawRings(
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

        let emitterXs = [0.88, 0.11]
        let emitterYs = [0.09, 0.89]
        let emitterMaxR = [minDim * 0.84, minDim * 0.62]
        let emitterCycle = [9.0, 11.0]
        let emitterGain = [1.0, 0.56]

        let primaryRing = colors.accent.lerp(to: colors.highlight, isDark ? 0.34 : 0.14)
        let secondaryRing = colors.accent2.lerp(to: colors.highlight, isDark ? 0.28 : 0.12)
        let hairline1 = isDark ? primaryRing.lerp(to: colors.highlight, 0.42) : primaryRing.lerp(to: colors.accent, 0.25)
        let hairline2 = isDark ? secondaryRing.lerp(to: colors.highlight, 0.38) : secondaryRing.lerp(to: colors.accent2, 0.25)

        let glowW = max(1.8, minDim * 0.0068)
        let coreW = max(1.1, minDim * 0.0020)
        let hubR = max(3.5, minDim * 0.020)
        let orbR = minDim * 0.09

        for e in 0..<2 {
            let ex = w * (emitterXs[e] + 0.012 * sin(t * 0.35 + Double(e) * 2.1))
            let ey = h * (emitterYs[e] + 0.010 * cos(t * 0.28 + Double(e) * 1.7))
            let baseTint = e == 1 ? secondaryRing : primaryRing
            let fineTint = e == 1 ? hairline2 : hairline1
            let gain = emitterGain[e]
            let hubPulse = 0.76 + 0.24 * sin(t * 1.25 + Double(e) * 1.9)

            LiveSceneToolkit.drawSoftDisc(
                ctx: &ctx,
                color: baseTint,
                peakAlpha: (e == 1 ? (isDark ? 0.08 : 0.07) : (isDark ? 0.11 : 0.09)) * k,
                edgeTint: e == 1 ? colors.skyLowerMid : colors.skyUpperMid,
                cx: ex,
                cy: ey,
                radius: orbR,
                alpha: hubPulse * gain
            )
            let hr = hubR * (0.94 + 0.06 * hubPulse)
            ctx.stroke(
                Path(ellipseIn: CGRect(x: ex - hr, y: ey - hr, width: hr * 2, height: hr * 2)),
                with: .color(fineTint.color(alpha: (isDark ? 0.28 : 0.24) * hubPulse * gain * k)),
                lineWidth: coreW
            )

            let period = emitterCycle[e]
            let maxR = emitterMaxR[e]
            for rIdx in 0..<6 {
                let age = LiveSceneToolkit.positiveMod(t / period + Double(rIdx) / 6.0 + Double(e) * 0.14, 1.0)
                let radius = hubR * 1.35 + maxR * age
                let birthEase = pow(sin(min(1.0, age * 2.2) * (.pi * 0.5)), 0.75)
                let outwardFade = pow(1.0 - age, 1.25)
                let midCalm = 1.0 - 0.38 * pow(sin(age * .pi), 2.0)
                let waveAlpha = min(1.0, max(0.0, birthEase * outwardFade * midCalm * gain * k))
                if waveAlpha > 0.008 {
                    let ringRect = CGRect(x: ex - radius, y: ey - radius, width: radius * 2, height: radius * 2)
                    ctx.stroke(Path(ellipseIn: ringRect), with: .color(baseTint.color(alpha: waveAlpha * (isDark ? 0.055 : 0.045))), lineWidth: glowW)
                    ctx.stroke(Path(ellipseIn: ringRect), with: .color(fineTint.color(alpha: waveAlpha * (isDark ? 0.23 : 0.19))), lineWidth: coreW)
                }
            }
        }
    }

    // MARK: - 2. Circles ("Bokeh")

    private struct MovingCircle {
        let xBase: Double
        let yBase: Double
        let vx: Double
        let vy: Double
        let sizeRatio: Double
        let swayAmp: Double
        let swayFreq: Double
        let phase: Double
        let layer: Int
        let colorSlot: Int
    }

    private static let movingCircles: [MovingCircle] = [
        MovingCircle(xBase: 0.14, yBase: 0.08, vx: 0.013, vy: -0.017, sizeRatio: 0.235, swayAmp: 0.030, swayFreq: 0.42, phase: 0.3, layer: 1, colorSlot: 0),
        MovingCircle(xBase: 0.56, yBase: 0.04, vx: -0.012, vy: -0.015, sizeRatio: 0.255, swayAmp: 0.032, swayFreq: 0.38, phase: 1.4, layer: 0, colorSlot: 1),
        MovingCircle(xBase: 0.84, yBase: 0.14, vx: -0.016, vy: -0.022, sizeRatio: 0.205, swayAmp: 0.028, swayFreq: 0.48, phase: 2.6, layer: 1, colorSlot: 2),
        MovingCircle(xBase: 0.32, yBase: 0.19, vx: 0.018, vy: -0.026, sizeRatio: 0.190, swayAmp: 0.038, swayFreq: 0.54, phase: 3.8, layer: 2, colorSlot: 0),
        MovingCircle(xBase: 0.68, yBase: 0.23, vx: -0.014, vy: -0.021, sizeRatio: 0.215, swayAmp: 0.034, swayFreq: 0.46, phase: 4.9, layer: 2, colorSlot: 1),
        MovingCircle(xBase: 0.10, yBase: 0.29, vx: 0.015, vy: -0.020, sizeRatio: 0.155, swayAmp: 0.030, swayFreq: 0.58, phase: 0.9, layer: 2, colorSlot: 2),
        MovingCircle(xBase: 0.46, yBase: 0.12, vx: -0.011, vy: -0.018, sizeRatio: 0.142, swayAmp: 0.028, swayFreq: 0.60, phase: 2.0, layer: 2, colorSlot: 0),
        MovingCircle(xBase: 0.90, yBase: 0.31, vx: -0.015, vy: -0.019, sizeRatio: 0.168, swayAmp: 0.032, swayFreq: 0.52, phase: 5.4, layer: 1, colorSlot: 0),
        MovingCircle(xBase: 0.24, yBase: 0.36, vx: 0.012, vy: -0.017, sizeRatio: 0.132, swayAmp: 0.026, swayFreq: 0.64, phase: 1.7, layer: 2, colorSlot: 1),
        MovingCircle(xBase: 0.58, yBase: 0.35, vx: 0.011, vy: -0.016, sizeRatio: 0.122, swayAmp: 0.026, swayFreq: 0.58, phase: 4.1, layer: 1, colorSlot: 2),
        MovingCircle(xBase: 0.20, yBase: 0.62, vx: 0.014, vy: -0.018, sizeRatio: 0.195, swayAmp: 0.034, swayFreq: 0.40, phase: 3.1, layer: 0, colorSlot: 2),
        MovingCircle(xBase: 0.74, yBase: 0.68, vx: -0.013, vy: -0.017, sizeRatio: 0.220, swayAmp: 0.032, swayFreq: 0.44, phase: 0.7, layer: 0, colorSlot: 1),
        MovingCircle(xBase: 0.44, yBase: 0.80, vx: 0.016, vy: -0.022, sizeRatio: 0.175, swayAmp: 0.034, swayFreq: 0.48, phase: 2.3, layer: 1, colorSlot: 0),
        MovingCircle(xBase: 0.86, yBase: 0.85, vx: -0.012, vy: -0.020, sizeRatio: 0.148, swayAmp: 0.028, swayFreq: 0.52, phase: 5.1, layer: 1, colorSlot: 2)
    ]

    static func drawCircles(
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

        let warmGold = colors.highlight.lerp(to: SceneRGB(hex: 0xFFE5A45B), isDark ? 0.30 : 0.18)
        let rims = [
            warmGold.lerp(to: colors.accent, 0.24),
            colors.accent.lerp(to: colors.highlight, isDark ? 0.28 : 0.14),
            colors.accent2.lerp(to: colors.highlight, isDark ? 0.26 : 0.14)
        ]
        let inners = [
            rims[0].lerp(to: colors.skyUpperMid, 0.22),
            rims[1].lerp(to: colors.skyLowerMid, 0.22),
            rims[2].lerp(to: colors.skyUpperMid, 0.24)
        ]
        let edges = [colors.skyUpperMid, colors.skyLowerMid, colors.skyUpperMid]
        let haloPeak = (isDark ? 0.085 : 0.075) * k
        let bokehPeak = (isDark ? 0.135 : 0.115) * k
        let rimStrokeW = max(1.1, minDim * 0.0020)
        let outerStrokeW = max(1.8, minDim * 0.0052)

        let wrapMargin = 0.28
        let wrapSpan = 1.56
        let edgeFadeDist = 0.14

        for c in movingCircles {
            let xDrift = c.xBase + t * c.vx + c.swayAmp * sin(t * c.swayFreq + c.phase)
            let yDrift = c.yBase + t * c.vy + c.swayAmp * 0.45 * cos(t * c.swayFreq * 0.85 + c.phase)
            let xn = LiveSceneToolkit.positiveMod(xDrift + wrapMargin, wrapSpan) - wrapMargin
            let yn = LiveSceneToolkit.positiveMod(yDrift + wrapMargin, wrapSpan) - wrapMargin

            let fadeX = min(1.0, max(0.0, min((xn + wrapMargin) / edgeFadeDist, (1.0 + wrapMargin - xn) / edgeFadeDist)))
            let fadeY = min(1.0, max(0.0, min((yn + wrapMargin) / edgeFadeDist, (1.0 + wrapMargin - yn) / edgeFadeDist)))
            let layerGain: Double = c.layer == 0 ? 0.56 : (c.layer == 1 ? 0.82 : 1.0)
            let breath = 0.91 + 0.09 * sin(t * 0.65 + c.phase)
            let radius = minDim * c.sizeRatio * breath
            let calm = LiveSceneToolkit.calmMask(yn: yn, center: 0.50, halfSpan: 0.20, dip: 0.40)
            let alpha = min(1.0, max(0.0, layerGain * fadeX * fadeY * calm))
            if alpha <= 0.01 { continue }

            let cx = w * xn
            let cy = h * yn
            let rim = rims[c.colorSlot]
            let inner = inners[c.colorSlot]

            LiveSceneToolkit.drawSoftDisc(
                ctx: &ctx,
                color: rim,
                peakAlpha: haloPeak,
                edgeTint: edges[c.colorSlot],
                cx: cx,
                cy: cy,
                radius: radius * 1.18,
                alpha: alpha * 0.72
            )

            let peak = bokehPeak * alpha
            let lensGrad = Gradient(stops: [
                .init(color: inner.color(alpha: peak * 0.56), location: 0.00),
                .init(color: inner.color(alpha: peak * 0.68), location: 0.55),
                .init(color: rim.color(alpha: peak * 0.92), location: 0.84),
                .init(color: rim.color(alpha: peak * 0.65), location: 0.97),
                .init(color: .clear, location: 1.00)
            ])
            let discRect = CGRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2)
            ctx.fill(
                Path(ellipseIn: discRect),
                with: .radialGradient(lensGrad, center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: radius)
            )

            let rimAlpha = min(1.0, (isDark ? 0.24 : 0.20) * alpha * k)
            if rimAlpha > 0.01 {
                ctx.stroke(Path(ellipseIn: discRect), with: .color(rim.color(alpha: rimAlpha * 0.28)), lineWidth: outerStrokeW)
                ctx.stroke(Path(ellipseIn: discRect), with: .color(rim.color(alpha: rimAlpha)), lineWidth: rimStrokeW)
            }
        }
    }

    // MARK: - 3. Particles ("Constellation")

    static func drawParticles(
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

        let poolR = minDim * 0.48
        let tealTint = colors.accent.lerp(to: SceneRGB(hex: 0xFF287D8C), isDark ? 0.28 : 0.14)
        let violetTint = colors.accent2.lerp(to: colors.skyUpperMid, 0.20)

        LiveSceneToolkit.drawSoftDisc(
            ctx: &ctx, color: tealTint, peakAlpha: (isDark ? 0.13 : 0.09) * k, edgeTint: colors.skyTop,
            cx: w * (0.28 + 0.045 * sin(t * 0.25)), cy: h * 0.16, radius: poolR, scaleX: 1.35, scaleY: 0.85,
            alpha: 0.85 + 0.15 * cos(t * 0.32)
        )
        LiveSceneToolkit.drawSoftDisc(
            ctx: &ctx, color: violetTint, peakAlpha: (isDark ? 0.11 : 0.08) * k, edgeTint: colors.skyUpperMid,
            cx: w * (0.76 - 0.045 * cos(t * 0.21)), cy: h * 0.26, radius: poolR, scaleX: 1.25, scaleY: 0.80,
            alpha: 0.85 + 0.15 * sin(t * 0.28)
        )

        let nodeColor = isDark ? colors.highlight.lerp(to: .white, 0.30) : colors.accent.lerp(to: colors.accent2, 0.25)
        let lineColor = isDark ? colors.accent.lerp(to: colors.highlight, 0.48) : colors.accent.lerp(to: colors.accent2, 0.30)
        let lineW = max(0.85, minDim * 0.0014)
        let maxDist = minDim * 0.25
        let linePeak = (isDark ? 0.19 : 0.16) * k
        let anchorHaloR = max(6.0, minDim * 0.030)
        let glintHalf = max(2.2, minDim * 0.011)
        let glintW = max(0.75, minDim * 0.0012)

        // 42 background pinpoint stars
        let bgPeak = (isDark ? 0.42 : 0.30) * k
        for i in 0..<42 {
            let xn = 0.03 + 0.94 * LiveSceneToolkit.hash(i, 11)
            let hy = LiveSceneToolkit.hash(i, 29)
            let yn = i < 32 ? (0.02 + 0.46 * hy) : (0.46 + 0.36 * hy)
            let freq = 0.85 + 0.90 * LiveSceneToolkit.hash(i, 43)
            let phase = LiveSceneToolkit.hash(i, 61) * LiveSceneToolkit.twoPi
            let r = max(0.75, minDim * (0.0010 + 0.0009 * LiveSceneToolkit.hash(i, 79)))
            let vFade = min(1.0, max(0.06, (0.64 - yn) / 0.28))
            let a = bgPeak * vFade * (0.46 + 0.54 * sin(t * freq + phase))
            if a > 0.01 {
                ctx.fill(
                    Path(ellipseIn: CGRect(x: w * xn - r, y: h * yn - r, width: r * 2, height: r * 2)),
                    with: .color(nodeColor.color(alpha: a))
                )
            }
        }

        // 20 constellation vertices
        var px = [Double](repeating: 0, count: 20)
        var py = [Double](repeating: 0, count: 20)
        var yns = [Double](repeating: 0, count: 20)
        var fades = [Double](repeating: 0, count: 20)
        var phases = [Double](repeating: 0, count: 20)

        for i in 0..<20 {
            let baseX = 0.06 + 0.88 * LiveSceneToolkit.hash(i, 19)
            let rawY = LiveSceneToolkit.hash(i, 37)
            let baseY = i < 16 ? (0.04 + 0.39 * rawY) : (0.36 + 0.16 * rawY)
            let ax = 0.024 + 0.022 * LiveSceneToolkit.hash(i, 53)
            let ay = 0.018 + 0.018 * LiveSceneToolkit.hash(i, 71)
            let fx = 0.26 + 0.24 * LiveSceneToolkit.hash(i, 89)
            let fy = 0.22 + 0.22 * LiveSceneToolkit.hash(i, 103)
            let phase = LiveSceneToolkit.hash(i, 127) * LiveSceneToolkit.twoPi
            phases[i] = phase
            let xn = baseX + ax * sin(t * fx + phase)
            let yn = baseY + ay * cos(t * fy + phase * 1.15)
            px[i] = w * xn
            py[i] = h * yn
            yns[i] = yn
            fades[i] = min(1.0, max(0.06, (0.56 - yn) / 0.24))
        }

        // Triangulation threads
        for i in 0..<20 {
            for j in (i + 1)..<20 {
                let dist = hypot(px[i] - px[j], py[i] - py[j])
                if dist < maxDist {
                    let u = 1.0 - dist / maxDist
                    let midYn = (yns[i] + yns[j]) * 0.5
                    let fadeMid = min(1.0, max(0.0, (0.54 - midYn) / 0.24))
                    let a = linePeak * u * u * u * fadeMid
                    if a > 0.006 {
                        var line = Path()
                        line.move(to: CGPoint(x: px[i], y: py[i]))
                        line.addLine(to: CGPoint(x: px[j], y: py[j]))
                        ctx.stroke(line, with: .color(lineColor.color(alpha: a)), style: StrokeStyle(lineWidth: lineW, lineCap: .round))
                    }
                }
            }
        }

        // Vertices + 5 beacon stars
        let dotPeak = (isDark ? 0.72 : 0.52) * k
        for i in 0..<20 {
            let isAnchor = (i == 1 || i == 5 || i == 10 || i == 14 || i == 18)
            let pulse = 0.62 + 0.38 * sin(t * 1.15 + phases[i])
            let fade = fades[i]
            let x = px[i]
            let y = py[i]
            let r = isAnchor ? max(1.6, minDim * 0.0036) : max(1.0, minDim * (0.0018 + 0.0010 * LiveSceneToolkit.hash(i, 149)))

            if isAnchor {
                LiveSceneToolkit.drawSoftDisc(
                    ctx: &ctx, color: nodeColor, peakAlpha: (isDark ? 0.38 : 0.24) * k, edgeTint: tealTint,
                    cx: x, cy: y, radius: anchorHaloR, scaleX: 0.88 + 0.16 * pulse, scaleY: 0.88 + 0.16 * pulse,
                    alpha: pulse * fade
                )
                let ga = (isDark ? 0.28 : 0.20) * pulse * fade * k
                if ga > 0.01 {
                    let span = glintHalf * (0.88 + 0.16 * pulse)
                    var cross = Path()
                    cross.move(to: CGPoint(x: x - span, y: y))
                    cross.addLine(to: CGPoint(x: x + span, y: y))
                    cross.move(to: CGPoint(x: x, y: y - span))
                    cross.addLine(to: CGPoint(x: x, y: y + span))
                    ctx.stroke(cross, with: .color(nodeColor.color(alpha: ga)), style: StrokeStyle(lineWidth: glintW, lineCap: .round))
                }
            }

            let a = dotPeak * pulse * fade
            if a > 0.01 {
                ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(nodeColor.color(alpha: a)))
            }
        }
    }

    // MARK: - 4. Lava Lamp

    private struct LavaBlob {
        let xBase: Double
        let cycleSpeed: Double
        let phase: Double
        let baseRadiusRatio: Double
        let swayAmp: Double
        let swayFreq: Double
        let slot: Int
        let isSatellite: Bool
    }

    private static let lavaBlobs: [LavaBlob] = [
        LavaBlob(xBase: 0.26, cycleSpeed: 0.095, phase: 0.45, baseRadiusRatio: 0.155, swayAmp: 0.030, swayFreq: 0.18, slot: 0, isSatellite: false),
        LavaBlob(xBase: 0.70, cycleSpeed: 0.085, phase: 2.05, baseRadiusRatio: 0.165, swayAmp: 0.028, swayFreq: 0.16, slot: 1, isSatellite: false),
        LavaBlob(xBase: 0.48, cycleSpeed: 0.112, phase: 3.65, baseRadiusRatio: 0.140, swayAmp: 0.034, swayFreq: 0.21, slot: 2, isSatellite: false),
        LavaBlob(xBase: 0.80, cycleSpeed: 0.092, phase: 5.10, baseRadiusRatio: 0.125, swayAmp: 0.030, swayFreq: 0.19, slot: 0, isSatellite: false),
        LavaBlob(xBase: 0.36, cycleSpeed: 0.125, phase: 1.35, baseRadiusRatio: 0.068, swayAmp: 0.032, swayFreq: 0.24, slot: 2, isSatellite: true)
    ]

    static func drawLavaLamp(
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

        let skyBlend = colors.skyUpperMid.lerp(to: colors.skyLowerMid, 0.50)
        let waxPrimary = colors.accent.lerp(to: skyBlend, isDark ? 0.42 : 0.48)
        let waxSecondary = colors.accent2.lerp(to: skyBlend, isDark ? 0.45 : 0.50)
        let waxWarm = waxPrimary.lerp(to: waxSecondary, 0.38)
        let waxCore = waxPrimary.lerp(to: colors.highlight, isDark ? 0.24 : 0.30)

        let bodyScale = min(1.25, max(0.65, k))
        let crownA = min(0.45, (isDark ? 0.18 : 0.14) * bodyScale)
        let midA = min(0.55, (isDark ? 0.25 : 0.20) * bodyScale)
        let bellyA = min(0.65, (isDark ? 0.31 : 0.24) * bodyScale)

        // Base thermal glow
        LiveSceneToolkit.drawSoftDisc(
            ctx: &ctx,
            color: waxWarm,
            peakAlpha: (isDark ? 0.11 : 0.09) * k,
            edgeTint: waxSecondary,
            cx: w * (0.50 + 0.024 * sin(t * 0.22)),
            cy: h * 0.95,
            radius: minDim * 0.62,
            scaleX: 1.60,
            scaleY: 0.44,
            alpha: 0.88 + 0.12 * cos(t * 0.34)
        )

        // Top cooling wax meniscus
        var topPts: [CGPoint] = []
        for s in 0...36 {
            let xn = Double(s) / 36.0
            let y = h * (0.042 + 0.011 * sin(xn * LiveSceneToolkit.twoPi * 1.4 + t * 0.42 + 0.7) + 0.006 * cos(xn * LiveSceneToolkit.twoPi * 2.6 - t * 0.34))
            topPts.append(CGPoint(x: w * xn, y: y))
        }
        var topPool = LiveSceneToolkit.smoothCurvePath(points: topPts)
        topPool.addLine(to: CGPoint(x: w, y: 0))
        topPool.addLine(to: .zero)
        topPool.closeSubpath()
        ctx.fill(
            topPool,
            with: .linearGradient(
                Gradient(stops: [
                    .init(color: waxSecondary.color(alpha: min(0.45, 0.20 * bodyScale)), location: 0.0),
                    .init(color: waxPrimary.color(alpha: min(0.35, 0.11 * bodyScale)), location: 0.65),
                    .init(color: waxWarm.color(alpha: min(0.20, 0.03 * bodyScale)), location: 1.0)
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: h * 0.085)
            )
        )

        // 5 organically wobbling buoyant blobs
        let unitR = 100.0
        let haloPeak = (isDark ? 0.11 : 0.09) * k
        let hotCorePeak = (isDark ? 0.16 : 0.13) * k

        for spec in lavaBlobs {
            let phaseT = t * spec.cycleSpeed + spec.phase
            let rawSin = sin(phaseT)
            let vy = cos(phaseT)
            let dwell = rawSin * (0.82 + 0.18 * rawSin * rawSin)
            let yn = 0.50 - 0.37 * dwell
            let xn = spec.xBase + spec.swayAmp * sin(t * spec.swayFreq + spec.phase)
            let stretchFactor = 0.11 * (1.0 - rawSin * rawSin)
            let wobbleA = spec.isSatellite ? 0.72 : 0.62
            let wobbleB = spec.isSatellite ? 0.54 : 0.46

            var bx = [Double](repeating: 0, count: 32)
            var by = [Double](repeating: 0, count: 32)
            for s in 0..<32 {
                let theta = LiveSceneToolkit.twoPi * Double(s) / 32.0
                let localR = unitR * (
                    1.0
                    + stretchFactor * (-cos(2.0 * theta))
                    + 0.08 * vy * sin(theta)
                    + 0.045 * sin(3.0 * theta + t * wobbleA + spec.phase)
                    + 0.024 * cos(4.0 * theta - t * wobbleB)
                )
                bx[s] = localR * cos(theta)
                by[s] = localR * sin(theta)
            }

            let blobPath = LiveSceneToolkit.closedSmoothBlob(xs: bx, ys: by)
            let calm = LiveSceneToolkit.calmMask(yn: yn, center: 0.48, halfSpan: 0.24, dip: 0.48)
            let rPx = minDim * spec.baseRadiusRatio * (0.94 + 0.06 * sin(t * 0.42 + spec.phase))
            let scale = rPx / unitR

            let bodyGrad: Gradient
            let haloColor: SceneRGB
            let haloEdge: SceneRGB
            let coreColor: SceneRGB
            let coreEdge: SceneRGB
            switch spec.slot {
            case 0:
                bodyGrad = Gradient(stops: [
                    .init(color: waxSecondary.lerp(to: waxPrimary, 0.40).color(alpha: crownA), location: 0.0),
                    .init(color: waxWarm.color(alpha: midA), location: 0.5),
                    .init(color: waxWarm.lerp(to: waxCore, 0.45).color(alpha: bellyA), location: 1.0)
                ])
                haloColor = waxWarm; haloEdge = waxPrimary
                coreColor = waxCore; coreEdge = waxWarm
            case 1:
                bodyGrad = Gradient(stops: [
                    .init(color: waxSecondary.color(alpha: crownA), location: 0.0),
                    .init(color: waxPrimary.color(alpha: midA), location: 0.5),
                    .init(color: waxWarm.color(alpha: bellyA), location: 1.0)
                ])
                haloColor = waxSecondary; haloEdge = waxPrimary
                coreColor = waxCore.lerp(to: waxPrimary, 0.28); coreEdge = waxSecondary
            default:
                bodyGrad = Gradient(stops: [
                    .init(color: waxPrimary.color(alpha: crownA), location: 0.0),
                    .init(color: waxWarm.lerp(to: waxCore, 0.25).color(alpha: midA), location: 0.5),
                    .init(color: waxCore.color(alpha: bellyA), location: 1.0)
                ])
                haloColor = waxCore; haloEdge = waxWarm
                coreColor = waxCore.lerp(to: colors.highlight, 0.18); coreEdge = waxCore
            }

            var bctx = ctx
            bctx.translateBy(x: w * xn, y: h * yn)
            bctx.scaleBy(x: scale, y: scale)

            LiveSceneToolkit.drawSoftDisc(
                ctx: &bctx, color: haloColor, peakAlpha: haloPeak, edgeTint: haloEdge,
                cx: 0, cy: 0, radius: unitR * 1.95, alpha: calm
            )

            let startPt = CGPoint(x: 0, y: -unitR * 1.25)
            let endPt = CGPoint(x: 0, y: unitR * 1.25)
            for (skinScale, skinAlpha) in [(1.08, 0.10), (1.035, 0.18)] {
                var sctx = bctx
                sctx.opacity = skinAlpha * calm
                sctx.scaleBy(x: skinScale, y: skinScale)
                sctx.fill(blobPath, with: .linearGradient(bodyGrad, startPoint: startPt, endPoint: endPt))
            }

            var mctx = bctx
            mctx.opacity = calm
            mctx.fill(blobPath, with: .linearGradient(bodyGrad, startPoint: startPt, endPoint: endPt))

            var cctx = bctx
            cctx.clip(to: blobPath)
            LiveSceneToolkit.drawSoftDisc(
                ctx: &cctx, color: coreColor, peakAlpha: hotCorePeak * (spec.slot == 1 ? 0.92 : 1.0), edgeTint: coreEdge,
                cx: 0, cy: unitR * 0.22, radius: unitR * 0.85, alpha: calm
            )
            LiveSceneToolkit.drawSoftDisc(
                ctx: &cctx, color: waxCore.lerp(to: colors.highlight, 0.30), peakAlpha: (isDark ? 0.09 : 0.11) * k, edgeTint: waxWarm,
                cx: -unitR * 0.24, cy: -unitR * 0.26, radius: unitR * 0.52, alpha: calm
            )
        }

        // Bottom undulating wax pool
        var botPts: [CGPoint] = []
        for s in 0...36 {
            let xn = Double(s) / 36.0
            let y = h * (0.915 + 0.015 * sin(xn * LiveSceneToolkit.twoPi * 1.3 - t * 0.42) + 0.008 * cos(xn * LiveSceneToolkit.twoPi * 2.7 + t * 0.34))
            botPts.append(CGPoint(x: w * xn, y: y))
        }
        var botPool = LiveSceneToolkit.smoothCurvePath(points: botPts)
        botPool.addLine(to: CGPoint(x: w, y: h))
        botPool.addLine(to: CGPoint(x: 0, y: h))
        botPool.closeSubpath()

        var rimCtx = ctx
        rimCtx.translateBy(x: 0, y: -h * 0.012)
        rimCtx.opacity = 0.85
        rimCtx.fill(
            botPool,
            with: .linearGradient(
                Gradient(stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: waxCore.color(alpha: min(0.25, 0.08 * k)), location: 0.5),
                    .init(color: .clear, location: 1.0)
                ]),
                startPoint: CGPoint(x: 0, y: h * 0.85),
                endPoint: CGPoint(x: 0, y: h * 0.96)
            )
        )
        ctx.fill(
            botPool,
            with: .linearGradient(
                Gradient(stops: [
                    .init(color: waxCore.color(alpha: min(0.45, 0.16 * bodyScale)), location: 0.0),
                    .init(color: waxWarm.color(alpha: min(0.55, 0.24 * bodyScale)), location: 0.42),
                    .init(color: waxPrimary.lerp(to: waxSecondary, 0.35).color(alpha: min(0.65, 0.32 * bodyScale)), location: 1.0)
                ]),
                startPoint: CGPoint(x: 0, y: h * 0.87),
                endPoint: CGPoint(x: 0, y: h)
            )
        )
    }

    // MARK: - 5. Deep Space

    static func drawSpace(
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

        let starCore = colors.highlight.lerp(to: .white, 0.45)
        let starBlue = colors.highlight.lerp(to: SceneRGB(hex: 0xFFAAD4FF), 0.35)
        let starGold = colors.highlight.lerp(to: SceneRGB(hex: 0xFFFFE2B8), 0.32)

        // 3 breathing nebulae
        let nebR = minDim * 0.42
        let breathA = 0.90 + 0.10 * sin(t * 0.08)
        let breathB = 0.90 + 0.10 * cos(t * 0.07 + 1.2)
        LiveSceneToolkit.drawSoftDisc(
            ctx: &ctx, color: colors.accent.lerp(to: colors.accent2, 0.35), peakAlpha: (isDark ? 0.15 : 0.11) * k, edgeTint: colors.skyUpperMid,
            cx: w * (0.24 + 0.015 * sin(t * 0.04)), cy: h * 0.22, radius: nebR, scaleX: 1.42, scaleY: 0.72, rotationDeg: -18, alpha: breathA
        )
        LiveSceneToolkit.drawSoftDisc(
            ctx: &ctx, color: colors.accent2.lerp(to: starBlue, 0.25), peakAlpha: (isDark ? 0.13 : 0.09) * k, edgeTint: colors.accent,
            cx: w * (0.64 - 0.014 * cos(t * 0.05)), cy: h * 0.17, radius: nebR, scaleX: 1.28, scaleY: 0.66, rotationDeg: 14, alpha: breathB
        )
        LiveSceneToolkit.drawSoftDisc(
            ctx: &ctx, color: colors.accent.lerp(to: starGold, 0.28), peakAlpha: (isDark ? 0.12 : 0.08) * k, edgeTint: colors.skyLowerMid,
            cx: w * (0.76 + 0.012 * sin(t * 0.04)), cy: h * 0.78, radius: nebR, scaleX: 1.48, scaleY: 0.68, rotationDeg: -12, alpha: breathA
        )

        // Far & mid stars
        let baseA = isDark ? 0.60 : 0.18
        for i in 0..<48 {
            let xn = LiveSceneToolkit.positiveMod(LiveSceneToolkit.hash(i, 11) + t * 0.0008, 1.0)
            let yn = 0.03 + 0.92 * LiveSceneToolkit.hash(i, 23)
            let r = minDim * (0.0010 + 0.0012 * LiveSceneToolkit.hash(i, 41))
            let phase = LiveSceneToolkit.hash(i, 59) * LiveSceneToolkit.twoPi
            let speed = 0.28 + 0.32 * LiveSceneToolkit.hash(i, 73)
            let calm = LiveSceneToolkit.calmMask(yn: yn, center: 0.48, halfSpan: 0.24, dip: 0.72)
            let a = baseA * (0.54 + 0.46 * sin(t * speed + phase)) * calm * k
            if a > 0.01 {
                ctx.fill(Path(ellipseIn: CGRect(x: w * xn - r, y: h * yn - r, width: r * 2, height: r * 2)), with: .color(starCore.color(alpha: a)))
            }
        }
        for i in 0..<22 {
            let xn = LiveSceneToolkit.positiveMod(LiveSceneToolkit.hash(i, 97) + t * 0.0014, 1.0)
            let yn = 0.04 + 0.90 * LiveSceneToolkit.hash(i, 113)
            let r = minDim * (0.0017 + 0.0014 * LiveSceneToolkit.hash(i, 131))
            let phase = LiveSceneToolkit.hash(i, 149) * LiveSceneToolkit.twoPi
            let warmth = LiveSceneToolkit.hash(i, 167)
            let calm = LiveSceneToolkit.calmMask(yn: yn, center: 0.48, halfSpan: 0.24, dip: 0.74)
            let a = baseA * 1.15 * (0.48 + 0.52 * sin(t * 0.42 + phase)) * calm * k
            if a > 0.01 {
                let tint = starBlue.lerp(to: starGold, warmth)
                ctx.fill(Path(ellipseIn: CGRect(x: w * xn - r, y: h * yn - r, width: r * 2, height: r * 2)), with: .color(tint.color(alpha: a)))
            }
        }

        // 4 bright upper-sky stars with crosshair diffraction glints
        let glintXn = [0.18, 0.42, 0.67, 0.84]
        let glintYn = [0.13, 0.24, 0.11, 0.26]
        let glintPh = [0.5, 2.2, 4.1, 5.4]
        let glintHaloR = minDim * 0.026
        let armLen = minDim * 0.022
        let armW = minDim * 0.0014
        let coreR = minDim * 0.0025

        for i in 0..<4 {
            let xn = LiveSceneToolkit.positiveMod(glintXn[i] + t * 0.0016, 1.0)
            let yn = glintYn[i]
            let px = w * xn
            let py = h * yn
            let pulse = 0.62 + 0.38 * sin(t * 0.46 + glintPh[i])
            let calm = LiveSceneToolkit.calmMask(yn: yn, center: 0.48, halfSpan: 0.24, dip: 0.65)
            LiveSceneToolkit.drawSoftDisc(
                ctx: &ctx, color: starBlue, peakAlpha: (isDark ? 0.42 : 0.26) * k, edgeTint: colors.accent,
                cx: px, cy: py, radius: glintHaloR, scaleX: 0.85 + 0.25 * pulse, scaleY: 0.85 + 0.25 * pulse, alpha: pulse * calm
            )
            let span = armLen * (0.75 + 0.35 * pulse)
            let armA = (isDark ? 0.42 : 0.24) * k * pulse * calm
            let hGrad = Gradient(stops: [.init(color: .clear, location: 0), .init(color: starCore.color(alpha: armA), location: 0.5), .init(color: .clear, location: 1)])
            var hLine = Path()
            hLine.move(to: CGPoint(x: px - span, y: py))
            hLine.addLine(to: CGPoint(x: px + span, y: py))
            ctx.stroke(hLine, with: .linearGradient(hGrad, startPoint: CGPoint(x: px - span, y: py), endPoint: CGPoint(x: px + span, y: py)), lineWidth: armW)
            var vLine = Path()
            vLine.move(to: CGPoint(x: px, y: py - span))
            vLine.addLine(to: CGPoint(x: px, y: py + span))
            ctx.stroke(vLine, with: .linearGradient(hGrad, startPoint: CGPoint(x: px, y: py - span), endPoint: CGPoint(x: px, y: py + span)), lineWidth: armW)
            ctx.fill(
                Path(ellipseIn: CGRect(x: px - coreR, y: py - coreR, width: coreR * 2, height: coreR * 2)),
                with: .color(starCore.color(alpha: (isDark ? 0.86 : 0.44) * pulse * k))
            )
        }

        // Rare meteor every 20s
        let meteorEvery = 20.0
        let meteorDur = 1.1
        let slot = Int(t / meteorEvery)
        let localT = LiveSceneToolkit.positiveMod(t, meteorEvery)
        if localT >= 0.4 && localT <= 0.4 + meteorDur {
            let u = (localT - 0.4) / meteorDur
            let fade = min(1.0, max(0.0, sin(u * .pi)))
            let sx = w * (0.16 + 0.44 * LiveSceneToolkit.hash(slot, 307))
            let sy = h * (0.06 + 0.16 * LiveSceneToolkit.hash(slot, 331))
            let dx = w * 0.20
            let dy = h * 0.09
            let hx = sx + dx * u
            let hy = sy + dy * u
            let tailU = max(0.0, u - 0.32)
            let tx = sx + dx * tailU
            let ty = sy + dy * tailU
            var mp = Path()
            mp.move(to: CGPoint(x: tx, y: ty))
            mp.addLine(to: CGPoint(x: hx, y: hy))
            let peakA = (isDark ? 0.56 : 0.28) * k * fade
            ctx.stroke(
                mp,
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: starBlue.color(alpha: peakA * 0.35), location: 0.6),
                        .init(color: starCore.color(alpha: peakA), location: 1.0)
                    ]),
                    startPoint: CGPoint(x: tx, y: ty),
                    endPoint: CGPoint(x: hx, y: hy)
                ),
                style: StrokeStyle(lineWidth: minDim * 0.0020, lineCap: .round)
            )
        }
    }
}
