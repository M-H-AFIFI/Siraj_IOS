import SwiftUI
import SirajCore

struct AnimatedSkyCard: View {
    @Environment(\.sirajTheme) private var theme
    @Environment(\.scenePhase) private var scenePhase

    let appState: AppState
    let onTapHijri: () -> Void
    let onTapCard: () -> Void

    private static let countdownSlot = "{countdown}"
    private static let hijriGold = Color(argbHex: 0xFFE5B558)
    private static let moonlitText = ArgbColor.hex(0xFFC8D6FF)

    var body: some View {
        let isPinned = appState.pinnedSkyTime != nil
        let paused = isPinned || !theme.motionEnabled || scenePhase != .active

        TimelineView(.animation(minimumInterval: isPinned ? 60 : (1.0 / 12.0), paused: paused)) { timeline in
            let now = appState.pinnedSkyTime ?? timeline.date
            let day = PrayerCalculator.today(place: appState.activePlace, settings: appState.settings.calculationSettings, now: now)
            let state = PrayerState.at(day: day, now: now)
            let skyMoment = SkyTimeline.at(now, prayers: day.entries)
            let skyColors = SkyPalette.tint(skyMoment.colors, accent: theme.scheme.primary)
            let displayed = state?.prayer ?? day.next ?? day[.fajr]
            let arc = SolarArc.at(now, prayers: day.entries, next: displayed)
            let moon = MoonPhase.at(now)
            let animT = isPinned ? 4.2 : timeline.date.timeIntervalSinceReferenceDate

            cardBody(
                now: now,
                displayed: displayed,
                state: state,
                skyColors: skyColors,
                twilight: skyMoment.twilight,
                arc: arc,
                moon: moon,
                t: animT
            )
        }
    }

    private func cardBody(
        now: Date,
        displayed: PrayerTimeEntry,
        state: PrayerState?,
        skyColors: SkyColors,
        twilight: SkyTwilight,
        arc: SolarArc,
        moon: MoonPhaseInfo,
        t: Double
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: 32, style: .continuous)
        let isDuringAzan: Bool = { if case .azanCalled = state { return true }; return false }()
        let isWaitingForIqama: Bool = { if case .waitingForIqama = state { return true }; return false }()
        let isInPrayer: Bool = { if case .inPrayer = state { return true }; return false }()
        let isMaghrib = displayed.type == .maghrib
        let diffMinutes = Int(displayed.time.timeIntervalSince(now) / 60.0)
        let isUrgent = !isDuringAzan && !isWaitingForIqama && !isInPrayer && (1...15).contains(diffMinutes)
        let isSoon = !isDuringAzan && !isWaitingForIqama && !isInPrayer && (16...60).contains(diffMinutes)

        let prayerName: String = {
            if isDuringAzan && isMaghrib { return theme.t("maghrib_prayer_now") }
            if displayed.type == .dhuhr && appState.activePlace.today(at: displayed.time).weekdaySundayZero == 5 {
                return theme.t("prayer_jummah")
            }
            return theme.t(displayed.type.stringKey)
        }()

        let prayerClock = TimeFormatter.formatTime(
            displayed.time,
            timeZone: appState.activePlace.timeZone,
            hourFormat: theme.settings.hourFormat,
            numeralSystem: theme.settings.numeralSystem,
            lang: theme.language
        )

        let countdownNumber = formattedCountdownNumber(state: state)
        let countdownTemplate: String? = {
            if isDuringAzan || isInPrayer { return nil }
            if isWaitingForIqama { return theme.tf("until_iqama_format", Self.countdownSlot) }
            return theme.tf("dashboard_countdown_format", Self.countdownSlot)
        }()

