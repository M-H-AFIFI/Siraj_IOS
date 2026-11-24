import Foundation

public enum QuranTables {
    public static let madinahTotalPages = 604
    public static let indopakTotalPages = 610
    public static let shamarlyTotalPages = 521

    public static let madinahJuzStartPages: [Int] = [
        0, 1, 22, 42, 62, 82, 102, 122, 142, 162, 182,
        202, 222, 242, 262, 282, 302, 322, 342, 362, 382,
        402, 422, 442, 462, 482, 502, 522, 542, 562, 582
    ]

    public static let madinahSurahStartPages: [Int] = [
        0, 1, 2, 50, 77, 106, 128, 151, 177, 187, 208, 221, 235, 249, 255, 262, 267, 282, 293, 305, 312,
        322, 332, 342, 350, 359, 367, 377, 385, 396, 404, 411, 415, 418, 428, 434, 440, 446, 453, 458, 467,
        477, 483, 489, 496, 499, 502, 507, 511, 515, 518, 520, 523, 526, 528, 531, 534, 537, 542, 545, 549,
        551, 553, 554, 556, 558, 560, 562, 564, 566, 568, 570, 572, 574, 575, 577, 578, 580, 582, 583, 585,
        586, 587, 587, 589, 590, 591, 591, 592, 593, 594, 595, 595, 596, 596, 597, 597, 598, 598, 599, 599,
        600, 600, 601, 601, 601, 602, 602, 602, 603, 603, 603, 604, 604, 604
    ]

    public static let madinahHizbStartPages: [Int] = [
        0,
        1, 11, 22, 32, 42, 51, 62, 72, 82, 92,
        102, 112, 121, 132, 142, 151, 162, 172, 182, 192,
        201, 212, 222, 231, 242, 252, 262, 272, 282, 292,
        302, 312, 322, 332, 342, 352, 362, 371, 382, 392,
        402, 411, 422, 431, 442, 451, 462, 472, 482, 491,
        502, 513, 522, 531, 542, 553, 562, 571, 582, 591
    ]

    public static let shamarlyJuzStartPages: [Int] = [
        0, 1, 19, 35, 51, 67, 83, 98, 115, 131, 147, 163, 180, 198, 215, 232, 249, 267, 283, 301,
        319, 335, 352, 369, 387, 403, 422, 439, 458, 477, 497
    ]

    public static let shamarlySurahStartPages: [Int] = [
        0, 1, 2, 41, 63, 86, 104, 122, 144, 152, 168, 180, 192, 204, 209, 215, 220, 232, 242, 252,
        259, 267, 275, 283, 290, 299, 305, 314, 322, 331, 337, 343, 346, 349, 357, 363, 368, 373,
        379, 384, 391, 399, 404, 410, 416, 418, 422, 426, 429, 433, 436, 438, 441, 443, 446, 448,
        451, 454, 458, 461, 464, 467, 468, 470, 471, 473, 475, 477, 479, 481, 483, 485, 487, 489,
        490, 492, 494, 496, 497, 499, 500, 501, 502, 503, 504, 505, 506, 507, 508, 509, 510, 511,
        511, 512, 513, 513, 513, 514, 515, 515, 516, 516, 517, 517, 518, 518, 519, 519, 519, 520,
        520, 520, 521, 521, 521
    ]

    public static let shamarlyHizbStartPages: [Int] = [
        0, 1, 11, 19, 27, 35, 43, 51, 59, 67, 75, 83, 91, 98, 107, 115, 122, 131, 140, 147, 156,
        163, 171, 180, 188, 198, 206, 215, 224, 232, 241, 249, 259, 267, 275, 283, 292, 301, 309,
        319, 327, 335, 344, 352, 360, 369, 378, 387, 395, 403, 411, 422, 431, 439, 448, 458, 468,
        477, 487, 497, 507
    ]

    public static let indopakSurahStartPages: [Int] = [
        0, 1, 2, 50, 77, 106, 128, 151, 177, 187, 208, 221, 235, 249, 255, 261, 267, 282, 293, 305,
        312, 322, 331, 342, 350, 359, 366, 376, 385, 396, 404, 411, 415, 418, 428, 434, 440, 445,
        452, 458, 467, 477, 483, 489, 495, 498, 502, 506, 511, 515, 518, 520, 523, 526, 528, 531,
        534, 537, 542, 545, 549, 551, 553, 554, 556, 558, 560, 562, 564, 567, 569, 571, 573, 576,
        578, 580, 582, 584, 586, 587, 589, 590, 591, 592, 594, 595, 596, 597, 597, 598, 600, 600,
        601, 602, 602, 603, 603, 604, 604, 605, 605, 606, 606, 607, 607, 607, 608, 608, 608, 608,
        609, 609, 609, 610, 610
    ]

    public static let indopakJuzStartPages: [Int] = [
        0, 1, 22, 42, 62, 82, 102, 121, 142, 162, 182, 201, 222, 242, 261, 282, 302, 322, 342, 362,
        381, 402, 422, 442, 462, 482, 502, 522, 542, 562, 586
    ]

    public static let indopakHizbStartPages: [Int] = [
        0, 1, 11, 22, 31, 42, 51, 62, 72, 82, 92, 102, 112, 121, 132, 142, 151, 162, 173, 182, 192,
        201, 212, 222, 231, 242, 252, 261, 272, 282, 291, 302, 312, 322, 331, 342, 352, 362, 371,
        381, 392, 402, 413, 422, 431, 442, 451, 462, 472, 482, 491, 502, 513, 522, 531, 542, 553,
        562, 573, 586, 597
    ]

    public static func surahStartPages(edition: MushafEdition) -> [Int] {
        switch edition {
        case .madinah: return madinahSurahStartPages
        case .indopak: return indopakSurahStartPages
        case .shamarly: return shamarlySurahStartPages
        }
    }

    public static func juzStartPages(edition: MushafEdition) -> [Int] {
        switch edition {
        case .madinah: return madinahJuzStartPages
        case .indopak: return indopakJuzStartPages
        case .shamarly: return shamarlyJuzStartPages
        }
    }

    public static func hizbStartPages(edition: MushafEdition) -> [Int] {
        switch edition {
        case .madinah: return madinahHizbStartPages
        case .indopak: return indopakHizbStartPages
        case .shamarly: return shamarlyHizbStartPages
        }
    }

    public static func pageForSurah(_ surah: Int, edition: MushafEdition = .madinah) -> Int {
        let table = surahStartPages(edition: edition)
        guard surah >= 1, surah < table.count else { return 1 }
        return table[surah]
    }

    public static func pageForJuz(_ juz: Int, edition: MushafEdition = .madinah) -> Int {
        let table = juzStartPages(edition: edition)
        guard juz >= 1, juz < table.count else { return 1 }
        return table[juz]
    }

    public static func pageForHizb(_ hizb: Int, edition: MushafEdition = .madinah) -> Int {
        let table = hizbStartPages(edition: edition)
        guard hizb >= 1, hizb < table.count else { return 1 }
        return table[hizb]
    }

    public static func juzForPage(_ page: Int, edition: MushafEdition = .madinah) -> Int {
        let starts = juzStartPages(edition: edition)
        for i in stride(from: 30, through: 1, by: -1) {
            if page >= starts[i] { return i }
        }
        return 1
    }

    public static func surahForPage(_ page: Int, edition: MushafEdition = .madinah) -> Int {
        let starts = surahStartPages(edition: edition)
        for i in stride(from: 114, through: 1, by: -1) {
            if page >= starts[i] { return i }
        }
        return 1
    }

    public static func isIndopakAyahEndMarker(_ text: String) -> Bool {
        var hasPrivateUse = false
        for scalar in text.unicodeScalars {
            if scalar.properties.generalCategory == .otherLetter { return false }
            if scalar.value >= 0xE000 && scalar.value <= 0xF8FF { hasPrivateUse = true }
        }
        return hasPrivateUse
    }

    public static func isIndopakMedallionPiece(_ piece: String, isLast: Bool) -> Bool {
        isIndopakAyahEndMarker(piece) && (isLast || piece.unicodeScalars.first?.value == 0x06DF)
    }

