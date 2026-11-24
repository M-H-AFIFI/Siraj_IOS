import Foundation

public enum ArabicTransliterator {
    private static let fatha: Character = "\u{064E}"
    private static let damma: Character = "\u{064F}"
    private static let kasra: Character = "\u{0650}"
    private static let fathatan: Character = "\u{064B}"
    private static let dammatan: Character = "\u{064C}"
    private static let kasratan: Character = "\u{064D}"
    private static let shadda: Character = "\u{0651}"
    private static let sukun: Character = "\u{0652}"
    private static let superscriptAlef: Character = "\u{0670}"

    private static let marks: Set<Character> = [
        fatha, damma, kasra, fathatan, dammatan, kasratan, shadda, sukun, superscriptAlef
    ]

    private static let consonants: [Character: String] = [
        "ب": "b", "ت": "t", "ث": "th", "ج": "j", "ح": "h", "خ": "kh", "د": "d",
        "ذ": "dh", "ر": "r", "ز": "z", "س": "s", "ش": "sh", "ص": "s", "ض": "d",
        "ط": "t", "ظ": "z", "ع": "'", "غ": "gh", "ف": "f", "ق": "q", "ك": "k",
        "ل": "l", "م": "m", "ن": "n", "ه": "h", "و": "w", "ي": "y", "ء": "'",
        "أ": "'", "إ": "'", "ؤ": "'", "ئ": "'", "ة": "t"
    ]
    private static let hamzas: Set<Character> = ["أ", "إ", "ؤ", "ئ", "ء"]
    private static let sunLetters: Set<Character> = ["ت", "ث", "د", "ذ", "ر", "ز", "س", "ش", "ص", "ض", "ط", "ظ", "ل", "ن"]
    private static let alefs: Set<Character> = ["ا", "ٱ"]
    private static let alefMadda: Character = "آ"
    private static let alefMaqsura: Character = "ى"
    private static let proclitics: [Character: String] = ["و": "w", "ف": "f", "ب": "b", "ك": "k", "ل": "l"]
    private static let punctuation: [String: String] = ["،": ",", "؛": ";", "؟": "?", ".": ".", ",": ",", ":": ":", "!": "!"]

    private static let functionWords: Set<String> = [
        "لا", "هو", "هي", "لم", "لن", "ما", "من", "عن", "على", "علي", "في", "فى", "له", "لها",
        "لك", "بك", "قد", "إن", "أن", "أنا", "إلى", "إلي", "إليه", "إليك", "أنت"
    ]

    private struct Letter {
        let ch: Character
        var marks: [Character]
    }

    private struct Rendered {
        var latin: String
        let shortEnd: Bool
        let tanweenEnd: String
        let taEnd: Bool
    }

    private struct Word {
        var latin: String
        let shortEnd: Bool
        let tanweenEnd: String
        let taEnd: Bool
        let joins: Bool
        let helper: Bool

        init(
            latin: String,
            shortEnd: Bool = false,
            tanweenEnd: String = "",
            taEnd: Bool = false,
            joins: Bool = false,
            helper: Bool = false
        ) {
            self.latin = latin
            self.shortEnd = shortEnd
            self.tanweenEnd = tanweenEnd
            self.taEnd = taEnd
            self.joins = joins
            self.helper = helper
        }

        init(_ r: Rendered, joins: Bool = false, helper: Bool = false) {
            self.init(latin: r.latin, shortEnd: r.shortEnd, tanweenEnd: r.tanweenEnd, taEnd: r.taEnd, joins: joins, helper: helper)
        }
    }

    public static func transliterate(_ arabicText: String) -> String {
        if arabicText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "" }
        let normalized = normalize(arabicText)
        let tokens = tokenize(normalized)
        var out: [String] = []
        var last: Word?

