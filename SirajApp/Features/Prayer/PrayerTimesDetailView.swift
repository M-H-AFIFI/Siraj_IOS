import SwiftUI
import SirajCore

struct PrayerTimesDetailView: View {
    @Environment(\.sirajTheme) private var theme
    @Environment(\.scenePhase) private var scenePhase
    let appState: AppState
    var onTapLocation: () -> Void = {}

    private static let moonlitText = ArgbColor.hex(0xFFC8D6FF)

    var body: some View {
        let isPinned = appState.pinnedSkyTime != nil
        let paused = isPinned || !theme.motionEnabled || scenePhase != .active

        TimelineView(.animation(minimumInterval: isPinned ? 60 : (1.0 / 10.0), paused: paused)) { timeline in
            let now = appState.pinnedSkyTime ?? timeline.date
            let day = PrayerCalculator.today(place: appState.activePlace, settings: appState.settings.calculationSettings, now: now)
            let state = PrayerState.at(day: day, now: now)
            let skyMoment = SkyTimeline.at(now, prayers: day.entries)
            let skyColors = SkyPalette.tint(skyMoment.colors, accent: theme.scheme.primary)
            let displayed = state?.prayer ?? day.next ?? day[.fajr]
            let arc = SolarArc.at(now, prayers: day.entries, next: displayed)
            let moon = MoonPhase.at(now)
            let animT = isPinned ? 4.2 : timeline.date.timeIntervalSinceReferenceDate

            ScrollView {
                VStack(spacing: 0) {
                    dynamicPrayerArcCard(
                        now: now,
                        day: day,
                        state: state,
                        skyColors: skyColors,
                        twilight: skyMoment.twilight,
                        arc: arc,
                        moon: moon,
                        t: animT
                    )

                    Spacer().frame(height: 16)

                    locationSelectorPill

                    Spacer().frame(height: 20)

                    VStack(spacing: 12) {
                        ForEach(day.entries) { entry in
                            DetailPrayerRow(
                                entry: entry,
                                day: day,
                                now: now,
                                alertEnabled: appState.settings.prayerReminders[entry.type.lowercaseKey] ?? (entry.type != .sunrise),
                                onToggleAlert: { enabled in
                                    appState.updateSettings { snap in
                                        snap.prayerReminders[entry.type.lowercaseKey] = enabled
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
        }
        .background(SirajRootBackdrop(activePrayer: appState.prayerDay.next?.type))
        .navigationTitle(theme.t("nav_prayer"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func dynamicPrayerArcCard(
        now: Date,
        day: PrayerDay,
        state: PrayerState?,
        skyColors: SkyColors,
        twilight: SkyTwilight,
        arc: SolarArc,
        moon: MoonPhaseInfo,
        t: Double
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: 32, style: .continuous)
        let textLight = arc.isDaytime
            ? ArgbColor.lerp(skyColors.orbCore, skyColors.orbGlow, 0.55)
            : Self.moonlitText
        let countdownGradient = LinearGradient(
            stops: [
                .init(color: .white, location: 0.0),
                .init(color: .white, location: 0.45),
                .init(color: Color(argb: ArgbColor.lerp(.hex(0xFFFFFFFF), textLight, 0.55)), location: 1.0)
            ],
            startPoint: .top, endPoint: .bottom
        )

        return ZStack {
            CelestialArcCanvas(
                colors: skyColors,
                twilight: twilight,
                arc: arc,
                moon: moon,
                timeSeconds: t,
                motionEnabled: theme.motionEnabled,
                cornerRadius: 32
            )

            VStack(spacing: 6) {
                switch state {
                case .azanCalled:
                    HStack(spacing: 6) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(argbHex: 0xFFFFB74D))
                        Text(theme.t("azan_time_now"))
                            .font(theme.scaledFont(size: 16, weight: .black))
                            .foregroundStyle(Color(argbHex: 0xFFFFB74D))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color(argbHex: 0xFFE65100).opacity(0.38)))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color(argbHex: 0xFFFF9800).opacity(0.55), lineWidth: 1)
                    }

                case .waitingForIqama(_, _, let until, _):
                    let cd = TimeFormatter.formatCountdown(seconds: until, withHours: false, numeralSystem: theme.settings.numeralSystem, lang: theme.language)
                    RollingCountdownText(text: cd, fontSize: 38 * theme.textScale, weight: .black, gradient: countdownGradient, hasShadow: true)
                    Text(theme.t("time_until_iqama"))
                        .font(theme.scaledFont(size: 12, weight: .bold))
                        .foregroundStyle(Color(argbHex: 0xFFFFE082))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(argbHex: 0xFF3E2723).opacity(0.42)))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color(argbHex: 0xFFE5B558).opacity(0.55), lineWidth: 0.8)
                        }

                case .inPrayer:
                    Text(theme.t("prayer_in_progress"))
                        .font(theme.scaledFont(size: 16, weight: .black))
                        .foregroundStyle(Color(argbHex: 0xFF81C784))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color(argbHex: 0xFF1B5E20).opacity(0.38)))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(Color(argbHex: 0xFF81C784).opacity(0.55), lineWidth: 1)
                        }

                case .upcomingAzan(let prayer, let rem):
                    let cd = TimeFormatter.formatCountdown(seconds: rem, withHours: true, numeralSystem: theme.settings.numeralSystem, lang: theme.language)
                    let pName = prayerName(prayer, place: appState.activePlace)
                    RollingCountdownText(text: cd, fontSize: 38 * theme.textScale, weight: .black, gradient: countdownGradient, hasShadow: true)
                    Text(theme.tf("until_prayer_format", pName))
                        .font(theme.scaledFont(size: 12, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.95))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.black.opacity(0.35)))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.32), Color(argb: skyColors.cardBorderTop).opacity(0.40), .clear],
                                        startPoint: .top, endPoint: .bottom
                                    ),
                                    lineWidth: 0.8
                                )
                        }

                case nil:
                    EmptyView()
                }
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 276)
        .background(Color(argb: skyColors.cardBg))
        .clipShape(shape)
        .overlay {
            shape.strokeBorder(
                LinearGradient(
                    colors: [Color(argb: skyColors.cardBorderTop).opacity(0.65), Color(argb: skyColors.cardBorderBottom).opacity(0.35)],
                    startPoint: .top, endPoint: .bottom
                ),
                lineWidth: 1
            )
        }
    }

    private var locationSelectorPill: some View {
        let cityLabel = appState.activePlace.displayName(language: theme.language) ?? theme.t("detecting_location")
        return Button(action: onTapLocation) {
            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.primary)
                Text(cityLabel)
                    .font(theme.scaledFont(size: 14, weight: .bold))
                    .foregroundStyle(theme.onSurface)
                    .lineLimit(1)
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(theme.onSurfaceVariant)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .sirajCardSurface(cornerRadius: 24)
        }
        .buttonStyle(.plain)
    }

    private func prayerName(_ entry: PrayerTimeEntry, place: Place) -> String {
        if entry.type == .dhuhr && place.today(at: entry.time).weekdaySundayZero == 5 {
            return theme.t("prayer_jummah")
        }
        return theme.t(entry.type.stringKey)
    }
}

