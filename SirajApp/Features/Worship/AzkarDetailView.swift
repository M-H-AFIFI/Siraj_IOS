import SwiftUI
import UIKit
import SirajCore

struct AzkarDetailView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    let worshipStore: WorshipStore
    let categoryKey: String

    @State private var showResetAlert = false

    private var allItems: [AzkarItem] {
        worshipStore.catalog.items(forCategoryKey: categoryKey)
    }

    private var title: String {
        worshipStore.catalog.title(forCategoryKey: categoryKey, language: theme.language)
    }

    private var completedCount: Int {
        allItems.filter { worshipStore.count(for: categoryKey, itemId: $0.id) >= $0.count }.count
    }

    private var hasProgress: Bool {
        allItems.contains { worshipStore.count(for: categoryKey, itemId: $0.id) > 0 }
    }

    private var allDone: Bool {
        !allItems.isEmpty && completedCount == allItems.count
    }

    private var displayedItems: [AzkarItem] {
        if appState.settings.isHideCompletedAzkar {
            return allItems.filter { worshipStore.count(for: categoryKey, itemId: $0.id) < $0.count }
        }
        return allItems
    }

    private var sharedCommentary: String? {
        guard appState.settings.isShowVirtues, displayedItems.count > 1 else { return nil }
        let values = displayedItems.map { ($0.localizedCommentary(language: theme.language) ?? "").trimmingCharacters(in: .whitespacesAndNewlines) }
        guard let first = values.first, !first.isEmpty, values.allSatisfy({ $0 == first }) else { return nil }
        return first
    }

    var body: some View {
        let total = allItems.count
        let progress = total > 0 ? Double(completedCount) / Double(total) : 0
        let positions = Dictionary(uniqueKeysWithValues: allItems.enumerated().map { ($0.element.id, $0.offset + 1) })

        VStack(spacing: 0) {
            if total > 0 {
                setProgressHeader(progress: progress)
            }

            if appState.settings.isHideCompletedAzkar && displayedItems.isEmpty && total > 0 {
                Spacer()
                AllDoneAzkarCard {
                    worshipStore.resetAzkar(categoryKey: categoryKey)
                }
                .padding(.horizontal, 24)
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            if let sharedCommentary {
                                AzkarCommentaryBanner(commentary: sharedCommentary)
                                    .id("shared_commentary")
                            }

                            ForEach(displayedItems) { item in
                                let current = worshipStore.count(for: categoryKey, itemId: item.id)
                                let completed = current >= item.count

                                AzkarDhikrCard(
                                    item: item,
                                    position: positions[item.id] ?? 0,
                                    currentCount: current,
                                    isCompleted: completed,
                                    showCommentary: sharedCommentary == nil,
                                    showTranslation: appState.settings.isShowTranslation,
                                    showTransliteration: appState.settings.isShowTransliteration && appState.settings.isShowTranslation,
                                    showVirtues: appState.settings.isShowVirtues,
                                    onTapCount: {
                                        handleCountTap(item: item, proxy: proxy)
                                    }
                                )
                                .id(item.id)
                            }

                            if allDone && !appState.settings.isHideCompletedAzkar {
                                AllDoneAzkarCard {
                                    worshipStore.resetAzkar(categoryKey: categoryKey)
                                    if let firstId = allItems.first?.id {
                                        scrollTo(proxy: proxy, id: firstId)
                                    }
                                }
                                .id("all_done")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        .padding(.bottom, 128)
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
        .background(Color.clear)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    Text(title)
                        .font(theme.scaledFont(size: 16.5, weight: .black))
                        .foregroundStyle(theme.onSurface)
                        .lineLimit(1)
                    if total > 0 {
                        Text("\(theme.digits(String(completedCount))) / \(theme.digits(String(total)))")
                            .font(theme.scaledFont(size: 11.5, weight: .bold))
                            .foregroundStyle(theme.primary)
                    }
                }
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    if !theme.language.hasPrefix("ar") {
                        Toggle(theme.t("settings_show_translation"), isOn: Binding(
                            get: { appState.settings.isShowTranslation },
                            set: { v in appState.updateSettings { $0.isShowTranslation = v } }
                        ))
                        if appState.settings.isShowTranslation {
                            Toggle(theme.t("settings_show_transliteration"), isOn: Binding(
                                get: { appState.settings.isShowTransliteration },
                                set: { v in appState.updateSettings { $0.isShowTransliteration = v } }
                            ))
                        }
                    }
                    Toggle(theme.t("settings_show_virtues"), isOn: Binding(
                        get: { appState.settings.isShowVirtues },
                        set: { v in appState.updateSettings { $0.isShowVirtues = v } }
                    ))
                    Toggle(theme.t("settings_hide_completed_title"), isOn: Binding(
                        get: { appState.settings.isHideCompletedAzkar },
                        set: { v in appState.updateSettings { $0.isHideCompletedAzkar = v } }
                    ))
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(theme.onSurface)
                }

                Button {
                    showResetAlert = true
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundStyle(hasProgress ? theme.onSurface : theme.outline.opacity(0.45))
                }
                .disabled(!hasProgress)
                .accessibilityLabel(theme.t("azkar_reset_all"))
            }
        }
        .alert(theme.t("adhkar_reset_title"), isPresented: $showResetAlert) {
            Button(theme.t("adhkar_cancel"), role: .cancel) {}
            Button(theme.t("adhkar_reset_confirm"), role: .destructive) {
                worshipStore.resetAzkar(categoryKey: categoryKey)
            }
        } message: {
            Text(theme.t("adhkar_reset_message"))
        }
        .onAppear {
            worshipStore.refreshForToday()
        }
    }

    private func setProgressHeader(progress: Double) -> some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(theme.primary.opacity(0.15))
                    Capsule()
                        .fill(allDone ? theme.tertiary : theme.primary)
                        .frame(width: max(0, geo.size.width * progress))
                        .animation(theme.motionEnabled ? .easeInOut(duration: 0.35) : nil, value: progress)
                }
            }
            .frame(height: 5)

            if !hasProgress {
                Text(theme.t("adhkar_tap_hint"))
                    .font(theme.scaledFont(size: 12))
                    .foregroundStyle(theme.outline)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 6)
    }

    private func handleCountTap(item: AzkarItem, proxy: ScrollViewProxy) {
        let result = worshipStore.incrementAzkar(categoryKey: categoryKey, item: item)
        if !result.ignored && appState.settings.isHapticEnabled {
            if result.justCompleted {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }

        guard result.justCompleted else { return }

        if let idx = allItems.firstIndex(where: { $0.id == item.id }) {
            let remainingBelow = allItems.dropFirst(idx + 1).first { nextItem in
                worshipStore.count(for: categoryKey, itemId: nextItem.id) < nextItem.count
            }
            if let nextItem = remainingBelow {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(120))
                    scrollTo(proxy: proxy, id: nextItem.id)
                }
            } else if allDone && !appState.settings.isHideCompletedAzkar {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(160))
                    scrollTo(proxy: proxy, id: "all_done")
                }
            }
        }
    }

    private func scrollTo<ID: Hashable>(proxy: ScrollViewProxy, id: ID) {
        if theme.motionEnabled {
            withAnimation(.easeInOut(duration: 0.42)) {
                proxy.scrollTo(id, anchor: .top)
            }
        } else {
            proxy.scrollTo(id, anchor: .top)
        }
    }
}

