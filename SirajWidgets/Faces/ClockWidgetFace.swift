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

        // Analog dials advance cleanly on 5-minute ticks; digital faces use live system time.
        var dates: [Date] = []
        if style.isDial {
            let cal = Calendar.current
            let base = cal.date(bySetting: .second, value: 0, of: now) ?? now
            for i in 0..<24 {
                dates.append(base.addingTimeInterval(TimeInterval(i * 5 * 60)))
            }
        } else {
            dates = WidgetDataLoader.timelineDates(from: now, settings: settings, include15MinTicks: false)
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
    let entry: ClockWidgetEntry
    let style: WidgetPaletteStyle

    var body: some View {
        let snap = entry.snapshot
        let nextName = WidgetDataLoader.t(snap.nextPrayer.type.stringKey, lang: snap.language)
        let nextClock = WidgetDataLoader.formatClock(snap.nextPrayer.time, snapshot: snap)
        let hijriLine = HijriFormatter.format(snap.hijri, lang: snap.language, numeralSystem: snap.settings.numeralSystem)

        VStack(spacing: 6) {
            if entry.clockStyle.isDial {
                AnalogClockDialView(date: entry.date, timeZone: snap.place.timeZone, clockStyle: entry.clockStyle, style: style)
                    .frame(width: 78, height: 78)
            } else {
                Text(entry.date, style: .time)
                    .font(digitalFont(for: entry.clockStyle))
                    .foregroundStyle(style.primaryText)
                    .minimumScaleFactor(0.6)
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
        let hourAngle = ((hour + minute / 60.0) / 12.0) * 2.0 * .pi - .pi / 2.0
        let minuteAngle = (minute / 60.0) * 2.0 * .pi - .pi / 2.0

        return Canvas { ctx, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 3
            let rimRect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)

            if clockStyle == .star {
                var star = Path()
                for i in 0..<16 {
                    let a = Double(i) * (.pi / 8.0) - .pi / 2.0
                    let r = i % 2 == 0 ? radius : radius * 0.84
                    let pt = CGPoint(x: center.x + cos(a) * r, y: center.y + sin(a) * r)
                    if i == 0 { star.move(to: pt) } else { star.addLine(to: pt) }
                }
                star.closeSubpath()
                ctx.stroke(star, with: .color(style.accent.opacity(0.65)), lineWidth: 1.6)
            } else {
                let dash: [CGFloat] = clockStyle == .ink ? [5, 2] : []
                ctx.stroke(Path(ellipseIn: rimRect), with: .color(style.accent.opacity(0.55)), style: StrokeStyle(lineWidth: 2, dash: dash))
            }

            for tick in 0..<12 {
                let a = Double(tick) * (.pi / 6.0) - .pi / 2.0
                let inner = tick % 3 == 0 ? radius * 0.78 : radius * 0.86
                var p = Path()
                p.move(to: CGPoint(x: center.x + cos(a) * inner, y: center.y + sin(a) * inner))
                p.addLine(to: CGPoint(x: center.x + cos(a) * (radius - 2), y: center.y + sin(a) * (radius - 2)))
                ctx.stroke(p, with: .color(style.secondaryText.opacity(tick % 3 == 0 ? 0.9 : 0.45)), lineWidth: tick % 3 == 0 ? 1.8 : 1.0)
            }

            var hPath = Path()
            hPath.move(to: center)
            hPath.addLine(to: CGPoint(x: center.x + cos(hourAngle) * radius * 0.50, y: center.y + sin(hourAngle) * radius * 0.50))
            ctx.stroke(hPath, with: .color(style.primaryText), style: StrokeStyle(lineWidth: 2.8, lineCap: .round))

            var mPath = Path()
            mPath.move(to: center)
            mPath.addLine(to: CGPoint(x: center.x + cos(minuteAngle) * radius * 0.72, y: center.y + sin(minuteAngle) * radius * 0.72))
            ctx.stroke(mPath, with: .color(style.accent), style: StrokeStyle(lineWidth: 2.0, lineCap: .round))

            ctx.fill(Path(ellipseIn: CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6)), with: .color(style.accent))
        }
    }
}
