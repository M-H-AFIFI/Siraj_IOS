import AVFoundation
import CoreGraphics
import CoreImage
import Foundation
import SirajCore
import UIKit

enum QuranVideoBackground: Equatable, @unchecked Sendable {
    case scene(VideoScene)
    case clip(VideoClip)
    case photo(UIImage)
}

enum QuranVideoStatus: Equatable {
    case idle
    case fetching(done: Int, total: Int)
    case rendering(progress: Double)
    case ready(url: URL, shape: VideoShape)
    case failed(String)

    var isWorking: Bool {
        switch self {
        case .fetching, .rendering: return true
        default: return false
        }
    }
}

final class QuranVideoRenderer {
    let width: Int
    let height: Int
    let script: VideoScript
    let background: QuranVideoBackground
    private let bgImage: CGImage?
    private let shape: VideoShape

    init(width: Int, height: Int, script: VideoScript, background: QuranVideoBackground) {
        self.width = width
        self.height = height
        self.script = script
        self.background = background
        if height > width { self.shape = .story }
        else if height == width { self.shape = .square }
        else { self.shape = .wide }

        switch background {
        case .scene:
            self.bgImage = nil
        case .clip(let clip):
            self.bgImage = UIImage(named: clip.previewImageAsset)?.cgImage
        case .photo(let img):
            self.bgImage = img.cgImage
        }
    }

