import SwiftUI
import SirajCore

struct NumberStar: View {
    @Environment(\.sirajTheme) private var theme
    let text: String
    var size: CGFloat = 42

    var body: some View {
        let fontSize: CGFloat = text.count >= 3 ? 11 : (text.count == 2 ? 12 : 14)
        ZStack {
            Canvas { ctx, sz in
                let side = min(sz.width, sz.height) * 0.68
                let rect = CGRect(
                    x: (sz.width - side) / 2,
                    y: (sz.height - side) / 2,
                    width: side,
                    height: side
                )
                let rounded = Path(roundedRect: rect, cornerRadius: 5)
                let fillColor = theme.primaryContainer
                let strokeColor = theme.primary.opacity(0.32)

                ctx.fill(rounded, with: .color(fillColor))
                ctx.stroke(rounded, with: .color(strokeColor), lineWidth: 1)

                var rotated = ctx
                rotated.translateBy(x: sz.width / 2, y: sz.height / 2)
                rotated.rotate(by: .degrees(45))
                rotated.translateBy(x: -sz.width / 2, y: -sz.height / 2)
                rotated.fill(rounded, with: .color(fillColor))
                rotated.stroke(rounded, with: .color(strokeColor), lineWidth: 1)
            }
            Text(text)
                .font(.system(size: fontSize, weight: .black))
                .foregroundStyle(theme.onPrimaryContainer)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(width: size, height: size)
    }
}

struct AyahEndSymbol: View {
    let ayahNumber: Int
    var size: CGFloat = 28
    let color: Color
    let textColor: Color
    var showArabicDigits: Bool = true

    var body: some View {
        let label = DigitFormatter.localizeDigits(String(ayahNumber), eastern: showArabicDigits, lang: "ar")
        let fontSize: CGFloat = label.count >= 3 ? size * 0.38 : (label.count == 2 ? size * 0.44 : size * 0.50)

        ZStack {
            Canvas { ctx, sz in
                let w = sz.width
                let h = sz.height
                guard w > 0, h > 0 else { return }
                let center = CGPoint(x: w / 2, y: h / 2)
                let outerR = max(0, (min(w, h) / 2) - 1.5)

                let outerPath = Path(ellipseIn: CGRect(x: center.x - outerR, y: center.y - outerR, width: outerR * 2, height: outerR * 2))
                ctx.stroke(outerPath, with: .color(color), lineWidth: 1.3)

                for i in 0..<8 {
                    let angle = Double(i) * 2.0 * .pi / 8.0
                    let px = center.x + outerR * CGFloat(cos(angle))
                    let py = center.y + outerR * CGFloat(sin(angle))
                    let dot = Path(ellipseIn: CGRect(x: px - 1.1, y: py - 1.1, width: 2.2, height: 2.2))
                    ctx.fill(dot, with: .color(color))
                }

                let innerR = outerR * 0.76
                let innerPath = Path(ellipseIn: CGRect(x: center.x - innerR, y: center.y - innerR, width: innerR * 2, height: innerR * 2))
                ctx.stroke(innerPath, with: .color(color.opacity(0.75)), lineWidth: 0.8)

                var crowns = Path()
                crowns.move(to: CGPoint(x: center.x - 2, y: center.y - outerR - 1.2))
                crowns.addLine(to: CGPoint(x: center.x + 2, y: center.y - outerR - 1.2))
                crowns.move(to: CGPoint(x: center.x - 2, y: center.y + outerR + 1.2))
                crowns.addLine(to: CGPoint(x: center.x + 2, y: center.y + outerR + 1.2))
                ctx.stroke(crowns, with: .color(color), style: StrokeStyle(lineWidth: 1.0, lineCap: .round))
            }

            Text(label)
                .font(.system(size: fontSize, weight: .bold))
                .foregroundStyle(textColor)
                .lineLimit(1)
        }
        .frame(width: size, height: size)
    }
}

struct OrnamentalSurahBanner: View {
    @Environment(\.sirajTheme) private var theme
    let name: String
    var compact: Bool = false
    var accentColor: Color? = nil
    var textColor: Color? = nil

