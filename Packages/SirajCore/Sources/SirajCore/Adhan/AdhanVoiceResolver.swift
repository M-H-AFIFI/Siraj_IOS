import Foundation

public enum AdhanVoiceResolver {
    public static func findRecording(id: String) -> AdhanVoice? {
        let wanted = id.trimmingCharacters(in: .whitespacesAndNewlines)
        return AdhanCatalog.allRecordings.first { $0.id.caseInsensitiveCompare(wanted) == .orderedSame }
    }

    public static func findVoice(_ identifier: String) -> AdhanVoice {
        if let exact = findRecording(id: identifier) { return exact }
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()
        if lower.hasSuffix(AdhanCatalog.fajrSuffix.trimmingCharacters(in: .whitespaces).lowercased()) {
            let baseName = String(trimmed.dropLast(AdhanCatalog.fajrSuffix.trimmingCharacters(in: .whitespaces).count)).trimmingCharacters(in: .whitespaces)
            let base = findVoice(baseName)
            if let fajrId = base.fajrVoiceId, let fajr = findRecording(id: fajrId) {
                return fajr
            }
            return base
        }

        let match = AdhanCatalog.voices.first { v in
            let id = v.id.lowercased()
            let file = v.fileName.lowercased()
            if lower.contains("madin") || lower.contains("مدينة") { return id.contains("madin") }
            if lower.contains("aqsa") || lower.contains("أقصى") || lower.contains("اقصى") { return id.contains("aqsa") }
            if lower.contains("basit") || lower.contains("باسط") { return id.contains("basit") }
            if lower.contains("minshawi") || lower.contains("منشاوي") { return id.contains("minshawi") }
            if lower.contains("alafasy") || lower.contains("mishary") || lower.contains("عفاسي") || lower.contains("مشاري") { return id.contains("alafasy") }
            if lower.contains("nafees") || lower.contains("نفيس") { return id.contains("nafees") }
            if lower.contains("zahrani") || lower.contains("زهراني") { return id.contains("zahrani") }
            if lower.contains("naghshbandi") || lower.contains("naqshbandi") || lower.contains("نقشبند") { return id.contains("naghshbandi") }
            if lower.contains("yusuf") || lower.contains("يوسف") { return id.contains("yusuf") }
            if lower.contains("makkah") || lower.contains("mecca") || lower.contains("مكة") || lower == "default" {
                return id.contains("mecca") || id.contains("makkah")
            }
            return id.contains(lower) || file.contains(lower)
        }
        return match ?? AdhanCatalog.voices[0]
    }

    public static func fajrVoice(for voiceId: String, preferredFajrId: String = "") -> AdhanVoice {
        let pick = preferredFajrId.trimmingCharacters(in: .whitespacesAndNewlines)
        if !pick.isEmpty {
            if let exact = findRecording(id: pick), exact.isFajr { return exact }
            let base = findVoice(pick)
            if let fId = base.fajrVoiceId, let f = findRecording(id: fId) { return f }
        }
        let voice = findVoice(voiceId)
        if let fId = voice.fajrVoiceId, let f = findRecording(id: fId) { return f }
        if !voice.group.isEmpty, let grpFajr = AdhanCatalog.fajrRecordings.first(where: { $0.group == voice.group }) {
            return grpFajr
        }
        let def = findVoice(AdhanCatalog.defaultVoiceId)
        if let fId = def.fajrVoiceId, let f = findRecording(id: fId) { return f }
        return AdhanCatalog.fajrRecordings[0]
    }

    /// Resolves the <=30s `.caf` notification clip name guaranteed to exist in the bundle or `Library/Sounds/`.
    /// Falls back cleanly to `Adhan-Makkah.caf` if a remote voice has not yet been downloaded locally.
    public static func notificationSoundName(
        voiceId: String,
        prayer: PrayerType,
        fajrAdhanEnabled: Bool,
        preferredFajrId: String = "",
        availableSoundFiles: Set<String>
    ) -> String {
        if prayer == .fajr && fajrAdhanEnabled {
            let fajr = fajrVoice(for: voiceId, preferredFajrId: preferredFajrId)
            if availableSoundFiles.contains(fajr.cafFileName) {
                return fajr.cafFileName
            }
        }
        let chosen = findVoice(voiceId)
        if chosen.isBundled || availableSoundFiles.contains(chosen.cafFileName) {
            return chosen.cafFileName
        }
        return AdhanCatalog.defaultBundledCaf
    }
}
