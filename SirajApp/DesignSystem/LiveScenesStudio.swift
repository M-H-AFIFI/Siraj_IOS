import SwiftUI

enum LiveScenesStudio {

    // MARK: - 1. Silk

    static func drawSilk(
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

        let warm = colors.accent.lerp(to: SceneRGB(hex: 0xFFE07A86), 0.35)
        let cool = colors.accent2.lerp(to: SceneRGB(hex: 0xFF4AC2D4), 0.35)
        let mid = warm.lerp(to: cool, 0.50)

        LiveSceneToolkit.drawSoftDisc(
            ctx: &ctx,
            color: warm.lerp(to: colors.highlight, 0.25),
            peakAlpha: (isDark ? 0.16 : 0.14) * k,
            edgeTint: colors.skyUpperMid,
            cx: w * (0.84 + 0.025 * sin(t * 0.38)),
            cy: h * (0.065 + 0.018 * cos(t * 0.32)),
            radius: minDim * 0.22,
            alpha: 0.85 + 0.15 * sin(t * 0.75)
        )

        let upperGrad = Gradient(stops: [
            .init(color: .clear, location: 0.00),
            .init(color: warm.color(alpha: (isDark ? 0.28 : 0.22) * k), location: 0.18),
            .init(color: mid.color(alpha: (isDark ? 0.32 : 0.24) * k), location: 0.50),
            .init(color: cool.color(alpha: (isDark ? 0.28 : 0.22) * k), location: 0.82),
            .init(color: .clear, location: 1.00)
        ])
        let lowerGrad = Gradient(stops: [
            .init(color: .clear, location: 0.00),
            .init(color: cool.color(alpha: (isDark ? 0.24 : 0.19) * k), location: 0.22),
            .init(color: mid.color(alpha: (isDark ? 0.26 : 0.20) * k), location: 0.52),
            .init(color: warm.color(alpha: (isDark ? 0.24 : 0.19) * k), location: 0.82),
            .init(color: .clear, location: 1.00)
        ])
        let strokeStyle = StrokeStyle(lineWidth: minDim * 0.0014, lineCap: .round, lineJoin: .round)

        func drawRibbon(baseY: Double, spineAmp: Double, twistAmp: Double, spinePhase: Double, twistPhase: Double, speed: Double, grad: Gradient) {
            let strands = 26
            let steps = 36
            for strand in 0..<strands {
                let u = Double(strand) / Double(strands - 1) - 0.5
                let weight = min(1.0, max(0.32, 1.0 - abs(u) * 1.15))
                var pts: [CGPoint] = []
                pts.reserveCapacity(steps + 1)
                for s in 0...steps {
                    let x = -w * 0.04 + w * 1.08 * (Double(s) / Double(steps))
                    let xn = x / w
                    let spine = h * baseY + h * spineAmp * sin(xn * LiveSceneToolkit.twoPi * 1.15 + t * speed + spinePhase)
                    let halfSpan = h * twistAmp * sin(xn * LiveSceneToolkit.twoPi * 0.92 - t * speed * 0.72 + u * 0.42 + twistPhase)
                    let shimmer = h * 0.018 * cos(xn * LiveSceneToolkit.twoPi * 2.1 + u * 2.4 + t * speed * 1.15)
                    pts.append(CGPoint(x: x, y: spine + halfSpan * (0.45 + 1.10 * u) + shimmer))
                }
                var sctx = ctx
                sctx.opacity = weight
                sctx.stroke(
                    LiveSceneToolkit.smoothCurvePath(points: pts),
                    with: .linearGradient(grad, startPoint: .zero, endPoint: CGPoint(x: w, y: 0)),
                    style: strokeStyle
                )
            }
        }

        drawRibbon(baseY: 0.215, spineAmp: 0.056, twistAmp: 0.130, spinePhase: 0.4, twistPhase: 0.9, speed: 0.68, grad: upperGrad)
        drawRibbon(baseY: 0.785, spineAmp: 0.052, twistAmp: 0.120, spinePhase: 2.6, twistPhase: 3.1, speed: -0.56, grad: lowerGrad)
    }

    // MARK: - 2. Contours

