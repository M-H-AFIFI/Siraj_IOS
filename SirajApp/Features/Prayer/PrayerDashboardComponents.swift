import SwiftUI
import SirajCore

struct MihrabLocationHeader: View {
    @Environment(\.sirajTheme) private var theme
    let place: Place
    let onTapLocation: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(theme.t("app_name"))
                    .font(theme.scaledFont(size: 24, weight: .black))
                    .foregroundStyle(theme.primary)
                Text(theme.t("dashboard_greeting"))
                    .font(theme.scaledFont(size: 12.5, weight: .semibold))
                    .foregroundStyle(theme.onSurfaceVariant)
            }
            Spacer(minLength: 8)
            Button(action: onTapLocation) {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.primary)
                    Text(place.displayName(language: theme.language) ?? place.timeZoneId)
                        .font(theme.scaledFont(size: 13.5, weight: .bold))
                        .foregroundStyle(theme.onSurface)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(theme.onSurfaceVariant)
                }
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .sirajCardSurface(cornerRadius: 20)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("location_pill")
        }
    }
}

struct MihrabPrayerTable: View {
    @Environment(\.sirajTheme) private var theme
    let day: PrayerDay
    let settings: SettingsSnapshot
    let now: Date
    let onTapTable: () -> Void

    var body: some View {
        let dateText = HijriFormatter.formatGregorian(day.date, lang: theme.language, numeralSystem: settings.numeralSystem)

        Button(action: onTapTable) {
            VStack(spacing: 8) {
                HStack {
                    Text(theme.t("today"))
                        .font(theme.scaledFont(size: 17, weight: .heavy))
                        .foregroundStyle(theme.onSurface)
                    Spacer()
                    Text(dateText)
                        .font(theme.scaledFont(size: 12, weight: .bold))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .lineLimit(1)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 6)

                ForEach(day.entries) { entry in
                    prayerRow(entry)
                }
            }
            .padding(18)
            .sirajCardSurface(cornerRadius: 24)
        }
        .buttonStyle(.plain)
    }

    private func prayerRow(_ entry: PrayerTimeEntry) -> some View {
        let isNext = entry.isNext
        let isPast = !isNext && entry.time < now
        let alertOn = settings.prayerReminders[entry.type.lowercaseKey] ?? (entry.type != .sunrise)
        let timeStr = TimeFormatter.formatTime(
            entry.time,
            timeZone: day.place.timeZone,
            hourFormat: settings.hourFormat,
            numeralSystem: settings.numeralSystem,
            lang: theme.language
        )
        let title: String = {
            if entry.type == .dhuhr && day.date.weekdaySundayZero == 5 {
                return theme.t("prayer_jummah")
            }
            return theme.t(entry.type.stringKey)
        }()

        return HStack(spacing: 12) {
            Image(entry.type.iconAssetName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(isNext ? theme.primary : (isPast ? theme.outline : theme.onSurfaceVariant))
                .frame(width: 34, height: 34)
                .background(Circle().fill(isNext ? theme.primary.opacity(0.18) : theme.surfaceVariant.opacity(0.6)))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(theme.scaledFont(size: 15.5, weight: isNext ? .bold : .semibold))
                    .foregroundStyle(isNext ? theme.primary : (isPast ? theme.onSurfaceVariant : theme.onSurface))
                if let iqama = entry.iqama {
                    let iqStr = TimeFormatter.formatTime(
                        iqama,
                        timeZone: day.place.timeZone,
                        hourFormat: settings.hourFormat,
                        numeralSystem: settings.numeralSystem,
                        lang: theme.language
                    )
                    Text("\(theme.t("iqama")) \(iqStr)")
                        .font(theme.scaledFont(size: 11.5))
                        .foregroundStyle(theme.onSurfaceVariant)
                }
            }

            Spacer()

            Text(timeStr)
                .font(theme.scaledFont(size: 15.5, weight: isNext ? .heavy : .semibold))
                .foregroundStyle(isNext ? theme.primary : (isPast ? theme.onSurfaceVariant : theme.onSurface))

            Image(systemName: alertOn ? "bell.fill" : "bell.slash")
                .font(.system(size: 13))
                .foregroundStyle(alertOn ? (isNext ? theme.primary : theme.onSurfaceVariant) : theme.outline.opacity(0.55))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isNext ? theme.primary.opacity(theme.isDark ? 0.18 : 0.10) : .clear)
        )
    }
}

struct IslamicEventsBanner: View {
    @Environment(\.sirajTheme) private var theme
    let occasion: DatedOccasion

