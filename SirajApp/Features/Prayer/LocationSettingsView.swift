import SwiftUI
import SirajCore

struct LocationSettingsView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    let locationService: LocationService
    @State private var query: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(theme.primary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(appState.activePlace.displayName(language: theme.language) ?? appState.activePlace.timeZoneId)
                            .font(theme.scaledFont(size: 17, weight: .bold))
                            .foregroundStyle(theme.onSurface)
                        Text(String(format: "%.3f, %.3f · %@", appState.activePlace.latitude, appState.activePlace.longitude, appState.activePlace.timeZoneId))
                            .font(theme.scaledFont(size: 12))
                            .foregroundStyle(theme.onSurfaceVariant)
                    }
                    Spacer()
                }
                .padding(16)
                .sirajCardSurface(cornerRadius: 20)

                Button {
                    Task {
                        if let place = await locationService.requestCurrentPlace() {
                            apply(place: place, manual: false)
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        if locationService.isLocating {
                            ProgressView().tint(theme.onPrimary)
                        } else {
                            Image(systemName: "location.fill")
                        }
                        Text(theme.t("detect_location"))
                            .font(theme.scaledFont(size: 15, weight: .bold))
                    }
                    .foregroundStyle(theme.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(theme.primary))
                }
                .buttonStyle(.plain)
                .disabled(locationService.isLocating)

                TextField(theme.t("search_city"), text: $query)
                    .padding(13)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.surfaceVariant))
                    .foregroundStyle(theme.onSurface)

                LazyVStack(spacing: 8) {
                    ForEach(Cities.search(query)) { city in
                        Button {
                            apply(place: Place.fromCity(city), manual: true)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(city.displayName(language: theme.language))
                                        .font(theme.scaledFont(size: 15, weight: .semibold))
                                        .foregroundStyle(theme.onSurface)
                                    Text(city.displayCountry(language: theme.language))
                                        .font(theme.scaledFont(size: 12))
                                        .foregroundStyle(theme.onSurfaceVariant)
                                }
                                Spacer()
                                if appState.activePlace.cityName == city.name {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(theme.primary)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .sirajCardSurface(cornerRadius: 15)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 100)
        }
        .background(SirajRootBackdrop(activePrayer: appState.prayerDay.next?.type))
        .navigationTitle(theme.t("settings_location"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func apply(place: Place, manual: Bool) {
        let country = place.resolvedCountryCode
        appState.updateSettings {
            $0.cachedLocation = place
            $0.isManualLocation = manual
            $0.calculationMethod = CalculationMethods.recommended(forCountryCode: country)
            $0.madhab = CalculationMethods.recommendedMadhab(forCountryCode: country)
        }
    }
}
