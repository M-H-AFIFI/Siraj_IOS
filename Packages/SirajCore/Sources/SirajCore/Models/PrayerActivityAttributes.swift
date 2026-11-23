#if canImport(ActivityKit) && os(iOS)
import ActivityKit
import Foundation

public struct PrayerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public let nextPrayerRaw: String
        public let nextPrayerTitle: String
        public let nextPrayerTime: Date
        public let intervalStart: Date
        public let formattedClock: String
        public let cityName: String
        public let hijriShort: String

        public init(
            nextPrayerRaw: String,
            nextPrayerTitle: String,
            nextPrayerTime: Date,
            intervalStart: Date,
            formattedClock: String,
            cityName: String,
            hijriShort: String
        ) {
            self.nextPrayerRaw = nextPrayerRaw
            self.nextPrayerTitle = nextPrayerTitle
            self.nextPrayerTime = nextPrayerTime
            self.intervalStart = intervalStart
            self.formattedClock = formattedClock
            self.cityName = cityName
            self.hijriShort = hijriShort
        }
    }

    public let paletteId: String

    public init(paletteId: String) {
        self.paletteId = paletteId
    }
}
#endif
