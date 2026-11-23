import SwiftUI
import SirajCore

enum LiveScenesAmbient {
    static func drawRings(ctx: inout GraphicsContext, size: CGSize, palette: LiveSceneColors, t: Double, alpha: Double) {
        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.36)
        let maxR = max(size.width, size.height) * 0.65
        for i in 0..<7 {
            let phase = LiveScenesNature.frac(Double(i) / 7.0 + t * 0.05)
            let r = phase * maxR
            let opacity = (1.0 - phase) * 0.34 * alpha
            let col = i % 2 == 0 ? Color(argbHex: palette.accentGlow) : Color(argbHex: palette.secondaryGlow)
            ctx.stroke(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                       with: .color(col.opacity(opacity)), lineWidth: 1.8)
        }
    }

    static func drawCircles(ctx: inout GraphicsContext, size: CGSize, palette: LiveSceneColors, t: Double, alpha: Double) {
        let w = size.width, h = size.height
        for i in 0..<9 {
            let seed = Double(i) * 1.9
            let cx = w * (0.15 + 0.7 * LiveScenesNature.frac(seed * 0.37)) + sin(t * 0.35 + seed) * 26
            let cy = h * (0.12 + 0.75 * LiveScenesNature.frac(seed * 0.61)) + cos(t * 0.28 + seed) * 24
            let r = 36.0 + Double(i % 4) * 28.0
            let col = i % 2 == 0 ? Color(argbHex: palette.accentGlow) : Color(argbHex: palette.secondaryGlow)
            ctx.fill(Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)),
                     with: .radialGradient(Gradient(colors: [col.opacity(0.24 * alpha), .clear]),
                                           center: CGPoint(x: cx, y: cy), startRadius: 2, endRadius: r))
        }
    }

    static func drawParticles(ctx: inout GraphicsContext, size: CGSize, palette: LiveSceneColors, t: Double, alpha: Double) {
        let w = size.width, h = size.height
        for i in 0..<45 {
            let seed = Double(i) * 3.17
            let x = LiveScenesNature.frac(seed * 0.41 + sin(t * 0.15 + seed) * 0.03) * w
            let y = LiveScenesNature.frac(seed * 0.73 - t * 0.025) * h
            let r = 1.6 + Double(i % 4) * 1.1
            let col = i % 3 == 0 ? Color(argbHex: palette.secondaryGlow) : Color(argbHex: palette.accentGlow)
            ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                     with: .color(col.opacity(0.55 * alpha)))
        }
    }

    static func drawLavaLamp(ctx: inout GraphicsContext, size: CGSize, palette: LiveSceneColors, t: Double, alpha: Double) {
        let w = size.width, h = size.height
        for i in 0..<6 {
            let seed = Double(i) * 1.37
            let cx = w * (0.2 + 0.6 * (0.5 + 0.5 * sin(t * 0.22 + seed)))
            let cy = h * (0.15 + 0.7 * (0.5 + 0.5 * cos(t * 0.18 + seed * 1.3)))
            let r = w * (0.22 + Double(i % 3) * 0.07)
            let col = i % 2 == 0 ? Color(argbHex: palette.accentGlow) : Color(argbHex: palette.secondaryGlow)
            ctx.fill(Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)),
                     with: .radialGradient(Gradient(colors: [col.opacity(0.32 * alpha), .clear]),
                                           center: CGPoint(x: cx, y: cy), startRadius: 8, endRadius: r))
        }
    }

    static func drawSpace(ctx: inout GraphicsContext, size: CGSize, palette: LiveSceneColors, t: Double, alpha: Double) {
        LiveScenesNature.drawNightStars(ctx: &ctx, size: size, palette: palette, t: t, alpha: alpha)
        let w = size.width, h = size.height
        let nebulaCenter = CGPoint(x: w * (0.5 + 0.12 * sin(t * 0.12)), y: h * 0.38)
        ctx.fill(
            Path(ellipseIn: CGRect(x: nebulaCenter.x - w * 0.48, y: nebulaCenter.y - h * 0.25, width: w * 0.96, height: h * 0.5)),
            with: .radialGradient(
                Gradient(colors: [
                    Color(argbHex: palette.accentGlow).opacity(0.28 * alpha),
                    Color(argbHex: palette.secondaryGlow).opacity(0.16 * alpha),
                    .clear
                ]),
                center: nebulaCenter, startRadius: 10, endRadius: w * 0.48
            )
        )
    }
}
