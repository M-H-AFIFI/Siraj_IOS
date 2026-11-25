import SwiftUI
import WidgetKit
import SirajCore

struct QuoteWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: SirajWidgetSnapshot
    let face: QuoteWidgetFaceOption
    let rotation: QuoteRotation
    let showMeaning: Bool
    let background: WidgetBackgroundStyle
    let paletteOverride: String?
}

struct QuoteWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> QuoteWidgetEntry {
        let now = Date()
        return QuoteWidgetEntry(
            date: now,
            snapshot: WidgetDataLoader.snapshot(at: now),
            face: .verseCard,
            rotation: .prayer,
            showMeaning: true,
            background: .soft,
            paletteOverride: nil
        )
    }

    func snapshot(for configuration: QuoteWidgetConfigurationIntent, in context: Context) async -> QuoteWidgetEntry {
        let now = Date()
        return QuoteWidgetEntry(
            date: now,
            snapshot: WidgetDataLoader.snapshot(at: now),
            face: configuration.face,
            rotation: configuration.rotation.model,
            showMeaning: configuration.showMeaning,
            background: configuration.background.model,
            paletteOverride: configuration.palette.overrideId
        )
    }

    func timeline(for configuration: QuoteWidgetConfigurationIntent, in context: Context) async -> Timeline<QuoteWidgetEntry> {
        let now = Date()
        let settings = WidgetDataLoader.loadSettings()
        let rot = configuration.rotation.model
        let dates = WidgetDataLoader.timelineDates(
            from: now,
            settings: settings,
            include15MinTicks: false,
            includeHourlyTicks: rot == .hour
        )
        let entries = dates.map { d in
            QuoteWidgetEntry(
                date: d,
                snapshot: WidgetDataLoader.snapshot(at: d, settings: settings),
                face: configuration.face,
                rotation: rot,
                showMeaning: configuration.showMeaning,
                background: configuration.background.model,
                paletteOverride: configuration.palette.overrideId
            )
        }
        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct SirajQuoteWidget: Widget {
    let kind = "SirajQuoteWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: QuoteWidgetConfigurationIntent.self, provider: QuoteWidgetProvider()) { entry in
            SirajWidgetContainer(
                snapshot: entry.snapshot,
                paletteOverride: entry.paletteOverride,
                backgroundStyle: entry.background
            ) { style in
                QuoteWidgetBody(entry: entry, style: style)
            }
        }
        .configurationDisplayName("Verse, Hadith & Dhikr")
        .description("A Quran verse, floral verse card, prophetic hadith, or dhikr that rotates through your day.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private struct QuoteWidgetBody: View {
    @Environment(\.widgetFamily) private var family
    let entry: QuoteWidgetEntry
    let style: WidgetPaletteStyle

    private var slot: Int {
        WidgetQuotesCatalog.slot(
            for: entry.date,
            rotation: entry.rotation,
            prayerIndex: entry.snapshot.currentPrayerIndex
        )
    }

    private var isArabic: Bool {
        SirajLocalizer.baseLanguage(entry.snapshot.language) == "ar"
    }

    var body: some View {
        switch entry.face {
        case .verseCard:
            floralVerseCardFace
        case .ayah:
            ayahFace
        case .hadith:
            hadithFace
        case .dhikr:
            dhikrFace
        }
    }

    private var ayahFace: some View {
        let snap = entry.snapshot
        let verse = WidgetQuotesCatalog.verse(forSlot: slot)
        let meaning = localizedVerseMeaning(verse, lang: snap.language)
        let ref = verseReference(verse, snap: snap)
        let wide = family != .systemSmall

        return VStack(alignment: wide ? .center : .leading, spacing: 6) {
            Spacer(minLength: 2)

            (
                Text("﴿ ").foregroundColor(style.accent)
                + Text(verse.textAr).foregroundColor(style.primaryText)
                + Text(" ﴾").foregroundColor(style.accent)
            )
            .font(.custom("Amiri-Regular", size: wide ? 21 : 17))
            .multilineTextAlignment(wide ? .center : .leading)
            .lineSpacing(3)
            .minimumScaleFactor(0.68)

            if entry.showMeaning && !isArabic && !meaning.isEmpty {
                Text(meaning)
                    .font(.system(size: wide ? 11.5 : 10.5, weight: .medium))
                    .foregroundStyle(style.secondaryText)
                    .multilineTextAlignment(wide ? .center : .leading)
                    .lineLimit(family == .systemLarge ? 4 : 2)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 2)

            Text(ref)
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(style.accent)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: wide ? .center : .leading)
    }

    private var floralVerseCardFace: some View {
        let snap = entry.snapshot
        let verse = WidgetQuotesCatalog.verse(forSlot: slot)
        let meaning = localizedVerseMeaning(verse, lang: snap.language)
        let ref = verseReference(verse, snap: snap)
        let wide = family != .systemSmall
        let cornerSize: CGFloat = wide ? 56 : 44

        return ZStack {
            // Subtle warm parchment tint on soft light cards
            if entry.background == .soft && !style.scheme.isDark {
                Color(argbHex: 0xFFFAF5E8).opacity(0.62)
                    .padding(-16)
            }

            // Inner botanical frame
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(style.accent.opacity(0.32), lineWidth: 1)

            // Top-leading floral spray
            VStack {
                HStack {
                    ZStack {
                        Image("widget_floral_top_leaves")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(style.accent.opacity(0.45))
                        Image("widget_floral_top_blooms")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(style.accent)
                    }
                    .frame(width: cornerSize, height: cornerSize)
                    Spacer()
                }
                Spacer()
            }
            .padding(2)

            // Bottom-trailing floral spray
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ZStack {
                        Image("widget_floral_bottom_leaves")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(style.accent.opacity(0.45))
                        Image("widget_floral_bottom_blooms")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(style.accent)
                    }
                    .frame(width: cornerSize * 0.85, height: cornerSize * 0.85)
                }
            }
            .padding(2)

            // Centered verse & source pill
            VStack(spacing: 6) {
                Spacer(minLength: 4)

                (
                    Text("﴿ ").foregroundColor(style.accent)
                    + Text(verse.textAr).foregroundColor(style.primaryText)
                    + Text(" ﴾").foregroundColor(style.accent)
                )
                .font(.custom("Amiri-Regular", size: wide ? 20 : 16))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .minimumScaleFactor(0.65)
                .padding(.horizontal, wide ? 18 : 10)

                if entry.showMeaning && !isArabic && !meaning.isEmpty {
                    Text(meaning)
                        .font(.system(size: wide ? 11 : 10, weight: .medium))
                        .foregroundStyle(style.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(family == .systemLarge ? 4 : 2)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, wide ? 18 : 10)
                }

                Spacer(minLength: 4)

                Text(ref)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(style.isFilled ? style.primaryText : Color(argb: style.scheme.onPrimary))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(style.isFilled ? style.subtleFill : style.accent))
                    .padding(.bottom, 6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var hadithFace: some View {
        let snap = entry.snapshot
        let hadith = WidgetQuotesCatalog.hadith(forSlot: slot)
        let wide = family != .systemSmall
        let source = hadith.source(language: snap.language, numeralSystem: snap.settings.numeralSystem)

        return quoteCardLayout(
            arabic: hadith.quote.ar,
            meaning: isArabic ? "" : hadith.quote.meaning(language: snap.language),
            source: source,
            wide: wide
        )
    }

    private var dhikrFace: some View {
        let snap = entry.snapshot
        let hour = Calendar.current.component(.hour, from: entry.date)
        let cat = AzkarCategory.suggested(forHour: hour)
        let dhikr = WidgetQuotesCatalog.dhikr(forSlot: slot, category: cat)
        let wide = family != .systemSmall
        let source = dhikr.source(language: snap.language, numeralSystem: snap.settings.numeralSystem)

        return quoteCardLayout(
            arabic: dhikr.quote.ar,
            meaning: isArabic ? "" : dhikr.quote.meaning(language: snap.language),
            source: source,
            wide: wide
        )
    }

    private func quoteCardLayout(arabic: String, meaning: String, source: String, wide: Bool) -> some View {
        VStack(alignment: wide ? .center : .leading, spacing: 6) {
            if !wide {
                HStack {
                    Image("widget_quote_mark")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(style.accent.opacity(0.45))
                    Spacer()
                }
            } else {
                Spacer(minLength: 2)
            }

            if isArabic || !entry.showMeaning || meaning.isEmpty {
                Text(arabic)
                    .font(.custom("Amiri-Regular", size: wide ? 21 : 16.5))
                    .foregroundStyle(style.primaryText)
                    .multilineTextAlignment(wide ? .center : .leading)
                    .lineSpacing(3)
                    .minimumScaleFactor(0.65)
            } else {
                Text(arabic)
                    .font(.custom("Amiri-Regular", size: wide ? 18 : 14.5))
                    .foregroundStyle(style.primaryText)
                    .multilineTextAlignment(wide ? .center : .leading)
                    .lineLimit(family == .systemLarge ? 4 : 2)
                    .minimumScaleFactor(0.7)

                Text(meaning)
                    .font(.system(size: wide ? 11.5 : 10.5, weight: .medium))
                    .foregroundStyle(style.secondaryText)
                    .multilineTextAlignment(wide ? .center : .leading)
                    .lineLimit(family == .systemLarge ? 4 : 2)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 2)

            Text(source)
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(style.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: wide ? .center : .leading)
    }

    private func localizedVerseMeaning(_ verse: OfflineDailyVerse, lang: String) -> String {
        switch SirajLocalizer.baseLanguage(lang) {
        case "tr": return verse.meaningTr
        case "ur": return verse.meaningUr
        default: return verse.meaningEn
        }
    }

    private func verseReference(_ verse: OfflineDailyVerse, snap: SirajWidgetSnapshot) -> String {
        let name = isArabic ? verse.surahNameAr : verse.surahNameEn
        let num = WidgetDataLoader.digits("\(verse.surahNumber):\(verse.ayahNumber)", snapshot: snap)
        return "\(name) \(num)"
    }
}
