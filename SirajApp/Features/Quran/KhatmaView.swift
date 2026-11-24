import Observation
import SirajCore
import SwiftUI
import UserNotifications

@MainActor
@Observable
final class KhatmaStore {
    private let userStore: UserDataStore
    var record: KhatmaRecord?
    var khatmasCompleted: Int

    init(userStore: UserDataStore) {
        self.userStore = userStore
        self.record = userStore.loadKhatmaRecord()
        self.khatmasCompleted = userStore.loadKhatmasCompleted()
    }

    func plan(surahs: [Surah]) -> KhatmaPlan? {
        guard let record else { return nil }
        return KhatmaPlanner.buildPlan(
            record: record,
            todayEpochDay: KhatmaPlanner.todayEpochDay(),
            khatmasCompleted: khatmasCompleted,
            surahs: surahs
        )
    }

    func begin(days: Int, startFromPage: Int) {
        let today = KhatmaPlanner.todayEpochDay()
        let clampedDays = min(KhatmaPlanner.dayRange.upperBound, max(KhatmaPlanner.dayRange.lowerBound, days))
        let anchorPages = max(0, min(KhatmaPlanner.totalPages - 1, startFromPage - 1))
        let rec = KhatmaRecord(
            startEpochDay: today,
            anchorEpochDay: today,
            anchorPages: anchorPages,
            endEpochDay: today + Int64(clampedDays - 1),
            pagesCompleted: anchorPages,
            totalPages: KhatmaPlanner.totalPages,
            reminderEnabled: true,
            reminderTime: "20:00",
            lastReadEpochDay: 0,
            streak: 0
        )
        record = rec
        userStore.saveKhatmaRecord(rec)
        syncReminderNotification()
    }

    func completeToday(surahs: [Surah]) {
        guard let currentPlan = plan(surahs: surahs) else { return }
        let targetPage: Int
        if let today = currentPlan.today {
            targetPage = max(currentPlan.pagesCompleted, today.endPage)
        } else {
            targetPage = min(currentPlan.totalPages, currentPlan.pagesCompleted + currentPlan.pagesPerDayToCatchUp)
        }
        updatePagesCompleted(targetPage)
    }

    func undoLastDay(surahs: [Surah]) {
        guard let currentPlan = plan(surahs: surahs), let rec = record else { return }
        let prevEnd: Int
        if let today = currentPlan.today {
            prevEnd = max(rec.anchorPages, today.startPage - 1)
        } else {
            prevEnd = max(rec.anchorPages, rec.pagesCompleted - 1)
        }
        var next = rec
        next.pagesCompleted = prevEnd
        record = next
        userStore.saveKhatmaRecord(next)
    }

    func updatePagesCompleted(_ pages: Int) {
        guard let rec = record else { return }
        let wasFinished = rec.isFinished
        let next = KhatmaPlanner.applyProgress(
            record: rec,
            newPagesCompleted: pages,
            todayEpochDay: KhatmaPlanner.todayEpochDay()
        )
        record = next
        userStore.saveKhatmaRecord(next)
        if !wasFinished && next.isFinished {
            khatmasCompleted += 1
            userStore.saveKhatmasCompleted(khatmasCompleted)
        }
    }

    func reschedule() {
        guard let rec = record else { return }
        let next = KhatmaPlanner.rescheduled(record: rec, todayEpochDay: KhatmaPlanner.todayEpochDay())
        record = next
        userStore.saveKhatmaRecord(next)
    }

    func setReminderEnabled(_ enabled: Bool) {
        guard var rec = record else { return }
        rec.reminderEnabled = enabled
        record = rec
        userStore.saveKhatmaRecord(rec)
        syncReminderNotification()
    }

    func setReminderTime(hour: Int, minute: Int) {
        guard var rec = record else { return }
        rec.reminderTime = String(format: "%02d:%02d", hour, minute)
        record = rec
        userStore.saveKhatmaRecord(rec)
        syncReminderNotification()
    }