    static func drawContours(
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

        let peakX = w * 0.78 + w * 0.020 * sin(t * 0.38)
        let peakY = h * 0.16 + h * 0.015 * cos(t * 0.31)
        let contourTint = colors.accent.lerp(to: colors.accent2, 0.35)
        let summitAmber = colors.accent2.lerp(to: SceneRGB(hex: 0xFFE0B066), 0.55)

        LiveSceneToolkit.drawSoftDisc(
            ctx: &ctx,
            color: summitAmber,
            peakAlpha: (isDark ? 0.45 : 0.38) * k,
            edgeTint: contourTint,
            cx: peakX,
            cy: peakY,
            radius: minDim * 0.042,
            alpha: 0.80 + 0.20 * sin(t * 1.35)
        )
        let dotR = minDim * 0.0045
        ctx.fill(
            Path(ellipseIn: CGRect(x: peakX - dotR, y: peakY - dotR, width: dotR * 2, height: dotR * 2)),
            with: .color(summitAmber.color(alpha: 0.88 * k))
        )

        let fadeGrad = Gradient(stops: [
            .init(color: contourTint.color(alpha: (isDark ? 0.42 : 0.34) * k), location: 0.00),
            .init(color: contourTint.color(alpha: (isDark ? 0.30 : 0.24) * k), location: 0.26),
            .init(color: contourTint.color(alpha: (isDark ? 0.14 : 0.10) * k), location: 0.48),
            .init(color: .clear, location: 0.62),
            .init(color: .clear, location: 1.00)
        ])
        let thinStroke = StrokeStyle(lineWidth: minDim * 0.0014, lineCap: .round, lineJoin: .round)
        let indexStroke = StrokeStyle(lineWidth: minDim * 0.0024, lineCap: .round, lineJoin: .round)
        let tiltRad = -28.0 * .pi / 180.0
        let samples = 40

        let cycleProgress = t * 0.28
        let cycleFloor = Int(floor(cycleProgress))
        let flow = cycleProgress - Double(cycleFloor)

        var xs = [Double](repeating: 0, count: samples)
        var ys = [Double](repeating: 0, count: samples)

        for rIdx in 0..<16 {
            let frac = (Double(rIdx) + flow) / 16.0
            let baseR = minDim * (0.032 + frac * (16.0 * 0.042))
            for s in 0..<samples {
                let theta = LiveSceneToolkit.twoPi * Double(s) / Double(samples)
                let thetaL = theta - tiltRad
                let harmonics = 0.24 * cos(2.0 * thetaL + t * 0.36)
                    + 0.12 * sin(3.0 * thetaL - t * 0.48 + 0.8 + 0.15 * frac)
                    + 0.06 * cos(5.0 * thetaL + t * 0.62 - 0.5)
                let breathe = 0.036 * sin(t * 0.75 + frac * 5.0 + thetaL)
                let r = baseR * (1.0 + harmonics + breathe)
                xs[s] = peakX + r * (1.08 * cos(theta) - 0.06 * sin(thetaL))
                ys[s] = peakY + r * (0.92 * sin(theta) + 0.05 * cos(thetaL))
            }
            let ring = LiveSceneToolkit.closedSmoothBlob(xs: xs, ys: ys)
            let isIndex = (((rIdx - cycleFloor) % 4) + 4) % 4 == 0
            let birthFade = min(1.0, max(0.0, frac / 0.10))
            let outerFade = min(1.0, max(0.0, (1.0 - frac) / 0.22))
            let pulseWave = 0.82 + 0.18 * sin(frac * LiveSceneToolkit.twoPi * 2.0 - t * 1.4)
            let a = min(1.0, max(0.0, birthFade * outerFade * pulseWave * (isIndex ? 1.0 : 0.74)))
            if a > 0.006 {
                var rctx = ctx
                rctx.opacity = a
                rctx.stroke(
                    ring,
                    with: .linearGradient(fadeGrad, startPoint: .zero, endPoint: CGPoint(x: 0, y: h * 0.65)),
                    style: isIndex ? indexStroke : thinStroke
                )
            }
        }
    }

    // MARK: - 3. Mosaic