    public static func splitIndopakAyahEnd(_ text: String) -> (body: String, marker: String?) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let spaceIdx = trimmed.lastIndex(of: " ") {
            let tail = String(trimmed[trimmed.index(after: spaceIdx)...])
            if isIndopakAyahEndMarker(tail) {
                let body = String(trimmed[..<spaceIdx]).trimmingCharacters(in: .whitespaces)
                return (body, tail)
            }
        } else if isIndopakAyahEndMarker(trimmed) {
            return ("", trimmed)
        }
        return (trimmed, nil)
    }

    public static func attachIndopakPauseMarks(_ text: String) -> String {
        let pieces = text.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
        var out = ""
        out.reserveCapacity(text.count)
        for (index, piece) in pieces.enumerated() {
            if index > 0 {
                let isPauseSign = !piece.isEmpty
                    && !piece.unicodeScalars.contains(where: { $0.properties.generalCategory == .otherLetter })
                    && !isIndopakMedallionPiece(piece, isLast: index == pieces.count - 1)
                if !isPauseSign {
                    out.append(" ")
                }
            }
            out.append(piece)
        }
        return out
    }

    public static func sanitizeDisplayText(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        return text
            .replacingOccurrences(of: "\u{0645}\u{064E}\u{062C}\u{06E1}\u{0631}\u{065C}\u{0649}\u{0670}\u{0647}\u{064E}\u{0627}", with: "مَجْرَاهَا")
            .replacingOccurrences(of: "\u{0645}\u{064E}\u{062C}\u{0652}\u{0631}\u{06EA}\u{0649}\u{0670}\u{0647}\u{064E}\u{0627}", with: "مَجْرَاهَا")
            .replacingOccurrences(of: "\u{0645}\u{064E}\u{062C}\u{06E1}\u{0631}\u{06EA}\u{0649}\u{0670}\u{0647}\u{064E}\u{0627}", with: "مَجْرَاهَا")
            .replacingOccurrences(of: "مَجْر۪ىٰهَا", with: "مَجْرَاهَا")
            .replacingOccurrences(of: "مَجۡرٜىٰهَا", with: "مَجْرَاهَا")
            .replacingOccurrences(of: "مَجۡر۪ىٰهَا", with: "مَجْرَاهَا")
            .replacingOccurrences(of: "\u{25CC}", with: "")
            .replacingOccurrences(of: "\u{065C}", with: "")
            .replacingOccurrences(of: "\u{06EA}", with: "")
            .replacingOccurrences(of: "\u{06EB}", with: "")
    }
}

public enum ArabicSearchText {
    public static let minQueryLength = 2

    public static func isDropped(_ scalar: UnicodeScalar) -> Bool {
        let v = scalar.value
        if v == 0x0640 || v == 0x0621 || v == 0x0670 { return true }
        if v >= 0x064B && v <= 0x065F { return true }
        if v >= 0x06D6 && v <= 0x06ED { return true }
        if v == 0x08F0 || v == 0x08F1 || v == 0x08F2 { return true }
        if v == 0x200B || v == 0x200C || v == 0x200D || v == 0x200E || v == 0x200F { return true }
        return false
    }

    public static func fold(_ scalar: UnicodeScalar) -> Character {
        switch scalar.value {
        case 0x0622, 0x0623, 0x0625, 0x0671, 0x0672, 0x0673: return "ا"
        case 0x0649, 0x0626, 0x06CC: return "ي"
        case 0x0624: return "و"
        case 0x0629, 0x06BE: return "ه"
        case 0x06A9, 0x06AA: return "ك"
        default:
            return Character(String(scalar).lowercased())
        }
    }

    public static func normalize(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        var out = ""
        out.reserveCapacity(text.count)
        for scalar in text.unicodeScalars {
            if isDropped(scalar) { continue }
            out.append(fold(scalar))
        }
        return out
    }

    public static func normalizeQuery(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        let folded = normalize(trimmed)
        var out = ""
        out.reserveCapacity(folded.count)
        var lastSpace = false
        for ch in folded {
            if ch.isWhitespace {
                if !lastSpace && !out.isEmpty { out.append(" ") }
                lastSpace = true
            } else {
                out.append(ch)
                lastSpace = false
            }
        }
        return out.trimmingCharacters(in: .whitespaces)
    }

    public static func matchRanges(in displayText: String, normalizedQuery: String, limit: Int = 8) -> [Range<String.Index>] {
        guard !displayText.isEmpty, !normalizedQuery.isEmpty, limit > 0 else { return [] }
        let scalars = displayText.unicodeScalars
        var foldedChars: [Character] = []
        var sourceIndices: [String.Index] = []
        foldedChars.reserveCapacity(scalars.count)
        sourceIndices.reserveCapacity(scalars.count + 1)

        var idx = scalars.startIndex
        while idx < scalars.endIndex {
            let s = scalars[idx]
            if !isDropped(s) {
                sourceIndices.append(idx)
                foldedChars.append(fold(s))
            }
            idx = scalars.index(after: idx)
        }
        sourceIndices.append(displayText.endIndex)

        let haystack = String(foldedChars)
        var hits: [Range<String.Index>] = []
        var searchStart = haystack.startIndex
        while hits.count < limit, let range = haystack.range(of: normalizedQuery, range: searchStart..<haystack.endIndex) {
            let startOffset = haystack.distance(from: haystack.startIndex, to: range.lowerBound)
            let endOffset = haystack.distance(from: haystack.startIndex, to: range.upperBound)
            if startOffset < sourceIndices.count && endOffset < sourceIndices.count {
                hits.append(sourceIndices[startOffset]..<sourceIndices[endOffset])
            }
            searchStart = range.upperBound
        }
        return hits
    }
}

public enum SurahNames {
    private static let oldConventionChars = CharacterSet(charactersIn: "ĥĤşŞţŢđĐ`'á‘’")
    private static let surahWords: Set<String> = ["surah", "sura", "surat", "sure", "suresi", "سوره", "سورت", "سورۃ"]
    private static let notLetters: Set<Character> = ["ـ", "ʾ", "ʿ"]

    public static func transliteration(_ raw: String) -> String {
        guard !raw.isEmpty, raw.rangeOfCharacter(from: oldConventionChars) != nil else { return raw }
        var s = raw
            .replacingOccurrences(of: "aá", with: "ā")
            .replacingOccurrences(of: "á", with: "ā")
            .replacingOccurrences(of: "Anbyā", with: "Anbiyā")

        // Remove word-initial apostrophes (e.g. "Al-'Anfal" -> "Al-Anfal").
        if let regex = try? NSRegularExpression(pattern: "(^|[\\s-])'") {
            let range = NSRange(s.startIndex..<s.endIndex, in: s)
            s = regex.stringByReplacingMatches(in: s, range: range, withTemplate: "$1")
        }

        var out = ""
        out.reserveCapacity(s.count)
        for ch in s {
            switch ch {
            case "ĥ": out.append("ḥ")
            case "Ĥ": out.append("Ḥ")
            case "ş": out.append("ṣ")
            case "Ş": out.append("Ṣ")
            case "ţ": out.append("ṭ")
            case "Ţ": out.append("Ṭ")
            case "đ": out.append("ḍ")
            case "Đ": out.append("Ḍ")
            case "`", "‘": out.append("ʿ")
            case "'", "’": out.append("ʾ")
            default: out.append(ch)
            }
        }
        return out
    }

    public static func isArabicScript(_ language: String) -> Bool {
        let base = SirajLocalizer.baseLanguage(language)
        return base == "ar" || base == "ur"
    }

    public static func forLanguage(_ surah: Surah, language: String) -> String {
        if isArabicScript(language) {
            return surah.name
        }
        let clean = transliteration(surah.englishName)
        return clean.isEmpty ? surah.name : clean
    }

    public static func forLanguage(arabicName: String, latinName: String, language: String) -> String {
        if isArabicScript(language) {
            return arabicName.isEmpty ? transliteration(latinName) : arabicName
        }
        let clean = transliteration(latinName)
        return clean.isEmpty ? arabicName : clean
    }

    public static func matches(_ surah: Surah, query: String) -> Bool {
        let key = searchKey(query)
        guard !key.isEmpty else { return true }
        if key.allSatisfy({ $0 >= "0" && $0 <= "9" }) {
            return Int(key) == surah.number
        }
        return searchKey(surah.englishName).contains(key)
            || searchKey(surah.name).contains(key)
            || searchKey(surah.englishNameTranslation).contains(key)
    }

    public static func searchKey(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        let words = trimmed.lowercased().split(whereSeparator: { $0.isWhitespace }).map(String.init)
        let kept = words.filter { !surahWords.contains(foldWord($0)) }
        let target = kept.isEmpty ? words : kept
        return target.map(foldWord).joined()
    }