        let textLight = arc.isDaytime
            ? ArgbColor.lerp(skyColors.orbCore, skyColors.orbGlow, 0.55)
            : Self.moonlitText
        let nameGradient = LinearGradient(
            colors: [.white, Color(argb: ArgbColor.lerp(.hex(0xFFFFFFFF), textLight, 0.32))],
            startPoint: .top, endPoint: .bottom
        )
        let timeGradient = LinearGradient(
            stops: [
                .init(color: .white, location: 0.0),
                .init(color: .white, location: 0.45),
                .init(color: Color(argb: ArgbColor.lerp(.hex(0xFFFFFFFF), textLight, 0.55)), location: 1.0)
            ],
            startPoint: .top, endPoint: .bottom
        )

        let civilToday = appState.activePlace.today(at: now)
        let currentHijri = appState.hijriCalendar.toHijri(civilToday)
        let hijriText = HijriFormatter.format(currentHijri, lang: theme.language, numeralSystem: theme.settings.numeralSystem)
        let gregorianText = HijriFormatter.formatGregorian(civilToday, lang: theme.language, numeralSystem: theme.settings.numeralSystem)
        let badgeAngle = arc.isDaytime
            ? (theme.motionEnabled ? t * 6.0 : 0.0)
            : (theme.motionEnabled ? 9.0 * sin(t * (2.0 * .pi / 7.0)) : 0.0)

