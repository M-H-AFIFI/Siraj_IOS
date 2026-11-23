import SwiftUI
import SirajCore

struct PrayerTimesDetailView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    @State private var dayOffset: Int = 0

    var body: some View {
        let baseDate = appState.activePlace.today(at: appState.currentTime)
        let selectedDate = baseDate.addingDays(dayOffset)
        let raw = PrayerCalculator.raw(place: appState.activePlace, date: selectedDate, settings: appState.settings.calculationSettings)
        let hijri = appState.hijriCalendar.toHijri(selectedDate)
        let maghrib = raw[4].time
        let nextFajr = PrayerCalculator.raw(place: appState.activePlace, date: selectedDate.addingDays(1), settings: appState.settings.calculationSettings)[0].time
        let nightLen = max(0, nextFajr.timeIntervalSince(maghrib))
        let midnight = maghrib.addingTimeInterval(nightLen / 2.0)
        let lastThird = maghrib.addingTimeInterval(nightLen * 2.0 / 3.0)

        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    Button { dayOffset -= 1 } label: {
                        Image(systemName: theme.isRTL ? "chevron.right" : "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(theme.surfaceVariant))
                    }
                    .buttonStyle(.plain)

                    Spacer()
                    VStack(spacing: 3) {
                        Text(HijriFormatter.format(hijri, lang: theme.language, numeralSystem: theme.settings.numeralSystem))
                            .font(theme.scaledFont(size: 16, weight: .bold))
                            .foregroundStyle(theme.onSurface)
                        Text(HijriFormatter.formatGregorian(selectedDate, lang: theme.language, numeralSystem: theme.settings.numeralSystem))
                            .font(theme.scaledFont(size: 12.5))
                            .foregroundStyle(theme.onSurfaceVariant)
                    }
                    Spacer()

                    Button { dayOffset += 1 } label: {
                        Image(systemName: theme.isRTL ? "chevron.left" : "chevron.right")
                            .font(.system(size: 16, weight: .bold))
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(theme.surfaceVariant))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .sirajCardSurface(cornerRadius: 20)

                if dayOffset != 0 {
                    Button(theme.t("today")) { dayOffset = 0 }
                        .font(theme.scaledFont(size: 13, weight: .bold))
                        .foregroundStyle(theme.primary)
                }

                VStack(spacing: 0) {
                    ForEach(raw) { entry in
                        HStack {
                            Image(entry.type.iconAssetName)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(theme.primary)
                            Text(theme.t(entry.type.stringKey))
                                .font(theme.scaledFont(size: 15.5, weight: .semibold))
                                .foregroundStyle(theme.onSurface)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(formatTime(entry.time))
                                    .font(theme.scaledFont(size: 15.5, weight: .bold))
                                    .foregroundStyle(theme.onSurface)
                                if let iq = entry.iqama {
                                    Text("\(theme.t("iqama")) \(formatTime(iq))")
                                        .font(theme.scaledFont(size: 11.5))
                                        .foregroundStyle(theme.onSurfaceVariant)
                                }
                            }
                        }
                        .padding(15)
                        if entry.type != .isha { Divider().padding(.leading, 48) }
                    }
                }
                .sirajCardSurface(cornerRadius: 22)

                VStack(spacing: 12) {
                    nightRow(title: theme.t("phase_midnight"), time: formatTime(midnight))
                    Divider()
                    nightRow(title: theme.t("phase_last_third"), time: formatTime(lastThird))
                }
                .padding(16)
                .sirajCardSurface(cornerRadius: 20)
            }
            .padding(16)
            .padding(.bottom, 100)
        }
        .background(SirajRootBackdrop(activePrayer: appState.prayerDay.next?.type))
        .navigationTitle(theme.t("prayer_times"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatTime(_ date: Date) -> String {
        TimeFormatter.formatTime(
            date,
            timeZone: appState.activePlace.timeZone,
            hourFormat: theme.settings.hourFormat,
            numeralSystem: theme.settings.numeralSystem,
            lang: theme.language
        )
    }

    private func nightRow(title: String, time: String) -> some View {
        HStack {
            Text(title)
                .font(theme.scaledFont(size: 14.5, weight: .semibold))
                .foregroundStyle(theme.onSurface)
            Spacer()
            Text(time)
                .font(theme.scaledFont(size: 14.5, weight: .bold))
                .foregroundStyle(theme.gold)
        }
    }
}