    var body: some View {
        HStack(spacing: 12) {
            Image("ic_siraj_crescent_star")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .foregroundStyle(theme.gold)
                .frame(width: 40, height: 40)
                .background(Circle().fill(theme.gold.opacity(0.16)))

            VStack(alignment: .leading, spacing: 2) {
                Text(occasion.occasion.title(language: theme.language))
                    .font(theme.scaledFont(size: 15, weight: .bold))
                    .foregroundStyle(theme.onSurface)
                Text(HijriFormatter.formatGregorian(occasion.date, lang: theme.language, numeralSystem: theme.settings.numeralSystem))
                    .font(theme.scaledFont(size: 12))
                    .foregroundStyle(theme.onSurfaceVariant)
            }
            Spacer()
            Text(occasion.isToday ? theme.t("today") : theme.tf("fasting_in_days", theme.digits("\(occasion.daysUntil)")))
                .font(theme.scaledFont(size: 12.5, weight: .bold))
                .foregroundStyle(theme.onPrimaryContainer)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(theme.primaryContainer))
        }
        .padding(14)
        .sirajCardSurface(cornerRadius: 20)
    }
}

struct MihrabQuickActions: View {
    @Environment(\.sirajTheme) private var theme
    let onCalculation: () -> Void
    let onReminders: () -> Void
    let onWidgets: () -> Void
    let onLocation: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            tile(icon: "clock.badge.checkmark", title: theme.t("settings_calc_method_title"), action: onCalculation)
            tile(icon: "bell.badge", title: theme.t("settings_reminders"), action: onReminders)
            tile(icon: "square.grid.2x2", title: theme.t("widget_settings_title"), action: onWidgets)
            tile(icon: "location", title: theme.t("settings_location"), action: onLocation)
        }
    }

    private func tile(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(theme.primary)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(theme.primary.opacity(0.12)))
                Text(title)
                    .font(theme.scaledFont(size: 11, weight: .semibold))
                    .foregroundStyle(theme.onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 6)
            .sirajCardSurface(cornerRadius: 18)
        }
        .buttonStyle(.plain)
    }
}

struct DailyAyahCard: View {
    @Environment(\.sirajTheme) private var theme
    let verse: OfflineDailyVerse

    var body: some View {
        let meaning: String = {
            switch SirajLocalizer.baseLanguage(theme.language) {
            case "tr": return verse.meaningTr
            case "ur": return verse.meaningUr
            case "ar": return ""
            default: return verse.meaningEn
            }
        }()
        let surahTitle = theme.isRTL ? verse.surahNameAr : verse.surahNameEn
        let sep = theme.isRTL ? "، " : " · "
        let ref = "\(surahTitle)\(sep)\(theme.digits("\(verse.surahNumber):\(verse.ayahNumber)"))"
        let shareText = meaning.isEmpty ? "\(verse.textAr)\n- \(ref)" : "\(verse.textAr)\n\n\(meaning)\n- \(ref)"

        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(theme.t("ayah_of_the_day"), systemImage: "book.pages.fill")
                    .font(theme.scaledFont(size: 12, weight: .heavy))
                    .foregroundStyle(theme.primary)
                    .textCase(.uppercase)
                Spacer()
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(theme.primary)
                }
            }

            Text(verse.textAr)
                .font(theme.amiriFont(size: 23))
                .foregroundStyle(theme.onSurface)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)

            if theme.settings.isShowTranslation && !meaning.isEmpty {
                Text(meaning)
                    .font(theme.scaledFont(size: 14))
                    .foregroundStyle(theme.onSurfaceVariant)
            }

            Text(ref)
                .font(theme.scaledFont(size: 12, weight: .bold))
                .foregroundStyle(theme.gold)
        }
        .padding(20)
        .sirajCardSurface(cornerRadius: 24)
    }
}

struct DailyInspirationCard: View {
    @Environment(\.sirajTheme) private var theme
    let hadith: OfflineDailyHadith
    @State private var showExplanation = false

    var body: some View {
        let translation: String = {
            switch SirajLocalizer.baseLanguage(theme.language) {
            case "tr": return hadith.translationTr.isEmpty ? hadith.translationEn : hadith.translationTr
            case "ur": return hadith.translationUr.isEmpty ? hadith.translationEn : hadith.translationUr
            case "ar": return ""
            default: return hadith.translationEn
            }
        }()
        let ref = theme.isRTL ? hadith.referenceAr : hadith.referenceEn
        let narrator = theme.isRTL ? hadith.narratorAr : hadith.narratorEn
        let explanation = theme.isRTL ? hadith.explanationAr : hadith.explanationEn

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(theme.t("hadith_of_the_day"), systemImage: "text.quote")
                    .font(theme.scaledFont(size: 12, weight: .heavy))
                    .foregroundStyle(theme.primary)
                    .textCase(.uppercase)
                Spacer()
                Text(theme.isRTL ? hadith.categoryAr : hadith.categoryEn)
                    .font(theme.scaledFont(size: 11, weight: .bold))
                    .foregroundStyle(theme.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(theme.primary.opacity(0.12)))
            }

