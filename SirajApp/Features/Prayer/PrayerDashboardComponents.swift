import SwiftUI
import UIKit
import SirajCore

struct MihrabLocationHeader: View {
    @Environment(\.sirajTheme) private var theme
    let place: Place
    let onTapLocation: () -> Void

    var body: some View {
        let city = resolvedDisplayCity()
        let pillShape = RoundedRectangle(cornerRadius: 20, style: .continuous)

        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(theme.t("app_name"))
                    .font(theme.scaledFont(size: 22, weight: .black))
                    .foregroundStyle(theme.primary)
                Text(theme.t("dashboard_greeting"))
                    .font(theme.scaledFont(size: 12, weight: .bold))
                    .foregroundStyle(theme.outline)
            }
            Spacer(minLength: 8)
            Button(action: onTapLocation) {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(theme.primary)
                    Text(city)
                        .font(theme.scaledFont(size: 14, weight: .black))
                        .foregroundStyle(theme.onSurface)
                        .lineLimit(1)
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(theme.onSurface)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    if theme.isGlass {
                        let spec = SirajGlassSpec.resolve(theme: theme)
                        ZStack {
                            if spec.usesMaterial { pillShape.fill(.ultraThinMaterial) }
                            pillShape.fill(spec.pillTint)
                        }
                    } else {
                        pillShape.fill(theme.surfaceVariant.opacity(0.40))
                    }
                }
                .overlay {
                    if !theme.isGlass {
                        pillShape.strokeBorder(theme.outlineVariant.opacity(0.30), lineWidth: 1)
                    } else {
                        let spec = SirajGlassSpec.resolve(theme: theme)
                        pillShape.strokeBorder(
                            LinearGradient(colors: [spec.topRim, spec.bottomRim], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("location_pill")
        }
    }

    private func resolvedDisplayCity() -> String {
        let raw = place.displayName(language: theme.language) ?? theme.t("detecting_location")
        let parts = raw.split(whereSeparator: { "/|-–".contains($0) }).map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count > 1 else { return raw }
        let wantArabic = theme.isRTL
        if let match = parts.first(where: { part in
            let hasAr = part.unicodeScalars.contains { (0x0600...0x06FF).contains($0.value) }
            return wantArabic ? hasAr : !hasAr
        }) {
            return match
        }
        return parts[0]
    }
}

struct MihrabQuickActions: View {
    @Environment(\.sirajTheme) private var theme
    let onOpenQuran: () -> Void
    let onOpenTasbih: () -> Void
    let onOpenListen: () -> Void
    let onOpenDuas: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Button(action: onOpenQuran) {
                HStack(spacing: 16) {
                    Image("ic_quick_quran")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                    Text(theme.t("open_quran"))
                        .font(theme.scaledFont(size: 20, weight: .black))
                        .lineLimit(1)
                }
                .foregroundStyle(theme.onPrimary)
                .frame(maxWidth: .infinity, minHeight: 68)
                .padding(.horizontal, 20)
                .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(theme.primary))
                .shadow(color: theme.primary.opacity(theme.isDark ? 0.35 : 0.25), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(ScalePressButtonStyle(scale: 0.98))

            HStack(spacing: 16) {
                actionTile(asset: "ic_quick_tasbih", label: theme.t("nav_tasbih"), action: onOpenTasbih)
                actionTile(asset: "ic_quick_listen", label: theme.t("quick_listen"), action: onOpenListen)
                actionTile(asset: "ic_quick_duas", label: theme.t("duas"), action: onOpenDuas)
            }
        }
    }

    private func actionTile(asset: String, label: String, action: @escaping () -> Void) -> some View {
        let tileShape = RoundedRectangle(cornerRadius: 28, style: .continuous)
        return Button(action: action) {
            VStack(spacing: 8) {
                Image(asset)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(theme.primary)
                Text(label)
                    .font(theme.scaledFont(size: 14, weight: .black))
                    .foregroundStyle(theme.onSurface)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .padding(.horizontal, 8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 96)
            .background {
                if theme.isGlass {
                    let spec = SirajGlassSpec.resolve(theme: theme)
                    ZStack {
                        if spec.usesMaterial { tileShape.fill(.ultraThinMaterial) }
                        tileShape.fill(spec.cardTint)
                    }
                } else {
                    tileShape.fill(theme.surfaceContainer)
                }
            }
            .overlay {
                if theme.isGlass {
                    let spec = SirajGlassSpec.resolve(theme: theme)
                    tileShape.strokeBorder(
                        LinearGradient(colors: [spec.topRim, spec.bottomRim], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1
                    )
                } else {
                    tileShape.strokeBorder(theme.outlineVariant, lineWidth: 1)
                }
            }
        }
        .buttonStyle(ScalePressButtonStyle(scale: 0.95))
    }
}

struct MihrabPrayerTable: View {
    @Environment(\.sirajTheme) private var theme
    let day: PrayerDay
    let settings: SettingsSnapshot
    let now: Date
    let onTapTable: () -> Void

    var body: some View {
        let dateText = HijriFormatter.formatGregorianCompact(day.date, lang: theme.language, numeralSystem: settings.numeralSystem)

        Button(action: onTapTable) {
            VStack(spacing: 0) {
                HStack {
                    Text(theme.t("today"))
                        .font(theme.scaledFont(size: 16, weight: .black))
                        .foregroundStyle(theme.onSurface)
                    Spacer()
                    Text(dateText)
                        .font(theme.scaledFont(size: 11, weight: .bold))
                        .foregroundStyle(theme.outline)
                        .lineLimit(1)
                }
                .padding(.horizontal, 4)
                .padding(.top, 4)
                .padding(.bottom, 16)

                ForEach(day.entries) { entry in
                    prayerRow(entry)
                }
            }
            .padding(18)
            .sirajCardSurface(cornerRadius: 28)
        }
        .buttonStyle(.plain)
    }

    private func prayerRow(_ entry: PrayerTimeEntry) -> some View {
        let isNext = entry.isNext
        let isPast = !isNext && entry.time < now
        let rowShape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        let badgeShape = RoundedRectangle(cornerRadius: 12, style: .continuous)

        let badgeFill: Color = {
            if isNext { return theme.primary }
            if isPast { return theme.surfaceVariant.opacity(theme.isDark ? 0.35 : 0.50) }
            return theme.surfaceVariant.opacity(theme.isDark ? 0.50 : 0.75)
        }()
        let iconTint: Color = {
            if isNext { return theme.onPrimary }
            if isPast { return theme.primary.opacity(0.80) }
            return theme.primary
        }()
        let nameColor: Color = {
            if isNext { return theme.primary }
            if isPast { return theme.onSurface.opacity(0.60) }
            return theme.onSurface
        }()
        let timeColor: Color = {
            if isNext { return theme.primary }
            if isPast { return theme.onSurfaceVariant.opacity(0.75) }
            return theme.onSurfaceVariant
        }()

        let title: String = {
            if entry.type == .dhuhr && day.date.weekdaySundayZero == 5 {
                return theme.t("prayer_jummah")
            }
            return theme.t(entry.type.stringKey)
        }()
        let timeStr = TimeFormatter.formatTime(
            entry.time,
            timeZone: day.place.timeZone,
            hourFormat: settings.hourFormat,
            numeralSystem: settings.numeralSystem,
            lang: theme.language
        )

        return HStack(spacing: 12) {
            ZStack {
                badgeShape.fill(badgeFill)
                if isPast {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(iconTint)
                } else {
                    Image(entry.type.iconAssetName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 23, height: 23)
                        .foregroundStyle(iconTint)
                }
            }
            .frame(width: 38, height: 38)

            Text(title)
                .font(theme.scaledFont(size: 16, weight: isNext ? .black : (isPast ? .medium : .bold)))
                .foregroundStyle(nameColor)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text(timeStr)
                .font(theme.scaledFont(size: 16, weight: isNext ? .black : .medium))
                .foregroundStyle(timeColor)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            if isNext {
                rowShape.fill(theme.primary.opacity(theme.isDark ? 0.16 : 0.08))
            }
        }
        .overlay {
            if theme.isGlass && isNext {
                rowShape.strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(theme.isDark ? 0.26 : 0.72), theme.primary.opacity(0.34)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            }
        }
    }
}

struct TodayIslamicOccasion {
    let id: String
    let title: String
    let subtitle: String?

    static func forHijri(month: Int, day: Int, language: String, digits: (String) -> String) -> TodayIslamicOccasion? {
        func pick(_ ar: String, _ en: String, _ tr: String, _ ur: String) -> String {
            let base = SirajLocalizer.baseLanguage(language)
            switch base {
            case "ar": return ar
            case "ur": return ur
            case "tr": return tr
            default: return en
            }
        }
        let d = digits("\(day)")
        switch (month, day) {
        case (1, 1):
            return TodayIslamicOccasion(
                id: "islamic_new_year",
                title: pick("عام هجري جديد", "A new Hijri year", "Hicri yılbaşı", "نیا ہجری سال"),
                subtitle: pick("كل عام وأنتم بخير", "May it be a blessed year", "Hayırlı yıllar", "اللہ یہ سال مبارک کرے")
            )
        case (1, 10):
            return TodayIslamicOccasion(
                id: "ashura",
                title: pick("يوم عاشوراء", "The Day of Ashura", "Aşure Günü", "یومِ عاشورہ"),
                subtitle: pick("يُسنّ صيامه وصيام يوم قبله", "A Sunnah day of fasting", "Oruç tutulması sünnettir", "اس دن کا روزہ سنت ہے")
            )
        case (7, 27):
            return TodayIslamicOccasion(
                id: "isra_miraj",
                title: pick("ذكرى الإسراء والمعراج", "Al-Isra' wal-Mi'raj", "Miraç Kandili", "شبِ معراج"),
                subtitle: nil
            )
        case (8, 15):
            return TodayIslamicOccasion(
                id: "mid_shaban",
                title: pick("ليلة النصف من شعبان", "Mid-Sha'ban", "Berat Kandili", "شبِ برات"),
                subtitle: nil
            )
        case (9, _):
            let sub = day >= 21
                ? pick("اليوم \(d) من رمضان، العشر الأواخر", "Day \(d) of Ramadan · the last ten nights", "Ramazan'ın \(d). günü · son on gece", "رمضان کا دن \(d)، آخری عشرہ")
                : pick("اليوم \(d) من رمضان", "Day \(d) of Ramadan", "Ramazan'ın \(d). günü", "رمضان کا دن \(d)")
            return TodayIslamicOccasion(
                id: "ramadan",
                title: pick("رمضان مبارك", "Ramadan Mubarak", "Hayırlı Ramazanlar", "رمضان مبارک"),
                subtitle: sub
            )
        case (10, 1...3):
            return TodayIslamicOccasion(
                id: "eid_al_fitr",
                title: pick("عيد فطر مبارك", "Eid al-Fitr Mubarak", "Ramazan Bayramınız mübarek olsun", "عید الفطر مبارک"),
                subtitle: pick("تقبّل الله منا ومنكم", "May Allah accept from us and from you", "Allah bizden ve sizden kabul etsin", "اللہ ہم سے اور آپ سے قبول فرمائے")
            )
        case (12, 9):
            return TodayIslamicOccasion(
                id: "day_of_arafah",
                title: pick("يوم عرفة", "The Day of Arafah", "Arefe Günü", "یومِ عرفہ"),
                subtitle: pick("خير الدعاء دعاء يوم عرفة", "The best supplication is on the Day of Arafah", "Duanın en hayırlısı Arefe günü yapılandır", "بہترین دعا عرفہ کے دن کی دعا ہے")
            )
        case (12, 10...13):
            return TodayIslamicOccasion(
                id: "eid_al_adha",
                title: pick("عيد أضحى مبارك", "Eid al-Adha Mubarak", "Kurban Bayramınız mübarek olsun", "عید الاضحیٰ مبارک"),
                subtitle: pick("تقبّل الله منا ومنكم", "May Allah accept from us and from you", "Allah bizden ve sizden kabul etsin", "اللہ ہم سے اور آپ سے قبول فرمائے")
            )
        default:
            return nil
        }
    }
}

struct IslamicEventsBanner: View {
    @Environment(\.sirajTheme) private var theme
    let occasion: TodayIslamicOccasion
    let onTap: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        Button(action: onTap) {
            HStack(spacing: 14) {
                IslamicOccasionBadge(occasionId: occasion.id, size: 48, highlighted: true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.t("calendar_today_title"))
                        .font(theme.scaledFont(size: 11, weight: .bold))
                        .foregroundStyle(theme.primary)
                    Text(occasion.title)
                        .font(theme.scaledFont(size: 14.5, weight: .black))
                        .foregroundStyle(theme.onSurface)
                    if let subtitle = occasion.subtitle {
                        Text(subtitle)
                            .font(theme.scaledFont(size: 12.5))
                            .foregroundStyle(theme.onSurfaceVariant)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background {
                if !theme.isGlass {
                    shape.fill(
                        LinearGradient(
                            colors: [theme.primaryContainer.opacity(theme.isDark ? 0.55 : 0.85), theme.surface],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                }
            }
            .sirajCardSurface(cornerRadius: 24, isElevated: true)
            .overlay {
                if !theme.isGlass {
                    shape.strokeBorder(theme.primary.opacity(theme.isDark ? 0.28 : 0.18), lineWidth: 1)
                }
            }
        }
        .buttonStyle(ScalePressButtonStyle(scale: 0.98))
    }
}

struct DailyCardActionsRow: View {
    @Environment(\.sirajTheme) private var theme
    let bodyText: String
    @State private var copied = false

    var body: some View {
        let signed = "\(bodyText)\n\n\(theme.t("dashboard_shared_via"))"
        HStack(spacing: 4) {
            Button {
                UIPasteboard.general.string = bodyText
                if theme.settings.isHapticEnabled {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                copied = true
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    copied = false
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 14, weight: .semibold))
                    Text(copied ? theme.t("dashboard_copied") : theme.t("quran_action_copy"))
                        .font(theme.scaledFont(size: 13.5, weight: .bold))
                        .lineLimit(1)
                }
                .foregroundStyle(theme.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            ShareLink(item: signed) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                    Text(theme.t("quran_action_share"))
                        .font(theme.scaledFont(size: 13.5, weight: .bold))
                        .lineLimit(1)
                }
                .foregroundStyle(theme.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
        }
    }
}

struct DailyAyahCard: View {
    @Environment(\.sirajTheme) private var theme
    let verse: OfflineDailyVerse
    var onTapCard: (() -> Void)? = nil

    var body: some View {
        let baseLang = SirajLocalizer.baseLanguage(theme.language)
        let isAr = baseLang == "ar"
        let meaning: String = {
            switch baseLang {
            case "tr": return verse.meaningTr
            case "ur": return verse.meaningUr
            case "ar": return ""
            default: return verse.meaningEn
            }
        }()
        let surahTitle = theme.isRTL ? verse.surahNameAr : verse.surahNameEn
        let ayahLabel = theme.tf("quran_ayah_label", theme.digits("\(verse.ayahNumber)"))
        let sep = theme.isRTL ? "، " : " • "
        let reference = "\(surahTitle)\(sep)\(ayahLabel)"
        let showsTranslation = theme.settings.isShowTranslation && !meaning.isEmpty && !isAr
        let shareBody: String = {
            var parts = [verse.textAr]
            if showsTranslation { parts.append(meaning) }
            parts.append(reference)
            return parts.joined(separator: "\n\n")
        }()

        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.primary)
                    Text(theme.t("ayah_of_the_day"))
                        .font(theme.scaledFont(size: 11, weight: .black))
                        .tracking(theme.isRTL ? 0 : 1.2)
                        .foregroundStyle(theme.primary)
                        .textCase(.uppercase)
                        .lineLimit(2)
                }

                Text(reference)
                    .font(theme.scaledFont(size: 11, weight: .bold))
                    .foregroundStyle(theme.primary)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(theme.primary.opacity(0.08)))
            }

            Spacer().frame(height: 16)

            Button {
                onTapCard?()
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    Text(verse.textAr)
                        .font(theme.quranMadinahFont(size: 24))
                        .lineSpacing(14)
                        .foregroundStyle(theme.onSurface)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .rightToLeft)

                    if showsTranslation {
                        Text(meaning)
                            .font(theme.scaledFont(size: 14))
                            .lineSpacing(4)
                            .foregroundStyle(theme.onSurfaceVariant)
                            .frame(maxWidth: .infinity, alignment: baseLang == "ur" ? .trailing : .leading)
                            .environment(\.layoutDirection, baseLang == "ur" ? .rightToLeft : .leftToRight)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer().frame(height: 12)
            Divider().overlay(theme.outlineVariant.opacity(0.35))
            HStack {
                Spacer()
                DailyCardActionsRow(bodyText: shareBody)
            }
            .padding(.top, 4)
        }
        .padding(.top, 20)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .sirajCardSurface(cornerRadius: 24)
    }
}

struct DailyInspirationCard: View {
    @Environment(\.sirajTheme) private var theme
    let hadith: OfflineDailyHadith
    var onOpenCollection: (() -> Void)? = nil
    @State private var showExplanation = false

    var body: some View {
        let baseLang = SirajLocalizer.baseLanguage(theme.language)
        let title = hadith.localizedTitle(language: theme.language)
        let category = hadith.localizedCategory(language: theme.language)
        let translation = theme.settings.isShowTranslation ? hadith.localizedTranslation(language: theme.language) : nil
        let hasOwnUrdu = baseLang == "ur" && !hadith.translationUr.isEmpty
        let narrator = theme.isRTL ? hadith.narratorAr : hadith.narratorEn
        let reference = theme.isRTL ? hadith.referenceAr : hadith.referenceEn
        let explanation = theme.settings.isShowVirtues ? hadith.localizedExplanation(language: theme.language) : nil

        let shareBody: String = {
            var out = "\(title)\n\n\(hadith.textAr)"
            if let translation, !translation.isEmpty { out += "\n\n\(translation)" }
            out += "\n\n- \(narrator)\n\(reference)"
            return out
        }()

        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "text.book.closed.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.primary)
                Text(theme.t("hadith_of_the_day"))
                    .font(theme.scaledFont(size: 11, weight: .black))
                    .tracking(theme.isRTL ? 0 : 1.2)
                    .foregroundStyle(theme.primary)
                    .textCase(.uppercase)
                    .lineLimit(1)
                Spacer(minLength: 4)
                Text(category)
                    .font(theme.scaledFont(size: 11, weight: .bold))
                    .foregroundStyle(theme.primary)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(theme.primary.opacity(0.10)))
            }

            if !title.isEmpty {
                Text(title)
                    .font(theme.scaledFont(size: 16, weight: .black))
                    .foregroundStyle(theme.onSurface)
                    .padding(.top, 12)
            }

            if !hadith.textAr.isEmpty {
                Text(hadith.textAr)
                    .font(theme.amiriFont(size: 20))
                    .lineSpacing(10)
                    .foregroundStyle(theme.onSurface)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .environment(\.layoutDirection, .rightToLeft)
                    .padding(.top, 12)
            }

            if let translation, !translation.isEmpty {
                Text(translation)
                    .font(theme.scaledFont(size: 14))
                    .lineSpacing(hasOwnUrdu ? 8 : 4)
                    .foregroundStyle(theme.onSurfaceVariant)
                    .frame(maxWidth: .infinity, alignment: hasOwnUrdu ? .trailing : .leading)
                    .environment(\.layoutDirection, hasOwnUrdu ? .rightToLeft : .leftToRight)
                    .padding(.top, 10)
            }

            Text("- \(narrator)")
                .font(theme.scaledFont(size: 12, weight: .bold))
                .foregroundStyle(theme.onSurfaceVariant)
                .padding(.top, 12)

            Text(reference)
                .font(theme.scaledFont(size: 11, weight: .medium))
                .foregroundStyle(theme.outline)
                .padding(.top, 2)

            if let explanation, !explanation.isEmpty, showExplanation {
                Text(explanation)
                    .font(theme.scaledFont(size: 14))
                    .lineSpacing(4)
                    .foregroundStyle(theme.onSurface)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.primary.opacity(0.07)))
                    .padding(.top, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Spacer().frame(height: 10)
            Divider().overlay(theme.outlineVariant.opacity(0.35))

            HStack(spacing: 4) {
                if let explanation, !explanation.isEmpty {
                    Button {
                        if theme.motionEnabled {
                            withAnimation(.easeInOut(duration: 0.22)) { showExplanation.toggle() }
                        } else {
                            showExplanation.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .bold))
                                .rotationEffect(.degrees(showExplanation ? 180 : 0))
                            Text(theme.t("dashboard_hadith_explanation"))
                                .font(theme.scaledFont(size: 13.5, weight: .bold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(theme.primary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 6)
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 4)
                DailyCardActionsRow(bodyText: shareBody)
            }
            .padding(.top, 4)

            if let onOpenCollection {
                Button(action: onOpenCollection) {
                    HStack(spacing: 6) {
                        Text(theme.t("dashboard_hadith_more"))
                            .font(theme.scaledFont(size: 13.5, weight: .bold))
                        Image(systemName: theme.isRTL ? "arrow.left" : "arrow.right")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(theme.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 20)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .sirajCardSurface(cornerRadius: 28)
    }
}

struct ScalePressButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
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
                        MoonPhaseGlyph(phaseFraction: moon.phaseFraction, color: theme.gold)
                            .frame(width: 44, height: 44)
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
                            HStack(spacing: 12) {
                                IslamicOccasionBadge(occasionId: item.occasion.id, size: 36, highlighted: item.isToday)
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
