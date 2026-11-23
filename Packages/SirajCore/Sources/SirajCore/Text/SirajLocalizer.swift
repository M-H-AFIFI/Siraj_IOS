import Foundation

private struct LocaleBundlePayload: Codable {
    let strings: [String: String]
    let plurals: [String: [String: String]]?
    let arrays: [String: [String]]?
}

public final class SirajLocalizer: @unchecked Sendable {
    public static let supportedLanguages: [String] = ["en", "ar", "tr", "ur"]

    private let tables: [String: [String: String]]
    private let plurals: [String: [String: [String: String]]]
    private let arrays: [String: [String: [String]]]

    public init(
        tables: [String: [String: String]],
        plurals: [String: [String: [String: String]]] = [:],
        arrays: [String: [String: [String]]] = [:]
    ) {
        self.tables = tables
        self.plurals = plurals
        self.arrays = arrays
    }

    public convenience init(bundle: Bundle, subdirectory: String? = "Data") {
        var loadedStrings: [String: [String: String]] = [:]
        var loadedPlurals: [String: [String: [String: String]]] = [:]
        var loadedArrays: [String: [String: [String]]] = [:]

        for lang in Self.supportedLanguages {
            let url = bundle.url(forResource: lang, withExtension: "json", subdirectory: subdirectory)
                ?? bundle.url(forResource: lang, withExtension: "json")
            if let url, let data = try? Data(contentsOf: url),
               let payload = try? JSONDecoder().decode(LocaleBundlePayload.self, from: data) {
                loadedStrings[lang] = payload.strings
                loadedPlurals[lang] = payload.plurals ?? [:]
                loadedArrays[lang] = payload.arrays ?? [:]
            }
        }
        self.init(tables: loadedStrings, plurals: loadedPlurals, arrays: loadedArrays)
    }

    public static func baseLanguage(_ language: String) -> String {
        let code = String(language.trimmingCharacters(in: .whitespacesAndNewlines).prefix(2)).lowercased()
        return supportedLanguages.contains(code) ? code : "en"
    }

    public static func isRTL(_ language: String) -> Bool {
        let base = baseLanguage(language)
        return base == "ar" || base == "ur"
    }

    public func isRTL(_ language: String) -> Bool {
        Self.isRTL(language)
    }

    public func string(_ key: String, lang: String) -> String {
        let base = Self.baseLanguage(lang)
        if let value = tables[base]?[key] { return value }
        if let fallback = tables["en"]?[key] { return fallback }
        return key
    }

    /// Safe positional formatting for `{0}`, `{1}`, `{0:.1f}` tokens without printf crashes.
    public func format(_ key: String, lang: String, _ args: Any...) -> String {
        formatTemplate(string(key, lang: lang), args: args)
    }

    public func formatArray(_ key: String, lang: String, args: [Any]) -> String {
        formatTemplate(string(key, lang: lang), args: args)
    }

    public func plural(_ key: String, count: Int, lang: String, _ args: Any...) -> String {
        let base = Self.baseLanguage(lang)
        let forms = plurals[base]?[key] ?? plurals["en"]?[key] ?? [:]
        let quantity = Self.pluralQuantity(count: count, lang: base)
        let template = forms[quantity] ?? forms["other"] ?? string(key, lang: lang)
        let allArgs = args.isEmpty ? [count] : args
        return formatTemplate(template, args: allArgs)
    }

    public func array(_ key: String, lang: String) -> [String] {
        let base = Self.baseLanguage(lang)
        return arrays[base]?[key] ?? arrays["en"]?[key] ?? []
    }

    public func formatTemplate(_ template: String, args: [Any]) -> String {
        var output = ""
        output.reserveCapacity(template.count + 16)
        let chars = Array(template)
        var i = 0
        while i < chars.count {
            let ch = chars[i]
            if ch == "{" {
                if i + 1 < chars.count && chars[i + 1] == "{" {
                    output.append("{")
                    i += 2
                    continue
                }
                if let close = chars[(i + 1)...].firstIndex(of: "}") {
                    let token = String(chars[(i + 1)..<close])
                    if let replacement = resolveToken(token, args: args) {
                        output.append(replacement)
                        i = close + 1
                        continue
                    }
                }
            } else if ch == "}" && i + 1 < chars.count && chars[i + 1] == "}" {
                output.append("}")
                i += 2
                continue
            }
            output.append(ch)
            i += 1
        }
        return output
    }

    private func resolveToken(_ token: String, args: [Any]) -> String? {
        let parts = token.split(separator: ":", maxSplits: 1)
        guard let idx = Int(parts[0]) else { return nil }
        guard idx >= 0 && idx < args.count else { return "" }
        let value = args[idx]
        if parts.count == 2, parts[1].hasPrefix("."), parts[1].hasSuffix("f"),
           let decimals = Int(parts[1].dropFirst().dropLast()) {
            let num: Double?
            if let d = value as? Double { num = d }
            else if let f = value as? Float { num = Double(f) }
            else if let n = value as? Int { num = Double(n) }
            else { num = Double("\(value)") }
            if let num {
                return String(format: "%.\(decimals)f", num)
            }
        }
        return "\(value)"
    }

    private static func pluralQuantity(count: Int, lang: String) -> String {
        let n = abs(count)
        if lang == "ar" {
            if n == 0 { return "zero" }
            if n == 1 { return "one" }
            if n == 2 { return "two" }
            let mod100 = n % 100
            if mod100 >= 3 && mod100 <= 10 { return "few" }
            if mod100 >= 11 && mod100 <= 99 { return "many" }
            return "other"
        }
        return n == 1 ? "one" : "other"
    }
}
