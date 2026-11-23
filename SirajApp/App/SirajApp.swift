import SwiftUI
import UIKit
import SirajCore

// Register BGTaskScheduler handlers and notification delegate before didFinishLaunchingWithOptions returns.
final class SirajAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        MainActor.assumeIsolated {
            AdhanNotificationScheduler.shared.registerAtLaunch()
        }
        return true
    }
}

@main
struct SirajApp: App {
    @UIApplicationDelegateAdaptor(SirajAppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @State private var appState = AppState()
    @State private var locationService = LocationService()
    @State private var audioEngine = AdhanAudioEngine()
    @State private var liveActivity = LiveActivityCoordinator()
    @State private var hasWiredServices = false

    private var scheduler: AdhanNotificationScheduler { .shared }

    var body: some Scene {
        WindowGroup {
            SirajThemeProvider(settings: appState.settings, localizer: appState.localizer) {
                RootView(
                    appState: appState,
                    locationService: locationService,
                    audioEngine: audioEngine,
                    scheduler: scheduler
                )
            }
            .task {
                guard !hasWiredServices else { return }
                hasWiredServices = true
                wireServices()
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                guard newPhase == .active, oldPhase != .active, hasWiredServices, !appState.isUITesting else { return }
                appState.refreshPrayers()
                liveActivity.sync(appState: appState)
                scheduler.scheduleReschedule(
                    settings: appState.settings,
                    place: appState.activePlace,
                    localizer: appState.localizer,
                    audioEngine: audioEngine
                )
            }
        }
    }

    private func wireServices() {
        scheduler.onOpenPrayerAlert = { prayer in
            appState.isAdhanAlertTest = false
            appState.activeAdhanAlert = prayer
        }
        scheduler.onDismissAlert = {
            audioEngine.stop()
            appState.activeAdhanAlert = nil
        }
        scheduler.shouldOpenAdhanScreen = {
            appState.settings.isAdhanScreenEnabled && appState.settings.azanReminderType.lowercased() == "azan"
        }
        scheduler.backgroundRefreshHandler = {
            appState.refreshPrayers()
            scheduler.scheduleReschedule(
                settings: appState.settings,
                place: appState.activePlace,
                localizer: appState.localizer,
                audioEngine: audioEngine
            )
        }
        appState.onSettingsChangedForAlerts = { settings, place in
            guard !appState.isUITesting else { return }
            liveActivity.sync(appState: appState)
            scheduler.scheduleReschedule(
                settings: settings,
                place: place,
                localizer: appState.localizer,
                audioEngine: audioEngine
            )
        }

        guard !appState.isUITesting else { return }

        liveActivity.sync(appState: appState)
        scheduler.scheduleReschedule(
            settings: appState.settings,
            place: appState.activePlace,
            localizer: appState.localizer,
            audioEngine: audioEngine
        )
    }
}
