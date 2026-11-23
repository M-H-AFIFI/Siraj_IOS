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

        ZStack {
            AdhanSkyBackdrop(
                spec: spec,
                matchSky: matchSky,
                animate: theme.motionEnabled && !finished && appState.pinnedSkyTime == nil
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Text(datesLine)
                    .font(theme.scaledFont(size: 13.5, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                    .padding(.horizontal, 24)

                Spacer(minLength: 24)

                AdhanCelestialOrb(
                    spec: spec,
                    matchSky: matchSky,
                    sounding: !finished,
                    animate: theme.motionEnabled && !finished && appState.pinnedSkyTime == nil
                )
                .frame(width: 148, height: 148)

                Spacer().frame(height: 28)

                VStack(spacing: 8) {
                    Text(theme.t(finished ? "adhan_screen_finished" : "adhan_screen_now"))
                        .font(theme.scaledFont(size: 16, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.84))

                    Text(finished ? theme.t("adhan_screen_finished_body") : theme.t(prayer.stringKey))
                        .font(.system(size: finished ? 28 : 48, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: Color.black.opacity(0.36), radius: 10, x: 0, y: 2)

                    if !finished {
                        Text(prayerClock)
                            .font(theme.scaledFont(size: 22, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.88))

                        Text(activeVoice.localizedTitle(language: theme.language))
                            .font(theme.scaledFont(size: 13.5, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.68))
                            .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 32)

                if !finished {
                    HStack(spacing: 12) {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white.opacity(0.72))
                        Slider(value: $sliderVolume, in: 0.1...1.0)
                            .tint(Color(argb: spec.skyTheme.orbCore))
                            .onChange(of: sliderVolume) { _, val in
                                audioEngine.setVolume(val)
                                appState.updateSettings { $0.adhanVolume = val }
                            }
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white.opacity(0.72))
                    }
                    .padding(.horizontal, 36)
                    .padding(.bottom, 22)
                }

                Button {
                    audioEngine.stop()
                    onDismiss()
                } label: {
                    HStack(spacing: 10) {
                        if !finished {
                            Image(systemName: "bell.slash.fill")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        Text(theme.t(finished ? "adhan_screen_close" : "adhan_screen_stop"))
                            .font(theme.scaledFont(size: 17, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: 290)
                    .frame(height: 56)
                    .background(Capsule().fill(Color.white.opacity(finished ? 0.12 : 0.17)))
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.28), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("adhan_alert_stop")
                .padding(.bottom, 28)
            }
        }
        .onAppear {
            sliderVolume = appState.settings.adhanVolume
            if !appState.isUITesting {
                audioEngine.playFullAdhan(for: prayer, settings: appState.settings)
            }
        }
        .onDisappear {
            audioEngine.stop()
        }
    }
}

private struct AdhanSkyBackdrop: View {
    @Environment(\.sirajTheme) private var theme
    let spec: AdhanSkyAtmosphere
    let matchSky: Bool
    let animate: Bool

    private static let stars: [(x: Double, y: Double, r: Double)] = [
        (0.11, 0.08, 1.3), (0.24, 0.14, 1.0), (0.41, 0.07, 1.4), (0.62, 0.11, 1.1),
        (0.79, 0.09, 1.5), (0.89, 0.17, 1.2), (0.16, 0.23, 1.2), (0.35, 0.21, 0.9),
        (0.54, 0.19, 1.3), (0.72, 0.24, 1.0), (0.86, 0.28, 1.4), (0.09, 0.34, 1.1),
        (0.29, 0.33, 1.2), (0.68, 0.35, 1.1), (0.91, 0.39, 1.2), (0.19, 0.45, 1.0),
        (0.46, 0.43, 1.2), (0.77, 0.47, 1.0), (0.13, 0.54, 0.9), (0.84, 0.56, 1.1)
    ]

    var body: some View {
        let deepBase = Color(argbHex: 0xFF060A13)
        let skyColors: [Color] = {
            if matchSky {
                let s = spec.skyTheme.sky
                return [Color(argb: s[0]), Color(argb: s[1]), Color(argb: s[3]), Color(argb: s[4]).opacity(0.92), deepBase]
            }
            return [theme.primaryContainer.opacity(0.55), Color(argbHex: 0xFF0C1322), deepBase]
        }()

        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: !animate)) { timeline in
            let t = animate ? timeline.date.timeIntervalSinceReferenceDate : 3.0
            Canvas { ctx, size in
                let rect = CGRect(origin: .zero, size: size)
                ctx.fill(Path(rect), with: .linearGradient(Gradient(colors: skyColors), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))

                if matchSky {
                    let bloomCenter = CGPoint(x: size.width * 0.5, y: size.height * 0.52)
                    let bloomColor = Color(argb: spec.horizonGlowColor)
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: -size.width * 0.25, y: size.height * 0.22, width: size.width * 1.5, height: size.height * 0.60)),
                        with: .radialGradient(
                            Gradient(colors: [bloomColor.opacity(spec.horizonGlowAlpha), bloomColor.opacity(spec.horizonGlowAlpha * 0.35), .clear]),
                            center: bloomCenter, startRadius: 12, endRadius: size.width * 0.72
                        )
                    )

                    let starAlpha = max(spec.starDensity, spec.showStars ? 0.45 : 0.0)
                    if starAlpha > 0.05 {
                        for (idx, st) in Self.stars.enumerated() {
                            let twinkle = 0.5 + 0.5 * sin(t * 0.9 + Double(idx) * 1.3)
                            let alpha = starAlpha * (0.4 + 0.6 * twinkle) * max(0.0, 1.0 - st.y * 1.4)
                            let px = st.x * size.width
                            let py = st.y * size.height
                            ctx.fill(
                                Path(ellipseIn: CGRect(x: px - st.r, y: py - st.r, width: st.r * 2, height: st.r * 2)),
                                with: .color(Color.white.opacity(alpha))
                            )
                        }
                    }
                }

                // Bottom vignette keeps the stop button and captions legible on bright daytime skies.
                ctx.fill(
                    Path(rect),
                    with: .linearGradient(
                        Gradient(colors: [.clear, deepBase.opacity(0.45), deepBase.opacity(0.92)]),
                        startPoint: CGPoint(x: 0, y: size.height * 0.48),
                        endPoint: CGPoint(x: 0, y: size.height)
                    )
                )
            }
        }
    }
}

