import SwiftUI
import SirajCore

private enum NumeralOption: String, CaseIterable, Identifiable {
    case auto = "Auto"
    case western = "Western"
    case arabic = "Arabic"

    var id: String { rawValue }
}

private enum HourFormatOption: String, CaseIterable, Identifiable {
    case system = "System"
    case h12 = "12"
    case h24 = "24"

    var id: String { rawValue }
}

struct LanguageFormatSettingsView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState

    private let languages: [(code: String, native: String, key: String)] = [
        ("en", "English", "settings_polish_lang_english"),
        ("ar", "العربية", "settings_polish_lang_arabic"),
        ("tr", "Türkçe", "settings_polish_lang_turkish"),
        ("ur", "اردو", "settings_polish_lang_urdu")
    ]

    var body: some View {
        let numeralBinding = Binding<NumeralOption>(
            get: { NumeralOption(rawValue: appState.settings.numeralSystem) ?? .auto },
            set: { val in appState.updateSettings { $0.numeralSystem = val.rawValue } }
        )
        let hourBinding = Binding<HourFormatOption>(
            get: { HourFormatOption(rawValue: appState.settings.hourFormat) ?? .system },
            set: { val in appState.updateSettings { $0.hourFormat = val.rawValue } }
        )

        ScrollView {
            VStack(spacing: 20) {
                SirajSettingsSection(title: theme.t("settings_language")) {
                    ForEach(Array(languages.enumerated()), id: \.element.code) { idx, item in
                        let selected = SirajLocalizer.baseLanguage(appState.settings.language) == item.code
                        Button {
                            appState.updateSettings { $0.language = item.code }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.native)
                                        .font(theme.scaledFont(size: 16, weight: .bold))
                                        .foregroundStyle(theme.onSurface)
                                    Text(theme.t(item.key))
                                        .font(theme.scaledFont(size: 12))
                                        .foregroundStyle(theme.onSurfaceVariant)
                                }
                                Spacer()
                                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 21))
                                    .foregroundStyle(selected ? theme.primary : theme.outline)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if idx < languages.count - 1 {
                            Divider().padding(.leading, 16)
                        }
                    }
                }

                SirajSettingsSection(title: theme.t("settings_numeral_system")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(theme.t("settings_numeral_desc"))
                            .font(theme.scaledFont(size: 12.5))
                            .foregroundStyle(theme.onSurfaceVariant)
                        SirajSegmentedPills(options: NumeralOption.allCases, selection: numeralBinding) { opt in
                            switch opt {
                            case .auto: return theme.t("settings_numeral_auto")
                            case .western: return "123"
                            case .arabic: return "١٢٣"
                            }
                        }
                    }
                    .padding(16)

                    Divider().padding(.leading, 16)

                    SirajSettingsToggleRow(
                        icon: "book.closed.fill",
                        title: theme.t("settings_quran_numeral_exception"),
                        subtitle: theme.t("settings_quran_numeral_desc"),
                        isOn: Binding(
                            get: { appState.settings.isQuranNumeralException },
                            set: { v in appState.updateSettings { $0.isQuranNumeralException = v } }
                        )
                    )
                }

                SirajSettingsSection(title: theme.t("settings_hour_format")) {
                    SirajSegmentedPills(options: HourFormatOption.allCases, selection: hourBinding) { opt in
                        switch opt {
                        case .system: return theme.t("settings_hour_system")
                        case .h12: return theme.t("settings_hour_12_sample")
                        case .h24: return theme.t("settings_hour_24_sample")
                        }
                    }
                    .padding(16)
                }

                SirajSettingsSection(title: theme.t("settings_appearance_more")) {
                    if !theme.language.hasPrefix("ar") {
                        SirajSettingsToggleRow(
                            icon: "character.book.closed.fill",
                            title: theme.t("settings_show_translation"),
                            subtitle: theme.t("settings_show_translation_desc"),
                            isOn: Binding(
                                get: { appState.settings.isShowTranslation },
                                set: { v in appState.updateSettings { $0.isShowTranslation = v } }
                            )
                        )
                        if appState.settings.isShowTranslation {
                            Divider().padding(.leading, 16)
                            SirajSettingsToggleRow(
                                icon: "textformat.abc",
                                title: theme.t("settings_show_transliteration"),
                                subtitle: theme.t("settings_show_transliteration_desc"),
                                isOn: Binding(
                                    get: { appState.settings.isShowTransliteration },
                                    set: { v in appState.updateSettings { $0.isShowTransliteration = v } }
                                )
                            )
                        }
                        Divider().padding(.leading, 16)
                    }
                    SirajSettingsToggleRow(
                        icon: "sparkles",
                        title: theme.t("settings_show_virtues"),
                        subtitle: theme.t("settings_show_virtues_desc"),
                        isOn: Binding(
                            get: { appState.settings.isShowVirtues },
                            set: { v in appState.updateSettings { $0.isShowVirtues = v } }
                        )
                    )
                    Divider().padding(.leading, 16)
                    SirajSettingsToggleRow(
                        icon: "eye.slash.fill",
                        title: theme.t("settings_hide_completed_title"),
                        subtitle: theme.t("settings_hide_completed_desc"),
                        isOn: Binding(
                            get: { appState.settings.isHideCompletedAzkar },
                            set: { v in appState.updateSettings { $0.isHideCompletedAzkar = v } }
                        )
                    )
                    Divider().padding(.leading, 16)
                    SirajSettingsToggleRow(
                        icon: "hand.tap.fill",
                        title: theme.t("settings_haptic_title"),
                        subtitle: theme.t("settings_haptic_desc"),
                        isOn: Binding(
                            get: { appState.settings.isHapticEnabled },
                            set: { v in appState.updateSettings { $0.isHapticEnabled = v } }
                        )
                    )
                    Divider().padding(.leading, 16)
                    SirajSettingsToggleRow(
                        icon: "speaker.wave.1.fill",
                        title: theme.t("settings_sound_effects_title"),
                        subtitle: theme.t("settings_sound_effects_desc"),
                        isOn: Binding(
                            get: { appState.settings.isSoundEnabled },
                            set: { v in appState.updateSettings { $0.isSoundEnabled = v } }
                        )
                    )
                    Divider().padding(.leading, 16)
                    SirajSettingsToggleRow(
                        icon: "figure.walk.motion",
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
            .padding(.top, 12)
            .padding(.bottom, 108)
        }
        .background(Color.clear)
        .navigationTitle(theme.t("settings_section_language"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
