import SwiftUI
import SirajCore

public struct RootView: View {
    @Environment(\.sirajTheme) private var theme
    @Bindable var appState: AppState
    let locationService: LocationService

    public init(appState: AppState, locationService: LocationService) {
        self.appState = appState
        self.locationService = locationService
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            SirajRootBackdrop(activePrayer: appState.prayerDay.next?.type)

            if !appState.onboardingComplete {
                OnboardingView(appState: appState, locationService: locationService)
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
                        MilestonePlaceholderView(
                            iconAsset: "ic_nav_quran",
                            titleKey: "nav_quran",
                            descriptionKey: "ios_milestone_quran_desc"
                        )
                    case .qibla:
                        MilestonePlaceholderView(
                            iconAsset: "ic_nav_qibla",
                            titleKey: "nav_qibla",
                            descriptionKey: "ios_milestone_qibla_desc"
                        )
                    case .azkar:
                        MilestonePlaceholderView(
                            iconAsset: "ic_nav_azkar",
                            titleKey: "nav_azkar",
                            descriptionKey: "ios_milestone_azkar_desc"
                        )
                    case .settings:
                        MilestonePlaceholderView(
                            iconAsset: "ic_siraj_emblem",
                            titleKey: "nav_settings",
                            descriptionKey: "settings_appearance"
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                FloatingTabBar(selectedTab: $appState.selectedTab)
            }
        }
    }
}