    private static func foldWord(_ word: String) -> String {
        let decomposed = word.decomposedStringWithCanonicalMapping
        var out = ""
        out.reserveCapacity(decomposed.count)
        for scalar in decomposed.unicodeScalars {
            if scalar.properties.generalCategory == .nonspacingMark { continue }
            let mapped: Character
            switch scalar.value {
            case 0x0111: mapped = "d"
            case 0x0131: mapped = "i"
            case 0x0671: mapped = "ا"
            case 0x0649, 0x06CC: mapped = "ي"
            case 0x0629, 0x06C3, 0x06C1, 0x06BE: mapped = "ه"
            case 0x06A9: mapped = "ك"
            case 0x0660...0x0669:
                mapped = Character(UnicodeScalar(0x30 + (scalar.value - 0x0660))!)
            case 0x06F0...0x06F9:
                mapped = Character(UnicodeScalar(0x30 + (scalar.value - 0x06F0))!)
            default:
                mapped = Character(scalar)
            }
            if (mapped.isLetter || mapped.isNumber) && !notLetters.contains(mapped) {
                out.append(mapped)
            }
        }
        return out
    }
}

public struct ExactAyahReference: Sendable, Equatable {
    public let surahNumber: Int
    public let ayahNumber: Int
    public let surah: Surah

    public init(surahNumber: Int, ayahNumber: Int, surah: Surah) {
        self.surahNumber = surahNumber
        self.ayahNumber = ayahNumber
        self.surah = surah
    }
}

public enum QuranSearchParser {
    private static let meccanWords: Set<String> = [
        "مكيه", "مكي", "مکی", "مکيه", "meccan", "makki", "makkan", "mekki", "mekkî", "mekke"
    ]
    private static let medinanWords: Set<String> = [
        "مدنيه", "مدني", "مدنی", "medinan", "madani", "madinan", "medeni", "medenî", "medine"
    ]

    public static func revelationFilter(for query: String) -> Bool? {
        let norm = ArabicSearchText.normalizeQuery(query).replacingOccurrences(of: "سورة", with: "").trimmingCharacters(in: .whitespaces)
        if meccanWords.contains(norm) { return true }
        if medinanWords.contains(norm) { return false }
        return nil
    }

