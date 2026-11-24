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
                            onOpenQuran: { appState.selectedTab = .quran },
                            onOpenReader: { dest in
                                if appState.quranStore.assetState.isReady {
                                    appState.activeReader = dest
                                } else {
                                    appState.selectedTab = .quran
                                }
                            },
                            onOpenTasbih: {
                                appState.selectedTab = .azkar
                                appState.requestedWorshipRoute = .tasbih
                            },
                            onOpenListen: {
                                appState.selectedTab = .quran
                                appState.requestedQuranRoute = "listen"
                            },
                            onOpenDuas: { appState.selectedTab = .azkar },
                            onOpenHadith: { hadithId in
                                appState.selectedTab = .azkar
                                appState.requestedWorshipRoute = .hadith(hadithId)
                            }
                        )
                    case .quran:
                        SurahListView(
                            appState: appState,
                            quranStore: appState.quranStore,
                            onOpenReader: { appState.activeReader = $0 }
                        )
                    case .qibla:
                        QiblaCompassView(
                            appState: appState,
                            locationService: locationService
                        )
                    case .azkar:
                        WorshipHubView(
                            appState: appState,
                            worshipStore: appState.worshipStore,
                            onOpenListenPlayer: {
                                appState.showListenPlayer = true
                            }
                        )
                    case .settings:
                        SettingsHubView(
                            appState: appState,
                            locationService: locationService,
                            audioEngine: audioEngine,
                            scheduler: scheduler,
                            onOpenReader: { dest in
                                if appState.quranStore.assetState.isReady {
                                    appState.activeReader = dest
                                } else {
                                    appState.selectedTab = .quran
                                }
                            }
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack(spacing: 8) {
                    if appState.audioStore.hasAnyMiniPlayer {
                        QuranMiniPlayer(
                            appState: appState,
                            audioStore: appState.audioStore,
                            onOpenReader: { dest in
                                if appState.quranStore.assetState.isReady {
                                    appState.activeReader = dest
                                } else {
                                    appState.selectedTab = .quran
                                }
                            },
                            onOpenListenPlayer: {
                                appState.showListenPlayer = true
                            }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    FloatingTabBar(selectedTab: $appState.selectedTab, isCollapsed: appState.isTabBarCollapsed)
                        .onChange(of: appState.selectedTab) { _, _ in
                            appState.isTabBarCollapsed = false
                        }
                }
            }
        }
        .onChange(of: appState.activeAdhanAlert) { _, alert in
            if alert != nil {
                appState.audioStore.pauseForAdhan()
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
        .fullScreenCover(item: $appState.activeReader) { destination in
            QuranReaderView(
                appState: appState,
                quranStore: appState.quranStore,
                initialDestination: destination
            )
        }
        .fullScreenCover(isPresented: $appState.showListenPlayer) {
            ListenPlayerView(
                appState: appState,
                audioStore: appState.audioStore
            )
        }
    }
}
