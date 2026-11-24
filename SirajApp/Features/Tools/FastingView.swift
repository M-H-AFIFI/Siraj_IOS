import Foundation
import Observation
import SwiftUI
import UIKit
import UserNotifications
import SirajCore

@MainActor
@Observable
final class FastingStore {
    private let userStore: UserDataStore

    var logs: [FastingLogEntry] = []
    var isReminderEnabled: Bool = false

    init(userStore: UserDataStore) {
        self.userStore = userStore
        let prefs = userStore.loadFastingPrefs()
        self.logs = prefs.logs
        self.isReminderEnabled = prefs.isReminderEnabled
    }

    func isFasting(on date: CivilDate) -> Bool {
        let iso = FastingPlanner.dateISO(date)
        return logs.first(where: { $0.dateISO == iso })?.isFasting == true
    }

    func toggleFasting(on date: CivilDate, calendar: SirajHijriCalendar) {
        let iso = FastingPlanner.dateISO(date)
        if let idx = logs.firstIndex(where: { $0.dateISO == iso }) {
            if logs[idx].isFasting {
                logs.remove(at: idx)
            } else {
                logs[idx].isFasting = true
            }
        } else {
            let hijri = calendar.toHijri(date)
            let dow = FastingPlanner.weekdaySun0(date)
            let type: FastingType
            if hijri.month == 9 {
                type = .required
            } else if dow == 1 || dow == 4 || IslamicOccasions.isWhiteDay(month: hijri.month, day: hijri.day)
                || (hijri.month == 1 && hijri.day == 10) || (hijri.month == 12 && hijri.day == 9) {
                type = .sunnah
            } else {
                type = .nafil
            }
            logs.append(FastingLogEntry(dateISO: iso, isFasting: true, type: type))
        }
        logs.sort { $0.dateISO > $1.dateISO }
        persist()
    }

    func removeLog(dateISO: String) {
        logs.removeAll { $0.dateISO == dateISO }
        persist()
    }

    func setReminderEnabled(_ enabled: Bool, title: String, body: String) {
        isReminderEnabled = enabled
        persist()
        syncSunnahReminders(enabled: enabled, title: title, body: body)
    }

    func ramadanCount() -> Int {
        logs.filter { $0.isFasting && $0.type == .required }.count
    }

    func voluntaryCount() -> Int {
        logs.filter { $0.isFasting && $0.type != .required }.count
    }

    func streak(today: CivilDate) -> Int {
        FastingPlanner.calculateStreak(logs: logs, today: today)
    }

    private func persist() {
        userStore.saveFastingPrefs(FastingPrefs(logs: logs, isReminderEnabled: isReminderEnabled))
    }

    private func syncSunnahReminders(enabled: Bool, title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        let ids = ["siraj_fasting_sun_eve", "siraj_fasting_wed_eve"]
        center.removePendingNotificationRequests(withIdentifiers: ids)
        guard enabled else { return }

        // Remind Sunday evening (weekday 1) for Monday fast, and Wednesday evening (weekday 4) for Thursday fast.
        let pairs: [(String, Int)] = [("siraj_fasting_sun_eve", 1), ("siraj_fasting_wed_eve", 4)]
        for (id, weekday) in pairs {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            var comps = DateComponents()
            comps.weekday = weekday
            comps.hour = 20
            comps.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }
}

struct FastingView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    let fastingStore: FastingStore

    @State private var shownYear: Int
    @State private var shownMonth: Int

    init(appState: AppState, fastingStore: FastingStore) {
        self.appState = appState
        self.fastingStore = fastingStore
        let today = appState.activePlace.today(at: appState.currentTime)
        self._shownYear = State(initialValue: today.year)
        self._shownMonth = State(initialValue: today.month)
    }

    private var todayCivil: CivilDate { appState.activePlace.today(at: appState.currentTime) }
    private var hijriCalendar: SirajHijriCalendar { appState.hijriCalendar }

    var body: some View {
        let isTodayFasting = fastingStore.isFasting(on: todayCivil)
        let upcoming = FastingPlanner.computeUpcoming(from: todayCivil, calendar: hijriCalendar)

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(theme.t("fasting_header_title"))
                        .font(theme.scaledFont(size: 24, weight: .black))
                        .foregroundStyle(theme.onBackground)
                    Text(theme.t("fasting_header_sub"))
                        .font(theme.scaledFont(size: 13.5))
                        .foregroundStyle(theme.onSurfaceVariant)
                }
                .padding(.horizontal, 4)