    public static func parseExactAyah(_ query: String, surahs: [Surah]) -> ExactAyahReference? {
        let q = DigitFormatter.toWestern(query).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty, !surahs.isEmpty else { return nil }

        if let numRegex = try? NSRegularExpression(pattern: #"^(\d{1,3})\s*[:/,\-\s]\s*(\d{1,3})$"#),
           let m = numRegex.firstMatch(in: q, range: NSRange(q.startIndex..<q.endIndex, in: q)),
           let r1 = Range(m.range(at: 1), in: q),
           let r2 = Range(m.range(at: 2), in: q),
           let sNum = Int(q[r1]),
           let aNum = Int(q[r2]),
           let surah = surahs.first(where: { $0.number == sNum }),
           aNum >= 1 && aNum <= surah.numberOfAyahs {
            return ExactAyahReference(surahNumber: sNum, ayahNumber: aNum, surah: surah)
        }

        if let namedRegex = try? NSRegularExpression(
            pattern: #"^(?:سورة\s+|surah\s+|sure\s+)?(.+?)\s*(?:[:/,\-]|آية|اية|ayah|\s)\s*(\d{1,3})$"#,
            options: [.caseInsensitive]
        ),
           let m = namedRegex.firstMatch(in: q, range: NSRange(q.startIndex..<q.endIndex, in: q)),
           let r1 = Range(m.range(at: 1), in: q),
           let r2 = Range(m.range(at: 2), in: q),
           let aNum = Int(q[r2]) {
            let namePart = String(q[r1]).trimmingCharacters(in: .whitespaces)
            if !namePart.isEmpty,
               let surah = surahs.first(where: { s in
                   SurahNames.matches(s, query: namePart)
                       || s.name.localizedCaseInsensitiveContains(namePart)
                       || namePart.localizedCaseInsensitiveContains(s.name)
                       || s.englishName.localizedCaseInsensitiveContains(namePart)
               }),
               aNum >= 1 && aNum <= surah.numberOfAyahs {
                return ExactAyahReference(surahNumber: surah.number, ayahNumber: aNum, surah: surah)
            }
        }
        return nil
    }

    public static func parseDirectPage(_ query: String, totalPages: Int = 604) -> Int? {
        let q = DigitFormatter.toWestern(query).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return nil }

        if let labelRegex = try? NSRegularExpression(pattern: #"^(?:page|p|صفحة|ص|sayfa)\s*(\d{1,4})$"#, options: [.caseInsensitive]),
           let m = labelRegex.firstMatch(in: q, range: NSRange(q.startIndex..<q.endIndex, in: q)),
           let r1 = Range(m.range(at: 1), in: q),
           let p = Int(q[r1]),
           p >= 1 && p <= totalPages {
            return p
        }

        if let pureRegex = try? NSRegularExpression(pattern: #"^(\d{1,4})$"#),
           let m = pureRegex.firstMatch(in: q, range: NSRange(q.startIndex..<q.endIndex, in: q)),
           let r1 = Range(m.range(at: 1), in: q),
           let p = Int(q[r1]),
           p >= 1 && p <= totalPages {
            return p
        }
        return nil
    }
}

public enum HtmlSanitizer {
    private static let entities: [(String, String)] = [
        ("&quot;", "\""), ("&apos;", "'"), ("&#39;", "'"), ("&amp;", "&"),
        ("&lt;", "<"), ("&gt;", ">"), ("&nbsp;", " "), ("&rlm;", ""),
        ("&lrm;", ""), ("&bull;", "•"), ("&mdash;", "—"), ("&ndash;", "–"), ("&hellip;", "…")
    ]

    public static func sanitize(_ raw: String?) -> String {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "" }
        var cleaned = raw.replacingOccurrences(of: "<[^>]*>", with: "", options: .regularExpression)
        for (entity, replacement) in entities {
            cleaned = cleaned.replacingOccurrences(of: entity, with: replacement)
        }
        if let decRegex = try? NSRegularExpression(pattern: "&#(\\d+);") {
            let matches = decRegex.matches(in: cleaned, range: NSRange(cleaned.startIndex..<cleaned.endIndex, in: cleaned))
            for m in matches.reversed() {
                if let full = Range(m.range, in: cleaned),
                   let numR = Range(m.range(at: 1), in: cleaned),
                   let code = UInt32(cleaned[numR]),
                   let scalar = UnicodeScalar(code) {
                    cleaned.replaceSubrange(full, with: String(scalar))
                }
            }
        }
        if let hexRegex = try? NSRegularExpression(pattern: "&#x([0-9a-fA-F]+);") {
            let matches = hexRegex.matches(in: cleaned, range: NSRange(cleaned.startIndex..<cleaned.endIndex, in: cleaned))
            for m in matches.reversed() {
                if let full = Range(m.range, in: cleaned),
                   let numR = Range(m.range(at: 1), in: cleaned),
                   let code = UInt32(cleaned[numR], radix: 16),
                   let scalar = UnicodeScalar(code) {
                    cleaned.replaceSubrange(full, with: String(scalar))
                }
            }
        }
        cleaned = cleaned.replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public enum DigitalKhattText {
    // DigitalKhatt's space is 0.1 em; three spaces give an ordinary word gap in running text.
    private static let wordGap = "   "

    public static func forDisplay(_ text: String) -> String {
        let words = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }
        return forDisplay(words)
    }

    public static func forDisplay(_ words: [String]) -> String {
        var joined: [String] = []
        joined.reserveCapacity(words.count)
        for word in words {
            let hasOtherLetter = word.unicodeScalars.contains { $0.properties.generalCategory == .otherLetter }
            let hasNonSpacing = word.unicodeScalars.contains { $0.properties.generalCategory == .nonspacingMark }
            if !hasOtherLetter && hasNonSpacing && !joined.isEmpty {
                joined[joined.count - 1] += word
            } else {
                joined.append(word)
            }
        }
        return joined.joined(separator: wordGap)
    }
}

public enum ShamarlyText {
    public static let ayahEnd = Character(UnicodeScalar(0x06DD)!)
    public static let quarterSign = Character(UnicodeScalar(0x06DE)!)
    public static let sajdahSign = Character(UnicodeScalar(0x06E9)!)
    public static let quarterStar = "* "
    public static let tatweel = Character(UnicodeScalar(0x0640)!)

    public static let basmalah: String = {
        let codes: [UInt32] = [
            0x0628, 0x0650, 0x0633, 0x06E1, 0x0645, 0x0650, 0x20,
            0x0671, 0x0644, 0x0644, 0x0651, 0x064E, 0x0647, 0x0650, 0x20,
            0x0671, 0x0644, 0x0631, 0x0651, 0x064E, 0x062D, 0x06E1, 0x0645, 0x064E, 0x0670, 0x0646, 0x0650, 0x20,
            0x0671, 0x0644, 0x0631, 0x0651, 0x064E, 0x062D, 0x0650, 0x064A, 0x0645, 0x0650
        ]
        return String(String.UnicodeScalarView(codes.compactMap(UnicodeScalar.init)))
    }()

    public struct Word: Sendable, Equatable {
        public let text: String
        public let opensQuarter: Bool
        public let endsSajdah: Bool
    }

    public struct KashidaSlot: Sendable, Equatable {
        public let utf16Offset: Int
        public let priority: Int
    }

    private static let openTanweenMap: [UInt32: UnicodeScalar] = [
        0x0657: UnicodeScalar(0x08F0)!,
        0x065E: UnicodeScalar(0x08F1)!,
        0x0656: UnicodeScalar(0x08F2)!
    ]

    private static let dualJoining: Set<UInt32> = [
        0x0626, 0x0628, 0x062A, 0x062B, 0x062C, 0x062D, 0x062E, 0x0633, 0x0634, 0x0635, 0x0636,
        0x0637, 0x0638, 0x0639, 0x063A, 0x0641, 0x0642, 0x0643, 0x0644, 0x0645, 0x0646, 0x0647,
        0x064A, 0x0649, 0x066E, 0x066F, 0x06A1, 0x06BA
    ]

    private static let rightJoining: Set<UInt32> = [
        0x0622, 0x0623, 0x0624, 0x0625, 0x0627, 0x0629, 0x062F, 0x0630, 0x0631, 0x0632, 0x0648,
        0x0671, 0x0675, 0x0676, 0x0677
    ]

    private static let alefs: Set<UInt32> = [0x0622, 0x0623, 0x0625, 0x0627, 0x0671]
    private static let drawnOutFirst: Set<UInt32> = [0x0633, 0x0634, 0x0635, 0x0636, 0x0637, 0x0638]

    public static func word(_ stored: String) -> Word {
        var text = stored
        let opensQuarter = text.unicodeScalars.first?.value == 0x06DE
        if opensQuarter {
            text = String(text.dropFirst()).trimmingCharacters(in: .whitespaces)
        }
        let endsSajdah = text.unicodeScalars.contains { $0.value == 0x06E9 }
        if endsSajdah {
            text = text.replacingOccurrences(of: "\u{06E9}", with: "").trimmingCharacters(in: .whitespaces)
        }
        text = dotlessFinalYa(openTanween(text))
        return Word(text: opensQuarter ? quarterStar + text : text, opensQuarter: opensQuarter, endsSajdah: endsSajdah)
    }

    public static func medallion(_ number: String, sajdah: Bool = false) -> String {
        let base = "\u{06DD}" + number.trimmingCharacters(in: .whitespaces)
        return sajdah ? base + " \u{06E9}" : base
    }

    public static func quote(_ stored: String) -> String {
        var pieces: [String] = []
        var sajdah = false
        for rawPiece in stored.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ") {
            let piece = String(rawPiece)
            if piece.isEmpty || piece == "\u{06DE}" { continue }
            if piece == "\u{06E9}" {
                sajdah = true
                continue
            }
            let isDigitsOrEnd = piece.unicodeScalars.allSatisfy { ($0.value >= 0x0660 && $0.value <= 0x0669) || $0.value == 0x06DD }
            if isDigitsOrEnd {
                let digitsOnly = String(piece.unicodeScalars.filter { $0.value != 0x06DD })
                pieces.append("\u{2060}" + medallion(digitsOnly, sajdah: sajdah))
                sajdah = false
            } else {
                let shown = word(piece)
                if shown.endsSajdah { sajdah = true }
                let cleaned = shown.text.hasPrefix(quarterStar) ? String(shown.text.dropFirst(quarterStar.count)) : shown.text
                pieces.append(cleaned)
            }
        }
        return pieces.joined(separator: " ")
    }

    public static func openTanween(_ text: String) -> String {
        guard text.unicodeScalars.contains(where: { openTanweenMap[$0.value] != nil }) else { return text }
        var out = String.UnicodeScalarView()
        out.reserveCapacity(text.unicodeScalars.count)
        for s in text.unicodeScalars {
            out.append(openTanweenMap[s.value] ?? s)
        }
        return String(out)
    }

    public static func dotlessFinalYa(_ text: String) -> String {
        let scalars = Array(text.unicodeScalars)
        guard scalars.contains(where: { $0.value == 0x064A }) else { return text }
        var out = scalars
        for i in scalars.indices where scalars[i].value == 0x064A {
            var j = i + 1
            while j < scalars.count && isMark(scalars[j]) { j += 1 }
            if j == scalars.count || scalars[j].value == 0x20 || scalars[j].value == 0x0621 {
                out[i] = UnicodeScalar(0x0649)!
            }
        }
        return String(String.UnicodeScalarView(out))
    }

    public static func kashidaSlots(_ text: String) -> [KashidaSlot] {
        let scalars = Array(text.unicodeScalars)
        var starts: [Int] = []
        var endsUtf16: [Int] = []
        var utf16Pos = 0
        var i = 0
        while i < scalars.count {
            starts.append(i)
            utf16Pos += scalars[i].utf16.count
            var j = i + 1
            while j < scalars.count && isMark(scalars[j]) {
                utf16Pos += scalars[j].utf16.count
                j += 1
            }
            endsUtf16.append(utf16Pos)
            i = j
        }
        guard starts.count >= 2 else { return [] }
        let letters = String(String.UnicodeScalarView(starts.map { scalars[$0] }))
        if letters.contains("لله") { return [] }

        var slots: [KashidaSlot] = []
        for k in 0..<(starts.count - 1) {
            let a = scalars[starts[k]].value
            let b = scalars[starts[k + 1]].value
            guard dualJoining.contains(a) else { continue }
            guard dualJoining.contains(b) || rightJoining.contains(b) else { continue }
            if a == 0x0644 && alefs.contains(b) { continue }
            let priority: Int
            if drawnOutFirst.contains(a) {
                priority = 0
            } else if k == starts.count - 2 {
                priority = 1
            } else {
                priority = 2
            }
            slots.append(KashidaSlot(utf16Offset: endsUtf16[k], priority: priority))
        }
        return slots.sorted {
            if $0.priority != $1.priority { return $0.priority < $1.priority }
            return $0.utf16Offset > $1.utf16Offset
        }
    }

    private static func isMark(_ s: UnicodeScalar) -> Bool {
        let cat = s.properties.generalCategory
        return cat == .nonspacingMark || cat == .enclosingMark || cat == .spacingMark
    }
}

public struct ShamarlyBanner: Sendable, Equatable {
    public let first: String
    public let second: String
}

public enum ShamarlyBanners {
    public static let all: [ShamarlyBanner] = [
        ShamarlyBanner(first: "(١) سورة الفاتحة مكية", second: "وآياتها ٧ نزلت بعد المدثر"),
        ShamarlyBanner(first: "(٢) سورة البقرة مدنية", second: "وآياتها ٢٨٦ نزلت بعد المطففين"),
        ShamarlyBanner(first: "(٣) سورة آل عمران مدنية", second: "وآياتها ٢٠٠ نزلت بعد الأنفال"),
        ShamarlyBanner(first: "(٤) سورة النساء مدنية", second: "وآياتها ١٧٦ نزلت بعد الممتحنة"),
        ShamarlyBanner(first: "(٥) سورة المائدة مدنية", second: "وآياتها ١٢٠ نزلت بعد الفتح"),
        ShamarlyBanner(first: "(٦) سورة الأنعام مكية", second: "وآياتها ١٦٥ نزلت بعد الحجر"),
        ShamarlyBanner(first: "(٧) سورة الأعراف مكية", second: "وآياتها ٢٠٦ نزلت بعد ص"),
        ShamarlyBanner(first: "(٨) سورة الأنفال مدنية", second: "وآياتها ٧٥ نزلت بعد البقرة"),
        ShamarlyBanner(first: "(٩) سورة التوبة مدنية", second: "وآياتها ١٢٩ نزلت بعد المائدة"),
        ShamarlyBanner(first: "(١٠) سورة يونس مكية", second: "وآياتها ١٠٩ نزلت بعد الإسراء"),
        ShamarlyBanner(first: "(١١) سورة هود مكية", second: "وآياتها ١٢٣ نزلت بعد يونس"),
        ShamarlyBanner(first: "(١٢) سورة يوسف مكية", second: "وآياتها ١١١ نزلت بعد هود"),
        ShamarlyBanner(first: "(١٣) سورة الرعد مدنية", second: "وآياتها ٤٣ نزلت بعد محمد"),
        ShamarlyBanner(first: "(١٤) سورة إبراهيم مكية", second: "وآياتها ٥٢ نزلت بعد نوح"),
        ShamarlyBanner(first: "(١٥) سورة الحجر مكية", second: "وآياتها ٩٩ نزلت بعد يوسف"),
        ShamarlyBanner(first: "(١٦) سورة النحل مكية", second: "وآياتها ١٢٨ نزلت بعد الكهف"),
        ShamarlyBanner(first: "(١٧) سورة الإسراء مكية", second: "وآياتها ١١١ نزلت بعد القصص"),
        ShamarlyBanner(first: "(١٨) سورة الكهف مكية", second: "وآياتها ١١٠ نزلت بعد الغاشية"),
        ShamarlyBanner(first: "(١٩) سورة مريم مكية", second: "وآياتها ٩٨ نزلت بعد فاطر"),
        ShamarlyBanner(first: "(٢٠) سورة طه مكية", second: "وآياتها ١٣٥ نزلت بعد مريم"),
        ShamarlyBanner(first: "(٢١) سورة الأنبياء مكية", second: "وآياتها ١١٢ نزلت بعد إبراهيم"),
        ShamarlyBanner(first: "(٢٢) سورة الحج مدنية", second: "وآياتها ٧٨ نزلت بعد النور"),
        ShamarlyBanner(first: "(٢٣) سورة المؤمنون مكية", second: "وآياتها ١١٨ نزلت بعد الأنبياء"),
        ShamarlyBanner(first: "(٢٤) سورة النور مدنية", second: "وآياتها ٦٤ نزلت بعد الحشر"),
        ShamarlyBanner(first: "(٢٥) سورة الفرقان مكية", second: "وآياتها ٧٧ نزلت بعد يس"),
        ShamarlyBanner(first: "(٢٦) سورة الشعراء مكية", second: "وآياتها ٢٢٧ نزلت بعد الواقعة"),
        ShamarlyBanner(first: "(٢٧) سورة النمل مكية", second: "وآياتها ٩٣ نزلت بعد الشعراء"),
        ShamarlyBanner(first: "(٢٨) سورة القصص مكية", second: "وآياتها ٨٨ نزلت بعد النمل"),
        ShamarlyBanner(first: "(٢٩) سورة العنكبوت مكية", second: "وآياتها ٦٩ نزلت بعد الروم"),
        ShamarlyBanner(first: "(٣٠) سورة الروم مكية", second: "وآياتها ٦٠ نزلت بعد الانشقاق"),
        ShamarlyBanner(first: "(٣١) سورة لقمان مكية", second: "وآياتها ٣٤ نزلت بعد الصافات"),
        ShamarlyBanner(first: "(٣٢) سورة السجدة مكية", second: "وآياتها ٣٠ نزلت بعد المؤمنون"),
        ShamarlyBanner(first: "(٣٣) سورة الأحزاب مدنية", second: "وآياتها ٧٣ نزلت بعد آل عمران"),
        ShamarlyBanner(first: "(٣٤) سورة سبأ مكية", second: "وآياتها ٥٤ نزلت بعد لقمان"),
        ShamarlyBanner(first: "(٣٥) سورة فاطر مكية", second: "وآياتها ٤٥ نزلت بعد الفرقان"),
        ShamarlyBanner(first: "(٣٦) سورة يس مكية", second: "وآياتها ٨٣ نزلت بعد الجن"),
        ShamarlyBanner(first: "(٣٧) سورة الصافات مكية", second: "وآياتها ١٨٢ نزلت بعد الأنعام"),
        ShamarlyBanner(first: "(٣٨) سورة ص مكية", second: "وآياتها ٨٨ نزلت بعد القمر"),
        ShamarlyBanner(first: "(٣٩) سورة الزمر مكية", second: "وآياتها ٧٥ نزلت بعد سبأ"),
        ShamarlyBanner(first: "(٤٠) سورة غافر مكية", second: "وآياتها ٨٥ نزلت بعد الزمر"),
        ShamarlyBanner(first: "(٤١) سورة فصلت مكية", second: "وآياتها ٥٤ نزلت بعد غافر"),
        ShamarlyBanner(first: "(٤٢) سورة الشورى مكية", second: "وآياتها ٥٣ نزلت بعد فصلت"),
        ShamarlyBanner(first: "(٤٣) سورة الزخرف مكية", second: "وآياتها ٨٩ نزلت بعد الشورى"),
        ShamarlyBanner(first: "(٤٤) سورة الدخان مكية", second: "وآياتها ٥٩ نزلت بعد الزخرف"),
        ShamarlyBanner(first: "(٤٥) سورة الجاثية مكية", second: "وآياتها ٣٧ نزلت بعد الدخان"),
        ShamarlyBanner(first: "(٤٦) سورة الأحقاف مكية", second: "وآياتها ٣٥ نزلت بعد الجاثية"),
        ShamarlyBanner(first: "(٤٧) سورة محمد مدنية", second: "وآياتها ٣٨ نزلت بعد الحديد"),
        ShamarlyBanner(first: "(٤٨) سورة الفتح مدنية", second: "وآياتها ٢٩ نزلت بعد الجمعة"),
        ShamarlyBanner(first: "(٤٩) سورة الحجرات مدنية", second: "وآياتها ١٨ نزلت بعد المجادلة"),
        ShamarlyBanner(first: "(٥٠) سورة ق مكية", second: "وآياتها ٤٥ نزلت بعد المرسلات"),
        ShamarlyBanner(first: "(٥١) سورة الذاريات مكية", second: "وآياتها ٦٠ نزلت بعد الأحقاف"),
        ShamarlyBanner(first: "(٥٢) سورة الطور مكية", second: "وآياتها ٤٩ نزلت بعد السجدة"),
        ShamarlyBanner(first: "(٥٣) سورة النجم مكية", second: "وآياتها ٦٢ نزلت بعد الإخلاص"),
        ShamarlyBanner(first: "(٥٤) سورة القمر مكية", second: "وآياتها ٥٥ نزلت بعد الطارق"),
        ShamarlyBanner(first: "(٥٥) سورة الرحمن مدنية", second: "وآياتها ٧٨ نزلت بعد الرعد"),
        ShamarlyBanner(first: "(٥٦) سورة الواقعة مكية", second: "وآياتها ٩٦ نزلت بعد طه"),
        ShamarlyBanner(first: "(٥٧) سورة الحديد مدنية", second: "وآياتها ٢٩ نزلت بعد الزلزلة"),
        ShamarlyBanner(first: "(٥٨) سورة المجادلة مدنية", second: "وآياتها ٢٢ نزلت بعد المنافقون"),
        ShamarlyBanner(first: "(٥٩) سورة الحشر مدنية", second: "وآياتها ٢٤ نزلت بعد البينة"),
        ShamarlyBanner(first: "(٦٠) سورة الممتحنة مدنية", second: "وآياتها ١٣ نزلت بعد الأحزاب"),
        ShamarlyBanner(first: "(٦١) سورة الصف مدنية", second: "وآياتها ١٤ نزلت بعد التغابن"),
        ShamarlyBanner(first: "(٦٢) سورة الجمعة مدنية", second: "وآياتها ١١ نزلت بعد الصف"),
        ShamarlyBanner(first: "(٦٣) سورة المنافقون مدنية", second: "وآياتها ١١ نزلت بعد الحج"),
        ShamarlyBanner(first: "(٦٤) سورة التغابن مدنية", second: "وآياتها ١٨ نزلت بعد التحريم"),
        ShamarlyBanner(first: "(٦٥) سورة الطلاق مدنية", second: "وآياتها ١٢ نزلت بعد الإنسان"),
        ShamarlyBanner(first: "(٦٦) سورة التحريم مدنية", second: "وآياتها ١٢ نزلت بعد الحجرات"),
        ShamarlyBanner(first: "(٦٧) سورة الملك مكية", second: "وآياتها ٣٠ نزلت بعد الطور"),
        ShamarlyBanner(first: "(٦٨) سورة القلم مكية", second: "وآياتها ٥٢ نزلت بعد العلق"),
        ShamarlyBanner(first: "(٦٩) سورة الحاقة مكية", second: "وآياتها ٥٢ نزلت بعد الملك"),
        ShamarlyBanner(first: "(٧٠) سورة المعارج مكية", second: "وآياتها ٤٤ نزلت بعد الحاقة"),
        ShamarlyBanner(first: "(٧١) سورة نوح مكية", second: "وآياتها ٢٨ نزلت بعد النحل"),
        ShamarlyBanner(first: "(٧٢) سورة الجن مكية", second: "وآياتها ٢٨ نزلت بعد الأعراف"),
        ShamarlyBanner(first: "(٧٣) سورة المزمل مكية", second: "وآياتها ٢٠ نزلت بعد القلم"),
        ShamarlyBanner(first: "(٧٤) سورة المدثر مكية", second: "وآياتها ٥٦ نزلت بعد المزمل"),
        ShamarlyBanner(first: "(٧٥) سورة القيامة مكية", second: "وآياتها ٤٠ نزلت بعد القارعة"),
        ShamarlyBanner(first: "(٧٦) سورة الإنسان مدنية", second: "وآياتها ٣١ نزلت بعد الرحمن"),
        ShamarlyBanner(first: "(٧٧) سورة المرسلات مكية", second: "وآياتها ٥٠ نزلت بعد الهمزة"),
        ShamarlyBanner(first: "(٧٨) سورة النبأ مكية", second: "وآياتها ٤٠ نزلت بعد المعارج"),
        ShamarlyBanner(first: "(٧٩) سورة النازعات مكية", second: "وآياتها ٤٦ نزلت بعد النبأ"),
        ShamarlyBanner(first: "(٨٠) سورة عبس مكية", second: "وآياتها ٤٢ نزلت بعد النجم"),
        ShamarlyBanner(first: "(٨١) سورة التكوير مكية", second: "وآياتها ٢٩ نزلت بعد المسد"),
        ShamarlyBanner(first: "(٨٢) سورة الانفطار مكية", second: "وآياتها ١٩ نزلت بعد النازعات"),
        ShamarlyBanner(first: "(٨٣) سورة المطففين مكية", second: "وآياتها ٣٦ نزلت بعد العنكبوت"),
        ShamarlyBanner(first: "(٨٤) سورة الانشقاق مكية", second: "وآياتها ٢٥ نزلت بعد الانفطار"),
        ShamarlyBanner(first: "(٨٥) سورة البروج مكية", second: "وآياتها ٢٢ نزلت بعد الشمس"),
        ShamarlyBanner(first: "(٨٦) سورة الطارق مكية", second: "وآياتها ١٧ نزلت بعد البلد"),
        ShamarlyBanner(first: "(٨٧) سورة الأعلى مكية", second: "وآياتها ١٩ نزلت بعد التكوير"),
        ShamarlyBanner(first: "(٨٨) سورة الغاشية مكية", second: "وآياتها ٢٦ نزلت بعد الذاريات"),
        ShamarlyBanner(first: "(٨٩) سورة الفجر مكية", second: "وآياتها ٣٠ نزلت بعد الليل"),
        ShamarlyBanner(first: "(٩٠) سورة البلد مكية", second: "وآياتها ٢٠ نزلت بعد ق"),
        ShamarlyBanner(first: "(٩١) سورة الشمس مكية", second: "وآياتها ١٥ نزلت بعد القدر"),
        ShamarlyBanner(first: "(٩٢) سورة الليل مكية", second: "وآياتها ٢١ نزلت بعد الأعلى"),
        ShamarlyBanner(first: "(٩٣) سورة الضحى مكية", second: "وآياتها ١١ نزلت بعد الفجر"),
        ShamarlyBanner(first: "(٩٤) سورة الشرح مكية", second: "وآياتها ٨ نزلت بعد الضحى"),
        ShamarlyBanner(first: "(٩٥) سورة التين مكية", second: "وآياتها ٨ نزلت بعد البروج"),
        ShamarlyBanner(first: "(٩٦) سورة العلق مكية", second: "وآياتها ١٩ وهي أول ما نزل من القرآن"),
        ShamarlyBanner(first: "(٩٧) سورة القدر مكية", second: "وآياتها ٥ نزلت بعد عبس"),
        ShamarlyBanner(first: "(٩٨) سورة البينة مدنية", second: "وآياتها ٨ نزلت بعد الطلاق"),
        ShamarlyBanner(first: "(٩٩) سورة الزلزلة مدنية", second: "وآياتها ٨ نزلت بعد النساء"),
        ShamarlyBanner(first: "(١٠٠) سورة العاديات مكية", second: "وآياتها ١١ نزلت بعد العصر"),
        ShamarlyBanner(first: "(١٠١) سورة القارعة مكية", second: "وآياتها ١١ نزلت بعد قريش"),
        ShamarlyBanner(first: "(١٠٢) سورة التكاثر مكية", second: "وآياتها ٨ نزلت بعد الكوثر"),
        ShamarlyBanner(first: "(١٠٣) سورة العصر مكية", second: "وآياتها ٣ نزلت بعد الشرح"),
        ShamarlyBanner(first: "(١٠٤) سورة الهمزة مكية", second: "وآياتها ٩ نزلت بعد القيامة"),
        ShamarlyBanner(first: "(١٠٥) سورة الفيل مكية", second: "وآياتها ٥ نزلت بعد الكافرون"),
        ShamarlyBanner(first: "(١٠٦) سورة قريش مكية", second: "وآياتها ٤ نزلت بعد التين"),
        ShamarlyBanner(first: "(١٠٧) سورة الماعون مكية", second: "وآياتها ٧ نزلت بعد التكاثر"),
        ShamarlyBanner(first: "(١٠٨) سورة الكوثر مكية", second: "وآياتها ٣ نزلت بعد العاديات"),
        ShamarlyBanner(first: "(١٠٩) سورة الكافرون مكية", second: "وآياتها ٦ نزلت بعد الماعون"),
        ShamarlyBanner(first: "(١١٠) سورة النصر مدنية", second: "وآياتها ٣ نزلت بعد التوبة"),
        ShamarlyBanner(first: "(١١١) سورة المسد مكية", second: "وآياتها ٥ نزلت بعد الفاتحة"),
        ShamarlyBanner(first: "(١١٢) سورة الإخلاص مكية", second: "وآياتها ٤ نزلت بعد الناس"),
        ShamarlyBanner(first: "(١١٣) سورة الفلق مكية", second: "وآياتها ٥ نزلت بعد الفيل"),
        ShamarlyBanner(first: "(١١٤) سورة الناس مكية", second: "وآياتها ٦ نزلت بعد الفلق")
    ]

