import Foundation

public enum PrayerState: Sendable, Equatable {
    case upcomingAzan(prayer: PrayerTimeEntry, remaining: TimeInterval)
    case azanCalled(prayer: PrayerTimeEntry, sinceAzan: TimeInterval, iqamaTime: Date)
    case waitingForIqama(prayer: PrayerTimeEntry, iqamaTime: Date, untilIqama: TimeInterval, progress: Double)
    case inPrayer(prayer: PrayerTimeEntry, sinceIqama: TimeInterval)

    public var prayer: PrayerTimeEntry {
        switch self {
        case .upcomingAzan(let p, _),
             .azanCalled(let p, _, _),
             .waitingForIqama(let p, _, _, _),
             .inPrayer(let p, _):
            return p
        }
    }

    public static func at(day: PrayerDay, now: Date) -> PrayerState? {
        for entry in day.entries {
            if entry.type == .sunrise { continue }
            let start = entry.time
            let iqama = entry.iqama ?? start.addingTimeInterval(20 * 60)
            if now < start || now >= iqama.addingTimeInterval(15 * 60) { continue }

            if now < start.addingTimeInterval(2 * 60) {
                return .azanCalled(prayer: entry, sinceAzan: max(0, now.timeIntervalSince(start)), iqamaTime: iqama)
            }
            if now < iqama {
                let total = max(1.0, iqama.timeIntervalSince(start))
                let remaining = max(0.0, iqama.timeIntervalSince(now))
                let progress = min(1.0, max(0.0, (total - remaining) / total))
                return .waitingForIqama(prayer: entry, iqamaTime: iqama, untilIqama: remaining, progress: progress)
            }
            return .inPrayer(prayer: entry, sinceIqama: max(0, now.timeIntervalSince(iqama)))
        }

        let next = day.entries.first { $0.isNext && $0.time > now } ?? day.entries.first { $0.time > now }
        guard let next else { return nil }
        return .upcomingAzan(prayer: next, remaining: next.time.timeIntervalSince(now))
    }
}
