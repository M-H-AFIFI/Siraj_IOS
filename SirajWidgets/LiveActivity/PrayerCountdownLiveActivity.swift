#if canImport(ActivityKit)
import ActivityKit
import SwiftUI
import WidgetKit
import SirajCore

struct PrayerCountdownLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PrayerActivityAttributes.self) { context in
            let palette = SirajColorSchemeSpec.resolve(palette: context.attributes.paletteId, isDark: true, isBlack: false)
            let accent = Color(argb: palette.primary)
            let gold = Color(argb: palette.gold)
            let range = safeRange(start: context.state.intervalStart, end: context.state.nextPrayerTime)

            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(gold)
                        Text(context.state.cityName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Text(context.state.nextPrayerTitle)
                        .font(.system(size: 20, weight: .bold))
                    Text("\(context.state.formattedClock) · \(context.state.hijriShort)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(timerInterval: range, countsDown: true)
                        .font(.system(size: 24, weight: .heavy, design: .rounded).monospacedDigit())
                        .foregroundStyle(accent)
                        .multilineTextAlignment(.trailing)
                    ProgressView(timerInterval: range, countsDown: false) {
                        EmptyView()
                    } currentValueLabel: {
                        EmptyView()
                    }
                    .tint(gold)
                    .frame(width: 96)
                }
            }
            .padding(16)
            .activityBackgroundTint(Color(argb: palette.surface).opacity(0.92))
            .activitySystemActionForegroundColor(accent)
        } dynamicIsland: { context in
            let palette = SirajColorSchemeSpec.resolve(palette: context.attributes.paletteId, isDark: true, isBlack: false)
            let gold = Color(argb: palette.gold)
            let range = safeRange(start: context.state.intervalStart, end: context.state.nextPrayerTime)

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.nextPrayerTitle)
                            .font(.system(size: 16, weight: .bold))
                        Text(context.state.formattedClock)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: range, countsDown: true)
                        .font(.system(size: 18, weight: .heavy, design: .rounded).monospacedDigit())
                        .foregroundStyle(gold)
                        .multilineTextAlignment(.trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        ProgressView(timerInterval: range, countsDown: false) {
                            EmptyView()
                        } currentValueLabel: {
                            EmptyView()
                        }
                        .tint(gold)
                        HStack {
                            Text(context.state.cityName)
                            Spacer()
                            Text(context.state.hijriShort)
                        }
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                HStack(spacing: 4) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(gold)
                    Text(context.state.nextPrayerTitle)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                }
            } compactTrailing: {
                Text(timerInterval: range, countsDown: true)
                    .font(.system(size: 12, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(gold)
                    .frame(maxWidth: 56)
            } minimal: {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(gold)
            }
        }
    }

    private func safeRange(start: Date, end: Date) -> ClosedRange<Date> {
        let now = Date()
        let safeEnd = max(now.addingTimeInterval(60), end)
        let safeStart = min(start, safeEnd.addingTimeInterval(-60))
        return safeStart...safeEnd
    }
}
#endif
