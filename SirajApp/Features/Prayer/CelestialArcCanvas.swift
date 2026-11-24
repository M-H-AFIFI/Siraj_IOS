import Foundation
import SwiftUI
import SirajCore

struct CelestialArcCanvas: View {
    let colors: SkyColors
    let twilight: SkyTwilight
    let arc: SolarArc
    let moon: MoonPhaseInfo
    let timeSeconds: Double
    let motionEnabled: Bool
    var cornerRadius: CGFloat = 32

    private static let twoPi = Double.pi * 2.0
    private static let referenceCardHeight: CGFloat = 318.0
    private static let cloudLoop: CGFloat = 1.7
    private static let farCloudLoopSeconds = 900.0
    private static let nearCloudLoopSeconds = 600.0
    private static let nightCloudStrength = 0.42
    private static let rayTurnSeconds = 600.0
    private static let meteorCycle = 22.0
    private static let meteorSeconds = 1.1
    private static let firstMeteor = 3.2
    private static let flightCycle = 45.0
    private static let flightSeconds = 19.0
    private static let firstFlight = 1.2
    private static let restingFlight = 0.62
    private static let glintCycle = 13.0
    private static let glintDelay = 5.0
    private static let glintSeconds = 1.3
    private static let waterPace = 0.55
    private static let roadHead: CGFloat = 9.0
    private static let roadSpread: CGFloat = 38.0
    private static let lampRanks: [Double] = [0.0, 0.35, 0.45, 0.15, 0.25, 0.55, 0.62]
    private static let starTints: [Color] = [
        .white, Color(argbHex: 0xFFDCE6FF), Color(argbHex: 0xFFFFF1DC), .white, Color(argbHex: 0xFFE8EEFF)
    ]

    private struct StarSpec {
        let x: CGFloat, y: CGFloat, r: CGFloat, phase: Double
    }

    private struct CloudSpec {
        let x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, layer: Int, bumps: Int, seed: Int
    }

    private static let starSpecs: [StarSpec] = [
        StarSpec(x: 0.06, y: 0.11, r: 0.85, phase: 0.02), StarSpec(x: 0.12, y: 0.17, r: 0.70, phase: 0.47),
        StarSpec(x: 0.17, y: 0.07, r: 1.05, phase: 0.71), StarSpec(x: 0.24, y: 0.13, r: 0.75, phase: 0.19),
        StarSpec(x: 0.31, y: 0.08, r: 0.90, phase: 0.58), StarSpec(x: 0.41, y: 0.06, r: 1.15, phase: 0.86),
        StarSpec(x: 0.47, y: 0.15, r: 0.65, phase: 0.33), StarSpec(x: 0.55, y: 0.07, r: 0.80, phase: 0.09),
        StarSpec(x: 0.61, y: 0.19, r: 0.70, phase: 0.64), StarSpec(x: 0.67, y: 0.09, r: 1.00, phase: 0.28),
        StarSpec(x: 0.73, y: 0.14, r: 0.70, phase: 0.91), StarSpec(x: 0.81, y: 0.08, r: 1.10, phase: 0.42),
        StarSpec(x: 0.88, y: 0.13, r: 0.80, phase: 0.77), StarSpec(x: 0.94, y: 0.09, r: 0.90, phase: 0.15),
        StarSpec(x: 0.08, y: 0.25, r: 0.70, phase: 0.53), StarSpec(x: 0.15, y: 0.30, r: 0.60, phase: 0.81),
        StarSpec(x: 0.21, y: 0.22, r: 0.55, phase: 0.37), StarSpec(x: 0.27, y: 0.28, r: 0.65, phase: 0.68),
        StarSpec(x: 0.35, y: 0.21, r: 0.60, phase: 0.05), StarSpec(x: 0.44, y: 0.27, r: 0.55, phase: 0.44),
        StarSpec(x: 0.52, y: 0.23, r: 0.60, phase: 0.95), StarSpec(x: 0.58, y: 0.31, r: 0.55, phase: 0.22),
        StarSpec(x: 0.66, y: 0.25, r: 0.65, phase: 0.61), StarSpec(x: 0.70, y: 0.21, r: 0.75, phase: 0.13),
        StarSpec(x: 0.78, y: 0.29, r: 0.60, phase: 0.74), StarSpec(x: 0.86, y: 0.23, r: 0.70, phase: 0.31),
        StarSpec(x: 0.93, y: 0.27, r: 0.60, phase: 0.88), StarSpec(x: 0.04, y: 0.36, r: 0.55, phase: 0.50),
        StarSpec(x: 0.19, y: 0.40, r: 0.50, phase: 0.17), StarSpec(x: 0.33, y: 0.37, r: 0.55, phase: 0.79),
        StarSpec(x: 0.49, y: 0.41, r: 0.50, phase: 0.26), StarSpec(x: 0.63, y: 0.38, r: 0.55, phase: 0.66),
        StarSpec(x: 0.76, y: 0.42, r: 0.50, phase: 0.11), StarSpec(x: 0.90, y: 0.36, r: 0.60, phase: 0.56),
        StarSpec(x: 0.11, y: 0.47, r: 0.45, phase: 0.84), StarSpec(x: 0.29, y: 0.50, r: 0.50, phase: 0.39),
        StarSpec(x: 0.57, y: 0.48, r: 0.45, phase: 0.72), StarSpec(x: 0.83, y: 0.46, r: 0.50, phase: 0.24)
    ]

    private static let cloudSpecs: [CloudSpec] = [
        CloudSpec(x: 0.65, y: 0.28, w: 52, h: 16, layer: 0, bumps: 4, seed: 3),
        CloudSpec(x: 1.18, y: 0.36, w: 60, h: 18, layer: 0, bumps: 4, seed: 4),
        CloudSpec(x: 0.12, y: 0.24, w: 42, h: 13, layer: 0, bumps: 3, seed: 7),
        CloudSpec(x: 0.82, y: 0.50, w: 76, h: 22, layer: 1, bumps: 5, seed: 5),
        CloudSpec(x: 1.46, y: 0.53, w: 68, h: 20, layer: 1, bumps: 5, seed: 6)
    ]

    private static let mistBanks: [(CGFloat, CGFloat, Double, CGFloat, CGFloat, Double)] = [
        (0.10, 0.42, 1.0 / 260.0, -3, 0.15, 0.80),
        (0.70, 0.52, 1.0 / 340.0, 4, 0.13, 0.72),
        (1.15, 0.36, 1.0 / 220.0, 9, 0.12, 0.62),
        (1.50, 0.46, 1.0 / 300.0, -7, 0.14, 0.60)
    ]

    private static let frondDirs: [(CGFloat, CGFloat)] = [
        (-1.00, -0.30), (-0.92, 0.26), (-0.50, -0.78),
        (0.50, -0.78), (0.92, 0.26), (1.00, -0.30), (0.06, -1.02)
    ]

    var body: some View {
        Canvas { ctx, size in
            guard size.width > 1, size.height > 1 else { return }
            let geo = SceneGeometry(size: size)
            let t = motionEnabled ? timeSeconds : 0.0
            let nightness = colors.starAlpha
            let orb = geo.bezierPoint(arc.progress)
            let moonCenter: CGPoint? = arc.isDaytime ? nil : orb
            let lightsAlpha = resolvedLightsAlpha()

            drawSkyBase(ctx: &ctx, geo: geo, orb: orb)
            drawTwilight(ctx: &ctx, geo: geo)
            if twilight.milkyWay > 0.01 {
                drawMilkyWay(ctx: &ctx, geo: geo, strength: twilight.milkyWay)
            }
            if colors.starAlpha > 0.02 {
                let dustStrength = max(0.0, min(1.0, (colors.starAlpha - 0.35) / 0.65))
                if dustStrength > 0.02 {
                    drawStarDust(ctx: &ctx, geo: geo, strength: dustStrength)
                }
                drawStars(ctx: &ctx, geo: geo, t: t, moonCenter: moonCenter)
            }

            if motionEnabled {
                let mw = max(twilight.milkyWay, max(0.0, min(1.0, (colors.starAlpha - 0.7) / 0.3)) * 0.5)
                let mp = meteorProgress(t: t, weight: mw)
                if mp >= 0 {
                    drawMeteor(ctx: &ctx, geo: geo, t: t, p: mp)
                }
            }

            drawArcAndTrail(ctx: &ctx, geo: geo)

            let cloudStrength = max(colors.cloudAlpha, nightness * Self.nightCloudStrength)
            let lowSun = min(1.0, max(twilight.sunriseGlow, max(twilight.sunsetGlow, twilight.shafaq * 0.8)))
            if cloudStrength > 0.02 {
                let farDrift = motionEnabled ? CGFloat((t / Self.farCloudLoopSeconds).truncatingRemainder(dividingBy: 1.0)) * Self.cloudLoop : 0
                drawClouds(ctx: &ctx, geo: geo, layer: 0, drift: farDrift, orb: orb, nightness: nightness, lowSun: lowSun, deckAlpha: cloudStrength * 0.62)
            }

            let breath = motionEnabled ? 0.5 + 0.5 * sin(t * 0.65) : 0.5
            let beaconPulse = motionEnabled ? 0.5 + 0.5 * sin(t * 1.45) : 0.5
            if arc.isDaytime {
                if colors.rayAlpha > 0.02 {
                    let turn = motionEnabled ? (t / Self.rayTurnSeconds).truncatingRemainder(dividingBy: 1.0) * 360.0 : 0.0
                    drawSunRays(ctx: &ctx, geo: geo, orb: orb, strength: colors.rayAlpha, turnDegrees: turn)
                }
                drawMilestones(ctx: &ctx, geo: geo, beaconPulse: beaconPulse)
                drawSun(ctx: &ctx, geo: geo, orb: orb, breath: breath)
            } else {
                drawMilestones(ctx: &ctx, geo: geo, beaconPulse: beaconPulse)
                drawMoon(ctx: &ctx, orb: orb, breath: breath)
            }

            if cloudStrength > 0.02 {
                let nearDrift = motionEnabled ? CGFloat((t / Self.nearCloudLoopSeconds).truncatingRemainder(dividingBy: 1.0)) * Self.cloudLoop : 0
                drawClouds(ctx: &ctx, geo: geo, layer: 1, drift: nearDrift, orb: orb, nightness: nightness, lowSun: lowSun, deckAlpha: cloudStrength * 0.85)
            }

            drawSkyline(ctx: &ctx, geo: geo, orbX: orb.x, lightsAlpha: lightsAlpha)
            drawStillWater(ctx: &ctx, geo: geo, orbX: orb.x)
            drawMovingWater(ctx: &ctx, geo: geo, orbX: orb.x, lightsAlpha: lightsAlpha, t: t)
            if lightsAlpha > 0.02 {
                drawLampGlow(ctx: &ctx, geo: geo, t: t, alpha: lightsAlpha)
            }
            if twilight.mist > 0.01 {
                drawMist(ctx: &ctx, geo: geo, t: t, strength: twilight.mist)
            }
            if motionEnabled && arc.isDaytime {
                let elev = min(1.0, max(0.0, 1.0 - abs(arc.progress - 0.5) * 2.0))
                let sunUp = min(1.0, elev / 0.12) * max(0.0, 1.0 - colors.starAlpha)
                if sunUp > 0.02 {
                    drawCrescentGlint(ctx: &ctx, geo: geo, t: t, strength: sunUp)
                }
            }
            let flight = motionEnabled ? flightProgress(t: t, weight: twilight.birds) : (twilight.birds > 0.3 ? Self.restingFlight : -1.0)
            if flight >= 0 {
                let cycle = motionEnabled ? Int(floor((t - Self.firstFlight) / Self.flightCycle)) : 0
                drawBirds(ctx: &ctx, geo: geo, t: t, flight: flight, cycle: cycle, weight: twilight.birds)
            }

            drawVignetteAndRim(ctx: &ctx, geo: geo, orb: orb, nightness: nightness)
        }
    }