    func end() {
        record = nil
        userStore.saveKhatmaRecord(nil)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["siraj_khatma_daily"])
    }

    private func syncReminderNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["siraj_khatma_daily"])
        guard let rec = record, rec.reminderEnabled, !rec.isFinished else { return }
        let parts = rec.reminderTime.split(separator: ":")
        let hour = Int(parts.first ?? "20") ?? 20
        let minute = Int(parts.dropFirst().first ?? "0") ?? 0

        let content = UNMutableNotificationContent()
        content.title = "Siraj"
        content.body = "Time for today's Quran Khatma reading."
        content.sound = .default

        var dc = DateComponents()
        dc.hour = hour
        dc.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        let req = UNNotificationRequest(identifier: "siraj_khatma_daily", content: content, trigger: trigger)
        center.add(req)
    }
}

struct KhatmaHeroCard: View {
    @Environment(\.sirajTheme) private var theme
    let plan: KhatmaPlan?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(theme.primary.opacity(0.14))
                        .frame(width: 48, height: 48)
                    if let plan {
                        Circle()
                            .trim(from: 0, to: plan.fraction)
                            .stroke(theme.primary, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 44, height: 44)
                        Text("\(theme.digits(String(Int((plan.fraction * 100).rounded()))))%")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(theme.primary)
                    } else {
                        Image("ic_quick_quran")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .foregroundStyle(theme.primary)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(theme.t("kh_card_title"))
                        .font(theme.scaledFont(size: 15, weight: .black))
                        .foregroundStyle(theme.onSurface)
                    if let plan {
                        if let today = plan.today {
                            let range = theme.t("kh_pages_range", theme.digits(String(today.startPage)), theme.digits(String(today.endPage)))
                            Text(today.isComplete ? theme.t("kh_today_done") : theme.t("kh_card_today", range))
                                .font(theme.scaledFont(size: 12.5))
                                .foregroundStyle(theme.onSurfaceVariant)
                                .lineLimit(1)
                        } else if plan.record.isFinished {
                            Text(theme.t("kh_finished_title"))
                                .font(theme.scaledFont(size: 12.5, weight: .semibold))
                                .foregroundStyle(theme.primary)
                        } else {
                            Text(theme.t("kh_progress", theme.digits(String(plan.pagesCompleted)), theme.digits(String(plan.totalPages))))
                                .font(theme.scaledFont(size: 12.5))
                                .foregroundStyle(theme.onSurfaceVariant)
                        }
                    } else {
                        Text(theme.t("kh_card_empty"))
                            .font(theme.scaledFont(size: 12.5))
                            .foregroundStyle(theme.onSurfaceVariant)
                            .lineLimit(2)
                    }
                }

                Spacer()

                Image(systemName: theme.isRTL ? "chevron.left" : "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.onSurfaceVariant)
            }
            .padding(14)
            .sirajCardSurface(cornerRadius: 22)
        }
        .buttonStyle(.plain)
    }
}