                todayStatusCard(isFasting: isTodayFasting)
                fastingHoursCard
                statsRow
                MihrabCalendarView(
                    year: $shownYear,
                    month: $shownMonth,
                    today: todayCivil,
                    hijriCalendar: hijriCalendar,
                    fastedISOs: Set(fastingStore.logs.filter(\.isFasting).map(\.dateISO)),
                    onToggleDay: { civil in
                        if appState.settings.isHapticEnabled {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        fastingStore.toggleFasting(on: civil, calendar: hijriCalendar)
                    }
                )
                reminderCard
                upcomingSection(upcoming)
                loggedHistorySection
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 124)
        }
        .scrollIndicators(.hidden)
        .background(Color.clear)
        .navigationTitle(theme.t("fasting_title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func todayStatusCard(isFasting: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isFasting ? theme.primary : theme.primary.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image("ic_siraj_fasting")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(isFasting ? theme.onPrimary : theme.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.t(isFasting ? "fasting_today_yes" : "fasting_today_question"))
                        .font(theme.scaledFont(size: 16.5, weight: .black))
                        .foregroundStyle(theme.onSurface)
                    Text(HijriFormatter.format(appState.hijriDate, lang: theme.language, numeralSystem: appState.settings.numeralSystem))
                        .font(theme.scaledFont(size: 12.5))
                        .foregroundStyle(theme.onSurfaceVariant)
                }
                Spacer(minLength: 0)
            }

            Button {
                if appState.settings.isHapticEnabled {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
                fastingStore.toggleFasting(on: todayCivil, calendar: hijriCalendar)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isFasting ? "checkmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text(theme.t(isFasting ? "fasting_action_fasting" : "fasting_action_not_fasting"))
                        .font(theme.scaledFont(size: 14.5, weight: .black))
                }
                .foregroundStyle(isFasting ? theme.primary : theme.onPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isFasting ? theme.primary.opacity(0.14) : theme.primary)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .sirajCardSurface(cornerRadius: 24, isElevated: isFasting)
        .overlay(shape.strokeBorder(isFasting ? theme.primary.opacity(0.45) : Color.clear, lineWidth: isFasting ? 1.2 : 0))
    }

    private var fastingHoursCard: some View {
        let fajr = appState.prayerDay.entries.first(where: { $0.type == .fajr })?.time
        let maghrib = appState.prayerDay.entries.first(where: { $0.type == .maghrib })?.time
        let tz = appState.activePlace.timeZone

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sun.horizon.fill")
                    .foregroundStyle(theme.primary)
                Text(theme.t("fasting_imsakiah_title"))
                    .font(theme.scaledFont(size: 15, weight: .black))
                    .foregroundStyle(theme.onSurface)
            }

            if let fajr, let maghrib {
                HStack(spacing: 12) {
                    imsakTile(
                        title: theme.t("tools_fasting_suhoor"),
                        subtitle: theme.t("fasting_suhoor_label"),
                        time: TimeFormatter.formatTime(
                            fajr,
                            timeZone: tz,
                            hourFormat: appState.settings.hourFormat,
                            numeralSystem: appState.settings.numeralSystem,
                            lang: theme.language
                        ),
                        icon: "moon.stars.fill"
                    )
                    imsakTile(
                        title: theme.t("tools_fasting_iftar"),
                        subtitle: theme.t("fasting_iftar_label"),
                        time: TimeFormatter.formatTime(
                            maghrib,
                            timeZone: tz,
                            hourFormat: appState.settings.hourFormat,
                            numeralSystem: appState.settings.numeralSystem,
                            lang: theme.language
                        ),
                        icon: "sunset.fill"
                    )
                }
            } else {
                Text(theme.t("tools_fasting_times_unavailable"))
                    .font(theme.scaledFont(size: 13))
                    .foregroundStyle(theme.onSurfaceVariant)
            }
        }
        .padding(16)
        .sirajCardSurface(cornerRadius: 22)
    }

    private func imsakTile(title: String, subtitle: String, time: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(theme.primary)
                Text(title)
                    .font(theme.scaledFont(size: 12, weight: .bold))
                    .foregroundStyle(theme.primary)
            }
            Text(time)
                .font(theme.scaledFont(size: 20, weight: .black))
                .foregroundStyle(theme.onSurface)
            Text(subtitle)
                .font(theme.scaledFont(size: 11))
                .foregroundStyle(theme.outline)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.primary.opacity(theme.isDark ? 0.14 : 0.08))
        )
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statTile(value: fastingStore.ramadanCount(), label: theme.t("fasting_stat_ramadan"))
            statTile(value: fastingStore.voluntaryCount(), label: theme.t("fasting_stat_sunnah"))
            statTile(value: fastingStore.streak(today: todayCivil), label: theme.t("fasting_stat_streak"))
        }
    }

    private func statTile(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text(theme.digits(String(value)))
                .font(theme.scaledFont(size: 22, weight: .black))
                .foregroundStyle(theme.primary)
            Text(label)
                .font(theme.scaledFont(size: 11.5, weight: .semibold))
                .foregroundStyle(theme.onSurfaceVariant)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .sirajCardSurface(cornerRadius: 20)
    }

    private var reminderCard: some View {
        SirajSettingsToggleRow(
            icon: "bell.badge.fill",
            title: theme.t("fasting_reminder_title"),
            subtitle: theme.t("fasting_reminder_desc"),
            isOn: Binding(
                get: { fastingStore.isReminderEnabled },
                set: { enabled in
                    fastingStore.setReminderEnabled(
                        enabled,
                        title: theme.t("fasting_reminder_title"),
                        body: theme.t("fasting_reminder_desc")
                    )
                }
            )
        )
        .sirajCardSurface(cornerRadius: 22)
    }

    private func upcomingSection(_ items: [UpcomingFast]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(theme.t("fasting_upcoming_header"))
                .font(theme.scaledFont(size: 16, weight: .black))
                .foregroundStyle(theme.onBackground)
                .padding(.horizontal, 4)

            VStack(spacing: 8) {
                ForEach(items) { fast in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(theme.primary.opacity(0.12))
                                .frame(width: 40, height: 40)
                            Image(systemName: fast.type == .whiteDays ? "moon.fill" : "calendar")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(theme.primary)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(theme.t(fast.type.titleKey))
                                .font(theme.scaledFont(size: 14.5, weight: .bold))
                                .foregroundStyle(theme.onSurface)
                            Text(HijriFormatter.formatGregorianCompact(fast.targetDate, lang: theme.language, numeralSystem: appState.settings.numeralSystem))
                                .font(theme.scaledFont(size: 12))
                                .foregroundStyle(theme.onSurfaceVariant)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text(daysAwayLabel(fast.daysAway))
                            .font(theme.scaledFont(size: 11.5, weight: .bold))
                            .foregroundStyle(fast.daysAway == 0 ? theme.onPrimary : theme.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(fast.daysAway == 0 ? theme.primary : theme.primary.opacity(0.12)))
                    }
                    .padding(12)
                    .sirajCardSurface(cornerRadius: 18)
                }
            }
        }
    }

    private var loggedHistorySection: some View {
        let activeLogs = fastingStore.logs.filter(\.isFasting)
        return VStack(alignment: .leading, spacing: 10) {
            Text(theme.t("fasting_logged_header"))
                .font(theme.scaledFont(size: 16, weight: .black))
                .foregroundStyle(theme.onBackground)
                .padding(.horizontal, 4)

            if activeLogs.isEmpty {
                VStack(spacing: 6) {
                    Text(theme.t("tools_fasting_logs_empty_title"))
                        .font(theme.scaledFont(size: 14.5, weight: .bold))
                        .foregroundStyle(theme.onSurface)
                    Text(theme.t("tools_fasting_logs_empty_body"))
                        .font(theme.scaledFont(size: 12.5))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .sirajCardSurface(cornerRadius: 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(activeLogs.prefix(20)) { entry in
                        let civil = FastingPlanner.parseISO(entry.dateISO)
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(theme.primary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(
                                    civil.map { HijriFormatter.formatGregorianCompact($0, lang: theme.language, numeralSystem: appState.settings.numeralSystem) }
                                        ?? entry.dateISO
                                )
                                .font(theme.scaledFont(size: 14, weight: .bold))
                                .foregroundStyle(theme.onSurface)
                                Text(theme.t(entry.type.labelKey))
                                    .font(theme.scaledFont(size: 11.5))
                                    .foregroundStyle(theme.primary)
                            }
                            Spacer()
                            Button {
                                fastingStore.removeLog(dateISO: entry.dateISO)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                                    .foregroundStyle(theme.outline)
                                    .frame(width: 32, height: 32)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .sirajCardSurface(cornerRadius: 18)
                    }
                }
            }
        }
    }

    private func daysAwayLabel(_ days: Int) -> String {
        if days == 0 { return theme.t("tools_fasting_today") }
        if days == 1 { return theme.t("tools_fasting_tomorrow") }
        return theme.plural("tools_fasting_in_days", count: days, theme.digits(String(days)))
    }
}

private struct MihrabCalendarView: View {
    @Environment(\.sirajTheme) private var theme
    @Binding var year: Int
    @Binding var month: Int
    let today: CivilDate
    let hijriCalendar: SirajHijriCalendar
    let fastedISOs: Set<String>
    let onToggleDay: (CivilDate) -> Void

    var body: some View {
        let firstOfMonth = CivilDate(year: year, month: month, day: 1)
        let daysInMonth = Self.monthLength(year: year, month: month)
        let leadingEmpty = FastingPlanner.weekdaySun0(firstOfMonth)
        let totalSlots = leadingEmpty + daysInMonth
        let trailing = (7 - (totalSlots % 7)) % 7
        let cellCount = totalSlots + trailing
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

        VStack(spacing: 12) {
            HStack {
                Text(theme.t("fasting_cal_header"))
                    .font(theme.scaledFont(size: 15, weight: .black))
                    .foregroundStyle(theme.onSurface)
                Spacer()
                HStack(spacing: 8) {
                    Button { shiftMonth(-1) } label: {
                        Image(systemName: theme.isRTL ? "chevron.right" : "chevron.left")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(theme.primary)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(theme.primary.opacity(0.10)))
                    }
                    .buttonStyle(.plain)

                    Text(monthTitle(firstOfMonth))
                        .font(theme.scaledFont(size: 13, weight: .bold))
                        .foregroundStyle(theme.onSurface)
                        .lineLimit(1)

                    Button { shiftMonth(1) } label: {
                        Image(systemName: theme.isRTL ? "chevron.left" : "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(theme.primary)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(theme.primary.opacity(0.10)))
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { dow in
                    Text(shortWeekday(dow))
                        .font(theme.scaledFont(size: 11, weight: .bold))
                        .foregroundStyle(dow == 1 || dow == 4 ? theme.primary : theme.outline)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(0..<cellCount, id: \.self) { slot in
                    let day = slot - leadingEmpty + 1
                    if day >= 1 && day <= daysInMonth {
                        let civil = CivilDate(year: year, month: month, day: day)
                        let iso = FastingPlanner.dateISO(civil)
                        let isFasted = fastedISOs.contains(iso)
                        let isToday = civil == today
                        let isFuture = civil > today
                        let hijri = hijriCalendar.toHijri(civil)
                        let dow = FastingPlanner.weekdaySun0(civil)
                        let isSunnah = (dow == 1 || dow == 4) || IslamicOccasions.isWhiteDay(month: hijri.month, day: hijri.day)

                        Button {
                            guard !isFuture else { return }
                            onToggleDay(civil)
                        } label: {
                            VStack(spacing: 2) {
                                Text(theme.digits(String(day)))
                                    .font(theme.scaledFont(size: 13.5, weight: (isFasted || isToday) ? .black : .semibold))
                                    .foregroundStyle(
                                        isFasted ? theme.onPrimary : (isFuture ? theme.outline.opacity(0.45) : theme.onSurface)
                                    )
                                Circle()
                                    .fill(isFasted ? theme.onPrimary.opacity(0.85) : (isSunnah && !isFuture ? theme.gold : Color.clear))
                                    .frame(width: 4, height: 4)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(isFasted ? theme.primary : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(isToday && !isFasted ? theme.primary : Color.clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isFuture)
                        .accessibilityLabel(isFasted ? theme.t("tools_fasting_logged_a11y") : String(day))
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }
        }
        .padding(16)
        .sirajCardSurface(cornerRadius: 22)
    }

    private func shiftMonth(_ delta: Int) {
        var m = month + delta
        var y = year
        if m < 1 { m = 12; y -= 1 }
        if m > 12 { m = 1; y += 1 }
        year = y
        month = m
    }

    private func monthTitle(_ date: CivilDate) -> String {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.locale = Locale(identifier: SirajLocalizer.baseLanguage(theme.language))
        df.dateFormat = "MMM yyyy"
        return theme.digits(DigitFormatter.toWestern(df.string(from: date.utcMidnight)))
    }

    private func shortWeekday(_ sun0: Int) -> String {
        switch SirajLocalizer.baseLanguage(theme.language) {
        case "ar": return ["أحد", "إثن", "ثلا", "أرب", "خمي", "جمع", "سبت"][sun0]
        case "tr": return ["P", "Pt", "S", "Ç", "Pe", "C", "Ct"][sun0]
        case "ur": return ["اتوار", "پیر", "منگل", "بدھ", "جمعرات", "جمعہ", "ہفتہ"][sun0]
        default: return ["S", "M", "T", "W", "T", "F", "S"][sun0]
        }
    }

    private static func monthLength(year: Int, month: Int) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let comps = DateComponents(year: year, month: month, day: 1)
        guard let date = cal.date(from: comps), let range = cal.range(of: .day, in: .month, for: date) else {
            return 30
        }
        return range.count
    }
}
