import CoreGraphics
import CoreText
import SirajCore
import SwiftUI
import UIKit

private enum PageSettingKind {
    case qcfGlyphs
    case shapedWords
}

private struct RenderedWord {
    let word: MushafWord
    let glyphs: String
    let emWidth: CGFloat
    let isMarker: Bool
    let trailingMark: String?
}

private struct RenderedLine {
    let lineNumber: Int
    let lineType: MushafLineType
    let isCentered: Bool
    let surahNumber: Int?
    let words: [RenderedWord]
    let emWidth: CGFloat
    let marginMark: String?
}

private struct PreparedMushafLayout {
    let page: MushafPage
    let edition: MushafEdition
    let setting: PageSettingKind
    let pageFace: QcfFaceMetrics
    let basmalahFace: QcfFaceMetrics?
    let bannerFace: QcfFaceMetrics?
    let lines: [RenderedLine]
    let columnEm: CGFloat
    let minColumnEm: CGFloat
    let firstLineNumber: Int
    let lastLineNumber: Int
    let fillsPage: Bool
    let maxSlotFill: CGFloat
    let baselineDropEm: CGFloat
    let naturalGapEm: CGFloat
    let tightGapEm: CGFloat
    let minGapEm: CGFloat
    let maxStretch: CGFloat
    let minStretch: CGFloat
    let wordScaleX: CGFloat
    let emboldenEm: CGFloat
    let basmalahText: String?
    let usesShamarlyTitles: Bool
}

private struct PlacedWord {
    let word: MushafWord
    let glyphs: String
    let isMarker: Bool
    let left: CGFloat
    let right: CGFloat
    let top: CGFloat
    let bottom: CGFloat
    let baseline: CGFloat
    let glyphX: [CGFloat]
    let lineNumber: Int
    let textSize: CGFloat
    let scaleX: CGFloat
    let trailingMark: String?
    let trailingMarkX: CGFloat
    let hitLeft: CGFloat
    let hitRight: CGFloat
}

private struct PlacedOrnament {
    let face: QcfFaceMetrics
    let text: String
    let glyphX: [CGFloat]
    let baseline: CGFloat
    let textSize: CGFloat
    let shaped: Bool
    let tinted: Bool
    let scaleX: CGFloat
}

private struct PlacedTitleFrame {
    let outline: CGPath
    let rules: CGPath
    let knots: CGPath
}

private struct PlacedMushafPage {
    let words: [PlacedWord]
    let ornaments: [PlacedOrnament]
    let frames: [PlacedTitleFrame]
    let textSize: CGFloat
    let width: CGFloat
    let height: CGFloat
}

private enum MushafLayoutBuilder {
    static let nominalLines = 15

    static func prepare(page: MushafPage, edition: MushafEdition, store: QuranStore) -> PreparedMushafLayout? {
        switch edition {
        case .madinah:
            if let qcf = prepareQcfMadinah(page: page, store: store) {
                return qcf
            }
            return prepareFallbackMadinah(page: page, store: store)
        case .indopak:
            return prepareIndopak(page: page, store: store)
        case .shamarly:
            return prepareShamarly(page: page, store: store)
        }
    }

    private static func prepareQcfMadinah(page: MushafPage, store: QuranStore) -> PreparedMushafLayout? {
        guard let pageFace = store.fontCache.pageFace(for: page.pageNumber),
              let table = store.qcfTable,
              let entry = table.entry(forPage: page.pageNumber) else { return nil }

        let sortedLines = page.lines.sorted { $0.lineNumber < $1.lineNumber }
        let allWords = sortedLines.flatMap(\.words)
        guard allWords.count == entry.slotCounts.count,
              QcfGlyphTable.verifyFingerprint(words: allWords, expected: entry.fingerprint) else {
            return nil
        }

        var wordIndex = 0
        var slot = 0
        var renderedLines: [RenderedLine] = []
        renderedLines.reserveCapacity(sortedLines.count)

        for line in sortedLines {
            var lineWords: [RenderedWord] = []
            lineWords.reserveCapacity(line.words.count)
            for w in line.words {
                let count = Int(entry.slotCounts[wordIndex])
                wordIndex += 1
                var glyphs = ""
                for s in 0..<count {
                    glyphs += QcfGlyphTable.v1Glyph(slot: slot + s)
                }
                slot += count
                let em = pageFace.advance(glyphs: glyphs)
                lineWords.append(RenderedWord(
                    word: w,
                    glyphs: glyphs,
                    emWidth: em,
                    isMarker: isMadinahMarker(w.text),
                    trailingMark: nil
                ))
            }
            let totalEm = lineWords.reduce(CGFloat(0)) { $0 + $1.emWidth }
            renderedLines.append(RenderedLine(
                lineNumber: line.lineNumber,
                lineType: line.lineType,
                isCentered: line.isCentered,
                surahNumber: line.surahNumber,
                words: lineWords,
                emWidth: totalEm,
                marginMark: nil
            ))
        }

        let columnEm = renderedLines
            .filter { !$0.words.isEmpty && !$0.isCentered }
            .map(\.emWidth).max()
            ?? renderedLines.filter { !$0.words.isEmpty }.map(\.emWidth).max()
            ?? 0
        guard columnEm > 0 else { return nil }

        let nonEmpty = renderedLines.filter { $0.lineType != .empty }
        let firstLine = nonEmpty.map(\.lineNumber).min() ?? 1
        let lastLine = nonEmpty.map(\.lineNumber).max() ?? nominalLines

        return PreparedMushafLayout(
            page: page,
            edition: .madinah,
            setting: .qcfGlyphs,
            pageFace: pageFace,
            basmalahFace: store.fontCache.basmalah(),
            bannerFace: store.fontCache.surahBanner(),
            lines: renderedLines,
            columnEm: columnEm,
            minColumnEm: columnEm,
            firstLineNumber: firstLine,
            lastLineNumber: lastLine,
            fillsPage: page.pageNumber > 2,
            maxSlotFill: 0.72,
            baselineDropEm: (pageFace.ascentEm - pageFace.descentEm) / 2.0,
            naturalGapEm: 0,
            tightGapEm: 0,
            minGapEm: 0,
            maxStretch: 1.0,
            minStretch: 1.0,
            wordScaleX: 1.0,
            emboldenEm: 0,
            basmalahText: nil,
            usesShamarlyTitles: false
        )
    }

