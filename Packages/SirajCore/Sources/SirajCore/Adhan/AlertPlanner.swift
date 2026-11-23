import Foundation

public struct CustomReminder: Identifiable, Codable, Sendable, Equatable {
    public let id: String
    public var title: String
    public var hour: Int
    public var minute: Int
    public var isEnabled: Bool
    /// 1 = Sunday .. 7 = Saturday; empty means every day.
    public var weekdays: [Int]

    public init(
        id: String = UUID().uuidString,
        title: String,
        hour: Int,
        minute: Int,
        isEnabled: Bool = true,
        weekdays: [Int] = []
    ) {
        self.id = id
        self.title = title
        self.hour = hour
        self.minute = minute
        self.isEnabled = isEnabled
        self.weekdays = weekdays
    }
}

public enum AlertKind: Codable, Sendable, Equatable, Hashable {
    case prayer
    case prePrayer
    case suggested(String)
    case custom(String)

    public var keyTag: String {
        switch self {
        case .prayer: return "prayer"
        case .prePrayer: return "pre"
        case .suggested(let id): return "suggested_\(id)"
        case .custom(let id): return "custom_\(id)"
        }
    }
}

public struct PlannedAlert: Sendable, Equatable, Identifiable {
    public let id: String
    public let kind: AlertKind
    public let prayer: PrayerType?
    public let fireDate: Date
    public let prayerTime: Date?
    public let titleKey: String
    public let soundFileName: String?

    public init(
        id: String,
        kind: AlertKind,
        prayer: PrayerType?,
        fireDate: Date,
        prayerTime: Date?,
        titleKey: String,
        soundFileName: String?
    ) {
        self.id = id
        self.kind = kind
        self.prayer = prayer
        self.fireDate = fireDate
        self.prayerTime = prayerTime
        self.titleKey = titleKey
        self.soundFileName = soundFileName
    }
}

public enum PrePrayerReminder {
    public static let off = 0
    public static let options: [Int] = [0, 5, 10, 15, 30]

    public static func normalize(_ minutes: Int) -> Int {
        options.contains(minutes) ? minutes : off
    }
}

public struct AlertScheduleConfig: Sendable, Equatable {
    public var calculation: CalculationSettings
    public var prayerReminders: [String: Bool]
    public var prePrayerMinutes: Int
    public var alertMode: String // "azan", "notification", "silent"
    public var suggestedReminders: [String: Bool]
    public var suggestedTimes: [String: String]
    public var customReminders: [CustomReminder]

    public init(
        calculation: CalculationSettings = CalculationSettings(),
        prayerReminders: [String: Bool] = ["fajr": true, "sunrise": false, "dhuhr": true, "asr": true, "maghrib": true, "isha": true],
        prePrayerMinutes: Int = 0,
        alertMode: String = "azan",
        suggestedReminders: [String: Bool] = [:],
        suggestedTimes: [String: String] = [:],
        customReminders: [CustomReminder] = []
    ) {
        self.calculation = calculation
        self.prayerReminders = prayerReminders
        self.prePrayerMinutes = prePrayerMinutes
        self.alertMode = alertMode
        self.suggestedReminders = suggestedReminders
        self.suggestedTimes = suggestedTimes
        self.customReminders = customReminders
    }

    public func isAlertEnabled(for prayer: PrayerType) -> Bool {
        prayerReminders[prayer.lowercaseKey] ?? (prayer != .sunrise)
    }
}

public enum AlertPlanner {
    public static let maxIOSPendingNotifications = 64
    public static let graceSeconds: TimeInterval = 120

