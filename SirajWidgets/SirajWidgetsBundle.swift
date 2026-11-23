import SwiftUI
import WidgetKit

@main
struct SirajWidgetsBundle: WidgetBundle {
    var body: some Widget {
        PrayerLockScreenWidget()
        SirajPrayerWidget()
        SirajClockWidget()
        SirajHijriMoonWidget()
        #if canImport(ActivityKit)
        PrayerCountdownLiveActivity()
        #endif
    }
}
