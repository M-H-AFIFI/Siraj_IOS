import SwiftUI
import SirajCore

struct OnboardingWelcomeStep: View {
    @Environment(\.sirajTheme) private var theme

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Spacer(minLength: 28)

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [theme.gold.opacity(0.24), theme.primary.opacity(0.10), .clear],
                                center: .center,
                                startRadius: 12,
                                endRadius: 96
                            )
                        )
                        .frame(width: 180, height: 180)
                    SirajEmblemMark(height: 112, tint: theme.gold)
                }

                VStack(spacing: 10) {
                    Text(theme.t("app_name"))
                        .font(theme.scaledFont(size: 32, weight: .bold))
                        .foregroundStyle(theme.onBackground)

                    Text(theme.t("onb_easy_lang_desc"))
                        .font(theme.scaledFont(size: 16))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }

                VStack(spacing: 12) {
                    featurePill(icon: "sun.horizon.fill", title: theme.t("nav_prayer"))
                    featurePill(icon: "bell.badge.fill", title: theme.t("settings_reminders"))
                    featurePill(icon: "paintpalette.fill", title: theme.t("settings_appearance_header"))
                }
                .padding(.top, 8)
            }
            .padding(24)
        }
    }

    private func featurePill(icon: String, title: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.gold)
                .frame(width: 36, height: 36)
                .background(Circle().fill(theme.primary.opacity(0.14)))
            Text(title)
                .font(theme.scaledFont(size: 15, weight: .semibold))
                .foregroundStyle(theme.onSurface)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .sirajCardSurface(cornerRadius: 18)
    }
}

struct OnboardingLanguageStep: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState

    private let languages: [(code: String, native: String, english: String)] = [
        ("en", "English", "English"),
        ("ar", "العربية", "Arabic"),
        ("tr", "Türkçe", "Turkish"),
        ("ur", "اردو", "Urdu")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(theme.t("settings_language"))
                    .font(theme.scaledFont(size: 26, weight: .bold))
                    .foregroundStyle(theme.onBackground)

                VStack(spacing: 10) {
                    ForEach(languages, id: \.code) { item in
                        let selected = appState.settings.language == item.code
                        Button {
                            appState.updateSettings { $0.language = item.code }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.native)
                                        .font(theme.scaledFont(size: 17, weight: .bold))
                                        .foregroundStyle(theme.onSurface)
                                    Text(item.english)
                                        .font(theme.scaledFont(size: 13))
                                        .foregroundStyle(theme.onSurfaceVariant)
                                }
                                Spacer()
                                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22))
                                    .foregroundStyle(selected ? theme.primary : theme.outline)
                            }
                            .padding(16)
                            .sirajCardSurface(cornerRadius: 18)
                            .overlay {
                                if selected {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .strokeBorder(theme.primary, lineWidth: 1.8)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(24)
        }
    }
}

struct OnboardingLocationStep: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    let locationService: LocationService
    @Binding var cityQuery: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(theme.t("settings_location"))
                    .font(theme.scaledFont(size: 26, weight: .bold))
                    .foregroundStyle(theme.onBackground)

                if let loc = appState.settings.cachedLocation {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(theme.primary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(loc.displayName(language: theme.language) ?? loc.timeZoneId)
                                .font(theme.scaledFont(size: 16, weight: .bold))
                                .foregroundStyle(theme.onSurface)
                            Text(loc.timeZoneId)
                                .font(theme.scaledFont(size: 12))
                                .foregroundStyle(theme.onSurfaceVariant)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .sirajCardSurface(cornerRadius: 18)
                }

                Button {
                    Task {
                        if let place = await locationService.requestCurrentPlace() {
                            select(place: place, manual: false)
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        if locationService.isLocating {
                            ProgressView().tint(theme.onPrimary)
                        } else {
                            Image(systemName: "location.fill")
                        }
                        Text(theme.t("settings_automatic_gps"))
                            .font(theme.scaledFont(size: 15, weight: .bold))
                    }
                    .foregroundStyle(theme.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(theme.primary))
                }
                .buttonStyle(.plain)
                .disabled(locationService.isLocating)

                TextField(theme.t("settings_search_city_hint"), text: $cityQuery)
                    .padding(13)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.surfaceVariant))
                    .foregroundStyle(theme.onSurface)

                let matches = Cities.search(cityQuery, limit: 12)
                VStack(spacing: 8) {
                    ForEach(matches) { city in
                        Button {
                            select(place: Place.fromCity(city), manual: true)
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
                                if appState.settings.cachedLocation?.cityName == city.name {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(theme.primary)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 11)
                            .sirajCardSurface(cornerRadius: 14)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(24)
        }
    }

    private func select(place: Place, manual: Bool) {
        let country = place.resolvedCountryCode
        appState.updateSettings {
            $0.cachedLocation = place
            $0.isManualLocation = manual
            $0.calculationMethod = CalculationMethods.recommended(forCountryCode: country)
            $0.madhab = CalculationMethods.recommendedMadhab(forCountryCode: country)
        }
    }
}

