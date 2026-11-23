import SwiftUI
import SirajCore

struct AppearanceSettingsView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState

    @State private var showIconPicker = false

    private let paletteCols = [GridItem(.adaptive(minimum: 72), spacing: 10)]
    private let sceneCols = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

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
        let currentIcon = SirajAppIconCatalog.definition(for: appState.settings.selectedAppIcon)

        ScrollView {
            VStack(spacing: 20) {
                heroPreviewCard

                SirajSettingsSection(title: theme.t("live_theme_classic_palettes_title")) {
                    LazyVGrid(columns: paletteCols, spacing: 12) {
                        ForEach(SirajPalettes.all) { palette in
                            let selected = SirajPalettes.canonicalId(appState.settings.themePalette) == palette.id
                            let roles = theme.isDark ? palette.dark : palette.light
                            Button {
                                appState.updateSettings { $0.themePalette = palette.id }
                            } label: {
                                VStack(spacing: 6) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color(argbHex: roles.primary), Color(argbHex: roles.primaryContainer)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 44, height: 44)
                                            .overlay {
                                                Circle().strokeBorder(selected ? theme.onSurface : theme.outlineVariant, lineWidth: selected ? 2.5 : 1)
                                            }
                                        if selected {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundStyle(Color(argbHex: roles.onPrimary))
                                        }
                                    }
                                    Text(theme.t(Self.paletteTitleKey(palette.id)))
                                        .font(theme.scaledFont(size: 11.5, weight: selected ? .bold : .medium))
                                        .foregroundStyle(selected ? theme.primary : theme.onSurfaceVariant)
                                        .lineLimit(1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }

                SirajSettingsSection(title: theme.t("live_theme_mode_title")) {
                    VStack(spacing: 12) {
                        SirajSegmentedPills(options: ThemeMode.allCases, selection: modeBinding) { mode in
                            switch mode {
                            case .system: return theme.t("live_theme_mode_system")
                            case .light: return theme.t("live_theme_mode_light")
                            case .dark: return theme.t("live_theme_mode_dark")
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 14)

                        Divider().padding(.leading, 16)

                        SirajSettingsToggleRow(
                            icon: "moon.fill",
                            title: theme.t("live_theme_amoled_title"),
                            subtitle: theme.t("live_theme_amoled_desc"),
                            isOn: Binding(
                                get: { appState.settings.isAmoled },
                                set: { v in appState.updateSettings { $0.isAmoled = v } }
                            )
                        )
                    }
                }

                SirajSettingsSection(title: theme.t("appearance_glass_ui")) {
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
                                .font(theme.scaledFont(size: 13.5, weight: .semibold))
                                .foregroundStyle(theme.onSurface)
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
                            icon: "circle.hexagongrid.fill",
                            title: theme.t("appearance_glass_mesh"),
                            subtitle: theme.t("appearance_glass_mesh_desc"),
                            isOn: Binding(
                                get: { appState.settings.isGlassMesh },
                                set: { v in appState.updateSettings { $0.isGlassMesh = v } }
                            )
                        )

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

                SirajSettingsSection(title: theme.t("live_theme_section_title")) {
                    SirajSettingsToggleRow(
                        icon: "photo.artframe",
                        title: theme.t("live_theme_live_bg_title"),
                        subtitle: theme.t("live_theme_live_bg_desc"),
                        isOn: Binding(
                            get: { appState.settings.isLiveBackgroundEnabled },
                            set: { v in appState.updateSettings { $0.isLiveBackgroundEnabled = v } }
                        )
                    )

                    if appState.settings.isLiveBackgroundEnabled {
                        Divider().padding(.leading, 16)

                        VStack(alignment: .leading, spacing: 10) {
                            Text(theme.t("live_theme_intensity_title"))
                                .font(theme.scaledFont(size: 13.5, weight: .semibold))
                                .foregroundStyle(theme.onSurface)
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
                            icon: "paintpalette.fill",
                            title: theme.t("live_theme_palette_sync_title"),
                            subtitle: theme.t("live_theme_palette_sync_desc"),
                            isOn: Binding(
                                get: { appState.settings.isLivePaletteSync },
                                set: { v in
                                    appState.updateSettings { snap in
                                        snap.isLivePaletteSync = v
                                        if v {
                                            let def = LiveThemeCatalog.definition(for: snap.liveTheme)
                                            snap.themePalette = SirajPalettes.canonicalId(def.pairedPaletteId)
                                        }
                                    }
                                }
                            )
                        )

                        Divider().padding(.leading, 16)

                        LazyVGrid(columns: sceneCols, spacing: 10) {
                            ForEach(LiveThemeCatalog.all) { scene in
                                let selected = appState.settings.liveTheme == scene.id
                                let colors = theme.isBlack ? scene.amoled : (theme.isDark ? scene.dark : scene.light)
                                Button {
                                    appState.updateSettings { snap in
                                        snap.liveTheme = scene.id
                                        if snap.isLivePaletteSync {
                                            snap.themePalette = SirajPalettes.canonicalId(scene.pairedPaletteId)
                                        }
                                    }
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color(argbHex: colors.skyTop), Color(argbHex: colors.skyHorizon)],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .frame(height: 54)
                                            .overlay(alignment: .bottomLeading) {
                                                Circle()
                                                    .fill(Color(argbHex: scene.swatchPrimary))
                                                    .frame(width: 14, height: 14)
                                                    .padding(8)
                                            }
                                            .overlay(alignment: .topTrailing) {
                                                if selected {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundStyle(.white)
                                                        .padding(6)
                                                }
                                            }
                                        Text(theme.t(scene.titleKey))
                                            .font(theme.scaledFont(size: 12.5, weight: selected ? .bold : .semibold))
                                            .foregroundStyle(selected ? theme.primary : theme.onSurface)
                                            .lineLimit(1)
                                    }
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(selected ? theme.primary.opacity(0.12) : theme.surfaceVariant.opacity(0.5))
                                    )
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .strokeBorder(selected ? theme.primary : .clear, lineWidth: 1.5)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(14)
                    }
                }

                SirajSettingsSection(title: theme.t("appearance_icon_section_title")) {
                    Button {
                        showIconPicker = true
                    } label: {
                        HStack(spacing: 14) {
                            SirajAppIconBadge(icon: currentIcon, size: 46)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(theme.t("app_icon_sheet_title"))
                                    .font(theme.scaledFont(size: 15, weight: .semibold))
                                    .foregroundStyle(theme.onSurface)
                                Text(theme.t(currentIcon.titleKey))
                                    .font(theme.scaledFont(size: 12.5))
                                    .foregroundStyle(theme.onSurfaceVariant)
                            }
                            Spacer()
                            Image(systemName: theme.isRTL ? "chevron.left" : "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(theme.outline)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                }

                SirajSettingsSection(title: theme.t("appearance_nav_section_title")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(theme.t("appearance_nav_style_title"))
                            .font(theme.scaledFont(size: 13.5, weight: .semibold))
                            .foregroundStyle(theme.onSurface)
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

                SirajSettingsSection(title: theme.t("text_size_title")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(theme.t("text_size_sample"))
                            .font(theme.scaledFont(size: 15, weight: .medium))
                            .foregroundStyle(theme.onSurface)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.surfaceVariant.opacity(0.6)))

                        HStack {
                            Text("A")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(theme.onSurfaceVariant)
                            Slider(
                                value: Binding(
                                    get: { appState.settings.textScale },
                                    set: { val in appState.updateSettings { $0.textScale = val } }
                                ),
                                in: 0.85...1.35,
                                step: 0.05
                            )
                            .tint(theme.primary)
                            Text("A")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(theme.onSurfaceVariant)
                        }

                        Text(theme.digits("\(Int((appState.settings.textScale * 100).rounded()))%"))
                            .font(theme.scaledFont(size: 12, weight: .bold))
                            .foregroundStyle(theme.primary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(16)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 108)
        }
        .background(Color.clear)
        .navigationTitle(theme.t("settings_appearance_header"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showIconPicker) {
            AppIconPickerSheet(appState: appState)
        }
    }

    private var heroPreviewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(theme.t("appearance_preview_badge"))
                    .font(theme.scaledFont(size: 12, weight: .bold))
                    .foregroundStyle(theme.onPrimaryContainer)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(theme.primaryContainer))
                Spacer()
                if theme.isGlass {
                    Text(theme.t("appearance_glass_badge"))
                        .font(theme.scaledFont(size: 11, weight: .bold))
                        .foregroundStyle(theme.gold)
                }
            }
            Text(theme.t("appearance_preview_ayah"))
                .font(theme.scaledFont(size: 15, weight: .medium))
                .foregroundStyle(theme.onSurface)
        }
        .padding(18)
        .sirajCardSurface(cornerRadius: 24)
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