    static func drawMosaic(
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

        let cols = 7
        let rows = 6
        let count = cols * rows
        var lx = [Double](repeating: 0, count: count)
        var ly = [Double](repeating: 0, count: count)

        for r in 0..<rows {
            let yGrid = -0.04 + (Double(r) / Double(rows - 1)) * 0.60
            for c in 0..<cols {
                let idx = r * cols + c
                let xGrid = -0.06 + (Double(c) / Double(cols - 1)) * 1.12
                let pinX = (c == 0 || c == cols - 1)
                let pinY = (r == 0 || r == rows - 1)
                let jx = pinX ? 0.0 : (LiveSceneToolkit.hash(idx, 13) - 0.5) * 0.11
                let jy = r == 0 ? 0.0 : (LiveSceneToolkit.hash(idx, 29) - 0.5) * 0.065
                let baseX = xGrid + jx
                let baseY = yGrid + jy
                if pinX || pinY {
                    lx[idx] = w * baseX
                    ly[idx] = h * baseY
                } else {
                    let phase = LiveSceneToolkit.hash(idx, 47) * LiveSceneToolkit.twoPi
                    let speed = 0.58 + 0.46 * LiveSceneToolkit.hash(idx, 61)
                    lx[idx] = w * (baseX + 0.032 * cos(t * speed + phase))
                    ly[idx] = h * (baseY + 0.026 * sin(t * speed * 0.85 + phase * 1.2))
                }
            }
        }

        let baseShade = colors.skyUpperMid.lerp(to: colors.shade, 0.35)
        let edgeTint = colors.highlight.lerp(to: colors.accent, 0.30)
        let edgeStyle = StrokeStyle(lineWidth: minDim * 0.0012, lineJoin: .bevel)

        func drawTri(_ ax: Double, _ ay: Double, _ bx: Double, _ by: Double, _ cx: Double, _ cy: Double, triIdx: Int) {
            let cxN = ((ax + bx + cx) / 3.0) / w
            let cyN = ((ay + by + cy) / 3.0) / h
            let fade = min(1.0, max(0.0, (0.56 - cyN) / 0.34))
            let mixA = LiveSceneToolkit.hash(triIdx, 83)
            let mixB = LiveSceneToolkit.hash(triIdx, 107)
            let jewel = colors.accent.lerp(to: colors.accent2, mixA)
            let color = baseShade.lerp(to: jewel, 0.28 + 0.42 * mixB)
            let baseAlpha = (isDark ? 0.24 : 0.18) + 0.14 * LiveSceneToolkit.hash(triIdx, 131)
            let wave01 = 0.5 + 0.5 * sin(t * 1.25 - cxN * 3.0 - cyN * 2.2 + Double(triIdx) * 0.37)
            let fillAlpha = min(0.72, baseAlpha * fade * fade * (0.60 + 0.50 * wave01) * k)
            if fillAlpha <= 0.005 { return }

            var path = Path()
            path.move(to: CGPoint(x: ax, y: ay))
            path.addLine(to: CGPoint(x: bx, y: by))
            path.addLine(to: CGPoint(x: cx, y: cy))
            path.closeSubpath()

            ctx.fill(path, with: .color(color.color(alpha: fillAlpha)))
            let edgeAlpha = min(0.38, fillAlpha * (0.22 + 0.24 * wave01))
            if edgeAlpha > 0.004 {
                ctx.stroke(path, with: .color(edgeTint.color(alpha: edgeAlpha)), style: edgeStyle)
            }
        }

        var triIdx = 0
        for r in 0..<(rows - 1) {
            for c in 0..<(cols - 1) {
                let i00 = r * cols + c
                let i10 = i00 + 1
                let i01 = (r + 1) * cols + c
                let i11 = i01 + 1
                if (r + c) % 2 == 0 {
                    drawTri(lx[i00], ly[i00], lx[i10], ly[i10], lx[i11], ly[i11], triIdx: triIdx); triIdx += 1
                    drawTri(lx[i00], ly[i00], lx[i11], ly[i11], lx[i01], ly[i01], triIdx: triIdx); triIdx += 1
                } else {
                    drawTri(lx[i00], ly[i00], lx[i10], ly[i10], lx[i01], ly[i01], triIdx: triIdx); triIdx += 1
                    drawTri(lx[i10], ly[i10], lx[i11], ly[i11], lx[i01], ly[i01], triIdx: triIdx); triIdx += 1
                }
            }
        }
    }

