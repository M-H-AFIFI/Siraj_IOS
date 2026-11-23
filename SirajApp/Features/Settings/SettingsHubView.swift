import SwiftUI
import SirajCore

enum SettingsRoute: Hashable {
    case location
    case calculation
    case reminders
    case appearance
    case language
    case widgets
    case about
}

struct SettingsHubView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    let locationService: LocationService
    let audioEngine: AdhanAudioEngine
    let scheduler: AdhanNotificationScheduler

    @State private var path = NavigationPath()

    var body: some View {
        let cityName = appState.activePlace.displayName(language: theme.language) ?? appState.activePlace.timeZoneId
        let activeVoice = AdhanVoiceResolver.findVoice(appState.settings.azanSound).localizedTitle(language: theme.language)

        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 20) {
                    headerCard(cityName: cityName)

                    SirajSettingsSection(title: theme.t("settings_section_prayer")) {
                        SirajSettingsRow(
                            icon: "location.fill",
                            title: theme.t("settings_location"),
                            value: cityName
                        ) {
                            path.append(SettingsRoute.location)
                        }
                        Divider().padding(.leading, 16)
                        SirajSettingsRow(
                            icon: "clock.badge.checkmark.fill",
                            title: theme.t("settings_prayer_calculation"),
                            value: CalculationMethods.byId(appState.settings.calculationMethod)?.name(language: theme.language)
                        ) {
                            path.append(SettingsRoute.calculation)
                        }
                        Divider().padding(.leading, 16)
                        SirajSettingsRow(
                            icon: "bell.badge.fill",
                            title: theme.t("settings_reminders"),
                            value: activeVoice
                        ) {
                            path.append(SettingsRoute.reminders)
                        }
                    }

                    appearanceQuickCard

                    SirajSettingsSection(title: theme.t("widget_settings_title")) {
                        SirajSettingsRow(
                            icon: "square.grid.2x2.fill",
                            title: theme.t("widget_gallery_browse"),
                            subtitle: theme.t("ios_lockscreen_widget_desc")
                        ) {
                            path.append(SettingsRoute.widgets)
                        }
                    }

                    SirajSettingsSection(title: theme.t("settings_section_language")) {
                        SirajSettingsRow(
                            icon: "globe",
                            title: theme.t("settings_section_language"),
                            value: languageNativeName(appState.settings.language)
                        ) {
                            path.append(SettingsRoute.language)
                        }
                    }

                    SirajSettingsSection(title: theme.t("settings_support_header")) {
                        SirajSettingsRow(
                            icon: "info.circle.fill",
                            title: theme.t("settings_about_siraj")
                        ) {
                            path.append(SettingsRoute.about)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 108)
            }
            .scrollIndicators(.hidden)
            .background(Color.clear)
            .navigationTitle(theme.t("settings_title"))
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .location:
                    LocationSettingsView(appState: appState, locationService: locationService)
                case .calculation:
                    PrayerCalculationSettingsView(appState: appState)
                case .reminders:
                    RemindersSettingsView(
                        appState: appState,
                        audioEngine: audioEngine,
                        scheduler: scheduler,
                        onOpenWidgets: { path.append(SettingsRoute.widgets) }
                    )
                case .appearance:
                    AppearanceSettingsView(appState: appState)
                case .language:
                    LanguageFormatSettingsView(appState: appState)
                case .widgets:
                    WidgetGalleryView(appState: appState)
                case .about:
                    AboutSirajView()
                }
            }
        }
        .onAppear {
            consumeRequestedRoute()
        }
        .onChange(of: appState.requestedRoute) { _, _ in
            consumeRequestedRoute()
        }
    }

    private func consumeRequestedRoute() {
        guard let route = appState.requestedRoute else { return }
        appState.requestedRoute = nil
        path = NavigationPath()
        switch route {
        case "appearance": path.append(SettingsRoute.appearance)
        case "reminders": path.append(SettingsRoute.reminders)
        case "widgets": path.append(SettingsRoute.widgets)
        case "location": path.append(SettingsRoute.location)
        case "language": path.append(SettingsRoute.language)
        case "about": path.append(SettingsRoute.about)
        default: break
        }
    }

    private func headerCard(cityName: String) -> some View {
        HStack(spacing: 10) {
            quickPill(icon: "location.fill", label: cityName) {
                path.append(SettingsRoute.location)
            }
            quickPill(icon: "globe", label: languageNativeName(appState.settings.language)) {
                path.append(SettingsRoute.language)
            }
            quickPill(icon: "paintpalette.fill", label: theme.t("settings_appearance_header")) {
                path.append(SettingsRoute.appearance)
            }
        }
    }

    private func quickPill(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.primary)
                Text(label)
                    .font(theme.scaledFont(size: 12.5, weight: .semibold))
                    .foregroundStyle(theme.onSurface)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .sirajCardSurface(cornerRadius: 16)
        }
        .buttonStyle(.plain)
    }

    private var appearanceQuickCard: some View {
        let modeBinding = Binding<ThemeMode>(
            get: { appState.settings.themeMode },
            set: { val in appState.updateSettings { $0.themeMode = val } }
        )

        return SirajSettingsSection(title: theme.t("settings_appearance_header")) {
            VStack(spacing: 14) {
                SirajSegmentedPills(options: ThemeMode.allCases, selection: modeBinding) { mode in
                    switch mode {
                    case .system: return theme.t("live_theme_mode_system")
                    case .light: return theme.t("live_theme_mode_light")
                    case .dark: return theme.t("live_theme_mode_dark")
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(SirajPalettes.all) { palette in
                            let selected = SirajPalettes.canonicalId(appState.settings.themePalette) == palette.id
                            let roles = theme.isDark ? palette.dark : palette.light
                            Button {
                                appState.updateSettings { $0.themePalette = palette.id }
                            } label: {
                                Circle()
                                    .fill(Color(argbHex: roles.primary))
                                    .frame(width: 34, height: 34)
                                    .overlay {
                                        if selected {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundStyle(Color(argbHex: roles.onPrimary))
                                        }
                                    }
                                    .overlay {
                                        Circle().strokeBorder(selected ? theme.onSurface : theme.outlineVariant, lineWidth: selected ? 2 : 1)
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                }

                Divider().padding(.leading, 16)

                SirajSettingsRow(
                    icon: "sparkles",
                    title: theme.t("settings_appearance_open_action"),
                    subtitle: theme.t("settings_appearance_card_subtitle")
                ) {
                    path.append(SettingsRoute.appearance)
                }
            }
        }
    }

    private func languageNativeName(_ code: String) -> String {
        switch SirajLocalizer.baseLanguage(code) {
        case "ar": return "العربية"
        case "tr": return "Türkçe"
        case "ur": return "اردو"
        default: return "English"
        }
    }
}