    private static func prepareFallbackMadinah(page: MushafPage, store: QuranStore) -> PreparedMushafLayout? {
        guard let face = store.fontCache.madinahFallback() ?? store.fontCache.shamarly() else { return nil }
        let sortedLines = page.lines.sorted { $0.lineNumber < $1.lineNumber }
        var renderedLines: [RenderedLine] = []
        for line in sortedLines {
            let lineWords: [RenderedWord] = line.words.map { w in
                let marker = w.isMarker || isMadinahMarker(w.text)
                let shown = marker ? "\u{06DD}\(DigitFormatter.localizeDigits(String(w.ayahNumber ?? 1), eastern: true, lang: "ar"))" : w.text
                return RenderedWord(
                    word: w,
                    glyphs: shown,
                    emWidth: max(0.25, face.runAdvance(shown, rtl: !marker)),
                    isMarker: marker,
                    trailingMark: nil
                )
            }
            let totalEm = lineWords.reduce(CGFloat(0)) { $0 + $1.emWidth }
            renderedLines.append(RenderedLine(
                lineNumber: line.lineNumber,
                lineType: line.lineType,
                isCentered: line.isCentered || page.pageNumber <= 2,
                surahNumber: line.surahNumber,
                words: lineWords,
                emWidth: totalEm,
                marginMark: nil
            ))
        }
        let gap: CGFloat = 0.24
        let columnEm = renderedLines
            .filter { !$0.words.isEmpty && !$0.isCentered }
            .map { $0.emWidth + gap * CGFloat(max(0, $0.words.count - 1)) }
            .max()
            ?? renderedLines.filter { !$0.words.isEmpty }.map { $0.emWidth + gap * CGFloat(max(0, $0.words.count - 1)) }.max()
            ?? 16.0
        let nonEmpty = renderedLines.filter { $0.lineType != .empty }
        return PreparedMushafLayout(
            page: page,
            edition: .madinah,
            setting: .shapedWords,
            pageFace: face,
            basmalahFace: nil,
            bannerFace: store.fontCache.surahBanner(),
            lines: renderedLines,
            columnEm: max(12, columnEm),
            minColumnEm: max(12, columnEm * 0.88),
            firstLineNumber: nonEmpty.map(\.lineNumber).min() ?? 1,
            lastLineNumber: nonEmpty.map(\.lineNumber).max() ?? nominalLines,
            fillsPage: page.pageNumber > 2,
            maxSlotFill: 0.50,
            baselineDropEm: 0.30,
            naturalGapEm: gap,
            tightGapEm: 0.14,
            minGapEm: 0.08,
            maxStretch: 1.06,
            minStretch: 0.90,
            wordScaleX: 1.0,
            emboldenEm: 0,
            basmalahText: ShamarlyText.basmalah,
            usesShamarlyTitles: false
        )
    }

    private static func prepareIndopak(page: MushafPage, store: QuranStore) -> PreparedMushafLayout? {
        guard let face = store.fontCache.indopak() else { return nil }
        let sortedLines = page.lines.sorted { $0.lineNumber < $1.lineNumber }
        var renderedLines: [RenderedLine] = []

        for line in sortedLines {
            var lineWords: [RenderedWord] = []
            for w in line.words {
                let isMarker = w.isMarker || QuranTables.isIndopakAyahEndMarker(w.text)
                let isPauseOnly = !isMarker && !w.text.unicodeScalars.contains { $0.properties.generalCategory == .otherLetter }
                if isPauseOnly, let last = lineWords.popLast() {
                    lineWords.append(RenderedWord(
                        word: last.word,
                        glyphs: last.glyphs,
                        emWidth: last.emWidth,
                        isMarker: last.isMarker,
                        trailingMark: (last.trailingMark ?? "") + w.text
                    ))
                    continue
                }
                let em = max(0.20, face.runAdvance(w.text, rtl: !isMarker))
                lineWords.append(RenderedWord(
                    word: w,
                    glyphs: w.text,
                    emWidth: em,
                    isMarker: isMarker,
                    trailingMark: nil
                ))
            }
            let totalEm = lineWords.reduce(CGFloat(0)) { $0 + $1.emWidth }
            renderedLines.append(RenderedLine(
                lineNumber: line.lineNumber,
                lineType: line.lineType,
                isCentered: line.isCentered,
                surahNumber: line.surahNumber,
                words: lineWords,
                emWidth: totalEm,
                marginMark: nil
            ))
        }

        let naturalGap: CGFloat = 0.20
        let columnEm = renderedLines
            .filter { !$0.words.isEmpty && !$0.isCentered }
            .map { $0.emWidth + naturalGap * CGFloat(max(0, $0.words.count - 1)) }
            .max()
            ?? renderedLines.filter { !$0.words.isEmpty }.map { $0.emWidth + naturalGap * CGFloat(max(0, $0.words.count - 1)) }.max()
            ?? 16.0
        let nonEmpty = renderedLines.filter { $0.lineType != .empty }

        return PreparedMushafLayout(
            page: page,
            edition: .indopak,
            setting: .shapedWords,
            pageFace: face,
            basmalahFace: nil,
            bannerFace: store.fontCache.surahBanner(),
            lines: renderedLines,
            columnEm: max(12.0, columnEm),
            minColumnEm: max(11.0, columnEm * 0.88),
            firstLineNumber: nonEmpty.map(\.lineNumber).min() ?? 1,
            lastLineNumber: nonEmpty.map(\.lineNumber).max() ?? nominalLines,
            fillsPage: page.pageNumber > 2,
            maxSlotFill: 0.46,
            baselineDropEm: 0.32,
            naturalGapEm: naturalGap,
            tightGapEm: 0.11,
            minGapEm: 0.06,
            maxStretch: 1.08,
            minStretch: 0.88,
            wordScaleX: 0.94,
            emboldenEm: 0,
            basmalahText: "\u{0628}\u{0650}\u{0633}\u{0652}\u{0645}\u{0650} \u{0627}\u{0644}\u{0644}\u{0651}\u{0670}\u{0647}\u{0650} \u{0627}\u{0644}\u{0631}\u{0651}\u{064E}\u{062D}\u{0652}\u{0645}\u{0670}\u{0646}\u{0650} \u{0627}\u{0644}\u{0631}\u{0651}\u{064E}\u{062D}\u{0650}\u{06CC}\u{0652}\u{0645}\u{0650}",
            usesShamarlyTitles: false
        )
    }

