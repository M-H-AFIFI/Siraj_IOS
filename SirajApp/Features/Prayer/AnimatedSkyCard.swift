import SwiftUI
import SirajCore

public struct AnimatedSkyCard: View {
    @Environment(\.sirajTheme) private var theme
    @Environment(\.scenePhase) private var scenePhase

    let appState: AppState
    let onTapHijri: () -> Void
    let onTapCard: () -> Void

    public init(appState: AppState, onTapHijri: @escaping () -> Void, onTapCard: @escaping () -> Void) {
        self.appState = appState
        self.onTapHijri = onTapHijri
        self.onTapCard = onTapCard
    }

    public var body: some View {
        let isPinned = appState.pinnedSkyTime != nil
        let paused = isPinned || !theme.motionEnabled || scenePhase != .active

        TimelineView(.animation(minimumInterval: isPinned ? 60 : (1.0 / 6.0), paused: paused)) { timeline in
            let now = appState.pinnedSkyTime ?? timeline.date
            let day = PrayerCalculator.today(place: appState.activePlace, settings: appState.settings.calculationSettings, now: now)
            let state = PrayerState.at(day: day, now: now)
            let skyMoment = SkyTimeline.at(now, prayers: day.entries)
            let arc = SolarArc.at(now, prayers: day.entries, next: day.next)
            let moon = MoonPhase.at(now)
            let animT = isPinned ? 4.2 : timeline.date.timeIntervalSinceReferenceDate

            cardBody(now: now, day: day, state: state, sky: skyMoment, arc: arc, moon: moon, t: animT)
        }
    }

    private func cardBody(
        now: Date,
        day: PrayerDay,
        state: PrayerState?,
        sky: SkyMoment,
        arc: SolarArc,
        moon: MoonPhaseInfo,
        t: Double
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)
        let displayed = state?.prayer ?? day.next ?? day[.fajr]
        let countdownText = formattedCountdown(state: state)
        let hijriText = HijriFormatter.format(appState.hijriDate, lang: theme.language, numeralSystem: theme.settings.numeralSystem)
        let gregorianText = HijriFormatter.formatGregorian(appState.activePlace.today(at: now), lang: theme.language, numeralSystem: theme.settings.numeralSystem)
        let prayerClock = TimeFormatter.formatTime(
            displayed.time,
            timeZone: appState.activePlace.timeZone,
            hourFormat: theme.settings.hourFormat,
            numeralSystem: theme.settings.numeralSystem,
            lang: theme.language
        )

