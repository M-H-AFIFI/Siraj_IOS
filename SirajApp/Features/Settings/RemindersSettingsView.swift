import SwiftUI
import SirajCore

private enum AlertModeOption: String, CaseIterable, Identifiable {
    case azan
    case notification
    case silent

    var id: String { rawValue }
}

private struct SuggestedItem: Identifiable {
    let id: String
    let icon: String
    let titleKey: String
    let descKey: String
}

struct RemindersSettingsView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    let audioEngine: AdhanAudioEngine
    let scheduler: AdhanNotificationScheduler
    let onOpenWidgets: () -> Void

    @State private var editingSuggestedId: String?
    @State private var showNewReminderSheet = false
    @State private var newReminderTitle = ""
    @State private var newReminderHour = 21
    @State private var newReminderMinute = 0
    @State private var showVoicePicker = false
    @State private var showFajrPicker = false
    @State private var notificationsDenied = false
    @State private var draftVolume: Double = 0.85

    private let suggestedItems: [SuggestedItem] = [
        SuggestedItem(id: "duha", icon: "sun.max.fill", titleKey: "reminders_duha_title", descKey: "reminders_duha_desc"),
        SuggestedItem(id: "qiyam", icon: "moon.stars.fill", titleKey: "reminders_qiyam_title", descKey: "reminders_qiyam_desc"),
        SuggestedItem(id: "surat_kahf", icon: "book.fill", titleKey: "reminders_kahf_title", descKey: "reminders_kahf_desc"),
        SuggestedItem(id: "morning_azkar", icon: "sunrise.fill", titleKey: "reminders_morning_azkar_title", descKey: "reminders_morning_azkar_desc"),
        SuggestedItem(id: "evening_azkar", icon: "sunset.fill", titleKey: "reminders_evening_azkar_title", descKey: "reminders_evening_azkar_desc"),
        SuggestedItem(id: "fasting_days", icon: "moon.fill", titleKey: "reminders_fasting_days_title", descKey: "reminders_fasting_days_desc"),
        SuggestedItem(id: "daily_reading", icon: "book.pages.fill", titleKey: "reminders_daily_reading_title", descKey: "reminders_daily_reading_desc"),
        SuggestedItem(id: "verse_day", icon: "sparkles", titleKey: "reminders_verse_day_title", descKey: "reminders_verse_day_desc")
    ]

    var body: some View {
        let modeBinding = Binding<AlertModeOption>(
            get: { AlertModeOption(rawValue: appState.settings.azanReminderType.lowercased()) ?? .azan },
            set: { val in appState.updateSettings { $0.azanReminderType = val.rawValue } }
        )
        let activeVoice = AdhanVoiceResolver.findVoice(appState.settings.azanSound)
        let activeFajr = AdhanVoiceResolver.fajrVoice(
            for: appState.settings.azanSound,
            preferredFajrId: appState.settings.fajrAdhanVoice
        )

        ScrollView {
            VStack(spacing: 20) {
                if notificationsDenied {
                    notificationPermissionBanner
                }

                SirajSettingsSection(title: theme.t("reminders_alert_type_section")) {
                    VStack(spacing: 14) {
                        SirajSegmentedPills(options: AlertModeOption.allCases, selection: modeBinding) { mode in
                            switch mode {
                            case .azan: return theme.t("reminders_mode_full_azan")
                            case .notification: return theme.t("reminders_mode_tone_only")
                            case .silent: return theme.t("reminders_mode_silent")
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 14)

                        Text(theme.t("ios_notification_sound_note"))
                            .font(theme.scaledFont(size: 12))
                            .foregroundStyle(theme.onSurfaceVariant)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)

                        Divider().padding(.leading, 16)

                        SirajSettingsRow(
                            icon: "speaker.wave.2.fill",
                            title: theme.t("reminders_selected_sound"),
                            value: activeVoice.localizedTitle(language: theme.language)
                        ) {
                            showVoicePicker = true
                        }

                        Divider().padding(.leading, 16)

                        SirajSettingsToggleRow(
                            icon: "sun.horizon.fill",
                            title: theme.t("fajr_adhan_title"),
                            subtitle: theme.t("fajr_adhan_body"),
                            isOn: Binding(
                                get: { appState.settings.fajrAdhanEnabled },
                                set: { v in appState.updateSettings { $0.fajrAdhanEnabled = v } }
                            )
                        )

                        if appState.settings.fajrAdhanEnabled {
                            Divider().padding(.leading, 16)
                            SirajSettingsRow(
                                icon: "music.note",
                                title: theme.t("fajr_adhan_change"),
                                value: activeFajr.localizedTitle(language: theme.language)
                            ) {
                                showFajrPicker = true
                            }
                        }

                        Divider().padding(.leading, 16)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(theme.t("adhan_volume_title"))
                                    .font(theme.scaledFont(size: 14.5, weight: .semibold))
                                    .foregroundStyle(theme.onSurface)
                                Spacer()
                                Text(theme.digits("\(Int((draftVolume * 100).rounded()))%"))
                                    .font(theme.scaledFont(size: 13, weight: .bold))
                                    .foregroundStyle(theme.primary)
                            }
                            Slider(value: $draftVolume, in: 0.1...1.0) { editing in
                                if !editing {
                                    appState.updateSettings { $0.adhanVolume = draftVolume }
                                }
                            }
                            .tint(theme.primary)
                            .onChange(of: draftVolume) { _, val in
                                audioEngine.setVolume(val)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                        Divider().padding(.leading, 16)

                        SirajSettingsToggleRow(
                            icon: "rectangle.portrait.on.rectangle.portrait.fill",
                            title: theme.t("adhan_screen_setting_title"),
                            subtitle: theme.t("adhan_screen_setting_body"),
                            isOn: Binding(
                                get: { appState.settings.isAdhanScreenEnabled },
                                set: { v in appState.updateSettings { $0.isAdhanScreenEnabled = v } }
                            )
                        )

                        if appState.settings.isAdhanScreenEnabled {
                            Divider().padding(.leading, 16)
                            SirajSettingsToggleRow(
                                icon: "sun.and.horizon.fill",
                                title: theme.t("adhan_match_prayer_title"),
                                subtitle: theme.t("adhan_match_prayer_body"),
                                isOn: Binding(
                                    get: { appState.settings.isAdhanScreenMatchPrayer },
                                    set: { v in appState.updateSettings { $0.isAdhanScreenMatchPrayer = v } }
                                )
                            )
                        }

                        Divider().padding(.leading, 16)

                        Button {
                            appState.isAdhanAlertTest = true
                            appState.activeAdhanAlert = appState.prayerDay.next?.type ?? .fajr
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "play.fill")
                                Text(theme.t("reminders_test_notification_title"))
                                    .font(theme.scaledFont(size: 14.5, weight: .bold))
                            }
                            .foregroundStyle(theme.onPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(theme.primary))
                            .padding(.horizontal, 16)
                            .padding(.bottom, 14)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("test_adhan_button")
                    }
                }

                SirajSettingsSection(title: theme.t("prayer_reminders_header")) {
                    ForEach(Array(PrayerType.allCases.enumerated()), id: \.element.id) { idx, prayer in
                        let key = prayer.lowercaseKey
                        let isOn = Binding<Bool>(
                            get: { appState.settings.prayerReminders[key] ?? (prayer != .sunrise) },
                            set: { val in appState.updateSettings { $0.prayerReminders[key] = val } }
                        )
                        HStack(spacing: 12) {
                            Image(prayer.iconAssetName)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(theme.primary)
                                .frame(width: 34, height: 34)
                                .background(Circle().fill(theme.primary.opacity(0.12)))

                            Text(theme.t(prayer.stringKey))
                                .font(theme.scaledFont(size: 15, weight: .semibold))
                                .foregroundStyle(theme.onSurface)

                            Spacer()
                            SirajSwitch(isOn: isOn)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)

                        if idx < PrayerType.allCases.count - 1 {
                            Divider().padding(.leading, 16)
                        }
                    }
                }

                SirajSettingsSection(title: theme.t("pre_prayer_title")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(theme.t("pre_prayer_desc_off"))
                            .font(theme.scaledFont(size: 12.5))
                            .foregroundStyle(theme.onSurfaceVariant)

                        HStack(spacing: 8) {
                            ForEach(PrePrayerReminder.options, id: \.self) { mins in
                                let active = appState.settings.prePrayerReminderMinutes == mins
                                Button {
                                    appState.updateSettings { $0.prePrayerReminderMinutes = mins }
                                } label: {
                                    Text(mins == 0 ? theme.t("pre_prayer_off") : theme.tf("pre_prayer_minutes_short", theme.digits("\(mins)")))
                                        .font(theme.scaledFont(size: 12.5, weight: active ? .bold : .medium))
                                        .foregroundStyle(active ? theme.onPrimary : theme.onSurface)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 9)
                                        .background(Capsule().fill(active ? theme.primary : theme.surfaceVariant))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(16)
                }

                SirajSettingsSection(title: theme.t("ios_live_activity_title")) {
                    SirajSettingsToggleRow(
                        icon: "timer",
                        title: theme.t("ios_live_activity_title"),
                        subtitle: theme.t("ios_live_activity_desc"),
                        isOn: Binding(
                            get: { appState.settings.liveActivityEnabled },
                            set: { v in appState.updateSettings { $0.liveActivityEnabled = v } }
                        )
                    )
                    Divider().padding(.leading, 16)
                    SirajSettingsRow(
                        icon: "square.grid.2x2.fill",
                        title: theme.t("widget_gallery_browse"),
                        subtitle: theme.t("ios_lockscreen_widget_desc"),
                        action: onOpenWidgets
                    )
                }

                SirajSettingsSection(title: theme.t("reminders_suggested_header")) {
                    ForEach(Array(suggestedItems.enumerated()), id: \.element.id) { idx, item in
                        let enabled = Binding<Bool>(
                            get: { appState.settings.suggestedReminders[item.id] ?? false },
                            set: { v in appState.updateSettings { $0.suggestedReminders[item.id] = v } }
                        )
                        let timeStr = appState.settings.suggestedTimes[item.id] ?? "09:00"
                        HStack(spacing: 12) {
                            Image(systemName: item.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(theme.primary)
                                .frame(width: 34, height: 34)
                                .background(Circle().fill(theme.primary.opacity(0.12)))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(theme.t(item.titleKey))
                                    .font(theme.scaledFont(size: 14.5, weight: .semibold))
                                    .foregroundStyle(theme.onSurface)
                                Text(theme.t(item.descKey))
                                    .font(theme.scaledFont(size: 11.5))
                                    .foregroundStyle(theme.onSurfaceVariant)
                                    .lineLimit(2)
                            }
                            Spacer(minLength: 6)

                            Button {
                                editingSuggestedId = item.id
                            } label: {
                                Text(formatTimeLabel(timeStr))
                                    .font(theme.scaledFont(size: 12, weight: .bold))
                                    .foregroundStyle(theme.primary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Capsule().fill(theme.primary.opacity(0.12)))
                            }
                            .buttonStyle(.plain)

                            SirajSwitch(isOn: enabled)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)

                        if idx < suggestedItems.count - 1 {
                            Divider().padding(.leading, 16)
                        }
                    }
                }

                SirajSettingsSection(title: theme.t("reminders_custom_header")) {
                    if appState.settings.customReminders.isEmpty {
                        Text(theme.t("reminders_empty_custom"))
                            .font(theme.scaledFont(size: 13))
                            .foregroundStyle(theme.onSurfaceVariant)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                    } else {
                        ForEach(Array(appState.settings.customReminders.enumerated()), id: \.element.id) { idx, rem in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(rem.title)
                                        .font(theme.scaledFont(size: 14.5, weight: .semibold))
                                        .foregroundStyle(theme.onSurface)
                                    Text(formatTimeLabel(String(format: "%02d:%02d", rem.hour, rem.minute)))
                                        .font(theme.scaledFont(size: 12))
                                        .foregroundStyle(theme.onSurfaceVariant)
                                }
                                Spacer()
                                SirajSwitch(isOn: Binding(
                                    get: { rem.isEnabled },
                                    set: { val in
                                        appState.updateSettings { snap in
                                            if let i = snap.customReminders.firstIndex(where: { $0.id == rem.id }) {
                                                snap.customReminders[i].isEnabled = val
                                            }
                                        }
                                    }
                                ))
                                Button {
                                    appState.updateSettings { snap in
                                        snap.customReminders.removeAll { $0.id == rem.id }
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14))
                                        .foregroundStyle(theme.outline)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            if idx < appState.settings.customReminders.count - 1 {
                                Divider().padding(.leading, 16)
                            }
                        }
                    }

                    Divider().padding(.leading, 16)
                    Button {
                        newReminderTitle = ""
                        newReminderHour = 21
                        newReminderMinute = 0
                        showNewReminderSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text(theme.t("reminders_add_custom"))
                                .font(theme.scaledFont(size: 14.5, weight: .bold))
                        }
                        .foregroundStyle(theme.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 108)
        }
        .background(Color.clear)
        .navigationTitle(theme.t("settings_reminders"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showVoicePicker) {
            AdhanVoicePickerView(appState: appState, audioEngine: audioEngine, isFajrMode: false)
        }
        .navigationDestination(isPresented: $showFajrPicker) {
            AdhanVoicePickerView(appState: appState, audioEngine: audioEngine, isFajrMode: true)
        }
        .sheet(item: Binding(
            get: { editingSuggestedId.map { SuggestedTimeTarget(id: $0) } },
            set: { editingSuggestedId = $0?.id }
        )) { target in
            let current = appState.settings.suggestedTimes[target.id] ?? "09:00"
            let (h, m) = parseHM(current)
            MihrabTimePickerSheet(title: theme.t("reminders_time_picker_title"), hour: h, minute: m) { hour, minute in
                let formatted = String(format: "%02d:%02d", hour, minute)
                appState.updateSettings {
                    $0.suggestedTimes[target.id] = formatted
                    $0.suggestedReminders[target.id] = true
                }
            }
        }
        .sheet(isPresented: $showNewReminderSheet) {
            newCustomReminderSheet
        }
        .task {
            draftVolume = appState.settings.adhanVolume
            let status = await scheduler.authorizationStatus()
            notificationsDenied = (status == .denied)
        }
    }

    private var notificationPermissionBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.slash.fill")
                .foregroundStyle(.orange)
            Text(theme.t("onboarding_alerts_blocked"))
                .font(theme.scaledFont(size: 13))
                .foregroundStyle(theme.onSurface)
            Spacer()
            Button(theme.t("onboarding_alerts_open_settings")) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(theme.scaledFont(size: 13, weight: .bold))
            .foregroundStyle(theme.primary)
        }
        .padding(14)
        .sirajCardSurface(cornerRadius: 18)
    }

    private var newCustomReminderSheet: some View {
        NavigationStack {
            VStack(spacing: 18) {
                TextField(theme.t("reminders_title_hint"), text: $newReminderTitle)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.surfaceVariant))

                DatePicker(
                    theme.t("reminders_time_label"),
                    selection: Binding(
                        get: {
                            var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                            c.hour = newReminderHour
                            c.minute = newReminderMinute
                            return Calendar.current.date(from: c) ?? Date()
                        },
                        set: { date in
                            let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                            newReminderHour = c.hour ?? 21
                            newReminderMinute = c.minute ?? 0
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()

                Spacer()
            }
            .padding(20)
            .background(theme.background.ignoresSafeArea())
            .navigationTitle(theme.t("reminders_new_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(theme.t("settings_cancel")) { showNewReminderSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(theme.t("settings_save")) {
                        let clean = newReminderTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        let rem = CustomReminder(
                            title: clean.isEmpty ? theme.t("reminders_new_title") : clean,
                            hour: newReminderHour,
                            minute: newReminderMinute
                        )
                        appState.updateSettings { $0.customReminders.append(rem) }
                        showNewReminderSheet = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func parseHM(_ text: String) -> (Int, Int) {
        let parts = text.split(separator: ":")
        let h = parts.count > 0 ? (Int(parts[0]) ?? 9) : 9
        let m = parts.count > 1 ? (Int(parts[1]) ?? 0) : 0
        return (h, m)
    }

    private func formatTimeLabel(_ hm: String) -> String {
        let (h, m) = parseHM(hm)
        return TimeFormatter.formatTime(
            hour: h,
            minute: m,
            hourFormat: appState.settings.hourFormat,
            numeralSystem: appState.settings.numeralSystem,
            lang: theme.language
        )
    }
}

private struct SuggestedTimeTarget: Identifiable {
    let id: String
}
