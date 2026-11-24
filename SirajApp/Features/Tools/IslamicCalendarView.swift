import SwiftUI
import UIKit
import SirajCore

private enum CalendarTabOption: String, CaseIterable, Identifiable, Hashable {
    case monthly
    case events

    var id: String { rawValue }
}

private struct HijriYearMonth: Equatable {
    var year: Int
    var month: Int

    var index: Int { year * 12 + (month - 1) }

    func adding(months delta: Int) -> HijriYearMonth {
        let total = index + delta
        let y = total / 12
        let m = total % 12 + 1
        if y < 1301 { return HijriYearMonth(year: 1301, month: 1) }
        if y > 1599 { return HijriYearMonth(year: 1599, month: 12) }
        return HijriYearMonth(year: y, month: m)
    }
}

struct IslamicCalendarView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState

    @State private var activeTab: CalendarTabOption = .monthly
    @State private var displayedMonth: HijriYearMonth
    @State private var selectedDate: CivilDate
    @State private var sheetOccasion: DatedOccasion?
    @State private var showHijriSourceSheet = false

    init(appState: AppState) {
        self.appState = appState
        let todayCivil = appState.activePlace.today(at: appState.currentTime)
        let hijri = appState.hijriCalendar.toHijri(todayCivil)
        self._displayedMonth = State(initialValue: HijriYearMonth(year: hijri.year, month: hijri.month))
        self._selectedDate = State(initialValue: todayCivil)
    }

    private var calendar: SirajHijriCalendar { appState.hijriCalendar }
    private var todayCivil: CivilDate { appState.activePlace.today(at: appState.currentTime) }
    private var todayHijri: HijriDate { calendar.toHijri(todayCivil) }
    private var todayYearMonth: HijriYearMonth { HijriYearMonth(year: todayHijri.year, month: todayHijri.month) }

    var body: some View {
        let upcoming = IslamicOccasions.upcoming(from: todayCivil, calendar: calendar)

        ScrollView {
            VStack(spacing: 16) {
                SirajSegmentedPills(
                    options: CalendarTabOption.allCases,
                    selection: $activeTab
                ) { tab in
                    theme.t(tab == .monthly ? "calendar_monthly_tab" : "calendar_events_tab")
                }

                if activeTab == .monthly {
                    todayHeroCard
                    if let next = upcoming.first {
                        nextOccasionCard(next)
                    }
                    monthCalendarCard
                    selectedDayDetailCard
                } else {
                    eventsListSection(upcoming: upcoming)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 124)
        }
        .scrollIndicators(.hidden)
        .background(Color.clear)
        .navigationTitle(theme.t("calendar_title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $sheetOccasion) { dated in
            OccasionDetailSheet(dated: dated, todayCivil: todayCivil)
        }
        .sheet(isPresented: $showHijriSourceSheet) {
            HijriDateSheetView(appState: appState)
        }
    }

    // MARK: - Today Hero & Astronomical Moon Disc

    private var todayHeroCard: some View {
        let moon = MoonPhase.at(appState.currentTime)
        let litPct = Int((moon.illumination * 100).rounded())
        let gregorianText = HijriFormatter.formatGregorian(
            todayCivil,
            lang: theme.language,
            numeralSystem: appState.settings.numeralSystem
        )

        return VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.t("calendar_today_title"))
                        .font(theme.scaledFont(size: 11, weight: .bold))
                        .foregroundStyle(theme.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(theme.primary.opacity(0.12)))
                        .overlay(Capsule().strokeBorder(theme.primary.opacity(0.30), lineWidth: 0.8))

                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(theme.digits(String(todayHijri.day)))
                            .font(theme.scaledFont(size: 42, weight: .black))
                            .foregroundStyle(theme.primary)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(HijriFormatter.monthName(todayHijri.month, lang: theme.language))
                                .font(theme.scaledFont(size: 20, weight: .black))
                                .foregroundStyle(theme.onSurface)
                                .lineLimit(1)
                            Text(HijriFormatter.yearString(todayHijri.year, lang: theme.language, numeralSystem: appState.settings.numeralSystem))
                                .font(theme.scaledFont(size: 13.5, weight: .bold))
                                .foregroundStyle(theme.onSurfaceVariant)
                        }
                    }

                    Text(gregorianText)
                        .font(theme.scaledFont(size: 13))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .lineLimit(1)
                        .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 6) {
                    AstronomicalMoonDisc(phaseFraction: moon.phaseFraction)
                        .frame(width: 72, height: 72)

                    Text(theme.t(moon.name.stringKey))
                        .font(theme.scaledFont(size: 11, weight: .bold))
                        .foregroundStyle(theme.onSurface)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Text(theme.t("moon_lit", theme.digits(String(litPct))))
                        .font(theme.scaledFont(size: 10.5))
                        .foregroundStyle(theme.outline)
                }
                .frame(width: 96)
            }

            Divider().opacity(0.45)

            Button {
                showHijriSourceSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(theme.primary)
                    Text(theme.t("calendar_source_change"))
                        .font(theme.scaledFont(size: 12.5, weight: .semibold))
                        .foregroundStyle(theme.primary)
                    Spacer()
                    Image(systemName: theme.isRTL ? "chevron.left" : "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(theme.outline)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .sirajCardSurface(cornerRadius: 26, isElevated: true)
    }

    // MARK: - Next Occasion Card

    private func nextOccasionCard(_ dated: DatedOccasion) -> some View {
        Button {
            sheetOccasion = dated
        } label: {
            HStack(spacing: 12) {
                IslamicOccasionBadge(occasionId: dated.occasion.id, size: 46, highlighted: dated.isToday)

                VStack(alignment: .leading, spacing: 3) {
                    Text(theme.t("calendar_next_occasion"))
                        .font(theme.scaledFont(size: 11, weight: .bold))
                        .foregroundStyle(theme.primary)
                    Text(dated.occasion.title(language: theme.language))
                        .font(theme.scaledFont(size: 15.5, weight: .black))
                        .foregroundStyle(theme.onSurface)
                        .lineLimit(1)
                    Text(HijriFormatter.formatGregorianCompact(dated.date, lang: theme.language, numeralSystem: appState.settings.numeralSystem))
                        .font(theme.scaledFont(size: 12))
                        .foregroundStyle(theme.onSurfaceVariant)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                countdownChip(daysUntil: dated.daysUntil)
            }
            .padding(14)
            .sirajCardSurface(cornerRadius: 22)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Monthly Hijri Grid

    private var monthCalendarCard: some View {
        let monthLength = calendar.lengthOfMonth(year: displayedMonth.year, month: displayedMonth.month)
        let firstCivil = calendar.firstDayOf(year: displayedMonth.year, month: displayedMonth.month)
        let lastCivil = firstCivil.addingDays(monthLength - 1)
        let leadingEmpty = FastingPlanner.weekdaySun0(firstCivil)
        let totalSlots = leadingEmpty + monthLength
        let trailingEmpty = (7 - (totalSlots % 7)) % 7
        let cellCount = totalSlots + trailingEmpty
        let isCurrentMonth = displayedMonth == todayYearMonth

        return VStack(spacing: 14) {
            // Month header with Arabic watermark
            ZStack {
                Text(HijriFormatter.monthName(displayedMonth.month, lang: "ar"))
                    .font(theme.amiriFont(size: 40))
                    .foregroundStyle(theme.primary.opacity(theme.isDark ? 0.12 : 0.08))
                    .lineLimit(1)

                HStack {
                    Button {
                        shiftMonth(-1)
                    } label: {
                        Image(systemName: theme.isRTL ? "chevron.right" : "chevron.left")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(theme.primary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(theme.primary.opacity(0.10)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(theme.t("calendar_prev_month"))

                    Spacer()

                    VStack(spacing: 2) {
                        Text("\(HijriFormatter.monthName(displayedMonth.month, lang: theme.language)) \(HijriFormatter.yearString(displayedMonth.year, lang: theme.language, numeralSystem: appState.settings.numeralSystem))")
                            .font(theme.scaledFont(size: 16.5, weight: .black))
                            .foregroundStyle(theme.onSurface)
                        Text(gregorianSpanText(start: firstCivil, end: lastCivil))
                            .font(theme.scaledFont(size: 11.5))
                            .foregroundStyle(theme.onSurfaceVariant)
                    }

                    Spacer()

                    Button {
                        shiftMonth(1)
                    } label: {
                        Image(systemName: theme.isRTL ? "chevron.left" : "chevron.right")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(theme.primary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(theme.primary.opacity(0.10)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(theme.t("calendar_next_month"))
                }
            }

            if !isCurrentMonth {
                Button {
                    withAnimation(theme.motionEnabled ? .easeInOut(duration: 0.2) : nil) {
                        displayedMonth = todayYearMonth
                        selectedDate = todayCivil
                    }
                } label: {
                    Text(theme.t("calendar_back_to_today"))
                        .font(theme.scaledFont(size: 12, weight: .bold))
                        .foregroundStyle(theme.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(theme.primary.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }

            // Weekday labels (Sun .. Sat, Friday in gold)
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { dow in
                    Text(shortWeekday(dow))
                        .font(theme.scaledFont(size: 11.5, weight: .bold))
                        .foregroundStyle(dow == 5 ? theme.gold : theme.outline)
                        .frame(maxWidth: .infinity)
                }
            }

            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(0..<cellCount, id: \.self) { slot in
                    let hDay = slot - leadingEmpty + 1
                    if hDay >= 1 && hDay <= monthLength {
                        let civil = firstCivil.addingDays(hDay - 1)
                        dayCell(hDay: hDay, civil: civil)
                    } else {
                        Color.clear.frame(height: 46)
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 36)
                    .onEnded { value in
                        let dx = value.translation.width
                        guard abs(dx) > abs(value.translation.height) else { return }
                        let step = (dx < 0) ? (theme.isRTL ? -1 : 1) : (theme.isRTL ? 1 : -1)
                        shiftMonth(step)
                    }
            )

            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(theme.primary.opacity(0.28))
                        .frame(width: 8, height: 8)
                    Text(theme.t("calendar_legend_white_days"))
                        .font(theme.scaledFont(size: 11))
                        .foregroundStyle(theme.onSurfaceVariant)
                }
                HStack(spacing: 6) {
                    Capsule()
                        .fill(theme.gold)
                        .frame(width: 14, height: 4)
                    Text(theme.t("calendar_legend_occasion"))
                        .font(theme.scaledFont(size: 11))
                        .foregroundStyle(theme.onSurfaceVariant)
                }
                Spacer()
            }
            .padding(.top, 2)
        }
        .padding(16)
        .sirajCardSurface(cornerRadius: 24)
    }

    private func dayCell(hDay: Int, civil: CivilDate) -> some View {
        let isToday = civil == todayCivil
        let isSelected = civil == selectedDate
        let isFriday = FastingPlanner.weekdaySun0(civil) == 5
        let isWhite = IslamicOccasions.isWhiteDay(month: displayedMonth.month, day: hDay)
        let hasOccasion = IslamicOccasions.on(month: displayedMonth.month, day: hDay) != nil
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)

        return Button {
            if appState.settings.isHapticEnabled {
                UISelectionFeedbackGenerator().selectionChanged()
            }
            selectedDate = civil
        } label: {
            VStack(spacing: 1) {
                Text(theme.digits(String(hDay)))
                    .font(theme.scaledFont(size: 14.5, weight: (isToday || isSelected) ? .black : .bold))
                    .foregroundStyle(
                        isSelected ? theme.onPrimary : (isFriday ? theme.gold : theme.onSurface)
                    )
                Text(theme.digits(String(civil.day)))
                    .font(theme.scaledFont(size: 10))
                    .foregroundStyle(
                        isSelected ? theme.onPrimary.opacity(0.85) : theme.outline
                    )
                if hasOccasion {
                    Capsule()
                        .fill(isSelected ? theme.onPrimary : theme.gold)
                        .frame(width: 16, height: 3)
                        .padding(.top, 1)
                } else {
                    Color.clear.frame(height: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background {
                if isSelected {
                    shape.fill(theme.primary)
                } else if isWhite {
                    shape.fill(theme.primary.opacity(theme.isDark ? 0.16 : 0.09))
                } else {
                    shape.fill(Color.clear)
                }
            }
            .overlay {
                if isToday && !isSelected {
                    shape.strokeBorder(theme.primary, lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Selected Day Details

    private var selectedDayDetailCard: some View {
        let h = calendar.toHijri(selectedDate)
        let delta = selectedDate.dayNumber - todayCivil.dayNumber
        let dow = FastingPlanner.weekdaySun0(selectedDate)
        let isFriday = dow == 5
        let isWhite = IslamicOccasions.isWhiteDay(month: h.month, day: h.day)
        let isSunnahMonThu = (dow == 1 || dow == 4) && h.month != 9 && !IslamicOccasions.isFastingForbidden(month: h.month, day: h.day)
        let occasion = IslamicOccasions.on(month: h.month, day: h.day)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(HijriFormatter.format(h, lang: theme.language, numeralSystem: appState.settings.numeralSystem))
                        .font(theme.scaledFont(size: 17, weight: .black))
                        .foregroundStyle(theme.onSurface)
                    Text(HijriFormatter.formatGregorian(selectedDate, lang: theme.language, numeralSystem: appState.settings.numeralSystem))
                        .font(theme.scaledFont(size: 13))
                        .foregroundStyle(theme.onSurfaceVariant)
                }
                Spacer(minLength: 8)
                relativeDayChip(delta: delta)
            }

            if isFriday || isWhite || isSunnahMonThu {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if isFriday {
                            dayBadge(theme.t("calendar_badge_jumuah"), color: theme.gold)
                        }
                        if isWhite {
                            dayBadge(theme.t("calendar_white_days_badge"), color: theme.primary)
                        }
                        if isSunnahMonThu {
                            dayBadge(theme.t("calendar_sunnah_fast_badge"), color: theme.primary)
                        }
                    }
                }
            }

            if let occasion {
                let dated = DatedOccasion(occasion: occasion, date: selectedDate, hijriYear: h.year, daysUntil: delta)
                Button {
                    sheetOccasion = dated
                } label: {
                    HStack(spacing: 12) {
                        IslamicOccasionBadge(occasionId: occasion.id, size: 42)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(occasion.title(language: theme.language))
                                .font(theme.scaledFont(size: 14.5, weight: .bold))
                                .foregroundStyle(theme.onSurface)
                            Text(theme.t("calendar_tap_for_details"))
                                .font(theme.scaledFont(size: 11.5))
                                .foregroundStyle(theme.primary)
                        }
                        Spacer()
                        Image(systemName: theme.isRTL ? "chevron.left" : "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(theme.outline)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(theme.gold.opacity(theme.isDark ? 0.14 : 0.10))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .sirajCardSurface(cornerRadius: 22)
    }

    // MARK: - Events Tab

    private func eventsListSection(upcoming: [DatedOccasion]) -> some View {
        let groupedYears = Array(Set(upcoming.map(\.hijriYear))).sorted()
        return VStack(alignment: .leading, spacing: 14) {
            if upcoming.isEmpty {
                Text(theme.t("calendar_events_empty"))
                    .font(theme.scaledFont(size: 14))
                    .foregroundStyle(theme.onSurfaceVariant)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                ForEach(groupedYears, id: \.self) { year in
                    let items = upcoming.filter { $0.hijriYear == year }
                    Text(HijriFormatter.yearString(year, lang: theme.language, numeralSystem: appState.settings.numeralSystem))
                        .font(theme.scaledFont(size: 14, weight: .black))
                        .foregroundStyle(theme.primary)
                        .padding(.horizontal, 6)
                        .padding(.top, 4)

                    VStack(spacing: 10) {
                        ForEach(items) { dated in
                            Button {
                                sheetOccasion = dated
                            } label: {
                                HStack(spacing: 12) {
                                    IslamicOccasionBadge(occasionId: dated.occasion.id, size: 46, highlighted: dated.isToday)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(dated.occasion.title(language: theme.language))
                                            .font(theme.scaledFont(size: 15, weight: .bold))
                                            .foregroundStyle(theme.onSurface)
                                            .lineLimit(1)
                                        Text("\(theme.digits(String(dated.occasion.hijriDay))) \(HijriFormatter.monthName(dated.occasion.hijriMonth, lang: theme.language)) · \(HijriFormatter.formatGregorianCompact(dated.date, lang: theme.language, numeralSystem: appState.settings.numeralSystem))")
                                            .font(theme.scaledFont(size: 12))
                                            .foregroundStyle(theme.onSurfaceVariant)
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                    countdownChip(daysUntil: dated.daysUntil)
                                }
                                .padding(12)
                                .sirajCardSurface(cornerRadius: 20, isElevated: dated.isToday)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func shiftMonth(_ delta: Int) {
        if appState.settings.isHapticEnabled {
            UISelectionFeedbackGenerator().selectionChanged()
        }
        withAnimation(theme.motionEnabled ? .easeInOut(duration: 0.2) : nil) {
            displayedMonth = displayedMonth.adding(months: delta)
        }
    }

    private func countdownChip(daysUntil: Int) -> some View {
        let label: String = {
            if daysUntil == 0 { return theme.t("calendar_countdown_today") }
            if daysUntil == 1 { return theme.t("calendar_countdown_tomorrow") }
            return theme.plural("calendar_countdown_days_left", count: daysUntil, theme.digits(String(daysUntil)))
        }()
        return Text(label)
            .font(theme.scaledFont(size: 11.5, weight: .bold))
            .foregroundStyle(daysUntil == 0 ? theme.onPrimary : theme.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(daysUntil == 0 ? theme.primary : theme.primary.opacity(0.12)))
    }

    private func relativeDayChip(delta: Int) -> some View {
        let label: String = {
            if delta == 0 { return theme.t("calendar_countdown_today") }
            if delta == 1 { return theme.t("calendar_countdown_tomorrow") }
            if delta == -1 { return theme.t("calendar_relative_yesterday") }
            if delta > 1 { return theme.plural("calendar_relative_in_days", count: delta, theme.digits(String(delta))) }
            let ago = abs(delta)
            return theme.plural("calendar_relative_days_ago", count: ago, theme.digits(String(ago)))
        }()
        return Text(label)
            .font(theme.scaledFont(size: 11.5, weight: .bold))
            .foregroundStyle(theme.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(theme.primary.opacity(0.12)))
    }

    private func dayBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(theme.scaledFont(size: 11.5, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(color.opacity(0.14)))
    }

    private func shortWeekday(_ sun0: Int) -> String {
        switch SirajLocalizer.baseLanguage(theme.language) {
        case "ar": return ["أحد", "إثن", "ثلا", "أرب", "خمي", "جمع", "سبت"][sun0]
        case "tr": return ["Paz", "Pzt", "Sal", "Çar", "Per", "Cum", "Cmt"][sun0]
        case "ur": return ["اتوار", "پیر", "منگل", "بدھ", "جمعرات", "جمعہ", "ہفتہ"][sun0]
        default: return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][sun0]
        }
    }

    private func gregorianSpanText(start: CivilDate, end: CivilDate) -> String {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.locale = Locale(identifier: SirajLocalizer.baseLanguage(theme.language))
        df.dateFormat = "MMM yyyy"
        let a = df.string(from: start.utcMidnight)
        let b = df.string(from: end.utcMidnight)
        let raw = a == b ? a : "\(a) / \(b)"
        return theme.digits(DigitFormatter.toWestern(raw))
    }
}

private struct AstronomicalMoonDisc: View {
    let phaseFraction: Double

    var body: some View {
        Canvas { ctx, size in
            let rect = CGRect(origin: .zero, size: size)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let outerR = min(size.width, size.height) / 2
            ctx.fill(
                Path(ellipseIn: rect),
                with: .radialGradient(
                    Gradient(colors: [Color(argbHex: 0xFF1A2540), Color(argbHex: 0xFF0A101E)]),
                    center: center,
                    startRadius: 2,
                    endRadius: outerR
                )
            )

            // Subtle background stars
            let stars: [(CGFloat, CGFloat, CGFloat)] = [
                (0.20, 0.24, 1.1), (0.82, 0.28, 1.0), (0.76, 0.78, 1.2), (0.24, 0.76, 0.9)
            ]
            for (sx, sy, sr) in stars {
                let pt = CGPoint(x: size.width * sx, y: size.height * sy)
                ctx.fill(
                    Path(ellipseIn: CGRect(x: pt.x - sr, y: pt.y - sr, width: sr * 2, height: sr * 2)),
                    with: .color(Color.white.opacity(0.65))
                )
            }

            let moonR = outerR * 0.62
            let discRect = CGRect(x: center.x - moonR, y: center.y - moonR, width: moonR * 2, height: moonR * 2)
            ctx.fill(Path(ellipseIn: discRect), with: .color(Color(argbHex: 0xFF28344E)))

            let litPath = moonLimbPath(center: center, radius: moonR, phaseFraction: phaseFraction)
            ctx.fill(
                litPath,
                with: .radialGradient(
                    Gradient(colors: [Color(argbHex: 0xFFFFF8DC), Color(argbHex: 0xFFE6C87A)]),
                    center: CGPoint(x: center.x - moonR * 0.2, y: center.y - moonR * 0.2),
                    startRadius: 1,
                    endRadius: moonR * 1.4
                )
            )
            ctx.stroke(Path(ellipseIn: discRect), with: .color(Color.white.opacity(0.18)), lineWidth: 0.75)
        }
    }
}

private struct OccasionDetailSheet: View {
    @Environment(\.sirajTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    let dated: DatedOccasion
    let todayCivil: CivilDate

    var body: some View {
        let delta = dated.date.dayNumber - todayCivil.dayNumber
        let badgeText: String = {
            if delta == 0 { return theme.t("calendar_countdown_today") }
            if delta == 1 { return theme.t("calendar_countdown_tomorrow") }
            if delta == -1 { return theme.t("calendar_relative_yesterday") }
            if delta > 1 { return theme.plural("calendar_countdown_days_left", count: delta, theme.digits(String(delta))) }
            let ago = abs(delta)
            return theme.plural("calendar_relative_days_ago", count: ago, theme.digits(String(ago)))
        }()

        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    IslamicOccasionBadge(occasionId: dated.occasion.id, size: 72, highlighted: dated.isToday)
                        .padding(.top, 10)

                    Text(dated.occasion.title(language: theme.language))
                        .font(theme.scaledFont(size: 22, weight: .black))
                        .foregroundStyle(theme.onSurface)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 4) {
                        Text("\(theme.digits(String(dated.occasion.hijriDay))) \(HijriFormatter.monthName(dated.occasion.hijriMonth, lang: theme.language)) \(HijriFormatter.yearString(dated.hijriYear, lang: theme.language, numeralSystem: theme.settings.numeralSystem))")
                            .font(theme.scaledFont(size: 15, weight: .bold))
                            .foregroundStyle(theme.primary)
                        Text(HijriFormatter.formatGregorian(dated.date, lang: theme.language, numeralSystem: theme.settings.numeralSystem))
                            .font(theme.scaledFont(size: 13.5))
                            .foregroundStyle(theme.onSurfaceVariant)
                    }

                    Text(badgeText)
                        .font(theme.scaledFont(size: 12.5, weight: .bold))
                        .foregroundStyle(dated.isToday ? theme.onPrimary : theme.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(dated.isToday ? theme.primary : theme.primary.opacity(0.12)))

                    Rectangle()
                        .fill(theme.gold.opacity(0.40))
                        .frame(width: 72, height: 2)
                        .clipShape(Capsule())

                    Text(dated.occasion.description(language: theme.language))
                        .font(theme.scaledFont(size: 15.5))
                        .foregroundStyle(theme.onSurface)
                        .lineSpacing(6)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(20)
            }
            .background(theme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(theme.t("close")) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