        return Button(action: onTapCard) {
            ZStack {
                Canvas { ctx, size in
                    drawSkyLayers(ctx: &ctx, size: size, sky: sky, arc: arc, moon: moon, t: t)
                }

                VStack(spacing: 12) {
                    // Top bar: phase badge + Hijri date pill
                    HStack(spacing: 8) {
                        HStack(spacing: 5) {
                            Image(systemName: arc.isDaytime ? "sun.max.fill" : "moon.stars.fill")
                                .font(.system(size: 11, weight: .semibold))
                            Text(theme.t(arc.phaseKey))
                                .font(.system(size: 11 * theme.textScale, weight: .semibold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(Color.white.opacity(0.92))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.black.opacity(0.24)))

                        Spacer(minLength: 6)

                        Button(action: onTapHijri) {
                            HStack(spacing: 5) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 11, weight: .semibold))
                                Text(hijriText)
                                    .font(.system(size: 11 * theme.textScale, weight: .bold))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(Color(argb: sky.colors.orbCore))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.black.opacity(0.28)))
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer(minLength: 36)

                    // Center hero readout
                    VStack(spacing: 4) {
                        Text(statusLabel(state: state, prayer: displayed))
                            .font(.system(size: 12 * theme.textScale, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.84))
                            .textCase(.uppercase)

                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(prayerDisplayName(displayed, place: appState.activePlace))
                                .font(.system(size: 26 * theme.textScale, weight: .heavy))
                                .foregroundStyle(.white)
                            Text(prayerClock)
                                .font(.system(size: 16 * theme.textScale, weight: .semibold))
                                .foregroundStyle(Color(argb: sky.colors.orbGlow))
                        }

                        RollingCountdownText(text: countdownText, fontSize: 38 * theme.textScale, color: .white)
                            .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 2)

                        if case .waitingForIqama(_, _, _, let progress) = state {
                            GeometryReader { g in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.white.opacity(0.22))
                                    Capsule()
                                        .fill(Color(argb: sky.colors.orbGlow))
                                        .frame(width: g.size.width * CGFloat(progress))
                                }
                            }
                            .frame(height: 5)
                            .padding(.horizontal, 28)
                            .padding(.top, 4)
                        }
                    }

                    Spacer(minLength: 6)

                    // Footer strip with Gregorian date
                    HStack {
                        Text(gregorianText)
                            .font(.system(size: 11.5 * theme.textScale, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.78))
                        Spacer()
                        Image(systemName: theme.isRTL ? "chevron.left" : "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.65))
                    }
                    .padding(.top, 4)
                }
                .padding(18)
            }
            .frame(minHeight: 272)
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(
                    LinearGradient(
                        colors: [Color(argb: sky.colors.cardBorderTop), Color(argb: sky.colors.cardBorderBottom)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.2
                )
            }
            .shadow(color: Color.black.opacity(theme.isDark ? 0.42 : 0.18), radius: 18, x: 0, y: 9)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("prayer_sky_card")
    }

    private func prayerDisplayName(_ entry: PrayerTimeEntry, place: Place) -> String {
        if entry.type == .dhuhr && place.today(at: entry.time).weekdaySundayZero == 5 {
            let jumuah = theme.t("prayer_jumuah")
            if jumuah != "prayer_jumuah" { return jumuah }
        }
        return theme.t(entry.type.stringKey)
    }

    private func statusLabel(state: PrayerState?, prayer: PrayerTimeEntry) -> String {
        switch state {
        case .azanCalled:
            return theme.t("adhan_now")
        case .waitingForIqama:
            return theme.t("iqama_in")
        case .inPrayer:
            return theme.t("in_prayer")
        default:
            return theme.t("next_prayer")
        }
    }

    private func formattedCountdown(state: PrayerState?) -> String {
        switch state {
        case .upcomingAzan(_, let rem):
            return TimeFormatter.formatCountdown(seconds: rem, withHours: true, numeralSystem: theme.settings.numeralSystem, lang: theme.language)
        case .azanCalled(_, let since, _):
            return TimeFormatter.formatCountdown(seconds: since, withHours: false, numeralSystem: theme.settings.numeralSystem, lang: theme.language)
        case .waitingForIqama(_, _, let until, _):
            return TimeFormatter.formatCountdown(seconds: until, withHours: false, numeralSystem: theme.settings.numeralSystem, lang: theme.language)
        case .inPrayer(_, let since):
            return TimeFormatter.formatCountdown(seconds: since, withHours: false, numeralSystem: theme.settings.numeralSystem, lang: theme.language)
        case nil:
            return TimeFormatter.formatCountdown(seconds: 0, withHours: true, numeralSystem: theme.settings.numeralSystem, lang: theme.language)
        }
    }

    private func drawSkyLayers(
        ctx: inout GraphicsContext,
        size: CGSize,
        sky: SkyMoment,
        arc: SolarArc,
        moon: MoonPhaseInfo,
        t: Double
    ) {
        let w = size.width
        let h = size.height
        let colors = sky.colors

        // 1. Six-stop sky gradient
        let skyGrad = Gradient(colors: colors.sky.map { Color(argb: $0) })
        ctx.fill(Path(CGRect(origin: .zero, size: size)),
                 with: .linearGradient(skyGrad, startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))

        // 2. Horizon twilight blooms (sunrise/sunset/shafaq/trueDawn)
        let horizonBloom = max(sky.twilight.sunriseGlow, max(sky.twilight.sunsetGlow, max(sky.twilight.shafaq, sky.twilight.trueDawn * 0.7)))
        if horizonBloom > 0.02 {
            let bloomCenter = CGPoint(x: w * 0.5, y: h * 0.86)
            ctx.fill(
                Path(ellipseIn: CGRect(x: -w * 0.15, y: h * 0.45, width: w * 1.3, height: h * 0.8)),
                with: .radialGradient(
                    Gradient(colors: [Color(argb: colors.orbGlow).opacity(0.36 * horizonBloom), .clear]),
                    center: bloomCenter, startRadius: 8, endRadius: w * 0.65
                )
            )
        }

        // 3. Stars + occasional shooting star at night
        if colors.starAlpha > 0.02 {
            for i in 0..<46 {
                let sx = frac(sin(Double(i) * 19.19) * 43758.5453) * w
                let sy = frac(sin(Double(i) * 73.13) * 19341.123) * h * 0.62
                let twinkle = 0.45 + 0.55 * (0.5 + 0.5 * sin(t * (1.3 + Double(i % 4) * 0.4) + Double(i)))
                let r = 0.75 + Double(i % 3) * 0.55
                ctx.fill(
                    Path(ellipseIn: CGRect(x: sx - r, y: sy - r, width: r * 2, height: r * 2)),
                    with: .color(Color.white.opacity(colors.starAlpha * twinkle * 0.9))
                )
            }
            // Occasional shooting star cycle
            let cycle = t.truncatingRemainder(dividingBy: 9.0)
            if cycle < 0.85 {
                let p = cycle / 0.85
                let start = CGPoint(x: w * (0.18 + 0.42 * p), y: h * (0.12 + 0.18 * p))
                let tail = CGPoint(x: start.x - 32, y: start.y - 14)
                var meteor = Path()
                meteor.move(to: tail)
                meteor.addLine(to: start)
                ctx.stroke(meteor, with: .color(Color.white.opacity(colors.starAlpha * (1.0 - p) * 0.85)),
                           style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            }
        }

        // 4. Soft clouds
        if colors.cloudAlpha > 0.04 {
            let drift = (t * 4.0).truncatingRemainder(dividingBy: w + 120)
            for idx in 0..<3 {
                let cx = ((Double(idx) * w * 0.42 + drift).truncatingRemainder(dividingBy: w + 120)) - 60
                let cy = h * (0.24 + Double(idx) * 0.11)
                let cw = 72.0 + Double(idx) * 18.0
                let ch = 20.0 + Double(idx) * 4.0
                let cloudRect = CGRect(x: cx - cw / 2, y: cy - ch / 2, width: cw, height: ch)
                ctx.fill(
                    Path(roundedRect: cloudRect, cornerRadius: ch / 2),
                    with: .linearGradient(
                        Gradient(colors: [Color(argb: colors.cloudLight).opacity(colors.cloudAlpha * 0.38),
                                          Color(argb: colors.cloudDark).opacity(colors.cloudAlpha * 0.25)]),
                        startPoint: CGPoint(x: cx, y: cy - ch / 2),
                        endPoint: CGPoint(x: cx, y: cy + ch / 2)
                    )
                )
            }
        }

        // 5. Celestial solar/lunar arc
        let arcLeft = CGPoint(x: w * 0.08, y: h * 0.72)
        let arcRight = CGPoint(x: w * 0.92, y: h * 0.72)
        let arcCtrl = CGPoint(x: w * 0.50, y: h * 0.14)

        func quadPoint(_ u: Double) -> CGPoint {
            let mu = 1.0 - u
            let x = mu * mu * arcLeft.x + 2 * mu * u * arcCtrl.x + u * u * arcRight.x
            let y = mu * mu * arcLeft.y + 2 * mu * u * arcCtrl.y + u * u * arcRight.y
            return CGPoint(x: x, y: y)
        }

        var arcPath = Path()
        arcPath.move(to: arcLeft)
        arcPath.addQuadCurve(to: arcRight, control: arcCtrl)
        let arcGrad = Gradient(colors: colors.arc.map { Color(argb: $0) })
        ctx.stroke(
            arcPath,
            with: .linearGradient(arcGrad, startPoint: arcLeft, endPoint: arcRight),
            style: StrokeStyle(lineWidth: 2.0, lineCap: .round, dash: [4, 5])
        )

        // Milestone markers along arc
        for m in arc.milestones {
            let pt = quadPoint(m.progress)
            let r: CGFloat = m.isNext ? 4.8 : 2.8
            if m.isNext {
                let breathe = 1.0 + 0.22 * sin(t * 2.4)
                let gr = r * 2.4 * breathe
                ctx.fill(Path(ellipseIn: CGRect(x: pt.x - gr, y: pt.y - gr, width: gr * 2, height: gr * 2)),
                         with: .color(Color(argb: colors.orbGlow).opacity(0.32)))
            }
            ctx.fill(Path(ellipseIn: CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)),
                     with: .color(m.isNext ? Color(argb: colors.orbCore) : Color.white.opacity(m.isPast ? 0.35 : 0.72)))
        }

        // 6. Sun or Moon orb riding along the arc
        let orb = quadPoint(arc.progress)
        let glowR: CGFloat = 28 + CGFloat(3.5 * sin(t * 1.8))
        ctx.fill(
            Path(ellipseIn: CGRect(x: orb.x - glowR, y: orb.y - glowR, width: glowR * 2, height: glowR * 2)),
            with: .radialGradient(
                Gradient(colors: [Color(argb: colors.orbGlow).opacity(0.68), Color(argb: colors.orbGlow).opacity(0.16), .clear]),
                center: orb, startRadius: 4, endRadius: glowR
            )
        )

        if colors.rayAlpha > 0.05 && !colors.showCrescent {
            for ray in 0..<8 {
                let angle = Double(ray) * (.pi / 4.0) + t * 0.12
                let inner = CGPoint(x: orb.x + cos(angle) * 13, y: orb.y + sin(angle) * 13)
                let outer = CGPoint(x: orb.x + cos(angle) * 23, y: orb.y + sin(angle) * 23)
                var rp = Path()
                rp.move(to: inner)
                rp.addLine(to: outer)
                ctx.stroke(rp, with: .color(Color(argb: colors.orbGlow).opacity(colors.rayAlpha * 0.55)),
                           style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            }
        }

        let coreR: CGFloat = 10.5
        if colors.showCrescent {
            drawMoonDisc(ctx: &ctx, center: orb, radius: coreR, phase: moon, litColor: Color(argb: colors.orbCore))
        } else {
            ctx.fill(Path(ellipseIn: CGRect(x: orb.x - coreR, y: orb.y - coreR, width: coreR * 2, height: coreR * 2)),
                     with: .color(Color(argb: colors.orbCore)))
        }

        // 7. Mosque skyline silhouette & night lamps along bottom
        drawMosqueSkyline(ctx: &ctx, size: size, footerColor: Color(argb: colors.footerBg), isNight: colors.starAlpha > 0.25)
    }

    private func drawMoonDisc(ctx: inout GraphicsContext, center: CGPoint, radius: CGFloat, phase: MoonPhaseInfo, litColor: Color) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        ctx.fill(Path(ellipseIn: rect), with: .color(litColor.opacity(0.18)))
        // Crescent/gibbous lit region approximation via clipped shadow offset
        let offsetFactor = (1.0 - phase.illumination) * 1.45 * Double(radius)
        let dx = phase.waxing ? -offsetFactor : offsetFactor
        ctx.drawLayer { layer in
            layer.clip(to: Path(ellipseIn: rect))
            layer.fill(Path(ellipseIn: rect), with: .color(litColor))
            if phase.illumination < 0.94 {
                let shadowRect = CGRect(x: center.x - radius + dx, y: center.y - radius, width: radius * 2, height: radius * 2)
                layer.blendMode = .destinationOut
                layer.fill(Path(ellipseIn: shadowRect), with: .color(.black))
            }
        }
    }

    private func drawMosqueSkyline(ctx: inout GraphicsContext, size: CGSize, footerColor: Color, isNight: Bool) {
        let w = size.width, h = size.height
        let baseY = h * 0.85
        var p = Path()
        p.move(to: CGPoint(x: 0, y: h))
        p.addLine(to: CGPoint(x: 0, y: baseY + 6))
        p.addLine(to: CGPoint(x: w * 0.14, y: baseY + 6))
        // Left minaret
        p.addLine(to: CGPoint(x: w * 0.14, y: baseY - 22))
        p.addLine(to: CGPoint(x: w * 0.155, y: baseY - 32))
        p.addLine(to: CGPoint(x: w * 0.17, y: baseY - 22))
        p.addLine(to: CGPoint(x: w * 0.17, y: baseY + 4))
        // Central dome
        p.addLine(to: CGPoint(x: w * 0.38, y: baseY + 4))
        p.addQuadCurve(to: CGPoint(x: w * 0.50, y: baseY - 26), control: CGPoint(x: w * 0.41, y: baseY - 20))
        p.addQuadCurve(to: CGPoint(x: w * 0.62, y: baseY + 4), control: CGPoint(x: w * 0.59, y: baseY - 20))
        // Right minaret
        p.addLine(to: CGPoint(x: w * 0.83, y: baseY + 4))
        p.addLine(to: CGPoint(x: w * 0.83, y: baseY - 22))
        p.addLine(to: CGPoint(x: w * 0.845, y: baseY - 32))
        p.addLine(to: CGPoint(x: w * 0.86, y: baseY - 22))
        p.addLine(to: CGPoint(x: w * 0.86, y: baseY + 6))
        p.addLine(to: CGPoint(x: w, y: baseY + 6))
        p.addLine(to: CGPoint(x: w, y: h))
        p.closeSubpath()

        ctx.fill(p, with: .color(footerColor.opacity(0.68)))

        if isNight {
            let lampColor = Color(argbHex: 0xFFFFD54F).opacity(0.72)
            for lx in [w * 0.155, w * 0.46, w * 0.50, w * 0.54, w * 0.845] {
                ctx.fill(Path(ellipseIn: CGRect(x: lx - 1.8, y: baseY + 10, width: 3.6, height: 3.6)), with: .color(lampColor))
            }
        }
    }

    private func frac(_ x: Double) -> Double {
        let r = x - floor(x)
        return r < 0 ? r + 1.0 : r
    }
}
