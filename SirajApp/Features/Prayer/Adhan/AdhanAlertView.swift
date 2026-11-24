import SwiftUI
import SirajCore

struct AdhanAlertView: View {
    @Environment(\.sirajTheme) private var theme
    let prayer: PrayerType
    let appState: AppState
    let audioEngine: AdhanAudioEngine
    let onDismiss: () -> Void

    @State private var sliderVolume: Double = 0.85

    var body: some View {
        let spec = AdhanSkySpec.atmosphere(for: prayer)
        let matchSky = appState.settings.isAdhanScreenMatchPrayer
        let finished = audioEngine.adhanFinished
        let animate = theme.motionEnabled && !finished && appState.pinnedSkyTime == nil
        let prayerEntry = appState.prayerDay[prayer]
        let prayerClock = TimeFormatter.formatTime(
            prayerEntry.time,
            timeZone: appState.activePlace.timeZone,
            hourFormat: appState.settings.hourFormat,
            numeralSystem: appState.settings.numeralSystem,
            lang: theme.language
        )
        let hijri = HijriFormatter.format(appState.hijriDate, lang: theme.language, numeralSystem: appState.settings.numeralSystem)
        let gregorian = HijriFormatter.formatGregorian(appState.activePlace.today(at: appState.currentTime), lang: theme.language, numeralSystem: appState.settings.numeralSystem)
        let sep = theme.isRTL ? "، " : " · "
        let datesLine = "\(hijri)\(sep)\(gregorian)"
        let activeVoice: AdhanVoice = {
            if prayer == .fajr && appState.settings.fajrAdhanEnabled {
                return AdhanVoiceResolver.fajrVoice(for: appState.settings.azanSound, preferredFajrId: appState.settings.fajrAdhanVoice)
            }
            return AdhanVoiceResolver.findVoice(appState.settings.azanSound)
        }()
        let captionShadowAlpha: Double = (matchSky && spec.isDaytime) ? 0.28 : 0.0

        ZStack {
            AdhanAtmosphericBackdrop(
                spec: spec,
                matchPrayerSky: matchSky,
                animate: animate
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Text(datesLine)
                    .font(theme.scaledFont(size: 14, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.68))
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                    .padding(.horizontal, 28)

                Spacer(minLength: 20)

                AdhanCelestialCenterpiece(
                    spec: spec,
                    matchPrayerSky: matchSky,
                    sounding: !finished,
                    animate: animate
                )
                .frame(width: 224, height: 224)

                Spacer().frame(height: 24)

                VStack(spacing: 6) {
                    Text(theme.t(finished ? "adhan_screen_finished" : "adhan_screen_now"))
                        .font(theme.scaledFont(size: 16, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.84))
                        .shadow(color: Color.black.opacity(captionShadowAlpha), radius: 6, x: 0, y: 1.5)

                    Text(finished ? theme.t("adhan_screen_finished_body") : theme.t(prayer.stringKey))
                        .font(.system(size: finished ? 28 : 48, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: Color.black.opacity(0.36), radius: 10, x: 0, y: 2)

                    if !finished {
                        Text(prayerClock)
                            .font(theme.scaledFont(size: 24, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.86))
                            .shadow(color: Color.black.opacity(captionShadowAlpha), radius: 6, x: 0, y: 1.5)

                        Text(activeVoice.localizedTitle(language: theme.language))
                            .font(theme.scaledFont(size: 13, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.66))
                            .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 28)
                .animation(theme.motionEnabled ? .easeInOut(duration: 0.35) : nil, value: finished)

                Spacer(minLength: 28)

                if !finished {
                    HStack(spacing: 12) {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.66))
                        Slider(value: $sliderVolume, in: 0.1...1.0) { editing in
                            if !editing {
                                appState.updateSettings { $0.adhanVolume = sliderVolume }
                            }
                        }
                        .tint(Color(argb: spec.skyTheme.orbCore))
                        .onChange(of: sliderVolume) { _, val in
                            audioEngine.setVolume(val)
                        }
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.66))
                    }
                    .frame(maxWidth: 290)
                    .padding(.bottom, 18)
                }

                Button {
                    audioEngine.stop()
                    onDismiss()
                } label: {
                    HStack(spacing: 10) {
                        if !finished {
                            Image(systemName: "bell.slash.fill")
                                .font(.system(size: 19, weight: .semibold))
                        }
                        Text(theme.t(finished ? "adhan_screen_close" : "adhan_screen_stop"))
                            .font(theme.scaledFont(size: 16.5, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: 290)
                    .frame(height: 56)
                    .background(Capsule().fill(Color.white.opacity(finished ? 0.10 : 0.15)))
                    .overlay(Capsule().strokeBorder(Color.white.opacity(finished ? 0.18 : 0.24), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("adhan_alert_stop")
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            sliderVolume = appState.settings.adhanVolume
            let shouldPlay = appState.isAdhanAlertTest || appState.settings.azanReminderType.lowercased() == "azan"
            if !appState.isUITesting && shouldPlay {
                audioEngine.playFullAdhan(for: prayer, settings: appState.settings)
            }
        }
        .onDisappear {
            appState.isAdhanAlertTest = false
            audioEngine.stop()
        }
    }
}

private struct AdhanAtmosphericBackdrop: View {
    @Environment(\.sirajTheme) private var theme
    let spec: AdhanSkyAtmosphere
    let matchPrayerSky: Bool
    let animate: Bool

    private static let stars: [(x: Double, y: Double, r: Double)] = [
        (0.11, 0.08, 1.3), (0.24, 0.14, 1.0), (0.41, 0.07, 1.4), (0.62, 0.11, 1.1),
        (0.79, 0.09, 1.5), (0.89, 0.17, 1.2), (0.16, 0.23, 1.2), (0.35, 0.21, 0.9),
        (0.54, 0.19, 1.3), (0.72, 0.24, 1.0), (0.86, 0.28, 1.4), (0.09, 0.34, 1.1),
        (0.29, 0.33, 1.2), (0.68, 0.35, 1.1), (0.91, 0.39, 1.2), (0.19, 0.45, 1.0),
        (0.46, 0.43, 1.2), (0.77, 0.47, 1.0), (0.13, 0.54, 0.9), (0.84, 0.56, 1.1)
    ]

    var body: some View {
        let stops = buildSkyStops()

        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: !animate)) { timeline in
            let elapsed = animate ? timeline.date.timeIntervalSinceReferenceDate : 3.2
            let twinkle = animate ? (0.5 - 0.5 * cos(elapsed * (.pi / 7.5))) : 0.5
            let motePhase = animate ? LiveSceneToolkit.positiveMod(elapsed / 18.0, 1.0) : 0.3

            Canvas { ctx, size in
                let w = Double(size.width)
                let h = Double(size.height)
                guard w > 0, h > 0 else { return }

                ctx.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .linearGradient(Gradient(stops: stops), startPoint: .zero, endPoint: CGPoint(x: 0, y: h))
                )

                if matchPrayerSky {
                    // Scaled circle instead of an oval keeps the elliptical horizon bloom free of sharp edges.
                    let bloomC = CGPoint(x: w * 0.50, y: h * 0.54)
                    let bloomR = w * 0.72
                    let glowC = Color(argb: spec.horizonGlowColor)
                    var bctx = ctx
                    bctx.translateBy(x: bloomC.x, y: bloomC.y)
                    bctx.scaleBy(x: 1.45, y: 0.78)
                    bctx.fill(
                        Path(ellipseIn: CGRect(x: -bloomR, y: -bloomR, width: bloomR * 2, height: bloomR * 2)),
                        with: .radialGradient(
                            Gradient(colors: [
                                glowC.opacity(spec.horizonGlowAlpha),
                                glowC.opacity(spec.horizonGlowAlpha * 0.36),
                                .clear
                            ]),
                            center: .zero,
                            startRadius: 0,
                            endRadius: bloomR
                        )
                    )

                    if spec.isDaytime {
                        let titleC = CGPoint(x: w * 0.50, y: h * 0.60)
                        let featherR = w * 0.62
                        let darkInk = Color(argbHex: 0xFF0A1220)
                        var fctx = ctx
                        fctx.translateBy(x: titleC.x, y: titleC.y)
                        fctx.scaleBy(x: 1.50, y: 0.65)
                        fctx.fill(
                            Path(ellipseIn: CGRect(x: -featherR, y: -featherR, width: featherR * 2, height: featherR * 2)),
                            with: .radialGradient(
                                Gradient(colors: [darkInk.opacity(0.20), darkInk.opacity(0.08), .clear]),
                                center: .zero,
                                startRadius: 0,
                                endRadius: featherR
                            )
                        )
                    }

                    let starVis = min(1.0, max(spec.skyTheme.starAlpha, spec.showStars ? spec.starDensity * 0.85 : 0.0))
                    if starVis > 0.05 {
                        for (idx, st) in Self.stars.enumerated() {
                            let altFade: Double = spec.warmth > 0.5
                                ? min(1.0, max(0.0, (0.38 - st.y) / 0.26))
                                : min(1.0, max(0.0, (0.60 - st.y) / 0.28))
                            if altFade <= 0.02 { continue }
                            let wave = sin(twinkle * .pi + Double(idx) * 0.85)
                            let alpha = starVis * altFade * (0.20 + 0.52 * wave * wave)
                            let cx = w * st.x
                            let cy = h * st.y
                            ctx.fill(
                                Path(ellipseIn: CGRect(x: cx - st.r, y: cy - st.r, width: st.r * 2, height: st.r * 2)),
                                with: .color(.white.opacity(alpha))
                            )
                            if st.r >= 1.3 && alpha > 0.22 {
                                let hr = st.r * 3.2
                                ctx.fill(
                                    Path(ellipseIn: CGRect(x: cx - hr, y: cy - hr, width: hr * 2, height: hr * 2)),
                                    with: .radialGradient(
                                        Gradient(colors: [.white.opacity(alpha * 0.45), .clear]),
                                        center: CGPoint(x: cx, y: cy),
                                        startRadius: 0,
                                        endRadius: hr
                                    )
                                )
                            }
                        }
                    }

                    if spec.moteStrength > 0.08 {
                        let moteColor = SceneRGB(argb: spec.skyTheme.orbCore).lerp(to: SceneRGB(hex: 0xFFFFE4A8), 0.5)
                        for i in 0..<12 {
                            let seedX = Double((i * 73 + 19) % 100) / 100.0
                            let seedY = Double((i * 41 + 7) % 100) / 100.0
                            let life = LiveSceneToolkit.positiveMod(motePhase + Double(i) * 0.13, 1.0)
                            let mx = w * (0.12 + seedX * 0.76 + 0.04 * sin(life * 2.0 * .pi + Double(i)))
                            let my = h * (0.18 + LiveSceneToolkit.positiveMod(seedY + 1.0 - life * 0.35, 0.44))
                            let fade = min(1.0, max(0.0, sin(life * .pi)))
                            let r = 1.1 + Double(i % 3) * 0.45
                            ctx.fill(
                                Path(ellipseIn: CGRect(x: mx - r, y: my - r, width: r * 2, height: r * 2)),
                                with: .color(moteColor.color(alpha: 0.22 * spec.moteStrength * fade))
                            )
                        }
                    }
                } else {
                    let auroraC = CGPoint(x: w * (0.42 + 0.14 * twinkle), y: h * 0.29)
                    let ar = w * 0.72
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: auroraC.x - ar, y: auroraC.y - ar, width: ar * 2, height: ar * 2)),
                        with: .radialGradient(
                            Gradient(colors: [theme.primary.opacity(0.12), .clear]),
                            center: auroraC,
                            startRadius: 0,
                            endRadius: ar
                        )
                    )
                    for (idx, st) in Self.stars.enumerated() {
                        let wave = sin(twinkle * .pi + Double(idx) * 0.9)
                        let a = 0.15 + 0.42 * wave * wave
                        let cx = w * st.x
                        let cy = h * st.y
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: cx - st.r, y: cy - st.r, width: st.r * 2, height: st.r * 2)),
                            with: .color(.white.opacity(a))
                        )
                    }
                }
            }
        }
    }

    private func buildSkyStops() -> [Gradient.Stop] {
        let deepBase = SceneRGB(hex: 0xFF060A13)
        if !matchPrayerSky {
            let pc = SceneRGB(argb: theme.scheme.primaryContainer)
            return [
                .init(color: pc.lerp(to: SceneRGB(hex: 0xFF0B101C), 0.46).color(), location: 0.00),
                .init(color: pc.lerp(to: deepBase, 0.72).color(), location: 0.52),
                .init(color: deepBase.color(), location: 1.00)
            ]
        }

        let grad = spec.skyTheme.sky.map(SceneRGB.init(argb:))
        guard !grad.isEmpty else {
            return [.init(color: deepBase.color(), location: 0), .init(color: deepBase.color(), location: 1)]
        }

        func sample(_ frac: Double) -> SceneRGB {
            if grad.count == 1 { return grad[0] }
            let f = min(1.0, max(0.0, frac)) * Double(grad.count - 1)
            let lo = min(grad.count - 1, max(0, Int(f)))
            let hi = min(grad.count - 1, lo + 1)
            return grad[lo].lerp(to: grad[hi], f - Double(lo))
        }

        let top = sample(0.00).lerp(to: SceneRGB(hex: 0xFF060B14), 0.04)
        let upperMid = sample(0.28)

        // Daytime skies end in pale sand/cream; route the lower fade through upperMid to avoid an olive band behind white text.
        if spec.skyTheme.isWarmGlow && !spec.skyTheme.showCrescent {
            let midSky = sample(0.52)
            let horizon = sample(0.72).lerp(to: upperMid.lerp(to: deepBase, 0.42), 0.48)
            let lowerMid = upperMid.lerp(to: deepBase, 0.78)
            let lowerAnchor = upperMid.lerp(to: deepBase, 0.94)
            return [
                .init(color: top.color(), location: 0.00),
                .init(color: upperMid.color(), location: 0.24),
                .init(color: midSky.color(), location: 0.48),
                .init(color: horizon.color(), location: 0.64),
                .init(color: lowerMid.color(), location: 0.78),
                .init(color: lowerAnchor.color(), location: 0.90),
                .init(color: deepBase.color(), location: 1.00)
            ]
        }

        let midSky = sample(0.62)
        let horizon = sample(0.94).lerp(to: deepBase, 0.22)
        let last = grad.last ?? deepBase
        return [
            .init(color: top.color(), location: 0.00),
            .init(color: upperMid.color(), location: 0.24),
            .init(color: midSky.color(), location: 0.48),
            .init(color: horizon.color(), location: 0.64),
            .init(color: last.lerp(to: deepBase, 0.72).color(), location: 0.78),
            .init(color: last.lerp(to: deepBase, 0.92).color(), location: 0.90),
            .init(color: deepBase.color(), location: 1.00)
        ]
    }
}