    public static func forSurah(_ number: Int) -> ShamarlyBanner? {
        guard number >= 1 && number <= all.count else { return nil }
        return all[number - 1]
    }
}

public enum ShamarlyMeasures {
    public static let measureEmByPage: [Double] = [
        16.80, 16.80, 16.80, 17.26, 17.78, 18.31, 18.05, 18.13, 18.68, 19.20,
        19.35, 19.50, 20.08, 19.50, 20.08, 19.50, 19.12, 19.69, 19.20, 19.78,
        19.85, 20.08, 20.24, 19.88, 20.48, 20.60, 20.36, 20.55, 20.06, 20.60,
        20.01, 20.20, 20.27, 20.48, 20.53, 19.93, 19.35, 19.16, 19.74, 19.65,
        19.08, 19.65, 19.34, 19.92, 20.03, 20.28, 20.06, 19.86, 20.10, 19.67,
        19.67, 19.63, 19.78, 19.50, 20.09, 19.84, 19.27, 19.84, 19.41, 19.84,
        19.56, 19.63, 19.86, 19.76, 20.05, 20.22, 20.44, 19.84, 20.44, 20.12,
        19.65, 19.49, 19.54, 19.83, 20.32, 19.73, 19.73, 19.77, 19.97, 20.23,
        19.74, 20.11, 20.49, 20.60, 20.33, 19.74, 20.33, 20.20, 19.73, 20.32,
        20.11, 20.27, 19.86, 20.22, 20.14, 19.78, 20.38, 20.59, 20.02, 20.05,
        20.19, 20.39, 20.07, 19.49, 20.08, 20.12, 20.29, 19.70, 20.29, 20.38,
        20.40, 20.60, 20.28, 20.20, 19.61, 20.20, 19.61, 19.63, 20.22, 20.31,
        20.60, 20.18, 20.40, 19.96, 20.42, 20.10, 19.51, 19.88, 19.94, 19.77,
        20.36, 20.01, 20.49, 19.89, 19.31, 19.77, 19.82, 19.89, 20.19, 19.86,
        19.66, 19.97, 20.16, 19.81, 19.23, 19.25, 19.60, 19.36, 19.45, 19.16,
        19.39, 19.97, 19.39, 19.59, 19.54, 19.18, 18.62, 19.18, 18.64, 19.03,
        19.52, 19.02, 19.59, 19.37, 19.30, 19.36, 19.11, 19.12, 18.78, 19.35,
        19.52, 19.63, 19.72, 20.01, 19.43, 18.95, 19.52, 19.46, 19.71, 19.14,
        18.99, 19.43, 19.64, 19.65, 20.01, 19.50, 18.93, 19.03, 18.84, 19.40,
        18.83, 18.66, 18.81, 19.38, 19.67, 19.09, 18.54, 18.79, 18.87, 18.87,
        19.43, 19.70, 19.54, 18.97, 19.54, 20.03, 19.56, 19.06, 19.02, 18.49,
        19.05, 19.15, 19.72, 19.64, 19.15, 19.08, 19.16, 19.17, 19.62, 19.04,
        19.25, 18.75, 19.32, 19.47, 18.90, 19.18, 19.35, 18.79, 19.25, 19.27,
        19.41, 19.37, 18.81, 18.84, 19.40, 19.99, 19.40, 19.36, 19.75, 20.34,
        20.22, 20.38, 19.79, 19.21, 19.79, 19.60, 19.58, 19.20, 19.77, 19.20,
        19.70, 20.10, 19.54, 19.84, 19.55, 18.98, 19.23, 19.81, 20.07, 19.89,
        19.70, 20.29, 19.73, 19.21, 19.79, 20.38, 20.02, 19.44, 20.02, 19.44,
        19.71, 19.14, 19.71, 20.30, 19.71, 20.10, 20.39, 20.38, 19.91, 19.58,
        20.17, 20.59, 19.99, 19.41, 19.26, 19.58, 20.14, 19.61, 20.20, 19.61,
        19.82, 19.93, 19.41, 19.99, 20.15, 19.56, 18.99, 19.42, 19.09, 19.67,
        19.34, 19.54, 20.11, 19.52, 19.93, 20.53, 20.60, 20.08, 19.81, 20.05,
        20.60, 20.22, 19.63, 19.23, 19.43, 20.01, 19.65, 19.08, 19.65, 20.24,
        20.20, 19.87, 20.46, 20.27, 19.68, 19.10, 19.34, 19.83, 20.33, 20.44,
        19.85, 20.44, 19.85, 20.05, 20.34, 19.75, 20.03, 19.89, 20.12, 20.37,
        20.28, 19.85, 19.74, 20.21, 19.91, 20.30, 19.71, 19.95, 20.17, 19.78,
        19.92, 19.34, 19.35, 19.93, 19.86, 19.28, 19.17, 19.75, 20.34, 19.75,
        19.51, 20.10, 19.51, 19.06, 19.64, 19.75, 20.19, 19.60, 19.93, 19.35,
        19.41, 20.00, 19.91, 20.32, 20.60, 20.00, 20.60, 20.25, 20.39, 19.79,
        20.26, 19.67, 19.42, 19.74, 19.65, 20.22, 20.48, 19.88, 20.42, 20.21,
        19.62, 20.21, 19.86, 20.18, 20.37, 19.77, 20.26, 20.05, 19.59, 19.08,
        19.65, 19.26, 19.47, 18.91, 19.33, 19.91, 19.73, 19.21, 19.78, 20.06,
        19.70, 19.32, 19.74, 19.67, 19.78, 20.03, 19.81, 19.57, 19.21, 19.79,
        19.83, 20.36, 19.77, 19.25, 19.83, 19.77, 19.20, 19.77, 19.80, 19.22,
        19.56, 19.48, 19.70, 19.26, 19.84, 20.44, 20.31, 20.60, 20.22, 19.63,
        19.47, 19.82, 19.76, 20.35, 20.60, 20.41, 20.60, 20.60, 20.28, 20.52,
        20.60, 20.05, 19.47, 20.05, 20.11, 19.53, 20.11, 19.94, 20.54, 20.60,
        20.38, 20.07, 19.52, 19.24, 19.57, 19.99, 20.59, 20.41, 19.82, 19.24,
        19.44, 18.87, 19.24, 19.53, 18.96, 19.38, 19.07, 19.40, 19.98, 19.40,
        19.83, 19.57, 20.16, 20.60, 20.60, 20.60, 20.09, 20.09, 19.76, 19.98,
        20.32, 20.31, 19.78, 19.21, 18.65, 19.21, 19.78, 20.38, 20.54, 19.94,
        20.54, 20.60, 20.42, 20.30, 19.71, 20.30, 20.27, 20.59, 19.99, 19.80,
        20.25, 19.66, 19.48, 19.88, 19.45, 18.88, 18.33, 18.88, 19.45, 18.98,
        19.54
    ]

