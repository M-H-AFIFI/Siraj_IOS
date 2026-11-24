import Foundation

public struct KhatmaRecord: Codable, Sendable, Equatable {
    public var startEpochDay: Int64
    public var anchorEpochDay: Int64
    public var anchorPages: Int
    public var endEpochDay: Int64
    public var pagesCompleted: Int
    public var totalPages: Int
    public var reminderEnabled: Bool
    public var reminderTime: String
    public var lastReadEpochDay: Int64
    public var streak: Int

    public init(
        startEpochDay: Int64,
        anchorEpochDay: Int64,
        anchorPages: Int,
        endEpochDay: Int64,
        pagesCompleted: Int = 0,
        totalPages: Int = KhatmaPlanner.totalPages,
        reminderEnabled: Bool = true,
        reminderTime: String = "20:00",
        lastReadEpochDay: Int64 = 0,
        streak: Int = 0
    ) {
        self.startEpochDay = startEpochDay
        self.anchorEpochDay = anchorEpochDay
        self.anchorPages = anchorPages
        self.endEpochDay = endEpochDay
        self.pagesCompleted = pagesCompleted
        self.totalPages = totalPages
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
        self.lastReadEpochDay = lastReadEpochDay
        self.streak = streak
    }

    public var isFinished: Bool { pagesCompleted >= totalPages }
}

public struct KhatmaDayPortion: Sendable, Equatable, Identifiable {
    public var id: Int { dayNumber }
    public let dayNumber: Int
    public let epochDay: Int64
    public let startPage: Int
    public let endPage: Int
    public let startSurahNumber: Int
    public let startSurahName: String
    public let startSurahEnglishName: String
    public let startAyahInSurah: Int
    public let endSurahNumber: Int
    public let endSurahName: String
    public let endSurahEnglishName: String
    public let endAyahInSurah: Int
    public let isComplete: Bool
    public let isToday: Bool

    public init(
        dayNumber: Int,
        epochDay: Int64,
        startPage: Int,
        endPage: Int,
        startSurahNumber: Int,
        startSurahName: String,
        startSurahEnglishName: String,
        startAyahInSurah: Int,
        endSurahNumber: Int,
        endSurahName: String,
        endSurahEnglishName: String,
        endAyahInSurah: Int,
        isComplete: Bool,
        isToday: Bool
    ) {
        self.dayNumber = dayNumber
        self.epochDay = epochDay
        self.startPage = startPage
        self.endPage = endPage
        self.startSurahNumber = startSurahNumber
        self.startSurahName = startSurahName
        self.startSurahEnglishName = startSurahEnglishName
        self.startAyahInSurah = startAyahInSurah
        self.endSurahNumber = endSurahNumber
        self.endSurahName = endSurahName
        self.endSurahEnglishName = endSurahEnglishName
        self.endAyahInSurah = endAyahInSurah
        self.isComplete = isComplete
        self.isToday = isToday
    }

    public var pageCount: Int { max(0, endPage - startPage + 1) }
    public var isWithinOneSurah: Bool { startSurahNumber == endSurahNumber }
    public var hasLabels: Bool { startSurahNumber > 0 && endSurahNumber > 0 }
}

public struct KhatmaPlan: Sendable, Equatable {
    public let record: KhatmaRecord
    public let days: [KhatmaDayPortion]
    public let today: KhatmaDayPortion?
    public let expectedPages: Int
    public let todayTargetPages: Int
    public let daysRemaining: Int
    public let khatmasCompleted: Int

    public init(
        record: KhatmaRecord,
        days: [KhatmaDayPortion],
        today: KhatmaDayPortion?,
        expectedPages: Int,
        todayTargetPages: Int,
        daysRemaining: Int,
        khatmasCompleted: Int
    ) {
        self.record = record
        self.days = days
        self.today = today
        self.expectedPages = expectedPages
        self.todayTargetPages = todayTargetPages
        self.daysRemaining = daysRemaining
        self.khatmasCompleted = khatmasCompleted
    }

    public var pagesCompleted: Int { record.pagesCompleted }
    public var totalPages: Int { record.totalPages }
    public var pagesRemaining: Int { max(0, totalPages - pagesCompleted) }
    public var fraction: Double { min(1.0, max(0.0, Double(pagesCompleted) / Double(max(1, totalPages)))) }
    public var pagesBehind: Int { max(0, expectedPages - pagesCompleted) }
    public var pagesAhead: Int { max(0, pagesCompleted - todayTargetPages) }
    public var isBehind: Bool { !record.isFinished && pagesBehind > 0 }
    public var nextPage: Int { min(totalPages, max(1, pagesCompleted + 1)) }

    public var nextReadingPage: Int? {
        if record.isFinished { return nil }
        if let t = today, !t.isComplete { return t.startPage }
        return nextPage
    }

    public var pagesPerDayToCatchUp: Int {
        if record.isFinished { return 0 }
        let d = max(1, daysRemaining)
        return max(1, (pagesRemaining + d - 1) / d)
    }
}

public enum KhatmaPlanner {
    public static let totalPages = 604
    public static let presetDays = [7, 10, 15, 20, 30, 40, 60, 90]
    public static let dayRange = 3...365

    public static func todayEpochDay(date: Date = Date(), calendar: Calendar = .current) -> Int64 {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let civil = CivilDate(year: comps.year ?? 2026, month: comps.month ?? 1, day: comps.day ?? 1)
        return Int64(civil.dayNumber)
    }

    public static func civilDate(fromEpochDay epochDay: Int64) -> CivilDate {
        CivilDate(dayNumber: Int(epochDay))
    }