private struct AdhanCelestialCenterpiece: View {
    let spec: AdhanSkyAtmosphere
    let matchPrayerSky: Bool
    let sounding: Bool
    let animate: Bool

    var body: some View {
        let orbCore = SceneRGB(argb: spec.skyTheme.orbCore)
        let orbGlow = SceneRGB(argb: spec.skyTheme.orbGlow)
        let rippleTint: Color = {
            if !matchPrayerSky { return .white }
            if spec.isDaytime { return orbCore.lerp(to: .white, 0.38).color() }
            if spec.duskUndersideGlow > 0.5 { return Color(argbHex: 0xFFFFE0BE) }
            return Color(argbHex: 0xFFE2E8F0)
        }()

        ZStack {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !(animate && sounding))) { timeline in
                let elapsed = (animate && sounding) ? timeline.date.timeIntervalSinceReferenceDate : 0.0
                let waveT: Double? = (animate && sounding) ? LiveSceneToolkit.positiveMod(elapsed / 3.6, 1.0) : nil
                let breath: Double = (animate && sounding) ? (0.5 - 0.5 * cos(elapsed * (.pi / 3.2))) : 0.5

                Canvas { ctx, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let baseR: Double = matchPrayerSky ? 29.0 : 42.0
                    let maxRippleR = min(104.0, Double(min(size.width, size.height)) / 2.0)

                    // Outer Mie atmospheric bloom
                    let bloomStrength = 0.90 + 0.20 * breath
                    let glowR = (matchPrayerSky ? 104.0 : 96.0) * (0.96 + 0.06 * breath)
                    let glowColor = matchPrayerSky ? orbGlow : SceneRGB.white
                    let basePeak = matchPrayerSky ? 0.34 : 0.084
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: center.x - glowR, y: center.y - glowR, width: glowR * 2, height: glowR * 2)),
                        with: .radialGradient(
                            Gradient(stops: [
                                .init(color: glowColor.color(alpha: basePeak * bloomStrength), location: 0.00),
                                .init(color: glowColor.color(alpha: (matchPrayerSky ? 0.13 : 0.03) * bloomStrength), location: 0.42),
                                .init(color: glowColor.color(alpha: (matchPrayerSky ? 0.04 : 0.009) * bloomStrength), location: 0.74),
                                .init(color: .clear, location: 1.00)
                            ]),
                            center: center,
                            startRadius: 0,
                            endRadius: glowR
                        )
                    )

                    // Three cubic-ease-out expanding wavefront ripples
                    for i in 0..<3 {
                        let p = waveT.map { LiveSceneToolkit.positiveMod($0 + Double(i) / 3.0, 1.0) } ?? (Double(i + 1) / 4.0)
                        let eased = 1.0 - pow(1.0 - p, 3.0)
                        let a: Double = waveT != nil
                            ? min(1.0, max(0.0, sin(p * .pi))) * 0.15 * (1.0 - p * 0.35)
                            : 0.08 * (1.0 - p)
                        let r = baseR + (maxRippleR - baseR) * eased
                        ctx.stroke(
                            Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                            with: .color(rippleTint.opacity(a)),
                            lineWidth: 0.8
                        )
                    }

                    if matchPrayerSky {
                        let orbR = 25.0
                        if spec.isDaytime {
                            let chromoR = orbR * 2.15
                            ctx.fill(
                                Path(ellipseIn: CGRect(x: center.x - chromoR, y: center.y - chromoR, width: chromoR * 2, height: chromoR * 2)),
                                with: .radialGradient(
                                    Gradient(stops: [
                                        .init(color: .white.opacity(0.88), location: 0.00),
                                        .init(color: SceneRGB.white.lerp(to: orbGlow, 0.35).color(alpha: 0.46), location: 0.45),
                                        .init(color: orbGlow.color(alpha: 0.14), location: 0.74),
                                        .init(color: .clear, location: 1.00)
                                    ]),
                                    center: center,
                                    startRadius: 0,
                                    endRadius: chromoR
                                )
                            )
                            let coreEdge = orbCore.lerp(to: orbGlow, 0.22)
                            ctx.fill(
                                Path(ellipseIn: CGRect(x: center.x - orbR, y: center.y - orbR, width: orbR * 2, height: orbR * 2)),
                                with: .radialGradient(
                                    Gradient(colors: [Color(argbHex: 0xFFFFFEFA), orbCore.color(), coreEdge.color()]),
                                    center: CGPoint(x: center.x - orbR * 0.14, y: center.y - orbR * 0.14),
                                    startRadius: 0,
                                    endRadius: orbR * 1.15
                                )
                            )
                        } else if spec.isCrescent {
                            let lightC = spec.duskUndersideGlow > 0.5 ? Color(argbHex: 0xFFFFF7E6) : Color(argbHex: 0xFFF8FAFC)
                            let shadowC = spec.duskUndersideGlow > 0.5 ? Color(argbHex: 0xFFFFD699) : Color(argbHex: 0xFFCBD5E1)
                            ctx.drawLayer { layer in
                                let fullRect = CGRect(x: center.x - orbR, y: center.y - orbR, width: orbR * 2, height: orbR * 2)
                                layer.fill(
                                    Path(ellipseIn: fullRect),
                                    with: .linearGradient(
                                        Gradient(colors: [lightC, shadowC]),
                                        startPoint: CGPoint(x: center.x - orbR, y: center.y - orbR),
                                        endPoint: CGPoint(x: center.x + orbR, y: center.y + orbR)
                                    )
                                )
                                let cutR = orbR * 0.86
                                let cutCenter = CGPoint(x: center.x + orbR * 0.38, y: center.y - orbR * 0.18)
                                layer.blendMode = .destinationOut
                                layer.fill(
                                    Path(ellipseIn: CGRect(x: cutCenter.x - cutR, y: cutCenter.y - cutR, width: cutR * 2, height: cutR * 2)),
                                    with: .color(.black)
                                )
                            }
                        } else {
                            ctx.fill(
                                Path(ellipseIn: CGRect(x: center.x - orbR, y: center.y - orbR, width: orbR * 2, height: orbR * 2)),
                                with: .radialGradient(
                                    Gradient(colors: [Color(argbHex: 0xFFF8FAFC), Color(argbHex: 0xFFE2E8F0), Color(argbHex: 0xFF94A3B8)]),
                                    center: CGPoint(x: center.x - orbR * 0.25, y: center.y - orbR * 0.25),
                                    startRadius: 0,
                                    endRadius: orbR * 1.35
                                )
                            )
                        }
                    }
                }
            }

            if !matchPrayerSky {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .overlay(Circle().strokeBorder(Color.white.opacity(0.20), lineWidth: 0.9))
                    Image("ic_siraj_emblem")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 38, height: 38)
                        .foregroundStyle(Color.white.opacity(0.92))
                }
                .frame(width: 84, height: 84)
            }
        }
    }
}
