import SwiftUI
import WidgetKit
import SirajCore

struct PrayerLockScreenProvider: TimelineProvider {
    func placeholder(in context: Context) -> SirajWidgetSnapshot {
        WidgetDataLoader.snapshot(at: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SirajWidgetSnapshot) -> Void) {
        completion(WidgetDataLoader.snapshot(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SirajWidgetSnapshot>) -> Void) {
        let now = Date()
        let settings = WidgetDataLoader.loadSettings()
        let dates = WidgetDataLoader.timelineDates(from: now, settings: settings, include15MinTicks: true)
        let entries = dates.map { WidgetDataLoader.snapshot(at: $0, settings: settings) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct PrayerLockScreenWidget: Widget {
    let kind = "SirajPrayerLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerLockScreenProvider()) { entry in
            PrayerLockScreenView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Next Prayer")
        .description("Always-on offline countdown to the next prayer on your Lock Screen.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

private struct PrayerLockScreenView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SirajWidgetSnapshot

    var body: some View {
        let name = WidgetDataLoader.t(entry.nextPrayer.type.stringKey, lang: entry.language)
        let clock = WidgetDataLoader.formatClock(entry.nextPrayer.time, snapshot: entry)
        let end = max(entry.date, entry.nextPrayer.time)
        let range = entry.date...end

        switch family {
        case .accessoryCircular:
            Gauge(value: entry.progressToNext) {
                Image(systemName: "sun.horizon.fill")
            } currentValueLabel: {
                Text(clock)
                    .font(.system(size: 11, weight: .bold))
                    .minimumScaleFactor(0.55)
                    .lineLimit(1)
            }
            .gaugeStyle(.accessoryCircular)
            .widgetAccentable()

        case .accessoryInline:
            HStack(spacing: 4) {
                Image(systemName: "moon.stars.fill")
                Text("\(name) \(clock)")
            }

        default:
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "sun.horizon.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text(name)
                        .font(.system(size: 13, weight: .bold))
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Text(clock)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .widgetAccentable()

                Text(timerInterval: range, countsDown: true)
                    .font(.system(size: 18, weight: .heavy, design: .rounded).monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                ProgressView(value: entry.progressToNext)
                    .progressViewStyle(.linear)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