    func draw(in ctx: CGContext, timeUs: Int64) {
        let w = CGFloat(width)
        let h = CGFloat(height)
        let short = min(w, h)
        let u = short / 1080.0
        let t = CGFloat(Double(timeUs) / 1_000_000.0)

        ctx.saveGState()

        // 1. Backdrop
        switch background {
        case .scene(.pattern):
            drawPatternBackdrop(ctx: ctx, w: w, h: h, u: u, t: t)
        case .scene(.plain):
            drawPlainBackdrop(ctx: ctx, w: w, h: h)
        case .clip, .photo:
            if let cg = bgImage {
                drawAspectFillImage(cg, in: CGRect(x: 0, y: 0, width: w, height: h), ctx: ctx)
            } else {
                drawPlainBackdrop(ctx: ctx, w: w, h: h)
            }
            drawPhotoVeil(ctx: ctx, w: w, h: h)
        }

        // 2. Header (Surah name + gold ornament rule + verse range)
        let titleTop = h * (shape == .wide ? 0.08 : 0.11)
        let titleSize = max(18, short * (shape == .wide ? 0.044 : 0.052))
        let smallSize = max(13, short * (shape == .wide ? 0.025 : 0.029))
        let accent = UIColor(red: 0.922, green: 0.831, blue: 0.620, alpha: 1.0)

        var bandTop = titleTop + short * 0.05
        if script.design.showSurahName && !script.labels.surahTitle.isEmpty {
            let titleFont = UIFont(name: "Amiri-Regular", size: titleSize) ?? UIFont.systemFont(ofSize: titleSize, weight: .bold)
            let titleH = drawCenteredText(
                script.labels.surahTitle,
                font: titleFont,
                color: UIColor.white.withAlphaComponent(0.96),
                y: titleTop,
                maxWidth: w * 0.86,
                in: ctx,
                canvasWidth: w
            )

            let ruleY = titleTop + titleH + titleSize * 0.28
            let half = titleSize * 2.1
            let gap = titleSize * 0.22
            let cx = w / 2
            ctx.saveGState()
            ctx.setStrokeColor(accent.withAlphaComponent(0.47).cgColor)
            ctx.setLineWidth(max(1.0, short * 0.0018))
            ctx.move(to: CGPoint(x: cx - half, y: ruleY))
            ctx.addLine(to: CGPoint(x: cx - gap * 1.6, y: ruleY))
            ctx.move(to: CGPoint(x: cx + gap * 1.6, y: ruleY))
            ctx.addLine(to: CGPoint(x: cx + half, y: ruleY))
            ctx.strokePath()

            ctx.setFillColor(accent.withAlphaComponent(0.68).cgColor)
            ctx.translateBy(x: cx, y: ruleY)
            ctx.rotate(by: .pi / 4)
            ctx.fill(CGRect(x: -gap * 0.45, y: -gap * 0.45, width: gap * 0.9, height: gap * 0.9))
            ctx.restoreGState()

            var rangeBottom = ruleY + titleSize * 0.3
            if !script.labels.rangeLabel.isEmpty {
                let rangeFont = UIFont.systemFont(ofSize: smallSize, weight: .medium)
                let rh = drawCenteredText(
                    script.labels.rangeLabel,
                    font: rangeFont,
                    color: UIColor.white.withAlphaComponent(0.72),
                    y: rangeBottom,
                    maxWidth: w * 0.84,
                    in: ctx,
                    canvasWidth: w
                )
                rangeBottom += rh
            }
            bandTop = rangeBottom + short * 0.04
        }

        // 3. Footer (Reciter line + Made with Siraj)
        let markCenterY = h * (shape == .wide ? 0.92 : 0.91)
        let reciterTop = markCenterY - smallSize * 2.1
        let bandBottom = (script.design.showReciter && !script.labels.reciterLine.isEmpty ? reciterTop : markCenterY) - short * 0.04

        if script.design.showReciter && !script.labels.reciterLine.isEmpty {
            let recFont = UIFont.systemFont(ofSize: smallSize, weight: .semibold)
            _ = drawCenteredText(
                script.labels.reciterLine,
                font: recFont,
                color: UIColor.white.withAlphaComponent(0.82),
                y: reciterTop,
                maxWidth: w * 0.86,
                in: ctx,
                canvasWidth: w
            )
        }

        if !script.labels.madeWith.isEmpty {
            let markFont = UIFont.systemFont(ofSize: smallSize * 0.90, weight: .bold)
            _ = drawCenteredText(
                script.labels.madeWith,
                font: markFont,
                color: accent.withAlphaComponent(0.86),
                y: markCenterY - smallSize * 0.5,
                maxWidth: w * 0.86,
                in: ctx,
                canvasWidth: w
            )
        }

        // 4. Active Verse + optional under-text
        if let active = activeVerse(at: timeUs) {
            let sinceStart = Double(timeUs - active.startUs) / 1_000_000.0
            let untilEnd = Double(active.endUs - timeUs) / 1_000_000.0
            let isFirst = active.startUs == script.verses.first?.startUs
            let isLast = active.endUs == script.verses.last?.endUs
            let fadeIn = isFirst ? 1.0 : smoothstep(sinceStart / 0.35)
            let fadeOut = isLast ? 1.0 : smoothstep(untilEnd / 0.25)
            let alpha = CGFloat(min(fadeIn, fadeOut))

            if alpha > 0.01 {
                let scale = CGFloat(script.design.textSize.scale)
                let ayahSize = max(20, short * (shape == .wide ? 0.056 : 0.064) * scale)
                let underSize = max(14, short * (shape == .wide ? 0.028 : 0.032) * scale)
                let quranFont = UIFont(name: "DigitalKhattOldMadinaRegular", size: ayahSize)
                    ?? UIFont(name: "Amiri-Regular", size: ayahSize)
                    ?? UIFont.systemFont(ofSize: ayahSize)
                let underFont = script.labels.underIsRtl
                    ? (UIFont(name: "Amiri-Regular", size: underSize * 1.1) ?? UIFont.systemFont(ofSize: underSize))
                    : UIFont.systemFont(ofSize: underSize, weight: .regular)

                let verseDisplay: String = {
                    let clean = DigitalKhattText.forDisplay(active.text)
                    if active.number > 0 {
                        let digits = DigitFormatter.localizeDigits(String(active.number), eastern: true, lang: "ar")
                        return "\(clean) \u{06DD}\(digits)"
                    }
                    return clean
                }()

                let maxW = w * 0.86
                let verseH = measureTextHeight(verseDisplay, font: quranFont, maxWidth: maxW, lineSpacing: ayahSize * 0.32)
                let underH: CGFloat
                let gap: CGFloat
                if let under = active.under, !under.isEmpty {
                    underH = measureTextHeight(under, font: underFont, maxWidth: w * 0.82, lineSpacing: underSize * 0.28)
                    gap = ayahSize * 0.45
                } else {
                    underH = 0
                    gap = 0
                }

                let totalH = verseH + gap + underH
                let centerY = (bandTop + bandBottom) / 2
                let rise = CGFloat(1.0 - fadeIn) * short * 0.014
                let top = max(bandTop, min(bandBottom - totalH, centerY - totalH / 2)) + rise

                _ = drawCenteredText(
                    verseDisplay,
                    font: quranFont,
                    color: UIColor(red: 1.0, green: 0.988, blue: 0.957, alpha: alpha),
                    y: top,
                    maxWidth: maxW,
                    lineSpacing: ayahSize * 0.32,
                    isRTL: true,
                    in: ctx,
                    canvasWidth: w
                )

                if let under = active.under, !under.isEmpty {
                    _ = drawCenteredText(
                        under,
                        font: underFont,
                        color: UIColor.white.withAlphaComponent(0.88 * alpha),
                        y: top + verseH + gap,
                        maxWidth: w * 0.82,
                        lineSpacing: underSize * 0.28,
                        isRTL: script.labels.underIsRtl,
                        in: ctx,
                        canvasWidth: w
                    )
                }
            }
        }

        ctx.restoreGState()
    }