private struct AzkarDhikrCard: View {
    @Environment(\.sirajTheme) private var theme
    let item: AzkarItem
    let position: Int
    let currentCount: Int
    let isCompleted: Bool
    let showCommentary: Bool
    let showTranslation: Bool
    let showTransliteration: Bool
    let showVirtues: Bool
    let onTapCount: () -> Void

    @State private var ringScale: CGFloat = 1.0

    private var isArabic: Bool {
        theme.language.hasPrefix("ar")
    }

    private var labels: (pronunciation: String, meaning: String, virtue: String) {
        let lang = SirajLocalizer.baseLanguage(theme.language)
        switch lang {
        case "ar": return ("النطق", "المعنى", "الفضل والهدي")
        case "ur": return ("تلفظ", "مفہوم", "فضیلت اور طریقہ")
        case "tr": return ("Okunuşu", "Anlamı", "Fazileti ve uygulanışı")
        default: return ("Pronunciation", "Meaning", "Virtue & practice")
        }
    }

    private var shareText: String {
        var parts = [item.text]
        if let tr = item.localizedTranslation(language: theme.language), !tr.isEmpty {
            parts.append(tr)
        }
        if let ref = item.localizedReference(language: theme.language), !ref.isEmpty {
            parts.append("(\(ref))")
        }
        return parts.joined(separator: "\n\n")
    }

    var body: some View {
        let contentAlpha: Double = isCompleted ? 0.55 : 1.0
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)

