import Foundation
import WidgetKit
import SirajCore

struct FastWindowSnapshot {
    let suhoorTime: Date
    let iftarTime: Date
    let targetDate: Date
    let isIftarNext: Bool
    let isTomorrowFast: Bool
    let progress: Double
}

struct SirajWidgetSnapshot: TimelineEntry {
    let date: Date
    let settings: SettingsSnapshot
    let place: Place
    let day: PrayerDay
    let previousPrayer: PrayerTimeEntry?
    let nextPrayer: PrayerTimeEntry
    let hijri: HijriDate
    let moon: MoonPhaseInfo
    let nextOccasion: DatedOccasion?
    let language: String
    let isRTL: Bool
    let progressToNext: Double
    let currentPrayerIndex: Int
    let fastWindow: FastWindowSnapshot
    let readingPosition: ReadingPosition?
    let widgetTasbihCount: Int
}

enum WidgetDataLoader {
    static let localizer = SirajLocalizer(bundle: .main, subdirectory: "Data")

    static func userStore() -> UserDataStore {
        let appGroup = Bundle.main.object(forInfoDictionaryKey: "SirajAppGroupID") as? String
        return UserDataStore(appGroupId: appGroup)
    }

    static func loadSettings() -> SettingsSnapshot {
        userStore().loadSettings()
    }

    static func snapshot(at date: Date, settings: SettingsSnapshot? = nil) -> SirajWidgetSnapshot {
        let store = userStore()
        let snap = settings ?? store.loadSettings()
        let place = snap.cachedLocation ?? .cairoDefault
        let day = PrayerCalculator.today(place: place, settings: snap.calculationSettings, now: date)
        let cal = SirajHijriCalendar.forSettings(
            method: snap.hijriMethod,
            countryCode: place.resolvedCountryCode,
            adjustment: snap.hijriAdjustment
        )
        let civil = place.today(at: date)
        let hijri = cal.toHijri(civil)
        let moon = MoonPhase.at(date)
        let occasion = IslamicOccasions.upcoming(from: civil, calendar: cal).first

        let next = PrayerCalculator.nextUpcoming(place: place, settings: snap.calculationSettings, now: date)
        let prev = previousEntry(in: day, before: date, place: place, calc: snap.calculationSettings)
        let progress: Double = {
            guard let prev else { return 0.5 }
            let span = next.time.timeIntervalSince(prev.time)
            guard span > 60 else { return 0.5 }
            return min(1.0, max(0.0, date.timeIntervalSince(prev.time) / span))
        }()

        let prayerIndex = day.entries.lastIndex(where: { $0.time <= date }) ?? 0
        let fast = computeFastWindow(date: date, day: day, place: place, calc: snap.calculationSettings)

        return SirajWidgetSnapshot(
            date: date,
            settings: snap,
            place: place,
            day: day,
            previousPrayer: prev,
            nextPrayer: next,
            hijri: hijri,
            moon: moon,
            nextOccasion: occasion,
            language: snap.language,
            isRTL: localizer.isRTL(snap.language),
            progressToNext: progress,
            currentPrayerIndex: prayerIndex,
            fastWindow: fast,
            readingPosition: store.loadReadingPosition(),
            widgetTasbihCount: store.loadWidgetTasbihCount()
        )
    }

    // Schedules refreshes at each prayer transition plus 15-minute progress checkpoints so
    // Lock Screen gauges and Home Screen faces advance offline for a full 24 hours.
    static func timelineDates(from now: Date, settings: SettingsSnapshot, include15MinTicks: Bool, includeHourlyTicks: Bool = false) -> [Date] {
        let place = settings.cachedLocation ?? .cairoDefault
        let today = place.today(at: now)
        var dates = Set<Int64>()
        dates.insert(Int64(now.timeIntervalSince1970))

        for offset in 0...1 {
            let entries = PrayerCalculator.raw(place: place, date: today.addingDays(offset), settings: settings.calculationSettings)
            for e in entries {
                if e.time > now && e.time < now.addingTimeInterval(26 * 3600) {
                    dates.insert(Int64(e.time.timeIntervalSince1970) + 1)
                }
                if let iq = e.iqama, iq > now && iq < now.addingTimeInterval(26 * 3600) {
                    dates.insert(Int64(iq.timeIntervalSince1970) + 1)
                }
                if e.windowEnd > now && e.windowEnd < now.addingTimeInterval(26 * 3600) {
                    dates.insert(Int64(e.windowEnd.timeIntervalSince1970) + 1)
                }
            }
        }

        if include15MinTicks {
            let step: TimeInterval = 15 * 60
            var cursor = now.addingTimeInterval(step)
            let horizon = now.addingTimeInterval(8 * 3600)
            while cursor < horizon {
                dates.insert(Int64(cursor.timeIntervalSince1970))
                cursor = cursor.addingTimeInterval(step)
            }
        } else if includeHourlyTicks {
            let startHour = floor(now.timeIntervalSince1970 / 3600.0) * 3600.0
            for h in 1...18 {
                let ts = Int64(startHour) + Int64(h) * 3600 + 1
                dates.insert(ts)
            }
        }

        return dates.sorted().prefix(48).map { Date(timeIntervalSince1970: TimeInterval($0)) }
    }

