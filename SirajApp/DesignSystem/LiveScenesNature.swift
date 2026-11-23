import SwiftUI
import SirajCore

enum LiveScenesNature {
    static func drawDesertDunes(ctx: inout GraphicsContext, size: CGSize, palette: LiveSceneColors, t: Double, alpha: Double) {
        let w = size.width, h = size.height
        let glowCenter = CGPoint(x: w * 0.72, y: h * 0.24)
        ctx.fill(
            Path(ellipseIn: CGRect(x: glowCenter.x - w * 0.45, y: glowCenter.y - w * 0.45, width: w * 0.9, height: w * 0.9)),
            with: .radialGradient(
                Gradient(colors: [Color(argbHex: palette.accentGlow).opacity(0.32 * alpha), .clear]),
                center: glowCenter, startRadius: 8, endRadius: w * 0.45
            )
        )
        for layer in 0..<4 {
            let baseY = h * (0.56 + Double(layer) * 0.11)
            let amp = h * (0.045 - Double(layer) * 0.006)
            let drift = t * (0.14 + Double(layer) * 0.04)
            var path = Path()
            path.move(to: CGPoint(x: 0, y: h))
            for step in 0...40 {
                let x = w * Double(step) / 40.0
                let y = baseY + sin(Double(step) * 0.22 + drift + Double(layer) * 1.4) * amp
                    + cos(Double(step) * 0.11 - drift * 0.6) * amp * 0.5
                path.addLine(to: CGPoint(x: x, y: y))
            }
            path.addLine(to: CGPoint(x: w, y: h))
            path.closeSubpath()
            let col = layer % 2 == 0 ? Color(argbHex: palette.secondaryGlow) : Color(argbHex: palette.accentGlow)
            ctx.fill(path, with: .color(col.opacity((0.18 + Double(layer) * 0.08) * alpha)))
        }
    }

    static func drawSeaWaves(ctx: inout GraphicsContext, size: CGSize, palette: LiveSceneColors, t: Double, alpha: Double) {
        let w = size.width, h = size.height
        for layer in 0..<5 {
            let yBase = h * (0.48 + Double(layer) * 0.11)
            let speed = 0.65 + Double(layer) * 0.18
            let amp = 10.0 + Double(layer) * 4.0
            var path = Path()
            path.move(to: CGPoint(x: 0, y: h))
            for s in 0...48 {
                let x = w * Double(s) / 48.0
                let y = yBase + sin(Double(s) * 0.30 + t * speed + Double(layer)) * amp
                path.addLine(to: CGPoint(x: x, y: y))
            }
            path.addLine(to: CGPoint(x: w, y: h))
            path.closeSubpath()
            let col = layer % 2 == 0 ? Color(argbHex: palette.accentGlow) : Color(argbHex: palette.secondaryGlow)
            ctx.fill(path, with: .color(col.opacity((0.14 + Double(layer) * 0.06) * alpha)))
        }
    }

    static func drawAurora(ctx: inout GraphicsContext, size: CGSize, palette: LiveSceneColors, t: Double, alpha: Double) {
        let w = size.width, h = size.height
        for ribbon in 0..<3 {
            var path = Path()
            let yMid = h * (0.25 + Double(ribbon) * 0.13)
            path.move(to: CGPoint(x: -20, y: yMid))
            for s in 0...32 {
                let x = w * Double(s) / 32.0
                let y = yMid + sin(Double(s) * 0.25 + t * (0.45 + Double(ribbon) * 0.15)) * (h * 0.08)
                path.addLine(to: CGPoint(x: x, y: y))
            }
            let col = ribbon == 1 ? Color(argbHex: palette.secondaryGlow) : Color(argbHex: palette.accentGlow)
            ctx.stroke(path, with: .color(col.opacity(0.26 * alpha)), style: StrokeStyle(lineWidth: 34 + CGFloat(ribbon * 10), lineCap: .round))
        }
    }

    static func drawNightStars(ctx: inout GraphicsContext, size: CGSize, palette: LiveSceneColors, t: Double, alpha: Double) {
        let w = size.width, h = size.height
        for i in 0..<72 {
            let x = frac(sin(Double(i) * 12.9898) * 43758.5453) * w
            let y = frac(sin(Double(i) * 78.233) * 19341.123) * h * 0.82
            let twinkle = 0.35 + 0.65 * (0.5 + 0.5 * sin(t * (1.2 + Double(i % 5) * 0.4) + Double(i)))
            let r = 0.9 + Double(i % 3) * 0.7
            ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                     with: .color(Color.white.opacity(twinkle * 0.85 * alpha)))
        }
        let glow = Color(argbHex: palette.accentGlow)
        ctx.fill(
            Path(ellipseIn: CGRect(x: w * 0.1, y: h * 0.05, width: w * 0.8, height: h * 0.45)),
            with: .radialGradient(Gradient(colors: [glow.opacity(0.18 * alpha), .clear]),
                                  center: CGPoint(x: w * 0.5, y: h * 0.28), startRadius: 10, endRadius: w * 0.42)
        )
    }

    static func drawRosePetals(ctx: inout GraphicsContext, size: CGSize, palette: LiveSceneColors, t: Double, alpha: Double) {
        let w = size.width, h = size.height
        for i in 0..<24 {
            let seed = Double(i) * 1.71
            let speed = 18.0 + Double(i % 5) * 7.0
            let y = (frac(seed * 0.37) * h + t * speed).truncatingRemainder(dividingBy: h + 40) - 20
            let x = frac(seed * 0.63) * w + sin(t * 0.8 + seed) * 24.0
            let col = i % 2 == 0 ? Color(argbHex: palette.accentGlow) : Color(argbHex: palette.secondaryGlow)
            ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 10, height: 6)), with: .color(col.opacity(0.45 * alpha)))
        }
    }

    static func drawSnow(ctx: inout GraphicsContext, size: CGSize, palette: LiveSceneColors, t: Double, alpha: Double) {
        let w = size.width, h = size.height
        for i in 0..<56 {
            let seed = Double(i) * 2.13
            let speed = 22.0 + Double(i % 6) * 9.0
            let y = (frac(seed * 0.29) * h + t * speed).truncatingRemainder(dividingBy: h + 20) - 10
            let x = frac(seed * 0.81) * w + sin(t * 0.9 + seed) * 14.0
            let r = 1.5 + Double(i % 4) * 0.9
            ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                     with: .color(Color.white.opacity(0.65 * alpha)))
        }
    }

    static func drawButterflies(ctx: inout GraphicsContext, size: CGSize, palette: LiveSceneColors, t: Double, alpha: Double) {
        let w = size.width, h = size.height
        for i in 0..<12 {
            let seed = Double(i) * 2.41
            let x = frac(seed * 0.43 + t * 0.018) * (w + 40) - 20
            let y = frac(seed * 0.71) * h * 0.85 + sin(t * 1.4 + seed) * 18.0
            let flap = 0.55 + 0.45 * abs(sin(t * 5.0 + seed))
            let col = i % 2 == 0 ? Color(argbHex: palette.accentGlow) : Color(argbHex: palette.secondaryGlow)
            let wingW = 9.0 * flap
            ctx.fill(Path(ellipseIn: CGRect(x: x - wingW, y: y - 5, width: wingW, height: 10)), with: .color(col.opacity(0.48 * alpha)))
            ctx.fill(Path(ellipseIn: CGRect(x: x, y: y - 5, width: wingW, height: 10)), with: .color(col.opacity(0.48 * alpha)))
        }
    }

    static func frac(_ x: Double) -> Double {
        let r = x - floor(x)
        return r < 0 ? r + 1.0 : r
    }
}
