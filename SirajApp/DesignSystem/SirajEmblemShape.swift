import SwiftUI
import SirajCore

/// Mihrab arch silhouette matching `ic_siraj_emblem` (viewport 96.91 x 100.0, aspect 0.96905).
public struct SirajEmblemShape: Shape {
    public static let viewportWidth: CGFloat = 96.91
    public static let viewportHeight: CGFloat = 100.0
    public static let aspectRatio: CGFloat = 0.96905

    public init() {}

    public func path(in rect: CGRect) -> Path {
        let sx = rect.width / Self.viewportWidth
        let sy = rect.height / Self.viewportHeight
        let ox = rect.minX
        let oy = rect.minY
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: ox + x * sx, y: oy + y * sy)
        }

        var p = Path()
        p.move(to: pt(76.87, 88.96))
        p.addCurve(to: pt(66.86, 89.06), control1: pt(73.59, 89.27), control2: pt(70.17, 89.06))
        p.addCurve(to: pt(47.75, 89.06), control1: pt(60.49, 89.06), control2: pt(54.12, 89.06))
        p.addCurve(to: pt(29.94, 89.06), control1: pt(41.81, 89.06), control2: pt(35.87, 89.06))
        p.addCurve(to: pt(19.96, 88.93), control1: pt(26.66, 89.06), control2: pt(23.17, 89.35))
        p.addCurve(to: pt(19.98, 79.38), control1: pt(19.73, 85.8), control2: pt(19.98, 82.55))
        p.addCurve(to: pt(19.98, 58.38), control1: pt(19.98, 72.38), control2: pt(19.98, 65.38))
        p.addCurve(to: pt(19.98, 43.78), control1: pt(19.98, 53.52), control2: pt(19.98, 48.65))
        p.addCurve(to: pt(20.05, 33.6), control1: pt(19.98, 40.39), control2: pt(19.71, 36.98))
        p.addCurve(to: pt(31.49, 13.59), control1: pt(20.83, 25.75), control2: pt(25.43, 18.49))
        p.addCurve(to: pt(42.12, 6.08), control1: pt(34.88, 10.86), control2: pt(38.6, 8.62))
        p.addCurve(to: pt(48.54, 0.09), control1: pt(44.5, 4.37), control2: pt(46.1, 1.6))
        p.addCurve(to: pt(54.26, 5.74), control1: pt(50.55, 1.85), control2: pt(52.15, 4.05))
        p.addCurve(to: pt(70.19, 18.26), control1: pt(59.95, 10.29), control2: pt(65.21, 12.35))
        p.addCurve(to: pt(76.21, 30.58), control1: pt(73.1, 21.72), control2: pt(75.36, 26.13))
        p.addCurve(to: pt(76.87, 51.26), control1: pt(77.5, 37.35), control2: pt(76.87, 44.4))
        p.addCurve(to: pt(76.95, 88.82), control1: pt(76.87, 63.77), control2: pt(76.72, 76.34))
        p.addLine(to: pt(76.87, 88.96))
        p.closeSubpath()
        return p
    }
}

public struct SirajEmblemMark: View {
    let height: CGFloat
    let tint: Color

    public init(height: CGFloat = 64, tint: Color) {
        self.height = height
        self.tint = tint
    }

    public var body: some View {
        Image("ic_siraj_emblem")
            .renderingMode(.template)
            .resizable()
            .aspectRatio(SirajEmblemShape.aspectRatio, contentMode: .fit)
            .frame(width: height * SirajEmblemShape.aspectRatio, height: height)
            .foregroundStyle(tint)
    }
}

public struct SirajLoadingView: View {
    @Environment(\.sirajTheme) private var theme
    let message: String?
    @State private var phase: CGFloat = 0

    public init(message: String? = nil) {
        self.message = message
    }

    public var body: some View {
        VStack(spacing: 18) {
            ZStack {
                SirajEmblemShape()
                    .stroke(theme.gold.opacity(0.22), lineWidth: 2)
                    .frame(width: 82 * SirajEmblemShape.aspectRatio, height: 82)
                SirajEmblemShape()
                    .trim(from: phase, to: min(1.0, phase + 0.28))
                    .stroke(theme.gold, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: 82 * SirajEmblemShape.aspectRatio, height: 82)
                SirajEmblemMark(height: 68, tint: theme.gold)
            }
            if let message, !message.isEmpty {
                Text(message)
                    .font(theme.scaledFont(size: 14, weight: .medium))
                    .foregroundStyle(theme.onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear {
            guard theme.motionEnabled else { return }
            withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) {
                phase = 0.72
            }
        }
    }
}