    static func t(_ key: String, lang: String) -> String {
        localizer.string(key, lang: lang)
    }

    static func tf(_ key: String, lang: String, _ args: Any...) -> String {
        localizer.formatArray(key, lang: lang, args: args)
    }

    static func formatClock(_ date: Date, snapshot: SirajWidgetSnapshot) -> String {
        TimeFormatter.formatTime(
            date,
            timeZone: snapshot.place.timeZone,
            hourFormat: snapshot.settings.hourFormat,
            numeralSystem: snapshot.settings.numeralSystem,
            lang: snapshot.language
        )
    }

    static func digits(_ raw: String, snapshot: SirajWidgetSnapshot) -> String {
        DigitFormatter.localizeDigits(
            raw,
            numeralSystem: snapshot.settings.numeralSystem,
            lang: snapshot.language
        )
    }

    private static func previousEntry(
        in day: PrayerDay,
        before now: Date,
        place: Place,
        calc: CalculationSettings
    ) -> PrayerTimeEntry? {
        if let lastPast = day.entries.last(where: { $0.time <= now }) {
            return lastPast
        }
        let yesterday = PrayerCalculator.raw(place: place, date: day.date.addingDays(-1), settings: calc)
        return yesterday.last
    }

    private static func computeFastWindow(
        date: Date,
        day: PrayerDay,
        place: Place,
        calc: CalculationSettings
    ) -> FastWindowSnapshot {
        let todayFajr = day[.fajr].time
        let todayMaghrib = day[.maghrib].time

        if date < todayFajr {
            // Before Fajr: night before today's fast, counting down to Suhoor end.
            let yesterday = PrayerCalculator.raw(place: place, date: day.date.addingDays(-1), settings: calc)
            let prevMaghrib = yesterday.first(where: { $0.type == .maghrib })?.time ?? todayFajr.addingTimeInterval(-10 * 3600)
            let span = max(60, todayFajr.timeIntervalSince(prevMaghrib))
            let prog = min(1.0, max(0.0, date.timeIntervalSince(prevMaghrib) / span))
            return FastWindowSnapshot(
                suhoorTime: todayFajr,
                iftarTime: todayMaghrib,
                targetDate: todayFajr,
                isIftarNext: false,
                isTomorrowFast: false,
                progress: prog
            )
        } else if date < todayMaghrib {
            // Between Fajr and Maghrib: actively fasting, counting down to Iftar.
            let span = max(60, todayMaghrib.timeIntervalSince(todayFajr))
            let prog = min(1.0, max(0.0, date.timeIntervalSince(todayFajr) / span))
            return FastWindowSnapshot(
                suhoorTime: todayFajr,
                iftarTime: todayMaghrib,
                targetDate: todayMaghrib,
                isIftarNext: true,
                isTomorrowFast: false,
                progress: prog
            )
        } else {
            // After Maghrib: show tomorrow's Suhoor and Iftar.
            let tomorrowEntries = PrayerCalculator.raw(place: place, date: day.date.addingDays(1), settings: calc)
            let nextFajr = tomorrowEntries.first(where: { $0.type == .fajr })?.time ?? todayFajr.addingTimeInterval(24 * 3600)
            let nextMaghrib = tomorrowEntries.first(where: { $0.type == .maghrib })?.time ?? todayMaghrib.addingTimeInterval(24 * 3600)
            let span = max(60, nextFajr.timeIntervalSince(todayMaghrib))
            let prog = min(1.0, max(0.0, date.timeIntervalSince(todayMaghrib) / span))
            return FastWindowSnapshot(
                suhoorTime: nextFajr,
                iftarTime: nextMaghrib,
                targetDate: nextFajr,
                isIftarNext: false,
                isTomorrowFast: true,
                progress: prog
            )
        }
    }
}
