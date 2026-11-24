import SwiftUI
import SirajCore

struct RootView: View {
    @Environment(\.sirajTheme) private var theme
    @Bindable var appState: AppState
    let locationService: LocationService
    let audioEngine: AdhanAudioEngine
    let scheduler: AdhanNotificationScheduler

    var body: some View {
        ZStack(alignment: .bottom) {
            SirajRootBackdrop(activePrayer: appState.prayerDay.next?.type)

            if !appState.onboardingComplete {
                OnboardingView(
                    appState: appState,
                    locationService: locationService,
                    onPreviewVoice: { voiceId in
                        audioEngine.playPreview(voiceId: voiceId, volume: appState.settings.adhanVolume)
                    },
                    onStopPreview: {
                        audioEngine.stop()
                    },
                    onRequestNotifications: {
                        _ = await scheduler.requestAuthorization()
                    }
                )
            } else {
                Group {
                    switch appState.selectedTab {
                    case .prayer:
                        PrayerDashboardView(
                            appState: appState,
                            locationService: locationService,
                            onOpenReminders: {
                                appState.requestedRoute = "reminders"
                                appState.selectedTab = .settings
                            },
                            onOpenWidgets: {
                                appState.requestedRoute = "widgets"
                                appState.selectedTab = .settings
                            }
                        )
                    case .quran:
                        ComingSoonTabView(
                            iconAsset: "ic_nav_quran",
                            titleKey: "nav_quran",
                            descriptionKey: "tab_coming_soon_quran"
                        )
                    case .qibla:
                        ComingSoonTabView(
                            iconAsset: "ic_nav_qibla",
                            titleKey: "nav_qibla",
                            descriptionKey: "tab_coming_soon_qibla"
                        )
                    case .azkar:
                        ComingSoonTabView(
                            iconAsset: "ic_nav_azkar",
                            titleKey: "nav_azkar",
                            descriptionKey: "tab_coming_soon_azkar"
                        )
                    case .settings:
                        SettingsHubView(
                            appState: appState,
                            locationService: locationService,
                            audioEngine: audioEngine,
                            scheduler: scheduler
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                FloatingTabBar(selectedTab: $appState.selectedTab)
            }
        }
        .fullScreenCover(item: $appState.activeAdhanAlert) { prayer in
            AdhanAlertView(
                prayer: prayer,
                appState: appState,
                audioEngine: audioEngine,
                onDismiss: {
                    appState.activeAdhanAlert = nil
                }
            )
        }
    }
}