        VStack(alignment: .leading, spacing: 0) {
            if position > 0 || item.count > 1 {
                HStack {
                    if position > 0 {
                        ZStack {
                            Circle()
                                .fill(theme.primary.opacity(0.12))
                                .frame(width: 26, height: 26)
                            Text(theme.digits(String(position)))
                                .font(theme.scaledFont(size: 12, weight: .bold))
                                .foregroundStyle(theme.primary)
                        }
                    }
                    Spacer()
                    if item.count > 1 {
                        Text(repeatLabel(count: item.count))
                            .font(theme.scaledFont(size: 12, weight: .semibold))
                            .foregroundStyle(theme.onSecondaryContainer)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(theme.secondaryContainer.opacity(0.65)))
                    }
                }
                .opacity(contentAlpha)
                .padding(.bottom, 10)
            }

            dhikrArabicText
                .opacity(contentAlpha)

            if !isCompleted {
                VStack(alignment: .leading, spacing: 8) {
                    if !isArabic {
                        if showTransliteration, let translit = item.localizedTransliteration(language: theme.language) {
                            AzkarInfoBlock(
                                label: labels.pronunciation,
                                text: translit,
                                labelColor: theme.primary,
                                background: theme.primaryContainer.opacity(0.24),
                                italic: true
                            )
                        }
                        if showTranslation, let translation = item.localizedTranslation(language: theme.language) {
                            AzkarInfoBlock(
                                label: labels.meaning,
                                text: translation,
                                labelColor: theme.outline,
                                background: theme.surfaceVariant.opacity(0.38),
                                italic: false
                            )
                        }
                    }

                    if showCommentary && showVirtues, let virtue = item.localizedCommentary(language: theme.language) {
                        AzkarVirtueBlock(label: labels.virtue, text: virtue)
                    }
                }
                .padding(.top, 12)
                .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }

            HStack(spacing: 10) {
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(theme.onSurfaceVariant.opacity(0.75))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(theme.t("adhkar_share_title"))

                if let reference = item.localizedReference(language: theme.language) {
                    HStack(spacing: 6) {
                        Image(systemName: "book")
                            .font(.system(size: 12))
                            .foregroundStyle(theme.outline)
                        Text(reference)
                            .font(theme.scaledFont(size: 11.5))
                            .foregroundStyle(theme.outline)
                            .lineLimit(2)
                    }
                    .opacity(contentAlpha)
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Spacer()
                }

                AzkarCounterRing(
                    current: currentCount,
                    target: item.count,
                    isCompleted: isCompleted,
                    scale: ringScale
                )
            }
            .padding(.top, 12)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background {
            if isCompleted {
                shape.fill(theme.primary.opacity(theme.isGlass ? 0.14 : 0.08))
            }
        }
        .sirajCardSurface(cornerRadius: 24, isElevated: false)
        .overlay(
            shape.strokeBorder(
                isCompleted ? theme.primary.opacity(0.60) : Color.clear,
                lineWidth: isCompleted ? 1.5 : 0
            )
        )
        .contentShape(shape)
        .onTapGesture {
            onTapCount()
            if theme.motionEnabled {
                withAnimation(.easeOut(duration: 0.08)) { ringScale = 0.9 }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(80))
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.65)) { ringScale = 1.0 }
                }
            }
        }
        .animation(theme.motionEnabled ? .easeInOut(duration: 0.36) : nil, value: isCompleted)
    }

    private var dhikrArabicText: some View {
        let attr = buildAttributedDhikr()
        return Text(attr)
            .font(item.isQuranic ? theme.hafsFont(size: 23) : theme.amiriFont(size: 23))
            .lineSpacing(12)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .environment(\.layoutDirection, .rightToLeft)
    }

    private func buildAttributedDhikr() -> AttributedString {
        var str = AttributedString(item.text)
        str.foregroundColor = theme.onSurface
        guard item.isQuranic else { return str }
        if let regex = try? NSRegularExpression(pattern: "(?<=^|\\s)([٠-٩]{1,3})(?=\\s|$)") {
            let ns = item.text as NSString
            let matches = regex.matches(in: item.text, range: NSRange(location: 0, length: ns.length))
            for match in matches {
                if let range = Range(match.range, in: item.text),
                   let attrRange = Range(range, in: str) {
                    str[attrRange].foregroundColor = theme.primary
                }
            }
        }
        return str
    }

    private func repeatLabel(count: Int) -> String {
        let digits = theme.digits(String(count))
        let lang = SirajLocalizer.baseLanguage(theme.language)
        switch lang {
        case "ar":
            if count == 2 { return "مرتان" }
            if (3...10).contains(count) { return "\(digits) مرات" }
            return "\(digits) مرة"
        case "ur":
            return "\(digits) بار"
        case "tr":
            return "\(count) kez"
        default:
            return "\(count) times"
        }
    }
}