    public static func plan(
        config: AlertScheduleConfig,
        place: Place,
        now: Date,
        horizonDays: Int = 12,
        resolvedSound: (PrayerType) -> String? = { _ in AdhanCatalog.defaultBundledCaf }
    ) -> [PlannedAlert] {
        let today = place.today(at: now)
        let cutoff = now.addingTimeInterval(-graceSeconds)
        let lead = PrePrayerReminder.normalize(config.prePrayerMinutes)
        let isSilent = config.alertMode.lowercased() == "silent"
        let useAdhanClip = config.alertMode.lowercased() == "azan"

        var alerts: [PlannedAlert] = []
        var seen = Set<String>()

        for dayOffset in -1...max(1, horizonDays) {
            let civil = today.addingDays(dayOffset)
            let raw = PrayerCalculator.raw(place: place, date: civil, settings: config.calculation)

            for entry in raw {
                guard config.isAlertEnabled(for: entry.type) else { continue }
                let epochSec = Int64(entry.time.timeIntervalSince1970.rounded())
                let key = "\(entry.type.rawValue)|prayer|\(epochSec)"
                if entry.time >= cutoff, seen.insert(key).inserted {
                    let sound: String?
                    if isSilent || entry.type == .sunrise {
                        sound = nil
                    } else if useAdhanClip {
                        sound = resolvedSound(entry.type)
                    } else {
                        sound = nil
                    }
                    alerts.append(PlannedAlert(
                        id: key,
                        kind: .prayer,
                        prayer: entry.type,
                        fireDate: entry.time,
                        prayerTime: entry.time,
                        titleKey: entry.type.stringKey,
                        soundFileName: sound
                    ))
                }

                // Sunrise has no adhan, so no pre-prayer reminder either.
                if lead > 0 && entry.type != .sunrise {
                    let preTime = entry.time.addingTimeInterval(TimeInterval(-lead * 60))
                    let preKey = "\(entry.type.rawValue)|pre|\(epochSec)"
                    if preTime >= cutoff && preTime < entry.time, seen.insert(preKey).inserted {
                        alerts.append(PlannedAlert(
                            id: preKey,
                            kind: .prePrayer,
                            prayer: entry.type,
                            fireDate: preTime,
                            prayerTime: entry.time,
                            titleKey: entry.type.stringKey,
                            soundFileName: nil
                        ))
                    }
                }
            }

            // Suggested daily/weekly reminders (Duha, Qiyam, Kahf on Friday, Azkar, etc.)
            for (remId, enabled) in config.suggestedReminders where enabled {
                if remId == "surat_kahf" && civil.weekdaySundayZero != 5 { continue }
                let timeStr = config.suggestedTimes[remId] ?? "09:00"
                let (h, m) = parseHourMinute(timeStr)
                let fire = Zones.atLocal(date: civil, hour: h, minute: m, timeZone: place.timeZone)
                let key = "suggested|\(remId)|\(Int64(fire.timeIntervalSince1970.rounded()))"
                if fire >= cutoff, seen.insert(key).inserted {
                    alerts.append(PlannedAlert(
                        id: key,
                        kind: .suggested(remId),
                        prayer: nil,
                        fireDate: fire,
                        prayerTime: nil,
                        titleKey: "reminder_\(remId)",
                        soundFileName: nil
                    ))
                }
            }

            // Custom reminders
            for custom in config.customReminders where custom.isEnabled {
                let weekday = civil.weekdaySundayZero + 1 // 1=Sun..7=Sat
                if !custom.weekdays.isEmpty && !custom.weekdays.contains(weekday) { continue }
                let fire = Zones.atLocal(date: civil, hour: custom.hour, minute: custom.minute, timeZone: place.timeZone)
                let key = "custom|\(custom.id)|\(Int64(fire.timeIntervalSince1970.rounded()))"
                if fire >= cutoff, seen.insert(key).inserted {
                    alerts.append(PlannedAlert(
                        id: key,
                        kind: .custom(custom.id),
                        prayer: nil,
                        fireDate: fire,
                        prayerTime: nil,
                        titleKey: custom.title,
                        soundFileName: nil
                    ))
                }
            }
        }

        alerts.sort { lhs, rhs in
            if lhs.fireDate != rhs.fireDate { return lhs.fireDate < rhs.fireDate }
            return lhs.id < rhs.id
        }
        return Array(alerts.prefix(maxIOSPendingNotifications))
    }

    private static func parseHourMinute(_ text: String) -> (Int, Int) {
        let parts = text.split(separator: ":")
        let h = parts.count > 0 ? (Int(parts[0]) ?? 9) : 9
        let m = parts.count > 1 ? (Int(parts[1]) ?? 0) : 0
        return (min(23, max(0, h)), min(59, max(0, m)))
    }
}