    private func activeVerse(at timeUs: Int64) -> VideoVerse? {
        guard !script.verses.isEmpty else { return nil }
        for v in script.verses where timeUs >= v.startUs && timeUs <= v.endUs {
            return v
        }
        return script.verses.last
    }

    private func drawPatternBackdrop(ctx: CGContext, w: CGFloat, h: CGFloat, u: CGFloat, t: CGFloat) {
        let cs = CGColorSpaceCreateDeviceRGB()
        let colors = [
            UIColor(red: 0.071, green: 0.278, blue: 0.224, alpha: 1).cgColor,
            UIColor(red: 0.043, green: 0.173, blue: 0.145, alpha: 1).cgColor,
            UIColor(red: 0.016, green: 0.075, blue: 0.059, alpha: 1).cgColor
        ] as CFArray
        let locs: [CGFloat] = [0, 0.55, 1]
        if let grad = CGGradient(colorsSpace: cs, colors: colors, locations: locs) {
            let center = CGPoint(x: w * 0.5, y: h * 0.46)
            let radius = hypot(w, h) * 0.62
            ctx.drawRadialGradient(grad, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: .drawsAfterEndLocation)
        }

        ctx.saveGState()
        ctx.translateBy(x: w * 0.5, y: h * 0.46)
        ctx.rotate(by: t * 0.016)
        let breathe = 1.0 + 0.02 * sin(t * 0.35)
        ctx.scaleBy(x: breathe, y: breathe)
        ctx.setStrokeColor(UIColor(red: 0.831, green: 0.698, blue: 0.416, alpha: 0.21).cgColor)
        ctx.setLineWidth(max(1.0, 1.6 * u))

        let cell = 190 * u
        let reach = hypot(w, h) * 0.6 + cell
        var gy = -reach
        while gy <= reach {
            var gx = -reach
            while gx <= reach {
                strokeStar(ctx: ctx, cx: gx, cy: gy, r: cell * 0.5)
                gx += cell
            }
            gy += cell
        }
        ctx.strokePath()
        ctx.restoreGState()

        // Vignette edge shadow
        let vColors = [
            UIColor.clear.cgColor,
            UIColor.clear.cgColor,
            UIColor(red: 0.008, green: 0.039, blue: 0.031, alpha: 0.70).cgColor
        ] as CFArray
        if let vGrad = CGGradient(colorsSpace: cs, colors: vColors, locations: [0, 0.45, 1]) {
            let center = CGPoint(x: w * 0.5, y: h * 0.46)
            ctx.drawRadialGradient(vGrad, startCenter: center, startRadius: 0, endCenter: center, endRadius: hypot(w, h) * 0.6, options: .drawsAfterEndLocation)
        }
    }