    // MARK: - 4. Waves

    static func drawWaves(
        ctx: inout GraphicsContext,
        size: CGSize,
        colors: LiveSceneDrawColors,
        t: Double,
        detail: Double
    ) {
        let w = Double(size.width)
        let h = Double(size.height)
        let k = min(1.35, max(0.40, detail))
        let isDark = colors.isDark

        let wavePrimary = colors.accent.lerp(to: colors.highlight, isDark ? 0.18 : 0.12)
        let waveSecondary = colors.accent2.lerp(to: colors.shade, isDark ? 0.22 : 0.16)

        let bases = [0.645, 0.705, 0.768, 0.832, 0.896]
        let amps = [0.032, 0.035, 0.033, 0.029, 0.024]
        let speeds = [-0.62, 0.72, -0.56, 0.48, -0.38]
        let startYs = [0.60, 0.66, 0.73, 0.80, 0.87]
        let topColors = [
            colors.shade.lerp(to: waveSecondary, 0.28),
            colors.shade.lerp(to: wavePrimary, 0.32),
            colors.shade.lerp(to: wavePrimary, 0.24),
            colors.ink.lerp(to: wavePrimary, 0.24),
            colors.ink.lerp(to: waveSecondary, 0.18)
        ]
        let topAlphas = isDark ? [0.18, 0.26, 0.35, 0.45, 0.58] : [0.14, 0.19, 0.25, 0.32, 0.40]
        let botAlphas = isDark ? [0.36, 0.46, 0.58, 0.70, 0.84] : [0.24, 0.31, 0.39, 0.48, 0.58]
        let steps = 56

        for b in 0..<5 {
            var pts: [CGPoint] = []
            pts.reserveCapacity(steps + 1)
            for s in 0...steps {
                let x = -w * 0.03 + w * 1.06 * (Double(s) / Double(steps))
                let xn = x / w
                let y = h * bases[b] + h * amps[b] * (
                    0.68 * sin(xn * LiveSceneToolkit.twoPi * (1.18 + Double(b) * 0.20) + t * speeds[b] + Double(b) * 1.40)
                    + 0.32 * cos(xn * LiveSceneToolkit.twoPi * (2.30 - Double(b) * 0.16) - t * speeds[b] * 0.62)
                )
                pts.append(CGPoint(x: x, y: y))
            }
            var path = LiveSceneToolkit.smoothCurvePath(points: pts)
            path.addLine(to: CGPoint(x: pts[steps].x, y: h))
            path.addLine(to: CGPoint(x: pts[0].x, y: h))
            path.closeSubpath()

            ctx.fill(
                path,
                with: .linearGradient(
                    Gradient(colors: [
                        topColors[b].color(alpha: topAlphas[b] * k),
                        colors.ink.color(alpha: botAlphas[b] * k)
                    ]),
                    startPoint: CGPoint(x: 0, y: h * startYs[b]),
                    endPoint: CGPoint(x: 0, y: h)
                )
            )
        }
    }

    // MARK: - 5. Harvest

    private struct HarvestLeaf {
        let xBase: Double
        let phase: Double
        let fallSpeed: Double
        let swayAmp: Double
        let swayFreq: Double
        let rotAmpDeg: Double
        let scale: Double
        let paletteIdx: Int
        let isMaple: Bool
    }

