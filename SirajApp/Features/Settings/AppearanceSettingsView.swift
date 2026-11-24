import SwiftUI
import SirajCore

private enum TextSizePreset: Double, CaseIterable, Identifiable {
    case standard = 1.0
    case large = 1.15
    case largest = 1.30

    var id: Double { rawValue }

    static func nearest(to value: Double) -> TextSizePreset {
        if value >= 1.22 { return .largest }
        if value >= 1.08 { return .large }
        return .standard
    }
}

struct AppearanceSettingsView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState

    @State private var showIconPicker = false

    private let paletteCols = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        let modeBinding = Binding<ThemeMode>(
            get: { appState.settings.themeMode },
            set: { val in appState.updateSettings { $0.themeMode = val } }
        )
        let finishBinding = Binding<GlassFinish>(
            get: { appState.settings.glassFinish },
            set: { val in appState.updateSettings { $0.glassFinish = val } }
        )
        let intensityBinding = Binding<LiveBackgroundIntensity>(
            get: { appState.settings.liveBackgroundIntensity },
            set: { val in appState.updateSettings { $0.liveBackgroundIntensity = val } }
        )
        let navStyleBinding = Binding<NavBarStyle>(
            get: { appState.settings.navBarStyle },
            set: { val in appState.updateSettings { $0.navBarStyle = val } }
        )
        let textPresetBinding = Binding<TextSizePreset>(
            get: { TextSizePreset.nearest(to: appState.settings.textScale) },
            set: { preset in appState.updateSettings { $0.textScale = preset.rawValue } }
        )
        let isArabicDigits = DigitFormatter.shouldUseArabicDigits(
            numeralSystem: appState.settings.numeralSystem,
            lang: theme.language
        )

        ScrollView {
            VStack(spacing: 20) {
                heroPreviewCard

                // 2. Colour palettes (2-column 60pt tiles)
                SirajSettingsSection(title: theme.t("live_theme_classic_palettes_title"), icon: "paintpalette.fill") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(theme.t("live_theme_classic_palettes_desc"))
                            .font(theme.scaledFont(size: 12.5))
                            .foregroundStyle(theme.onSurfaceVariant)

                        LazyVGrid(columns: paletteCols, spacing: 10) {
                            ForEach(SirajPalettes.all) { palette in
                                paletteTile(palette)
                            }
                        }
                    }
                    .padding(14)
                }

                // 3. Background: Plain or Live Scene + Intensity + Sky Sync
                SirajSettingsSection(title: theme.t("looks_background_title"), icon: "sparkles") {
                    SirajSettingsToggleRow(
                        icon: "sparkles",
                        title: theme.t("live_theme_live_bg_title"),
                        subtitle: theme.t("live_theme_live_bg_desc"),
                        isOn: Binding(
                            get: { appState.settings.isLiveBackgroundEnabled },
                            set: { v in appState.updateSettings { $0.isLiveBackgroundEnabled = v } }
                        )
                    )

                    if appState.settings.isLiveBackgroundEnabled {
                        Divider().padding(.leading, 16)

                        VStack(alignment: .leading, spacing: 12) {
                            Text(theme.t("looks_background_desc"))
                                .font(theme.scaledFont(size: 12.5))
                                .foregroundStyle(theme.onSurfaceVariant)
                                .padding(.horizontal, 16)

                            LiveScenePicker(
                                selectedSceneId: appState.settings.isLiveBackgroundEnabled ? appState.settings.liveTheme : nil
                            ) { chosenId in
                                appState.updateSettings { snap in
                                    if let chosenId {
                                        snap.isLiveBackgroundEnabled = true
                                        snap.liveTheme = chosenId
                                    } else {
                                        snap.isLiveBackgroundEnabled = false
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 12)

                        Divider().padding(.leading, 16)

                        VStack(alignment: .leading, spacing: 10) {
                            Text(theme.t("live_theme_intensity_title"))
                                .font(theme.scaledFont(size: 14, weight: .semibold))
                                .foregroundStyle(theme.onSurface)
                            Text(theme.t("live_theme_intensity_desc"))
                                .font(theme.scaledFont(size: 12))
                                .foregroundStyle(theme.onSurfaceVariant)
                            SirajSegmentedPills(options: LiveBackgroundIntensity.allCases, selection: intensityBinding) { item in
                                switch item {
                                case .subtle: return theme.t("live_theme_intensity_subtle")
                                case .balanced: return theme.t("live_theme_intensity_balanced")
                                case .vivid: return theme.t("live_theme_intensity_vivid")
                                }
                            }
                        }
                        .padding(16)

                        Divider().padding(.leading, 16)

                        SirajSettingsToggleRow(
                            icon: "sun.horizon.fill",
                            title: theme.t("live_theme_sky_sync_title"),
                            subtitle: theme.t("live_theme_sky_sync_desc"),
                            isOn: Binding(
                                get: { appState.settings.isWeatherBackgroundEnabled },
                                set: { v in appState.updateSettings { $0.isWeatherBackgroundEnabled = v } }
                            )
                        )
                    }
                }

                // 4. Colour mode (Auto / Light / Dark + True Black when dark)
                SirajSettingsSection(title: theme.t("live_theme_mode_title"), icon: "circle.lefthalf.filled") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(theme.t("settings_dark_mode"))
                            .font(theme.scaledFont(size: 14.5, weight: .semibold))
                            .foregroundStyle(theme.onSurface)
                        Text(theme.t("settings_dark_mode_desc"))
                            .font(theme.scaledFont(size: 12))
                            .foregroundStyle(theme.onSurfaceVariant)
                        SirajSegmentedPills(options: ThemeMode.allCases, selection: modeBinding) { mode in
                            switch mode {
                            case .system: return theme.t("settings_system_default")
                            case .light: return theme.t("settings_light")
                            case .dark: return theme.t("settings_dark")
                            }
                        }
                    }
                    .padding(16)

                    if theme.isDark {
                        Divider().padding(.leading, 16)
                        SirajSettingsToggleRow(
                            icon: "moon.stars.fill",
                            title: theme.t("live_theme_amoled_title"),
                            subtitle: theme.t("live_theme_amoled_desc"),
                            isOn: Binding(
                                get: { appState.settings.isAmoled },
                                set: { v in appState.updateSettings { $0.isAmoled = v } }
                            )
                        )
                    }
                }

                // 5. Liquid Glass
                SirajSettingsSection(title: theme.t("appearance_glass_ui"), icon: "sparkles.rectangle.stack.fill") {
                    SirajSettingsToggleRow(
                        icon: "sparkles.rectangle.stack.fill",
                        title: theme.t("appearance_glass_ui"),
                        subtitle: theme.t("appearance_glass_ui_desc"),
                        isOn: Binding(
                            get: { appState.settings.isGlassUi },
                            set: { v in appState.updateSettings { $0.isGlassUi = v } }
                        )
                    )
                    if appState.settings.isGlassUi {
                        Divider().padding(.leading, 16)
                        VStack(alignment: .leading, spacing: 10) {
                            Text(theme.t("live_theme_glass_style_title"))
                                .font(theme.scaledFont(size: 14, weight: .semibold))
                                .foregroundStyle(theme.onSurface)
                            Text(theme.t("appearance_glass_mesh_desc"))
                                .font(theme.scaledFont(size: 12))
                                .foregroundStyle(theme.onSurfaceVariant)
                            SirajSegmentedPills(options: GlassFinish.allCases, selection: finishBinding) { finish in
                                switch finish {
                                case .clear: return theme.t("live_theme_glass_style_clear")
                                case .satin: return theme.t("live_theme_glass_style_satin")
                                case .frosted: return theme.t("live_theme_glass_style_frosted")
                                }
                            }
                        }
                        .padding(16)

                        Divider().padding(.leading, 16)

                        SirajSettingsToggleRow(
                            icon: "gauge.with.needle.fill",
                            title: theme.t("glass_performance_mode_title"),
                            subtitle: theme.t("glass_performance_mode_desc"),
                            isOn: Binding(
                                get: { appState.settings.isGlassPerformanceMode },
                                set: { v in appState.updateSettings { $0.isGlassPerformanceMode = v } }
                            )
                        )
                    }
                }

                // 6. Floating Tab Bar
                SirajSettingsSection(title: theme.t("appearance_nav_section_title"), icon: "dock.rectangle") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(theme.t("appearance_nav_style_title"))
                            .font(theme.scaledFont(size: 14, weight: .semibold))
                            .foregroundStyle(theme.onSurface)
                        Text(theme.t("appearance_nav_style_desc"))
                            .font(theme.scaledFont(size: 12))
                            .foregroundStyle(theme.onSurfaceVariant)
                        SirajSegmentedPills(options: NavBarStyle.allCases, selection: navStyleBinding) { style in
                            switch style {
                            case .rounded: return theme.t("appearance_nav_style_rounded")
                            case .compact: return theme.t("appearance_nav_style_pill")
                            }
                        }
                    }
                    .padding(16)

                    Divider().padding(.leading, 16)

                    SirajSettingsToggleRow(
                        icon: "rectangle.compress.vertical",
                        title: theme.t("appearance_nav_always_small_title"),
                        subtitle: theme.t("appearance_nav_always_small_desc"),
                        isOn: Binding(
                            get: { appState.settings.isNavAlwaysCompact },
                            set: { v in appState.updateSettings { $0.isNavAlwaysCompact = v } }
                        )
                    )

                    if !appState.settings.isNavAlwaysCompact {
                        Divider().padding(.leading, 16)
                        SirajSettingsToggleRow(
                            icon: "arrow.up.and.down.text.horizontal",
                            title: theme.t("appearance_nav_shrink_title"),
                            subtitle: theme.t("appearance_nav_shrink_desc"),
                            isOn: Binding(
                                get: { appState.settings.isNavShrinkEnabled },
                                set: { v in appState.updateSettings { $0.isNavShrinkEnabled = v } }
                            )
                        )
                    }
                }

                // 7. App Icon Showcase + 12-Icon Quick-Select Strip
                SirajSettingsSection(title: theme.t("appearance_icon_section_title"), icon: "square.grid.2x2.fill") {
                    appIconShowcaseSection
                }

                // 8. Numerals, Text Size & Motion
                SirajSettingsSection(title: theme.t("appearance_numerals_section_title"), icon: "textformat.size") {
                    SirajSettingsToggleRow(
                        icon: "book.closed.fill",
                        title: theme.t("live_theme_arabic_numerals_title"),
                        subtitle: theme.t("live_theme_arabic_numerals_desc"),
                        isOn: Binding(
                            get: { isArabicDigits },
                            set: { checked in
                                appState.updateSettings { $0.numeralSystem = checked ? "Arabic" : "English" }
                            }
                        )
                    )

                    Divider().padding(.leading, 16)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(theme.t("guide_text_size_title"))
                            .font(theme.scaledFont(size: 14.5, weight: .semibold))
                            .foregroundStyle(theme.onSurface)
                        Text(theme.t("guide_text_size_body"))
                            .font(theme.scaledFont(size: 12))
                            .foregroundStyle(theme.onSurfaceVariant)
                        SirajSegmentedPills(options: TextSizePreset.allCases, selection: textPresetBinding) { preset in
                            switch preset {
                            case .standard: return theme.t("guide_text_size_default")
                            case .large: return theme.t("guide_text_size_large")
                            case .largest: return theme.t("guide_text_size_largest")
                            }
                        }
                    }
                    .padding(16)

                    Divider().padding(.leading, 16)

                    SirajSettingsToggleRow(
                        icon: "hare.fill",
                        title: theme.t("settings_reduce_motion"),
                        subtitle: theme.t("settings_motion_desc"),
                        isOn: Binding(
                            get: { appState.settings.isReduceMotionEnabled },
                            set: { v in appState.updateSettings { $0.isReduceMotionEnabled = v } }
                        )
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 108)
        }
        .scrollIndicators(.hidden)
        .background(Color.clear)
        .navigationTitle(theme.t("settings_appearance_header"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showIconPicker) {
            AppIconPickerSheet(appState: appState)
        }
    }

    // MARK: - Live Hero Preview Card

    private var heroPreviewCard: some View {
        let activePalette = SirajPalettes.canonicalId(appState.settings.themePalette)
        let activeScene = LiveThemeCatalog.definition(for: appState.settings.liveTheme)
        let activeIcon = SirajAppIconCatalog.definition(for: appState.settings.selectedAppIcon)
        let paletteName = theme.t(Self.paletteTitleKey(activePalette))
        let modeLabel: String = {
            if theme.isDark && appState.settings.isAmoled { return theme.t("live_theme_amoled_title") }
            switch appState.settings.themeMode {
            case .light: return theme.t("settings_light")
            case .dark: return theme.t("settings_dark")
            case .system: return theme.t("settings_system_default")
            }
        }()
        let heroShape = RoundedRectangle(cornerRadius: 28, style: .continuous)
        let innerShape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        let sceneColors = LiveSceneDrawColors.resolve(
            scheme: theme.scheme,
            isTimeSyncEnabled: appState.settings.isWeatherBackgroundEnabled
        )

        return ZStack {
            LinearGradient(
                colors: [
                    theme.primaryContainer.opacity(theme.isDark ? 0.45 : 0.78),
                    theme.isGlass ? theme.surfaceContainerLow.opacity(theme.isDark ? 0.78 : 0.88) : theme.surface
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            if appState.settings.isLiveBackgroundEnabled {
                LiveSceneArtwork(
                    themeId: activeScene.id,
                    intensity: appState.settings.liveBackgroundIntensity,
                    isTimeSyncEnabled: appState.settings.isWeatherBackgroundEnabled,
                    animate: true,
                    fps: 24.0
                )
                LinearGradient(
                    stops: [
                        .init(color: sceneColors.veil.color(alpha: theme.isDark ? 0.30 : 0.24), location: 0.0),
                        .init(color: sceneColors.veil.color(alpha: 0.10), location: 0.5),
                        .init(color: sceneColors.veil.color(alpha: theme.isDark ? 0.34 : 0.26), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }

            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    SirajAppIconBadge(icon: activeIcon, size: 42, cornerRadius: 12)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(theme.t("app_name"))
                            .font(theme.scaledFont(size: 16, weight: .bold))
                            .foregroundStyle(theme.onSurface)
                        HStack(spacing: 6) {
                            Circle()
                                .fill(theme.primary)
                                .frame(width: 8, height: 8)
                            Text("\(paletteName)  ·  \(modeLabel)")
                                .font(theme.scaledFont(size: 11.5, weight: .semibold))
                                .foregroundStyle(theme.onSurfaceVariant)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                }

                VStack(spacing: 8) {
                    HStack(spacing: 7) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(theme.primary)
                        Text(theme.t("appearance_preview_badge"))
                            .font(theme.scaledFont(size: 12.5, weight: .bold))
                            .foregroundStyle(theme.primary)
                    }

                    Text(theme.t("appearance_preview_ayah"))
                        .font(.system(size: 15 * theme.textScale, weight: .medium))
                        .foregroundStyle(theme.onSurface)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background {
                    if appState.settings.isGlassUi {
                        innerShape.fill(.ultraThinMaterial)
                            .overlay(innerShape.fill(theme.surface.opacity(theme.isDark ? 0.22 : 0.42)))
                    } else {
                        innerShape.fill(theme.surfaceContainerHigh.opacity(theme.isDark ? 0.90 : 0.92))
                    }
                }
                .overlay(
                    innerShape.strokeBorder(
                        appState.settings.isGlassUi
                            ? Color.white.opacity(theme.isDark ? 0.22 : 0.58)
                            : theme.outlineVariant.opacity(0.35),
                        lineWidth: 1
                    )
                )
            }
            .padding(18)
        }
        .clipShape(heroShape)
        .overlay(
            heroShape.strokeBorder(
                appState.settings.isGlassUi
                    ? Color.white.opacity(theme.isDark ? 0.22 : 0.58)
                    : theme.outlineVariant.opacity(theme.isDark ? 0.50 : 0.60),
                lineWidth: 1
            )
        )
    }

    // MARK: - 2-Column 60pt Palette Tile

    private func paletteTile(_ palette: PaletteDefinition) -> some View {
        let selected = SirajPalettes.canonicalId(appState.settings.themePalette) == palette.id
        let spec = SirajColorSchemeSpec.resolve(palette: palette.id, isDark: theme.isDark, isBlack: theme.isBlack)
        let primaryCol = Color(argb: spec.primary)
        let secondaryCol = Color(argb: spec.secondary)
        let onPrimaryCol = Color(argb: spec.onPrimary)
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

        return Button {
            appState.updateSettings { $0.themePalette = palette.id }
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(primaryCol)
                        .frame(width: 34, height: 34)
                        .overlay(alignment: .bottomTrailing) {
                            Circle()
                                .fill(secondaryCol)
                                .frame(width: 14, height: 14)
                        }
                    if selected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(onPrimaryCol)
                    }
                }

                Text(theme.t(Self.paletteTitleKey(palette.id)))
                    .font(theme.scaledFont(size: 13.5, weight: selected ? .bold : .medium))
                    .foregroundStyle(selected ? theme.onSurface : theme.onSurfaceVariant)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background {
                if selected {
                    shape.fill(primaryCol.opacity(theme.isGlass ? 0.18 : 0.12))
                } else {
                    shape.fill(theme.isGlass ? theme.surface.opacity(theme.isDark ? 0.20 : 0.45) : theme.surface)
                }
            }
            .overlay {
                shape.strokeBorder(
                    selected ? primaryCol : theme.outlineVariant.opacity(0.4),
                    lineWidth: selected ? 2 : 1
                )
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - App Icon Showcase + Quick Strip

    private var appIconShowcaseSection: some View {
        let selectedIcon = SirajAppIconCatalog.definition(for: appState.settings.selectedAppIcon)
        let activeAccent = Color(argbHex: selectedIcon.centerColor)

        return VStack(spacing: 0) {
            Button {
                showIconPicker = true
            } label: {
                HStack(spacing: 14) {
                    SirajAppIconBadge(icon: selectedIcon, size: 62, cornerRadius: 17, showAmbientGlow: true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(theme.t("live_theme_icon_title"))
                            .font(theme.scaledFont(size: 16, weight: .black))
                            .foregroundStyle(theme.onSurface)

                        Text(theme.t(selectedIcon.titleKey))
                            .font(theme.scaledFont(size: 11, weight: .bold))
                            .foregroundStyle(theme.primary)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(activeAccent.opacity(theme.isDark ? 0.22 : 0.14)))
                            .overlay(Capsule().strokeBorder(theme.primary.opacity(0.32), lineWidth: 1))

                        Text(theme.t("appearance_icon_card_desc"))
                            .font(theme.scaledFont(size: 12))
                            .foregroundStyle(theme.onSurfaceVariant)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 4)

                    HStack(spacing: 2) {
                        Text(theme.t("appearance_icon_browse_all"))
                            .font(theme.scaledFont(size: 12, weight: .bold))
                        Image(systemName: theme.isRTL ? "chevron.left" : "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(theme.primary)
                    .padding(.leading, 11)
                    .padding(.trailing, 7)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(theme.primary.opacity(theme.isDark ? 0.18 : 0.10)))
                    .overlay(Capsule().strokeBorder(theme.primary.opacity(0.28), lineWidth: 1))
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(SirajAppIconCatalog.all) { option in
                        let isSelected = option.id.caseInsensitiveCompare(selectedIcon.id) == .orderedSame
                        Button {
                            applyIcon(option)
                        } label: {
                            VStack(spacing: 6) {
                                ZStack(alignment: .topTrailing) {
                                    ZStack {
                                        SirajAppIconBadge(icon: option, size: isSelected ? 46 : 48, cornerRadius: 13)
                                    }
                                    .frame(width: 54, height: 54)
                                    .overlay {
                                        if isSelected {
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .strokeBorder(theme.primary, lineWidth: 2)
                                        }
                                    }

                                    if isSelected {
                                        ZStack {
                                            Circle().fill(theme.primary).frame(width: 18, height: 18)
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(theme.onPrimary)
                                        }
                                    }
                                }
                                .scaleEffect(isSelected ? 1.05 : 1.0)

                                Text(theme.t(option.titleKey))
                                    .font(theme.scaledFont(size: 11, weight: isSelected ? .bold : .medium))
                                    .foregroundStyle(isSelected ? theme.onSurface : theme.onSurfaceVariant)
                                    .lineLimit(1)
                            }
                            .frame(width: 68)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .animation(theme.motionEnabled ? .easeOut(duration: 0.2) : nil, value: isSelected)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
    }

    private func applyIcon(_ icon: SirajAppIconDefinition) {
        appState.updateSettings { $0.selectedAppIcon = icon.id }
        guard UIApplication.shared.supportsAlternateIcons else { return }
        UIApplication.shared.setAlternateIconName(icon.alternateIconName) { _ in }
    }

    static func paletteTitleKey(_ id: String) -> String {
        switch id {
        case "RoyalIndigo": return "palette_royal_indigo"
        case "OceanBlue": return "palette_ocean_blue"
        case "TealCaspian": return "palette_teal_caspian"
        default: return "palette_\(id.lowercased())"
        }
    }
}
