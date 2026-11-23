import Foundation
import XCTest
@testable import SirajCore

final class PrayerTimesTests: XCTestCase {
    func testPrayerTimesFixturesToTheMinute() throws {
        let rows = try ReferenceLoader.rows(named: "prayer_times.csv.gz")
        XCTAssertGreaterThan(rows.count, 20_000, "Expected > 20,000 reference rows, got \(rows.count)")

        var mismatches: [String] = []
        for r in rows {
            guard r.count >= 13,
                  let lat = Double(r[1]),
                  let lon = Double(r[2]),
                  let date = CivilDate(isoString: r[6]) else {
                XCTFail("Malformed reference row: \(r)")
                continue
            }
            let settings = CalculationSettings(method: r[3], madhab: r[4], highLatitudeRule: r[5])
            let times = AdhanPrayerTimes(
                coordinates: Coordinates(latitude: lat, longitude: lon),
                date: date,
                parameters: PrayerCalculator.parameters(for: settings)
            )
            let actual: [Date?] = [times.fajr, times.sunrise, times.dhuhr, times.asr, times.maghrib, times.isha]
            for idx in 0..<6 {
                let expected = r[7 + idx]
                let got: String
                if let d = actual[idx] {
                    let ms = Int64((d.timeIntervalSince1970 * 1000.0).rounded())
                    got = String(ms / 60_000)
                } else {
                    got = ""
                }
                if expected != got {
                    mismatches.append("\(r[0..<(7)].joined(separator: ",")) #\(idx): expected \(expected) got \(got)")
                    if mismatches.count >= 20 { break }
                }
            }
            if mismatches.count >= 20 { break }
        }
        XCTAssertTrue(mismatches.isEmpty, "\(mismatches.count)+ mismatches, first:\n\(mismatches.joined(separator: "\n"))")
    }

    func testCairoTimesRespectDstAndIqama() throws {
        let cairoCity = try XCTUnwrap(Cities.search("Cairo").first)
        let cairo = Place.fromCity(cairoCity)
        let now = Date(timeIntervalSince1970: CivilDate(year: 2026, month: 10, day: 30).utcMidnight.timeIntervalSince1970 + 6 * 3600)
        let day = PrayerCalculator.day(place: cairo, date: CivilDate(year: 2026, month: 10, day: 30), settings: CalculationSettings(method: "Egyptian"), now: now)
        let dhuhr = day[.dhuhr]

        XCTAssertEqual(cairo.timeZone.secondsFromGMT(for: dhuhr.time), 2 * 3600)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = cairo.timeZone
        let hour = cal.component(.hour, from: dhuhr.time)
        XCTAssertTrue((11...12).contains(hour), "Expected Cairo Dhuhr hour in 11..12, got \(hour)")
        XCTAssertEqual(dhuhr.iqama, dhuhr.time.addingTimeInterval(20 * 60))
    }

    func testAfterIshaNextPrayerIsTomorrowsFajr() throws {
        let mecca = Place.fromCity(try XCTUnwrap(Cities.search("Mecca").first))
        let date = CivilDate(year: 2026, month: 3, day: 1)
        let settings = CalculationSettings(method: "UmmAlQura")
        let isha = PrayerCalculator.raw(place: mecca, date: date, settings: settings)[5]
        let late = isha.windowEnd.addingTimeInterval(60)
        let day = PrayerCalculator.day(place: mecca, date: date, settings: settings, now: late)
        let next = try XCTUnwrap(day.next)
        XCTAssertEqual(next.type, .fajr)
        XCTAssertEqual(CivilDate.from(date: next.time, timeZone: mecca.timeZone), date.addingDays(1))
    }