    var body: some View {
        let frameColor = accentColor ?? theme.primary
        let fgColor = textColor ?? theme.onBackground
        let minHeight: CGFloat = compact ? 74 : 108

        ZStack {
            Canvas { ctx, sz in
                let w = sz.width
                let h = sz.height
                guard w > 8, h > 8 else { return }
                let outer = Path(roundedRect: CGRect(origin: .zero, size: sz).insetBy(dx: 0.75, dy: 0.75), cornerRadius: 12)
                ctx.stroke(outer, with: .color(frameColor), lineWidth: 1.5)

                let inner = Path(roundedRect: CGRect(origin: .zero, size: sz).insetBy(dx: 4, dy: 4), cornerRadius: 8)
                ctx.stroke(inner, with: .color(frameColor), lineWidth: 0.6)

                let m: CGFloat = 2
                let c: CGFloat = 16
                var corners = Path()
                corners.move(to: CGPoint(x: m, y: m + c)); corners.addLine(to: CGPoint(x: m, y: m)); corners.addLine(to: CGPoint(x: m + c, y: m))
                corners.move(to: CGPoint(x: w - m - c, y: m)); corners.addLine(to: CGPoint(x: w - m, y: m)); corners.addLine(to: CGPoint(x: w - m, y: m + c))
                corners.move(to: CGPoint(x: m, y: h - m - c)); corners.addLine(to: CGPoint(x: m, y: h - m)); corners.addLine(to: CGPoint(x: m + c, y: h - m))
                corners.move(to: CGPoint(x: w - m - c, y: h - m)); corners.addLine(to: CGPoint(x: w - m, y: h - m)); corners.addLine(to: CGPoint(x: w - m, y: h - m - c))
                ctx.stroke(corners, with: .color(frameColor), lineWidth: 2.8)
            }

            Text(name)
                .font(theme.amiriFont(size: compact ? 24 : 29, weight: .bold))
                .foregroundStyle(fgColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 18)
                .padding(.vertical, compact ? 8 : 14)
        }
        .frame(maxWidth: .infinity, minHeight: minHeight)
    }
}

struct AyahQuoteView: View {
    let ayah: Ayah
    let edition: MushafEdition
    var fontSize: CGFloat = 22
    let color: Color
    var alignment: TextAlignment = .trailing
    var lineLimit: Int? = nil

    var body: some View {
        let resolved = resolveQuote()
        Text(resolved.text)
            .font(.custom(resolved.fontName, size: fontSize * resolved.scale))
            .foregroundStyle(color)
            .multilineTextAlignment(alignment)
            .lineSpacing(fontSize * 0.45)
            .lineLimit(lineLimit)
            .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : .trailing)
            .environment(\.layoutDirection, .rightToLeft)
    }

    private func resolveQuote() -> (text: String, fontName: String, scale: CGFloat) {
        if edition == .shamarly, let sh = ayah.textShamarly, !sh.isEmpty {
            return (ShamarlyText.quote(sh), "AmiriQuran-Regular", 1.0)
        }
        if edition == .indopak, let ip = ayah.textIndopak, !ip.isEmpty {
            let attached = QuranTables.attachIndopakPauseMarks(ip)
            let split = QuranTables.splitIndopakAyahEnd(attached)
            let text: String
            if let marker = split.marker {
                text = split.body.isEmpty ? marker : "\(split.body) \u{2060}\(marker)"
            } else {
                text = split.body
            }
            return (text, "AlQuranIndoPakbyQuranWBW", 0.91)
        }
        return (DigitalKhattText.forDisplay(ayah.textUthmani), "DigitalKhattOldMadinaRegular", 1.0)
    }
}

struct ContinueReadingCard: View {
    @Environment(\.sirajTheme) private var theme
    let position: ReadingPosition?
    let bookmark: QuranBookmark?
    let surahs: [Surah]
    let onContinue: () -> Void
    let onOpenBookmark: (QuranBookmark) -> Void