    public static func measureEm(page: Int) -> Double {
        let idx = min(measureEmByPage.count - 1, max(0, page - 1))
        return measureEmByPage[idx]
    }
}

public struct MushafLineBreaksTable: Sendable {
    public struct PrintedPage: Sendable {
        public let counts: [Int]
        public let centred: [Bool]
    }

    public struct WordKey: Sendable, Equatable {
        public let surah: Int
        public let ayah: Int
        public let word: Int
    }

    public let pages: [Int: PrintedPage]
    public let ends: [Int: WordKey]

    public static let empty = MushafLineBreaksTable(pages: [:], ends: [:])

    public static func parse(_ table: String) -> MushafLineBreaksTable {
        var pages: [Int: PrintedPage] = [:]
        var ends: [Int: WordKey] = [:]
        for raw in table.split(whereSeparator: \.isNewline) {
            let row = raw.trimmingCharacters(in: .whitespaces)
            if row.isEmpty || row.hasPrefix("#") { continue }
            let parts = row.split(separator: " ").map(String.init)
            if parts.count == 3, parts[1] == "ends", let page = Int(parts[0]) {
                let nums = parts[2].split(separator: ":").compactMap { Int($0) }
                if nums.count == 3 && nums.allSatisfy({ $0 > 0 }) {
                    ends[page] = WordKey(surah: nums[0], ayah: nums[1], word: nums[2])
                }
                continue
            }
            guard let spaceIdx = row.firstIndex(of: " "),
                  let page = Int(row[..<spaceIdx]) else { continue }
            let rest = row[row.index(after: spaceIdx)...].trimmingCharacters(in: .whitespaces)
            let cells = rest.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            var centred: [Bool] = []
            var counts: [Int] = []
            var valid = !cells.isEmpty
            for cell in cells {
                let isC = cell.hasSuffix("c")
                let digits = isC ? String(cell.dropLast()) : cell
                guard let n = Int(digits), n > 0 else {
                    valid = false
                    break
                }
                centred.append(isC)
                counts.append(n)
            }
            if valid {
                pages[page] = PrintedPage(counts: counts, centred: centred)
            }
        }
        return MushafLineBreaksTable(pages: pages, ends: ends)
    }