    private static func prepareShamarly(page: MushafPage, store: QuranStore) -> PreparedMushafLayout? {
        guard let face = store.fontCache.shamarly() else { return nil }
        let sortedLines = page.lines.sorted { $0.lineNumber < $1.lineNumber }
        var renderedLines: [RenderedLine] = []

        for line in sortedLines {
            var lineWords: [RenderedWord] = []
            var pendingSajdah = false
            var lineOpensQuarter = false

            for w in line.words {
                let isDigits = !w.text.isEmpty && w.text.allSatisfy { ($0 >= "٠" && $0 <= "٩") || ($0 >= "0" && $0 <= "9") }
                if w.isMarker || isDigits {
                    let med = ShamarlyText.medallion(w.text, sajdah: pendingSajdah)
                    pendingSajdah = false
                    lineWords.append(RenderedWord(
                        word: w,
                        glyphs: med,
                        emWidth: max(0.30, face.runAdvance(med, rtl: false)),
                        isMarker: true,
                        trailingMark: nil
                    ))
                } else {
                    let parsed = ShamarlyText.word(w.text)
                    if parsed.opensQuarter { lineOpensQuarter = true }
                    if parsed.endsSajdah { pendingSajdah = true }
                    lineWords.append(RenderedWord(
                        word: w,
                        glyphs: parsed.text,
                        emWidth: max(0.20, face.runAdvance(parsed.text, rtl: true)),
                        isMarker: false,
                        trailingMark: nil
                    ))
                }
            }
            let totalEm = lineWords.reduce(CGFloat(0)) { $0 + $1.emWidth }
            renderedLines.append(RenderedLine(
                lineNumber: line.lineNumber,
                lineType: line.lineType,
                isCentered: line.isCentered,
                surahNumber: line.surahNumber,
                words: lineWords,
                emWidth: totalEm,
                marginMark: lineOpensQuarter ? String(ShamarlyText.quarterSign) : nil
            ))
        }

        let measureEm = CGFloat(ShamarlyMeasures.measureEm(page: page.pageNumber))
        let nonEmpty = renderedLines.filter { $0.lineType != .empty }

        return PreparedMushafLayout(
            page: page,
            edition: .shamarly,
            setting: .shapedWords,
            pageFace: face,
            basmalahFace: nil,
            bannerFace: nil,
            lines: renderedLines,
            columnEm: measureEm,
            minColumnEm: page.pageNumber <= 2 ? max(13.0, measureEm - 2.2) : measureEm,
            firstLineNumber: nonEmpty.map(\.lineNumber).min() ?? 1,
            lastLineNumber: nonEmpty.map(\.lineNumber).max() ?? nominalLines,
            fillsPage: page.pageNumber > 2,
            maxSlotFill: 0.46,
            baselineDropEm: 0.40,
            naturalGapEm: 0.175,
            tightGapEm: 0.125,
            minGapEm: 0.105,
            maxStretch: 1.06,
            minStretch: 0.88,
            wordScaleX: 1.0,
            emboldenEm: 0.032,
            basmalahText: ShamarlyText.basmalah,
            usesShamarlyTitles: true
        )
    }

    private static func isMadinahMarker(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        return trimmed.unicodeScalars.allSatisfy { ($0.value >= 0x0660 && $0.value <= 0x0669) || $0.value == 0x06DD }
    }

