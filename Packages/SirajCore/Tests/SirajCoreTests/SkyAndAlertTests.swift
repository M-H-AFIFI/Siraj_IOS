import Foundation
import XCTest
@testable import SirajCore

final class SkyAndAlertTests: XCTestCase {
    func testSkyTimelineSamplesFull24HoursAndHighLatitudeWithoutNaN() {
        let reykjavik = Place(latitude: 64.1466, longitude: -21.9426, cityName: "Reykjavik", timeZoneId: "Atlantic/Reykjavik", countryCode: "IS")
        let solstice = CivilDate(year: 2026, month: 6, day: 21)
        let entries = PrayerCalculator.raw(
            place: reykjavik,
            date: solstice,
            settings: CalculationSettings(method: "MuslimWorldLeague", madhab: "Shafi", highLatitudeRule: "MiddleOfTheNight")
        )
        let dayStart = solstice.utcMidnight
        for step in 0..<96 {
            let instant = dayStart.addingTimeInterval(TimeInterval(step * 15 * 60))
            let moment = SkyTimeline.at(instant, prayers: entries)
            XCTAssertEqual(moment.colors.sky.count, 6)
            XCTAssertFalse(moment.colors.cloudAlpha.isNaN)
            XCTAssertFalse(moment.colors.starAlpha.isNaN)
            XCTAssertFalse(moment.twilight.shafaq.isNaN)
            let arc = SolarArc.at(instant, prayers: entries)
            XCTAssertTrue((0.08...0.92).contains(arc.progress))
        }
    }

    func testAlertPlannerCapsAt64PrioritizesSoonestAndDropsStaleOver2Minutes() throws {
        let cairo = Place.cairoDefault
        let date = CivilDate(year: 2026, month: 5, day: 15)
        let prayers = PrayerCalculator.raw(place: cairo, date: date, settings: CalculationSettings(method: "Egyptian"))
        let dhuhr = prayers[2].time
        // 3 minutes after Dhuhr -> Dhuhr must be dropped (> 2 min stale)
        let now = dhuhr.addingTimeInterval(180)

        let config = AlertScheduleConfig(
            calculation: CalculationSettings(method: "Egyptian"),
            prayerReminders: ["fajr": true, "sunrise": true, "dhuhr": true, "asr": true, "maghrib": true, "isha": true],
            prePrayerMinutes: 15,
            alertMode: "azan",
            suggestedReminders: [
                "duha": true, "qiyam": true, "surat_kahf": true, "morning_azkar": true,
                "evening_azkar": true, "fasting_days": true, "daily_reading": true, "verse_day": true
            ],
            suggestedTimes: [
                "duha": "09:00", "qiyam": "03:00", "surat_kahf": "11:00", "morning_azkar": "06:30",
                "evening_azkar": "17:00", "fasting_days": "04:30", "daily_reading": "20:00", "verse_day": "07:30"
            ],
            customReminders: [CustomReminder(id: "c1", title: "Wird", hour: 21, minute: 30, isEnabled: true)]
        )

        let planned = AlertPlanner.plan(config: config, place: cairo, now: now, horizonDays: 12)
        XCTAssertEqual(planned.count, AlertPlanner.maxIOSPendingNotifications)

        // Sorted chronologically
        for idx in 1..<planned.count {
            XCTAssertLessThanOrEqual(planned[idx - 1].fireDate, planned[idx].fireDate)
        }
        // Dhuhr (3 min stale) must not be included
        XCTAssertFalse(planned.contains { $0.prayer == .dhuhr && $0.kind == .prayer && abs($0.fireDate.timeIntervalSince(dhuhr)) < 1 })

        // Within 1 minute of Dhuhr (inside 2-min grace window) -> Dhuhr IS included
        let insideGrace = AlertPlanner.plan(config: config, place: cairo, now: dhuhr.addingTimeInterval(60), horizonDays: 3)
        XCTAssertTrue(insideGrace.contains { $0.prayer == .dhuhr && $0.kind == .prayer && abs($0.fireDate.timeIntervalSince(dhuhr)) < 1 })
    }

    func testAlertPlannerSkipsPrePrayerForSunriseAndDeduplicatesAcrossDst() {
        let london = Place(latitude: 51.5074, longitude: -0.1278, cityName: "London", timeZoneId: "Europe/London", countryCode: "GB")
        // Around UK DST fall-back (Oct 25 2026)
        let now = CivilDate(year: 2026, month: 10, day: 24).utcMidnight
        let config = AlertScheduleConfig(
            calculation: CalculationSettings(method: "MuslimWorldLeague"),
            prayerReminders: ["fajr": true, "sunrise": true, "dhuhr": true, "asr": true, "maghrib": true, "isha": true],
            prePrayerMinutes: 10,
            alertMode: "azan"
        )
        let planned = AlertPlanner.plan(config: config, place: london, now: now, horizonDays: 5)
        XCTAssertFalse(planned.contains { $0.prayer == .sunrise && $0.kind == .prePrayer })
        let ids = planned.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Duplicate alert IDs across DST boundary")
    }

    func testAdhanVoiceResolverFallsBackWhenRemoteVoiceNotDownloaded() {
        // "Islam Sobhi" is a remote-only CDN voice (not bundled)
        let fallback = AdhanVoiceResolver.notificationSoundName(
            voiceId: "Islam Sobhi",
            prayer: .dhuhr,
            fajrAdhanEnabled: true,
            availableSoundFiles: []
        )
        XCTAssertEqual(fallback, AdhanCatalog.defaultBundledCaf)

        // Once downloaded into Library/Sounds, it resolves to its own .caf clip
        let downloaded = AdhanVoiceResolver.notificationSoundName(
            voiceId: "Islam Sobhi",
            prayer: .dhuhr,
            fajrAdhanEnabled: true,
            availableSoundFiles: ["Islam-Sobhi.caf"]
        )
        XCTAssertEqual(downloaded, "Islam-Sobhi.caf")

        // Bundled voice always resolves even with empty cached set
        let bundled = AdhanVoiceResolver.notificationSoundName(
            voiceId: "Adhan Madinah",
            prayer: .asr,
            fajrAdhanEnabled: false,
            availableSoundFiles: []
        )
        XCTAssertEqual(bundled, "Adhan-Madinah.caf")

        // Fajr uses Fajr recording only when available locally, otherwise base voice
        let fajrCached = AdhanVoiceResolver.notificationSoundName(
            voiceId: "Adhan Mecca",
            prayer: .fajr,
            fajrAdhanEnabled: true,
            availableSoundFiles: ["Makkah-Ali-Mulla-Fajr.caf"]
        )
        XCTAssertEqual(fajrCached, "Makkah-Ali-Mulla-Fajr.caf")

        let fajrNotCached = AdhanVoiceResolver.notificationSoundName(
            voiceId: "Adhan Mecca",
            prayer: .fajr,
            fajrAdhanEnabled: true,
            availableSoundFiles: []
        )
        XCTAssertEqual(fajrNotCached, "Adhan-Makkah.caf")
    }
}