        for token in tokens {
            if let punct = punctuation[token] {
                if let prev = last, !out.isEmpty {
                    let prevOut = out[out.count - 1]
                    let prefix = String(prevOut.dropLast(prev.latin.count))
                    out[out.count - 1] = prefix + pause(prev)
                }
                last = nil
                if !out.isEmpty && !punctuation.values.contains(where: { out[out.count - 1].hasSuffix($0) }) {
                    out[out.count - 1] += punct
                }
                continue
            }

            let words = renderWord(splitLetters(token))
            for var word in words {
                if word.latin.isEmpty { continue }
                if word.joins, last != nil, let prevStr = out.last, let prevChar = prevStr.last, "aiu".contains(prevChar) {
                    let joined = word.helper ? String(word.latin.dropFirst()) : word.latin
                    out[out.count - 1] = prevStr + joined
                    word.latin = joined
                } else {
                    out.append(word.latin)
                }
                last = word
            }
        }

        if let prev = last, !out.isEmpty {
            let prevOut = out[out.count - 1]
            let prefix = String(prevOut.dropLast(prev.latin.count))
            out[out.count - 1] = prefix + pause(prev)
        }

        var result = out.joined(separator: " ")
        result = capitalizeSentences(result)
        result = replaceRegex(result, pattern: "\\ballah", template: "Allah")
        return result.trimmingCharacters(in: CharacterSet(charactersIn: " ,;"))
    }

    private static func normalize(_ text: String) -> String {
        var t = replaceRegex(text, pattern: "\u{0640}([\u{064B}-\u{0652}]*)\u{0654}", template: "\u{0621}$1")
        t = t.replacingOccurrences(of: "\u{0654}", with: "\u{0621}")
        t = t.replacingOccurrences(of: "\u{0640}", with: "")
        t = t.replacingOccurrences(of: "\u{0657}", with: String(fathatan))
        t = t.replacingOccurrences(of: "\u{065E}", with: String(dammatan))
        t = t.replacingOccurrences(of: "\u{0656}", with: String(kasratan))
        t = t.replacingOccurrences(of: "\u{06E1}", with: String(sukun))
        t = replaceRegex(t, pattern: "[\u{06D6}\u{06D7}\u{06D8}\u{06DA}]", template: " ، ")
        t = replaceRegex(t, pattern: "[\u{0653}\u{06D9}\u{06DB}\u{06DC}\u{06DE}-\u{06E0}\u{06E2}-\u{06ED}]", template: "")
        t = replaceRegex(t, pattern: "\\s*[\u{0660}-\u{0669}]+\\s*", template: " . ")
        t = replaceRegex(t, pattern: "[0-9]+", template: "")
        t = replaceRegex(t, pattern: "[()\\[\\]{}\u{00AB}\u{00BB}\u{FD3E}\u{FD3F}\"\u{200E}\u{200F}-]", template: " ")
        t = replaceRegex(t, pattern: "([\u{064B}-\u{0650}\u{0652}\u{0670}])(\u{0651})", template: "$2$1")
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func tokenize(_ text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: "[^\\s،؛؟.,:!]+|[،؛؟.,:!]") else { return [] }
        let ns = text as NSString
        return regex.matches(in: text, range: NSRange(location: 0, length: ns.length)).map { ns.substring(with: $0.range) }
    }

    private static func replaceRegex(_ text: String, pattern: String, template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let range = NSRange(location: 0, length: (text as NSString).length)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: template)
    }

    private static func capitalizeSentences(_ text: String) -> String {
        var chars = Array(text)
        var capNext = true
        for i in chars.indices {
            let c = chars[i]
            if capNext && c >= "a" && c <= "z" {
                chars[i] = Character(String(c).uppercased())
                capNext = false
            } else if c == "." || c == "?" || c == "!" {
                capNext = true
            } else if !c.isWhitespace {
                capNext = false
            }
        }
        return String(chars)
    }

    private static func splitLetters(_ word: String) -> [Letter] {
        var out: [Letter] = []
        for scalar in word.unicodeScalars {
            let ch = Character(scalar)
            if marks.contains(ch) {
                if !out.isEmpty {
                    out[out.count - 1].marks.append(ch)
                }
            } else {
                out.append(Letter(ch: ch, marks: []))
            }
        }
        return out
    }

    private static func vowelOf(_ m: [Character]) -> String {
        if m.contains(fatha) { return "a" }
        if m.contains(damma) { return "u" }
        if m.contains(kasra) { return "i" }
        return ""
    }

    private static func tanweenOf(_ m: [Character]) -> String {
        if m.contains(fathatan) { return "an" }
        if m.contains(dammatan) { return "un" }
        if m.contains(kasratan) { return "in" }
        return ""
    }

    private static func bases(_ letters: [Letter]) -> String {
        String(letters.map(\.ch))
    }

    private static func renderLetters(_ letters: [Letter], wordInitial: Bool) -> Rendered {
        var s = ""
        var shortEnd = false
        var tanweenEnd = ""
        var taEnd = false

        for i in letters.indices {
            let letter = letters[i]
            let ch = letter.ch
            let m = letter.marks
            let prev = i > 0 ? letters[i - 1] : nil
            let prevVowel = prev.map { vowelOf($0.marks) } ?? ""
            let vowel = vowelOf(m)
            let tanween = tanweenOf(m)

            if ch == alefMadda {
                if i == 0 { s += "a" } else if prevVowel != "a" { s += "'a" }
                shortEnd = false; tanweenEnd = ""; taEnd = false
                continue
            }
            if alefs.contains(ch) {
                if i == 0 && !vowel.isEmpty {
                    s += vowel
                } else if let prev, !tanweenOf(prev.marks).isEmpty {
                    continue
                } else if let prev, prevVowel.isEmpty, !prev.marks.contains(sukun), !alefs.contains(prev.ch) {
                    s += "a"
                }
                shortEnd = false; tanweenEnd = ""; taEnd = false
                continue
            }
            if ch == alefMaqsura {
                if m.contains(superscriptAlef) || (prevVowel != "a" && (prev == nil || tanweenOf(prev!.marks).isEmpty)) {
                    s += "a"
                    shortEnd = false; tanweenEnd = ""; taEnd = false
                }
                continue
            }
            if ((ch == "و" && prevVowel == "u") || (ch == "ي" && prevVowel == "i")) && m.isEmpty {
                shortEnd = false; tanweenEnd = ""; taEnd = false
                continue
            }

            guard var base = consonants[ch] else { continue }
            if hamzas.contains(ch) && i == 0 && wordInitial { base = "" }
            let doubled = m.contains(shadda) && !(i == 0 && wordInitial)
            s += doubled ? (base + base) : base
            shortEnd = false; tanweenEnd = ""; taEnd = (ch == "ة")

            if m.contains(superscriptAlef) {
                s += "a"
            } else if !tanween.isEmpty {
                s += tanween
                tanweenEnd = tanween
            } else if !vowel.isEmpty {
                s += vowel
                shortEnd = true
            }
        }

        return Rendered(latin: s, shortEnd: shortEnd, tanweenEnd: tanweenEnd, taEnd: taEnd)
    }

    private static func renderWord(_ letters: [Letter]) -> [Word] {
        guard !letters.isEmpty else { return [] }
        var prefix = ""
        var rest = letters
        let firstVowel = vowelOf(rest[0].marks)

        if rest.count > 2, let pro = proclitics[rest[0].ch], !firstVowel.isEmpty, !rest[0].marks.contains(shadda) {
            let next = rest[1].ch
            if alefs.contains(next) || (rest[0].ch == "ل" && next == "ل") {
                prefix = pro + firstVowel
                rest = Array(rest.dropFirst())
                if prefix.first == "l" && rest[0].ch == "ل" {
                    rest = [Letter(ch: "ا", marks: [])] + rest
                }
            } else if (rest[0].ch == "و" || rest[0].ch == "ف") && firstVowel == "a" &&
                (hamzas.contains(next) || next == alefMadda || functionWords.contains(bases(Array(rest.dropFirst())))) {
                return [Word(latin: pro + "a")] + renderWord(Array(rest.dropFirst()))
            }
        }

        let b = Array(bases(rest))
        if prefix == "li", rest.count >= 3, alefs.contains(rest[0].ch), String(b[1...2]) == "له", rest[1].marks.contains(shadda) {
            var tail = renderLetters(Array(rest.dropFirst(2)), wordInitial: false)
            tail.latin = "lilla" + tail.latin
            return [Word(tail)]
        }

        if rest.count >= 4, alefs.contains(rest[0].ch), String(b[1...3]) == "لله", rest[2].marks.contains(shadda) {
            var tail = renderLetters(Array(rest.dropFirst(3)), wordInitial: false)
            if !prefix.isEmpty {
                tail.latin = prefix + "lla" + tail.latin
                return [Word(tail)]
            }
            tail.latin = "Alla" + tail.latin
            return [Word(tail, joins: true, helper: true)]
        }

        var article: (sound: String, tail: [Letter])?
        if rest.count >= 3, alefs.contains(rest[0].ch), rest[1].ch == "ل" {
            let lamMarks = rest[1].marks
            if vowelOf(lamMarks).isEmpty && !lamMarks.contains(shadda) {
                let third = rest[2]
                if third.marks.contains(shadda) && sunLetters.contains(third.ch), let c = consonants[third.ch] {
                    let cleaned = Letter(ch: third.ch, marks: third.marks.filter { $0 != shadda })
                    article = (c, [cleaned] + Array(rest.dropFirst(3)))
                } else {
                    article = ("l", Array(rest.dropFirst(2)))
                }
            } else if lamMarks.contains(shadda) {
                let cleaned = Letter(ch: "ل", marks: lamMarks.filter { $0 != shadda })
                article = ("l", [cleaned] + Array(rest.dropFirst(2)))
            }
        }

        if let article {
            var tail = renderLetters(article.tail, wordInitial: true)
            if !prefix.isEmpty {
                tail.latin = "\(prefix)\(article.sound)-\(tail.latin)"
                return [Word(tail)]
            }
            tail.latin = "a\(article.sound)-\(tail.latin)"
            return [Word(tail, joins: true, helper: true)]
        }

        if rest[0].ch == "ٱ" || (rest[0].ch == "ا" && rest[0].marks.isEmpty && rest.count > 1 && rest[1].marks.contains(sukun)) {
            var tail = renderLetters(Array(rest.dropFirst()), wordInitial: false)
            if !prefix.isEmpty {
                tail.latin = prefix + tail.latin
                return [Word(tail)]
            }
            tail.latin = "i" + tail.latin
            return [Word(tail, joins: true, helper: true)]
        }

        var body = renderLetters(rest, wordInitial: prefix.isEmpty)
        body.latin = prefix + body.latin
        return [Word(body)]
    }

    private static func pause(_ word: Word) -> String {
        var t = word.latin
        if !word.tanweenEnd.isEmpty {
            t = String(t.dropLast(word.tanweenEnd.count))
            if word.taEnd {
                t = String(t.dropLast()) + "h"
            } else if word.tanweenEnd == "an" {
                t += "a"
            }
        } else if word.shortEnd {
            let hasDoubledEnd = t.hasSuffix("yya") || t.hasSuffix("yyi") || t.hasSuffix("yyu")
                || t.hasSuffix("wwa") || t.hasSuffix("wwi") || t.hasSuffix("wwu")
            if !hasDoubledEnd {
                t = String(t.dropLast())
                if word.taEnd {
                    t = String(t.dropLast()) + "h"
                }
            }
        }
        return t
    }
}