private struct AzkarInfoBlock: View {
    @Environment(\.sirajTheme) private var theme
    let label: String
    let text: String
    let labelColor: Color
    let background: Color
    let italic: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(theme.scaledFont(size: 11.5, weight: .bold))
                .foregroundStyle(labelColor)
            Text(text)
                .font(italic ? theme.scaledFont(size: 14).italic() : theme.scaledFont(size: 14))
                .foregroundStyle(italic ? theme.onSurfaceVariant : theme.onSurface.opacity(0.9))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(background))
    }
}

private struct AzkarVirtueBlock: View {
    @Environment(\.sirajTheme) private var theme
    let label: String
    let text: String

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(theme.tertiary.opacity(0.55))
                .frame(width: 3)
                .padding(.vertical, 10)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image("ic_siraj_hadith")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(theme.tertiary)
                    Text(label)
                        .font(theme.scaledFont(size: 11.5, weight: .bold))
                        .foregroundStyle(theme.tertiary)
                }
                Text(text)
                    .font(theme.scaledFont(size: 13))
                    .foregroundStyle(theme.onSurfaceVariant)
                    .lineSpacing(4)
            }
            .padding(.leading, 11)
            .padding(.trailing, 12)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.tertiary.opacity(0.08)))
    }
}

private struct AzkarCounterRing: View {
    @Environment(\.sirajTheme) private var theme
    let current: Int
    let target: Int
    let isCompleted: Bool
    let scale: CGFloat

    var body: some View {
        let fraction = target > 0 ? min(1.0, max(0.0, Double(current) / Double(target))) : 0
        let currentStr = theme.digits(String(current))
        let targetStr = theme.digits(String(target))

        ZStack {
            Circle()
                .fill(isCompleted ? theme.primary : theme.primary.opacity(0.06))

            Circle()
                .stroke(theme.primary.opacity(0.16), lineWidth: 4)
                .padding(2)

            if fraction > 0 {
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(theme.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(2)
                    .animation(theme.motionEnabled ? .easeInOut(duration: 0.25) : nil, value: fraction)
            }

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(theme.onPrimary)
                    .transition(.scale.combined(with: .opacity))
            } else if target <= 1 {
                Image(systemName: "hand.tap")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(theme.primary)
            } else {
                VStack(spacing: 1) {
                    Text(currentStr)
                        .font(theme.scaledFont(size: currentStr.count > 2 ? 13 : 16, weight: .black))
                        .foregroundStyle(theme.primary)
                        .lineLimit(1)
                    Rectangle()
                        .fill(theme.primary.opacity(0.4))
                        .frame(width: 16, height: 1)
                    Text(targetStr)
                        .font(theme.scaledFont(size: 10, weight: .bold))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .lineLimit(1)
                }
            }
        }
        .frame(width: 58, height: 58)
        .scaleEffect(scale)
    }
}

private struct AzkarCommentaryBanner: View {
    @Environment(\.sirajTheme) private var theme
    let commentary: String

    private var heading: String {
        let lang = SirajLocalizer.baseLanguage(theme.language)
        switch lang {
        case "ar": return "الشرح والفضائل"
        case "ur": return "تشریح اور فضائل"
        case "tr": return "Açıklama ve Faziletleri"
        default: return "Virtue & Guidance"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image("ic_siraj_hadith")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 15, height: 15)
                    .foregroundStyle(theme.primary)
                Text(heading)
                    .font(theme.scaledFont(size: 12.5, weight: .bold))
                    .foregroundStyle(theme.primary)
            }
            Text(commentary)
                .font(theme.scaledFont(size: 13.5))
                .foregroundStyle(theme.onSurfaceVariant)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .sirajCardSurface(cornerRadius: 20)
    }
}

private struct AllDoneAzkarCard: View {
    @Environment(\.sirajTheme) private var theme
    let onRestart: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(theme.primary)

            Text(theme.t("azkar_all_done_title"))
                .font(theme.scaledFont(size: 20, weight: .black))
                .foregroundStyle(theme.onSurface)
                .multilineTextAlignment(.center)

            Text(theme.t("azkar_all_done_desc"))
                .font(theme.scaledFont(size: 14))
                .foregroundStyle(theme.onSurfaceVariant)
                .multilineTextAlignment(.center)

            Button(action: onRestart) {
                Label(theme.t("azkar_reset_and_restart"), systemImage: "arrow.counterclockwise")
                    .font(theme.scaledFont(size: 14.5, weight: .bold))
                    .foregroundStyle(theme.onPrimary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(theme.primary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(26)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(theme.primaryContainer.opacity(theme.isGlass ? 0.14 : 0.42))
        )
        .sirajCardSurface(cornerRadius: 28, isElevated: true)
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(theme.primary.opacity(0.32), lineWidth: 1.5)
        )
    }
}
