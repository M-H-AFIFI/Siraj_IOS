import SwiftUI
import SirajCore

private enum WidgetGalleryCategory: String, CaseIterable, Identifiable {
    case prayer
    case clock
    case hijri

    var id: String { rawValue }
}

struct WidgetGalleryView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState

    @State private var category: WidgetGalleryCategory = .prayer
    @State private var bgStyle: WidgetBackgroundStyle = .soft
    @State private var selectedPalette: String? = nil

    var body: some View {
        let activePalette = selectedPalette ?? appState.settings.themePalette
        let previewSpec = SirajColorSchemeSpec.resolve(
            palette: activePalette,
            isDark: theme.isDark,
            isBlack: theme.isBlack
        )

        ScrollView {
            VStack(spacing: 18) {
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

                styleControls(activePalette: activePalette)

                SirajSegmentedPills(options: WidgetGalleryCategory.allCases, selection: $category) { cat in
                    switch cat {
                    case .prayer: return theme.t("ios_widget_category_prayer")
                    case .clock: return theme.t("ios_widget_category_clock")
                    case .hijri: return theme.t("ios_widget_category_hijri")
                    }
                }

                switch category {
                case .prayer:
                    lockScreenPreviewCard
                    ForEach(WidgetFace.milestone1PrayerFaces) { face in
                        widgetPreviewWrapper(title: faceTitle(face), subtitle: faceDesc(face), spec: previewSpec) {
                            prayerFacePreview(face, spec: previewSpec)
                        }
                    }
                case .clock:
                    ForEach(ClockStyle.allCases) { clockStyle in
                        widgetPreviewWrapper(title: clockTitle(clockStyle), subtitle: theme.t("widget_clock_description"), spec: previewSpec) {
                            clockPreview(clockStyle, spec: previewSpec)
                        }
                    }
                case .hijri:
                    ForEach(WidgetFace.milestone1HijriMoonFaces) { face in
                        widgetPreviewWrapper(title: faceTitle(face), subtitle: faceDesc(face), spec: previewSpec) {
                            hijriFacePreview(face, spec: previewSpec)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 108)
        }
        .background(Color.clear)
        .navigationTitle(theme.t("widget_settings_title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func styleControls(activePalette: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SirajSegmentedPills(options: WidgetBackgroundStyle.allCases, selection: $bgStyle) { style in
                switch style {
                case .soft: return theme.t("widget_background_soft")
                case .colour: return theme.t("widget_background_colour")
                case .tintedGlass: return theme.t("widget_background_glass")
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
                                .frame(width: 30, height: 30)
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
        .padding(14)
        .sirajCardSurface(cornerRadius: 20)
    }

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
                        Image(systemName: "sun.horizon.fill").font(.system(size: 11))
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
                    VStack(spacing: 1) {
                        Text(String(theme.t(next.type.stringKey).prefix(3))).font(.system(size: 9, weight: .bold))
                        Text(clock).font(.system(size: 9.5, weight: .heavy)).minimumScaleFactor(0.7).lineLimit(1)
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

    private func widgetPreviewWrapper<Content: View>(
        title: String,
        subtitle: String,
        spec: SirajColorSchemeSpec,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        return VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(theme.scaledFont(size: 15, weight: .bold))
                    .foregroundStyle(theme.onSurface)
                Text(subtitle)
                    .font(theme.scaledFont(size: 12))
                    .foregroundStyle(theme.onSurfaceVariant)
            }

            content()
                .padding(16)
                .frame(maxWidth: .infinity)
                .background {
                    switch bgStyle {
                    case .soft:
                        shape.fill(LinearGradient(colors: [Color(argb: spec.surface), Color(argb: spec.surfaceContainerHigh)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    case .colour:
                        shape.fill(LinearGradient(colors: [Color(argb: spec.primary), Color(argb: spec.primary).opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    case .tintedGlass:
                        shape.fill(.ultraThinMaterial)
                            .overlay(shape.fill(Color(argb: spec.primaryContainer).opacity(0.32)))
                    }
                }
                .overlay {
                    shape.strokeBorder(Color(argb: spec.outlineVariant).opacity(0.6), lineWidth: 1)
                }
        }
        .padding(16)
        .sirajCardSurface(cornerRadius: 24)
    }

    @ViewBuilder
    private func prayerFacePreview(_ face: WidgetFace, spec: SirajColorSchemeSpec) -> some View {
        let isFilled = bgStyle == .colour
        let fg = isFilled ? Color(argb: spec.onPrimary) : Color(argb: spec.onSurface)
        let sub = isFilled ? Color(argb: spec.onPrimary).opacity(0.76) : Color(argb: spec.onSurfaceVariant)
        let accent = isFilled ? Color(argb: spec.gold) : Color(argb: spec.primary)
        let next = appState.prayerDay.next ?? appState.prayerDay[.fajr]
        let prayers = appState.prayerDay.entries.filter { $0.type != .sunrise }
        let rem = max(0, next.time.timeIntervalSince(appState.currentTime))
        let countdown = TimeFormatter.formatCountdown(seconds: rem, withHours: true, numeralSystem: appState.settings.numeralSystem, lang: theme.language)

        switch face {
        case .next:
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.t("next_prayer")).font(.system(size: 11, weight: .bold)).foregroundStyle(sub).textCase(.uppercase)
                    Text(theme.t(next.type.stringKey)).font(.system(size: 24, weight: .heavy)).foregroundStyle(fg)
                    Text(formatTime(next.time)).font(.system(size: 15, weight: .semibold)).foregroundStyle(accent)
                }
                Spacer()
                Text(countdown)
                    .font(.system(size: 22, weight: .heavy, design: .rounded).monospacedDigit())
                    .foregroundStyle(fg)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(accent.opacity(0.16)))
            }

        case .today, .day:
            VStack(alignment: .leading, spacing: 8) {
                if face == .day {
                    Text(HijriFormatter.format(appState.hijriDate, lang: theme.language, numeralSystem: appState.settings.numeralSystem))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(accent)
                }
                HStack(spacing: 4) {
                    ForEach(prayers) { p in
                        VStack(spacing: 4) {
                            Text(theme.t(p.type.stringKey))
                                .font(.system(size: 10.5, weight: p.isNext ? .bold : .medium))
                                .foregroundStyle(p.isNext ? accent : sub)
                                .lineLimit(1)
                            Text(formatTime(p.time))
                                .font(.system(size: 11, weight: p.isNext ? .heavy : .semibold))
                                .foregroundStyle(fg)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(p.isNext ? accent.opacity(0.15) : .clear))
                    }
                }
            }

        case .list:
            VStack(spacing: 6) {
                ForEach(prayers) { p in
                    HStack {
                        Circle().fill(p.isNext ? accent : sub.opacity(0.4)).frame(width: 6, height: 6)
                        Text(theme.t(p.type.stringKey)).font(.system(size: 13, weight: p.isNext ? .bold : .medium)).foregroundStyle(p.isNext ? accent : fg)
                        Spacer()
                        Text(formatTime(p.time)).font(.system(size: 13, weight: p.isNext ? .heavy : .semibold)).foregroundStyle(p.isNext ? accent : fg)
                    }
                }
            }

        case .spot:
            VStack(spacing: 4) {
                Text(arabicPrayerName(next.type))
                    .font(theme.amiriFont(size: 32))
                    .foregroundStyle(accent)
                Text("\(formatTime(next.time)) · \(countdown)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(fg)
            }

        case .ring:
            HStack(spacing: 16) {
                ZStack {
                    Circle().stroke(accent.opacity(0.2), lineWidth: 8)
                    Circle().trim(from: 0, to: 0.62).stroke(accent, style: StrokeStyle(lineWidth: 8, lineCap: .round)).rotationEffect(.degrees(-90))
                    Text(theme.t(next.type.stringKey)).font(.system(size: 12, weight: .bold)).foregroundStyle(fg)
                }
                .frame(width: 72, height: 72)
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatTime(next.time)).font(.system(size: 18, weight: .bold)).foregroundStyle(accent)
                    Text(countdown).font(.system(size: 16, weight: .bold, design: .rounded).monospacedDigit()).foregroundStyle(fg)
                }
                Spacer()
            }

        default:
            VStack(spacing: 8) {
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
        }
    }

    private func clockPreview(_ style: ClockStyle, spec: SirajColorSchemeSpec) -> some View {
        let isFilled = bgStyle == .colour
        let fg = isFilled ? Color(argb: spec.onPrimary) : Color(argb: spec.onSurface)
        let sub = isFilled ? Color(argb: spec.onPrimary).opacity(0.76) : Color(argb: spec.onSurfaceVariant)
        let accent = isFilled ? Color(argb: spec.gold) : Color(argb: spec.primary)
        let next = appState.prayerDay.next ?? appState.prayerDay[.fajr]
        let clockStr = formatTime(appState.currentTime)

        return HStack(spacing: 16) {
            if style.isDial {
                ZStack {
                    Circle().stroke(accent.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: style == .ink ? [4, 2] : []))
                    Image(systemName: style == .star ? "star.circle" : "clock")
                        .font(.system(size: 28))
                        .foregroundStyle(accent)
                }
                .frame(width: 60, height: 60)
            } else {
                Text(clockStr)
                    .font(clockFont(style))
                    .foregroundStyle(fg)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(HijriFormatter.format(appState.hijriDate, lang: theme.language, numeralSystem: appState.settings.numeralSystem))
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(sub)
                Text("\(theme.t(next.type.stringKey)) · \(formatTime(next.time))")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundStyle(accent)
            }
        }
    }

    @ViewBuilder
    private func hijriFacePreview(_ face: WidgetFace, spec: SirajColorSchemeSpec) -> some View {
        let isFilled = bgStyle == .colour
        let fg = isFilled ? Color(argb: spec.onPrimary) : Color(argb: spec.onSurface)
        let sub = isFilled ? Color(argb: spec.onPrimary).opacity(0.76) : Color(argb: spec.onSurfaceVariant)
        let accent = isFilled ? Color(argb: spec.gold) : Color(argb: spec.primary)
        let civil = appState.activePlace.today(at: appState.currentTime)
        let hijriLine = HijriFormatter.format(appState.hijriDate, lang: theme.language, numeralSystem: appState.settings.numeralSystem)
        let gregLine = HijriFormatter.formatGregorian(civil, lang: theme.language, numeralSystem: appState.settings.numeralSystem)
        let moon = MoonPhase.at(appState.currentTime)

        switch face {
        case .hijri:
            HStack {
                Text(theme.digits("\(appState.hijriDate.day)"))
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(HijriFormatter.monthName(appState.hijriDate.month, lang: theme.language))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(fg)
                    Text(gregLine)
                        .font(.system(size: 12))
                        .foregroundStyle(sub)
                }
                Spacer()
            }

        case .month:
            VStack(spacing: 4) {
                Text(HijriFormatter.monthName(appState.hijriDate.month, lang: "ar"))
                    .font(theme.amiriFont(size: 30))
                    .foregroundStyle(accent)
                Text(hijriLine).font(.system(size: 12.5, weight: .semibold)).foregroundStyle(fg)
            }

        case .date:
            let names = ["الأحد", "الإثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت"]
            let dayAr = names[((civil.weekdaySundayZero % 7) + 7) % 7]
            VStack(spacing: 4) {
                Text(dayAr).font(theme.amiriFont(size: 30)).foregroundStyle(accent)
                Text("\(hijriLine) · \(gregLine)").font(.system(size: 11.5)).foregroundStyle(sub).lineLimit(1)
            }

        case .moon:
            HStack(spacing: 14) {
                Image("ic_siraj_full_moon")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .foregroundStyle(accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(moon.name.rawValue).font(.system(size: 15, weight: .bold)).foregroundStyle(fg)
                    Text("\(theme.digits("\(Int((moon.illumination * 100).rounded()))%")) · \(hijriLine)")
                        .font(.system(size: 12))
                        .foregroundStyle(sub)
                }
                Spacer()
            }

        default:
            let occ = appState.upcomingOccasions.first
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(theme.t("widget_countdown_label")).font(.system(size: 11, weight: .bold)).foregroundStyle(sub).textCase(.uppercase)
                    Text(occ?.occasion.title(language: theme.language) ?? "").font(.system(size: 16, weight: .bold)).foregroundStyle(fg)
                }
                Spacer()
                Text(theme.digits("\(occ?.daysUntil ?? 0)"))
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(accent)
            }
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
        case .classic: return .system(size: 28, weight: .semibold)
        case .bold: return .system(size: 30, weight: .black, design: .rounded)
        case .serif: return .system(size: 28, weight: .semibold, design: .serif)
        case .condensed: return .system(size: 30, weight: .bold).width(.condensed)
        case .handwritten: return .system(size: 28, weight: .medium, design: .serif).italic()
        case .marker: return .system(size: 30, weight: .heavy, design: .rounded)
        default: return .system(size: 28, weight: .semibold)
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

    private func faceTitle(_ face: WidgetFace) -> String {
        switch face {
        case .next: return theme.t("widget_next_name")
        case .today: return theme.t("widget_today_name")
        case .list: return theme.t("widget_list_name")
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
