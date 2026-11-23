import Foundation
import SirajCore
#if canImport(ActivityKit)
import ActivityKit
#endif

@MainActor
final class LiveActivityCoordinator {
    func sync(appState: AppState) {
        #if canImport(ActivityKit)
        guard !appState.isUITesting else { return }
        guard appState.settings.liveActivityEnabled else {
            Task { await endAll() }
            return
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard let next = appState.prayerDay.next else { return }

        let now = appState.currentTime
        let prevTime = appState.prayerDay.entries.last(where: { $0.time <= now })?.time
            ?? now.addingTimeInterval(-3600)
        let title = appState.localizer.string(next.type.stringKey, lang: appState.settings.language)
        let clock = TimeFormatter.formatTime(
            next.time,
            timeZone: appState.activePlace.timeZone,
            hourFormat: appState.settings.hourFormat,
            numeralSystem: appState.settings.numeralSystem,
            lang: appState.settings.language
        )
        let city = appState.activePlace.displayName(language: appState.settings.language) ?? appState.activePlace.timeZoneId
        let hijri = HijriFormatter.format(appState.hijriDate, lang: appState.settings.language, numeralSystem: appState.settings.numeralSystem)

        let state = PrayerActivityAttributes.ContentState(
            nextPrayerRaw: next.type.rawValue,
            nextPrayerTitle: title,
            nextPrayerTime: next.time,
            intervalStart: min(prevTime, now),
            formattedClock: clock,
            cityName: city,
            hijriShort: hijri
        )

        let content = ActivityContent(state: state, staleDate: next.time)

        if let existing = Activity<PrayerActivityAttributes>.activities.first {
            if existing.attributes.paletteId == appState.settings.themePalette {
                Task { await existing.update(content) }
                return
            }
            Task {
                await endAll()
                startActivity(paletteId: appState.settings.themePalette, content: content)
            }
        } else {
            startActivity(paletteId: appState.settings.themePalette, content: content)
        }
        #endif
    }

    #if canImport(ActivityKit)
    private func startActivity(paletteId: String, content: ActivityContent<PrayerActivityAttributes.ContentState>) {
        let attributes = PrayerActivityAttributes(paletteId: paletteId)
        _ = try? Activity<PrayerActivityAttributes>.request(attributes: attributes, content: content, pushType: nil)
    }

    private func endAll() async {
        for activity in Activity<PrayerActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
    #endif
}