    private func strokeStar(ctx: CGContext, cx: CGFloat, cy: CGFloat, r: CGFloat) {
        let inner = r * 0.62
        for turn in 0...1 {
            let a0 = CGFloat(turn) * .pi / 4
            for i in 0...4 {
                let a = a0 + CGFloat(i) * .pi / 2
                let pt = CGPoint(x: cx + cos(a) * inner, y: cy + sin(a) * inner)
                if i == 0 { ctx.move(to: pt) } else { ctx.addLine(to: pt) }
            }
        }
        for i in 0..<4 {
            let a = CGFloat(i) * .pi / 2
            ctx.move(to: CGPoint(x: cx + cos(a) * inner, y: cy + sin(a) * inner))
            ctx.addLine(to: CGPoint(x: cx + cos(a) * r, y: cy + sin(a) * r))
        }
    }

    private func drawPlainBackdrop(ctx: CGContext, w: CGFloat, h: CGFloat) {
        let cs = CGColorSpaceCreateDeviceRGB()
        let colors = [
            UIColor(red: 0.102, green: 0.102, blue: 0.125, alpha: 1).cgColor,
            UIColor(red: 0.055, green: 0.055, blue: 0.071, alpha: 1).cgColor,
            UIColor(red: 0.024, green: 0.024, blue: 0.031, alpha: 1).cgColor
        ] as CFArray
        if let grad = CGGradient(colorsSpace: cs, colors: colors, locations: [0, 0.5, 1]) {
            let center = CGPoint(x: w * 0.5, y: h * 0.45)
            ctx.drawRadialGradient(grad, startCenter: center, startRadius: 0, endCenter: center, endRadius: hypot(w, h) * 0.6, options: .drawsAfterEndLocation)
        }
    }

    private func drawAspectFillImage(_ image: CGImage, in rect: CGRect, ctx: CGContext) {
        let iw = CGFloat(image.width)
        let ih = CGFloat(image.height)
        guard iw > 0, ih > 0 else { return }
        let scale = max(rect.width / iw, rect.height / ih)
        let dw = iw * scale
        let dh = ih * scale
        let drawRect = CGRect(x: rect.midX - dw / 2, y: rect.midY - dh / 2, width: dw, height: dh)
        // Flip locally so CGContextDrawImage draws upright in UIKit top-left coordinates.
        ctx.saveGState()
        ctx.clip(to: rect)
        ctx.translateBy(x: 0, y: rect.height)
        ctx.scaleBy(x: 1, y: -1)
        let flippedRect = CGRect(x: drawRect.minX, y: rect.height - drawRect.maxY, width: drawRect.width, height: drawRect.height)
        ctx.draw(image, in: flippedRect)
        ctx.restoreGState()
    }

    private func drawPhotoVeil(ctx: CGContext, w: CGFloat, h: CGFloat) {
        ctx.setFillColor(UIColor.black.withAlphaComponent(0.36).cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        let cs = CGColorSpaceCreateDeviceRGB()
        let colors = [
            UIColor.black.withAlphaComponent(0.42).cgColor,
            UIColor.clear.cgColor,
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.55).cgColor
        ] as CFArray
        if let grad = CGGradient(colorsSpace: cs, colors: colors, locations: [0, 0.25, 0.72, 1]) {
            ctx.drawLinearGradient(grad, start: .zero, end: CGPoint(x: 0, y: h), options: [])
        }
    }

    private func textAttributes(font: UIFont, color: UIColor, lineSpacing: CGFloat, isRTL: Bool) -> [NSAttributedString.Key: Any] {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        style.lineSpacing = lineSpacing
        style.lineBreakMode = .byWordWrapping
        style.baseWritingDirection = isRTL ? .rightToLeft : .natural
        return [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: style
        ]
    }