    func testPrayerStateWalksUpcomingAzanWaitingInPrayer() throws {
        let mecca = Place.fromCity(try XCTUnwrap(Cities.search("Mecca").first))
        let date = CivilDate(year: 2026, month: 3, day: 1)
        let settings = CalculationSettings(method: "UmmAlQura")
        let asr = PrayerCalculator.raw(place: mecca, date: date, settings: settings)[3]
        let iqama = try XCTUnwrap(asr.iqama)

        func stateAt(_ t: Date) -> PrayerState? {
            PrayerState.at(day: PrayerCalculator.day(place: mecca, date: date, settings: settings, now: t), now: t)
        }

        if case .upcomingAzan = stateAt(asr.time.addingTimeInterval(-10 * 60)) {} else { XCTFail("Expected upcomingAzan") }
        if case .azanCalled = stateAt(asr.time.addingTimeInterval(60)) {} else { XCTFail("Expected azanCalled") }
        if case .waitingForIqama(_, _, _, let progress) = stateAt(asr.time.addingTimeInterval(10 * 60)) {
            XCTAssertEqual(progress, 0.5, accuracy: 0.02)
        } else {
            XCTFail("Expected waitingForIqama")
        }
        if case .inPrayer = stateAt(iqama.addingTimeInterval(5 * 60)) {} else { XCTFail("Expected inPrayer") }
        if case .upcomingAzan(let p, _) = stateAt(iqama.addingTimeInterval(16 * 60)) {
            XCTAssertEqual(p.type, .maghrib)
        } else {
            XCTFail("Expected upcomingAzan for Maghrib")
        }
    }

    func testReykjavikSummerSolsticeAppliesHighLatitudeRuleWithoutNaN() {
        let reykjavik = Place(latitude: 64.1466, longitude: -21.9426, cityName: "Reykjavik", timeZoneId: "Atlantic/Reykjavik", countryCode: "IS")
        let solstice = CivilDate(year: 2026, month: 6, day: 21)
        for rule in ["MiddleOfTheNight", "SeventhOfTheNight", "TwilightAngle"] {
            let entries = PrayerCalculator.raw(
                place: reykjavik,
                date: solstice,
                settings: CalculationSettings(method: "MuslimWorldLeague", madhab: "Shafi", highLatitudeRule: rule)
            )
            XCTAssertEqual(entries.count, 6)
            for entry in entries {
                XCTAssertFalse(entry.time.timeIntervalSince1970.isNaN, "NaN for \(rule) \(entry.type)")
            }
            XCTAssertLessThanOrEqual(entries[0].time, entries[1].time, "Fajr <= Sunrise for \(rule)")
            XCTAssertLessThanOrEqual(entries[4].time, entries[5].time, "Maghrib <= Isha for \(rule)")
        }
    }

    func testCalculationMethodAliasesAndCountryRecommendations() {
        XCTAssertEqual(CalculationMethods.recommended(forCountryCode: "eg"), "Egyptian")
        XCTAssertEqual(CalculationMethods.recommended(forCountryCode: "PK"), "Karachi")
        XCTAssertEqual(CalculationMethods.recommendedMadhab(forCountryCode: "PK"), "Hanafi")
        XCTAssertEqual(CalculationMethods.recommendedMadhab(forCountryCode: "TR"), "Shafi")
        XCTAssertEqual(CalculationMethods.recommended(forCountryCode: nil), "MuslimWorldLeague")
        XCTAssertEqual(CalculationMethods.byId("ISNA")?.id, "NorthAmerica")
        XCTAssertEqual(CalculationMethods.byId("Diyanet")?.id, "Turkey")
    }

    func testQiblaFromCairoIsSoutheast() {
        let bearing = QiblaMath.bearing(from: Coordinates(latitude: 30.0444, longitude: 31.2357))
        XCTAssertTrue((135.5...136.5).contains(bearing), "Unexpected Cairo Qibla bearing: \(bearing)")
        let dist = QiblaMath.distanceKm(from: Coordinates(latitude: 30.0444, longitude: 31.2357))
        XCTAssertTrue((1250...1320).contains(dist), "Unexpected Cairo distance to Makkah: \(dist) km")
    }
}