    private static let harvestLeaves: [HarvestLeaf] = [
        HarvestLeaf(xBase: 0.14, phase: 0.08, fallSpeed: 0.036, swayAmp: 0.042, swayFreq: 1.08, rotAmpDeg: 30, scale: 0.92, paletteIdx: 0, isMaple: true),
        HarvestLeaf(xBase: 0.32, phase: 0.22, fallSpeed: 0.045, swayAmp: 0.048, swayFreq: 0.98, rotAmpDeg: 36, scale: 0.78, paletteIdx: 1, isMaple: false),
        HarvestLeaf(xBase: 0.54, phase: 0.14, fallSpeed: 0.039, swayAmp: 0.038, swayFreq: 1.24, rotAmpDeg: 28, scale: 0.86, paletteIdx: 2, isMaple: true),
        HarvestLeaf(xBase: 0.76, phase: 0.30, fallSpeed: 0.048, swayAmp: 0.054, swayFreq: 1.04, rotAmpDeg: 34, scale: 0.96, paletteIdx: 0, isMaple: true),
        HarvestLeaf(xBase: 0.88, phase: 0.04, fallSpeed: 0.032, swayAmp: 0.036, swayFreq: 0.95, rotAmpDeg: 26, scale: 0.72, paletteIdx: 1, isMaple: false),
        HarvestLeaf(xBase: 0.22, phase: 0.48, fallSpeed: 0.042, swayAmp: 0.046, swayFreq: 1.15, rotAmpDeg: 32, scale: 0.82, paletteIdx: 2, isMaple: false),
        HarvestLeaf(xBase: 0.66, phase: 0.56, fallSpeed: 0.037, swayAmp: 0.044, swayFreq: 1.32, rotAmpDeg: 29, scale: 0.90, paletteIdx: 0, isMaple: true),
        HarvestLeaf(xBase: 0.42, phase: 0.72, fallSpeed: 0.046, swayAmp: 0.050, swayFreq: 1.00, rotAmpDeg: 38, scale: 0.76, paletteIdx: 1, isMaple: true),
        HarvestLeaf(xBase: 0.12, phase: 0.86, fallSpeed: 0.040, swayAmp: 0.040, swayFreq: 1.40, rotAmpDeg: 28, scale: 0.84, paletteIdx: 0, isMaple: false),
        HarvestLeaf(xBase: 0.82, phase: 0.92, fallSpeed: 0.043, swayAmp: 0.045, swayFreq: 1.12, rotAmpDeg: 32, scale: 0.74, paletteIdx: 2, isMaple: true),
        HarvestLeaf(xBase: 0.30, phase: 0.98, fallSpeed: 0.034, swayAmp: 0.037, swayFreq: 1.18, rotAmpDeg: 27, scale: 0.68, paletteIdx: 1, isMaple: false),
        HarvestLeaf(xBase: 0.68, phase: 0.80, fallSpeed: 0.039, swayAmp: 0.041, swayFreq: 1.06, rotAmpDeg: 31, scale: 0.80, paletteIdx: 2, isMaple: true)
    ]