    static func place(layout: PreparedMushafLayout, width: CGFloat, height: CGFloat, sideMargin: CGFloat) -> PlacedMushafPage? {
        guard width > 0, height > 0 else { return nil }
        let column = width - 2 * sideMargin
        guard column > 0 else { return nil }

        let usedSlots = max(1, layout.lastLineNumber - layout.firstLineNumber + 1)
        let slots = layout.fillsPage ? usedSlots : max(nominalLines, layout.lastLineNumber)
        let slotHeight = height / CGFloat(slots)
        let face = layout.pageFace

        let columnEm = min(layout.columnEm, max(layout.minColumnEm, column / (slotHeight * layout.maxSlotFill)))
        let textSize = min(column / columnEm, slotHeight * layout.maxSlotFill)
        guard textSize > 0 else { return nil }

        let blockWidth = columnEm * textSize
        let columnRight = (width + blockWidth) / 2.0
        let topOffset = (height - CGFloat(usedSlots) * slotHeight) / 2.0

        var placedWords: [PlacedWord] = []
        var ornaments: [PlacedOrnament] = []
        var frames: [PlacedTitleFrame] = []

        for line in layout.lines {
            let slotTop = topOffset + CGFloat(line.lineNumber - layout.firstLineNumber) * slotHeight
            let slotCentre = slotTop + slotHeight / 2.0

            if let mark = line.marginMark {
                let margin = columnRight - blockWidth
                let markEm = face.runAdvance(mark)
                if markEm > 0 && margin > 4 {
                    let size = min(textSize * 0.9, margin * 0.72 / markEm)
                    let ink = face.inkBox(mark)
                    ornaments.append(PlacedOrnament(
                        face: face,
                        text: mark,
                        glyphX: [(margin - markEm * size) / 2.0],
                        baseline: slotCentre - ink.centre * size,
                        textSize: size,
                        shaped: true,
                        tinted: true,
                        scaleX: 1.0
                    ))
                }
            }

            if line.lineType == .surahName, let surahNum = line.surahNumber {
                if layout.usesShamarlyTitles, let banner = ShamarlyBanners.forSurah(surahNum) {
                    placeShamarlyTitleFrame(
                        face: face,
                        banner: banner,
                        left: columnRight - blockWidth,
                        right: columnRight,
                        top: max(2, slotTop - slotHeight),
                        bottom: slotTop + slotHeight,
                        textSize: textSize,
                        frames: &frames,
                        ornaments: &ornaments
                    )
                } else if let bannerFace = layout.bannerFace {
                    let glyph = QcfGlyphTable.surahBanner(surahNumber: surahNum)
                    let em = bannerFace.advance(glyphs: glyph)
                    let ink = bannerFace.inkBox(glyph)
                    if !glyph.isEmpty, em > 0 {
                        let size = ink.height > 0
                            ? min(blockWidth * 0.96 / em, slotHeight * 0.88 / ink.height)
                            : blockWidth * 0.96 / em
                        ornaments.append(PlacedOrnament(
                            face: bannerFace,
                            text: glyph,
                            glyphX: [(width - em * size) / 2.0],
                            baseline: slotCentre - ink.centre * size,
                            textSize: size,
                            shaped: false,
                            tinted: true,
                            scaleX: 1.0
                        ))
                    }
                }
            } else if line.lineType == .basmallah && line.words.isEmpty {
                if layout.setting == .shapedWords, let text = layout.basmalahText {
                    let em = face.runAdvance(text) * layout.wordScaleX
                    let ink = face.inkBox(text)
                    if em > 0 {
                        let size = ink.height > 0
                            ? min(min(blockWidth * 0.78 / em, slotHeight * 0.84 / ink.height), textSize)
                            : min(blockWidth * 0.78 / em, textSize)
                        ornaments.append(PlacedOrnament(
                            face: face,
                            text: text,
                            glyphX: [(width - em * size) / 2.0],
                            baseline: slotCentre - ink.centre * size,
                            textSize: size,
                            shaped: true,
                            tinted: false,
                            scaleX: layout.wordScaleX
                        ))
                    }
                } else if let bsmlFace = layout.basmalahFace {
                    let glyphs = QcfGlyphTable.basmalahGlyphs
                    let em = bsmlFace.advance(glyphs: glyphs)
                    let ink = bsmlFace.inkBox(glyphs)
                    if em > 0 {
                        let size = ink.height > 0
                            ? min(blockWidth * 0.68 / em, slotHeight * 0.84 / ink.height)
                            : blockWidth * 0.68 / em
                        var x = (width + em * size) / 2.0
                        var xs: [CGFloat] = []
                        for cu in glyphs.utf16 {
                            x -= bsmlFace.advance(codeUnit: cu) * size
                            xs.append(x)
                        }
                        ornaments.append(PlacedOrnament(
                            face: bsmlFace,
                            text: glyphs,
                            glyphX: xs,
                            baseline: slotCentre - ink.centre * size,
                            textSize: size,
                            shaped: false,
                            tinted: false,
                            scaleX: 1.0
                        ))
                    }
                }
            } else if !line.words.isEmpty && layout.setting == .shapedWords {
                let gaps = line.words.count - 1
                let markerEm = line.words.filter(\.isMarker).reduce(CGFloat(0)) { $0 + $1.emWidth }
                let wordEm = (line.emWidth - markerEm) * layout.wordScaleX
                var lineSize = textSize
                var stretch: CGFloat = 1.0
                let gapEm: CGFloat
                let lineEm: CGFloat

                if line.isCentered || gaps == 0 || wordEm <= 0 {
                    gapEm = layout.naturalGapEm
                    lineEm = markerEm + wordEm + gapEm * CGFloat(gaps)
                } else {
                    stretch = min(layout.maxStretch, (columnEm - markerEm - layout.naturalGapEm * CGFloat(gaps)) / wordEm)
                    if stretch < 1.0 {
                        stretch = min(1.0, max(layout.minStretch, (columnEm - markerEm - layout.tightGapEm * CGFloat(gaps)) / wordEm))
                    }
                    let slack = columnEm - markerEm - wordEm * stretch
                    if slack >= layout.minGapEm * CGFloat(gaps) {
                        gapEm = slack / CGFloat(gaps)
                    } else {
                        lineSize = textSize * columnEm / (markerEm + wordEm * stretch + layout.minGapEm * CGFloat(gaps))
                        gapEm = layout.minGapEm
                    }
                    lineEm = markerEm + wordEm * stretch + gapEm * CGFloat(gaps)
                }

                let gap = gapEm * lineSize
                var x = (line.isCentered || gaps == 0) ? (width + lineEm * lineSize) / 2.0 : columnRight
                let baseline = slotCentre + layout.baselineDropEm * lineSize

                for (index, w) in line.words.enumerated() {
                    let wordStretch = w.isMarker ? 1.0 : layout.wordScaleX * stretch
                    let right = x
                    let left = right - w.emWidth * wordStretch * lineSize
                    let markX = index == gaps ? left + 0.14 * lineSize : left - gap / 2.0
                    placedWords.append(PlacedWord(
                        word: w.word,
                        glyphs: w.glyphs,
                        isMarker: w.isMarker,
                        left: left,
                        right: right,
                        top: slotTop,
                        bottom: slotTop + slotHeight,
                        baseline: baseline,
                        glyphX: [left],
                        lineNumber: line.lineNumber,
                        textSize: lineSize,
                        scaleX: wordStretch,
                        trailingMark: w.trailingMark,
                        trailingMarkX: markX,
                        hitLeft: index == gaps ? left : left - gap / 2.0,
                        hitRight: index == 0 ? right : right + gap / 2.0
                    ))
                    x = left - gap
                }
            } else if !line.words.isEmpty {
                let stretch = (line.isCentered || line.emWidth <= 0) ? 1.0 : columnEm / line.emWidth
                let lineWidth = line.emWidth * stretch * textSize
                var x = line.isCentered ? (width + lineWidth) / 2.0 : columnRight
                let baseline = slotCentre + layout.baselineDropEm * textSize

                for w in line.words {
                    let right = x
                    var xs: [CGFloat] = []
                    xs.reserveCapacity(w.glyphs.utf16.count)
                    for cu in w.glyphs.utf16 {
                        x -= face.advance(codeUnit: cu) * stretch * textSize
                        xs.append(x)
                    }
                    placedWords.append(PlacedWord(
                        word: w.word,
                        glyphs: w.glyphs,
                        isMarker: w.isMarker,
                        left: x,
                        right: right,
                        top: slotTop,
                        bottom: slotTop + slotHeight,
                        baseline: baseline,
                        glyphX: xs,
                        lineNumber: line.lineNumber,
                        textSize: textSize,
                        scaleX: 1.0,
                        trailingMark: nil,
                        trailingMarkX: 0,
                        hitLeft: x,
                        hitRight: right
                    ))
                }
            }
        }

        return PlacedMushafPage(
            words: placedWords,
            ornaments: ornaments,
            frames: frames,
            textSize: textSize,
            width: width,
            height: height
        )
    }

