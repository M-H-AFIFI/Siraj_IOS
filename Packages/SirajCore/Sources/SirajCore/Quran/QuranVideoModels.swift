import Foundation

public enum VideoShape: String, CaseIterable, Codable, Sendable, Identifiable {
    case story
    case square
    case wide

    public var id: String { rawValue }

    public var ratioW: Int {
        switch self {
        case .story: return 9
        case .square: return 1
        case .wide: return 16
        }
    }

    public var ratioH: Int {
        switch self {
        case .story: return 16
        case .square: return 1
        case .wide: return 9
        }
    }

    public var aspect: Double { Double(ratioW) / Double(ratioH) }

    public func pixelSize(quality: VideoQuality) -> (width: Int, height: Int) {
        let short = quality.shortSide
        let long = short * 16 / 9
        switch self {
        case .story: return (short, long)
        case .square: return (short, short)
        case .wide: return (long, short)
        }
    }
}

public enum VideoQuality: String, CaseIterable, Codable, Sendable, Identifiable {
    case hd
    case fullHd

    public var id: String { rawValue }

    public var shortSide: Int {
        switch self {
        case .hd: return 720
        case .fullHd: return 1080
        }
    }
}

public enum VideoScene: String, CaseIterable, Codable, Sendable, Identifiable {
    case pattern
    case plain

    public var id: String { rawValue }
}

public enum VideoClip: String, CaseIterable, Codable, Sendable, Identifiable {
    case stars
    case sunset
    case clouds
    case horizon
    case sea
    case rain
    case forest
    case waterfall
    case dunes

    public var id: String { rawValue }

    public var bytes: Int64 {
        switch self {
        case .stars: return 2_114_707
        case .sunset: return 1_191_224
        case .clouds: return 3_584_277
        case .horizon: return 2_861_884
        case .sea: return 7_827_152
        case .rain: return 6_300_914
        case .forest: return 7_627_606
        case .waterfall: return 7_815_645
        case .dunes: return 1_529_241
        }
    }

    public var fileName: String { "\(rawValue).mp4" }
    public var assetPath: String { "video/backgrounds/v1/\(fileName)" }
    public var cdnURL: String { SirajAssetURLs.cdn(assetPath).absoluteString }
    public var rawURL: String { SirajAssetURLs.raw(assetPath).absoluteString }
    public var previewImageAsset: String { "quran_video_bg_\(rawValue)" }
    public var labelKey: String { "quran_video_clip_\(rawValue)" }
}

public enum VideoUnderText: String, CaseIterable, Codable, Sendable, Identifiable {
    case none
    case meaning
    case tafsir

    public var id: String { rawValue }
}

public enum VideoTextSize: String, CaseIterable, Codable, Sendable, Identifiable {
    case small
    case medium
    case large

    public var id: String { rawValue }

    public var scale: Double {
        switch self {
        case .small: return 0.86
        case .medium: return 1.0
        case .large: return 1.14
        }
    }
}

public struct VideoDesign: Codable, Sendable, Equatable {
    public var showSurahName: Bool
    public var showReciter: Bool
    public var under: VideoUnderText
    public var textSize: VideoTextSize

    public init(
        showSurahName: Bool = true,
        showReciter: Bool = true,
        under: VideoUnderText = .none,
        textSize: VideoTextSize = .medium
    ) {
        self.showSurahName = showSurahName
        self.showReciter = showReciter
        self.under = under
        self.textSize = textSize
    }
}

public struct VideoVerse: Sendable, Equatable {
    public let startUs: Int64
    public let endUs: Int64
    public let text: String
    public let number: Int
    public let under: String?

    public init(startUs: Int64, endUs: Int64, text: String, number: Int, under: String? = nil) {
        self.startUs = startUs
        self.endUs = endUs
        self.text = text
        self.number = number
        self.under = under
    }
}

public struct VideoLabels: Sendable, Equatable {
    public let surahTitle: String
    public let rangeLabel: String
    public let reciterLine: String
    public let madeWith: String
    public let underIsRtl: Bool

    public init(surahTitle: String, rangeLabel: String, reciterLine: String, madeWith: String, underIsRtl: Bool) {
        self.surahTitle = surahTitle
        self.rangeLabel = rangeLabel
        self.reciterLine = reciterLine
        self.madeWith = madeWith
        self.underIsRtl = underIsRtl
    }
}

public struct VideoScript: Sendable, Equatable {
    public let verses: [VideoVerse]
    public let labels: VideoLabels
    public let design: VideoDesign
    public let durationUs: Int64

    public init(verses: [VideoVerse], labels: VideoLabels, design: VideoDesign, durationUs: Int64) {
        self.verses = verses
        self.labels = labels
        self.design = design
        self.durationUs = durationUs
    }
}

public struct VersePart: Sendable, Equatable {
    public let surah: Int
    public let ayah: Int
    public let global: Int
    public let text: String
    public let number: Int

    public init(surah: Int, ayah: Int, global: Int, text: String, number: Int) {
        self.surah = surah
        self.ayah = ayah
        self.global = global
        self.text = text
        self.number = number
    }
}

public enum QuranVideoPlanner {
    public static let maxVerses = 15

    public static func recitationParts(
        surah: Int,
        from: Int,
        to: Int,
        ayahs: [Ayah],
        opening: Ayah?
    ) -> [VersePart] {
        var parts: [VersePart] = []
        let includeBasmala = from == 1 && surah != 1 && surah != 9 && opening != nil
        if includeBasmala, let opening {
            parts.append(VersePart(
                surah: 1,
                ayah: 1,
                global: opening.number,
                text: opening.textUthmani.trimmingCharacters(in: .whitespacesAndNewlines),
                number: 0
            ))
        }
        let filtered = ayahs
            .filter { $0.numberInSurah >= from && $0.numberInSurah <= to }
            .sorted { $0.numberInSurah < $1.numberInSurah }
        for a in filtered {
            parts.append(VersePart(
                surah: a.surahNumber,
                ayah: a.numberInSurah,
                global: a.number,
                text: a.textUthmani.trimmingCharacters(in: .whitespacesAndNewlines),
                number: a.numberInSurah
            ))
        }
        if includeBasmala && parts.count > 1 {
            let basmalaText = parts[0].text
            let first = parts[1]
            if !basmalaText.isEmpty && first.text.hasPrefix(basmalaText) {
                let stripped = String(first.text.dropFirst(basmalaText.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                parts[1] = VersePart(surah: first.surah, ayah: first.ayah, global: first.global, text: stripped, number: first.number)
            }
        }
        return parts
    }
}
