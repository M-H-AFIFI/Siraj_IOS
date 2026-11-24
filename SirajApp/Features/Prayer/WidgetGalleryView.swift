import SwiftUI
import SirajCore

struct WidgetGalleryView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState

    private let galleryFaces: [WidgetFace] =
        WidgetFace.prayerFaces + [.clock] + WidgetFace.hijriMoonFaces

    @State private var currentPage: Int = 0
    @State private var bgStyle: WidgetBackgroundStyle = .soft
    @State private var selectedPalette: String? = nil
    @State private var selectedClockStyle: ClockStyle = .classic

    var body: some View {
        let activePalette = selectedPalette ?? appState.settings.themePalette
        let previewSpec = SirajColorSchemeSpec.resolve(
            palette: activePalette,
            isDark: theme.isDark,
            isBlack: theme.isBlack
        )
        let face = galleryFaces[min(galleryFaces.count - 1, max(0, currentPage))]

        ScrollView {
            VStack(spacing: 16) {
                faceChipStrip

                TabView(selection: $currentPage) {
                    ForEach(Array(galleryFaces.enumerated()), id: \.element.id) { idx, pageFace in
                        widgetStage(for: pageFace, spec: previewSpec)
                            .padding(.horizontal, 20)
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 248)

                pageCounter(for: face)

                faceCaption(for: face)
                    .padding(.horizontal, 24)

                VStack(spacing: 14) {
                    styleControls(activePalette: activePalette, face: face)
                }
                .padding(18)
                .sirajCardSurface(cornerRadius: 26)
                .padding(.horizontal, 16)

                lockScreenPreviewCard
                    .padding(.horizontal, 16)

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "plus.square.on.square")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(theme.primary)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(theme.primary.opacity(0.12)))
                    Text(theme.t("ios_widget_gallery_hint"))
                        .font(theme.scaledFont(size: 13))
                        .foregroundStyle(theme.onSurfaceVariant)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .sirajCardSurface(cornerRadius: 18)
                .padding(.horizontal, 16)
            }
            .padding(.top, 10)
            .padding(.bottom, 108)
        }
        .scrollIndicators(.hidden)
        .background(Color.clear)
        .navigationTitle(theme.t("widget_settings_title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Top Face Chip Strip

    private var faceChipStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(galleryFaces.enumerated()), id: \.element.id) { idx, item in
                        let selected = idx == currentPage
                        Button {
                            if theme.motionEnabled {
                                withAnimation(.easeInOut(duration: 0.22)) { currentPage = idx }
                            } else {
                                currentPage = idx
                            }
                        } label: {
                            Text(theme.t(faceChipKey(item)))
                                .font(theme.scaledFont(size: 13, weight: .semibold))
                                .foregroundStyle(selected ? theme.onPrimary : theme.onSurface)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(selected ? theme.primary : theme.surfaceContainerHigh.opacity(0.7))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(selected ? .clear : theme.outlineVariant.opacity(0.45), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .id(idx)
                    }
                }
                .padding(.horizontal, 20)
            }
            .onChange(of: currentPage) { _, newPage in
                if theme.motionEnabled {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy.scrollTo(newPage, anchor: .center)
                    }
                } else {
                    proxy.scrollTo(newPage, anchor: .center)
                }
            }
        }
    }

    // MARK: - Live Wallpaper Stage

    private func widgetStage(for face: WidgetFace, spec: SirajColorSchemeSpec) -> some View {
        let stageShape = RoundedRectangle(cornerRadius: 28, style: .continuous)
        let cardShape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        let stageDark = theme.isDark

        return ZStack {
            LinearGradient(
                colors: stageDark
                    ? [Color(argbHex: 0xFF0E1726), Color(argbHex: 0xFF19283D), Color(argbHex: 0xFF101B2B)]
                    : [Color(argbHex: 0xFFDAE6F2), Color(argbHex: 0xFFEAF0F7), Color(argbHex: 0xFFDCE5EE)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(Color(argb: spec.primary).opacity(stageDark ? 0.26 : 0.20))
                .frame(width: 220, height: 220)
                .blur(radius: 36)
                .offset(x: -70, y: -50)
            Circle()
                .fill(Color(argb: spec.gold).opacity(stageDark ? 0.20 : 0.16))
                .frame(width: 180, height: 180)
                .blur(radius: 32)
                .offset(x: 80, y: 60)

            facePreview(face, spec: spec)
                .padding(16)
                .frame(maxWidth: face == .ring || face == .moon || face == .spot || face == .hijri || face == .month || face == .countdown ? 210 : 310)
                .background {
                    switch bgStyle {
                    case .soft:
                        cardShape.fill(
                            LinearGradient(
                                colors: [Color(argb: spec.surface), Color(argb: spec.surfaceContainerHigh)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    case .colour:
                        cardShape.fill(
                            LinearGradient(
                                colors: [Color(argb: spec.primary), Color(argb: spec.primary).opacity(0.84)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    case .tintedGlass:
                        cardShape.fill(.ultraThinMaterial)
                            .overlay(cardShape.fill(Color(argb: spec.primaryContainer).opacity(0.32)))
                    }
                }
                .overlay(cardShape.strokeBorder(Color(argb: spec.outlineVariant).opacity(0.55), lineWidth: 1))
                .shadow(color: Color.black.opacity(stageDark ? 0.42 : 0.14), radius: 14, x: 0, y: 8)
                .padding(18)
        }
        .clipShape(stageShape)
        .overlay(stageShape.strokeBorder(theme.outlineVariant.opacity(0.45), lineWidth: 1))
    }

    // MARK: - Page Counter & Caption

    private func pageCounter(for face: WidgetFace) -> some View {
        let canPrev = currentPage > 0
        let canNext = currentPage < galleryFaces.count - 1
        return HStack(spacing: 10) {
            Button {
                guard canPrev else { return }
                currentPage -= 1
            } label: {
                Image(systemName: theme.isRTL ? "chevron.right" : "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(theme.primary.opacity(canPrev ? 1 : 0.35))
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(theme.primary.opacity(canPrev ? 0.12 : 0.04)))
            }
            .buttonStyle(.plain)
            .disabled(!canPrev)

            HStack(spacing: 8) {
                Text(
                    theme.tf(
                        "widget_gallery_page",
                        theme.digits("\(currentPage + 1)"),
                        theme.digits("\(galleryFaces.count)")
                    )
                )
                .font(theme.scaledFont(size: 13.5, weight: .bold))
                .foregroundStyle(theme.primary)

                if face == .date {
                    Text(theme.t("widget_gallery_new"))
                        .font(theme.scaledFont(size: 10.5, weight: .black))
                        .foregroundStyle(theme.onPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(theme.primary))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Capsule().fill(theme.primary.opacity(0.10)))

            Button {
                guard canNext else { return }
                currentPage += 1
            } label: {
                Image(systemName: theme.isRTL ? "chevron.left" : "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(theme.primary.opacity(canNext ? 1 : 0.35))
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(theme.primary.opacity(canNext ? 0.12 : 0.04)))
            }
            .buttonStyle(.plain)
            .disabled(!canNext)
        }
    }

    private func faceCaption(for face: WidgetFace) -> some View {
        VStack(spacing: 5) {
            Text(faceTitle(face))
                .font(theme.scaledFont(size: 20, weight: .black))
                .foregroundStyle(theme.onSurface)
                .multilineTextAlignment(.center)

            Text(faceDesc(face))
                .font(theme.scaledFont(size: 13.5))
                .foregroundStyle(theme.onSurfaceVariant)
                .multilineTextAlignment(.center)

            HStack(spacing: 6) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 11.5, weight: .semibold))
                Text(theme.t("widget_gallery_resizable"))
                    .font(theme.scaledFont(size: 12, weight: .semibold))
            }
            .foregroundStyle(theme.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.primary.opacity(0.10)))
            .padding(.top, 5)
        }
    }

    // MARK: - Style Controls Card

    private func styleControls(activePalette: String, face: WidgetFace) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SirajSegmentedPills(options: WidgetBackgroundStyle.allCases, selection: $bgStyle) { style in
                switch style {
                case .soft: return theme.t("widget_background_soft")
                case .colour: return theme.t("widget_background_colour")
                case .tintedGlass: return theme.t("widget_background_glass")
                }
            }

            if face == .clock {
                VStack(alignment: .leading, spacing: 8) {
                    Text(theme.t("widget_style_clock"))
                        .font(theme.scaledFont(size: 13, weight: .bold))
                        .foregroundStyle(theme.onSurface)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ClockStyle.allCases) { style in
                                let active = selectedClockStyle == style
                                Button {
                                    selectedClockStyle = style
                                } label: {
                                    Text(clockTitle(style))
                                        .font(theme.scaledFont(size: 12, weight: active ? .bold : .medium))
                                        .foregroundStyle(active ? theme.onPrimary : theme.onSurface)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(Capsule().fill(active ? theme.primary : theme.surfaceVariant))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SirajPalettes.all) { pal in
                        let isSelected = SirajPalettes.canonicalId(activePalette) == pal.id
                        let roles = theme.isDark ? pal.dark : pal.light
                        Button {
                            selectedPalette = pal.id
                        } label: {
                            Circle()
                                .fill(Color(argbHex: roles.primary))
                                .frame(width: 32, height: 32)
                                .overlay {
                                    if isSelected {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(Color(argbHex: roles.onPrimary))
                                    }
                                }
                                .overlay {
                                    Circle().strokeBorder(isSelected ? theme.onSurface : theme.outlineVariant, lineWidth: isSelected ? 2 : 1)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Lock Screen Preview Card

    private var lockScreenPreviewCard: some View {
        let next = appState.prayerDay.next ?? appState.prayerDay[.fajr]
        let clock = formatTime(next.time)
        let rem = max(0, next.time.timeIntervalSince(appState.currentTime))
        let countdown = TimeFormatter.formatCountdown(seconds: rem, withHours: true, numeralSystem: appState.settings.numeralSystem, lang: theme.language)

        return VStack(alignment: .leading, spacing: 10) {
            Text(theme.t("ios_lockscreen_widget_title"))
                .font(theme.scaledFont(size: 15, weight: .bold))
                .foregroundStyle(theme.onSurface)
            Text(theme.t("ios_lockscreen_widget_desc"))
                .font(theme.scaledFont(size: 12.5))
                .foregroundStyle(theme.onSurfaceVariant)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Image(sunIconName(for: next.type))
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                        Text(theme.t(next.type.stringKey)).font(.system(size: 12.5, weight: .bold))
                        Spacer()
                        Text(clock).font(.system(size: 11.5)).opacity(0.8)
                    }
                    Text(countdown)
                        .font(.system(size: 18, weight: .heavy, design: .rounded).monospacedDigit())
                    Capsule().fill(.white.opacity(0.28)).frame(height: 4)
                        .overlay(alignment: .leading) {
                            Capsule().fill(.white).frame(width: 68, height: 4)
                        }
                }
                .foregroundStyle(.white)
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.black.opacity(0.76)))

                ZStack {
                    Circle().stroke(.white.opacity(0.25), lineWidth: 5)
                    Circle().trim(from: 0, to: 0.65).stroke(.white, style: StrokeStyle(lineWidth: 5, lineCap: .round)).rotationEffect(.degrees(-90))
                    VStack(spacing: 2) {
                        Image(sunIconName(for: next.type))
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 11, height: 11)
                        Text(clock).font(.system(size: 9.5, weight: .heavy)).minimumScaleFactor(0.6).lineLimit(1)
                    }
                    .foregroundStyle(.white)
                }
                .frame(width: 60, height: 60)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.black.opacity(0.76)))
            }
        }
        .padding(16)
        .sirajCardSurface(cornerRadius: 22)
    }

    // MARK: - Face Previews

    @ViewBuilder
    private func facePreview(_ face: WidgetFace, spec: SirajColorSchemeSpec) -> some View {
        let isFilled = bgStyle == .colour
        let fg = isFilled ? Color(argb: spec.onPrimary) : Color(argb: spec.onSurface)
        let sub = isFilled ? Color(argb: spec.onPrimary).opacity(0.76) : Color(argb: spec.onSurfaceVariant)
        let accent = isFilled ? Color(argb: spec.gold) : Color(argb: spec.primary)
        let next = appState.prayerDay.next ?? appState.prayerDay[.fajr]
        let prayers = appState.prayerDay.entries.filter { $0.type != .sunrise }
        let rem = max(0, next.time.timeIntervalSince(appState.currentTime))
        let countdown = TimeFormatter.formatCountdown(seconds: rem, withHours: true, numeralSystem: appState.settings.numeralSystem, lang: theme.language)
        let civil = appState.activePlace.today(at: appState.currentTime)
        let hijriLine = HijriFormatter.format(appState.hijriDate, lang: theme.language, numeralSystem: appState.settings.numeralSystem)
        let gregLine = HijriFormatter.formatGregorian(civil, lang: theme.language, numeralSystem: appState.settings.numeralSystem)
        let moon = MoonPhase.at(appState.currentTime)
        let sep = theme.isRTL ? "، " : " · "

        switch face {
        case .next:
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.t("next_prayer")).font(.system(size: 11, weight: .bold)).foregroundStyle(sub).textCase(.uppercase)
                    Text(theme.t(next.type.stringKey)).font(.system(size: 24, weight: .heavy)).foregroundStyle(fg)
                    Text(formatTime(next.time)).font(.system(size: 15, weight: .semibold)).foregroundStyle(accent)
                }
                Spacer()
                HStack(spacing: 6) {
                    Image("widget_timer")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(accent)
                    Text(countdown)
                        .font(.system(size: 19, weight: .heavy, design: .rounded).monospacedDigit())
                        .foregroundStyle(fg)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(accent.opacity(0.16)))
            }

        case .today, .day:
            VStack(alignment: .leading, spacing: 8) {
                if face == .day {
                    Text(hijriLine).font(.system(size: 13, weight: .bold)).foregroundStyle(accent)
                }
                HStack(spacing: 4) {
                    ForEach(prayers) { p in
                        VStack(spacing: 4) {
                            Image(sunIconName(for: p.type))
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                                .foregroundStyle(p.isNext ? accent : sub.opacity(0.8))
                            Text(theme.t(p.type.stringKey))
                                .font(.system(size: 10, weight: p.isNext ? .bold : .medium))
                                .foregroundStyle(p.isNext ? accent : sub)
                                .lineLimit(1)
                            Text(formatTime(p.time))
                                .font(.system(size: 11, weight: p.isNext ? .heavy : .semibold))
                                .foregroundStyle(fg)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(p.isNext ? accent.opacity(0.15) : .clear))
                    }
                }
            }

        case .list:
            VStack(spacing: 5) {
                ForEach(prayers) { p in
                    HStack(spacing: 7) {
                        Image(sunIconName(for: p.type))
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 13, height: 13)
                            .foregroundStyle(p.isNext ? accent : sub.opacity(0.7))
                        Text(theme.t(p.type.stringKey)).font(.system(size: 13, weight: p.isNext ? .bold : .medium)).foregroundStyle(p.isNext ? accent : fg)
                        Spacer()
                        Text(formatTime(p.time)).font(.system(size: 13, weight: p.isNext ? .heavy : .semibold)).foregroundStyle(p.isNext ? accent : fg)
                    }
                }
            }

        case .spot:
            VStack(spacing: 4) {
                Text(arabicPrayerName(next.type))
                    .font(.custom("Amiri-Regular", size: 38))
                    .foregroundStyle(accent)
                Text("\(formatTime(next.time))\(sep)\(countdown)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(fg)
            }

        case .ring:
            ZStack {
                Circle().stroke(accent.opacity(0.2), lineWidth: 9)
                Circle().trim(from: 0, to: 0.62).stroke(accent, style: StrokeStyle(lineWidth: 9, lineCap: .round)).rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text(theme.t(next.type.stringKey)).font(.system(size: 14, weight: .bold)).foregroundStyle(fg)
                    Text(formatTime(next.time)).font(.system(size: 12, weight: .semibold)).foregroundStyle(accent)
                    Text(countdown).font(.system(size: 11, weight: .bold, design: .rounded).monospacedDigit()).foregroundStyle(sub)
                }
            }
            .frame(width: 118, height: 118)

        case .dual:
            VStack(spacing: 10) {
                HStack {
                    Text(theme.t(appState.prayerDay.entries.first?.type.stringKey ?? "prayer_fajr")).font(.system(size: 13, weight: .semibold)).foregroundStyle(sub)
                    Spacer()
                    Text(theme.t(next.type.stringKey)).font(.system(size: 13, weight: .bold)).foregroundStyle(accent)
                }
                ProgressView(value: 0.58).tint(accent)
                HStack {
                    Text(formatTime(next.time)).font(.system(size: 13, weight: .semibold)).foregroundStyle(fg)
                    Spacer()
                    Text(countdown).font(.system(size: 14, weight: .bold, design: .rounded).monospacedDigit()).foregroundStyle(fg)
                }
            }

        case .clock:
            HStack(spacing: 16) {
                if selectedClockStyle.isDial {
                    galleryAnalogDial(style: selectedClockStyle, accent: accent, primary: fg)
                        .frame(width: 96, height: 96)
                } else {
                    Text(formatTime(appState.currentTime))
                        .font(clockFont(selectedClockStyle))
                        .foregroundStyle(fg)
                }
                Spacer(minLength: 6)
                VStack(alignment: .trailing, spacing: 4) {
                    Text(hijriLine).font(.system(size: 12, weight: .bold)).foregroundStyle(fg).lineLimit(1)
                    Text("\(theme.t(next.type.stringKey))\(sep)\(formatTime(next.time))")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(accent)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(accent.opacity(0.14)))
                }
            }

        case .hijri:
            VStack(alignment: .leading, spacing: 6) {
                Text(theme.t("widget_hijri_label")).font(.system(size: 10.5, weight: .bold)).foregroundStyle(sub).textCase(.uppercase)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(theme.digits("\(appState.hijriDate.day)"))
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(accent)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(HijriFormatter.monthName(appState.hijriDate.month, lang: theme.language))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(fg)
                        Text(gregLine).font(.system(size: 11.5)).foregroundStyle(sub).lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        case .month:
            VStack(spacing: 6) {
                Text(HijriFormatter.monthName(appState.hijriDate.month, lang: "ar"))
                    .font(.custom("Amiri-Regular", size: 36))
                    .foregroundStyle(accent)
                Image("widget_date_rule")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 9)
                    .foregroundStyle(accent.opacity(0.55))
                Text(hijriLine).font(.system(size: 12.5, weight: .bold)).foregroundStyle(fg)
            }

        case .date:
            let names = ["الأحد", "الإثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت"]
            let dayAr = names[((civil.weekdaySundayZero % 7) + 7) % 7]
            VStack(spacing: 6) {
                Text(dayAr).font(.custom("Amiri-Regular", size: 36)).foregroundStyle(accent)
                Image("widget_date_rule")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 9)
                    .foregroundStyle(accent.opacity(0.55))
                Text("\(hijriLine)\(sep)\(gregLine)").font(.system(size: 11.5, weight: .medium)).foregroundStyle(sub).lineLimit(1)
            }

        case .moon:
            VStack(spacing: 8) {
                MoonPhaseGlyph(phaseFraction: moon.phaseFraction, color: accent)
                    .frame(width: 58, height: 58)
                Text(theme.t(moon.name.stringKey)).font(.system(size: 14, weight: .bold)).foregroundStyle(fg)
                Text("\(theme.digits("\(Int((moon.illumination * 100).rounded()))%"))\(sep)\(hijriLine)")
                    .font(.system(size: 11.5))
                    .foregroundStyle(sub)
                    .lineLimit(1)
            }

        default:
            let occ = appState.upcomingOccasions.first
            VStack(alignment: .leading, spacing: 6) {
                Text(theme.t("widget_countdown_label")).font(.system(size: 10.5, weight: .bold)).foregroundStyle(sub).textCase(.uppercase)
                Text(occ?.occasion.title(language: theme.language) ?? "").font(.system(size: 16, weight: .bold)).foregroundStyle(fg)
                Text(theme.digits("\(occ?.daysUntil ?? 0)"))
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func galleryAnalogDial(style: ClockStyle, accent: Color, primary: Color) -> some View {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = appState.activePlace.timeZone
        let hour = Double(cal.component(.hour, from: appState.currentTime) % 12)
        let minute = Double(cal.component(.minute, from: appState.currentTime))
        let hourDeg = ((hour + minute / 60.0) / 12.0) * 360.0
        let minuteDeg = (minute / 60.0) * 360.0
        let prefix = style == .ink ? "widget_ink" : (style == .star ? "widget_star" : "widget_analog")

        return ZStack {
            Image("\(prefix)_dial_dark").renderingMode(.template).resizable().scaledToFit().foregroundStyle(accent.opacity(0.85))
            Image("\(prefix)_hour_dark").renderingMode(.template).resizable().scaledToFit().foregroundStyle(primary).rotationEffect(.degrees(hourDeg))
            Image("\(prefix)_minute_dark").renderingMode(.template).resizable().scaledToFit().foregroundStyle(accent).rotationEffect(.degrees(minuteDeg))
        }
    }

    private func sunIconName(for type: PrayerType) -> String {
        switch type {
        case .fajr: return "widget_sun_fajr"
        case .sunrise: return "widget_sun_sunrise"
        case .dhuhr: return "widget_sun_dhuhr"
        case .asr: return "widget_sun_asr"
        case .maghrib: return "widget_sun_maghrib"
        case .isha: return "widget_sun_isha"
        }
    }

    private func formatTime(_ date: Date) -> String {
        TimeFormatter.formatTime(
            date,
            timeZone: appState.activePlace.timeZone,
            hourFormat: appState.settings.hourFormat,
            numeralSystem: appState.settings.numeralSystem,
            lang: theme.language
        )
    }

    private func clockFont(_ style: ClockStyle) -> Font {
        switch style {
        case .classic: return .system(size: 30, weight: .semibold)
        case .bold: return .system(size: 32, weight: .black, design: .rounded)
        case .serif: return .system(size: 30, weight: .semibold, design: .serif)
        case .condensed: return .system(size: 32, weight: .bold).width(.condensed)
        case .handwritten: return .system(size: 30, weight: .medium, design: .serif).italic()
        case .marker: return .system(size: 32, weight: .heavy, design: .rounded)
        default: return .system(size: 30, weight: .semibold)
        }
    }

    private func arabicPrayerName(_ type: PrayerType) -> String {
        switch type {
        case .fajr: return "الفجر"
        case .sunrise: return "الشروق"
        case .dhuhr: return "الظهر"
        case .asr: return "العصر"
        case .maghrib: return "المغرب"
        case .isha: return "العشاء"
        }
    }

    private func faceChipKey(_ face: WidgetFace) -> String {
        switch face {
        case .next: return "widget_face_next"
        case .today: return "widget_face_today"
        case .list: return "widget_face_list"
        case .clock: return "widget_face_clock"
        case .spot: return "widget_face_spot"
        case .ring: return "widget_face_ring"
        case .dual: return "widget_face_dual"
        case .day: return "widget_face_day"
        case .hijri: return "widget_face_hijri"
        case .month: return "widget_face_month"
        case .date: return "widget_face_date"
        case .moon: return "widget_face_moon"
        case .countdown: return "widget_face_countdown"
        default: return "widget_face_next"
        }
    }

    private func faceTitle(_ face: WidgetFace) -> String {
        switch face {
        case .next: return theme.t("widget_next_name")
        case .today: return theme.t("widget_today_name")
        case .list: return theme.t("widget_list_name")
        case .clock: return theme.t("widget_clock_name")
        case .spot: return theme.t("widget_spot_name")
        case .ring: return theme.t("widget_ring_name")
        case .dual: return theme.t("widget_dual_name")
        case .day: return theme.t("widget_day_name")
        case .hijri: return theme.t("widget_hijri_name")
        case .month: return theme.t("widget_month_name")
        case .date: return theme.t("widget_date_name")
        case .moon: return theme.t("widget_moon_name")
        case .countdown: return theme.t("widget_countdown_name")
        default: return face.rawValue
        }
    }

    private func faceDesc(_ face: WidgetFace) -> String {
        switch face {
        case .next: return theme.t("widget_next_description")
        case .today: return theme.t("widget_today_description")
        case .list: return theme.t("widget_list_description")
        case .clock: return theme.t("widget_clock_description")
        case .spot: return theme.t("widget_spot_description")
        case .ring: return theme.t("widget_ring_description")
        case .dual: return theme.t("widget_dual_description")
        case .day: return theme.t("widget_day_description")
        case .hijri: return theme.t("widget_hijri_description")
        case .month: return theme.t("widget_month_description")
        case .date: return theme.t("widget_date_description")
        case .moon: return theme.t("widget_moon_description")
        case .countdown: return theme.t("widget_countdown_description")
        default: return ""
        }
    }

    private func clockTitle(_ style: ClockStyle) -> String {
        switch style {
        case .classic: return theme.t("widget_clock_classic")
        case .bold: return theme.t("widget_clock_bold")
        case .serif: return theme.t("widget_clock_serif")
        case .condensed: return theme.t("widget_clock_condensed")
        case .handwritten: return theme.t("widget_clock_handwritten")
        case .marker: return theme.t("widget_clock_marker")
        case .analog: return theme.t("widget_clock_analog")
        case .ink: return theme.t("widget_clock_ink")
        case .star: return theme.t("widget_clock_star")
        }
    }
}