    private static func placeShamarlyTitleFrame(
        face: QcfFaceMetrics,
        banner: ShamarlyBanner,
        left: CGFloat,
        right: CGFloat,
        top: CGFloat,
        bottom: CGFloat,
        textSize: CGFloat,
        frames: inout [PlacedTitleFrame],
        ornaments: inout [PlacedOrnament]
    ) {
        let height = bottom - top
        let pad = height * 0.04
        let frameTop = top + pad
        let frameBottom = bottom - pad
        let centreX = (left + right) / 2.0
        let centreY = (frameTop + frameBottom) / 2.0
        let frameHeight = frameBottom - frameTop
        let width = right - left
        let gap = frameHeight * 0.05

        let rules = CGMutablePath()
        rules.addRect(CGRect(x: left, y: frameTop, width: width, height: frameHeight))
        rules.addRect(CGRect(x: left + gap, y: frameTop + gap, width: width - gap * 2, height: frameHeight - gap * 2))

        let cTop = frameTop + frameHeight * 0.13
        let cBottom = frameBottom - frameHeight * 0.13
        let cLeft = left + width * 0.15
        let cRight = right - width * 0.15
        let r = (cBottom - cTop) / 2.0

        let outline = CGMutablePath()
        outline.move(to: CGPoint(x: cLeft + r, y: cTop))
        outline.addLine(to: CGPoint(x: cRight - r, y: cTop))
        outline.addCurve(
            to: CGPoint(x: cRight + r * 0.06, y: centreY),
            control1: CGPoint(x: cRight - r * 0.30, y: cTop),
            control2: CGPoint(x: cRight - r * 0.02, y: centreY - r * 0.40)
        )
        outline.addCurve(
            to: CGPoint(x: cRight - r, y: cBottom),
            control1: CGPoint(x: cRight - r * 0.02, y: centreY + r * 0.40),
            control2: CGPoint(x: cRight - r * 0.30, y: cBottom)
        )
        outline.addLine(to: CGPoint(x: cLeft + r, y: cBottom))
        outline.addCurve(
            to: CGPoint(x: cLeft - r * 0.06, y: centreY),
            control1: CGPoint(x: cLeft + r * 0.30, y: cBottom),
            control2: CGPoint(x: cLeft + r * 0.02, y: centreY + r * 0.40)
        )
        outline.addCurve(
            to: CGPoint(x: cLeft + r, y: cTop),
            control1: CGPoint(x: cLeft + r * 0.02, y: centreY - r * 0.40),
            control2: CGPoint(x: cLeft + r * 0.30, y: cTop)
        )
        outline.closeSubpath()

        let knots = CGMutablePath()
        for side in [-1.0, 1.0] {
            let panelLeft = side < 0 ? left + gap : cRight + r * 0.06
            let panelRight = side < 0 ? cLeft - r * 0.06 : right - gap
            let cx = (panelLeft + panelRight) / 2.0
            let rx = min((panelRight - panelLeft) * 0.30, r * 0.85)
            let ry = min(r * 0.85, rx * 1.15)
            knots.move(to: CGPoint(x: cx, y: centreY - ry))
            knots.addLine(to: CGPoint(x: cx + rx, y: centreY))
            knots.addLine(to: CGPoint(x: cx, y: centreY + ry))
            knots.addLine(to: CGPoint(x: cx - rx, y: centreY))
            knots.closeSubpath()

            rules.move(to: CGPoint(x: cx, y: centreY - ry * 0.5))
            rules.addLine(to: CGPoint(x: cx + rx * 0.5, y: centreY))
            rules.addLine(to: CGPoint(x: cx, y: centreY + ry * 0.5))
            rules.addLine(to: CGPoint(x: cx - rx * 0.5, y: centreY))
            rules.closeSubpath()
            rules.move(to: CGPoint(x: panelLeft, y: centreY))
            rules.addLine(to: CGPoint(x: cx - rx, y: centreY))
            rules.move(to: CGPoint(x: cx + rx, y: centreY))
            rules.addLine(to: CGPoint(x: panelRight, y: centreY))
        }

        frames.append(PlacedTitleFrame(outline: outline, rules: rules, knots: knots))

        let textWidth = (cRight - cLeft) - r * 0.9
        let lineBand = r * 0.90
        let firstMid = centreY - r * 0.46
        let secondMid = centreY + r * 0.48

        for (text, cap, mid) in [(banner.first, textSize, firstMid), (banner.second, textSize * 0.86, secondMid)] {
            let em = face.runAdvance(text, rtl: true)
            let ink = face.inkBox(text)
            guard em > 0, ink.height > 0 else { continue }
            let sz = min(min(cap, textWidth / em), lineBand / ink.height)
            ornaments.append(PlacedOrnament(
                face: face,
                text: text,
                glyphX: [centreX - em * sz / 2.0],
                baseline: mid - ink.centre * sz,
                textSize: sz,
                shaped: true,
                tinted: false,
                scaleX: 1.0
            ))
        }
    }
}

