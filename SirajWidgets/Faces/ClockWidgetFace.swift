import SwiftUI
import WidgetKit
import SirajCore

struct ClockWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: SirajWidgetSnapshot
    let clockStyle: ClockStyle
    let background: WidgetBackgroundStyle
    let paletteOverride: String?
}

struct ClockWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ClockWidgetEntry {
        let now = Date()
        return ClockWidgetEntry(
            date: now,
            snapshot: WidgetDataLoader.snapshot(at: now),
            clockStyle: .classic,
            background: .soft,
            paletteOverride: nil
        )
    }

    func snapshot(for configuration: ClockWidgetConfigurationIntent, in context: Context) async -> ClockWidgetEntry {
        let now = Date()
        return ClockWidgetEntry(
            date: now,
            snapshot: WidgetDataLoader.snapshot(at: now),
            clockStyle: configuration.style.model,
            background: configuration.background.model,
            paletteOverride: configuration.palette.overrideId
        )
    }

    func timeline(for configuration: ClockWidgetConfigurationIntent, in context: Context) async -> Timeline<ClockWidgetEntry> {
        let now = Date()
        let settings = WidgetDataLoader.loadSettings()
        let style = configuration.style.model

        // Digital faces advance per minute for an hour; analog dials tick every 5 minutes.
        var dates: [Date] = []
        let cal = Calendar.current
        let base = cal.date(bySetting: .second, value: 0, of: now) ?? now
        if style.isDial {
            for i in 0..<24 {
                dates.append(base.addingTimeInterval(TimeInterval(i * 5 * 60)))
            }
        } else {
            for i in 0..<60 {
                dates.append(base.addingTimeInterval(TimeInterval(i * 60)))
            }
        }

        let entries = dates.map { d in
            ClockWidgetEntry(
                date: d,
                snapshot: WidgetDataLoader.snapshot(at: d, settings: settings),
                clockStyle: style,
                background: configuration.background.model,
                paletteOverride: configuration.palette.overrideId
            )
        }
        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct SirajClockWidget: Widget {
    let kind = "SirajClockWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ClockWidgetConfigurationIntent.self, provider: ClockWidgetProvider()) { entry in
            SirajWidgetContainer(
                snapshot: entry.snapshot,
                paletteOverride: entry.paletteOverride,
                backgroundStyle: entry.background
            ) { style in
                ClockWidgetBody(entry: entry, style: style)
            }
        }
        .configurationDisplayName("Prayer Clock")
        .description("Large digital or analog clock paired with Hijri date and next prayer.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct ClockWidgetBody: View {
    @Environment(\.widgetFamily) private var family
    let entry: ClockWidgetEntry
    let style: WidgetPaletteStyle

    var body: some View {
        let snap = entry.snapshot
        let nextName = WidgetDataLoader.t(snap.nextPrayer.type.stringKey, lang: snap.language)
        let nextClock = WidgetDataLoader.formatClock(snap.nextPrayer.time, snapshot: snap)
        let hijriLine = HijriFormatter.format(snap.hijri, lang: snap.language, numeralSystem: snap.settings.numeralSystem)
        let gregLine = HijriFormatter.formatGregorianCompact(snap.place.today(at: snap.date), lang: snap.language, numeralSystem: snap.settings.numeralSystem)

        if entry.clockStyle.isDial && family == .systemMedium {
            HStack(spacing: 16) {
                AnalogClockDialView(date: entry.date, timeZone: snap.place.timeZone, clockStyle: entry.clockStyle, style: style)
                    .frame(width: 112, height: 112)
                    .widgetAccentable()

                VStack(alignment: .leading, spacing: 6) {
                    Text(hijriLine)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(style.primaryText)
                        .lineLimit(1)
                    Text(gregLine)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(style.secondaryText)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    HStack(spacing: 6) {
                        Text(nextName)
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundStyle(style.accent)
                        Text(nextClock)
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundStyle(style.primaryText)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(style.subtleFill))
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 6) {
                if entry.clockStyle.isDial {
                    AnalogClockDialView(date: entry.date, timeZone: snap.place.timeZone, clockStyle: entry.clockStyle, style: style)
                        .frame(width: 86, height: 86)
                        .widgetAccentable()
                } else {
                    Text(WidgetDataLoader.formatClock(entry.date, snapshot: snap))
                        .font(digitalFont(for: entry.clockStyle))
                        .foregroundStyle(style.primaryText)
                        .minimumScaleFactor(0.55)
                        .lineLimit(1)
                        .widgetAccentable()
                }

                Text(hijriLine)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(style.secondaryText)
                    .lineLimit(1)

                HStack(spacing: 5) {
                    Text(nextName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(style.accent)
                    Text(nextClock)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(style.primaryText)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(style.subtleFill))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func digitalFont(for clockStyle: ClockStyle) -> Font {
        switch clockStyle {
        case .classic: return .system(size: 34, weight: .semibold, design: .default)
        case .bold: return .system(size: 38, weight: .black, design: .rounded)
        case .serif: return .system(size: 34, weight: .semibold, design: .serif)
        case .condensed: return .system(size: 38, weight: .bold, design: .default).width(.condensed)
        case .handwritten: return .system(size: 34, weight: .medium, design: .serif).italic()
        case .marker: return .system(size: 36, weight: .heavy, design: .rounded)
        default: return .system(size: 34, weight: .semibold)
        }
    }
}

struct AnalogClockDialView: View {
    let date: Date
    let timeZone: TimeZone
    let clockStyle: ClockStyle
    let style: WidgetPaletteStyle

    var body: some View {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let hour = Double(cal.component(.hour, from: date) % 12)
        let minute = Double(cal.component(.minute, from: date))
        let hourDeg = ((hour + minute / 60.0) / 12.0) * 360.0
        let minuteDeg = (minute / 60.0) * 360.0

        let prefix: String = {
            switch clockStyle {
            case .ink: return "widget_ink"
            case .star: return "widget_star"
            default: return "widget_analog"
            }
        }()

        return ZStack {
            Image("\(prefix)_dial_dark")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(style.accent.opacity(0.85))

            Image("\(prefix)_hour_dark")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(style.primaryText)
                .rotationEffect(.degrees(hourDeg))

            Image("\(prefix)_minute_dark")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(style.accent)
                .rotationEffect(.degrees(minuteDeg))
        }
    }
}