    public static func pagesForDay(
        dayIndex: Int,
        spanDays: Int,
        pagesBefore: Int = 0,
        totalPages: Int = KhatmaPlanner.totalPages
    ) -> ClosedRange<Int>? {
        guard spanDays > 0, dayIndex >= 0, dayIndex < spanDays else { return nil }
        let remaining = max(0, totalPages - pagesBefore)
        guard remaining > 0 else { return nil }
        let from = pagesBefore + cumulative(day: dayIndex, spanDays: spanDays, remaining: remaining) + 1
        let to = pagesBefore + cumulative(day: dayIndex + 1, spanDays: spanDays, remaining: remaining)
        guard to >= from else { return nil }
        return from...to
    }

    public static func expectedPagesBy(
        dayIndex: Int,
        spanDays: Int,
        pagesBefore: Int = 0,
        totalPages: Int = KhatmaPlanner.totalPages
    ) -> Int {
        if spanDays <= 0 { return totalPages }
        if dayIndex < 0 { return pagesBefore }
        if dayIndex >= spanDays - 1 { return totalPages }
        let remaining = max(0, totalPages - pagesBefore)
        return pagesBefore + cumulative(day: dayIndex + 1, spanDays: spanDays, remaining: remaining)
    }

    public static func dayIndexForPage(
        page: Int,
        spanDays: Int,
        pagesBefore: Int = 0,
        totalPages: Int = KhatmaPlanner.totalPages
    ) -> Int {
        guard spanDays > 0 else { return 0 }
        for day in 0..<spanDays {
            if let range = pagesForDay(dayIndex: day, spanDays: spanDays, pagesBefore: pagesBefore, totalPages: totalPages),
               page <= range.upperBound {
                return day
            }
        }
        return spanDays - 1
    }

    public static func buildPlan(
        record: KhatmaRecord,
        todayEpochDay: Int64,
        khatmasCompleted: Int,
        surahs: [Surah]
    ) -> KhatmaPlan {
        let spanDays = max(1, Int(record.endEpochDay - record.anchorEpochDay) + 1)
        let todayIdx = Int(todayEpochDay - record.anchorEpochDay)
        let byNumber = Dictionary(uniqueKeysWithValues: surahs.map { ($0.number, $0) })

        var portions: [KhatmaDayPortion] = []
        portions.reserveCapacity(spanDays)

        for idx in 0..<spanDays {
            guard let range = pagesForDay(
                dayIndex: idx,
                spanDays: spanDays,
                pagesBefore: record.anchorPages,
                totalPages: record.totalPages
            ) else { continue }
            let dayEpoch = record.anchorEpochDay + Int64(idx)
            let startSurahNum = QuranTables.surahForPage(range.lowerBound, edition: .madinah)
            let endSurahNum = QuranTables.surahForPage(range.upperBound, edition: .madinah)
            let startSurah = byNumber[startSurahNum]
            let endSurah = byNumber[endSurahNum]

            portions.append(KhatmaDayPortion(
                dayNumber: idx + 1,
                epochDay: dayEpoch,
                startPage: range.lowerBound,
                endPage: range.upperBound,
                startSurahNumber: startSurahNum,
                startSurahName: startSurah?.name ?? "",
                startSurahEnglishName: startSurah?.englishName ?? "",
                startAyahInSurah: 1,
                endSurahNumber: endSurahNum,
                endSurahName: endSurah?.name ?? "",
                endSurahEnglishName: endSurah?.englishName ?? "",
                endAyahInSurah: endSurah?.numberOfAyahs ?? 1,
                isComplete: record.pagesCompleted >= range.upperBound,
                isToday: dayEpoch == todayEpochDay
            ))
        }

        let todayPortion = record.isFinished ? nil : portions.first(where: { $0.isToday })
        let expected = expectedPagesBy(
            dayIndex: todayIdx - 1,
            spanDays: spanDays,
            pagesBefore: record.anchorPages,
            totalPages: record.totalPages
        )
        let todayTarget = expectedPagesBy(
            dayIndex: todayIdx,
            spanDays: spanDays,
            pagesBefore: record.anchorPages,
            totalPages: record.totalPages
        )
        let daysRemaining = Int(record.endEpochDay - todayEpochDay) + 1

        return KhatmaPlan(
            record: record,
            days: portions,
            today: todayPortion,
            expectedPages: expected,
            todayTargetPages: todayTarget,
            daysRemaining: daysRemaining,
            khatmasCompleted: khatmasCompleted
        )
    }

    public static func applyProgress(
        record: KhatmaRecord,
        newPagesCompleted: Int,
        todayEpochDay: Int64
    ) -> KhatmaRecord {
        var next = record
        let clamped = min(record.totalPages, max(0, newPagesCompleted))
        let advanced = clamped > record.pagesCompleted
        next.pagesCompleted = clamped
        if advanced {
            if record.lastReadEpochDay == todayEpochDay {
                next.streak = max(1, record.streak)
            } else if record.lastReadEpochDay == todayEpochDay - 1 {
                next.streak = max(1, record.streak + 1)
            } else {
                next.streak = 1
            }
            next.lastReadEpochDay = todayEpochDay
        }
        return next
    }

    public static func rescheduled(record: KhatmaRecord, todayEpochDay: Int64) -> KhatmaRecord {
        var next = record
        next.anchorEpochDay = todayEpochDay
        next.anchorPages = record.pagesCompleted
        if next.endEpochDay < todayEpochDay {
            next.endEpochDay = todayEpochDay
        }
        return next
    }

    private static func cumulative(day: Int, spanDays: Int, remaining: Int) -> Int {
        Int((Int64(day) * Int64(remaining)) / Int64(spanDays))
    }
}