private struct AdhanCelestialOrb: View {
    let spec: AdhanSkyAtmosphere
    let matchSky: Bool
    let sounding: Bool
    let animate: Bool

    var body: some View {
        let core = matchSky ? Color(argb: spec.skyTheme.orbCore) : Color(argbHex: 0xFFE2C374)
        let glow = matchSky ? Color(argb: spec.skyTheme.orbGlow) : Color(argbHex: 0xFFD4AF37)

        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: !animate)) { timeline in
            let t = animate ? timeline.date.timeIntervalSinceReferenceDate : 1.0
            let pulse = sounding ? (1.0 + 0.06 * sin(t * 2.1)) : 0.94

            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [glow.opacity(0.45), glow.opacity(0.12), .clear], center: .center, startRadius: 16, endRadius: 74))
                    .scaleEffect(pulse)

                if sounding {
                    Circle()
                        .stroke(core.opacity(0.30), lineWidth: 1.4)
                        .frame(width: 96, height: 96)
                        .scaleEffect(1.0 + 0.14 * (0.5 + 0.5 * sin(t * 1.6)))
                }

                if matchSky && spec.isCrescent {
                    Image("ic_siraj_crescent_star")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 58, height: 58)
                        .foregroundStyle(core)
                        .shadow(color: glow.opacity(0.6), radius: 14)
                } else {
                    Circle()
                        .fill(RadialGradient(colors: [.white, core], center: .center, startRadius: 4, endRadius: 34))
                        .frame(width: 64, height: 64)
                        .shadow(color: glow.opacity(0.75), radius: 18)
                }
            }
        }
    }
}