            if !hadith.textAr.isEmpty {
                Text(hadith.textAr)
                    .font(theme.amiriFont(size: 19))
                    .foregroundStyle(theme.onSurface)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .environment(\.layoutDirection, .rightToLeft)
            }

            if theme.settings.isShowTranslation && !translation.isEmpty {
                Text(translation)
                    .font(theme.scaledFont(size: 14))
                    .foregroundStyle(theme.onSurfaceVariant)
            }

            HStack {
                let sep = theme.isRTL ? "، " : " · "
                Text([narrator, ref].filter { !$0.isEmpty }.joined(separator: sep))
                    .font(theme.scaledFont(size: 12, weight: .semibold))
                    .foregroundStyle(theme.gold)
                Spacer()
                if theme.settings.isShowVirtues && !explanation.isEmpty {
                    Button {
                        showExplanation.toggle()
                    } label: {
                        Image(systemName: showExplanation ? "chevron.up" : "chevron.down")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(theme.primary)
                    }
                    .buttonStyle(.plain)
                }
            }

            if showExplanation && !explanation.isEmpty {
                Text(explanation)
                    .font(theme.scaledFont(size: 13))
                    .foregroundStyle(theme.onSurfaceVariant)
                    .padding(.top, 4)
            }
        }
        .padding(20)
        .sirajCardSurface(cornerRadius: 24)
    }
}

struct HijriDateSheetView: View {
    @Environment(\.sirajTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    let appState: AppState

    var body: some View {
        let now = appState.currentTime
        let moon = MoonPhase.at(now)
        let hijriText = HijriFormatter.format(appState.hijriDate, lang: theme.language, numeralSystem: theme.settings.numeralSystem)
        let gregText = HijriFormatter.formatGregorian(appState.activePlace.today(at: now), lang: theme.language, numeralSystem: theme.settings.numeralSystem)
        let illumPct = theme.digits("\(Int((moon.illumination * 100).rounded()))%")

        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Image("ic_siraj_full_moon")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .foregroundStyle(theme.gold)
                        Text(hijriText)
                            .font(theme.scaledFont(size: 22, weight: .bold))
                            .foregroundStyle(theme.onSurface)
                        Text(gregText)
                            .font(theme.scaledFont(size: 14))
                            .foregroundStyle(theme.onSurfaceVariant)
                        let sep = theme.isRTL ? "، " : " · "
                        Text("\(theme.t(moon.name.stringKey))\(sep)\(illumPct)")
                            .font(theme.scaledFont(size: 12.5, weight: .semibold))
                            .foregroundStyle(theme.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .sirajCardSurface(cornerRadius: 22)

                    VStack(spacing: 10) {
                        HStack {
                            Text(theme.t("hijri_adjust_title"))
                                .font(theme.scaledFont(size: 15, weight: .semibold))
                                .foregroundStyle(theme.onSurface)
                            Spacer()
                            Stepper(
                                theme.digits("\(appState.settings.hijriAdjustment >= 0 ? "+" : "")\(appState.settings.hijriAdjustment)"),
                                value: Binding(
                                    get: { appState.settings.hijriAdjustment },
                                    set: { val in appState.updateSettings { $0.hijriAdjustment = val } }
                                ),
                                in: -2...2
                            )
                            .fixedSize()
                        }
                    }
                    .padding(16)
                    .sirajCardSurface(cornerRadius: 18)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(appState.upcomingOccasions.prefix(6)) { item in
                            HStack {
                                Text(item.occasion.title(language: theme.language))
                                    .font(theme.scaledFont(size: 14.5, weight: .semibold))
                                    .foregroundStyle(theme.onSurface)
                                Spacer()
                                Text(item.isToday ? theme.t("today") : theme.tf("fasting_in_days", theme.digits("\(item.daysUntil)")))
                                    .font(theme.scaledFont(size: 13, weight: .bold))
                                    .foregroundStyle(theme.primary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(18)
                    .sirajCardSurface(cornerRadius: 20)
                }
                .padding(18)
            }
            .background(theme.background.ignoresSafeArea())
            .navigationTitle(theme.t("hub_calendar_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(theme.t("hijri_done")) { dismiss() }
                }
            }
        }
    }
}