    public static func moveEdges(
        lines: [MushafLine],
        previousEnd: WordKey?,
        previousLastLine: MushafLine?,
        end: WordKey?,
        nextFirstLine: MushafLine?
    ) -> [MushafLine]? {
        if end == nil && previousEnd == nil { return lines }
        guard let first = lines.firstIndex(where: { $0.lineType == .ayah && !$0.words.isEmpty }),
              let last = lines.lastIndex(where: { $0.lineType == .ayah && !$0.words.isEmpty }) else {
            return nil
        }
        var out = lines
        var changed = false

        if let end {
            let words = out[last].words
            let moved: [MushafWord]
            if let k = indexOfKey(end, in: words) {
                moved = Array(words[0...k])
            } else {
                guard let nextWords = nextFirstLine?.words,
                      let j = indexOfKey(end, in: nextWords) else { return nil }
                moved = words + Array(nextWords[0...j])
            }
            if moved.count != words.count {
                out[last] = replacingWords(out[last], with: renumbered(moved))
                changed = true
            }
        }

        if let previousEnd {
            let words = out[first].words
            let moved: [MushafWord]
            if let k = indexOfKey(previousEnd, in: words) {
                moved = k + 1 < words.count ? Array(words[(k + 1)...]) : []
            } else {
                guard let prevWords = previousLastLine?.words,
                      let j = indexOfKey(previousEnd, in: prevWords) else { return nil }
                let tail = j + 1 < prevWords.count ? Array(prevWords[(j + 1)...]) : []
                moved = tail + words
            }
            if moved.count != words.count {
                out[first] = replacingWords(out[first], with: renumbered(moved))
                changed = true
            }
        }

        if out[first].words.isEmpty || out[last].words.isEmpty { return nil }
        return changed ? out : lines
    }

