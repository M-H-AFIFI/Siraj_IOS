import SwiftUI
import WidgetKit

@main
struct SirajWidgetsBundle: WidgetBundle {
    var body: some Widget {
        PrayerLockScreenWidget()
        SirajPrayerWidget()
        SirajClockWidget()
        SirajHijriMoonWidget()
        SirajQuoteWidget()
        SirajWorshipWidget()
        SirajTasbihWidget()
        #if canImport(ActivityKit)
        PrayerCountdownLiveActivity()
        #endif
    }
}
