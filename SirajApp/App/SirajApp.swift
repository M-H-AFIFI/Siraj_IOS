import SwiftUI
import SirajCore

@main
struct SirajApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var appState = AppState()
    @State private var locationService = LocationService()
    @State private var audioEngine = AdhanAudioEngine()
    @State private var scheduler = AdhanNotificationScheduler()
    @State private var liveActivity = LiveActivityCoordinator()

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
                wireServices()
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active, !appState.isUITesting else { return }
                appState.refreshPrayers()
                liveActivity.sync(appState: appState)
                Task {
                    await scheduler.reschedule(
                        settings: appState.settings,
                        place: appState.activePlace,
                        localizer: appState.localizer,
                        audioEngine: audioEngine
                    )
                }
            }
        }
    }

    private func wireServices() {
        scheduler.onOpenPrayerAlert = { prayer in
            appState.activeAdhanAlert = prayer
        }
        scheduler.onDismissAlert = {
            audioEngine.stop()
            appState.activeAdhanAlert = nil
        }
        scheduler.shouldOpenScreenInForeground = {
            appState.settings.isAdhanScreenEnabled
        }
        appState.onSettingsChangedForAlerts = { settings, place in
            guard !appState.isUITesting else { return }
            liveActivity.sync(appState: appState)
            Task {
                await scheduler.reschedule(
                    settings: settings,
                    place: place,
                    localizer: appState.localizer,
                    audioEngine: audioEngine
                )
            }
        }

        guard !appState.isUITesting else { return }

        liveActivity.sync(appState: appState)

        scheduler.configure(localizer: appState.localizer, language: appState.settings.language)
        scheduler.registerBackgroundRefresh {
            await scheduler.reschedule(
                settings: appState.settings,
                place: appState.activePlace,
                localizer: appState.localizer,
                audioEngine: audioEngine
            )
        }
        Task {
            await scheduler.reschedule(
                settings: appState.settings,
                place: appState.activePlace,
                localizer: appState.localizer,
                audioEngine: audioEngine
            )
        }
    }
}