private final class MushafCanvasUIView: UIView {
    var layout: PreparedMushafLayout? { didSet { placed = nil; setNeedsDisplay() } }
    var inkColor: UIColor = .label { didSet { setNeedsDisplay() } }
    var accentColor: UIColor = .systemYellow { didSet { setNeedsDisplay() } }
    var highlightSurah: Int? { didSet { setNeedsDisplay() } }
    var highlightAyah: Int? { didSet { setNeedsDisplay() } }
    var isDarkPage: Bool = false { didSet { setNeedsDisplay() } }
    var onTap: (() -> Void)?
    var onAyahLongPress: ((Int, Int) -> Void)?

    private var placed: PlacedMushafPage?
    private var lastBounds: CGSize = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)

        let lp = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        lp.minimumPressDuration = 0.32
        addGestureRecognizer(lp)
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func handleTap() {
        onTap?()
    }

    @objc private func handleLongPress(_ gr: UILongPressGestureRecognizer) {
        guard gr.state == .began, let placed else { return }
        let pt = gr.location(in: self)
        if let hit = placed.words.first(where: {
            pt.x >= $0.hitLeft && pt.x <= $0.hitRight && pt.y >= $0.top && pt.y <= $0.bottom
        }) {
            let surah = hit.word.surahNumber ?? layout?.page.ayahs.first(where: { $0.numberInSurah == hit.word.ayahNumber })?.surahNumber
            if let surah, let ayah = hit.word.ayahNumber {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onAyahLongPress?(surah, ayah)
            }
        }
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(), let layout else { return }
        if placed == nil || lastBounds != bounds.size {
            let margin: CGFloat = layout.edition == .shamarly ? 16 : 8
            placed = MushafLayoutBuilder.place(layout: layout, width: bounds.width, height: bounds.height, sideMargin: margin)
            lastBounds = bounds.size
        }
        guard let placed else { return }

        // 1. Shamarly title frames
        for frame in placed.frames {
            ctx.saveGState()
            ctx.setFillColor(accentColor.withAlphaComponent(0.11).cgColor)
            ctx.addPath(frame.outline)
            ctx.fillPath()

            ctx.setFillColor(accentColor.withAlphaComponent(0.20).cgColor)
            ctx.addPath(frame.knots)
            ctx.fillPath()

            ctx.setStrokeColor(accentColor.withAlphaComponent(0.75).cgColor)
            ctx.setLineWidth(max(0.75, 0.034 * placed.textSize))
            ctx.addPath(frame.rules)
            ctx.strokePath()

            ctx.setStrokeColor(accentColor.cgColor)
            ctx.setLineWidth(max(1.0, 0.047 * placed.textSize))
            ctx.addPath(frame.knots)
            ctx.strokePath()

            ctx.setLineWidth(max(1.1, 0.055 * placed.textSize))
            ctx.addPath(frame.outline)
            ctx.strokePath()
            ctx.restoreGState()
        }

        // 2. Highlight pill bands for active ayah
        if let hAyah = highlightAyah {
            let matching = placed.words.filter { w in
                let sMatch = highlightSurah == nil || w.word.surahNumber == nil || w.word.surahNumber == highlightSurah
                return sMatch && w.word.ayahNumber == hAyah
            }
            let byLine = Dictionary(grouping: matching, by: \.lineNumber)
            let fill = accentColor.withAlphaComponent(isDarkPage ? 0.24 : 0.14)
            ctx.setFillColor(fill.cgColor)
            for (_, rowWords) in byLine {
                guard let minX = rowWords.map(\.left).min(),
                      let maxX = rowWords.map(\.right).max(),
                      let top = rowWords.map(\.top).min(),
                      let bot = rowWords.map(\.bottom).max() else { continue }
                let pill = CGRect(x: minX - 3, y: top + 2, width: (maxX - minX) + 6, height: max(8, (bot - top) - 4))
                let path = UIBezierPath(roundedRect: pill, cornerRadius: 8)
                ctx.addPath(path.cgPath)
                ctx.fillPath()
            }
        }

        // 3. Ornaments (Surah banners, Basmalah, Shamarly margin rub' signs)
        for ornament in placed.ornaments {
            let color = ornament.tinted ? accentColor : inkColor
            let ctFont = ornament.face.font(size: ornament.textSize)
            if ornament.shaped {
                drawShapedText(
                    ctx: ctx,
                    text: ornament.text,
                    ctFont: ctFont,
                    x: ornament.glyphX.first ?? 0,
                    baselineY: ornament.baseline,
                    scaleX: ornament.scaleX,
                    color: color,
                    strokeEm: ornament.face === layout.pageFace ? layout.emboldenEm : 0,
                    textSize: ornament.textSize
                )
            } else {
                drawQcfGlyphs(
                    ctx: ctx,
                    text: ornament.text,
                    ctFont: ctFont,
                    xs: ornament.glyphX,
                    baselineY: ornament.baseline,
                    color: color
                )
            }
        }

        // 4. Words
        for w in placed.words {
            let color = w.isMarker ? accentColor : inkColor
            let ctFont = layout.pageFace.font(size: w.textSize)
            if layout.setting == .qcfGlyphs {
                drawQcfGlyphs(
                    ctx: ctx,
                    text: w.glyphs,
                    ctFont: ctFont,
                    xs: w.glyphX,
                    baselineY: w.baseline,
                    color: color
                )
            } else {
                drawShapedText(
                    ctx: ctx,
                    text: w.glyphs,
                    ctFont: ctFont,
                    x: w.glyphX.first ?? w.left,
                    baselineY: w.baseline,
                    scaleX: w.scaleX,
                    color: color,
                    strokeEm: layout.emboldenEm,
                    textSize: w.textSize
                )
                if let mark = w.trailingMark {
                    drawShapedText(
                        ctx: ctx,
                        text: mark,
                        ctFont: ctFont,
                        x: w.trailingMarkX,
                        baselineY: w.baseline,
                        scaleX: 1.0,
                        color: inkColor,
                        strokeEm: 0,
                        textSize: w.textSize
                    )
                }
            }
        }
    }

    private func drawQcfGlyphs(
        ctx: CGContext,
        text: String,
        ctFont: CTFont,
        xs: [CGFloat],
        baselineY: CGFloat,
        color: UIColor
    ) {
        let units = Array(text.utf16)
        guard units.count == xs.count else { return }
        ctx.saveGState()
        ctx.setFillColor(color.cgColor)
        ctx.setTextDrawingMode(.fill)

        for i in units.indices {
            var cu = units[i]
            var glyph: CGGlyph = 0
            guard CTFontGetGlyphsForCharacters(ctFont, &cu, &glyph, 1) else { continue }
            ctx.saveGState()
            ctx.translateBy(x: xs[i], y: baselineY)
            ctx.scaleBy(x: 1.0, y: -1.0)
            ctx.textMatrix = .identity
            var origin = CGPoint.zero
            CTFontDrawGlyphs(ctFont, &glyph, &origin, 1, ctx)
            ctx.restoreGState()
        }
        ctx.restoreGState()
    }

    private func drawShapedText(
        ctx: CGContext,
        text: String,
        ctFont: CTFont,
        x: CGFloat,
        baselineY: CGFloat,
        scaleX: CGFloat,
        color: UIColor,
        strokeEm: CGFloat,
        textSize: CGFloat
    ) {
        let attrs: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): ctFont,
            NSAttributedString.Key(kCTForegroundColorFromContextAttributeName as String): kCFBooleanTrue as Any
        ]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attrs))

        ctx.saveGState()
        ctx.translateBy(x: x, y: baselineY)
        ctx.scaleBy(x: scaleX, y: -1.0)
        ctx.textMatrix = .identity
        ctx.textPosition = .zero
        ctx.setFillColor(color.cgColor)
        if strokeEm > 0 {
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(strokeEm * textSize)
            ctx.setLineJoin(.round)
            ctx.setTextDrawingMode(.fillStroke)
        } else {
            ctx.setTextDrawingMode(.fill)
        }
        CTLineDraw(line, ctx)
        ctx.restoreGState()
    }
}

