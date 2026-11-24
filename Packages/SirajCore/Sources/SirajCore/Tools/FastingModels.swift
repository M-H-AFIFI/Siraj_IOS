import Foundation

public enum FastingType: String, Codable, Sendable, CaseIterable {
    case required = "REQUIRED"
    case sunnah = "SUNNAH"
    case nafil = "NAFIL"
    case kaffah = "KAFFAH"

    public var labelKey: String {
        switch self {
        case .required: return "fasting_type_ramadan"
        case .sunnah: return "fasting_type_sunnah"
        case .nafil: return "fasting_type_nafil"
        case .kaffah: return "fasting_type_kaffah"
        }
    }
}

public struct FastingLogEntry: Codable, Sendable, Equatable, Identifiable {
    public let dateISO: String
    public var isFasting: Bool
    public var type: FastingType
    public var note: String?

    public var id: String { dateISO }

    public init(dateISO: String, isFasting: Bool, type: FastingType = .nafil, note: String? = nil) {
        self.dateISO = dateISO
        self.isFasting = isFasting
        self.type = type
        self.note = note
    }
}

public enum FastingOccasionType: String, Sendable, Equatable {
    case monday
    case thursday
    case whiteDays
    case ashura
    case arafah
    case ramadan

    public var titleKey: String {
        switch self {
        case .monday: return "fasting_monday_sunnah"
        case .thursday: return "fasting_thursday_sunnah"
        case .whiteDays: return "fasting_white_days"
        case .ashura: return "fasting_ashura"
        case .arafah: return "fasting_arafah"
        case .ramadan: return "fasting_ramadan"
        }
    }
}

public struct UpcomingFast: Sendable, Equatable, Identifiable {
    public let id: String
    public let type: FastingOccasionType
    public let targetDate: CivilDate
    public let hijriDay: Int
    public let hijriMonth: Int
    public let daysAway: Int

    public init(
        type: FastingOccasionType,
        targetDate: CivilDate,
        hijriDay: Int = 0,
        hijriMonth: Int = 0,
        daysAway: Int
    ) {
        self.id = "\(type.rawValue)_\(targetDate.dayNumber)"
        self.type = type
        self.targetDate = targetDate
        self.hijriDay = hijriDay
        self.hijriMonth = hijriMonth
        self.daysAway = daysAway
    }
}

public struct FastingPrefs: Codable, Sendable, Equatable {
    public var logs: [FastingLogEntry]
    public var isReminderEnabled: Bool

    public init(logs: [FastingLogEntry] = [], isReminderEnabled: Bool = false) {
        self.logs = logs
        self.isReminderEnabled = isReminderEnabled
    }
}

public enum FastingPlanner {
    public static func dateISO(_ civil: CivilDate) -> String {
        String(format: "%04d-%02d-%02d", civil.year, civil.month, civil.day)
    }

    public static func parseISO(_ iso: String) -> CivilDate? {
        let parts = iso.split(separator: "-")
        guard parts.count == 3,
              let y = Int(parts[0]),
              let m = Int(parts[1]),
              let d = Int(parts[2]) else { return nil }
        return CivilDate(year: y, month: m, day: d)
    }

    public static func calculateStreak(logs: [FastingLogEntry], today: CivilDate) -> Int {
        let fastedSet = Set(logs.filter(\.isFasting).map(\.dateISO))
        var streak = 0
        var cursor = today
        while fastedSet.contains(dateISO(cursor)) {
            streak += 1
            cursor = cursor.addingDays(-1)
        }
        return streak
    }

    public static func computeUpcoming(from today: CivilDate, calendar: SirajHijriCalendar) -> [UpcomingFast] {
        var results: [UpcomingFast] = []
        let hijriNow = calendar.toHijri(today)

        // Day of week: CivilDate dayNumber % 7 -> let's derive Sunday=0..Saturday=6 from known Thursday 1970-01-01 (day 4).
        let todayDow = weekdaySun0(today)
        let daysToMonday = (1 - todayDow + 7) % 7
        results.append(UpcomingFast(type: .monday, targetDate: today.addingDays(daysToMonday), daysAway: daysToMonday))

        let daysToThursday = (4 - todayDow + 7) % 7
        results.append(UpcomingFast(type: .thursday, targetDate: today.addingDays(daysToThursday), daysAway: daysToThursday))

        let ashuraDate = nextHijriDate(month: 1, day: 10, from: hijriNow, calendar: calendar)
        results.append(UpcomingFast(
            type: .ashura,
            targetDate: ashuraDate,
            hijriDay: 10,
            hijriMonth: 1,
            daysAway: ashuraDate.dayNumber - today.dayNumber
        ))

        let arafahDate = nextHijriDate(month: 12, day: 9, from: hijriNow, calendar: calendar)
        results.append(UpcomingFast(
            type: .arafah,
            targetDate: arafahDate,
            hijriDay: 9,
            hijriMonth: 12,
            daysAway: arafahDate.dayNumber - today.dayNumber
        ))

        let ramadanDate = nextHijriDate(month: 9, day: 1, from: hijriNow, calendar: calendar)
        results.append(UpcomingFast(
            type: .ramadan,
            targetDate: ramadanDate,
            hijriDay: 1,
            hijriMonth: 9,
            daysAway: ramadanDate.dayNumber - today.dayNumber
        ))

        // Nearest White Day (13-15 of non-Ramadan months, excluding 13 Dhul-Hijjah).
        var nearestWhite: UpcomingFast?
        for yearOffset in 0...1 {
            for month in 1...12 where month != 9 {
                for day in 13...15 where !(month == 12 && day == 13) {
                    let g = calendar.toGregorian(year: hijriNow.year + yearOffset, month: month, day: day)
                    let diff = g.dayNumber - today.dayNumber
                    if diff >= 0 && diff <= 90 {
                        let candidate = UpcomingFast(type: .whiteDays, targetDate: g, hijriDay: day, hijriMonth: month, daysAway: diff)
                        if nearestWhite == nil || candidate.daysAway < nearestWhite!.daysAway {
                            nearestWhite = candidate
                        }
                    }
                }
            }
        }
        if let nearestWhite {
            results.append(nearestWhite)
        }

        return results.filter { $0.daysAway >= 0 }.sorted { $0.daysAway < $1.daysAway }
    }

    public static func weekdaySun0(_ date: CivilDate) -> Int {
        // 1970-01-01 was Thursday (4).
        let delta = date.dayNumber - CivilDate.unixEpochDayNumber
        return ((4 + delta) % 7 + 7) % 7
    }

    private static func nextHijriDate(month: Int, day: Int, from now: HijriDate, calendar: SirajHijriCalendar) -> CivilDate {
        var year = now.year
        if now.month > month || (now.month == month && now.day > day) {
            year += 1
        }
        return calendar.toGregorian(year: year, month: month, day: day)
    }
}