    private func measureTextHeight(_ text: String, font: UIFont, maxWidth: CGFloat, lineSpacing: CGFloat = 4) -> CGFloat {
        let attr = NSAttributedString(string: text, attributes: textAttributes(font: font, color: .white, lineSpacing: lineSpacing, isRTL: false))
        let bounds = attr.boundingRect(with: CGSize(width: maxWidth, height: 10_000), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return ceil(bounds.height)
    }

    @discardableResult
    private func drawCenteredText(
        _ text: String,
        font: UIFont,
        color: UIColor,
        y: CGFloat,
        maxWidth: CGFloat,
        lineSpacing: CGFloat = 4,
        isRTL: Bool = false,
        in ctx: CGContext,
        canvasWidth: CGFloat
    ) -> CGFloat {
        let attr = NSAttributedString(string: text, attributes: textAttributes(font: font, color: color, lineSpacing: lineSpacing, isRTL: isRTL))
        let bounds = attr.boundingRect(with: CGSize(width: maxWidth, height: 10_000), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        let rect = CGRect(x: (canvasWidth - maxWidth) / 2, y: y, width: maxWidth, height: ceil(bounds.height) + 4)
        UIGraphicsPushContext(ctx)
        attr.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        UIGraphicsPopContext()
        return ceil(bounds.height)
    }

    private func smoothstep(_ x: Double) -> Double {
        let t = min(1.0, max(0.0, x))
        return t * t * (3.0 - 2.0 * t)
    }
}

enum QuranVideoExportPipeline {
    static func exportVideo(
        parts: [VersePart],
        reciterId: String,
        underTexts: [Int: String],
        labels: VideoLabels,
        design: VideoDesign,
        background: QuranVideoBackground,
        shape: VideoShape,
        quality: VideoQuality,
        onProgress: @escaping @Sendable (QuranVideoStatus) -> Void
    ) async throws -> URL {
        let fm = FileManager.default
        let cacheDir = fm.temporaryDirectory.appendingPathComponent("siraj-video-work-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: cacheDir) }

        // 1. Download recitation MP3 per verse part & measure exact durations
        var audioURLs: [URL] = []
        var verses: [VideoVerse] = []
        var cursorUs: Int64 = 0

        for (idx, part) in parts.enumerated() {
            try Task.checkCancellation()
            onProgress(.fetching(done: idx, total: parts.count))
            let remoteStr = ReciterAudioURLs.ayahAudioURL(reciterId: reciterId, surah: part.surah, ayah: part.ayah)
            guard let remoteURL = URL(string: remoteStr) else { continue }
            let localMP3 = cacheDir.appendingPathComponent("part_\(idx).mp3")
            let (tmp, resp) = try await URLSession.shared.download(from: remoteURL)
            if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                throw NSError(domain: "SirajVideo", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Audio fetch failed"])
            }
            if fm.fileExists(atPath: localMP3.path) { try? fm.removeItem(at: localMP3) }
            try fm.moveItem(at: tmp, to: localMP3)
            audioURLs.append(localMP3)

            let asset = AVURLAsset(url: localMP3)
            let cmDur = try await asset.load(.duration)
            let durSec = cmDur.seconds.isFinite && cmDur.seconds > 0.2 ? cmDur.seconds : 3.0
            let durUs = Int64(durSec * 1_000_000.0)
            verses.append(VideoVerse(
                startUs: cursorUs,
                endUs: cursorUs + durUs,
                text: part.text,
                number: part.number,
                under: part.number > 0 ? underTexts[part.global] : nil
            ))
            cursorUs += durUs
        }

        onProgress(.fetching(done: parts.count, total: parts.count))
        guard !verses.isEmpty, cursorUs > 0 else {
            throw NSError(domain: "SirajVideo", code: -1, userInfo: [NSLocalizedDescriptionKey: "No verses available"])
        }

        let script = VideoScript(verses: verses, labels: labels, design: design, durationUs: cursorUs)
        let dims = shape.pixelSize(quality: quality)
        let renderer = QuranVideoRenderer(width: dims.width, height: dims.height, script: script, background: background)

        // 2. Render video-only H.264 file via AVAssetWriter
        let videoOnlyURL = cacheDir.appendingPathComponent("video_only.mp4")
        let writer = try AVAssetWriter(outputURL: videoOnlyURL, fileType: .mp4)
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: dims.width,
            AVVideoHeightKey: dims.height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: quality == .fullHd ? 6_000_000 : 3_200_000
            ]
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        input.expectsMediaDataInRealTime = false

        let pixelAttrs: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
            kCVPixelBufferWidthKey as String: dims.width,
            kCVPixelBufferHeightKey as String: dims.height
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: pixelAttrs)
        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        let fps = 24
        let totalSeconds = Double(cursorUs) / 1_000_000.0
        let totalFrames = max(1, Int(ceil(totalSeconds * Double(fps))))
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        for frameIndex in 0..<totalFrames {
            try Task.checkCancellation()
            while !input.isReadyForMoreMediaData {
                try await Task.sleep(for: .milliseconds(8))
            }
            guard let pool = adaptor.pixelBufferPool else { break }
            var pbOut: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pbOut)
            guard let pb = pbOut else { continue }

            CVPixelBufferLockBaseAddress(pb, [])
            if let base = CVPixelBufferGetBaseAddress(pb),
               let ctx = CGContext(
                data: base,
                width: dims.width,
                height: dims.height,
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(pb),
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
               ) {
                // Flip CoreGraphics coordinate space so top-left is (0,0) matching UIKit drawing.
                ctx.translateBy(x: 0, y: CGFloat(dims.height))
                ctx.scaleBy(x: 1, y: -1)
                let timeUs = Int64(Double(frameIndex) / Double(fps) * 1_000_000.0)
                renderer.draw(in: ctx, timeUs: timeUs)
            }
            CVPixelBufferUnlockBaseAddress(pb, [])

            let pts = CMTime(value: CMTimeValue(frameIndex), timescale: CMTimeScale(fps))
            adaptor.append(pb, withPresentationTime: pts)

            if frameIndex % 6 == 0 || frameIndex == totalFrames - 1 {
                onProgress(.rendering(progress: Double(frameIndex + 1) / Double(totalFrames) * 0.85))
            }
        }

        input.markAsFinished()
        await withCheckedContinuation { cont in
            writer.finishWriting { cont.resume() }
        }
        guard writer.status == .completed else {
            throw writer.error ?? NSError(domain: "SirajVideo", code: -2)
        }

        // 3. Mux rendered video with concatenated recitation MP3 audio
        let composition = AVMutableComposition()
        let vAsset = AVURLAsset(url: videoOnlyURL)
        if let vTrack = try await vAsset.loadTracks(withMediaType: .video).first,
           let compV = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) {
            let vDur = try await vAsset.load(.duration)
            try compV.insertTimeRange(CMTimeRange(start: .zero, duration: vDur), of: vTrack, at: .zero)
        }

        if let compA = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            var audioCursor = CMTime.zero
            for mp3URL in audioURLs {
                let aAsset = AVURLAsset(url: mp3URL)
                if let aTrack = try await aAsset.loadTracks(withMediaType: .audio).first {
                    let aDur = try await aAsset.load(.duration)
                    try? compA.insertTimeRange(CMTimeRange(start: .zero, duration: aDur), of: aTrack, at: audioCursor)
                    audioCursor = CMTimeAdd(audioCursor, aDur)
                }
            }
        }

        let finalURL = fm.temporaryDirectory.appendingPathComponent("Siraj-Quran-\(Int(Date().timeIntervalSince1970)).mp4")
        if fm.fileExists(atPath: finalURL.path) { try? fm.removeItem(at: finalURL) }

        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw NSError(domain: "SirajVideo", code: -3)
        }
        exporter.outputURL = finalURL
        exporter.outputFileType = .mp4
        exporter.shouldOptimizeForNetworkUse = true

        await exporter.export()
        guard exporter.status == .completed else {
            throw exporter.error ?? NSError(domain: "SirajVideo", code: -4)
        }
        onProgress(.rendering(progress: 1.0))
        return finalURL
    }
}