private struct MushafPageCanvasRepresentable: UIViewRepresentable {
    let layout: PreparedMushafLayout
    let inkColor: Color
    let accentColor: Color
    let highlightSurah: Int?
    let highlightAyah: Int?
    let isDarkPage: Bool
    let onTap: () -> Void
    let onAyahLongPress: (Int, Int) -> Void

    func makeUIView(context: Context) -> MushafCanvasUIView {
        let view = MushafCanvasUIView()
        updateUIView(view, context: context)
        return view
    }

    func updateUIView(_ uiView: MushafCanvasUIView, context: Context) {
        if uiView.layout?.page.pageNumber != layout.page.pageNumber
            || uiView.layout?.edition != layout.edition
            || uiView.layout?.page.lines.count != layout.page.lines.count {
            uiView.layout = layout
        }
        uiView.inkColor = UIColor(inkColor)
        uiView.accentColor = UIColor(accentColor)
        uiView.highlightSurah = highlightSurah
        uiView.highlightAyah = highlightAyah
        uiView.isDarkPage = isDarkPage
        uiView.onTap = onTap
        uiView.onAyahLongPress = onAyahLongPress
    }
}

struct MushafPageView: View {
    @Environment(\.sirajTheme) private var theme
    let pageNumber: Int
    let edition: MushafEdition
    let quranStore: QuranStore
    let paperColor: Color
    let inkColor: Color
    let accentColor: Color
    let isDarkPage: Bool
    let isBookmarked: Bool
    let highlightSurah: Int?
    let highlightAyah: Int?
    let onTapPage: () -> Void
    let onAyahLongPress: (Int, Int) -> Void

    @State private var loadedPage: MushafPage?
    @State private var prepared: PreparedMushafLayout?