    var body: some View {
        let page = position?.page ?? 1
        let pageCount = max(1, position?.pageCount ?? 604)
        let juz = position?.juz ?? 1
        let surahNum = position?.surahNumber ?? 1

        VStack(alignment: .leading, spacing: 0) {
            Button(action: onContinue) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(theme.t(position != nil ? "quran_continue_reading" : "quran_reading"))
                            .font(theme.scaledFont(size: 11, weight: .black))
                            .tracking(theme.isRTL ? 0 : 1.1)
                            .foregroundStyle(theme.primary)
                            .lineLimit(1)

                        if let pos = position {
                            Text(surahName(pos.surahNumber))
                                .font(theme.scaledFont(size: 21, weight: .black))
                                .foregroundStyle(theme.onSurface)
                                .lineLimit(1)
                            Text(theme.t(
                                "last_read_where",
                                theme.digits(String(pos.ayahNumber)),
                                theme.digits(String(pos.page)),
                                theme.digits(String(pos.juz))
                            ))
                            .font(theme.scaledFont(size: 13.5))
                            .foregroundStyle(theme.onSurfaceVariant)
                            .lineLimit(1)
                        } else {
                            Text(theme.t("quran_start_journey"))
                                .font(theme.scaledFont(size: 16, weight: .bold))
                                .foregroundStyle(theme.onSurface)
                                .lineLimit(2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    ZStack {
                        Circle()
                            .fill(theme.primary)
                            .frame(width: 48, height: 48)
                        Image(systemName: theme.isRTL ? "arrow.left" : "arrow.right")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(theme.onPrimary)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer().frame(height: 18)

            HStack(spacing: 8) {
                ProgressGaugeRing(
                    progress: Double(page) / Double(pageCount),
                    valueText: theme.digits(String(page)),
                    label: theme.t("last_read_page_gauge")
                )
                ProgressGaugeRing(
                    progress: Double(juz) / 30.0,
                    valueText: theme.digits("\(juz)/30"),
                    label: theme.t("quran_juz")
                )
                ProgressGaugeRing(
                    progress: Double(surahNum) / 114.0,
                    valueText: theme.digits("\(surahNum)/114"),
                    label: theme.t("quran_surah")
                )
            }

            if let bm = bookmark,
               bm.surahNumber != position?.surahNumber || bm.ayahNumber != position?.ayahNumber {
                Divider()
                    .background(theme.outlineVariant.opacity(0.35))
                    .padding(.top, 14)

                Button {
                    onOpenBookmark(bm)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(theme.secondary)
                        Text(theme.t(
                            "dashboard_reading_bookmark",
                            surahName(bm.surahNumber, fallback: bm.surahName),
                            theme.digits(String(bm.ayahNumber))
                        ))
                        .font(theme.scaledFont(size: 13.5, weight: .semibold))
                        .foregroundStyle(theme.onSurface)
                        .lineLimit(1)
                        Spacer()
                        Image(systemName: theme.isRTL ? "arrow.left" : "arrow.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(theme.onSurfaceVariant)
                    }
                    .padding(.top, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .sirajCardSurface(cornerRadius: 28)
    }

    private func surahName(_ number: Int, fallback: String = "") -> String {
        if let found = surahs.first(where: { $0.number == number }) {
            return SurahNames.forLanguage(found, language: theme.language)
        }
        if !fallback.isEmpty { return fallback }
        return theme.t("quran_surah_label", theme.digits(String(number)))
    }
}

private struct ProgressGaugeRing: View {
    @Environment(\.sirajTheme) private var theme
    let progress: Double
    let valueText: String
    let label: String

    var body: some View {
        let clamped = min(1.0, max(0.0, progress))
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(theme.outlineVariant.opacity(0.25), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: clamped)
                    .stroke(theme.primary, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(valueText)
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(theme.onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(width: 60, height: 60)

            Text(label)
                .font(theme.scaledFont(size: 11, weight: .black))
                .foregroundStyle(theme.outline)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}