struct KhatmaView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    let khatmaStore: KhatmaStore
    let onOpenReader: (ReaderDestination) -> Void

    @State private var selectedDays = 30
    @State private var startFromLastRead = false
    @State private var showCustomDays = false
    @State private var showFullSchedule = false
    @State private var showTimePicker = false
    @State private var showEndAlert = false

    private var activePlan: KhatmaPlan? {
        khatmaStore.plan(surahs: appState.quranStore.surahs)
    }

    private var lastReadMadaniPage: Int {
        guard let pos = appState.quranStore.readingPosition else { return 1 }
        return appState.quranStore.pageForAyah(surah: pos.surahNumber, ayah: pos.ayahNumber, edition: .madinah)
    }

    var body: some View {
        Group {
            if let plan = activePlan {
                activeBody(plan)
            } else {
                setupBody
            }
        }
        .background(Color.clear)
        .navigationTitle(theme.t("kh_title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCustomDays) {
            customDaysSheet
        }
        .sheet(isPresented: $showTimePicker) {
            let parts = (khatmaStore.record?.reminderTime ?? "20:00").split(separator: ":")
            let h = Int(parts.first ?? "20") ?? 20
            let m = Int(parts.dropFirst().first ?? "0") ?? 0
            MihrabTimePickerSheet(title: theme.t("kh_reminder_time"), hour: h, minute: m) { nh, nm in
                khatmaStore.setReminderTime(hour: nh, minute: nm)
            }
        }
        .alert(theme.t("kh_end"), isPresented: $showEndAlert) {
            Button(theme.t("kh_end_action"), role: .destructive) {
                khatmaStore.end()
            }
            Button(theme.t("kh_cancel"), role: .cancel) {}
        } message: {
            Text(theme.t("kh_end_confirm"))
        }
    }

    // MARK: - Setup Phase

    private var setupBody: some View {
        let presets = KhatmaPlanner.presetDays
        let isCustom = !presets.contains(selectedDays)
        let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
        let projectedEpoch = KhatmaPlanner.todayEpochDay() + Int64(selectedDays - 1)
        let projectedCivil = KhatmaPlanner.civilDate(fromEpochDay: projectedEpoch)
        let projectedLabel = HijriFormatter.formatGregorianCompact(
            projectedCivil,
            lang: theme.language,
            numeralSystem: appState.settings.numeralSystem
        )

        return ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(theme.primary.opacity(0.11))
                            .frame(width: 84, height: 84)
                        Image("ic_quick_quran")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundStyle(theme.primary)
                    }
                    Text(theme.t("kh_setup_headline"))
                        .font(theme.scaledFont(size: 22, weight: .black))
                        .foregroundStyle(theme.onSurface)
                        .multilineTextAlignment(.center)
                    Text(theme.t("kh_setup_sub"))
                        .font(theme.scaledFont(size: 13.5))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 8)

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(presets, id: \.self) { days in
                        lengthCard(days: days, selected: selectedDays == days, customTitle: nil) {
                            selectedDays = days
                        }
                    }
                }

                lengthCard(
                    days: selectedDays,
                    selected: isCustom,
                    customTitle: isCustom ? nil : theme.t("kh_custom_length"),
                    subtitleOverride: isCustom ? nil : theme.t("kh_custom_days")
                ) {
                    showCustomDays = true
                }

                if lastReadMadaniPage > 1 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(theme.t("kh_start_from"))
                            .font(theme.scaledFont(size: 12.5, weight: .bold))
                            .foregroundStyle(theme.onSurfaceVariant)
                        Picker("", selection: $startFromLastRead) {
                            Text(theme.t("kh_from_beginning")).tag(false)
                            Text(theme.t("kh_from_last_read", theme.digits(String(lastReadMadaniPage)))).tag(true)
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Text(theme.t("kh_finishes_on", projectedLabel))
                    .font(theme.scaledFont(size: 13.5, weight: .bold))
                    .foregroundStyle(theme.onSurfaceVariant)
                    .padding(.top, 4)

                Button {
                    let startP = startFromLastRead ? lastReadMadaniPage : 1
                    khatmaStore.begin(days: selectedDays, startFromPage: startP)
                } label: {
                    Text(theme.t("kh_begin"))
                        .font(theme.scaledFont(size: 16, weight: .black))
                        .foregroundStyle(theme.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(theme.primary, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 128)
        }
        .scrollIndicators(.hidden)
    }

    private func lengthCard(
        days: Int,
        selected: Bool,
        customTitle: String?,
        subtitleOverride: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        let pagesPerDay = (KhatmaPlanner.totalPages + days - 1) / max(1, days)
        return Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(customTitle ?? theme.plural("kh_days", count: days, theme.digits(String(days))))
                    .font(theme.scaledFont(size: 16, weight: .black))
                    .foregroundStyle(selected ? theme.primary : theme.onSurface)
                    .lineLimit(1)
                Text(subtitleOverride ?? theme.plural("kh_pages_a_day", count: pagesPerDay, theme.digits(String(pagesPerDay))))
                    .font(theme.scaledFont(size: 12.5))
                    .foregroundStyle(theme.onSurfaceVariant)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(selected ? theme.primary.opacity(0.12) : theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(selected ? theme.primary : theme.outlineVariant.opacity(0.4), lineWidth: selected ? 1.6 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var customDaysSheet: some View {
        let pagesPerDay = (KhatmaPlanner.totalPages + selectedDays - 1) / max(1, selectedDays)
        return VStack(spacing: 18) {
            Text(theme.t("kh_custom_days"))
                .font(theme.scaledFont(size: 17, weight: .black))
                .foregroundStyle(theme.onSurface)

            Text(theme.digits(String(selectedDays)))
                .font(.system(size: 46, weight: .black, design: .rounded))
                .foregroundStyle(theme.primary)

            Text(theme.plural("kh_pages_a_day", count: pagesPerDay, theme.digits(String(pagesPerDay))))
                .font(theme.scaledFont(size: 14))
                .foregroundStyle(theme.onSurfaceVariant)

            Slider(
                value: Binding(
                    get: { Double(selectedDays) },
                    set: { selectedDays = Int($0.rounded()) }
                ),
                in: Double(KhatmaPlanner.dayRange.lowerBound)...Double(KhatmaPlanner.dayRange.upperBound),
                step: 1
            )
            .tint(theme.primary)

            Button {
                showCustomDays = false
            } label: {
                Text(theme.t("kh_confirm"))
                    .font(theme.scaledFont(size: 15, weight: .black))
                    .foregroundStyle(theme.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(theme.primary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Active Phase

    private func activeBody(_ plan: KhatmaPlan) -> some View {
        let visibleDays: [KhatmaDayPortion] = {
            if showFullSchedule { return plan.days }
            let todayIdx = plan.days.firstIndex(where: \.isToday) ?? 0
            let from = max(0, todayIdx - 1)
            let to = min(plan.days.count, from + 5)
            return Array(plan.days[from..<to])
        }()

        return ScrollView {
            VStack(spacing: 14) {
                progressHero(plan)

                if plan.record.isFinished {
                    finishedCard(plan)
                } else {
                    todayCard(plan)
                }

                if plan.isBehind {
                    behindCard(plan)
                }

                // Schedule section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(theme.t("kh_schedule"))
                            .font(theme.scaledFont(size: 15, weight: .black))
                            .foregroundStyle(theme.onSurface)
                        Spacer()
                        if plan.days.count > 5 {
                            Button(showFullSchedule
                                   ? theme.t("kh_schedule_show_less")
                                   : theme.t("kh_schedule_show_all", theme.digits(String(plan.days.count)))) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showFullSchedule.toggle()
                                }
                            }
                            .font(theme.scaledFont(size: 12.5, weight: .bold))
                            .foregroundStyle(theme.primary)
                        }
                    }
                    .padding(.horizontal, 4)

                    VStack(spacing: 8) {
                        ForEach(visibleDays) { day in
                            scheduleRow(day)
                        }
                    }
                }

                // Reminder & end khatma settings
                SirajSettingsSection(title: theme.t("kh_reminder"), icon: "bell.badge.fill") {
                    SirajSettingsToggleRow(
                        icon: "bell.fill",
                        title: theme.t("kh_reminder"),
                        subtitle: theme.t("kh_reminder_desc"),
                        isOn: Binding(
                            get: { plan.record.reminderEnabled },
                            set: { khatmaStore.setReminderEnabled($0) }
                        )
                    )
                    if plan.record.reminderEnabled {
                        Divider().padding(.leading, 16)
                        SirajSettingsRow(
                            icon: "clock.fill",
                            title: theme.t("kh_reminder_time"),
                            value: theme.digits(plan.record.reminderTime)
                        ) {
                            showTimePicker = true
                        }
                    }
                    Divider().padding(.leading, 16)
                    Button {
                        showEndAlert = true
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(theme.error)
                                .frame(width: 34, height: 34)
                                .background(Circle().fill(theme.error.opacity(0.12)))
                            Text(theme.t("kh_end"))
                                .font(theme.scaledFont(size: 15, weight: .semibold))
                                .foregroundStyle(theme.error)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 128)
        }
        .scrollIndicators(.hidden)
    }

    private func progressHero(_ plan: KhatmaPlan) -> some View {
        let pct = Int((plan.fraction * 100).rounded())
        let statusText: String = {
            if plan.record.isFinished { return theme.t("kh_finished_title") }
            if plan.isBehind { return theme.plural("kh_behind", count: plan.pagesBehind, theme.digits(String(plan.pagesBehind))) }
            if plan.pagesAhead > 0 { return theme.plural("kh_ahead", count: plan.pagesAhead, theme.digits(String(plan.pagesAhead))) }
            return theme.t("kh_on_track")
        }()

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(theme.primary.opacity(0.16), lineWidth: 7)
                    Circle()
                        .trim(from: 0, to: plan.fraction)
                        .stroke(theme.primary, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(theme.digits(String(pct)))%")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(theme.primary)
                }
                .frame(width: 72, height: 72)

                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.t("kh_progress", theme.digits(String(plan.pagesCompleted)), theme.digits(String(plan.totalPages))))
                        .font(theme.scaledFont(size: 17, weight: .black))
                        .foregroundStyle(theme.onSurface)
                    Text(statusText)
                        .font(theme.scaledFont(size: 13, weight: .semibold))
                        .foregroundStyle(plan.isBehind ? theme.error : theme.primary)
                    HStack(spacing: 8) {
                        if plan.record.streak > 0 {
                            Label(theme.plural("kh_streak", count: plan.record.streak, theme.digits(String(plan.record.streak))), systemImage: "flame.fill")
                                .font(theme.scaledFont(size: 11.5, weight: .bold))
                                .foregroundStyle(theme.gold)
                        }
                        if plan.daysRemaining > 0 && !plan.record.isFinished {
                            Text(theme.plural("kh_days_left", count: plan.daysRemaining, theme.digits(String(plan.daysRemaining))))
                                .font(theme.scaledFont(size: 11.5))
                                .foregroundStyle(theme.onSurfaceVariant)
                        } else if plan.daysRemaining <= 0 && !plan.record.isFinished {
                            let over = abs(plan.daysRemaining) + 1
                            Text(theme.plural("kh_overdue", count: over, theme.digits(String(over))))
                                .font(theme.scaledFont(size: 11.5, weight: .semibold))
                                .foregroundStyle(theme.error)
                        }
                    }
                }
                Spacer()
            }
        }
        .padding(18)
        .sirajCardSurface(cornerRadius: 24, isElevated: true)
    }

    private func todayCard(_ plan: KhatmaPlan) -> some View {
        let today = plan.today
        let startP = today?.startPage ?? plan.nextPage
        let endP = today?.endPage ?? min(plan.totalPages, plan.nextPage + plan.pagesPerDayToCatchUp - 1)
        let isDone = today?.isComplete ?? false

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(theme.t("kh_today"))
                    .font(theme.scaledFont(size: 12, weight: .black))
                    .foregroundStyle(theme.primary)
                    .textCase(.uppercase)
                Spacer()
                if isDone {
                    Label(theme.t("kh_today_done"), systemImage: "checkmark.circle.fill")
                        .font(theme.scaledFont(size: 12, weight: .bold))
                        .foregroundStyle(theme.primary)
                }
            }

            Text(theme.t("kh_pages_range", theme.digits(String(startP)), theme.digits(String(endP))))
                .font(theme.scaledFont(size: 20, weight: .black))
                .foregroundStyle(theme.onSurface)

            if let today, today.hasLabels {
                let startName = SurahNames.isArabicScript(theme.language) ? today.startSurahName : today.startSurahEnglishName
                let endName = SurahNames.isArabicScript(theme.language) ? today.endSurahName : today.endSurahEnglishName
                Text(today.isWithinOneSurah ? startName : "\(startName) → \(endName)")
                    .font(theme.scaledFont(size: 13.5))
                    .foregroundStyle(theme.onSurfaceVariant)
            }

            HStack(spacing: 10) {
                Button {
                    let surah = today?.startSurahNumber ?? QuranTables.surahForPage(startP, edition: .madinah)
                    let edition = MushafEdition.resolve(appState.settings.mushafEdition)
                    let targetPage = edition == .madinah ? startP : appState.quranStore.pageForAyah(surah: surah, ayah: 1, edition: edition)
                    onOpenReader(ReaderDestination(page: targetPage, surahNumber: surah, ayahNumber: 1))
                } label: {
                    Text(theme.t("kh_read_now"))
                        .font(theme.scaledFont(size: 14, weight: .bold))
                        .foregroundStyle(theme.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(theme.primary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                if isDone {
                    Button {
                        khatmaStore.undoLastDay(surahs: appState.quranStore.surahs)
                    } label: {
                        Label(theme.t("kh_undo"), systemImage: "arrow.uturn.backward")
                            .font(theme.scaledFont(size: 14, weight: .bold))
                            .foregroundStyle(theme.onSurface)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(theme.surfaceVariant.opacity(0.65), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        khatmaStore.completeToday(surahs: appState.quranStore.surahs)
                    } label: {
                        Label(theme.t("kh_mark_done"), systemImage: "checkmark")
                            .font(theme.scaledFont(size: 14, weight: .bold))
                            .foregroundStyle(theme.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(theme.primary.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(18)
        .sirajCardSurface(cornerRadius: 24)
    }

    private func behindCard(_ plan: KhatmaPlan) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(theme.plural("kh_catch_up", count: plan.pagesPerDayToCatchUp, theme.digits(String(plan.pagesPerDayToCatchUp))))
                .font(theme.scaledFont(size: 14, weight: .bold))
                .foregroundStyle(theme.onSurface)
            Text(theme.t("kh_reschedule_desc"))
                .font(theme.scaledFont(size: 12.5))
                .foregroundStyle(theme.onSurfaceVariant)
            Button {
                khatmaStore.reschedule()
            } label: {
                Label(theme.t("kh_reschedule"), systemImage: "arrow.triangle.2.circlepath")
                    .font(theme.scaledFont(size: 13.5, weight: .bold))
                    .foregroundStyle(theme.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(theme.primary.opacity(0.13), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .sirajCardSurface(cornerRadius: 20)
    }

    private func finishedCard(_ plan: KhatmaPlan) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 42))
                .foregroundStyle(theme.primary)
            Text(theme.t("kh_finished_title"))
                .font(theme.scaledFont(size: 20, weight: .black))
                .foregroundStyle(theme.onSurface)
            Text(theme.t("kh_finished_body"))
                .font(theme.scaledFont(size: 14))
                .foregroundStyle(theme.onSurfaceVariant)
                .multilineTextAlignment(.center)
            if plan.khatmasCompleted > 0 {
                Text(theme.plural("kh_completed_count", count: plan.khatmasCompleted, theme.digits(String(plan.khatmasCompleted))))
                    .font(theme.scaledFont(size: 12.5, weight: .bold))
                    .foregroundStyle(theme.primary)
            }
            Button {
                khatmaStore.end()
            } label: {
                Text(theme.t("kh_start_new"))
                    .font(theme.scaledFont(size: 14.5, weight: .bold))
                    .foregroundStyle(theme.onPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(theme.primary, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .sirajCardSurface(cornerRadius: 24)
    }

    private func scheduleRow(_ day: KhatmaDayPortion) -> some View {
        Button {
            let edition = MushafEdition.resolve(appState.settings.mushafEdition)
            let targetPage = edition == .madinah ? day.startPage : appState.quranStore.pageForAyah(surah: day.startSurahNumber, ayah: 1, edition: edition)
            onOpenReader(ReaderDestination(page: targetPage, surahNumber: day.startSurahNumber, ayahNumber: 1))
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(day.isComplete ? theme.primary : (day.isToday ? theme.primary.opacity(0.18) : theme.surfaceVariant.opacity(0.6)))
                        .frame(width: 34, height: 34)
                    if day.isComplete {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(theme.onPrimary)
                    } else {
                        Text(theme.digits(String(day.dayNumber)))
                            .font(theme.scaledFont(size: 12.5, weight: .bold))
                            .foregroundStyle(day.isToday ? theme.primary : theme.onSurfaceVariant)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(theme.t("kh_day_n", theme.digits(String(day.dayNumber))))
                            .font(theme.scaledFont(size: 14, weight: .bold))
                            .foregroundStyle(day.isToday ? theme.primary : theme.onSurface)
                        if day.isToday {
                            Text(theme.t("kh_due_today"))
                                .font(theme.scaledFont(size: 10.5, weight: .bold))
                                .foregroundStyle(theme.onPrimary)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(theme.primary, in: Capsule())
                        }
                    }
                    Text(theme.t("kh_pages_range", theme.digits(String(day.startPage)), theme.digits(String(day.endPage))))
                        .font(theme.scaledFont(size: 12.5))
                        .foregroundStyle(theme.onSurfaceVariant)
                }

                Spacer()

                Image(systemName: theme.isRTL ? "chevron.left" : "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.outline)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .sirajCardSurface(cornerRadius: 16)
        }
        .buttonStyle(.plain)
    }
}
