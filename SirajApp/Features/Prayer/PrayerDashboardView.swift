import SwiftUI
import SirajCore

enum PrayerRoute: Hashable {
    case detail
    case location
    case calculation
}

struct PrayerDashboardView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    let locationService: LocationService
    let onOpenQuran: () -> Void
    let onOpenTasbih: () -> Void
    let onOpenListen: () -> Void
    let onOpenDuas: () -> Void

    @State private var path = NavigationPath()
    @State private var showHijriSheet = false

    var body: some View {
        let todayCivil = appState.activePlace.today(at: appState.currentTime)
        let dayIndex = todayCivil.dayNumber
        let verse = DailyQuotesCatalog.verseForDayIndex(dayIndex)
        let hadith = DailyQuotesCatalog.hadithForDayIndex(dayIndex)

        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 0) {
                    MihrabLocationHeader(place: appState.activePlace) {
                        path.append(PrayerRoute.location)
                    }

                    Spacer().frame(height: 24)

                    AnimatedSkyCard(
                        appState: appState,
                        onTapHijri: { showHijriSheet = true },
                        onTapCard: { path.append(PrayerRoute.detail) }
                    )

                    Spacer().frame(height: 24)

                    MihrabQuickActions(
                        onOpenQuran: onOpenQuran,
                        onOpenTasbih: onOpenTasbih,
                        onOpenListen: onOpenListen,
                        onOpenDuas: onOpenDuas
                    )

                    Spacer().frame(height: 24)

                    MihrabPrayerTable(
                        day: appState.prayerDay,
                        settings: appState.settings,
                        now: appState.currentTime
                    ) {
                        path.append(PrayerRoute.detail)
                    }

                    if let todayOccasion = TodayIslamicOccasion.forHijri(
                        month: appState.hijriDate.month,
                        day: appState.hijriDate.day,
                        language: theme.language,
                        digits: { theme.digits($0) }
                    ) {
                        IslamicEventsBanner(occasion: todayOccasion) {
                            showHijriSheet = true
                        }
                        .padding(.top, 20)
                    }

                    DailyAyahCard(verse: verse, onTapCard: onOpenQuran)
                        .padding(.top, 20)

                    DailyInspirationCard(hadith: hadith, onOpenCollection: onOpenDuas)
                        .padding(.top, 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 118)
            }
            .scrollIndicators(.hidden)
            .modifier(ScrollCollapseTracker { delta in
                if delta > 0 {
                    appState.isTabBarCollapsed = true
                } else {
                    appState.isTabBarCollapsed = false
                }
            })
            .background(Color.clear)
            .navigationDestination(for: PrayerRoute.self) { route in
                switch route {
                case .detail:
                    PrayerTimesDetailView(appState: appState, onTapLocation: {
                        path.append(PrayerRoute.location)
                    })
                case .location:
                    LocationSettingsView(appState: appState, locationService: locationService)
                case .calculation:
                    PrayerCalculationSettingsView(appState: appState)
                }
            }
            .sheet(isPresented: $showHijriSheet) {
                HijriDateSheetView(appState: appState)
            }
        }
    }
}