    // MARK: - Sky, Twilight & Stars

    private func drawSkyBase(ctx: inout GraphicsContext, geo: SceneGeometry, orb: CGPoint) {
        let grad = Gradient(colors: colors.sky.map { Color(argb: $0) })
        ctx.fill(
            Path(CGRect(origin: .zero, size: geo.size)),
            with: .linearGradient(grad, startPoint: .zero, endPoint: CGPoint(x: 0, y: geo.h))
        )

        if colors.isWarmGlow {
            let bloomCenter = CGPoint(x: geo.w * 0.5, y: geo.horizonY)
            ctx.fill(
                Path(CGRect(origin: .zero, size: geo.size)),
                with: .radialGradient(
                    Gradient(colors: [Color(argb: colors.orbGlow).opacity(0.20), .clear]),
                    center: bloomCenter, startRadius: 0, endRadius: geo.w * 0.72
                )
            )
        }

        if arc.isDaytime {
            let low = sunLow(arc.progress, span: 0.14)
            if low > 0.01 {
                let r = geo.w * 0.78
                ctx.fill(
                    Path(ellipseIn: CGRect(x: orb.x - r, y: orb.y - r, width: r * 2, height: r * 2)),
                    with: .radialGradient(
                        Gradient(stops: [
                            .init(color: Color(argbHex: 0xFFFFBC6B).opacity(0.28 * low), location: 0.0),
                            .init(color: Color(argbHex: 0xFFFF8F5A).opacity(0.10 * low), location: 0.45),
                            .init(color: .clear, location: 1.0)
                        ]),
                        center: orb, startRadius: 0, endRadius: r
                    )
                )
            }
        }
    }

    private func drawTwilight(ctx: inout GraphicsContext, geo: SceneGeometry) {
        if twilight.falseDawn > 0.01 {
            let k = twilight.falseDawn
            let foot = CGPoint(x: geo.w * 0.13, y: geo.horizonY)
            let reach = geo.horizonY - geo.h * 0.10
            ctx.drawLayer { layer in
                layer.clip(to: Path(CGRect(x: 0, y: 0, width: geo.w, height: geo.horizonY)))
                layer.translateBy(x: foot.x, y: foot.y)
                layer.scaleBy(x: 0.17, y: 1.0)
                layer.fill(
                    Path(ellipseIn: CGRect(x: -reach, y: -reach, width: reach * 2, height: reach * 2)),
                    with: .radialGradient(
                        Gradient(stops: [
                            .init(color: Color(argbHex: 0xFFD2DCFF).opacity(0.13 * k), location: 0.0),
                            .init(color: Color(argbHex: 0xFFC8D2FF).opacity(0.06 * k), location: 0.35),
                            .init(color: Color(argbHex: 0xFFC8D2FF).opacity(0.02 * k), location: 0.70),
                            .init(color: .clear, location: 1.0)
                        ]),
                        center: .zero, startRadius: 0, endRadius: reach
                    )
                )
            }
        }
        if twilight.trueDawn > 0.01 {
            horizonBand(ctx: &ctx, geo: geo, cy: geo.horizonY - 20, radius: geo.w * 1.1, squash: 0.20, cx: geo.w * 0.06,
                        c0: Color(argbHex: 0xFFF4F6FF), a0: 0.62, c1: Color(argbHex: 0xFFDCE4FF), a1: 0.30, c2: Color(argbHex: 0xFFD6E0FF), a2: 0.08, strength: twilight.trueDawn)
        }
        if twilight.sunriseGlow > 0.01 {
            horizonBand(ctx: &ctx, geo: geo, cy: geo.horizonY, radius: geo.w * 0.95, squash: 0.30, cx: geo.w * 0.06,
                        c0: Color(argbHex: 0xFFFFB46B), a0: 0.55, c1: Color(argbHex: 0xFFFF8F6B), a1: 0.24, c2: Color(argbHex: 0xFFFFC8A0), a2: 0.06, strength: twilight.sunriseGlow)
        }
        if twilight.sunsetGlow > 0.01 {
            horizonBand(ctx: &ctx, geo: geo, cy: geo.horizonY, radius: geo.w * 1.0, squash: 0.32, cx: geo.w * 0.94,
                        c0: Color(argbHex: 0xFFFFC266), a0: 0.50, c1: Color(argbHex: 0xFFFF9A4D), a1: 0.22, c2: Color(argbHex: 0xFFFFD8A0), a2: 0.05, strength: twilight.sunsetGlow)
        }
        if twilight.shafaq > 0.01 {
            horizonBand(ctx: &ctx, geo: geo, cy: geo.horizonY, radius: geo.w * 0.9, squash: 0.34, cx: geo.w * 0.94,
                        c0: Color(argbHex: 0xFFFF6E3C), a0: 0.70, c1: Color(argbHex: 0xFFDC4646), a1: 0.34, c2: Color(argbHex: 0xFFB03A5A), a2: 0.08, strength: twilight.shafaq)
        }
    }

