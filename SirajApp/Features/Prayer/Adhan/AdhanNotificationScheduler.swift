import BackgroundTasks
import Foundation
import UserNotifications
import SirajCore

@MainActor
final class AdhanNotificationScheduler: NSObject, UNUserNotificationCenterDelegate {
    static let categoryId = "SIRAJ_ADHAN"
    static let openActionId = "SIRAJ_OPEN_ADHAN"
    static let dismissActionId = "SIRAJ_DISMISS_ADHAN"

    static var refreshTaskIdentifier: String {
        let bundleId = Bundle.main.bundleIdentifier ?? "com.siiraj.app"
        return "\(bundleId).refresh-prayers"
    }

    var onOpenPrayerAlert: ((PrayerType) -> Void)?
    var onDismissAlert: (() -> Void)?
    var shouldOpenScreenInForeground: (() -> Bool)?

    private var hasRegisteredBGTask = false

    func configure(localizer: SirajLocalizer, language: String) {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        let openAction = UNNotificationAction(
            identifier: Self.openActionId,
            title: localizer.string("ios_open_adhan", lang: language),
            options: [.foreground]
        )
        let dismissAction = UNNotificationAction(
            identifier: Self.dismissActionId,
            title: localizer.string("ios_dismiss_adhan", lang: language),
            options: [.destructive]
        )
        let category = UNNotificationCategory(
            identifier: Self.categoryId,
            actions: [openAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    func reschedule(
        settings: SettingsSnapshot,
        place: Place,
        now: Date = Date(),
        localizer: SirajLocalizer,
        audioEngine: AdhanAudioEngine
    ) async {
        configure(localizer: localizer, language: settings.language)

        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let staleIds = pending.map(\.identifier).filter { $0.hasPrefix("siraj.") }
        if !staleIds.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: staleIds)
        }

        let alerts = AlertPlanner.plan(settings: settings, place: place, now: now) { prayer in
            audioEngine.resolvedNotificationSound(for: prayer, settings: settings)
        }

        let lang = settings.language
        let isSilent = settings.azanReminderType.lowercased() == "silent"
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = place.timeZone

        for alert in alerts {
            guard alert.fireDate > now else { continue }
            let content = UNMutableNotificationContent()
            content.interruptionLevel = .timeSensitive

            switch alert.kind {
            case .prayer:
                let prayer = alert.prayer ?? .fajr
                let prayerName = localizer.string(prayer.stringKey, lang: lang)
                let clock = TimeFormatter.formatTime(
                    alert.fireDate,
                    timeZone: place.timeZone,
                    hourFormat: settings.hourFormat,
                    numeralSystem: settings.numeralSystem,
                    lang: lang
                )
                content.title = prayerName
                content.body = "\(localizer.string("azan_time_now", lang: lang)) · \(clock)"
                content.categoryIdentifier = Self.categoryId
                content.userInfo = ["prayer": prayer.rawValue]
                if isSilent {
                    content.sound = nil
                } else if let soundFile = alert.soundFileName {
                    content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: soundFile))
                } else {
                    content.sound = .default
                }

            case .prePrayer:
                let prayer = alert.prayer ?? .fajr
                let prayerName = localizer.string(prayer.stringKey, lang: lang)
                let mins = DigitFormatter.localizeDigits(
                    String(settings.prePrayerReminderMinutes),
                    numeralSystem: settings.numeralSystem,
                    lang: lang
                )
                let clock = TimeFormatter.formatTime(
                    alert.prayerTime ?? alert.fireDate,
                    timeZone: place.timeZone,
                    hourFormat: settings.hourFormat,
                    numeralSystem: settings.numeralSystem,
                    lang: lang
                )
                content.title = localizer.plural("pre_prayer_notification_title", count: settings.prePrayerReminderMinutes, lang: lang, prayerName, mins)
                content.body = localizer.format("pre_prayer_notification_body", lang: lang, clock)
                content.sound = isSilent ? nil : .default

            case .suggested(let remId):
                let titleKey = Self.suggestedTitleKey(for: remId)
                let descKey = Self.suggestedDescKey(for: remId)
                content.title = localizer.string(titleKey, lang: lang)
                content.body = localizer.string(descKey, lang: lang)
                content.sound = .default

            case .custom:
                content.title = alert.titleKey.isEmpty ? localizer.string("settings_reminders", lang: lang) : alert.titleKey
                content.body = localizer.string("app_name", lang: lang)
                content.sound = .default
            }

            let comps = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: alert.fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(identifier: "siraj.\(alert.id)", content: content, trigger: trigger)
            try? await center.add(request)
        }

        scheduleBackgroundRefresh()
    }

    func registerBackgroundRefresh(handler: @escaping @MainActor () async -> Void) {
        guard !hasRegisteredBGTask else { return }
        hasRegisteredBGTask = true
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.refreshTaskIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            let work = Task { @MainActor in
                await handler()
                refreshTask.setTaskCompleted(success: true)
            }
            refreshTask.expirationHandler = {
                work.cancel()
            }
        }
    }

    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 12 * 3600)
        try? BGTaskScheduler.shared.submit(request)
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        let rawPrayer = notification.request.content.userInfo["prayer"] as? String
        if let rawPrayer, let prayer = PrayerType(rawValue: rawPrayer), prayer != .sunrise {
            let openScreen = await MainActor.run { self.shouldOpenScreenInForeground?() ?? true }
            if openScreen {
                await MainActor.run { self.onOpenPrayerAlert?(prayer) }
                return [.banner, .list]
            }
        }
        return [.banner, .sound, .list]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        if response.actionIdentifier == Self.dismissActionId {
            await MainActor.run { self.onDismissAlert?() }
            return
        }
        if let rawPrayer = response.notification.request.content.userInfo["prayer"] as? String,
           let prayer = PrayerType(rawValue: rawPrayer), prayer != .sunrise {
            await MainActor.run { self.onOpenPrayerAlert?(prayer) }
        }
    }

    static func suggestedTitleKey(for id: String) -> String {
        switch id {
        case "duha": return "reminders_duha_title"
        case "qiyam": return "reminders_qiyam_title"
        case "surat_kahf": return "reminders_kahf_title"
        case "morning_azkar": return "reminders_morning_azkar_title"
        case "evening_azkar": return "reminders_evening_azkar_title"
        case "fasting_days": return "reminders_fasting_days_title"
        case "daily_reading": return "reminders_daily_reading_title"
        case "verse_day": return "reminders_verse_day_title"
        default: return "settings_reminders"
        }
    }

    static func suggestedDescKey(for id: String) -> String {
        switch id {
        case "duha": return "reminders_duha_desc"
        case "qiyam": return "reminders_qiyam_desc"
        case "surat_kahf": return "reminders_kahf_desc"
        case "morning_azkar": return "reminders_morning_azkar_desc"
        case "evening_azkar": return "reminders_evening_azkar_desc"
        case "fasting_days": return "reminders_fasting_days_desc"
        case "daily_reading": return "reminders_daily_reading_desc"
        case "verse_day": return "reminders_verse_day_desc"
        default: return "app_name"
        }
    }
}
