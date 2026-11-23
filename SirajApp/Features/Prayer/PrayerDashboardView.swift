import SwiftUI
import SirajCore

enum PrayerRoute: Hashable {
    case detail
    case location
    case calculation
    case reminders
    case widgets
}

struct PrayerDashboardView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    let locationService: LocationService
    let onOpenReminders: () -> Void
    let onOpenWidgets: () -> Void

    @State private var path = NavigationPath()
    @State private var showHijriSheet = false

    var body: some View {
        let dayIndex = appState.activePlace.today(at: appState.currentTime).dayNumber
        let verse = DailyQuotesCatalog.verseForDayIndex(dayIndex)
        let hadith = DailyQuotesCatalog.hadithForDayIndex(dayIndex)

        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 16) {
                    MihrabLocationHeader(place: appState.activePlace) {
                        path.append(PrayerRoute.location)
                    }

                    AnimatedSkyCard(
                        appState: appState,
                        onTapHijri: { showHijriSheet = true },
                        onTapCard: { path.append(PrayerRoute.detail) }
                    )

                    if let soon = appState.upcomingOccasions.first, soon.daysUntil <= 30 {
                        IslamicEventsBanner(occasion: soon)
                    }

                    MihrabPrayerTable(
                        day: appState.prayerDay,
                        settings: appState.settings,
                        now: appState.currentTime
                    ) {
                        path.append(PrayerRoute.detail)
                    }

                    MihrabQuickActions(
                        onCalculation: { path.append(PrayerRoute.calculation) },
                        onReminders: onOpenReminders,
                        onWidgets: onOpenWidgets,
                        onLocation: { path.append(PrayerRoute.location) }
                    )

                    DailyAyahCard(verse: verse)

                    DailyInspirationCard(hadith: hadith)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 108)
            }
            .scrollIndicators(.hidden)
            .background(Color.clear)
            .navigationDestination(for: PrayerRoute.self) { route in
                switch route {
                case .detail:
                    PrayerTimesDetailView(appState: appState)
                case .location:
                    LocationSettingsView(appState: appState, locationService: locationService)
                case .calculation:
                    PrayerCalculationSettingsView(appState: appState)
                case .reminders, .widgets:
                    EmptyView()
                }
            }
            .sheet(isPresented: $showHijriSheet) {
                HijriDateSheetView(appState: appState)
            }
        }
    }
}
