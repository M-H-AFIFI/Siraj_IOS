import AudioToolbox
import Foundation
import Observation
import UIKit
import SirajCore

@MainActor
@Observable
final class WorshipStore {
    let catalog: AzkarCatalog
    let allahNames: [AllahName]

    var azkarProgress: [String: [Int: Int]] = [:]
    var progressDateISO: String = ""
    var tasbih: TasbihSnapshot = TasbihSnapshot()

    private let userStore: UserDataStore

    init(userStore: UserDataStore, bundle: Bundle = .main) {
        self.userStore = userStore

        let azkarURL = bundle.url(forResource: "azkar", withExtension: "json", subdirectory: "Data")
            ?? bundle.url(forResource: "azkar", withExtension: "json")
        let hisnURL = bundle.url(forResource: "hisn_chapters", withExtension: "json", subdirectory: "Data")
            ?? bundle.url(forResource: "hisn_chapters", withExtension: "json")
        let namesURL = bundle.url(forResource: "allah_names", withExtension: "json", subdirectory: "Data")
            ?? bundle.url(forResource: "allah_names", withExtension: "json")

        if let azkarURL, let azkarData = try? Data(contentsOf: azkarURL) {
            let hisnData = hisnURL.flatMap { try? Data(contentsOf: $0) }
            self.catalog = AzkarCatalog.parse(azkarData: azkarData, hisnTitlesData: hisnData)
        } else {
            self.catalog = .empty
        }

        if let namesURL, let namesData = try? Data(contentsOf: namesURL) {
            self.allahNames = AllahNamesCatalog.parse(namesData)
        } else {
            self.allahNames = []
        }

        refreshForToday()
    }

    static func todayISO(date: Date = Date()) -> String {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", comps.year ?? 2026, comps.month ?? 1, comps.day ?? 1)
    }

    func refreshForToday() {
        let today = Self.todayISO()
        if progressDateISO != today {
            progressDateISO = today
            azkarProgress = userStore.loadAzkarProgress(for: today)
        }
        var loadedTasbih = userStore.loadTasbihSnapshot()
        if loadedTasbih.lastDateISO != today {
            loadedTasbih.todayTotal = 0
            loadedTasbih.lastDateISO = today
            userStore.saveTasbihSnapshot(loadedTasbih)
        }
        tasbih = loadedTasbih
    }

    func completion(for category: AzkarCategory) -> AzkarCompletion {
        let items = catalog.items(forCategoryKey: category.rawValue)
        guard !items.isEmpty else { return .none }
        let counts = azkarProgress[category.rawValue] ?? [:]
        let done = items.filter { (counts[$0.id] ?? 0) >= $0.count }.count
        return AzkarCompletion(done: done, total: items.count)
    }

    func count(for categoryKey: String, itemId: Int) -> Int {
        azkarProgress[categoryKey]?[itemId] ?? 0
    }

    /// Returns `(ignored, justCompleted)` so the caller can play matching haptics and advance focus.
    func incrementAzkar(categoryKey: String, item: AzkarItem) -> (ignored: Bool, justCompleted: Bool) {
        refreshForToday()
        var map = azkarProgress[categoryKey] ?? [:]
        let current = map[item.id] ?? 0
        if current >= item.count {
            if item.count <= 1 {
                map.removeValue(forKey: item.id)
                azkarProgress[categoryKey] = map
                userStore.saveAzkarProgress(azkarProgress, for: progressDateISO)
                return (false, false)
            }
            return (true, false)
        }
        let next = current + 1
        map[item.id] = next
        azkarProgress[categoryKey] = map
        userStore.saveAzkarProgress(azkarProgress, for: progressDateISO)
        return (false, next >= item.count)
    }

    func resetAzkar(categoryKey: String) {
        refreshForToday()
        azkarProgress.removeValue(forKey: categoryKey)
        userStore.saveAzkarProgress(azkarProgress, for: progressDateISO)
    }

    // MARK: - Tasbih

    var allTasbihDhikrs: [TasbihDhikr] {
        TasbihDhikr.presets + tasbih.customDhikrs
    }

    var currentTasbihDhikr: TasbihDhikr {
        let list = allTasbihDhikrs
        guard !list.isEmpty else { return TasbihDhikr.presets[0] }
        let idx = min(max(0, tasbih.currentDhikrIndex), list.count - 1)
        return list[idx]
    }

    func incrementTasbih(haptics: Bool, sound: Bool) {
        refreshForToday()
        let goal = tasbih.goal
        let next = (goal > 0 && tasbih.count >= goal) ? 1 : tasbih.count + 1
        let completes = goal > 0 && next >= goal

        if haptics {
            if completes {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
        if sound {
            AudioServicesPlaySystemSound(1104)
        }

        tasbih.count = next
        tasbih.todayTotal += 1
        tasbih.lastDateISO = Self.todayISO()
        userStore.saveTasbihSnapshot(tasbih)
    }

    func resetTasbihRound() {
        tasbih.count = 0
        userStore.saveTasbihSnapshot(tasbih)
    }

    func setTasbihGoal(_ goal: Int) {
        tasbih.goal = max(1, goal)
        userStore.saveTasbihSnapshot(tasbih)
    }

    func selectTasbihDhikr(at index: Int) {
        let list = allTasbihDhikrs
        guard !list.isEmpty else { return }
        let clamped = (index % list.count + list.count) % list.count
        tasbih.currentDhikrIndex = clamped
        tasbih.count = 0
        tasbih.goal = list[clamped].defaultGoal
        userStore.saveTasbihSnapshot(tasbih)
    }

    func nextTasbihDhikr() {
        selectTasbihDhikr(at: tasbih.currentDhikrIndex + 1)
    }

    func previousTasbihDhikr() {
        selectTasbihDhikr(at: tasbih.currentDhikrIndex - 1)
    }

    func addCustomTasbihDhikr(_ arabic: String) {
        let trimmed = arabic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let custom = TasbihDhikr(arabic: trimmed, defaultGoal: 33, isCustom: true)
        tasbih.customDhikrs.append(custom)
        tasbih.currentDhikrIndex = TasbihDhikr.presets.count + tasbih.customDhikrs.count - 1
        tasbih.count = 0
        tasbih.goal = 33
        userStore.saveTasbihSnapshot(tasbih)
    }
}