    var body: some View {
        let isRightPage = pageNumber % 2 != 0
        let surahTitle = loadedPage?.surahName ?? quranStore.surahs.first(where: { $0.number == QuranTables.surahForPage(pageNumber, edition: edition) })?.name ?? ""
        let juzNum = loadedPage?.juzNumber ?? QuranTables.juzForPage(pageNumber, edition: edition)

        ZStack(alignment: isRightPage ? .topTrailing : .topLeading) {
            paperColor

            if isBookmarked {
                silkBookmarkRibbon
                    .padding(.horizontal, 8)
            }

            VStack(spacing: 2) {
                mushafHeaderRow(
                    surahName: surahTitle,
                    juzNumber: juzNum,
                    isRightPage: isRightPage,
                    ribbonInset: isBookmarked ? 28 : 0
                )

                Group {
                    if let prepared {
                        MushafPageCanvasRepresentable(
                            layout: prepared,
                            inkColor: inkColor,
                            accentColor: accentColor,
                            highlightSurah: highlightSurah,
                            highlightAyah: highlightAyah,
                            isDarkPage: isDarkPage,
                            onTap: onTapPage,
                            onAyahLongPress: onAyahLongPress
                        )
                    } else {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { onTapPage() }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                mushafFooterBadge(pageNumber: pageNumber)
            }
            .padding(.horizontal, 6)
            .padding(.top, 2)
            .padding(.bottom, 4)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .task(id: "\(edition.rawValue)-\(pageNumber)-\(quranStore.hasPageFonts)") {
            if let cached = quranStore.mushafPage(pageNumber: pageNumber, edition: edition) {
                loadedPage = cached
                prepared = MushafLayoutBuilder.prepare(page: cached, edition: edition, store: quranStore)
            } else if let fetched = await quranStore.loadMushafPageAsync(pageNumber: pageNumber, edition: edition) {
                loadedPage = fetched
                prepared = MushafLayoutBuilder.prepare(page: fetched, edition: edition, store: quranStore)
            }
        }
    }

    private var silkBookmarkRibbon: some View {
        Canvas { ctx, sz in
            var path = Path()
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: sz.width, y: 0))
            path.addLine(to: CGPoint(x: sz.width, y: sz.height))
            path.addLine(to: CGPoint(x: sz.width / 2, y: max(0, sz.height - 12)))
            path.addLine(to: CGPoint(x: 0, y: sz.height))
            path.closeSubpath()
            ctx.fill(path, with: .color(theme.primary))
            ctx.stroke(path, with: .color(Color(hex: 0xFFFFD54F).opacity(0.6)), lineWidth: 1)
        }
        .frame(width: 22, height: 52)
    }

    private func mushafHeaderRow(surahName: String, juzNumber: Int, isRightPage: Bool, ribbonInset: CGFloat) -> some View {
        let cleanSurah = surahName
            .replacingOccurrences(of: "سُورَةُ", with: "")
            .replacingOccurrences(of: "سورة", with: "")
            .trimmingCharacters(in: .whitespaces)
        let displaySurah = cleanSurah.isEmpty ? "" : "سورة \(cleanSurah)"
        let juzText = "الجزء \(DigitFormatter.localizeDigits(String(juzNumber), eastern: true, lang: "ar"))"
        let headerColor = accentColor.opacity(0.95)

        return HStack {
            if isRightPage {
                Text(juzText)
                Spacer()
                Text(displaySurah)
            } else {
                Text(displaySurah)
                Spacer()
                Text(juzText)
            }
        }
        .font(theme.amiriFont(size: 16, weight: .bold))
        .foregroundStyle(headerColor)
        .padding(.leading, 8 + (isRightPage ? 0 : ribbonInset))
        .padding(.trailing, 8 + (isRightPage ? ribbonInset : 0))
        .frame(minHeight: 30)
    }

    private func mushafFooterBadge(pageNumber: Int) -> some View {
        let pageText = DigitFormatter.localizeDigits(String(pageNumber), eastern: true, lang: "ar")
        return HStack {
            Spacer()
            Text(pageText)
                .font(.system(size: 12.5, weight: .bold))
                .foregroundStyle(inkColor.opacity(0.85))
                .padding(.horizontal, 14)
                .frame(height: 26)
                .background {
                    Canvas { ctx, sz in
                        let w = sz.width
                        let h = sz.height
                        let r = h / 2
                        let outer = Path(roundedRect: CGRect(x: 0.5, y: 0.5, width: w - 1, height: h - 1), cornerRadius: r)
                        ctx.fill(outer, with: .color(accentColor.opacity(0.08)))
                        ctx.stroke(outer, with: .color(accentColor.opacity(0.75)), lineWidth: 1)

                        let inset: CGFloat = 2.5
                        if w > inset * 2 && h > inset * 2 {
                            let inner = Path(roundedRect: CGRect(x: inset, y: inset, width: w - inset * 2, height: h - inset * 2), cornerRadius: (h - inset * 2) / 2)
                            ctx.stroke(inner, with: .color(accentColor.opacity(0.35)), lineWidth: 0.6)
                        }

                        var wings = Path()
                        wings.move(to: CGPoint(x: -7, y: h / 2)); wings.addLine(to: CGPoint(x: 0, y: h / 2))
                        wings.move(to: CGPoint(x: w, y: h / 2)); wings.addLine(to: CGPoint(x: w + 7, y: h / 2))
                        ctx.stroke(wings, with: .color(accentColor.opacity(0.7)), lineWidth: 0.8)
                        ctx.fill(Path(ellipseIn: CGRect(x: -8.2, y: h / 2 - 1.2, width: 2.4, height: 2.4)), with: .color(accentColor))
                        ctx.fill(Path(ellipseIn: CGRect(x: w + 5.8, y: h / 2 - 1.2, width: 2.4, height: 2.4)), with: .color(accentColor))
                    }
                }
            Spacer()
        }
        .frame(minHeight: 28)
    }
}