    private func horizonBand(
        ctx: inout GraphicsContext, geo: SceneGeometry,
        cy: CGFloat, radius: CGFloat, squash: CGFloat, cx: CGFloat,
        c0: Color, a0: Double, c1: Color, a1: Double, c2: Color, a2: Double, strength: Double
    ) {
        ctx.drawLayer { layer in
            layer.translateBy(x: 0, y: cy)
            layer.scaleBy(x: 1, y: squash)
            layer.fill(
                Path(CGRect(x: 0, y: -radius, width: geo.w, height: radius * 2)),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: c0.opacity(a0 * strength), location: 0.0),
                        .init(color: c1.opacity(a1 * strength), location: 0.30),
                        .init(color: c2.opacity(a2 * strength), location: 0.65),
                        .init(color: .clear, location: 1.0)
                    ]),
                    center: CGPoint(x: cx, y: 0), startRadius: 0, endRadius: radius
                )
            )
        }
    }

    private func drawMilkyWay(ctx: inout GraphicsContext, geo: SceneGeometry, strength: Double) {
        let center = CGPoint(x: geo.w * 0.52, y: geo.h * 0.36)
        let half = geo.h * 0.16
        ctx.drawLayer { layer in
            layer.translateBy(x: center.x, y: center.y)
            layer.rotate(by: .degrees(-24))
            layer.fill(
                Path(CGRect(x: -geo.w * 0.8, y: -half, width: geo.w * 1.6, height: half * 2)),
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: Color(argbHex: 0xFFBEC8FF).opacity(0.15 * strength), location: 0.5),
                        .init(color: .clear, location: 1.0)
                    ]),
                    startPoint: CGPoint(x: 0, y: -half),
                    endPoint: CGPoint(x: 0, y: half)
                )
            )
        }
        let cosA = cos(-24.0 * .pi / 180.0)
        let sinA = sin(-24.0 * .pi / 180.0)
        let faintColor = Color(argbHex: 0xFFE1E6FF).opacity(0.24 * strength)
        let brightColor = Color(argbHex: 0xFFE1E6FF).opacity(0.48 * strength)
        for i in 0..<90 {
            let lx = (Self.seeded(i * 5 + 11) - 0.5) * Double(geo.w) * 1.4
            let ly = (Self.seeded(i * 5 + 12) - 0.5) * Double(geo.h) * 0.22 * (0.4 + Self.seeded(i * 5 + 13))
            let px = center.x + CGFloat(lx * cosA - ly * sinA)
            let py = center.y + CGFloat(lx * sinA + ly * cosA)
            let bright = Self.seeded(i * 5 + 14) > 0.66
            ctx.fill(Path(ellipseIn: CGRect(x: px - 0.45, y: py - 0.45, width: 0.9, height: 0.9)),
                     with: .color(bright ? brightColor : faintColor))
        }
    }

    private func drawStarDust(ctx: inout GraphicsContext, geo: SceneGeometry, strength: Double) {
        let faint = Color(argbHex: 0xFFDDE4FF).opacity(0.30 * strength)
        let bright = Color.white.opacity(0.55 * strength)
        for i in 0..<110 {
            let x = CGFloat(Self.seeded(i * 7 + 401)) * geo.w
            let y = geo.h * 0.66 * CGFloat(pow(Self.seeded(i * 7 + 402), 1.35))
            let isBright = Self.seeded(i * 7 + 403) > 0.74
            let r: CGFloat = isBright ? 0.55 : 0.45
            ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                     with: .color(isBright ? bright : faint))
        }
    }

    private func drawStars(ctx: inout GraphicsContext, geo: SceneGeometry, t: Double, moonCenter: CGPoint?) {
        let dim = colors.starAlpha
        let twinklePhase = (t / 4.2).truncatingRemainder(dividingBy: 1.0)
        for (index, spec) in Self.starSpecs.enumerated() {
            let center = CGPoint(x: geo.w * spec.x, y: geo.h * spec.y)
            let r = spec.r * geo.u
            let emerge = min(1.0, max(0.0, (1.15 - Double(spec.r)) / 0.7)) * 0.55
            let twinkles = spec.r >= 0.8
            let twinkle: Double = !twinkles ? 0.90 : (motionEnabled ? 0.80 + 0.20 * sin(Self.twoPi * (twinklePhase + spec.phase)) : 0.85)
            let out = min(1.0, max(0.0, (dim - emerge) / 0.35))
            var vis = min(1.0, max(0.0, Double(geo.horizonY - center.y) / Double(geo.horizonY * 0.55))) * out * (0.5 + 0.5 * dim)
            if let mc = moonCenter {
                let d = hypot(center.x - mc.x, center.y - mc.y)
                vis *= min(1.0, max(0.0, Double(d - 24.0) / 46.0))
            }
            if vis < 0.02 { continue }
            let tint = Self.starTints[index % Self.starTints.count]
            let hr = r * 2.4
            ctx.fill(Path(ellipseIn: CGRect(x: center.x - hr, y: center.y - hr, width: hr * 2, height: hr * 2)),
                     with: .color(tint.opacity(twinkle * 0.16 * vis)))
            ctx.fill(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                     with: .color(tint.opacity(twinkle * 0.90 * vis)))
            if spec.r > 1.02 {
                let l = 4.5 * CGFloat(0.7 + 0.3 * twinkle)
                let gc = tint.opacity(0.45 * twinkle * vis)
                var hp = Path()
                hp.move(to: CGPoint(x: center.x - l, y: center.y))
                hp.addLine(to: CGPoint(x: center.x + l, y: center.y))
                hp.move(to: CGPoint(x: center.x, y: center.y - l))
                hp.addLine(to: CGPoint(x: center.x, y: center.y + l))
                ctx.stroke(hp, with: .color(gc), style: StrokeStyle(lineWidth: 0.5, lineCap: .round))
            }
        }
    }

    private func meteorProgress(t: Double, weight: Double) -> Double {
        if weight < 0.05 || t < Self.firstMeteor { return -1 }
        let local = t - Self.firstMeteor
        let cycle = Int(floor(local / Self.meteorCycle))
        if cycle > 0 && Self.seeded(cycle * 13 + 5) > 0.2 + 0.6 * weight { return -1 }
        let start = cycle == 0 ? 0.0 : Self.seeded(cycle * 13 + 9) * (Self.meteorCycle - Self.meteorSeconds)
        let p = (local - Double(cycle) * Self.meteorCycle - start) / Self.meteorSeconds
        return (0.0...1.0).contains(p) ? p : -1
    }

    private func drawMeteor(ctx: inout GraphicsContext, geo: SceneGeometry, t: Double, p: Double) {
        let s = Int(floor((t - Self.firstMeteor) / Self.meteorCycle)) * 13
        let angle = (16.0 + 22.0 * Self.seeded(s + 2)) * .pi / 180.0
        let dirX = cos(angle) * (Self.seeded(s + 1) > 0.5 ? -1.0 : 1.0)
        let dirY = sin(angle)
        let startX = geo.w * CGFloat(0.18 + 0.64 * Self.seeded(s + 3))
        let startY = geo.h * CGFloat(0.05 + 0.20 * Self.seeded(s + 4))
        let travel = geo.w * CGFloat(0.24 + 0.10 * Self.seeded(s + 6))
        let eased = 1.0 - (1.0 - p) * (1.0 - p)
        let head = CGPoint(x: startX + CGFloat(dirX * eased) * travel, y: startY + CGFloat(dirY * eased) * travel)
        if head.y > geo.horizonY * 0.8 { return }
        let glow = min(1.0, max(0.0, sin(.pi * p)))
        let tail = 64.0 * (0.35 + 0.65 * glow)
        let end = CGPoint(x: head.x - CGFloat(dirX * tail), y: head.y - CGFloat(dirY * tail))

        var line = Path()
        line.move(to: end)
        line.addLine(to: head)
        ctx.stroke(
            line,
            with: .linearGradient(Gradient(colors: [.clear, Color(argbHex: 0xFFCFDBFF).opacity(0.22 * glow)]), startPoint: end, endPoint: head),
            style: StrokeStyle(lineWidth: 3.4, lineCap: .round)
        )
        ctx.stroke(
            line,
            with: .linearGradient(Gradient(colors: [.clear, Color.white.opacity(0.92 * glow)]), startPoint: end, endPoint: head),
            style: StrokeStyle(lineWidth: 1.2, lineCap: .round)
        )
        ctx.fill(
            Path(ellipseIn: CGRect(x: head.x - 5, y: head.y - 5, width: 10, height: 10)),
            with: .radialGradient(Gradient(colors: [Color.white.opacity(0.55 * glow), .clear]), center: head, startRadius: 0, endRadius: 5)
        )
        ctx.fill(Path(ellipseIn: CGRect(x: head.x - 1.1, y: head.y - 1.1, width: 2.2, height: 2.2)),
                 with: .color(Color.white.opacity(0.95 * glow)))
    }

    // MARK: - Arc, Trail, Milestones, Sun & Moon

    private func drawArcAndTrail(ctx: inout GraphicsContext, geo: SceneGeometry) {
        let arcColors = colors.arc.map { Color(argb: $0) }
        let arcGrad = Gradient(colors: arcColors)
        ctx.stroke(
            geo.arcPath,
            with: .linearGradient(arcGrad, startPoint: CGPoint(x: 0, y: geo.horizonY), endPoint: CGPoint(x: geo.w, y: geo.horizonY)),
            style: StrokeStyle(lineWidth: 1.6, lineCap: .round, dash: [4, 6])
        )

        var trail = Path()
        let endP = min(1.0, max(0.0, arc.progress))
        let steps = 52
        trail.move(to: geo.bezierPoint(0))
        for i in 1...steps {
            trail.addLine(to: geo.bezierPoint(endP * Double(i) / Double(steps)))
        }
        let trailGrad = Gradient(stops: [
            .init(color: Color(argb: colors.orbGlow).opacity(0.08), location: 0.0),
            .init(color: Color(argb: colors.orbGlow).opacity(0.65), location: 0.8),
            .init(color: Color(argb: colors.orbCore).opacity(0.92), location: 1.0)
        ])
        let orbPt = geo.bezierPoint(endP)
        ctx.stroke(
            trail,
            with: .linearGradient(trailGrad, startPoint: geo.p0, endPoint: orbPt),
            style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
        )
        ctx.stroke(
            trail,
            with: .linearGradient(trailGrad, startPoint: geo.p0, endPoint: orbPt),
            style: StrokeStyle(lineWidth: 2.0, lineCap: .round)
        )
    }

    private func drawMilestones(ctx: inout GraphicsContext, geo: SceneGeometry, beaconPulse: Double) {
        let padX: CGFloat = 14
        let clearance: CGFloat = 4
        for m in arc.milestones {
            let raw = geo.bezierPoint(m.progress)
            let pt = CGPoint(x: min(geo.w - padX, max(padX, raw.x)), y: min(geo.horizonY - clearance, max(padX, raw.y)))
            let dist = abs(arc.progress - m.progress)
            let alpha = dist < 0.05 ? min(1.0, max(0.0, dist / 0.05)) : 1.0
            if alpha < 0.06 { continue }

            if m.isNext {
                let outer = 7.0 * CGFloat(0.88 + 0.24 * beaconPulse)
                ctx.fill(diamondPath(center: pt, radius: outer),
                         with: .color(Color(argb: colors.orbGlow).opacity(0.26 * (0.70 + 0.60 * beaconPulse) * alpha)))
                ctx.fill(diamondPath(center: pt, radius: 3.4),
                         with: .color(Color(argbHex: 0xFFFFD54F).opacity(alpha)))
                ctx.fill(diamondPath(center: pt, radius: 1.5),
                         with: .color(Color.white.opacity(0.90 * alpha)))
            } else {
                ctx.fill(Path(ellipseIn: CGRect(x: pt.x - 4.4, y: pt.y - 4.4, width: 8.8, height: 8.8)),
                         with: .color(Color(argb: colors.orbGlow).opacity((m.isPast ? 0.22 : 0.34) * alpha)))
                let r: CGFloat = m.isPast ? 1.8 : 2.2
                ctx.fill(Path(ellipseIn: CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)),
                         with: .color(Color.white.opacity((m.isPast ? 0.42 : 0.80) * alpha)))
            }
        }
    }

    private func diamondPath(center: CGPoint, radius: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: center.x, y: center.y - radius))
        p.addLine(to: CGPoint(x: center.x + radius, y: center.y))
        p.addLine(to: CGPoint(x: center.x, y: center.y + radius))
        p.addLine(to: CGPoint(x: center.x - radius, y: center.y))
        p.closeSubpath()
        return p
    }

    private func drawSunRays(ctx: inout GraphicsContext, geo: SceneGeometry, orb: CGPoint, strength: Double, turnDegrees: Double) {
        let low = sunLow(arc.progress, span: 0.12)
        let reach = 110.0 + max(0.0, geo.w * 0.50 - 110.0) * CGFloat(low)
        let rayColor = ArgbColor.lerp(colors.orbGlow, ArgbColor.hex(0xFFFFB070), low)
        let alpha = min(1.0, (0.045 + 0.02 * low) * strength)
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: 4.5))
            layer.translateBy(x: orb.x, y: orb.y)
            layer.rotate(by: .degrees(turnDegrees))
            for k in 0..<12 {
                let angle = Double(k) * Self.twoPi / 12.0
                let halfSpread = 0.032 + 0.013 * Double((k * 7) % 3)
                var wedge = Path()
                wedge.move(to: .zero)
                wedge.addLine(to: CGPoint(x: cos(angle - halfSpread) * Double(reach), y: sin(angle - halfSpread) * Double(reach)))
                wedge.addLine(to: CGPoint(x: cos(angle + halfSpread) * Double(reach), y: sin(angle + halfSpread) * Double(reach)))
                wedge.closeSubpath()
                layer.fill(
                    wedge,
                    with: .radialGradient(
                        Gradient(stops: [
                            .init(color: Color(argb: rayColor).opacity(alpha * 2.2), location: 0.0),
                            .init(color: Color(argb: rayColor).opacity(alpha * 0.65), location: 0.6),
                            .init(color: .clear, location: 1.0)
                        ]),
                        center: .zero, startRadius: 0, endRadius: reach
                    )
                )
            }
        }
    }

    private func drawSun(ctx: inout GraphicsContext, geo: SceneGeometry, orb: CGPoint, breath: Double) {
        let warm = sunLow(arc.progress, span: 0.12)
        let near = sunLow(arc.progress, span: 0.08)
        let low = near * near
        let warmGlow = ArgbColor.lerp(colors.orbGlow, ArgbColor.hex(0xFFFF8A4C), warm)
        let core = ArgbColor.lerp(ArgbColor.lerp(colors.orbCore, ArgbColor.hex(0xFFFFD54F), warm), ArgbColor.hex(0xFFFFBE6A), low)

        let auraR: CGFloat = 42.0 * CGFloat(0.96 + 0.08 * breath)
        let auraStr = 0.88 + 0.24 * breath
        ctx.fill(
            Path(ellipseIn: CGRect(x: orb.x - auraR, y: orb.y - auraR, width: auraR * 2, height: auraR * 2)),
            with: .radialGradient(
                Gradient(colors: [
                    Color(argb: warmGlow).opacity(min(1.0, 0.46 * auraStr)),
                    Color(argb: warmGlow).opacity(min(1.0, 0.19 * auraStr)),
                    Color(argbHex: 0xFFFFE082).opacity(0.055),
                    .clear
                ]),
                center: orb, startRadius: 0, endRadius: auraR
            )
        )

        let chromoR: CGFloat = 18.0
        ctx.fill(
            Path(ellipseIn: CGRect(x: orb.x - chromoR, y: orb.y - chromoR, width: chromoR * 2, height: chromoR * 2)),
            with: .radialGradient(
                Gradient(colors: [Color.white.opacity(0.95), Color(argb: warmGlow).opacity(0.68), .clear]),
                center: orb, startRadius: 0, endRadius: chromoR
            )
        )

        if low > 0.01 {
            let flare = geo.w * 0.36
            ctx.drawLayer { layer in
                layer.translateBy(x: orb.x, y: orb.y)
                layer.scaleBy(x: 1.0, y: 0.06)
                layer.fill(
                    Path(ellipseIn: CGRect(x: -flare, y: -flare, width: flare * 2, height: flare * 2)),
                    with: .radialGradient(
                        Gradient(stops: [
                            .init(color: Color(argbHex: 0xFFFFE2B0).opacity(0.55 * low), location: 0.0),
                            .init(color: Color(argbHex: 0xFFFFB46B).opacity(0.22 * low), location: 0.25),
                            .init(color: .clear, location: 1.0)
                        ]),
                        center: .zero, startRadius: 0, endRadius: flare
                    )
                )
            }
        }

        ctx.drawLayer { layer in
            layer.translateBy(x: orb.x, y: orb.y)
            layer.scaleBy(x: CGFloat(1.0 + 0.10 * low), y: CGFloat(1.0 - 0.08 * low))
            let r1 = CGFloat(7.2 * (1.0 + 0.22 * low))
            let r2 = CGFloat(4.6 * (1.0 + 0.30 * low))
            layer.fill(Path(ellipseIn: CGRect(x: -r1, y: -r1, width: r1 * 2, height: r1 * 2)), with: .color(Color(argb: core)))
            let inner = ArgbColor.lerp(ArgbColor.hex(0xFFFFFFFF), ArgbColor.hex(0xFFFFDDA6), low)
            layer.fill(Path(ellipseIn: CGRect(x: -r2, y: -r2, width: r2 * 2, height: r2 * 2)), with: .color(Color(argb: inner)))
        }
    }

    private func drawMoon(ctx: inout GraphicsContext, orb: CGPoint, breath: Double) {
        let moonR: CGFloat = 12.0
        let lit = min(1.0, max(0.0, moon.illumination))
        let glow = 0.30 + 0.70 * lit
        let haloGlow = glow * (0.85 + 0.30 * breath)

        let haloR = CGFloat(28.0 * (0.95 + 0.10 * breath))
        ctx.fill(
            Path(ellipseIn: CGRect(x: orb.x - haloR, y: orb.y - haloR, width: haloR * 2, height: haloR * 2)),
            with: .radialGradient(
                Gradient(colors: [Color.white.opacity(min(1.0, 0.28 * haloGlow)), Color(argbHex: 0xFFCBD5E1).opacity(min(1.0, 0.10 * haloGlow)), .clear]),
                center: orb, startRadius: 0, endRadius: haloR
            )
        )

        let discGlow: CGFloat = 16.0
        ctx.fill(
            Path(ellipseIn: CGRect(x: orb.x - discGlow, y: orb.y - discGlow, width: discGlow * 2, height: discGlow * 2)),
            with: .radialGradient(
                Gradient(colors: [Color.white.opacity(0.50 * glow), Color(argbHex: 0xFFE2E8F0).opacity(0.18 * glow), .clear]),
                center: orb, startRadius: 0, endRadius: discGlow
            )
        )

        let unlit = 1.0 - lit
        if unlit > 0.03 {
            ctx.fill(
                Path(ellipseIn: CGRect(x: orb.x - moonR, y: orb.y - moonR, width: moonR * 2, height: moonR * 2)),
                with: .radialGradient(
                    Gradient(colors: [Color(argbHex: 0xFFCBD5E1).opacity(0.10 * unlit), Color(argbHex: 0xFF94A3B8).opacity(0.04 * unlit), .clear]),
                    center: orb, startRadius: 0, endRadius: moonR
                )
            )
        }

        let litPath = moonLimbPath(center: orb, radius: moonR, phaseFraction: moon.phaseFraction)
        let dirX: CGFloat = moon.waxing ? 1.0 : -1.0
        ctx.fill(
            litPath,
            with: .linearGradient(
                Gradient(colors: [.white, Color(argbHex: 0xFFF8FAFC), Color(argbHex: 0xFFCBD5E1).opacity(0.94)]),
                startPoint: CGPoint(x: orb.x + moonR * 0.85 * dirX, y: orb.y - moonR * 0.65),
                endPoint: CGPoint(x: orb.x - moonR * 0.65 * dirX, y: orb.y + moonR * 0.65)
            )
        )
    }

    // MARK: - Volumetric Clouds

    private func drawClouds(
        ctx: inout GraphicsContext, geo: SceneGeometry,
        layer targetLayer: Int, drift: CGFloat, orb: CGPoint,
        nightness: Double, lowSun: Double, deckAlpha: Double
    ) {
        let m = min(1.0, max(0.0, nightness))
        let light = ArgbColor.lerp(colors.cloudLight, ArgbColor.hex(0xFFD6E4FA), m)
        let dark = ArgbColor.lerp(colors.cloudDark, ArgbColor.hex(0xFF141D32), m)
        let lining = ArgbColor.lerp(colors.orbCore, ArgbColor.hex(0xFFFFFFFF), m)
        let horizon = colors.sky.last ?? colors.orbGlow
        let shadowColor = ArgbColor.lerp(light, dark, 0.72)
        let crownColor = ArgbColor.lerp(light, lining, 0.18)
        let underColor = ArgbColor.lerp(horizon, colors.orbCore, 0.45)

        ctx.drawLayer { deck in
            deck.opacity = min(1.0, deckAlpha)
            deck.addFilter(.blur(radius: targetLayer == 0 ? 2.4 : 1.8))

            for c in Self.cloudSpecs where c.layer == targetLayer {
                let rawX = (c.x + drift).truncatingRemainder(dividingBy: Self.cloudLoop)
                let cx = (rawX - (Self.cloudLoop - 1.0) / 2.0) * geo.w
                let cw = c.w * geo.u
                let ch = c.h * geo.u
                let baseY = c.y * geo.h
                if cx + cw < -10 || cx - cw > geo.w + 10 { continue }

                let side = min(1.0, max(-1.0, Double((orb.x - cx) / max(1.0, geo.w * 0.42))))
                let near = min(1.0, max(0.0, 1.0 - Double(hypot(orb.x - cx, orb.y - (baseY - ch * 0.5)) / max(1.0, geo.w * 0.34))))
                let silver = min(1.0, 0.35 * m + 0.8 * near * near * (1.0 - 0.5 * m))

                var cloudPath = Path()
                let summit = CGFloat(Self.seeded(c.seed * 7 + 1) - 0.5) * 0.18 * cw
                let baseCount = max(c.bumps, 4)
                for i in 0..<baseCount {
                    let f = CGFloat(Double(i) + 0.5) / CGFloat(baseCount)
                    let bx = cx - 0.38 * cw + 0.76 * cw * f + CGFloat(Self.seeded(c.seed * 17 + i) - 0.5) * 0.04 * cw
                    let dist = abs(bx - (cx + summit)) / (0.45 * cw)
                    let swell = max(0, 1 - dist * dist)
                    let ry = ch * (0.28 + 0.12 * swell) * CGFloat(0.95 + 0.10 * Self.seeded(c.seed * 31 + i))
                    let rx = ry * CGFloat(1.50 + 0.20 * Self.seeded(c.seed * 19 + i))
                    let by = baseY - ry * 0.65 - 0.06 * ch * swell
                    cloudPath.addEllipse(in: CGRect(x: bx - rx, y: by - ry, width: rx * 2, height: ry * 2))
                }
                let mainRy = ch * CGFloat(0.36 + 0.06 * Self.seeded(c.seed * 29))
                let mainRx = mainRy * CGFloat(1.45 + 0.10 * Self.seeded(c.seed * 37))
                let crownX = cx + summit
                cloudPath.addEllipse(in: CGRect(x: crownX - mainRx, y: baseY - ch * 0.56 - mainRy, width: mainRx * 2, height: mainRy * 2))
                let lRy = mainRy * 0.82
                cloudPath.addEllipse(in: CGRect(x: crownX - 0.18 * cw - lRy * 1.4, y: baseY - ch * 0.46 - lRy, width: lRy * 2.8, height: lRy * 2))
                let rRy = mainRy * 0.78
                cloudPath.addEllipse(in: CGRect(x: crownX + 0.20 * cw - rRy * 1.4, y: baseY - ch * 0.44 - rRy, width: rRy * 2.8, height: rRy * 2))

                // Volumetric top-lit to shadow gradient shifted subtly toward the orb side
                let lightShiftX = CGFloat(side) * cw * 0.28
                deck.fill(
                    cloudPath,
                    with: .linearGradient(
                        Gradient(stops: [
                            .init(color: Color(argb: crownColor), location: 0.0),
                            .init(color: Color(argb: shadowColor), location: 0.82),
                            .init(color: Color(argb: lowSun > 0.05 ? ArgbColor.lerp(shadowColor, underColor, lowSun * 0.55) : shadowColor), location: 1.0)
                        ]),
                        startPoint: CGPoint(x: cx + lightShiftX, y: baseY - ch * 1.05),
                        endPoint: CGPoint(x: cx - lightShiftX * 0.4, y: baseY + ch * 0.10)
                    )
                )

                if silver > 0.06 {
                    deck.stroke(
                        cloudPath,
                        with: .linearGradient(
                            Gradient(colors: [Color(argb: lining).opacity(0.52 * silver), .clear]),
                            startPoint: CGPoint(x: cx + lightShiftX, y: baseY - ch),
                            endPoint: CGPoint(x: cx - lightShiftX, y: baseY)
                        ),
                        lineWidth: 1.1
                    )
                }
            }
        }
    }

    // MARK: - Mosque, Dunes & Palms Skyline

    private func drawSkyline(ctx: inout GraphicsContext, geo: SceneGeometry, orbX: CGFloat, lightsAlpha: Double) {
        let horizonSky = colors.sky.last ?? ArgbColor.hex(0xFF14243F)
        let daylight = min(1.0, max(0.0, 1.0 - colors.starAlpha))
        let ink = ArgbColor.hex(0xFF03060F)
        let ridgeColor = ArgbColor.lerp(ink, horizonSky, 0.30 + 0.22 * daylight)
        let duneTop = ArgbColor.lerp(ink, horizonSky, 0.10 + 0.16 * daylight)
        let stone = ArgbColor.lerp(ink, horizonSky, 0.07 + 0.19 * daylight)

        ctx.fill(
            Path(CGRect(x: 0, y: geo.horizonY - 26, width: geo.w, height: 36)),
            with: .linearGradient(
                Gradient(colors: [.clear, Color(argb: colors.orbGlow).opacity(arc.isDaytime ? 0.16 : 0.09)]),
                startPoint: CGPoint(x: 0, y: geo.horizonY - 26),
                endPoint: CGPoint(x: 0, y: geo.horizonY + 10)
            )
        )

        ctx.fill(geo.farRidgePath, with: .color(Color(argb: ridgeColor).opacity(0.70)))
        ctx.fill(
            geo.midDunePath,
            with: .linearGradient(
                Gradient(colors: [Color(argb: duneTop).opacity(0.92), Color(argb: ArgbColor.lerp(duneTop, ink, 0.6)).opacity(0.97)]),
                startPoint: CGPoint(x: 0, y: geo.horizonY - 18),
                endPoint: CGPoint(x: 0, y: geo.h)
            )
        )

        let crown = ArgbColor.lerp(stone, horizonSky, 0.16 * daylight)
        ctx.fill(
            geo.mosquePath,
            with: .linearGradient(
                Gradient(colors: [Color(argb: crown), Color(argb: ArgbColor.lerp(stone, ink, 0.35)), Color(argb: ArgbColor.lerp(stone, ink, 0.55))]),
                startPoint: CGPoint(x: 0, y: geo.baseY - 76),
                endPoint: CGPoint(x: 0, y: geo.h)
            )
        )
        ctx.fill(geo.palmsPath, with: .color(Color(argb: stone)))

        if arc.isDaytime && daylight > 0.05 {
            let low = min(1.0, abs(arc.progress - 0.5) * 2.0)
            let warmth = daylight * (0.10 + 0.16 * low)
            let sunGrad = GraphicsContext.Shading.radialGradient(
                Gradient(colors: [Color(argb: colors.orbGlow).opacity(warmth), .clear]),
                center: CGPoint(x: min(geo.w, max(0, orbX)), y: geo.baseY - 40),
                startRadius: 0,
                endRadius: geo.w * 0.55
            )
            ctx.fill(geo.mosquePath, with: sunGrad)
            ctx.fill(geo.palmsPath, with: sunGrad)
        }

        // Day silhouettes of the dome and minaret crescents
        drawCrescentFinials(ctx: &ctx, geo: geo, color: Color(argb: stone), grandAlpha: 1.0, minaretAlpha: 1.0)

        if lightsAlpha > 0.02 {
            drawMosqueLights(ctx: &ctx, geo: geo, alpha: lightsAlpha)
        }
    }

    private func drawCrescentFinials(ctx: inout GraphicsContext, geo: SceneGeometry, color: Color, grandAlpha: Double, minaretAlpha: Double) {
        func drawCutCrescent(cx: CGFloat, cy: CGFloat, r: CGFloat, alpha: Double) {
            guard alpha > 0.01 else { return }
            ctx.drawLayer { layer in
                layer.opacity = alpha
                layer.fill(Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)), with: .color(color))
                let cutR = r * 0.82
                let cutCx = cx + r * 0.42
                let cutCy = cy - r * 0.16
                layer.blendMode = .destinationOut
                layer.fill(Path(ellipseIn: CGRect(x: cutCx - cutR, y: cutCy - cutR, width: cutR * 2, height: cutR * 2)), with: .color(.black))
            }
        }
        drawCutCrescent(cx: geo.cx, cy: geo.baseY - 73 * geo.u, r: 3.0 * geo.u, alpha: grandAlpha)
        let rMin = 1.7 * geo.u
        drawCutCrescent(cx: geo.leftMinaretX, cy: geo.baseY - 72 * geo.u - rMin * 1.1, r: rMin, alpha: minaretAlpha)
        drawCutCrescent(cx: geo.rightMinaretX, cy: geo.baseY - 57 * geo.u - rMin * 1.1, r: rMin, alpha: minaretAlpha)
    }

    private func drawMosqueLights(ctx: inout GraphicsContext, geo: SceneGeometry, alpha: Double) {
        let u = geo.u
        let cx = geo.cx

        func window(x: CGFloat, dy: CGFloat, ww: CGFloat, hh: CGFloat, strength: Double, rank: Double) {
            let on = lampOn(alpha: alpha, rank: rank)
            if on < 0.01 { return }
            let wPx = ww * u
            let hPx = hh * u
            let left = x - wPx / 2
            let top = geo.baseY - dy * u
            let center = CGPoint(x: x, y: top + hPx / 2)
            let halo = 8 * u
            ctx.fill(
                Path(ellipseIn: CGRect(x: center.x - halo, y: center.y - halo, width: halo * 2, height: halo * 2)),
                with: .radialGradient(Gradient(colors: [Color(argbHex: 0xFFFFC46B).opacity(0.42 * strength * on), .clear]),
                                      center: center, startRadius: 0, endRadius: halo)
            )
            ctx.fill(
                Path(roundedRect: CGRect(x: left, y: top, width: wPx, height: hPx), cornerRadius: 1.5 * u),
                with: .color(Color(argbHex: 0xFFFFE0A3).opacity(0.95 * strength * on))
            )
        }

        window(x: geo.leftMinaretX, dy: 46, ww: 2.3, hh: 4.8, strength: 1.0, rank: Self.lampRanks[1])
        window(x: geo.rightMinaretX, dy: 37, ww: 2.0, hh: 4.2, strength: 0.9, rank: Self.lampRanks[2])
        window(x: cx - 5.8 * u, dy: 37, ww: 2.4, hh: 5.6, strength: 0.95, rank: Self.lampRanks[3])
        window(x: cx + 5.8 * u, dy: 37, ww: 2.4, hh: 5.6, strength: 0.95, rank: Self.lampRanks[4])
        window(x: geo.leftDomeX, dy: 28, ww: 2.1, hh: 4.4, strength: 0.8, rank: Self.lampRanks[5])
        window(x: geo.rightDomeX, dy: 28, ww: 2.1, hh: 4.4, strength: 0.8, rank: Self.lampRanks[6])
        for (i, wx) in geo.arcadeWindowXs.enumerated() {
            window(x: wx, dy: 15.5, ww: 1.8, hh: 4.0, strength: 0.62, rank: 0.30 + 0.65 * Self.seeded(i * 7 + 3))
        }

        let gate = lampOn(alpha: alpha, rank: Self.lampRanks[0])
        ctx.fill(
            geo.gatePath,
            with: .linearGradient(
                Gradient(colors: [Color(argbHex: 0xFFFFC46B).opacity(0.88 * gate), Color(argbHex: 0xFFFF9E3D).opacity(0.28 * gate)]),
                startPoint: CGPoint(x: cx, y: geo.baseY - 18 * u),
                endPoint: CGPoint(x: cx, y: geo.baseY - 9 * u)
            )
        )
        let spillCenter = CGPoint(x: cx, y: geo.baseY - 9 * u)
        let spillR = 16 * u
        ctx.fill(
            Path(ellipseIn: CGRect(x: spillCenter.x - spillR, y: spillCenter.y - spillR, width: spillR * 2, height: spillR * 2)),
            with: .radialGradient(Gradient(colors: [Color(argbHex: 0xFFFF9E3D).opacity(0.22 * gate), .clear]),
                                  center: spillCenter, startRadius: 0, endRadius: spillR)
        )

        drawCrescentFinials(
            ctx: &ctx, geo: geo,
            color: Color(argbHex: 0xFFFFD54F),
            grandAlpha: 0.95 * lampOn(alpha: alpha, rank: 0.7),
            minaretAlpha: 0.85 * lampOn(alpha: alpha, rank: 0.8)
        )
    }

    private func drawLampGlow(ctx: inout GraphicsContext, geo: SceneGeometry, t: Double, alpha: Double) {
        for (i, lamp) in geo.lamps.enumerated() {
            let r = (i == 0 ? 15.0 : 9.0) * geo.u
            let baseA = i == 0 ? 0.22 : 0.26
            let flicker = motionEnabled ? (0.90 + 0.10 * sin(t * 0.9 + Double(i) * 1.7)) : 1.0
            let on = lampOn(alpha: alpha, rank: i < Self.lampRanks.count ? Self.lampRanks[i] : 0.5)
            let eff = min(1.0, max(0.0, flicker * on))
            if eff < 0.01 { continue }
            ctx.fill(
                Path(ellipseIn: CGRect(x: lamp.x - r, y: lamp.y - r, width: r * 2, height: r * 2)),
                with: .radialGradient(
                    Gradient(colors: [Color(argbHex: 0xFFFFC46B).opacity(baseA * eff), .clear]),
                    center: lamp, startRadius: 0, endRadius: r
                )
            )
        }
    }

    // MARK: - Reflecting Pool & Water Shimmer

    private struct WaterRoad {
        let core: ArgbColor, halo: ArgbColor, column: ArgbColor, strength: Double
    }

    private func waterRoad() -> WaterRoad? {
        guard (0.03...0.97).contains(arc.progress) else { return nil }
        if arc.isDaytime {
            let amber = sunLow(arc.progress, span: 0.16)
            let fiery = sunLow(arc.progress, span: 0.06)
            return WaterRoad(
                core: ArgbColor.lerp(ArgbColor.lerp(.hex(0xFFFFFDF5), .hex(0xFFFFF8E1), amber), .hex(0xFFFFECE5), fiery),
                halo: ArgbColor.lerp(ArgbColor.lerp(.hex(0xFFFFE082), .hex(0xFFFFB74D), amber), .hex(0xFFFF7043), fiery),
                column: ArgbColor.lerp(ArgbColor.lerp(colors.orbGlow, .hex(0xFFF57C00), amber), .hex(0xFFD84315), fiery),
                strength: 0.38 + 0.14 * amber + 0.03 * fiery
            )
        } else {
            let lunar = min(1.0, max(0.0, moon.illumination))
            return WaterRoad(core: .hex(0xFFFFFFFF), halo: .hex(0xFFE2E8F0), column: .hex(0xFF94A3B8), strength: 0.22 + 0.30 * lunar)
        }
    }

    private func drawStillWater(ctx: inout GraphicsContext, geo: SceneGeometry, orbX: CGFloat) {
        let top = geo.poolTop
        let depth = geo.h - top
        guard depth >= 4 else { return }
        let horizonSky = colors.sky.last ?? .hex(0xFF14243F)
        let zenithSky = colors.sky.first ?? .hex(0xFF0A0F1D)

        ctx.drawLayer { pool in
            pool.clip(to: Path(CGRect(x: 0, y: top, width: geo.w, height: depth)))
            pool.fill(
                Path(CGRect(x: 0, y: top, width: geo.w, height: depth)),
                with: .linearGradient(
                    Gradient(colors: [
                        Color(argb: ArgbColor.lerp(horizonSky, .hex(0xFF020612), 0.35)),
                        Color(argb: ArgbColor.lerp(zenithSky, .hex(0xFF030714), 0.58)),
                        arc.isDaytime ? Color(argbHex: 0xFF020713) : Color(argbHex: 0xFF010307)
                    ]),
                    startPoint: CGPoint(x: 0, y: top),
                    endPoint: CGPoint(x: 0, y: geo.h)
                )
            )
            pool.fill(
                Path(CGRect(x: 0, y: top, width: geo.w, height: depth)),
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: Color.black.opacity(0.34), location: 0.0),
                        .init(color: .clear, location: 0.10),
                        .init(color: .clear, location: 0.90),
                        .init(color: Color.black.opacity(0.34), location: 1.0)
                    ]),
                    startPoint: CGPoint(x: 0, y: top),
                    endPoint: CGPoint(x: geo.w, y: top)
                )
            )
            let shade = min(depth * 0.35, 5.5 * geo.u)
            pool.fill(
                Path(CGRect(x: 0, y: top, width: geo.w, height: shade)),
                with: .linearGradient(
                    Gradient(colors: [Color.black.opacity(0.55), Color.black.opacity(0.22), .clear]),
                    startPoint: CGPoint(x: 0, y: top),
                    endPoint: CGPoint(x: 0, y: top + shade)
                )
            )

            if let road = waterRoad() {
                let lip: CGFloat = 14
                pool.fill(
                    Path(ellipseIn: CGRect(x: orbX - lip, y: top - lip, width: lip * 2, height: lip * 2)),
                    with: .radialGradient(
                        Gradient(colors: [Color(argb: road.core).opacity(road.strength * 0.62), Color(argb: road.halo).opacity(road.strength * 0.26), .clear]),
                        center: CGPoint(x: orbX, y: top), startRadius: 0, endRadius: lip
                    )
                )
            }
        }

        // Ground wash before the mosque
        ctx.drawLayer { layer in
            layer.clip(to: Path(CGRect(x: 0, y: geo.horizonY - 4, width: geo.w, height: geo.h - geo.horizonY + 4)))
            let r = geo.w * 0.5
            layer.fill(
                Path(ellipseIn: CGRect(x: orbX - r, y: geo.horizonY - r, width: r * 2, height: r * 2)),
                with: .radialGradient(
                    Gradient(colors: [Color(argb: colors.orbGlow).opacity(arc.isDaytime ? 0.13 : 0.06), .clear]),
                    center: CGPoint(x: orbX, y: geo.horizonY), startRadius: 0, endRadius: r
                )
            )
        }
    }

    private func drawMovingWater(ctx: inout GraphicsContext, geo: SceneGeometry, orbX: CGFloat, lightsAlpha: Double, t: Double) {
        let top = geo.poolTop
        let depth = geo.h - top
        guard depth >= 4 else { return }
        let u = geo.u
        let waveTime = motionEnabled ? t * Self.waterPace : 0.0
        let reflColor = ArgbColor.lerp(.hex(0xFF010308), colors.sky.last ?? .hex(0xFF010308), 0.08 * (1.0 - colors.starAlpha))

        ctx.drawLayer { pool in
            pool.clip(to: Path(CGRect(x: 0, y: top, width: geo.w, height: depth)))

            // Soft mirrored mosque + palms silhouette in the pool
            pool.drawLayer { refl in
                refl.addFilter(.blur(radius: 1.8 * u))
                refl.opacity = 0.58
                let sway = motionEnabled ? CGFloat(0.65 * sin(waveTime * 1.6)) * u : 0
                refl.translateBy(x: sway, y: top)
                refl.scaleBy(x: 1.0, y: -0.88)
                refl.translateBy(x: 0, y: -top)
                refl.fill(geo.mosquePath, with: .color(Color(argb: reflColor)))
                refl.fill(geo.palmsPath, with: .color(Color(argb: reflColor)))
            }

            // Lantern streaks on the water
            if lightsAlpha > 0.02 {
                for (index, lx) in geo.reflectedLightXs.enumerated() {
                    let on = lampOn(alpha: lightsAlpha, rank: index < Self.lampRanks.count ? Self.lampRanks[index] : 0.5)
                    if on < 0.01 { continue }
                    let isGate = index == 0
                    let length = (isGate ? 30.0 : 16.0) * u
                    let half = (isGate ? 4.4 : 1.9) * u
                    let sway = motionEnabled ? 0.7 * u * CGFloat(sin(waveTime * 1.7 + Double(index) * 1.25)) : 0
                    let shimmer = motionEnabled ? 0.80 + 0.20 * sin(waveTime * 2.3 + Double(index) * 2.1) : 0.9
                    pool.drawLayer { sl in
                        sl.translateBy(x: lx + sway, y: top + length * 0.40)
                        sl.scaleBy(x: half / 100.0, y: length * 0.5 / 100.0)
                        sl.fill(
                            Path(ellipseIn: CGRect(x: -100, y: -100, width: 200, height: 200)),
                            with: .radialGradient(
                                Gradient(stops: [
                                    .init(color: Color(argbHex: 0xFFFFE0A3).opacity(0.85 * 0.62 * on * shimmer), location: 0.0),
                                    .init(color: Color(argbHex: 0xFFFFC46B).opacity(0.42 * 0.62 * on * shimmer), location: 0.35),
                                    .init(color: .clear, location: 1.0)
                                ]),
                                center: .zero, startRadius: 0, endRadius: 100
                            )
                        )
                    }
                }
            }

            // Brightest stars reflected in night water
            if colors.starAlpha > 0.5 {
                let starDim = motionEnabled ? 0.85 : 0.70
                for s in 0..<min(10, Self.starSpecs.count) {
                    let sp = Self.starSpecs[s]
                    let reflY = top + max(0, geo.horizonY - sp.y * geo.h) * 0.28
                    if reflY < top + 3 || reflY > geo.h - 4 { continue }
                    let reflX = sp.x * geo.w + (motionEnabled ? 0.9 * u * CGFloat(sin(waveTime * 1.8 + sp.phase)) : 0)
                    let tw = motionEnabled ? 0.35 + 0.65 * max(0, sin(Self.twoPi * (waveTime / 7.0 + sp.phase))) : 0.65
                    let a = 0.25 * tw * starDim
                    pool.fill(Path(ellipseIn: CGRect(x: reflX - 1.6, y: reflY - 1.6, width: 3.2, height: 3.2)),
                              with: .color(Self.starTints[s % Self.starTints.count].opacity(a * 0.40)))
                    pool.fill(Path(ellipseIn: CGRect(x: reflX - 0.7, y: reflY - 0.7, width: 1.4, height: 1.4)),
                              with: .color(Color.white.opacity(a * 0.80)))
                }
            }

            // Glowing road of sun or moon light + twinkling flecks
            if let road = waterRoad() {
                let breath = motionEnabled ? 0.88 + 0.12 * sin(waveTime * 0.7) : 0.94
                func roadGlow(cy: CGFloat, halfW: CGFloat, halfH: CGFloat, color: ArgbColor, alpha: Double) {
                    let clamped = min(1.0, max(0.0, alpha))
                    pool.drawLayer { rl in
                        rl.translateBy(x: orbX, y: cy)
                        rl.scaleBy(x: halfW / 100.0, y: halfH / 100.0)
                        rl.fill(
                            Path(ellipseIn: CGRect(x: -100, y: -100, width: 200, height: 200)),
                            with: .radialGradient(
                                Gradient(stops: [
                                    .init(color: Color(argb: color).opacity(0.70 * clamped), location: 0.0),
                                    .init(color: Color(argb: color).opacity(0.30 * clamped), location: 0.40),
                                    .init(color: .clear, location: 1.0)
                                ]),
                                center: .zero, startRadius: 0, endRadius: 100
                            )
                        )
                    }
                }
                roadGlow(cy: top, halfW: 34, halfH: 4.5 * u, color: road.halo, alpha: road.strength * breath)
                roadGlow(cy: top, halfW: (Self.roadHead + 5) * u, halfH: depth * 0.85, color: road.halo, alpha: road.strength * 1.4 * breath)
                roadGlow(cy: top + depth * 0.62, halfW: (Self.roadHead + Self.roadSpread * 0.75) * u, halfH: depth * 0.62, color: road.column, alpha: road.strength * breath)

                for i in 0..<42 {
                    let d = 0.03 + 0.94 * pow(Self.seeded(i * 29 + 3), 1.4)
                    let rawLat = (Self.seeded(i * 29 + 5) - 0.5) * 2.0
                    let lateral = copysign(pow(abs(rawLat), 1.4), rawLat)
                    let phase = Self.seeded(i * 29 + 9) * Self.twoPi
                    let speed = 1.4 + 2.0 * Self.seeded(i * 29 + 17)
                    let reach = 0.6 + 2.4 * d
                    let gy = top + 2.5 * u + CGFloat(d) * (depth - 5 * u)
                    let cone = Self.roadHead * u + (Self.roadSpread - 4) * u * CGFloat(d)
                    let gx = orbX + CGFloat(lateral) * cone + (motionEnabled ? 0.8 * u * CGFloat(sin(waveTime * 0.9 + phase)) : 0)
                    let wave = motionEnabled ? 0.5 + 0.5 * sin(waveTime * speed + phase) : 0.4
                    let swell = 0.55 + 0.45 * sin(Self.twoPi * (d * 1.6 - waveTime * 0.22))
                    let lit = wave * wave * wave * wave
                    let a = min(1.0, max(0.0, road.strength * 1.45 * lit * swell * (1.0 - 0.55 * abs(lateral))))
                    if a < 0.03 { continue }
                    let len = CGFloat(reach) * u * CGFloat(0.6 + 0.4 * lit)
                    let fleck = CGFloat(0.9 + 0.6 * d)
                    var seg = Path()
                    seg.move(to: CGPoint(x: gx - len, y: gy))
                    seg.addLine(to: CGPoint(x: gx + len, y: gy))
                    if lit > 0.45 {
                        pool.stroke(seg, with: .color(Color(argb: road.halo).opacity(a * 0.22)), style: StrokeStyle(lineWidth: fleck * 2.8, lineCap: .round))
                    }
                    pool.stroke(seg, with: .color(Color(argb: ArgbColor.lerp(road.halo, road.core, lit)).opacity(a)), style: StrokeStyle(lineWidth: fleck, lineCap: .round))
                }
            }
        }

        // Pool stone lip catching light
        let rimPeak = arc.isDaytime ? 0.34 : 0.18
        let rimBase = arc.isDaytime ? 0.08 : 0.05
        let rimCenter = min(0.95, max(0.05, Double(orbX / geo.w)))
        var lipLine = Path()
        lipLine.move(to: CGPoint(x: 0, y: top))
        lipLine.addLine(to: CGPoint(x: geo.w, y: top))
        ctx.stroke(
            lipLine,
            with: .linearGradient(
                Gradient(stops: [
                    .init(color: Color(argb: colors.orbGlow).opacity(rimBase), location: 0.0),
                    .init(color: Color(argb: colors.orbGlow).opacity(rimPeak * 0.6), location: max(0.001, rimCenter - 0.18)),
                    .init(color: Color(argb: colors.orbGlow).opacity(rimPeak), location: rimCenter),
                    .init(color: Color(argb: colors.orbGlow).opacity(rimPeak * 0.6), location: min(0.999, rimCenter + 0.18)),
                    .init(color: Color(argb: colors.orbGlow).opacity(rimBase), location: 1.0)
                ]),
                startPoint: CGPoint(x: 0, y: top),
                endPoint: CGPoint(x: geo.w, y: top)
            ),
            lineWidth: 1.2
        )
        let glintColor = arc.isDaytime ? Color(argbHex: 0xFFFFF8E1) : .white
        ctx.fill(
            Path(ellipseIn: CGRect(x: orbX - 8, y: top - 8, width: 16, height: 16)),
            with: .radialGradient(Gradient(colors: [glintColor.opacity(rimPeak * 0.9), .clear]), center: CGPoint(x: orbX, y: top), startRadius: 0, endRadius: 8)
        )
    }

    // MARK: - Mist, Crescent Glints, Birds & Rim Light

    private func drawMist(ctx: inout GraphicsContext, geo: SceneGeometry, t: Double, strength: Double) {
        let horizon = colors.sky.last ?? .hex(0xFFFFFFFF)
        let mistColor = ArgbColor.lerp(horizon, .hex(0xFFFFFFFF), 0.62)
        for (startX, reachF, pace, dy, squash, bankAlpha) in Self.mistBanks {
            let frac = (Double(startX) + t * pace).truncatingRemainder(dividingBy: 1.8)
            let x = CGFloat(frac - 0.4) * geo.w
            let r = reachF * geo.w
            let cy = geo.horizonY + dy * geo.u
            let eff = min(1.0, bankAlpha * strength)
            ctx.drawLayer { layer in
                layer.translateBy(x: x, y: cy)
                layer.scaleBy(x: 1.0, y: squash)
                layer.fill(
                    Path(ellipseIn: CGRect(x: -r, y: -r, width: r * 2, height: r * 2)),
                    with: .radialGradient(
                        Gradient(stops: [
                            .init(color: Color(argb: mistColor).opacity(0.55 * eff), location: 0.0),
                            .init(color: Color(argb: mistColor).opacity(0.26 * eff), location: 0.45),
                            .init(color: .clear, location: 1.0)
                        ]),
                        center: .zero, startRadius: 0, endRadius: r
                    )
                )
            }
        }
    }

    private func drawCrescentGlint(ctx: inout GraphicsContext, geo: SceneGeometry, t: Double, strength: Double) {
        let cycle = Int(floor(t / Self.glintCycle))
        let p = (t - Double(cycle) * Self.glintCycle - Self.glintDelay) / Self.glintSeconds
        guard (0.0...1.0).contains(p) else { return }
        let at = geo.crescentGlints[cycle % geo.crescentGlints.count]
        let e = sin(.pi * p)
        let k = e * e * strength
        let halo = 7.0 * geo.u
        ctx.fill(
            Path(ellipseIn: CGRect(x: at.x - halo, y: at.y - halo, width: halo * 2, height: halo * 2)),
            with: .radialGradient(Gradient(colors: [Color(argbHex: 0xFFFFF1C9).opacity(0.55 * k), .clear]), center: at, startRadius: 0, endRadius: halo)
        )
        let long = 7.5 * geo.u * CGFloat(e)
        let tall = 5.0 * geo.u * CGFloat(e)
        var cross = Path()
        cross.move(to: CGPoint(x: at.x - long, y: at.y))
        cross.addLine(to: CGPoint(x: at.x + long, y: at.y))
        cross.move(to: CGPoint(x: at.x, y: at.y - tall))
        cross.addLine(to: CGPoint(x: at.x, y: at.y + tall))
        ctx.stroke(cross, with: .color(Color.white.opacity(0.9 * k)), style: StrokeStyle(lineWidth: 0.7, lineCap: .round))
        let d = 2.2 * geo.u * CGFloat(e)
        var diag = Path()
        diag.move(to: CGPoint(x: at.x - d, y: at.y - d))
        diag.addLine(to: CGPoint(x: at.x + d, y: at.y + d))
        diag.move(to: CGPoint(x: at.x - d, y: at.y + d))
        diag.addLine(to: CGPoint(x: at.x + d, y: at.y - d))
        ctx.stroke(diag, with: .color(Color.white.opacity(0.45 * k)), style: StrokeStyle(lineWidth: 0.7, lineCap: .round))
    }

    private func flightProgress(t: Double, weight: Double) -> Double {
        if weight < 0.05 || t < Self.firstFlight { return -1 }
        let cycle = Int(floor((t - Self.firstFlight) / Self.flightCycle))
        if cycle > 0 && Self.seeded(cycle * 31 + 7) > weight { return -1 }
        let p = (t - Self.firstFlight - Double(cycle) * Self.flightCycle) / Self.flightSeconds
        return (0.0...1.0).contains(p) ? p : -1
    }

    private func drawBirds(ctx: inout GraphicsContext, geo: SceneGeometry, t: Double, flight: Double, cycle: Int, weight: Double) {
        let u = geo.u
        let s = cycle * 31
        let eastward = Self.seeded(s + 1) > 0.5
        let altitude = geo.h * CGFloat(0.19 + 0.15 * Self.seeded(s + 2))
        let climb = geo.h * 0.08 * CGFloat(Self.seeded(s + 3) - 0.5)
        let count = min(6, 3 + Int(Self.seeded(s + 4) * 2.0 + weight * 2.0))
        let span = geo.w * 1.36
        let leadX = eastward ? (-0.18 * geo.w + span * CGFloat(flight)) : (1.18 * geo.w - span * CGFloat(flight))
        let leadY = altitude + climb * CGFloat(flight) - geo.h * 0.025 * CGFloat(sin(.pi * flight))
        let behind: CGFloat = eastward ? -1 : 1
        let ink = ArgbColor.lerp(colors.sky.first ?? .hex(0xFF0B1220), .hex(0xFF05070D), 0.70)
        let birdColor = Color(argb: ink).opacity(0.80)

        for i in 0..<count {
            let row = CGFloat((i + 1) / 2)
            let side: CGFloat = i % 2 == 0 ? 1 : -1
            let x = leadX + behind * row * 13 * u + CGFloat(Self.seeded(s + 10 + i) - 0.5) * 7 * u
            let bob = motionEnabled ? CGFloat(sin(t * 1.7 + Double(i) * 2.1)) * 1.6 * u : 0
            let y = leadY + side * row * 6.5 * u + CGFloat(Self.seeded(s + 20 + i) - 0.5) * 6 * u + bob
            if x < -12 * u || x > geo.w + 12 * u { continue }
            let sz = (1.05 - 0.07 * row) * CGFloat(0.88 + 0.24 * Self.seeded(s + 40 + i))
            let beat: Double
            if motionEnabled {
                let pace = 2.1 + 0.5 * Self.seeded(s + 50 + i)
                let ease = 0.5 + 0.5 * sin(t * 0.8 + Double(i) * 1.3)
                beat = 0.3 * ease + (1.0 - 0.45 * ease) * sin(Self.twoPi * (t * pace + Self.seeded(s + 30 + i)))
            } else {
                beat = -0.4 + 1.2 * Self.seeded(s + 30 + i)
            }
            let wing = 4.6 * u * sz
            let tipY = y - wing * CGFloat(0.10 + 0.62 * beat)
            let midY = y - wing * CGFloat(0.42 + 0.22 * beat)
            var bp = Path()
            bp.move(to: CGPoint(x: x - wing, y: tipY))
            bp.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: x - wing * 0.45, y: midY))
            bp.addQuadCurve(to: CGPoint(x: x + wing, y: tipY), control: CGPoint(x: x + wing * 0.45, y: midY))
            ctx.stroke(bp, with: .color(birdColor), style: StrokeStyle(lineWidth: 1.25, lineCap: .round, lineJoin: .round))
        }
    }

    private func drawVignetteAndRim(ctx: inout GraphicsContext, geo: SceneGeometry, orb: CGPoint, nightness: Double) {
        ctx.fill(
            Path(CGRect(origin: .zero, size: geo.size)),
            with: .radialGradient(
                Gradient(colors: [.clear, Color.black.opacity(0.18 + 0.10 * min(1.0, max(0.0, nightness)))]),
                center: CGPoint(x: geo.w / 2, y: geo.h * 0.48),
                startRadius: 0,
                endRadius: geo.h * 0.95
            )
        )

        let rimColor: ArgbColor
        let strength: Double
        if arc.isDaytime {
            rimColor = ArgbColor.lerp(colors.orbGlow, colors.orbCore, 0.35)
            strength = 0.80
        } else {
            rimColor = .hex(0xFFDDE6FF)
            strength = 0.42 * (0.35 + 0.65 * min(1.0, max(0.0, moon.illumination)))
        }

        func strokeRim(width: CGFloat, alpha: Double) {
            let inset = 1.0 + width / 2.0
            let rect = CGRect(x: inset, y: inset, width: max(0, geo.w - inset * 2), height: max(0, geo.h - inset * 2))
            ctx.stroke(
                Path(roundedRect: rect, cornerRadius: max(0, cornerRadius - inset)),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: Color(argb: rimColor).opacity(strength * alpha), location: 0.0),
                        .init(color: Color(argb: rimColor).opacity(strength * 0.32 * alpha), location: 0.45),
                        .init(color: .clear, location: 1.0)
                    ]),
                    center: orb, startRadius: 0, endRadius: geo.w * 0.62
                ),
                lineWidth: width
            )
        }
        strokeRim(width: 5.0, alpha: 0.22)
        strokeRim(width: 1.3, alpha: 1.0)
    }

    // MARK: - Helpers

    private func resolvedLightsAlpha() -> Double {
        if !arc.isDaytime || colors.starAlpha > 0.5 { return 1.0 }
        let dusk = min(1.0, max(0.0, (arc.progress - 0.72) / 0.12))
        let dawn = min(1.0, max(0.0, (0.30 - arc.progress) / 0.12))
        return max(dusk, dawn) * 0.75
    }

    private func sunLow(_ progress: Double, span: Double) -> Double {
        let fromHorizon = min(progress - SolarArc.sunriseOnArc, SolarArc.sunsetOnArc - progress)
        return min(1.0, max(0.0, 1.0 - max(0.0, fromHorizon) / span))
    }

    private func lampOn(alpha: Double, rank: Double) -> Double {
        min(1.0, max(0.0, alpha * 1.8 - rank * 0.8))
    }

    private static func seeded(_ i: Int) -> Double {
        let x = sin(Double(i) * 12.9898) * 43758.5453
        return x - floor(x)
    }

    // MARK: - Skyline & Arc Geometry

    private struct SceneGeometry {
        let size: CGSize
        let w: CGFloat, h: CGFloat, u: CGFloat
        let horizonY: CGFloat, baseY: CGFloat, poolTop: CGFloat
        let cx: CGFloat, leftMinaretX: CGFloat, rightMinaretX: CGFloat, leftDomeX: CGFloat, rightDomeX: CGFloat
        let p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint
        let arcPath: Path
        let farRidgePath: Path
        let midDunePath: Path
        let mosquePath: Path
        let palmsPath: Path
        let gatePath: Path
        let arcadeWindowXs: [CGFloat]
        let reflectedLightXs: [CGFloat]
        let lamps: [CGPoint]
        let crescentGlints: [CGPoint]

        init(size: CGSize) {
            self.size = size
            let w = size.width
            let h = size.height
            self.w = w
            self.h = h
            let u = min(1.12, max(0.70, h / CelestialArcCanvas.referenceCardHeight))
            self.u = u
            let horizonY = h * 0.855
            let baseY = horizonY + 6 * u
            let poolTop = baseY + 2.5 * u
            self.horizonY = horizonY
            self.baseY = baseY
            self.poolTop = poolTop

            let cx = w * 0.50
            let leftMinaretX = cx - 105 * u
            let rightMinaretX = cx + 105 * u
            let leftDomeX = cx - 64 * u
            let rightDomeX = cx + 64 * u
            self.cx = cx
            self.leftMinaretX = leftMinaretX
            self.rightMinaretX = rightMinaretX
            self.leftDomeX = leftDomeX
            self.rightDomeX = rightDomeX

            self.arcadeWindowXs = [-97, -90.5, -84, -45.5, -40, 37.5, 43.5, 80.5, 85.5].map { cx + CGFloat($0) * u }
            self.reflectedLightXs = [cx, leftMinaretX, rightMinaretX, cx - 5.8 * u, cx + 5.8 * u, leftDomeX, rightDomeX]
            self.lamps = [
                CGPoint(x: cx, y: baseY - 13 * u),
                CGPoint(x: leftMinaretX, y: baseY - 43.6 * u),
                CGPoint(x: rightMinaretX, y: baseY - 34.9 * u),
                CGPoint(x: cx - 5.8 * u, y: baseY - 34.2 * u),
                CGPoint(x: cx + 5.8 * u, y: baseY - 34.2 * u),
                CGPoint(x: leftDomeX, y: baseY - 25.8 * u),
                CGPoint(x: rightDomeX, y: baseY - 25.8 * u)
            ]
            self.crescentGlints = [
                CGPoint(x: cx - 1.4 * u, y: baseY - 74.4 * u),
                CGPoint(x: leftMinaretX - 0.8 * u, y: baseY - 74.5 * u),
                CGPoint(x: rightMinaretX - 0.8 * u, y: baseY - 59.5 * u)
            ]

            let p0 = CGPoint(x: w * 0.045, y: horizonY)
            let p1 = CGPoint(x: w * 0.060, y: -h * 0.145)
            let p2 = CGPoint(x: w * 0.940, y: -h * 0.145)
            let p3 = CGPoint(x: w * 0.955, y: horizonY)
            self.p0 = p0; self.p1 = p1; self.p2 = p2; self.p3 = p3
            var ap = Path()
            ap.move(to: p0)
            ap.addCurve(to: p3, control1: p1, control2: p2)
            self.arcPath = ap

            // Far ridge
            var fr = Path()
            fr.move(to: CGPoint(x: 0, y: h))
            fr.addLine(to: CGPoint(x: 0, y: horizonY - 13 * u))
            fr.addCurve(to: CGPoint(x: w * 0.40, y: horizonY - 18 * u), control1: CGPoint(x: w * 0.14, y: horizonY - 26 * u), control2: CGPoint(x: w * 0.26, y: horizonY - 9 * u))
            fr.addCurve(to: CGPoint(x: w * 0.86, y: horizonY - 16 * u), control1: CGPoint(x: w * 0.56, y: horizonY - 29 * u), control2: CGPoint(x: w * 0.72, y: horizonY - 8 * u))
            fr.addCurve(to: CGPoint(x: w, y: horizonY - 13 * u), control1: CGPoint(x: w * 0.93, y: horizonY - 20 * u), control2: CGPoint(x: w * 0.97, y: horizonY - 10 * u))
            fr.addLine(to: CGPoint(x: w, y: h))
            fr.closeSubpath()
            self.farRidgePath = fr

            // Mid dune
            var md = Path()
            md.move(to: CGPoint(x: 0, y: h))
            md.addLine(to: CGPoint(x: 0, y: horizonY + 1 * u))
            md.addCurve(to: CGPoint(x: w * 0.56, y: horizonY - 7 * u), control1: CGPoint(x: w * 0.20, y: horizonY - 11 * u), control2: CGPoint(x: w * 0.38, y: horizonY + 3 * u))
            md.addCurve(to: CGPoint(x: w, y: horizonY - 4 * u), control1: CGPoint(x: w * 0.76, y: horizonY - 18 * u), control2: CGPoint(x: w * 0.90, y: horizonY))
            md.addLine(to: CGPoint(x: w, y: h))
            md.closeSubpath()
            self.midDunePath = md

            // Continuous mosque silhouette
            var mp = Path()
            let leftWallEnd = cx - 117.7 * u
            let rightWallStart = cx + 106.9 * u
            let rightWallEnd = cx + 140.7 * u
            let merlon = 5.9 * u
            mp.move(to: CGPoint(x: 0, y: h))
            mp.addLine(to: CGPoint(x: 0, y: baseY - 9 * u))
            Self.addCrenellations(&mp, x0: 0, x1: leftWallEnd, base: baseY, high: 9 * u, low: 5 * u, step: merlon)
            Self.addMinaret(&mp, cx: leftMinaretX, base: baseY, height: 72 * u, shaftW: 5.2 * u)
            mp.addLine(to: CGPoint(x: cx - 102.2 * u, y: baseY - 9 * u))
            mp.addLine(to: CGPoint(x: cx - 102.2 * u, y: baseY - 19 * u))
            mp.addLine(to: CGPoint(x: cx - 77.5 * u, y: baseY - 19 * u))
            Self.addSmallDome(&mp, cx: leftDomeX, halfW: 13.7 * u, yTop: baseY - 19 * u, height: 18 * u)
            mp.addLine(to: CGPoint(x: cx - 35.5 * u, y: baseY - 19 * u))
            mp.addLine(to: CGPoint(x: cx - 31.0 * u, y: baseY - 19 * u))
            mp.addLine(to: CGPoint(x: cx - 31.0 * u, y: baseY - 24 * u))
            mp.addLine(to: CGPoint(x: cx - 26.4 * u, y: baseY - 24 * u))
            Self.addOnionDome(&mp, cx: cx, halfW: 26.4 * u, yTop: baseY - 24 * u, height: 37 * u)
            mp.addLine(to: CGPoint(x: cx + 31.1 * u, y: baseY - 24 * u))
            mp.addLine(to: CGPoint(x: cx + 31.1 * u, y: baseY - 19 * u))
            mp.addLine(to: CGPoint(x: cx + 50.3 * u, y: baseY - 19 * u))
            Self.addSmallDome(&mp, cx: rightDomeX, halfW: 13.7 * u, yTop: baseY - 19 * u, height: 18 * u)
            mp.addLine(to: CGPoint(x: cx + 88.6 * u, y: baseY - 19 * u))
            mp.addLine(to: CGPoint(x: cx + 88.6 * u, y: baseY - 9 * u))
            Self.addMinaret(&mp, cx: rightMinaretX, base: baseY, height: 57 * u, shaftW: 4.6 * u)
            Self.addCrenellations(&mp, x0: rightWallStart, x1: rightWallEnd, base: baseY, high: 9 * u, low: 5 * u, step: merlon)
            mp.addLine(to: CGPoint(x: w, y: baseY - 6 * u))
            mp.addLine(to: CGPoint(x: w, y: h))
            mp.closeSubpath()
            self.mosquePath = mp

            // Palm grove
            var pp = Path()
            Self.addPalm(&pp, x: cx + 145 * u, footY: baseY + 1 * u, height: 34 * u, lean: 1, u: u)
            Self.addPalm(&pp, x: cx + 178 * u, footY: baseY + 1 * u, height: 44 * u, lean: -1, u: u)
            Self.addPalm(&pp, x: cx + 208 * u, footY: baseY + 1 * u, height: 28 * u, lean: 1, u: u)
            Self.addPalm(&pp, x: cx - 172 * u, footY: baseY + 1 * u, height: 30 * u, lean: 1, u: u)
            Self.addPalm(&pp, x: cx - 198 * u, footY: baseY + 1 * u, height: 38 * u, lean: -1, u: u)
            self.palmsPath = pp

            // Great arched gate
            var gp = Path()
            let gateHalf = 6.4 * u
            gp.move(to: CGPoint(x: cx - gateHalf, y: baseY - 9 * u))
            gp.addLine(to: CGPoint(x: cx - gateHalf, y: baseY - 13 * u))
            gp.addQuadCurve(to: CGPoint(x: cx + gateHalf, y: baseY - 13 * u), control: CGPoint(x: cx, y: baseY - 21 * u))
            gp.addLine(to: CGPoint(x: cx + gateHalf, y: baseY - 9 * u))
            gp.closeSubpath()
            self.gatePath = gp
        }

        func bezierPoint(_ t: Double) -> CGPoint {
            let tt = CGFloat(min(1.0, max(0.0, t)))
            let mu = 1.0 - tt
            let x = mu * mu * mu * p0.x + 3 * mu * mu * tt * p1.x + 3 * mu * tt * tt * p2.x + tt * tt * tt * p3.x
            let y = mu * mu * mu * p0.y + 3 * mu * mu * tt * p1.y + 3 * mu * tt * tt * p2.y + tt * tt * tt * p3.y
            return CGPoint(x: x, y: y)
        }

        private static func addCrenellations(_ p: inout Path, x0: CGFloat, x1: CGFloat, base: CGFloat, high: CGFloat, low: CGFloat, step: CGFloat) {
            var x = x0
            var up = true
            let merlon = step * 0.55
            p.addLine(to: CGPoint(x: x0, y: base - high))
            while x < x1 - step {
                p.addLine(to: CGPoint(x: x + merlon, y: base - (up ? high : low)))
                p.addLine(to: CGPoint(x: x + merlon, y: base - (up ? low : high)))
                x += merlon
                up.toggle()
            }
            p.addLine(to: CGPoint(x: x1, y: base - high))
        }

        private static func addMinaret(_ p: inout Path, cx: CGFloat, base: CGFloat, height: CGFloat, shaftW: CGFloat) {
            let foot = 9 * (shaftW / 5.2)
            p.addLine(to: CGPoint(x: cx - shaftW * 0.46, y: base - foot))
            p.addLine(to: CGPoint(x: cx - shaftW * 0.38, y: base - height * 0.500))
            p.addLine(to: CGPoint(x: cx - shaftW * 0.86, y: base - height * 0.525))
            p.addLine(to: CGPoint(x: cx - shaftW * 0.92, y: base - height * 0.585))
            p.addLine(to: CGPoint(x: cx - shaftW * 0.34, y: base - height * 0.615))
            p.addLine(to: CGPoint(x: cx - shaftW * 0.28, y: base - height * 0.840))
            p.addLine(to: CGPoint(x: cx - shaftW * 0.46, y: base - height * 0.855))
            p.addLine(to: CGPoint(x: cx - shaftW * 0.05, y: base - height * 0.975))
            p.addLine(to: CGPoint(x: cx - shaftW * 0.05, y: base - height))
            p.addLine(to: CGPoint(x: cx + shaftW * 0.05, y: base - height))
            p.addLine(to: CGPoint(x: cx + shaftW * 0.05, y: base - height * 0.975))
            p.addLine(to: CGPoint(x: cx + shaftW * 0.46, y: base - height * 0.855))
            p.addLine(to: CGPoint(x: cx + shaftW * 0.28, y: base - height * 0.840))
            p.addLine(to: CGPoint(x: cx + shaftW * 0.34, y: base - height * 0.615))
            p.addLine(to: CGPoint(x: cx + shaftW * 0.92, y: base - height * 0.585))
            p.addLine(to: CGPoint(x: cx + shaftW * 0.86, y: base - height * 0.525))
            p.addLine(to: CGPoint(x: cx + shaftW * 0.38, y: base - height * 0.500))
            p.addLine(to: CGPoint(x: cx + shaftW * 0.46, y: base - foot))
        }

        private static func addOnionDome(_ p: inout Path, cx: CGFloat, halfW: CGFloat, yTop: CGFloat, height: CGFloat) {
            p.addCurve(to: CGPoint(x: cx - halfW * 0.34, y: yTop - height * 0.90),
                       control1: CGPoint(x: cx - halfW * 1.24, y: yTop - height * 0.30),
                       control2: CGPoint(x: cx - halfW * 1.00, y: yTop - height * 0.63))
            p.addCurve(to: CGPoint(x: cx - halfW * 0.06, y: yTop - height),
                       control1: CGPoint(x: cx - halfW * 0.20, y: yTop - height * 0.955),
                       control2: CGPoint(x: cx - halfW * 0.11, y: yTop - height * 0.985))
            p.addLine(to: CGPoint(x: cx - halfW * 0.042, y: yTop - height * 1.26))
            p.addLine(to: CGPoint(x: cx + halfW * 0.042, y: yTop - height * 1.26))
            p.addLine(to: CGPoint(x: cx + halfW * 0.06, y: yTop - height))
            p.addCurve(to: CGPoint(x: cx + halfW * 0.34, y: yTop - height * 0.90),
                       control1: CGPoint(x: cx + halfW * 0.11, y: yTop - height * 0.985),
                       control2: CGPoint(x: cx + halfW * 0.20, y: yTop - height * 0.955))
            p.addCurve(to: CGPoint(x: cx + halfW, y: yTop),
                       control1: CGPoint(x: cx + halfW * 1.00, y: yTop - height * 0.63),
                       control2: CGPoint(x: cx + halfW * 1.24, y: yTop - height * 0.30))
        }

        private static func addSmallDome(_ p: inout Path, cx: CGFloat, halfW: CGFloat, yTop: CGFloat, height: CGFloat) {
            p.addCurve(to: CGPoint(x: cx - halfW * 0.05, y: yTop - height * 1.04),
                       control1: CGPoint(x: cx - halfW * 1.14, y: yTop - height * 0.52),
                       control2: CGPoint(x: cx - halfW * 0.60, y: yTop - height * 1.00))
            p.addLine(to: CGPoint(x: cx - halfW * 0.04, y: yTop - height * 1.22))
            p.addLine(to: CGPoint(x: cx + halfW * 0.04, y: yTop - height * 1.22))
            p.addLine(to: CGPoint(x: cx + halfW * 0.05, y: yTop - height * 1.04))
            p.addCurve(to: CGPoint(x: cx + halfW, y: yTop),
                       control1: CGPoint(x: cx + halfW * 0.60, y: yTop - height * 1.00),
                       control2: CGPoint(x: cx + halfW * 1.14, y: yTop - height * 0.52))
        }

        private static func addPalm(_ p: inout Path, x: CGFloat, footY: CGFloat, height: CGFloat, lean: CGFloat, u: CGFloat) {
            let topX = x + lean * height * 0.15
            let topY = footY - height
            p.move(to: CGPoint(x: x - 1.7 * u, y: footY))
            p.addQuadCurve(to: CGPoint(x: topX - 1.0 * u, y: topY), control: CGPoint(x: x + lean * height * 0.045, y: footY - height * 0.55))
            p.addLine(to: CGPoint(x: topX + 1.0 * u, y: topY))
            p.addQuadCurve(to: CGPoint(x: x + 1.7 * u, y: footY), control: CGPoint(x: x + lean * height * 0.045 + 2.6 * u, y: footY - height * 0.55))
            p.closeSubpath()

            let l = height * 0.46
            for (dx, dy) in CelestialArcCanvas.frondDirs {
                let ex = topX + dx * l
                let ey = topY + dy * l * 0.78
                let mx = (topX + ex) / 2
                let my = (topY + ey) / 2 - l * 0.26
                p.move(to: CGPoint(x: topX, y: topY))
                p.addQuadCurve(to: CGPoint(x: ex, y: ey), control: CGPoint(x: mx, y: my))
                p.addQuadCurve(to: CGPoint(x: topX, y: topY + 2.4 * u), control: CGPoint(x: mx, y: my + 3.4 * u))
                p.closeSubpath()
            }
        }
    }
}