    public static func reflow(lines: [MushafLine], counts: [Int], centred: [Bool]?) -> [MushafLine]? {
        let ayahIndices = lines.indices.filter { lines[$0].lineType == .ayah }
        guard !ayahIndices.isEmpty, !counts.isEmpty, counts.allSatisfy({ $0 > 0 }) else { return nil }
        let words = ayahIndices.flatMap { lines[$0].words }

        if ayahIndices.count != counts.count {
            let first = ayahIndices[0]
            guard ayahIndices.last == lines.count - 1, lines.count - first == ayahIndices.count else { return nil }
            guard words.count == counts.reduce(0, +) else { return nil }
            let template = lines[ayahIndices.last!]
            var next = 0
            var run: [MushafLine] = []
            for (k, n) in counts.enumerated() {
                let slice = renumbered(Array(words[next..<(next + n)]))
                next += n
                let isC = (k < centred?.count ?? 0) ? (centred?[k] ?? false) : false
                if k < ayahIndices.count {
                    let orig = lines[ayahIndices[k]]
                    run.append(MushafLine(
                        lineNumber: orig.lineNumber,
                        lineType: orig.lineType,
                        words: slice,
                        isCentered: orig.isCentered || isC,
                        surahNumber: orig.surahNumber,
                        surahName: orig.surahName,
                        fontFile: orig.fontFile
                    ))
                } else {
                    run.append(MushafLine(
                        lineNumber: template.lineNumber + (k - (ayahIndices.count - 1)),
                        lineType: .ayah,
                        words: slice,
                        isCentered: template.isCentered || isC,
                        surahNumber: template.surahNumber,
                        surahName: template.surahName,
                        fontFile: template.fontFile
                    ))
                }
            }
            return Array(lines[0..<first]) + run
        }

        var k = 0
        var runWords = 0
        var runCounts = 0
        for line in lines {
            if line.lineType == .ayah {
                runWords += line.words.count
                runCounts += counts[k]
                k += 1
            } else {
                if runWords != runCounts { return nil }
                runWords = 0
                runCounts = 0
            }
        }
        if runWords != runCounts { return nil }

        var next = 0
        k = 0
        return lines.map { line in
            guard line.lineType == .ayah else { return line }
            let isC = (k < centred?.count ?? 0) ? (centred?[k] ?? false) : false
            let n = counts[k]
            k += 1
            let slice = renumbered(Array(words[next..<(next + n)]))
            next += n
            return MushafLine(
                lineNumber: line.lineNumber,
                lineType: line.lineType,
                words: slice,
                isCentered: line.isCentered || isC,
                surahNumber: line.surahNumber,
                surahName: line.surahName,
                fontFile: line.fontFile
            )
        }
    }

    private static func indexOfKey(_ key: WordKey, in words: [MushafWord]) -> Int? {
        words.firstIndex {
            !$0.isMarker && $0.surahNumber == key.surah && $0.ayahNumber == key.ayah && $0.wordPosition == key.word
        }
    }

    private static func renumbered(_ words: [MushafWord]) -> [MushafWord] {
        words.enumerated().map { idx, w in
            MushafWord(
                id: idx,
                glyphCode: w.glyphCode,
                text: w.text,
                isMarker: w.isMarker,
                surahNumber: w.surahNumber,
                ayahNumber: w.ayahNumber,
                wordPosition: w.wordPosition
            )
        }
    }

    private static func replacingWords(_ line: MushafLine, with words: [MushafWord]) -> MushafLine {
        MushafLine(
            lineNumber: line.lineNumber,
            lineType: line.lineType,
            words: words,
            isCentered: line.isCentered,
            surahNumber: line.surahNumber,
            surahName: line.surahName,
            fontFile: line.fontFile
        )
    }
}

public struct QcfGlyphTable: Sendable {
    public struct PageEntry: Sendable {
        public let fingerprint: UInt32
        public let slotCounts: [UInt8]
    }

    public static let pageCount = 604
    public static let v1SlotCount = 194
    public static let basmalahGlyphs = "!\"#"

    private static let v1SlotCodepoints: [UInt32] = Array(0xFB51...0xFBB1) + Array(0xFBD3...0xFC33)

    private static let surahBannerCodepoints: [UInt32] = [
        0xFC45, 0xFC46, 0xFC47, 0xFC4A, 0xFC4B, 0xFC4E, 0xFC4F, 0xFC51,
        0xFC52, 0xFC53, 0xFC55, 0xFC56, 0xFC58, 0xFC5A, 0xFC5B, 0xFC5C,
        0xFC5D, 0xFC5E, 0xFC61, 0xFC62, 0xFC64, 0xFB51, 0xFB52, 0xFB54,
        0xFB55, 0xFB57, 0xFB58, 0xFB5A, 0xFB5B, 0xFB5D, 0xFB5E, 0xFB60,
        0xFB61, 0xFB63, 0xFB64, 0xFB66, 0xFB67, 0xFB69, 0xFB6A, 0xFB6C,
        0xFB6D, 0xFB6F, 0xFB70, 0xFB72, 0xFB73, 0xFB75, 0xFB76, 0xFB78,
        0xFB79, 0xFB7B, 0xFB7C, 0xFB7E, 0xFB7F, 0xFB81, 0xFB82, 0xFB84,
        0xFB85, 0xFB87, 0xFB88, 0xFB8A, 0xFB8B, 0xFB8D, 0xFB8E, 0xFB90,
        0xFB91, 0xFB93, 0xFB94, 0xFB96, 0xFB97, 0xFB99, 0xFB9A, 0xFB9C,
        0xFB9D, 0xFB9F, 0xFBA0, 0xFBA2, 0xFBA3, 0xFBA5, 0xFBA6, 0xFBA8,
        0xFBA9, 0xFBAB, 0xFBAC, 0xFBAE, 0xFBAF, 0xFBB1, 0xFBB2, 0xFBB4,
        0xFBB5, 0xFBB7, 0xFBB8, 0xFBBA, 0xFBBB, 0xFBBD, 0xFBBE, 0xFBC0,
        0xFBC1, 0xFBD3, 0xFBD4, 0xFBD6, 0xFBD7, 0xFBD9, 0xFBDA, 0xFBDC,
        0xFBDD, 0xFBDF, 0xFBE0, 0xFBE2, 0xFBE3, 0xFBE5, 0xFBE6, 0xFBE8,
        0xFBE9, 0xFBEB
    ]

    public let pages: [PageEntry]

    public static func parse(_ text: String) -> QcfGlyphTable? {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        var entries: [PageEntry] = []
        entries.reserveCapacity(pageCount)
        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty {
                if entries.count < pageCount {
                    entries.append(PageEntry(fingerprint: 0, slotCounts: []))
                }
                continue
            }
            guard let sp = line.firstIndex(of: " "),
                  let fp = UInt32(line[..<sp], radix: 16) else { continue }
            let digits = line[line.index(after: sp)...]
            var counts: [UInt8] = []
            counts.reserveCapacity(digits.count)
            for ch in digits {
                if let ascii = ch.asciiValue, ascii >= 48 && ascii <= 57 {
                    counts.append(ascii - 48)
                }
            }
            entries.append(PageEntry(fingerprint: fp, slotCounts: counts))
        }
        guard entries.count == pageCount else { return nil }
        return QcfGlyphTable(pages: entries)
    }

    public func entry(forPage pageNumber: Int) -> PageEntry? {
        guard pageNumber >= 1 && pageNumber <= pages.count else { return nil }
        let e = pages[pageNumber - 1]
        return e.slotCounts.isEmpty ? nil : e
    }

    public static func v1Glyph(slot: Int) -> String {
        guard slot >= 0 && slot < v1SlotCodepoints.count,
              let scalar = UnicodeScalar(v1SlotCodepoints[slot]) else { return "" }
        return String(scalar)
    }

    public static func surahBanner(surahNumber: Int) -> String {
        guard surahNumber >= 1 && surahNumber <= surahBannerCodepoints.count,
              let scalar = UnicodeScalar(surahBannerCodepoints[surahNumber - 1]) else { return "" }
        return String(scalar)
    }

    public static func verifyFingerprint(words: [MushafWord], expected: UInt32) -> Bool {
        let joined = words.map(\.text).joined(separator: "\n")
        return QuranArchiveUnpacker.crc32Checksum(Data(joined.utf8)) == expected
    }
}