struct OnboardingMethodStep: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(theme.t("settings_calc_method_title"))
                    .font(theme.scaledFont(size: 24, weight: .bold))
                    .foregroundStyle(theme.onBackground)

                VStack(spacing: 8) {
                    ForEach(CalculationMethods.all) { method in
                        let selected = appState.settings.calculationMethod == method.id
                        Button {
                            appState.updateSettings { $0.calculationMethod = method.id }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(method.name(language: theme.language))
                                        .font(theme.scaledFont(size: 15, weight: .semibold))
                                        .foregroundStyle(theme.onSurface)
                                    Text(method.whereUsed(language: theme.language))
                                        .font(theme.scaledFont(size: 12))
                                        .foregroundStyle(theme.onSurfaceVariant)
                                }
                                Spacer()
                                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selected ? theme.primary : theme.outline)
                            }
                            .padding(14)
                            .sirajCardSurface(cornerRadius: 16)
                            .overlay {
                                if selected {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(theme.primary, lineWidth: 1.6)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(24)
        }
    }
}

struct OnboardingAlertsStep: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    let onPreviewVoice: ((String) -> Void)?
    let onStopPreview: (() -> Void)?
    let onRequestNotifications: (() async -> Void)?
    @State private var granted = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(theme.t("settings_reminders"))
                    .font(theme.scaledFont(size: 26, weight: .bold))
                    .foregroundStyle(theme.onBackground)

                Text(theme.t("ios_notification_sound_note"))
                    .font(theme.scaledFont(size: 14))
                    .foregroundStyle(theme.onSurfaceVariant)

                Button {
                    Task {
                        await onRequestNotifications?()
                        granted = true
                    }
                } label: {
                    HStack {
                        Image(systemName: granted ? "bell.badge.fill" : "bell.fill")
                        Text(theme.t("onboarding_alerts_master"))
                            .font(theme.scaledFont(size: 15, weight: .bold))
                    }
                    .foregroundStyle(theme.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Capsule().fill(theme.primary))
                }
                .buttonStyle(.plain)

                VStack(spacing: 8) {
                    ForEach(AdhanCatalog.voices.prefix(6)) { voice in
                        let selected = appState.settings.azanSound == voice.id
                        HStack(spacing: 12) {
                            Button {
                                appState.updateSettings { $0.azanSound = voice.id }
                            } label: {
                                HStack {
                                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selected ? theme.primary : theme.outline)
                                    Text(voice.localizedTitle(language: theme.language))
                                        .font(theme.scaledFont(size: 14, weight: .semibold))
                                        .foregroundStyle(theme.onSurface)
                                        .lineLimit(2)
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)

                            if let onPreviewVoice {
                                Button {
                                    onPreviewVoice(voice.id)
                                } label: {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(theme.primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(14)
                        .sirajCardSurface(cornerRadius: 16)
                    }
                }
            }
            .padding(24)
        }
    }
}

struct OnboardingAppearanceStep: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(theme.t("settings_appearance_header"))
                    .font(theme.scaledFont(size: 26, weight: .bold))
                    .foregroundStyle(theme.onBackground)

                SirajSegmentedPills(
                    options: ThemeMode.allCases,
                    selection: Binding(
                        get: { appState.settings.themeMode },
                        set: { mode in appState.updateSettings { $0.themeMode = mode } }
                    )
                ) { mode in
                    switch mode {
                    case .system: return theme.t("live_theme_mode_system")
                    case .light: return theme.t("live_theme_mode_light")
                    case .dark: return theme.t("live_theme_mode_dark")
                    }
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(SirajPalettes.all) { pal in
                        let selected = appState.settings.themePalette == pal.id
                        Button {
                            appState.updateSettings { $0.themePalette = pal.id }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color(argbHex: theme.isDark ? pal.dark.primary : pal.light.primary))
                                    .frame(width: 44, height: 44)
                                if selected {
                                    Circle()
                                        .strokeBorder(theme.onBackground, lineWidth: 2.5)
                                        .frame(width: 52, height: 52)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(Color(argbHex: theme.isDark ? pal.dark.onPrimary : pal.light.onPrimary))
                                }
                            }
                            .frame(height: 54)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .sirajCardSurface(cornerRadius: 20)

                VStack(spacing: 0) {
                    SirajSettingsToggleRow(
                        icon: "moon.stars.fill",
                        title: theme.t("live_theme_amoled_title"),
                        isOn: Binding(
                            get: { appState.settings.isAmoled },
                            set: { on in appState.updateSettings { $0.isAmoled = on } }
                        )
                    )
                    Divider().padding(.leading, 62)
                    SirajSettingsToggleRow(
                        icon: "sparkles",
                        title: theme.t("appearance_glass_ui"),
                        isOn: Binding(
                            get: { appState.settings.isGlassUi },
                            set: { on in appState.updateSettings { $0.isGlassUi = on } }
                        )
                    )
                }
                .sirajCardSurface(cornerRadius: 20)
            }
            .padding(24)
        }
    }
}
