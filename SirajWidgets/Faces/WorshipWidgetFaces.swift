import AppIntents
import SwiftUI
import WidgetKit
import SirajCore

struct WorshipWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: SirajWidgetSnapshot
    let face: WorshipWidgetFaceOption
    let background: WidgetBackgroundStyle
    let paletteOverride: String?
}

struct WorshipWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> WorshipWidgetEntry {
        let now = Date()
        return WorshipWidgetEntry(
            date: now,
            snapshot: WidgetDataLoader.snapshot(at: now),
            face: .adhkar,
            background: .soft,
            paletteOverride: nil
        )
    }

    func snapshot(for configuration: WorshipWidgetConfigurationIntent, in context: Context) async -> WorshipWidgetEntry {
        let now = Date()
        return WorshipWidgetEntry(
            date: now,
            snapshot: WidgetDataLoader.snapshot(at: now),
            face: configuration.face,
            background: configuration.background.model,
            paletteOverride: configuration.palette.overrideId
        )
    }

    func timeline(for configuration: WorshipWidgetConfigurationIntent, in context: Context) async -> Timeline<WorshipWidgetEntry> {
        let now = Date()
        let settings = WidgetDataLoader.loadSettings()
        let dates = WidgetDataLoader.timelineDates(
            from: now,
            settings: settings,
            include15MinTicks: configuration.face == .fast
        )
        let entries = dates.map { d in
            WorshipWidgetEntry(
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

struct SirajWorshipWidget: Widget {
    let kind = "SirajWorshipWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: WorshipWidgetConfigurationIntent.self, provider: WorshipWidgetProvider()) { entry in
            SirajWidgetContainer(
                snapshot: entry.snapshot,
                paletteOverride: entry.paletteOverride,
                backgroundStyle: entry.background
            ) { style in
                WorshipWidgetBody(entry: entry, style: style)
            }
        }
        .configurationDisplayName("Worship & Reading")
        .description("Adhkar for the current time of day, Suhoor & Iftar fasting timer, or Continue Reading.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct WorshipWidgetBody: View {
    @Environment(\.widgetFamily) private var family
    let entry: WorshipWidgetEntry
    let style: WidgetPaletteStyle

    var body: some View {
        switch entry.face {
        case .adhkar:
            adhkarFace
        case .fast:
            fastFace
        case .read:
            readFace
        }
    }

    private var adhkarFace: some View {
        let snap = entry.snapshot
        let hour = Calendar.current.component(.hour, from: entry.date)
        let cat = AzkarCategory.suggested(forHour: hour)
        let slot = WidgetQuotesCatalog.slot(for: entry.date, rotation: .day)
        let sample = WidgetQuotesCatalog.dhikr(forSlot: slot, category: cat)
        let isSmall = family == .systemSmall

        let iconName: String = {
            switch cat {
            case .morning: return "sunrise.fill"
            case .evening: return "sunset.fill"
            case .afterPrayer: return "sparkles"
            default: return "moon.stars.fill"
            }
        }()

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(style.accent)
                Text(WidgetDataLoader.t("widget_adhkar_label", lang: snap.language))
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(style.secondaryText)
                    .textCase(.uppercase)
                    .lineLimit(1)
            }

            Text(cat.title(language: snap.language))
                .font(.system(size: isSmall ? 16 : 18, weight: .black))
                .foregroundStyle(style.primaryText)
                .lineLimit(2)

            if !isSmall {
                Text(sample.quote.ar)
                    .font(.custom("Amiri-Regular", size: 15))
                    .foregroundStyle(style.secondaryText)
                    .lineLimit(2)
            }

            Spacer(minLength: 2)

            HStack(spacing: 5) {
                Text(WidgetDataLoader.t("azkar_start_reading", lang: snap.language))
                    .font(.system(size: 11, weight: .bold))
                Image(systemName: snap.isRTL ? "arrow.left" : "arrow.right")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(style.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(style.subtleFill))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var fastFace: some View {
        let snap = entry.snapshot
        let fast = snap.fastWindow
        let suhoorClock = WidgetDataLoader.formatClock(fast.suhoorTime, snapshot: snap)
        let iftarClock = WidgetDataLoader.formatClock(fast.iftarTime, snapshot: snap)
        let safeRange = entry.date...max(entry.date, fast.targetDate)
        let headerKey = fast.isTomorrowFast ? "widget_fast_label_tomorrow" : "widget_fast_label"

        return VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(WidgetDataLoader.t(headerKey, lang: snap.language))
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(style.secondaryText)
                    .textCase(.uppercase)
                    .lineLimit(1)
                Spacer()
                Text(timerInterval: safeRange, countsDown: true)
                    .font(.system(size: 13, weight: .heavy, design: .rounded).monospacedDigit())
                    .foregroundStyle(style.accent)
            }

            HStack(spacing: 8) {
                fastTile(
                    label: WidgetDataLoader.t("widget_fast_suhoor", lang: snap.language),
                    time: suhoorClock,
                    highlighted: !fast.isIftarNext
                )
                fastTile(
                    label: WidgetDataLoader.t("widget_fast_iftar", lang: snap.language),
                    time: iftarClock,
                    highlighted: fast.isIftarNext
                )
            }

            ProgressView(value: fast.progress)
                .tint(style.accent)
                .widgetAccentable()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func fastTile(label: String, time: String, highlighted: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(highlighted ? Color(argb: style.scheme.onPrimary).opacity(0.85) : style.secondaryText)
                .lineLimit(1)
            Text(time)
                .font(.system(size: family == .systemSmall ? 13.5 : 16, weight: .black))
                .foregroundStyle(highlighted ? Color(argb: style.scheme.onPrimary) : style.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(highlighted ? style.accent : style.subtleFill)
        )
    }

    private var readFace: some View {
        let snap = entry.snapshot
        let pos = snap.readingPosition
        let surahNumber = pos?.surahNumber ?? 1
        let ayahNumber = pos?.ayahNumber ?? 1
        let juzNumber = pos?.juz ?? 1
        let page = pos?.page ?? 1
        let totalPages = max(1, pos?.pageCount ?? 604)
        let progress = min(1.0, max(0.0, Double(page) / Double(totalPages)))
        let arabicSurah = ShamarlyBanners.arabicName(forSurah: surahNumber)
        let detail = WidgetDataLoader.tf(
            "widget_read_detail",
            lang: snap.language,
            WidgetDataLoader.digits("\(ayahNumber)", snapshot: snap),
            WidgetDataLoader.digits("\(juzNumber)", snapshot: snap)
        )

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(WidgetDataLoader.t("widget_read_label", lang: snap.language))
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(style.secondaryText)
                    .textCase(.uppercase)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "book.pages.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(style.accent)
            }

            Spacer(minLength: 2)

            Text(arabicSurah.isEmpty ? "الفاتحة" : arabicSurah)
                .font(.custom("Amiri-Regular", size: family == .systemSmall ? 26 : 30))
                .foregroundStyle(style.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .widgetAccentable()

            Text(detail)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(style.primaryText)
                .lineLimit(1)

            ProgressView(value: progress)
                .tint(style.accent)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Interactive Tasbih Widget

struct TasbihWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: SirajWidgetSnapshot
    let background: WidgetBackgroundStyle
    let paletteOverride: String?
}

struct TasbihWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TasbihWidgetEntry {
        let now = Date()
        return TasbihWidgetEntry(
            date: now,
            snapshot: WidgetDataLoader.snapshot(at: now),
            background: .soft,
            paletteOverride: nil
        )
    }

    func snapshot(for configuration: TasbihWidgetConfigurationIntent, in context: Context) async -> TasbihWidgetEntry {
        let now = Date()
        return TasbihWidgetEntry(
            date: now,
            snapshot: WidgetDataLoader.snapshot(at: now),
            background: configuration.background.model,
            paletteOverride: configuration.palette.overrideId
        )
    }

    func timeline(for configuration: TasbihWidgetConfigurationIntent, in context: Context) async -> Timeline<TasbihWidgetEntry> {
        let now = Date()
        let entry = TasbihWidgetEntry(
            date: now,
            snapshot: WidgetDataLoader.snapshot(at: now),
            background: configuration.background.model,
            paletteOverride: configuration.palette.overrideId
        )
        return Timeline(entries: [entry], policy: .never)
    }
}

struct SirajTasbihWidget: Widget {
    let kind = "SirajTasbihWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: TasbihWidgetConfigurationIntent.self, provider: TasbihWidgetProvider()) { entry in
            SirajWidgetContainer(
                snapshot: entry.snapshot,
                paletteOverride: entry.paletteOverride,
                backgroundStyle: entry.background
            ) { style in
                TasbihWidgetBody(entry: entry, style: style)
            }
        }
        .configurationDisplayName("Tasbih Counter")
        .description("Tap right on your Home Screen to count after-prayer tasbih.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct TasbihWidgetBody: View {
    @Environment(\.widgetFamily) private var family
    let entry: TasbihWidgetEntry
    let style: WidgetPaletteStyle

    var body: some View {
        let snap = entry.snapshot
        let step = WidgetTasbihStep.of(count: snap.widgetTasbihCount)
        let shownNum = step.isDone ? WidgetTasbihStep.total : step.inPhrase
        let countDigits = WidgetDataLoader.digits("\(shownNum)", snapshot: snap)
        let targetText = WidgetDataLoader.tf(
            "widget_tasbih_of",
            lang: snap.language,
            WidgetDataLoader.digits("\(step.ofPhrase)", snapshot: snap)
        )
        let phrase = step.isDone
            ? WidgetDataLoader.t("widget_tasbih_done", lang: snap.language)
            : step.phraseArabic
        let meaning = step.isDone
            ? WidgetDataLoader.t("widget_tasbih_done_body", lang: snap.language)
            : WidgetDataLoader.t(step.meaningKey, lang: snap.language)

        ZStack(alignment: .topTrailing) {
            Button(intent: TapWidgetTasbihIntent()) {
                if family == .systemSmall {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .stroke(style.subtleFill, lineWidth: 7)
                            Circle()
                                .trim(from: 0, to: CGFloat(step.fraction))
                                .stroke(style.accent, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .widgetAccentable()

                            VStack(spacing: 0) {
                                Text(countDigits)
                                    .font(.system(size: 24, weight: .black, design: .rounded))
                                    .foregroundStyle(style.primaryText)
                                if !step.isDone {
                                    Text(targetText)
                                        .font(.system(size: 9.5, weight: .semibold))
                                        .foregroundStyle(style.secondaryText)
                                }
                            }
                        }
                        .frame(width: 76, height: 76)

                        Text(phrase)
                            .font(.custom("Amiri-Regular", size: 16))
                            .foregroundStyle(style.primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        if !SirajLocalizer.baseLanguage(snap.language).hasPrefix("ar") || step.isDone {
                            Text(meaning)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(style.secondaryText)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .stroke(style.subtleFill, lineWidth: 8)
                            Circle()
                                .trim(from: 0, to: CGFloat(step.fraction))
                                .stroke(style.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .widgetAccentable()

                            VStack(spacing: 1) {
                                Text(countDigits)
                                    .font(.system(size: 28, weight: .black, design: .rounded))
                                    .foregroundStyle(style.primaryText)
                                if !step.isDone {
                                    Text(targetText)
                                        .font(.system(size: 10.5, weight: .semibold))
                                        .foregroundStyle(style.secondaryText)
                                }
                            }
                        }
                        .frame(width: 96, height: 96)

                        VStack(alignment: .leading, spacing: 5) {
                            Text(WidgetDataLoader.t("widget_tasbih_label", lang: snap.language))
                                .font(.system(size: 10.5, weight: .bold))
                                .foregroundStyle(style.secondaryText)
                                .textCase(.uppercase)
                            Text(phrase)
                                .font(.custom("Amiri-Regular", size: 22))
                                .foregroundStyle(style.primaryText)
                                .lineLimit(2)
                                .minimumScaleFactor(0.7)
                            Text(meaning)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(style.secondaryText)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .buttonStyle(.plain)

            Button(intent: ResetWidgetTasbihIntent()) {
                Image("widget_reset")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundStyle(style.secondaryText)
                    .padding(6)
                    .background(Circle().fill(style.subtleFill))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(WidgetDataLoader.t("widget_tasbih_reset", lang: snap.language))
        }
    }
}