    private static func mapleLeafPath(r: Double) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: -r))
        p.addLine(to: CGPoint(x: r * 0.22, y: -r * 0.48))
        p.addLine(to: CGPoint(x: r * 0.78, y: -r * 0.58))
        p.addLine(to: CGPoint(x: r * 0.46, y: -r * 0.12))
        p.addLine(to: CGPoint(x: r * 0.92, y: r * 0.16))
        p.addLine(to: CGPoint(x: r * 0.34, y: r * 0.36))
        p.addLine(to: CGPoint(x: r * 0.42, y: r * 0.68))
        p.addLine(to: CGPoint(x: r * 0.06, y: r * 0.58))
        p.addLine(to: CGPoint(x: 0, y: r * 1.05))
        p.addLine(to: CGPoint(x: -r * 0.06, y: r * 0.58))
        p.addLine(to: CGPoint(x: -r * 0.42, y: r * 0.68))
        p.addLine(to: CGPoint(x: -r * 0.34, y: r * 0.36))
        p.addLine(to: CGPoint(x: -r * 0.92, y: r * 0.16))
        p.addLine(to: CGPoint(x: -r * 0.46, y: -r * 0.12))
        p.addLine(to: CGPoint(x: -r * 0.78, y: -r * 0.58))
        p.addLine(to: CGPoint(x: -r * 0.22, y: -r * 0.48))
        p.closeSubpath()
        return p
    }

    private static func oakLeafPath(r: Double) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: -r * 0.98))
        p.addCurve(to: CGPoint(x: r * 0.24, y: -r * 0.58), control1: CGPoint(x: r * 0.22, y: -r * 0.92), control2: CGPoint(x: r * 0.36, y: -r * 0.74))
        p.addCurve(to: CGPoint(x: r * 0.36, y: -r * 0.14), control1: CGPoint(x: r * 0.58, y: -r * 0.52), control2: CGPoint(x: r * 0.66, y: -r * 0.26))
        p.addCurve(to: CGPoint(x: r * 0.32, y: r * 0.34), control1: CGPoint(x: r * 0.72, y: -r * 0.02), control2: CGPoint(x: r * 0.68, y: r * 0.28))
        p.addCurve(to: CGPoint(x: r * 0.05, y: r * 0.62), control1: CGPoint(x: r * 0.44, y: r * 0.52), control2: CGPoint(x: r * 0.24, y: r * 0.68))
        p.addLine(to: CGPoint(x: 0, y: r * 1.02))
        p.addLine(to: CGPoint(x: -r * 0.05, y: r * 0.62))
        p.addCurve(to: CGPoint(x: -r * 0.32, y: r * 0.34), control1: CGPoint(x: -r * 0.24, y: r * 0.68), control2: CGPoint(x: -r * 0.44, y: r * 0.52))
        p.addCurve(to: CGPoint(x: -r * 0.36, y: -r * 0.14), control1: CGPoint(x: -r * 0.68, y: r * 0.28), control2: CGPoint(x: -r * 0.72, y: -r * 0.02))
        p.addCurve(to: CGPoint(x: -r * 0.24, y: -r * 0.58), control1: CGPoint(x: -r * 0.66, y: -r * 0.26), control2: CGPoint(x: -r * 0.58, y: -r * 0.52))
        p.addCurve(to: CGPoint(x: 0, y: -r * 0.98), control1: CGPoint(x: -r * 0.36, y: -r * 0.74), control2: CGPoint(x: -r * 0.22, y: -r * 0.92))
        p.closeSubpath()
        return p
    }

    static func drawHarvest(
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

        let gold = colors.accent.lerp(to: SceneRGB(hex: 0xFFD49A4A), 0.52)
        let copper = colors.accent.lerp(to: SceneRGB(hex: 0xFFC86D44), 0.52)
        let russet = colors.accent2.lerp(to: SceneRGB(hex: 0xFFA84C38), 0.50)
        let palette = [gold, copper, russet]
        let leafAlpha = min(0.88, (isDark ? 0.68 : 0.56) * k)
        let veinTint = colors.highlight.lerp(to: gold, 0.35)
        let veinAlpha = (isDark ? 0.28 : 0.24) * k

        // Upper canopy glow pools
        let glowR = minDim * 0.34
        LiveSceneToolkit.drawSoftDisc(
            ctx: &ctx, color: gold, peakAlpha: (isDark ? 0.20 : 0.16) * k, edgeTint: copper,
            cx: w * (0.20 + 0.015 * sin(t * 0.45)), cy: h * 0.08, radius: glowR, scaleX: 1.45, scaleY: 0.82,
            alpha: 0.85 + 0.15 * sin(t * 0.55)
        )
        LiveSceneToolkit.drawSoftDisc(
            ctx: &ctx, color: copper, peakAlpha: (isDark ? 0.18 : 0.15) * k, edgeTint: russet,
            cx: w * (0.82 - 0.015 * cos(t * 0.42)), cy: h * 0.11, radius: glowR, scaleX: 1.40, scaleY: 0.85,
            alpha: 0.85 + 0.15 * cos(t * 0.52)
        )

        // Swaying foliage canopies in top corners
        var canopyL = Path()
        canopyL.move(to: .zero)
        canopyL.addLine(to: CGPoint(x: w * 0.52, y: 0))
        canopyL.addCurve(to: CGPoint(x: w * 0.22, y: h * 0.16), control1: CGPoint(x: w * 0.44, y: h * 0.08), control2: CGPoint(x: w * 0.30, y: h * 0.11))
        canopyL.addCurve(to: CGPoint(x: 0, y: h * 0.28), control1: CGPoint(x: w * 0.14, y: h * 0.21), control2: CGPoint(x: w * 0.06, y: h * 0.22))
        canopyL.closeSubpath()

        var canopyR = Path()
        canopyR.move(to: CGPoint(x: w, y: 0))
        canopyR.addLine(to: CGPoint(x: w * 0.44, y: 0))
        canopyR.addCurve(to: CGPoint(x: w * 0.80, y: h * 0.17), control1: CGPoint(x: w * 0.56, y: h * 0.07), control2: CGPoint(x: w * 0.72, y: h * 0.12))
        canopyR.addCurve(to: CGPoint(x: w, y: h * 0.29), control1: CGPoint(x: w * 0.89, y: h * 0.22), control2: CGPoint(x: w * 0.95, y: h * 0.22))
        canopyR.closeSubpath()

        var lctx = ctx
        lctx.rotate(by: .degrees(2.2 * sin(t * 0.65)))
        lctx.fill(canopyL, with: .linearGradient(Gradient(colors: [russet.color(alpha: (isDark ? 0.26 : 0.16) * k), .clear]), startPoint: .zero, endPoint: CGPoint(x: 0, y: h * 0.30)))

        var rctx = ctx
        rctx.translateBy(x: w, y: 0)
        rctx.rotate(by: .degrees(-2.2 * sin(t * 0.65 + 1.1)))
        rctx.translateBy(x: -w, y: 0)
        rctx.fill(canopyR, with: .linearGradient(Gradient(colors: [copper.color(alpha: (isDark ? 0.24 : 0.15) * k), .clear]), startPoint: .zero, endPoint: CGPoint(x: 0, y: h * 0.30)))

        // 12 drifting maple & oak leaves
        let leafR = 24.0
        let maple = mapleLeafPath(r: leafR)
        let oak = oakLeafPath(r: leafR)
        var vein = Path()
        vein.move(to: CGPoint(x: 0, y: leafR * 1.15))
        vein.addLine(to: CGPoint(x: 0, y: -leafR * 0.78))
        vein.move(to: CGPoint(x: 0, y: leafR * 0.15))
        vein.addLine(to: CGPoint(x: -leafR * 0.42, y: -leafR * 0.22))
        vein.move(to: CGPoint(x: 0, y: leafR * 0.15))
        vein.addLine(to: CGPoint(x: leafR * 0.42, y: -leafR * 0.22))

        let scaleUnit = (minDim * 0.024) / leafR
        for (idx, spec) in harvestLeaves.enumerated() {
            let yn = -0.04 + LiveSceneToolkit.positiveMod(spec.phase + t * spec.fallSpeed, 1.06)
            let xn = spec.xBase + spec.swayAmp * sin(t * spec.swayFreq + spec.phase * LiveSceneToolkit.twoPi)
            let topFade = min(1.0, max(0.0, (yn + 0.04) / 0.08))
            let midFade: Double
            if yn < 0.35 {
                midFade = 1.0
            } else if yn < 0.65 {
                midFade = (1.0 - (yn - 0.35) / 0.30) * 0.88 + 0.12
            } else if yn < 0.88 {
                midFade = 0.14 + 0.22 * ((yn - 0.65) / 0.23)
            } else {
                midFade = min(1.0, max(0.0, (1.02 - yn) / 0.14)) * 0.36
            }
            let calm = LiveSceneToolkit.calmMask(yn: yn, center: 0.48, halfSpan: 0.18, dip: 0.55)
            let alpha = min(1.0, max(0.0, topFade * midFade * calm))
            if alpha <= 0.02 { continue }

            let rotDeg = spec.rotAmpDeg * sin(t * spec.swayFreq * 1.15 + spec.phase * 5.0)
                + Double((idx * 37) % 50) - 25.0
            let sc = scaleUnit * spec.scale
            let flutterX = sc * (0.72 + 0.28 * cos(t * spec.swayFreq * 1.35 + Double(idx)))

            var fctx = ctx
            fctx.translateBy(x: w * xn, y: h * yn)
            fctx.rotate(by: .degrees(rotDeg))
            fctx.scaleBy(x: flutterX, y: sc)
            fctx.fill(spec.isMaple ? maple : oak, with: .color(palette[spec.paletteIdx].color(alpha: leafAlpha * alpha)))
            fctx.stroke(vein, with: .color(veinTint.color(alpha: veinAlpha * alpha)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
        }
    }
}
