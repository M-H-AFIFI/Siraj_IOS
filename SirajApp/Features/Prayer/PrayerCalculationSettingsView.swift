import SwiftUI
import SirajCore

struct PrayerCalculationSettingsView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState

    private let madhabs = ["Shafi", "Hanafi"]
    private let highLatRules = ["MiddleOfTheNight", "SeventhOfTheNight", "TwilightAngle"]
    private let hijriMethods = ["auto", "umm_al_qura", "egypt", "turkey", "mabims"]

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                SirajSettingsSection(title: theme.t("settings_calc_method_title")) {
                    ForEach(CalculationMethods.all) { method in
                        let selected = appState.settings.calculationMethod == method.id
                        Button {
                            appState.updateSettings { $0.calculationMethod = method.id }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(method.name(language: theme.language))
                                        .font(theme.scaledFont(size: 14.5, weight: .semibold))
                                        .foregroundStyle(theme.onSurface)
                                    Text(method.whereUsed(language: theme.language))
                                        .font(theme.scaledFont(size: 12))
                                        .foregroundStyle(theme.onSurfaceVariant)
                                }
                                Spacer()
                                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selected ? theme.primary : theme.outline)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        if method.id != CalculationMethods.all.last?.id {
                            Divider().padding(.leading, 16)
                        }
                    }
                }

                SirajSettingsSection(title: theme.t("settings_calc_madhab_title")) {
                    HStack(spacing: 8) {
                        ForEach(madhabs, id: \.self) { m in
                            let active = appState.settings.madhab == m
                            Button {
                                appState.updateSettings { $0.madhab = m }
                            } label: {
                                Text(m == "Hanafi" ? theme.t("settings_asr_hanafi") : theme.t("settings_asr_standard"))
                                    .font(theme.scaledFont(size: 14, weight: active ? .bold : .medium))
                                    .foregroundStyle(active ? theme.onPrimary : theme.onSurface)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .background(Capsule().fill(active ? theme.primary : theme.surfaceVariant))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(14)
                }

                SirajSettingsSection(title: theme.t("settings_calc_high_latitude_title")) {
                    ForEach(highLatRules, id: \.self) { rule in
                        let selected = appState.settings.highLatitudeRule == rule
                        Button {
                            appState.updateSettings { $0.highLatitudeRule = rule }
                        } label: {
                            HStack {
                                Text(ruleLabel(rule))
                                    .font(theme.scaledFont(size: 14.5, weight: .medium))
                                    .foregroundStyle(theme.onSurface)
                                Spacer()
                                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selected ? theme.primary : theme.outline)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        if rule != highLatRules.last { Divider().padding(.leading, 16) }
                    }
                }

                SirajSettingsSection(title: theme.t("settings_calc_offsets_title")) {
                    ForEach([PrayerType.fajr, .dhuhr, .asr, .maghrib, .isha]) { p in
                        let val = appState.settings.minuteOffsets[p.rawValue] ?? 0
                        HStack {
                            Text(theme.t(p.stringKey))
                                .font(theme.scaledFont(size: 15, weight: .semibold))
                                .foregroundStyle(theme.onSurface)
                            Spacer()
                            Stepper(
                                theme.tf("pre_prayer_minutes_short", theme.digits("\(val >= 0 ? "+" : "")\(val)")),
                                value: Binding(
                                    get: { appState.settings.minuteOffsets[p.rawValue] ?? 0 },
                                    set: { newVal in appState.updateSettings { $0.minuteOffsets[p.rawValue] = newVal } }
                                ),
                                in: -30...30
                            )
                            .fixedSize()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        if p != .isha { Divider().padding(.leading, 16) }
                    }
                }

                SirajSettingsSection(title: theme.t("hub_calendar_title")) {
                    ForEach(hijriMethods, id: \.self) { hm in
                        let selected = appState.settings.hijriMethod == hm
                        Button {
                            appState.updateSettings { $0.hijriMethod = hm }
                        } label: {
                            HStack {
                                Text(hijriMethodLabel(hm))
                                    .font(theme.scaledFont(size: 14.5, weight: .medium))
                                    .foregroundStyle(theme.onSurface)
                                Spacer()
                                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selected ? theme.primary : theme.outline)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 16)
                    }
                    HStack {
                        Text(theme.t("hijri_adjust_title"))
                            .font(theme.scaledFont(size: 14.5, weight: .semibold))
                            .foregroundStyle(theme.onSurface)
                        Spacer()
                        Stepper(
                            hijriAdjustmentLabel(appState.settings.hijriAdjustment),
                            value: Binding(
                                get: { appState.settings.hijriAdjustment },
                                set: { v in appState.updateSettings { $0.hijriAdjustment = v } }
                            ),
                            in: -2...2
                        )
                        .fixedSize()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }
            .padding(16)
            .padding(.bottom, 100)
        }
        .background(SirajRootBackdrop(activePrayer: appState.prayerDay.next?.type))
        .navigationTitle(theme.t("settings_calc_method_title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func ruleLabel(_ rule: String) -> String {
        switch rule {
        case "SeventhOfTheNight": return theme.t("high_latitude_one_seventh")
        case "TwilightAngle": return theme.t("high_latitude_angle_based")
        default: return theme.t("high_latitude_middle_of_the_night")
        }
    }

    private func hijriMethodLabel(_ hm: String) -> String {
        switch hm {
        case "umm_al_qura": return theme.t("hijri_source_umm_al_qura")
        case "egypt": return theme.t("hijri_source_egypt")
        case "turkey": return theme.t("hijri_source_turkey")
        case "mabims": return theme.t("hijri_source_mabims")
        default: return theme.t("hijri_mode_auto")
        }
    }

    private func hijriAdjustmentLabel(_ adj: Int) -> String {
        switch adj {
        case -2: return theme.t("hijri_adjust_minus_two")
        case -1: return theme.t("hijri_adjust_minus_one")
        case 1: return theme.t("hijri_adjust_plus_one")
        case 2: return theme.t("hijri_adjust_plus_two")
        default: return theme.t("hijri_adjust_none")
        }
    }
}