private struct DetailPrayerRow: View {
    @Environment(\.sirajTheme) private var theme
    let entry: PrayerTimeEntry
    let day: PrayerDay
    let now: Date
    let alertEnabled: Bool
    let onToggleAlert: (Bool) -> Void

    @State private var ringTrigger = false

    var body: some View {
        let isNext = entry.isNext
        let isPast = !isNext && entry.time < now
        let rowShape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        let badgeShape = RoundedRectangle(cornerRadius: 14, style: .continuous)

        let title: String = {
            if entry.type == .dhuhr && day.date.weekdaySundayZero == 5 {
                return theme.t("prayer_jummah")
            }
            return theme.t(entry.type.stringKey)
        }()
        let timeStr = TimeFormatter.formatTime(
            entry.time,
            timeZone: day.place.timeZone,
            hourFormat: theme.settings.hourFormat,
            numeralSystem: theme.settings.numeralSystem,
            lang: theme.language
        )

        let badgeFill: Color = {
            if isNext { return theme.primary }
            if isPast { return theme.surfaceVariant.opacity(theme.isDark ? 0.35 : 0.50) }
            return theme.surfaceVariant.opacity(theme.isDark ? 0.50 : 0.75)
        }()
        let iconTint: Color = {
            if isNext { return theme.onPrimary }
            if isPast { return theme.primary.opacity(0.80) }
            return theme.primary
        }()
        let nameColor: Color = {
            if isNext { return theme.primary }
            if isPast { return theme.onSurface.opacity(0.65) }
            return theme.onSurface
        }()
        let timeColor: Color = {
            if isNext { return theme.primary }
            if isPast { return theme.onSurfaceVariant.opacity(0.55) }
            return theme.onSurface
        }()

        HStack(spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    badgeShape.fill(badgeFill)
                    if isPast {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(iconTint)
                    } else {
                        Image(entry.type.iconAssetName)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .foregroundStyle(iconTint)
                    }
                }
                .frame(width: 44, height: 44)

                Text(title)
                    .font(theme.scaledFont(size: 16, weight: isNext ? .black : (isPast ? .medium : .bold)))
                    .foregroundStyle(nameColor)
                    .lineLimit(1)

                if isNext {
                    Text(theme.t("next_prayer_badge"))
                        .font(.system(size: 10.5 * theme.textScale, weight: .bold))
                        .foregroundStyle(theme.primary)
                        .lineLimit(1)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(theme.primary.opacity(theme.isDark ? 0.22 : 0.12)))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(theme.primary.opacity(0.45), lineWidth: 0.75)
                        }
                }
            }

            Spacer(minLength: 6)

            HStack(spacing: 4) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(timeStr)
                        .font(.system(size: 16.5 * theme.textScale, weight: isNext ? .black : (isPast ? .medium : .bold)))
                        .foregroundStyle(timeColor)
                        .lineLimit(1)
                    if let iqama = entry.iqama {
                        let iqStr = TimeFormatter.formatTime(
                            iqama,
                            timeZone: day.place.timeZone,
                            hourFormat: theme.settings.hourFormat,
                            numeralSystem: theme.settings.numeralSystem,
                            lang: theme.language
                        )
                        Text("\(theme.t("iqama")) \(iqStr)")
                            .font(.system(size: 11 * theme.textScale, weight: .medium))
                            .foregroundStyle(isNext ? theme.primary.opacity(0.85) : theme.onSurfaceVariant.opacity(0.60))
                            .lineLimit(1)
                    }
                }

                Button {
                    let next = !alertEnabled
                    if next && theme.motionEnabled { ringTrigger.toggle() }
                    if theme.settings.isHapticEnabled {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    onToggleAlert(next)
                } label: {
                    Image(systemName: alertEnabled ? "bell.badge" : "bell.slash")
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(alertEnabled ? theme.primary : theme.onSurfaceVariant.opacity(0.60))
                        .symbolEffect(.bounce, value: ringTrigger)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .padding(.vertical, 12)
        .background {
            if !theme.isGlass {
                rowShape.fill(
                    isNext
                        ? theme.primary.opacity(theme.isDark ? 0.16 : 0.09)
                        : (isPast ? theme.surface.opacity(theme.isDark ? 0.55 : 0.85) : theme.surface)
                )
            } else if isNext {
                rowShape.fill(theme.primary.opacity(theme.isDark ? 0.14 : 0.08))
            }
        }
        .sirajCardSurface(cornerRadius: 22)
        .overlay {
            if isNext {
                rowShape.strokeBorder(theme.primary.opacity(0.85), lineWidth: 1.5)
            }
        }
    }
}
