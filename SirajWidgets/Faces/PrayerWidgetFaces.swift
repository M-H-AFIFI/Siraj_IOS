import SwiftUI
import WidgetKit
import SirajCore

struct PrayerWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: SirajWidgetSnapshot
    let face: PrayerWidgetFaceOption
    let background: WidgetBackgroundStyle
    let paletteOverride: String?
}

struct PrayerWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> PrayerWidgetEntry {
        let now = Date()
        return PrayerWidgetEntry(
            date: now,
            snapshot: WidgetDataLoader.snapshot(at: now),
            face: .next,
            background: .soft,
            paletteOverride: nil
        )
    }

    func snapshot(for configuration: PrayerWidgetConfigurationIntent, in context: Context) async -> PrayerWidgetEntry {
        let now = Date()
        return PrayerWidgetEntry(
            date: now,
            snapshot: WidgetDataLoader.snapshot(at: now),
            face: configuration.face,
            background: configuration.background.model,
            paletteOverride: configuration.palette.overrideId
        )
    }

    func timeline(for configuration: PrayerWidgetConfigurationIntent, in context: Context) async -> Timeline<PrayerWidgetEntry> {
        let now = Date()
        let settings = WidgetDataLoader.loadSettings()
        let needsTicks = configuration.face == .ring || configuration.face == .dual || configuration.face == .spot
        let dates = WidgetDataLoader.timelineDates(from: now, settings: settings, include15MinTicks: needsTicks)
        let entries = dates.map { d in
            PrayerWidgetEntry(
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

struct SirajPrayerWidget: Widget {
    let kind = "SirajPrayerWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: PrayerWidgetConfigurationIntent.self, provider: PrayerWidgetProvider()) { entry in
            SirajWidgetContainer(
                snapshot: entry.snapshot,
                paletteOverride: entry.paletteOverride,
                backgroundStyle: entry.background
            ) { style in
                PrayerWidgetBody(entry: entry, style: style)
            }
        }
        .configurationDisplayName("Prayer Times")
        .description("Next prayer countdown, today's schedule, prayer ring, calligraphy, or daily list.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private struct PrayerWidgetBody: View {
    @Environment(\.widgetFamily) private var family
    let entry: PrayerWidgetEntry
    let style: WidgetPaletteStyle

    var body: some View {
        switch entry.face {
        case .next:
            nextFace
        case .today:
            todayRowFace
        case .list:
            listFace
        case .spot:
            calligraphySpotFace
        case .ring:
            ringFace
        case .dual:
            dualFace
        case .day:
            dayPrayersFace
        }
    }

    private var safeTimerRange: ClosedRange<Date> {
        let end = max(entry.date.addingTimeInterval(60), entry.snapshot.nextPrayer.time)
        return entry.date...end
    }

    private var nextFace: some View {
        let snap = entry.snapshot
        let name = WidgetDataLoader.t(snap.nextPrayer.type.stringKey, lang: snap.language)
        let clock = WidgetDataLoader.formatClock(snap.nextPrayer.time, snapshot: snap)

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(WidgetDataLoader.t("next_prayer", lang: snap.language))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(style.secondaryText)
                    .textCase(.uppercase)
                Spacer()
                Text(snap.place.displayName(language: snap.language) ?? "")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(style.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 2)

            Text(name)
                .font(.system(size: family == .systemSmall ? 22 : 26, weight: .heavy))
                .foregroundStyle(style.primaryText)
                .widgetAccentable()

            Text(clock)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(style.accent)

            Spacer(minLength: 2)

            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(style.accent)
                Text(timerInterval: safeTimerRange, countsDown: true)
                    .font(.system(size: 17, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(style.primaryText)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(style.subtleFill))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var todayRowFace: some View {
        let snap = entry.snapshot
        let prayers = snap.day.entries.filter { $0.type != .sunrise }

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(snap.place.displayName(language: snap.language) ?? WidgetDataLoader.t("today", lang: snap.language))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(style.primaryText)
                    .lineLimit(1)
                Spacer()
                Text(HijriFormatter.format(snap.hijri, lang: snap.language, numeralSystem: snap.settings.numeralSystem))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(style.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 2)

            HStack(spacing: 4) {
                ForEach(prayers) { p in
                    let isNext = p.isNext
                    VStack(spacing: 5) {
                        Text(WidgetDataLoader.t(p.type.stringKey, lang: snap.language))
                            .font(.system(size: 10, weight: isNext ? .bold : .medium))
                            .foregroundStyle(isNext ? style.accent : style.secondaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(WidgetDataLoader.formatClock(p.time, snapshot: snap))
                            .font(.system(size: 11, weight: isNext ? .heavy : .semibold))
                            .foregroundStyle(isNext ? style.primaryText : style.primaryText.opacity(0.85))
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isNext ? style.subtleFill : .clear)
                    )
                    .widgetAccentable(isNext)
                }
            }
        }
    }

    private var listFace: some View {
        let snap = entry.snapshot
        let entries = family == .systemSmall ? Array(snap.day.entries.filter { $0.type != .sunrise }) : snap.day.entries

        return VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(snap.place.displayName(language: snap.language) ?? WidgetDataLoader.t("today", lang: snap.language))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(style.accent)
                Spacer()
                Text(WidgetDataLoader.t("today", lang: snap.language))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(style.secondaryText)
            }

            ForEach(entries) { p in
                HStack {
                    Circle()
                        .fill(p.isNext ? style.accent : style.secondaryText.opacity(0.35))
                        .frame(width: 6, height: 6)
                    Text(WidgetDataLoader.t(p.type.stringKey, lang: snap.language))
                        .font(.system(size: 12.5, weight: p.isNext ? .bold : .medium))
                        .foregroundStyle(p.isNext ? style.accent : style.primaryText)
                    Spacer()
                    Text(WidgetDataLoader.formatClock(p.time, snapshot: snap))
                        .font(.system(size: 12.5, weight: p.isNext ? .heavy : .semibold))
                        .foregroundStyle(p.isNext ? style.accent : style.primaryText)
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var calligraphySpotFace: some View {
        let snap = entry.snapshot
        let clock = WidgetDataLoader.formatClock(snap.nextPrayer.time, snapshot: snap)

        return VStack(spacing: 6) {
            Text(WidgetDataLoader.t("next_prayer", lang: snap.language))
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(style.secondaryText)
                .textCase(.uppercase)

            Text(PrayerArabicCalligraphy.label(for: snap.nextPrayer.type))
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundStyle(style.accent)
                .widgetAccentable()

            Text(clock)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(style.primaryText)

            Text(timerInterval: safeTimerRange, countsDown: true)
                .font(.system(size: 14, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(style.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var ringFace: some View {
        let snap = entry.snapshot
        let name = WidgetDataLoader.t(snap.nextPrayer.type.stringKey, lang: snap.language)
        let clock = WidgetDataLoader.formatClock(snap.nextPrayer.time, snapshot: snap)

        return ZStack {
            Circle()
                .stroke(style.subtleFill, lineWidth: 9)
            Circle()
                .trim(from: 0, to: CGFloat(snap.progressToNext))
                .stroke(style.accent, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .widgetAccentable()

            VStack(spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(style.primaryText)
                    .lineLimit(1)
                Text(clock)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(style.accent)
                Text(timerInterval: safeTimerRange, countsDown: true)
                    .font(.system(size: 11, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(style.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(14)
        }
        .padding(6)
    }

    private var dualFace: some View {
        let snap = entry.snapshot
        let prevName = snap.previousPrayer.map { WidgetDataLoader.t($0.type.stringKey, lang: snap.language) } ?? ""
        let prevClock = snap.previousPrayer.map { WidgetDataLoader.formatClock($0.time, snapshot: snap) } ?? ""
        let nextName = WidgetDataLoader.t(snap.nextPrayer.type.stringKey, lang: snap.language)
        let nextClock = WidgetDataLoader.formatClock(snap.nextPrayer.time, snapshot: snap)

        return VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(prevName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(style.secondaryText)
                    Text(prevClock)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(style.primaryText)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(nextName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(style.accent)
                    Text(nextClock)
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(style.primaryText)
                }
            }

            ProgressView(value: snap.progressToNext)
                .tint(style.accent)
                .widgetAccentable()

            HStack {
                Text(WidgetDataLoader.t("next_prayer", lang: snap.language))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(style.secondaryText)
                Spacer()
                Text(timerInterval: safeTimerRange, countsDown: true)
                    .font(.system(size: 14, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(style.primaryText)
            }
        }
    }

    private var dayPrayersFace: some View {
        let snap = entry.snapshot
        let civil = snap.place.today(at: snap.date)
        let hijriLine = HijriFormatter.format(snap.hijri, lang: snap.language, numeralSystem: snap.settings.numeralSystem)
        let gregLine = HijriFormatter.formatGregorian(civil, lang: snap.language, numeralSystem: snap.settings.numeralSystem)

        return VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(hijriLine)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(style.accent)
                    .widgetAccentable()
                Text(gregLine)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(style.secondaryText)
            }
            Divider()
            todayRowFace
        }
    }
}