        return ZStack(alignment: .bottom) {
            Button(action: onTapCard) {
                ZStack(alignment: .top) {
                    CelestialArcCanvas(
                        colors: skyColors,
                        twilight: twilight,
                        arc: arc,
                        moon: moon,
                        timeSeconds: t,
                        motionEnabled: theme.motionEnabled,
                        cornerRadius: 32
                    )

                    // Anchored to visual top-right in every language regardless of RTL layout mirroring.
                    HStack {
                        Spacer()
                        HStack(spacing: 6) {
                            Text(theme.t(arc.phaseKey))
                                .font(.system(size: min(11.5 * theme.textScale, 14), weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.95))
                                .lineLimit(1)
                            Image(systemName: arc.isDaytime ? "sun.max.fill" : "moon.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color(argb: skyColors.orbGlow))
                                .rotationEffect(.degrees(badgeAngle))
                        }
                        .environment(\.layoutDirection, theme.isRTL ? .rightToLeft : .leftToRight)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.black.opacity(0.35)))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.32), Color(argb: skyColors.cardBorderTop).opacity(0.40), .clear],
                                        startPoint: .top, endPoint: .bottom
                                    ),
                                    lineWidth: 0.8
                                )
                        }
                    }
                    .environment(\.layoutDirection, .leftToRight)
                    .padding(.horizontal, 18)
                    .padding(.top, 14)

                    // Center hero stack
                    VStack(spacing: 2) {
                        stateBadge(
                            isDuringAzan: isDuringAzan,
                            isMaghrib: isMaghrib,
                            isWaitingForIqama: isWaitingForIqama,
                            isInPrayer: isInPrayer
                        )

                        HeroText(
                            text: prayerName,
                            font: .system(size: 26 * theme.textScale, weight: .black),
                            gradient: nameGradient
                        )
                        .padding(.top, 2)

                        HeroText(
                            text: prayerClock,
                            font: .system(size: 34 * theme.textScale, weight: .black, design: .rounded),
                            gradient: timeGradient
                        )
                        .padding(.top, 2)

                        countdownPill(
                            isDuringAzan: isDuringAzan,
                            isWaitingForIqama: isWaitingForIqama,
                            isInPrayer: isInPrayer,
                            isUrgent: isUrgent,
                            isSoon: isSoon,
                            skyColors: skyColors,
                            countdownTemplate: countdownTemplate,
                            countdownNumber: countdownNumber,
                            t: t
                        )
                        .padding(.top, 6)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 48)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("prayer_sky_card")

            calendarCapsule(gregorianText: gregorianText, hijriText: hijriText, moonPhase: moon.phaseFraction)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 380)
        .background(Color(argb: skyColors.cardBg))
        .clipShape(shape)
        .overlay {
            shape.strokeBorder(
                LinearGradient(
                    colors: [Color(argb: skyColors.cardBorderTop), Color(argb: skyColors.cardBorderBottom)],
                    startPoint: .top, endPoint: .bottom
                ),
                lineWidth: 1.0
            )
        }
    }

    private func stateBadge(isDuringAzan: Bool, isMaghrib: Bool, isWaitingForIqama: Bool, isInPrayer: Bool) -> some View {
        let label: String = {
            if isDuringAzan && isMaghrib { return theme.t("azan_maghrib_now") }
            if isDuringAzan { return theme.t("adhan_badge") }
            if isWaitingForIqama { return theme.t("iqama") }
            if isInPrayer { return theme.t("in_prayer") }
            return theme.t("next_prayer")
        }()
        let bg: Color = {
            if isDuringAzan { return Color(argbHex: 0xFFFF9800).opacity(0.25) }
            if isWaitingForIqama { return Color(argbHex: 0xFFFFD54F).opacity(0.20) }
            if isInPrayer { return Color(argbHex: 0xFF4CAF50).opacity(0.22) }
            return .clear
        }()
        let fg: Color = {
            if isDuringAzan { return Color(argbHex: 0xFFFFB74D) }
            if isWaitingForIqama { return Color(argbHex: 0xFFFFE082) }
            if isInPrayer { return Color(argbHex: 0xFF81C784) }
            return Color.white.opacity(0.85)
        }()

        return Text(label)
            .font(.system(size: 11 * theme.textScale, weight: .bold))
            .tracking(theme.isRTL ? 0 : 0.5)
            .foregroundStyle(fg)
            .shadow(color: Color.black.opacity(0.55), radius: 6, x: 0, y: 2)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(bg))
    }

    private func countdownPill(
        isDuringAzan: Bool,
        isWaitingForIqama: Bool,
        isInPrayer: Bool,
        isUrgent: Bool,
        isSoon: Bool,
        skyColors: SkyColors,
        countdownTemplate: String?,
        countdownNumber: String,
        t: Double
    ) -> some View {
        let pillAccent: Color = {
            if isDuringAzan { return Color(argbHex: 0xFFFF9800) }
            if isWaitingForIqama { return Color(argbHex: 0xFFE5B558) }
            if isInPrayer { return Color(argbHex: 0xFF81C784) }
            if isUrgent { return Color(argbHex: 0xFFFF7043) }
            if isSoon { return Color(argbHex: 0xFFFFB74D) }
            return Color(argb: skyColors.cardBorderTop)
        }()
        let pillBg: Color = {
            if isDuringAzan { return Color(argbHex: 0xFFE65100).opacity(0.38) }
            if isWaitingForIqama { return Color(argbHex: 0xFF3E2723).opacity(0.42) }
            if isInPrayer { return Color(argbHex: 0xFF1B5E20).opacity(0.38) }
            if isUrgent { return Color(argbHex: 0xFFB71C1C).opacity(0.32) }
            if isSoon { return Color(argbHex: 0xFF422006).opacity(0.35) }
            return Color.black.opacity(0.38)
        }()
        let iconTint: Color = {
            if isDuringAzan { return Color(argbHex: 0xFFFFB74D) }
            if isWaitingForIqama { return Color(argbHex: 0xFFFFD54F) }
            if isInPrayer { return Color(argbHex: 0xFF81C784) }
            if isUrgent { return Color(argbHex: 0xFFFF7043) }
            if isSoon { return Color(argbHex: 0xFFFFD54F) }
            return Self.hijriGold
        }()

        let pulsing = isDuringAzan || isWaitingForIqama || isUrgent
        let pulseAlpha = theme.motionEnabled ? (0.35 + 0.50 * (0.5 + 0.5 * sin(t * 2.6))) : 0.85
        let borderWidth: CGFloat = (isDuringAzan || isUrgent) ? 1.5 : ((isWaitingForIqama || isInPrayer) ? 1.2 : 1.0)
        let accentAlpha: Double = isInPrayer ? 0.85 : (isSoon ? 0.70 : 0.60)

        return HStack(spacing: 6) {
            Image(systemName: isDuringAzan ? "bell.badge.fill" : "timer")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconTint)

            if let template = countdownTemplate {
                let parts = template.components(separatedBy: Self.countdownSlot)
                let before = (parts.first ?? "").trimmingCharacters(in: .whitespaces)
                let after = (parts.count > 1 ? parts[1] : "").trimmingCharacters(in: .whitespaces)
                HStack(spacing: 4) {
                    if !before.isEmpty {
                        Text(before)
                            .font(.system(size: 12.5 * theme.textScale, weight: .black))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    RollingCountdownText(
                        text: countdownNumber,
                        fontSize: 12.5 * theme.textScale,
                        weight: .black,
                        color: .white
                    )
                    if !after.isEmpty {
                        Text(after)
                            .font(.system(size: 12.5 * theme.textScale, weight: .black))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                }
            } else {
                Text(isDuringAzan ? theme.t("azan_time_now") : theme.t("prayer_in_progress"))
                    .font(.system(size: 12.5 * theme.textScale, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
        .background(Capsule().fill(pillBg))
        .overlay {
            if pulsing {
                Capsule().strokeBorder(pillAccent.opacity(pulseAlpha), lineWidth: borderWidth)
            } else {
                Capsule().strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.32),
                            pillAccent.opacity(min(0.55, accentAlpha * 0.75)),
                            pillAccent.opacity(min(0.20, accentAlpha * 0.25))
                        ],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: borderWidth
                )
            }
        }
    }

    private func calendarCapsule(gregorianText: String, hijriText: String, moonPhase: Double) -> some View {
        Button {
            if theme.settings.isHapticEnabled {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            onTapHijri()
        } label: {
            VStack(spacing: 3) {
                if !gregorianText.isEmpty {
                    Text(gregorianText)
                        .font(.system(size: 11 * theme.textScale, weight: .semibold))
                        .tracking(theme.isRTL ? 0 : 0.3)
                        .foregroundStyle(Color.white.opacity(0.88))
                        .shadow(color: Color.black.opacity(0.85), radius: 3, x: 0, y: 1)
                        .lineLimit(1)
                }

                if !hijriText.isEmpty {
                    let pillShape = RoundedRectangle(cornerRadius: 14, style: .continuous)
                    HStack(spacing: 6) {
                        MoonPhaseGlyph(phaseFraction: moonPhase, color: Self.hijriGold)
                            .frame(width: 13, height: 13)
                        Text(hijriText)
                            .font(.system(size: 12 * theme.textScale, weight: .bold))
                            .foregroundStyle(Self.hijriGold)
                            .shadow(color: Color.black.opacity(0.60), radius: 2, x: 0, y: 1)
                            .lineLimit(1)
                    }
                    .padding(.leading, 10)
                    .padding(.trailing, 12)
                    .padding(.vertical, 4)
                    .background {
                        ZStack {
                            pillShape.fill(Color(argbHex: 0xFF070B14).opacity(0.40))
                            pillShape.fill(
                                LinearGradient(
                                    colors: [Self.hijriGold.opacity(0.12), Self.hijriGold.opacity(0.06)],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                        }
                    }
                    .overlay {
                        pillShape.strokeBorder(
                            LinearGradient(
                                colors: [Self.hijriGold.opacity(0.33), Self.hijriGold.opacity(0.18)],
                                startPoint: .top, endPoint: .bottom
                            ),
                            lineWidth: 1.0
                        )
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(theme.t("dashboard_open_calendar"))
    }

    private func formattedCountdownNumber(state: PrayerState?) -> String {
        switch state {
        case .upcomingAzan(_, let rem):
            return TimeFormatter.formatCountdown(seconds: rem, withHours: true, numeralSystem: theme.settings.numeralSystem, lang: theme.language)
        case .waitingForIqama(_, _, let until, _):
            return TimeFormatter.formatCountdown(seconds: until, withHours: false, numeralSystem: theme.settings.numeralSystem, lang: theme.language)
        default:
            return TimeFormatter.formatCountdown(seconds: 0, withHours: true, numeralSystem: theme.settings.numeralSystem, lang: theme.language)
        }
    }
}
