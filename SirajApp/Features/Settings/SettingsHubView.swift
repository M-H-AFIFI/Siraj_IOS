import SwiftUI
import SirajCore

enum SettingsRoute: Hashable {
    case location
    case calculation
    case reminders
    case quranSettings
    case bookmarks
    case quranVideo
    case appearance
    case language
    case widgets
    case guide
    case about
}

private struct GuideSheetSession: Identifiable {
    let id = UUID()
    let topic: GuideTopic
    let isTour: Bool
}

struct SettingsHubView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    let locationService: LocationService
    let audioEngine: AdhanAudioEngine
    let scheduler: AdhanNotificationScheduler
    let onOpenReader: (ReaderDestination) -> Void

    @State private var path = NavigationPath()
    @State private var activeGuideSession: GuideSheetSession?

    var body: some View {
        let cityName = appState.activePlace.displayName(language: theme.language)
        let activeVoice = AdhanVoiceResolver.findVoice(appState.settings.azanSound).localizedTitle(language: theme.language)
        let digitsSample = DigitFormatter.useEastern(
            numeralSystem: appState.settings.numeralSystem,
            lang: theme.language
        ) ? "١٢٣" : "123"
        let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 24) {
                    settingsHeader(
                        cityName: cityName,
                        languageName: languageNativeName(appState.settings.language),
                        version: versionString
                    )

                    SirajSettingsSection(title: theme.t("settings_section_prayer"), icon: "clock.fill") {
                        SirajSettingsRow(
                            icon: "location.fill",
                            title: theme.t("settings_location_and_prayer_times"),
                            value: cityName ?? theme.t("settings_not_set")
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

                    appearanceHeroCardSection

                    SirajSettingsSection(title: theme.t("settings_section_quran"), icon: "book.closed.fill") {
                        SirajSettingsRow(
                            icon: "book.pages.fill",
                            title: theme.t("settings_quran_mushaf"),
                            subtitle: theme.t("settings_quran_mushaf_desc")
                        ) {
                            path.append(SettingsRoute.quranSettings)
                        }
                        Divider().padding(.leading, 16)
                        SirajSettingsRow(
                            icon: "bookmark.fill",
                            title: theme.t("bookmarks_screen_title"),
                            value: appState.quranStore.bookmarks.isEmpty ? nil : theme.digits(String(appState.quranStore.bookmarks.count))
                        ) {
                            path.append(SettingsRoute.bookmarks)
                        }
                        Divider().padding(.leading, 16)
                        SirajSettingsRow(
                            icon: "film.stack.fill",
                            title: theme.t("settings_quran_video_title"),
                            subtitle: theme.t("settings_quran_video_desc")
                        ) {
                            path.append(SettingsRoute.quranVideo)
                        }
                    }

                    SirajSettingsSection(title: theme.t("settings_section_language"), icon: "globe") {
                        SirajSettingsRow(
                            icon: "globe",
                            title: theme.t("settings_language"),
                            value: "\(languageNativeName(appState.settings.language)) | \(digitsSample)"
                        ) {
                            path.append(SettingsRoute.language)
                        }
                    }

                    SirajSettingsSection(title: theme.t("settings_support_header"), icon: "info.circle.fill") {
                        SirajSettingsRow(
                            icon: "book.and.wrench.fill",
                            title: theme.t("settings_guide_title"),
                            subtitle: theme.t("settings_guide_body")
                        ) {
                            path.append(SettingsRoute.guide)
                        }
                        Divider().padding(.leading, 16)
                        SirajSettingsRow(
                            icon: "info.circle.fill",
                            title: theme.t("settings_about_siraj"),
                            value: "v\(versionString)"
                        ) {
                            path.append(SettingsRoute.about)
                        }
                    }

                    Text("« وَدَاعِيًا إِلَى اللَّهِ بِإِذْنِهِ وَسِرَاجًا مُّنِيرًا »")
                        .font(theme.amiriFont(size: 14.5))
                        .foregroundStyle(theme.outline)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                        .padding(.bottom, 20)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 104)
            }
            .scrollIndicators(.hidden)
            .scrollCollapseTracker(
                enabled: appState.settings.isNavShrinkEnabled && !appState.settings.isNavAlwaysCompact,
                isCollapsed: Binding(
                    get: { appState.isTabBarCollapsed },
                    set: { appState.isTabBarCollapsed = $0 }
                )
            )
            .background(Color.clear)
            .navigationTitle(theme.t("settings_title"))
            .navigationBarTitleDisplayMode(.inline)
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
                case .quranSettings:
                    QuranSettingsView(appState: appState, quranStore: appState.quranStore)
                case .bookmarks:
                    BookmarksView(appState: appState, quranStore: appState.quranStore) { surah, ayah in
                        let ed = MushafEdition.resolve(appState.settings.mushafEdition)
                        let page = appState.quranStore.pageForAyah(surah: surah, ayah: ayah, edition: ed)
                        onOpenReader(ReaderDestination(page: page, surahNumber: surah, ayahNumber: ayah))
                    }
                case .quranVideo:
                    QuranVideoView(appState: appState, quranStore: appState.quranStore)
                case .appearance:
                    AppearanceSettingsView(appState: appState)
                case .language:
                    LanguageFormatSettingsView(appState: appState)
                case .widgets:
                    WidgetGalleryView(appState: appState)
                case .guide:
                    InteractiveGuideView(
                        appState: appState,
                        guideStore: appState.guideStore
                    ) { topic, isTour in
                        activeGuideSession = GuideSheetSession(topic: topic, isTour: isTour)
                    }
                case .about:
                    AboutSirajView()
                }
            }
            .fullScreenCover(item: $activeGuideSession) { session in
                GuideTopicPagerView(
                    appState: appState,
                    guideStore: appState.guideStore,
                    initialTopic: session.topic,
                    isTourMode: session.isTour
                ) { topic in
                    appState.navigateForGuideTopic(topic)
                }
            }
        }
        .task {
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
        case "quran_settings": path.append(SettingsRoute.quranSettings)
        case "bookmarks": path.append(SettingsRoute.bookmarks)
        case "widgets": path.append(SettingsRoute.widgets)
        case "guide": path.append(SettingsRoute.guide)
        case "location": path.append(SettingsRoute.location)
        case "language": path.append(SettingsRoute.language)
        case "about": path.append(SettingsRoute.about)
        default: break
        }
    }

    // MARK: - Branded Header Card

    private func settingsHeader(cityName: String?, languageName: String, version: String) -> some View {
        let iconDef = SirajAppIconCatalog.definition(for: appState.settings.selectedAppIcon)
        let headerShape = RoundedRectangle(cornerRadius: 28, style: .continuous)
        let modeIcon: String = {
            switch appState.settings.themeMode {
            case .light: return "sun.max.fill"
            case .dark: return "moon.fill"
            case .system: return "circle.lefthalf.filled"
            }
        }()
        let modeLabel: String = {
            switch appState.settings.themeMode {
            case .light: return theme.t("settings_light")
            case .dark: return theme.t("settings_dark")
            case .system: return theme.t("settings_system_default")
            }
        }()

        return VStack(spacing: 16) {
            HStack(spacing: 14) {
                SirajAppIconBadge(icon: iconDef, size: 56, cornerRadius: 16, showAmbientGlow: true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.t("app_name"))
                        .font(theme.scaledFont(size: 22, weight: .black))
                        .foregroundStyle(theme.onSurface)
                    Text("وَسِرَاجًا مُّنِيرًا")
                        .font(theme.amiriFont(size: 16))
                        .foregroundStyle(theme.primary)
                }

                Spacer()

                Text("v\(version)")
                    .font(theme.scaledFont(size: 12, weight: .bold))
                    .foregroundStyle(theme.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(theme.primary.opacity(0.12)))
            }

            HStack(spacing: 8) {
                quickSettingChip(
                    icon: "globe",
                    value: languageName,
                    label: theme.t("settings_language")
                ) {
                    path.append(SettingsRoute.language)
                }

                quickSettingChip(
                    icon: modeIcon,
                    value: modeLabel,
                    label: theme.t("settings_appearance_header")
                ) {
                    path.append(SettingsRoute.appearance)
                }

                quickSettingChip(
                    icon: "location.fill",
                    value: cityName ?? theme.t("settings_not_set"),
                    label: theme.t("settings_location")
                ) {
                    path.append(SettingsRoute.location)
                }
            }
        }
        .padding(18)
        .background {
            if !theme.isGlass {
                headerShape.fill(
                    LinearGradient(
                        colors: [
                            theme.primaryContainer.opacity(theme.isDark ? 0.55 : 0.85),
                            theme.surface
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .sirajCardSurface(cornerRadius: 28, isElevated: true)
    }

    private func quickSettingChip(icon: String, value: String, label: String, action: @escaping () -> Void) -> some View {
        let chipShape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        return Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(theme.primary)
                Text(value)
                    .font(theme.scaledFont(size: 13, weight: .black))
                    .foregroundStyle(theme.onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(label)
                    .font(theme.scaledFont(size: 10.5, weight: .medium))
                    .foregroundStyle(theme.outline)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .background(chipShape.fill(theme.isGlass ? theme.surface.opacity(theme.isDark ? 0.24 : 0.48) : theme.surface))
            .overlay(chipShape.strokeBorder(theme.outlineVariant.opacity(0.5), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Appearance Hero Card + Widgets Entry

    private var appearanceHeroCardSection: some View {
        let activeIcon = SirajAppIconCatalog.definition(for: appState.settings.selectedAppIcon)
        let activePalette = SirajPalettes.canonicalId(appState.settings.themePalette)
        let activeScene = LiveThemeCatalog.definition(for: appState.settings.liveTheme)
        let paletteSpec = SirajColorSchemeSpec.resolve(palette: activePalette, isDark: theme.isDark, isBlack: theme.isBlack)
        let bannerShape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        let lensShape = RoundedRectangle(cornerRadius: 15, style: .continuous)

        let modeIcon: String = {
            if theme.isDark && appState.settings.isAmoled { return "moon.stars.fill" }
            switch appState.settings.themeMode {
            case .light: return "sun.max.fill"
            case .dark: return "moon.fill"
            case .system: return "circle.lefthalf.filled"
            }
        }()
        let modeLabel: String = {
            if theme.isDark && appState.settings.isAmoled { return theme.t("appearance_black") }
            switch appState.settings.themeMode {
            case .light: return theme.t("settings_light")
            case .dark: return theme.t("settings_dark")
            case .system: return theme.t("settings_system_default")
            }
        }()
        let backgroundLabel = appState.settings.isLiveBackgroundEnabled
            ? theme.t(activeScene.titleKey)
            : theme.t("looks_background_plain")
        let textSizeLabel: String = {
            let s = appState.settings.textScale
            if s >= 1.22 { return theme.t("guide_text_size_largest") }
            if s >= 1.08 { return theme.t("guide_text_size_large") }
            return theme.t("guide_text_size_default")
        }()

        return VStack(spacing: 14) {
            Button {
                path.append(SettingsRoute.appearance)
            } label: {
                VStack(spacing: 14) {
                    // Live miniature visual stage banner
                    ZStack {
                        LinearGradient(
                            colors: [
                                Color(argb: paletteSpec.primary).opacity(theme.isDark ? 0.34 : 0.22),
                                Color(argb: paletteSpec.secondary).opacity(theme.isDark ? 0.22 : 0.14),
                                Color(argbHex: theme.isDark ? 0xFF121822 : 0xFFF6F8FC)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        if appState.settings.isLiveBackgroundEnabled {
                            LiveSceneArtwork(
                                themeId: activeScene.id,
                                intensity: appState.settings.liveBackgroundIntensity,
                                isTimeSyncEnabled: appState.settings.isWeatherBackgroundEnabled,
                                animate: true,
                                fps: 20.0,
                                speedScale: 0.85
                            )
                            let stageColors = LiveSceneDrawColors.resolve(
                                scheme: theme.scheme,
                                isTimeSyncEnabled: appState.settings.isWeatherBackgroundEnabled
                            )
                            LinearGradient(
                                colors: [
                                    stageColors.veil.color(alpha: theme.isDark ? 0.24 : 0.16),
                                    stageColors.veil.color(alpha: theme.isDark ? 0.36 : 0.24)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }

                        HStack(spacing: 12) {
                            SirajAppIconBadge(icon: activeIcon, size: 50, cornerRadius: 14, showAmbientGlow: true)

                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 5) {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(theme.primary)
                                    Text(theme.t("appearance_preview_badge"))
                                        .font(theme.scaledFont(size: 11, weight: .bold))
                                        .foregroundStyle(theme.primary)
                                        .lineLimit(1)
                                }
                                Capsule()
                                    .fill(theme.onSurface.opacity(0.42))
                                    .frame(width: 92, height: 6)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background {
                                if appState.settings.isGlassUi {
                                    lensShape.fill(.ultraThinMaterial)
                                        .overlay(lensShape.fill(theme.primary.opacity(0.10)))
                                } else {
                                    lensShape.fill(theme.surface.opacity(theme.isDark ? 0.88 : 0.92))
                                }
                            }
                            .overlay(
                                lensShape.strokeBorder(
                                    appState.settings.isGlassUi
                                        ? Color.white.opacity(theme.isDark ? 0.26 : 0.65)
                                        : theme.outlineVariant.opacity(0.35),
                                    lineWidth: 1
                                )
                            )

                            Spacer(minLength: 4)

                            if appState.settings.isGlassUi {
                                Text(theme.t("appearance_glass_badge"))
                                    .font(theme.scaledFont(size: 10.5, weight: .bold))
                                    .foregroundStyle(theme.primary)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(theme.surface.opacity(theme.isDark ? 0.62 : 0.82)))
                                    .overlay(Capsule().strokeBorder(Color.white.opacity(theme.isDark ? 0.26 : 0.65), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                    }
                    .frame(height: 126)
                    .clipShape(bannerShape)
                    .overlay(
                        bannerShape.strokeBorder(Color.white.opacity(theme.isDark ? 0.18 : 0.62), lineWidth: 1)
                    )

                    // Title + Customize pill
                    HStack(spacing: 12) {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(theme.primary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(theme.primary.opacity(0.12)))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(theme.t("settings_appearance_header"))
                                .font(theme.scaledFont(size: 16, weight: .black))
                                .foregroundStyle(theme.onSurface)
                            Text(theme.t("settings_appearance_card_subtitle"))
                                .font(theme.scaledFont(size: 12))
                                .foregroundStyle(theme.onSurfaceVariant)
                                .lineLimit(2)
                        }

                        Spacer(minLength: 6)

                        HStack(spacing: 3) {
                            Text(theme.t("settings_appearance_open_action"))
                                .font(theme.scaledFont(size: 12, weight: .bold))
                            Image(systemName: theme.isRTL ? "chevron.left" : "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(theme.primary)
                        .padding(.leading, 12)
                        .padding(.trailing, 8)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(theme.primary.opacity(theme.isDark ? 0.20 : 0.12)))
                        .overlay(Capsule().strokeBorder(theme.primary.opacity(0.32), lineWidth: 1))
                    }
                    .padding(.horizontal, 4)

                    // Active look summary chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            summaryChip(label: theme.t(AppearanceSettingsView.paletteTitleKey(activePalette))) {
                                Circle()
                                    .fill(Color(argb: paletteSpec.primary))
                                    .frame(width: 14, height: 14)
                                    .overlay(Circle().strokeBorder(theme.outlineVariant.opacity(0.5), lineWidth: 0.75))
                            }
                            summaryChip(label: modeLabel) {
                                Image(systemName: modeIcon)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(theme.primary)
                            }
                            summaryChip(label: backgroundLabel) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(theme.primary)
                            }
                            summaryChip(label: textSizeLabel) {
                                Image(systemName: "textformat.size")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(theme.primary)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
                .padding(14)
                .sirajCardSurface(cornerRadius: 28, isElevated: true)
            }
            .buttonStyle(.plain)

            // Home Screen Widgets entry directly beneath Appearance
            VStack(spacing: 0) {
                SirajSettingsRow(
                    icon: "square.grid.2x2.fill",
                    title: theme.t("widget_settings_title"),
                    subtitle: theme.t("widget_gallery_browse")
                ) {
                    path.append(SettingsRoute.widgets)
                }
            }
            .sirajCardSurface(cornerRadius: 22)
        }
    }

    private func summaryChip<Leading: View>(label: String, @ViewBuilder leading: () -> Leading) -> some View {
        HStack(spacing: 6) {
            leading()
            Text(label)
                .font(theme.scaledFont(size: 12, weight: .semibold))
                .foregroundStyle(theme.onSurface)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(theme.isGlass ? theme.surface.opacity(theme.isDark ? 0.26 : 0.50) : theme.surfaceContainerHigh.opacity(0.65)))
        .overlay(Capsule().strokeBorder(theme.outlineVariant.opacity(0.4), lineWidth: 1))
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
