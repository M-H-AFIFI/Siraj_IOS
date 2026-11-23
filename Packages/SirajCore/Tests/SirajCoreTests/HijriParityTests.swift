import Foundation
import XCTest
@testable import SirajCore

final class HijriParityTests: XCTestCase {
    func testUmmAlQuraMatchesJdkAll2172Rows() throws {
        let rows = try ReferenceLoader.rows(named: "umm_al_qura.csv")
        XCTAssertEqual(rows.count, (1499 - 1319 + 1) * 12)
        var mismatches: [String] = []
        for r in rows {
            let y = try XCTUnwrap(Int(r[0]))
            let m = try XCTUnwrap(Int(r[1]))
            let expected = try XCTUnwrap(CivilDate(isoString: r[2]))
            let got = SirajHijriCalendar.ummAlQura.firstDayOf(year: y, month: m)
            if got != expected {
                mismatches.append("\(y)-\(m): expected \(expected) got \(got)")
            }
            let back = SirajHijriCalendar.ummAlQura.toHijri(expected)
            if back.year != y || back.month != m || back.day != 1 {
                mismatches.append("\(y)-\(m): \(expected) mapped back as \(back)")
            }
            if mismatches.count >= 20 { break }
        }
        XCTAssertTrue(mismatches.isEmpty, "Mismatches:\n\(mismatches.joined(separator: "\n"))")
    }

    func testCountryMonthStartsMatchAndroid() throws {
        let rows = try ReferenceLoader.rows(named: "hijri_months.csv")
        XCTAssertGreaterThan(rows.count, 500)
        var calendars: [String: SirajHijriCalendar] = [:]
        var mismatches: [String] = []
        for r in rows {
            let key = r[0] + "|" + r[1]
            let cal = calendars[key] ?? {
                let c = SirajHijriCalendar(region: .forCountry(r[0]), adjustment: Int(r[1]) ?? 0)
                calendars[key] = c
                return c
            }()
            let y = try XCTUnwrap(Int(r[2]))
            let m = try XCTUnwrap(Int(r[3]))
            let first = cal.firstDayOf(year: y, month: m).isoString
            let length = cal.lengthOfMonth(year: y, month: m)
            if first != r[4] || length != Int(r[5]) {
                mismatches.append("\(r.joined(separator: ",")) -> \(first),\(length)")
                if mismatches.count >= 15 { break }
            }
        }
        XCTAssertTrue(mismatches.isEmpty, "Mismatches:\n\(mismatches.joined(separator: "\n"))")
    }

    func testHijriDaysMatchAndroid() throws {
        let rows = try ReferenceLoader.rows(named: "hijri_days.csv.gz")
        XCTAssertGreaterThan(rows.count, 1000)
        var calendars: [String: SirajHijriCalendar] = [:]
        var mismatches: [String] = []
        for r in rows {
            let cal = calendars[r[0]] ?? {
                let c = SirajHijriCalendar(region: .forCountry(r[0]))
                calendars[r[0]] = c
                return c
            }()
            let date = try XCTUnwrap(CivilDate(isoString: r[1]))
            let h = cal.toHijri(date)
            let got = "\(h.year),\(h.month),\(h.day),\(h.lengthOfMonth)"
            let expected = r[2..<6].joined(separator: ",")
            if got != expected {
                mismatches.append("\(r[0]) \(r[1]): expected \(expected) got \(got)")
                if mismatches.count >= 15 { break }
            }
        }
        XCTAssertTrue(mismatches.isEmpty, "Mismatches:\n\(mismatches.joined(separator: "\n"))")
    }

    func testMoonPhaseMatchesAndroid() throws {
        let rows = try ReferenceLoader.rows(named: "moon_phase.csv")
        XCTAssertGreaterThan(rows.count, 100)
        for r in rows {
            let ms = try XCTUnwrap(Int64(r[0]))
            let expectedIllum = try XCTUnwrap(Double(r[1]))
            let expectedWaxing = r[2].lowercased() == "true"
            let expectedAge = try XCTUnwrap(Double(r[3]))
            let p = MoonPhase.at(epochMillis: ms)
            XCTAssertEqual(p.illumination, expectedIllum, accuracy: 1e-8)
            XCTAssertEqual(p.waxing, expectedWaxing)
            XCTAssertEqual(p.ageDays, expectedAge, accuracy: 1e-6)
        }
    }

    func testZoneCountriesLookup() {
        XCTAssertEqual(Zones.countryOf("Africa/Cairo"), "EG")
        XCTAssertEqual(Zones.countryOf("Asia/Kuwait"), "KW")
        XCTAssertNil(Zones.countryOf("UTC"))
    }

    func testIslamicOccasionsUpcomingAreSorted() {
        let today = CivilDate(year: 2026, month: 3, day: 1)
        let upcoming = IslamicOccasions.upcoming(from: today, calendar: .ummAlQura)
        XCTAssertEqual(upcoming.count, IslamicOccasions.all.count)
        for i in 1..<upcoming.count {
            XCTAssertLessThanOrEqual(upcoming[i - 1].daysUntil, upcoming[i].daysUntil)
        }
    }
}
