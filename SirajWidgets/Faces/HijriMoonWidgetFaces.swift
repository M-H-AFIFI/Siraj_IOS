import SwiftUI
import WidgetKit
import SirajCore

struct HijriWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: SirajWidgetSnapshot
    let face: HijriWidgetFaceOption
    let background: WidgetBackgroundStyle
    let paletteOverride: String?
}

struct HijriWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> HijriWidgetEntry {
        let now = Date()
        return HijriWidgetEntry(
            date: now,
            snapshot: WidgetDataLoader.snapshot(at: now),
            face: .hijri,
            background: .soft,
            paletteOverride: nil
        )
    }

    func snapshot(for configuration: HijriWidgetConfigurationIntent, in context: Context) async -> HijriWidgetEntry {
        let now = Date()
        return HijriWidgetEntry(
            date: now,
            snapshot: WidgetDataLoader.snapshot(at: now),
            face: configuration.face,
            background: configuration.background.model,
            paletteOverride: configuration.palette.overrideId
        )
    }

    func timeline(for configuration: HijriWidgetConfigurationIntent, in context: Context) async -> Timeline<HijriWidgetEntry> {
        let now = Date()
        let settings = WidgetDataLoader.loadSettings()
        let dates = WidgetDataLoader.timelineDates(from: now, settings: settings, include15MinTicks: false)
        let entries = dates.map { d in
            HijriWidgetEntry(
                date: d,
                snapshot: WidgetDataLoader.snapshot(at: d, settings: settings),
                face: configuration.face,
                background: configuration.background.model,
                paletteOverride: configuration.palette.overrideId
            )
        }
        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct SirajHijriMoonWidget: Widget {
    let kind = "SirajHijriMoonWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: HijriWidgetConfigurationIntent.self, provider: HijriWidgetProvider()) { entry in
            SirajWidgetContainer(
                snapshot: entry.snapshot,
                paletteOverride: entry.paletteOverride,
                backgroundStyle: entry.background
            ) { style in
                HijriMoonWidgetBody(entry: entry, style: style)
            }
        }
        .configurationDisplayName("Hijri & Moon")
        .description("Hijri date, calligraphed month or weekday, tonight's moon phase, or occasion countdown.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct HijriMoonWidgetBody: View {
    let entry: HijriWidgetEntry
    let style: WidgetPaletteStyle

    var body: some View {
        switch entry.face {
        case .hijri:
            hijriFace
        case .month:
            monthCalligraphyFace
        case .date:
            dateCalligraphyFace
        case .moon:
            moonPhaseFace
        case .countdown:
            occasionCountdownFace
        }
    }

    private var hijriFace: some View {
        let snap = entry.snapshot
        let civil = snap.place.today(at: snap.date)
        let monthName = HijriFormatter.monthName(snap.hijri.month, lang: snap.language)
        let dayDigits = WidgetDataLoader.digits("\(snap.hijri.day)", snapshot: snap)
        let yearDigits = WidgetDataLoader.digits("\(snap.hijri.year)", snapshot: snap)
        let gregLine = HijriFormatter.formatGregorian(civil, lang: snap.language, numeralSystem: snap.settings.numeralSystem)

        return VStack(alignment: .leading, spacing: 4) {
            Text(WidgetDataLoader.t("widget_hijri_label", lang: snap.language))
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(style.secondaryText)
                .textCase(.uppercase)

            Spacer(minLength: 2)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(dayDigits)
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(style.accent)
                    .widgetAccentable()
                VStack(alignment: .leading, spacing: 1) {
                    Text(monthName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(style.primaryText)
                        .lineLimit(1)
                    Text("\(yearDigits) \(WidgetDataLoader.t("calendar_hijri_suffix", lang: snap.language))")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(style.secondaryText)
                }
            }

            Spacer(minLength: 2)

            Text(gregLine)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(style.secondaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var monthCalligraphyFace: some View {
        let snap = entry.snapshot
        let civil = snap.place.today(at: snap.date)
        let monthAr = HijriFormatter.monthName(snap.hijri.month, lang: "ar")
        let fullHijri = HijriFormatter.format(snap.hijri, lang: snap.language, numeralSystem: snap.settings.numeralSystem)
        let gregLine = HijriFormatter.formatGregorianCompact(civil, lang: snap.language, numeralSystem: snap.settings.numeralSystem)

        return VStack(spacing: 6) {
            Text(monthAr)
                .font(.custom("Amiri-Regular", size: 34))
                .foregroundStyle(style.accent)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .widgetAccentable()

            Image("widget_date_rule")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(height: 9)
                .foregroundStyle(style.accent.opacity(0.55))

            Text(fullHijri)
                .font(.system(size: 12.5, weight: .bold))
                .foregroundStyle(style.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(gregLine)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(style.secondaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var dateCalligraphyFace: some View {
        let snap = entry.snapshot
        let civil = snap.place.today(at: snap.date)
        let weekdayAr = PrayerArabicCalligraphy.weekdayArabic(sundayZero: civil.weekdaySundayZero)
        let hijriLine = HijriFormatter.format(snap.hijri, lang: snap.language, numeralSystem: snap.settings.numeralSystem)
        let gregLine = HijriFormatter.formatGregorian(civil, lang: snap.language, numeralSystem: snap.settings.numeralSystem)

        return VStack(spacing: 6) {
            Text(weekdayAr)
                .font(.custom("Amiri-Regular", size: 34))
                .foregroundStyle(style.accent)
                .minimumScaleFactor(0.65)
                .lineLimit(1)
                .widgetAccentable()

            Image("widget_date_rule")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(height: 9)
                .foregroundStyle(style.accent.opacity(0.55))

            Text(hijriLine)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(style.primaryText)
                .lineLimit(1)

            Text(gregLine)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(style.secondaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var moonPhaseFace: some View {
        let snap = entry.snapshot
        let moon = snap.moon
        let pct = WidgetDataLoader.digits("\(Int((moon.illumination * 100).rounded()))%", snapshot: snap)
        let hijriLine = HijriFormatter.format(snap.hijri, lang: snap.language, numeralSystem: snap.settings.numeralSystem)
        let sep = snap.isRTL ? "، " : " · "

        return VStack(spacing: 8) {
            WidgetMoonCanvas(phase: moon, litColor: style.accent)
                .frame(width: 58, height: 58)
                .widgetAccentable()

            Text(WidgetDataLoader.t(moon.name.stringKey, lang: snap.language))
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(style.primaryText)
                .lineLimit(1)

            Text("\(pct)\(sep)\(hijriLine)")
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(style.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var occasionCountdownFace: some View {
        let snap = entry.snapshot
        let occ = snap.nextOccasion
        let daysText = occ.map { WidgetDataLoader.digits("\($0.daysUntil)", snapshot: snap) } ?? "0"

        return VStack(alignment: .leading, spacing: 4) {
            Text(WidgetDataLoader.t("widget_countdown_label", lang: snap.language))
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(style.secondaryText)
                .textCase(.uppercase)

            Spacer(minLength: 2)

            Text(occ?.occasion.title(language: snap.language) ?? "")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(style.primaryText)
                .lineLimit(2)

            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(daysText)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(style.accent)
                    .widgetAccentable()
                Text(WidgetDataLoader.t("widget_preview_count_unit", lang: snap.language))
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(style.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

struct WidgetMoonCanvas: View {
    let phase: MoonPhaseInfo
    let litColor: Color

    var body: some View {
        Canvas { ctx, size in
            let r = min(size.width, size.height) / 2 - 2
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)

            ctx.fill(Path(ellipseIn: rect), with: .color(litColor.opacity(0.18)))
            let lit = widgetMoonLimbPath(center: center, radius: r, phaseFraction: phase.phaseFraction)
            ctx.fill(lit, with: .color(litColor))
        }
    }

    private func widgetMoonLimbPath(center: CGPoint, radius: CGFloat, phaseFraction: Double) -> Path {
        var path = Path()
        if phaseFraction >= 0.47 && phaseFraction <= 0.53 {
            path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            return path
        }
        if phaseFraction < 0.02 || phaseFraction > 0.98 { return path }

        let k = cos(phaseFraction * 2.0 * .pi)
        let isWaxing = phaseFraction <= 0.5
        let m: CGFloat = 0.55228475
        let cx = center.x
        let cy = center.y
        let limbX: CGFloat = isWaxing ? radius : -radius
        let rx = CGFloat(k) * limbX

        path.move(to: CGPoint(x: cx, y: cy - radius))
        path.addCurve(to: CGPoint(x: cx + limbX, y: cy), control1: CGPoint(x: cx + limbX * m, y: cy - radius), control2: CGPoint(x: cx + limbX, y: cy - radius * m))
        path.addCurve(to: CGPoint(x: cx, y: cy + radius), control1: CGPoint(x: cx + limbX, y: cy + radius * m), control2: CGPoint(x: cx + limbX * m, y: cy + radius))

        let isCrescent = (phaseFraction >= 0.02 && phaseFraction <= 0.22) || (phaseFraction >= 0.78 && phaseFraction <= 0.98)
        if isCrescent && k > 0.05 {
            let innerRx = limbX * CGFloat(min(0.85, max(0.18, k * 0.90)))
            path.addCurve(to: CGPoint(x: cx + innerRx, y: cy), control1: CGPoint(x: cx + innerRx * 0.22, y: cy + radius * 0.68), control2: CGPoint(x: cx + innerRx, y: cy + radius * 0.38))
            path.addCurve(to: CGPoint(x: cx, y: cy - radius), control1: CGPoint(x: cx + innerRx, y: cy - radius * 0.38), control2: CGPoint(x: cx + innerRx * 0.22, y: cy - radius * 0.68))
        } else {
            path.addCurve(to: CGPoint(x: cx + rx, y: cy), control1: CGPoint(x: cx + rx * m, y: cy + radius), control2: CGPoint(x: cx + rx, y: cy + radius * m))
            path.addCurve(to: CGPoint(x: cx, y: cy - radius), control1: CGPoint(x: cx + rx, y: cy - radius * m), control2: CGPoint(x: cx + rx * m, y: cy - radius))
        }
        path.closeSubpath()
        return path
    }
}
