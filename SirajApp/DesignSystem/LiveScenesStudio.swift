import SwiftUI
import SirajCore

enum LiveScenesStudio {
    static func drawSilk(ctx: inout GraphicsContext, size: CGSize, palette: LiveSceneColors, t: Double, alpha: Double) {
        let w = size.width, h = size.height
        for fold in 0..<5 {
            var path = Path()
            let baseY = h * (0.20 + Double(fold) * 0.16)
            path.move(to: CGPoint(x: 0, y: baseY))
            for s in 0...32 {
                let x = w * Double(s) / 32.0
                let y = baseY + sin(Double(s) * 0.18 + t * 0.35 + Double(fold) * 0.9) * 32.0
                path.addLine(to: CGPoint(x: x, y: y))
            }
            let col = fold % 2 == 0 ? Color(argbHex: palette.accentGlow) : Color(argbHex: palette.secondaryGlow)
            ctx.stroke(path, with: .color(col.opacity(0.20 * alpha)), style: StrokeStyle(lineWidth: 26, lineCap: .round))
        }
    }

    static func drawContours(ctx: inout GraphicsContext, size: CGSize, palette: LiveSceneColors, t: Double, alpha: Double) {
        let w = size.width, h = size.height
        for line in 0..<10 {
            var path = Path()
            let y0 = h * (0.08 + Double(line) * 0.095)
            path.move(to: CGPoint(x: 0, y: y0))
            for s in 0...40 {
                let x = w * Double(s) / 40.0
                let dy = sin(Double(s) * 0.24 + t * 0.25 + Double(line) * 0.55) * 16.0
                    + cos(Double(s) * 0.12 - t * 0.18) * 10.0
                path.addLine(to: CGPoint(x: x, y: y0 + dy))
            }
            let col = line % 2 == 0 ? Color(argbHex: palette.accentGlow) : Color(argbHex: palette.secondaryGlow)
            ctx.stroke(path, with: .color(col.opacity(0.26 * alpha)), lineWidth: 1.4)
        }
    }

    static func drawMosaic(ctx: inout GraphicsContext, size: CGSize, palette: LiveSceneColors, t: Double, alpha: Double) {
        let step: CGFloat = 54
        let cols = Int(size.width / step) + 2
        let rows = Int(size.height / step) + 2
        for r in 0..<rows {
            for c in 0..<cols {
                let cx = CGFloat(c) * step + (r % 2 == 0 ? 0 : step / 2)
                let cy = CGFloat(r) * step
                let pulse = 0.35 + 0.65 * (0.5 + 0.5 * sin(t * 0.55 + Double(r + c) * 0.7))
                let d: CGFloat = 14
                var diamond = Path()
                diamond.move(to: CGPoint(x: cx, y: cy - d))
                diamond.addLine(to: CGPoint(x: cx + d, y: cy))
                diamond.addLine(to: CGPoint(x: cx, y: cy + d))
                diamond.addLine(to: CGPoint(x: cx - d, y: cy))
                diamond.closeSubpath()
                let col = (r + c) % 2 == 0 ? Color(argbHex: palette.accentGlow) : Color(argbHex: palette.secondaryGlow)
                ctx.stroke(diamond, with: .color(col.opacity(0.18 * pulse * alpha)), lineWidth: 1.0)
            }
        }
    }

    static func drawWaves(ctx: inout GraphicsContext, size: CGSize, palette: LiveSceneColors, t: Double, alpha: Double) {
        let w = size.width, h = size.height
        for i in 0..<8 {
            var path = Path()
            let y0 = h * (0.18 + Double(i) * 0.10)
            path.move(to: CGPoint(x: 0, y: y0))
            for s in 0...44 {
                let x = w * Double(s) / 44.0
                let y = y0 + sin(Double(s) * 0.28 + t * (0.45 + Double(i) * 0.05) + Double(i)) * 18.0
                path.addLine(to: CGPoint(x: x, y: y))
            }
            let col = i % 2 == 0 ? Color(argbHex: palette.accentGlow) : Color(argbHex: palette.secondaryGlow)
            ctx.stroke(path, with: .color(col.opacity(0.24 * alpha)), lineWidth: 2.2)
        }
    }

    static func drawHarvest(ctx: inout GraphicsContext, size: CGSize, palette: LiveSceneColors, t: Double, alpha: Double) {
        let w = size.width, h = size.height
        ctx.fill(
            Path(ellipseIn: CGRect(x: w * 0.15, y: h * 0.08, width: w * 0.7, height: w * 0.7)),
            with: .radialGradient(
                Gradient(colors: [Color(argbHex: palette.accentGlow).opacity(0.26 * alpha), .clear]),
                center: CGPoint(x: w * 0.5, y: h * 0.30), startRadius: 10, endRadius: w * 0.38
            )
        )
        for i in 0..<18 {
            let baseX = w * (Double(i) + 0.5) / 18.0
            let sway = sin(t * 0.8 + Double(i) * 0.5) * 14.0
            var stalk = Path()
            stalk.move(to: CGPoint(x: baseX, y: h))
            stalk.addQuadCurve(to: CGPoint(x: baseX + sway, y: h * 0.72), control: CGPoint(x: baseX + sway * 0.35, y: h * 0.86))
            let col = i % 2 == 0 ? Color(argbHex: palette.accentGlow) : Color(argbHex: palette.secondaryGlow)
            ctx.stroke(stalk, with: .color(col.opacity(0.28 * alpha)), style: StrokeStyle(lineWidth: 2.0, lineCap: .round))
        }
    }
}
