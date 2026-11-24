import Foundation
import Observation
import SwiftUI
import UIKit
import SirajCore

enum GuideGroup: String, CaseIterable, Identifiable {
    case quran
    case daily
    case yours

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .quran: return "guide_group_quran"
        case .daily: return "guide_group_daily"
        case .yours: return "guide_group_yours"
        }
    }
}

enum GuideIconKind {
    case asset(String)
    case system(String)
}

struct GuideStepSpec: Identifiable {
    let id: String
    let titleKey: String
    let bodyKey: String
    let symbol: String
    let accent: String?
}

enum GuideTopic: String, CaseIterable, Identifiable, Hashable {
    case reading, mushaf, search, listening, library, downloads, bookmarks, tafsir, khatma
    case adhkar, hadith, radio, prayer, qibla, tasbih, calendar
    case widgets, appearance

    var id: String { rawValue }

    var group: GuideGroup {
        switch self {
        case .reading, .mushaf, .search, .listening, .library, .downloads, .bookmarks, .tafsir, .khatma:
            return .quran
        case .adhkar, .hadith, .radio, .prayer, .qibla, .tasbih, .calendar:
            return .daily
        case .widgets, .appearance:
            return .yours
        }
    }

    var titleKey: String { "guide_topic_\(rawValue)" }
    var summaryKey: String { "guide_topic_\(rawValue)_summary" }

    var icon: GuideIconKind {
        switch self {
        case .reading: return .asset("ic_nav_quran")
        case .mushaf: return .system("book.pages")
        case .search: return .system("magnifyingglass")
        case .listening: return .system("play.circle.fill")
        case .library: return .system("headphones")
        case .downloads: return .system("arrow.down.circle")
        case .bookmarks: return .system("bookmark")
        case .tafsir: return .system("text.book.closed")
        case .khatma: return .asset("ic_quick_quran")
        case .adhkar: return .asset("ic_nav_azkar")
        case .hadith: return .asset("ic_siraj_hadith")
        case .radio: return .system("radio")
        case .prayer: return .asset("ic_nav_prayer")
        case .qibla: return .asset("ic_nav_qibla")
        case .tasbih: return .asset("ic_quick_tasbih")
        case .calendar: return .asset("ic_siraj_hijri_calendar")
        case .widgets: return .system("square.grid.2x2")
        case .appearance: return .system("paintpalette")
        }
    }

    var steps: [GuideStepSpec] {
        switch self {
        case .reading:
            return [
                GuideStepSpec(id: "r1", titleKey: "guide_reading_1_title", bodyKey: "guide_reading_1_body", symbol: "book.closed.fill", accent: "ic_nav_quran"),
                GuideStepSpec(id: "r2", titleKey: "guide_reading_2_title", bodyKey: "guide_reading_2_body", symbol: "list.bullet.indent", accent: nil),
                GuideStepSpec(id: "r3", titleKey: "guide_reading_3_title", bodyKey: "guide_reading_3_body", symbol: "book.pages.fill", accent: nil),
                GuideStepSpec(id: "r4", titleKey: "guide_reading_4_title", bodyKey: "guide_reading_4_body", symbol: "hand.draw.fill", accent: nil),
                GuideStepSpec(id: "r5", titleKey: "guide_reading_5_title", bodyKey: "guide_reading_5_body", symbol: "arrow.up.and.down.text.horizontal", accent: nil)
            ]
        case .mushaf:
            return [
                GuideStepSpec(id: "m1", titleKey: "guide_mushaf_1_title", bodyKey: "guide_mushaf_1_body", symbol: "books.vertical.fill", accent: nil),
                GuideStepSpec(id: "m2", titleKey: "guide_mushaf_2_title", bodyKey: "guide_mushaf_2_body", symbol: "text.alignright", accent: nil)
            ]
        case .search:
            return [
                GuideStepSpec(id: "s1", titleKey: "guide_search_1_title", bodyKey: "guide_search_1_body", symbol: "magnifyingglass", accent: nil),
                GuideStepSpec(id: "s2", titleKey: "guide_search_2_title", bodyKey: "guide_search_2_body", symbol: "number.circle.fill", accent: nil)
            ]
        case .listening:
            return [
                GuideStepSpec(id: "l1", titleKey: "guide_listening_1_title", bodyKey: "guide_listening_1_body", symbol: "play.circle.fill", accent: nil),
                GuideStepSpec(id: "l2", titleKey: "guide_listening_2_title", bodyKey: "guide_listening_2_body", symbol: "backward.end.fill", accent: nil),
                GuideStepSpec(id: "l3", titleKey: "guide_listening_3_title", bodyKey: "guide_listening_3_body", symbol: "person.wave.2.fill", accent: nil),
                GuideStepSpec(id: "l4", titleKey: "guide_listening_4_title", bodyKey: "guide_listening_4_body", symbol: "repeat.1", accent: nil),
                GuideStepSpec(id: "l5", titleKey: "guide_listening_5_title", bodyKey: "guide_listening_5_body", symbol: "waveform", accent: nil)
            ]
        case .library:
            return [
                GuideStepSpec(id: "lb1", titleKey: "guide_library_1_title", bodyKey: "guide_library_1_body", symbol: "headphones", accent: "ic_quick_listen"),
                GuideStepSpec(id: "lb2", titleKey: "guide_library_2_title", bodyKey: "guide_library_2_body", symbol: "person.3.fill", accent: nil),
                GuideStepSpec(id: "lb3", titleKey: "guide_library_3_title", bodyKey: "guide_library_3_body", symbol: "moon.zzz.fill", accent: nil),
                GuideStepSpec(id: "lb4", titleKey: "guide_library_4_title", bodyKey: "guide_library_4_body", symbol: "rectangle.bottomthird.inset.filled", accent: nil)
            ]
        case .downloads:
            return [
                GuideStepSpec(id: "d1", titleKey: "guide_downloads_1_title", bodyKey: "guide_downloads_1_body", symbol: "arrow.down.circle.fill", accent: nil),
                GuideStepSpec(id: "d2", titleKey: "guide_downloads_2_title", bodyKey: "guide_downloads_2_body", symbol: "internaldrive.fill", accent: nil)
            ]
        case .bookmarks:
            return [
                GuideStepSpec(id: "b1", titleKey: "guide_bookmarks_1_title", bodyKey: "guide_bookmarks_1_body", symbol: "bookmark.fill", accent: nil),
                GuideStepSpec(id: "b2", titleKey: "guide_bookmarks_2_title", bodyKey: "guide_bookmarks_2_body", symbol: "note.text.badge.plus", accent: nil),
                GuideStepSpec(id: "b3", titleKey: "guide_bookmarks_3_title", bodyKey: "guide_bookmarks_3_body", symbol: "list.star", accent: nil)
            ]
        case .tafsir:
            return [
                GuideStepSpec(id: "t1", titleKey: "guide_tafsir_1_title", bodyKey: "guide_tafsir_1_body", symbol: "hand.tap.fill", accent: nil),
                GuideStepSpec(id: "t2", titleKey: "guide_tafsir_2_title", bodyKey: "guide_tafsir_2_body", symbol: "text.book.closed.fill", accent: nil),
                GuideStepSpec(id: "t3", titleKey: "guide_tafsir_3_title", bodyKey: "guide_tafsir_3_body", symbol: "textformat.size", accent: nil)
            ]
        case .khatma:
            return [
                GuideStepSpec(id: "k1", titleKey: "guide_khatma_1_title", bodyKey: "guide_khatma_1_body", symbol: "calendar.badge.checkmark", accent: "ic_quick_quran"),
                GuideStepSpec(id: "k2", titleKey: "guide_khatma_2_title", bodyKey: "guide_khatma_2_body", symbol: "slider.horizontal.3", accent: nil),
                GuideStepSpec(id: "k3", titleKey: "guide_khatma_3_title", bodyKey: "guide_khatma_3_body", symbol: "checkmark.seal.fill", accent: nil)
            ]
        case .adhkar:
            return [
                GuideStepSpec(id: "a1", titleKey: "guide_adhkar_1_title", bodyKey: "guide_adhkar_1_body", symbol: "sparkles", accent: "ic_nav_azkar"),
                GuideStepSpec(id: "a2", titleKey: "guide_adhkar_2_title", bodyKey: "guide_adhkar_2_body", symbol: "sun.and.horizon.fill", accent: nil),
                GuideStepSpec(id: "a3", titleKey: "guide_adhkar_3_title", bodyKey: "guide_adhkar_3_body", symbol: "circle.dashed.inset.filled", accent: nil),
                GuideStepSpec(id: "a4", titleKey: "guide_adhkar_4_title", bodyKey: "guide_adhkar_4_body", symbol: "books.vertical.fill", accent: nil)
            ]
        case .hadith:
            return [
                GuideStepSpec(id: "h1", titleKey: "guide_hadith_1_title", bodyKey: "guide_hadith_1_body", symbol: "scroll.fill", accent: "ic_siraj_hadith"),
                GuideStepSpec(id: "h2", titleKey: "guide_hadith_2_title", bodyKey: "guide_hadith_2_body", symbol: "tag.fill", accent: nil),
                GuideStepSpec(id: "h3", titleKey: "guide_hadith_3_title", bodyKey: "guide_hadith_3_body", symbol: "square.and.arrow.up", accent: nil)
            ]
        case .radio:
            return [
                GuideStepSpec(id: "rd1", titleKey: "guide_radio_1_title", bodyKey: "guide_radio_1_body", symbol: "radio", accent: nil),
                GuideStepSpec(id: "rd2", titleKey: "guide_radio_2_title", bodyKey: "guide_radio_2_body", symbol: "dot.radiowaves.left.and.right", accent: nil),
                GuideStepSpec(id: "rd3", titleKey: "guide_radio_3_title", bodyKey: "guide_radio_3_body", symbol: "speaker.wave.2.fill", accent: nil)
            ]
        case .prayer:
            return [
                GuideStepSpec(id: "p1", titleKey: "guide_prayer_1_title", bodyKey: "guide_prayer_1_body", symbol: "clock.fill", accent: "ic_nav_prayer"),
                GuideStepSpec(id: "p2", titleKey: "guide_prayer_2_title", bodyKey: "guide_prayer_2_body", symbol: "location.fill", accent: nil),
                GuideStepSpec(id: "p3", titleKey: "guide_prayer_3_title", bodyKey: "guide_prayer_3_body", symbol: "bell.badge.fill", accent: nil)
            ]
        case .qibla:
            return [
                GuideStepSpec(id: "q1", titleKey: "guide_qibla_1_title", bodyKey: "guide_qibla_1_body", symbol: "safari.fill", accent: "ic_nav_qibla"),
                GuideStepSpec(id: "q2", titleKey: "guide_qibla_2_title", bodyKey: "guide_qibla_2_body", symbol: "location.north.line.fill", accent: nil)
            ]
        case .tasbih:
            return [
                GuideStepSpec(id: "ts1", titleKey: "guide_tasbih_1_title", bodyKey: "guide_tasbih_1_body", symbol: "circle.circle.fill", accent: "ic_quick_tasbih"),
                GuideStepSpec(id: "ts2", titleKey: "guide_tasbih_2_title", bodyKey: "guide_tasbih_2_body", symbol: "hand.tap.fill", accent: nil)
            ]
        case .calendar:
            return [
                GuideStepSpec(id: "c1", titleKey: "guide_calendar_1_title", bodyKey: "guide_calendar_1_body", symbol: "calendar", accent: "ic_siraj_hijri_calendar"),
                GuideStepSpec(id: "c2", titleKey: "guide_calendar_2_title", bodyKey: "guide_calendar_2_body", symbol: "moon.stars.fill", accent: nil),
                GuideStepSpec(id: "c3", titleKey: "guide_calendar_3_title", bodyKey: "guide_calendar_3_body", symbol: "sun.horizon.fill", accent: "ic_siraj_fasting")
            ]
        case .widgets:
            return [
                GuideStepSpec(id: "w1", titleKey: "guide_widgets_1_title", bodyKey: "guide_widgets_1_body", symbol: "square.grid.2x2.fill", accent: nil),
                GuideStepSpec(id: "w2", titleKey: "guide_widgets_2_title", bodyKey: "guide_widgets_2_body", symbol: "swatchpalette.fill", accent: nil),
                GuideStepSpec(id: "w3", titleKey: "guide_widgets_3_title", bodyKey: "guide_widgets_3_body", symbol: "plus.app.fill", accent: nil)
            ]
        case .appearance:
            return [
                GuideStepSpec(id: "ap1", titleKey: "guide_appearance_1_title", bodyKey: "guide_appearance_1_body", symbol: "paintpalette.fill", accent: nil),
                GuideStepSpec(id: "ap2", titleKey: "guide_appearance_live_title", bodyKey: "guide_appearance_live_body", symbol: "sparkles", accent: nil),
                GuideStepSpec(id: "ap3", titleKey: "guide_appearance_2_title", bodyKey: "guide_appearance_2_body", symbol: "moon.fill", accent: nil),
                GuideStepSpec(id: "ap4", titleKey: "guide_appearance_glass_title", bodyKey: "guide_appearance_glass_body", symbol: "rectangle.on.rectangle.angled", accent: nil),
                GuideStepSpec(id: "ap5", titleKey: "guide_appearance_3_title", bodyKey: "guide_appearance_3_body", symbol: "textformat.size", accent: nil)
            ]
        }
    }

    var next: GuideTopic? {
        let all = Self.allCases
        guard let idx = all.firstIndex(of: self), idx + 1 < all.count else { return nil }
        return all[idx + 1]
    }
}

@MainActor
@Observable
final class GuideStore {
    private let userStore: UserDataStore

    var completedTopicIds: Set<String> = []
    var tipsEnabled: Bool = true

    init(userStore: UserDataStore) {
        self.userStore = userStore
        let rec = userStore.loadGuideProgress()
        self.completedTopicIds = Set(rec.completedTopics)
        self.tipsEnabled = rec.tipsEnabled
    }

    func markCompleted(_ topic: GuideTopic) {
        guard !completedTopicIds.contains(topic.id) else { return }
        completedTopicIds.insert(topic.id)
        persist()
    }

    func setTipsEnabled(_ enabled: Bool) {
        tipsEnabled = enabled
        persist()
    }

    var nextUnfinishedTopic: GuideTopic {
        GuideTopic.allCases.first { !completedTopicIds.contains($0.id) } ?? .reading
    }

    var allDone: Bool {
        completedTopicIds.count >= GuideTopic.allCases.count
    }

    private func persist() {
        userStore.saveGuideProgress(
            UserDataStore.GuideProgressRecord(
                completedTopics: Array(completedTopicIds).sorted(),
                tipsEnabled: tipsEnabled
            )
        )
    }
}

struct InteractiveGuideView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    let guideStore: GuideStore
    let onOpenTopic: (GuideTopic, Bool) -> Void

    private let textScaleOptions: [(labelKey: String, scale: Double)] = [
        ("guide_text_size_default", 1.0),
        ("guide_text_size_large", 1.12),
        ("guide_text_size_largest", 1.24)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                tourHeroCard
                textSizeCard

                ForEach(GuideGroup.allCases) { group in
                    let topics = GuideTopic.allCases.filter { $0.group == group }
                    VStack(alignment: .leading, spacing: 10) {
                        Text(theme.t(group.titleKey))
                            .font(theme.scaledFont(size: 15, weight: .black))
                            .foregroundStyle(theme.primary)
                            .padding(.horizontal, 4)

                        VStack(spacing: 10) {
                            ForEach(topics) { topic in
                                topicRow(topic)
                            }
                        }
                    }
                }

                SirajSettingsToggleRow(
                    icon: "lightbulb.fill",
                    title: theme.t("guide_tips_title"),
                    subtitle: theme.t("guide_tips_body"),
                    isOn: Binding(
                        get: { guideStore.tipsEnabled },
                        set: { guideStore.setTipsEnabled($0) }
                    )
                )
                .sirajCardSurface(cornerRadius: 22)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 124)
        }
        .scrollIndicators(.hidden)
        .background(Color.clear)
        .navigationTitle(theme.t("guide_title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var tourHeroCard: some View {
        let done = guideStore.completedTopicIds.count
        let total = GuideTopic.allCases.count
        let frac = total > 0 ? Double(done) / Double(total) : 0
        let ctaKey = guideStore.allDone
            ? "guide_restart_tour"
            : (done > 0 ? "guide_continue_tour" : "guide_start_tour")

        return VStack(alignment: .leading, spacing: 12) {
            Text(theme.t("guide_tour_badge"))
                .font(theme.scaledFont(size: 11, weight: .bold))
                .foregroundStyle(theme.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(theme.primary.opacity(0.12)))

            Text(theme.t("guide_hub_heading"))
                .font(theme.scaledFont(size: 22, weight: .black))
                .foregroundStyle(theme.onSurface)

            Text(theme.t("guide_hub_body"))
                .font(theme.scaledFont(size: 13.5))
                .foregroundStyle(theme.onSurfaceVariant)
                .lineSpacing(3)

            Text(theme.t("guide_tour_length"))
                .font(theme.scaledFont(size: 12, weight: .medium))
                .foregroundStyle(theme.outline)

            if done > 0 {
                HStack(spacing: 10) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(theme.primary.opacity(0.14))
                            Capsule()
                                .fill(theme.primary)
                                .frame(width: max(0, geo.size.width * frac))
                        }
                    }
                    .frame(height: 6)
                    Text("\(theme.digits(String(done)))/\(theme.digits(String(total)))")
                        .font(theme.scaledFont(size: 12, weight: .bold))
                        .foregroundStyle(theme.primary)
                }
            }

            Button {
                let target: GuideTopic = guideStore.allDone ? .reading : guideStore.nextUnfinishedTopic
                onOpenTopic(target, true)
            } label: {
                HStack(spacing: 8) {
                    Text(theme.t(ctaKey))
                        .font(theme.scaledFont(size: 14.5, weight: .black))
                    Image(systemName: theme.isRTL ? "arrow.left" : "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(theme.onPrimary)
                .padding(.horizontal, 18)
                .frame(height: 44)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.primary))
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .padding(18)
        .sirajCardSurface(cornerRadius: 26, isElevated: true)
    }

    private var textSizeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(theme.t("guide_text_size_title"))
                .font(theme.scaledFont(size: 15.5, weight: .black))
                .foregroundStyle(theme.onSurface)
            Text(theme.t("guide_text_size_body"))
                .font(theme.scaledFont(size: 12.5))
                .foregroundStyle(theme.onSurfaceVariant)

            HStack(spacing: 8) {
                ForEach(textScaleOptions, id: \.scale) { opt in
                    let active = abs(appState.settings.textScale - opt.scale) < 0.05
                    Button {
                        if appState.settings.isHapticEnabled {
                            UISelectionFeedbackGenerator().selectionChanged()
                        }
                        appState.updateSettings { $0.textScale = opt.scale }
                    } label: {
                        Text(theme.t(opt.labelKey))
                            .font(theme.scaledFont(size: 12.5, weight: active ? .black : .semibold))
                            .foregroundStyle(active ? theme.onPrimary : theme.onSurface)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(
                                Capsule().fill(active ? theme.primary : theme.surfaceContainerHigh.opacity(0.75))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(theme.t("guide_text_size_sample"))
                .font(theme.scaledFont(size: 14))
                .foregroundStyle(theme.primary)
                .padding(.top, 2)
        }
        .padding(16)
        .sirajCardSurface(cornerRadius: 22)
    }

    private func topicRow(_ topic: GuideTopic) -> some View {
        let isDone = guideStore.completedTopicIds.contains(topic.id)
        return Button {
            if appState.settings.isHapticEnabled {
                UISelectionFeedbackGenerator().selectionChanged()
            }
            onOpenTopic(topic, false)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(theme.primary.opacity(theme.isDark ? 0.18 : 0.11))
                        .frame(width: 44, height: 44)
                    topicIconView(topic.icon, size: 20, tint: theme.primary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(theme.t(topic.titleKey))
                        .font(theme.scaledFont(size: 15, weight: .bold))
                        .foregroundStyle(theme.onSurface)
                        .lineLimit(1)
                    Text(theme.t(topic.summaryKey))
                        .font(theme.scaledFont(size: 12))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 4) {
                    if isDone {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 17))
                            .foregroundStyle(theme.primary)
                    } else {
                        Image(systemName: theme.isRTL ? "chevron.left" : "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(theme.outline)
                    }
                    Text(theme.plural("guide_steps_count", count: topic.steps.count, theme.digits(String(topic.steps.count))))
                        .font(theme.scaledFont(size: 10.5, weight: .semibold))
                        .foregroundStyle(theme.outline)
                }
            }
            .padding(12)
            .sirajCardSurface(cornerRadius: 20)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func topicIconView(_ icon: GuideIconKind, size: CGFloat, tint: Color) -> some View {
        switch icon {
        case .asset(let name):
            Image(name)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundStyle(tint)
        case .system(let name):
            Image(systemName: name)
                .font(.system(size: size * 0.9, weight: .semibold))
                .foregroundStyle(tint)
        }
    }
}

struct GuideTopicPagerView: View {
    @Environment(\.sirajTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    let appState: AppState
    let guideStore: GuideStore
    let isTourMode: Bool
    let onTryInApp: (GuideTopic) -> Void

    @State private var currentTopic: GuideTopic
    @State private var stepIndex = 0
    @State private var showFinish = false

    init(
        appState: AppState,
        guideStore: GuideStore,
        initialTopic: GuideTopic,
        isTourMode: Bool,
        onTryInApp: @escaping (GuideTopic) -> Void
    ) {
        self.appState = appState
        self.guideStore = guideStore
        self.isTourMode = isTourMode
        self.onTryInApp = onTryInApp
        self._currentTopic = State(initialValue: initialTopic)
    }

    var body: some View {
        NavigationStack {
            if showFinish {
                finishView
            } else {
                let steps = currentTopic.steps
                let safeIdx = min(max(stepIndex, 0), max(0, steps.count - 1))

                VStack(spacing: 16) {
                    // Segmented step progress
                    HStack(spacing: 6) {
                        ForEach(0..<steps.count, id: \.self) { idx in
                            Capsule()
                                .fill(idx <= safeIdx ? theme.primary : theme.outlineVariant.opacity(0.4))
                                .frame(height: 5)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    Text(theme.t("guide_step_of", theme.digits(String(safeIdx + 1)), theme.digits(String(steps.count))))
                        .font(theme.scaledFont(size: 12, weight: .bold))
                        .foregroundStyle(theme.primary)

                    TabView(selection: $stepIndex) {
                        ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                            stepCard(step)
                                .tag(idx)
                                .padding(.horizontal, 20)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    // Bottom navigation controls
                    VStack(spacing: 10) {
                        if safeIdx == steps.count - 1 {
                            Button {
                                guideStore.markCompleted(currentTopic)
                                dismiss()
                                onTryInApp(currentTopic)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.up.forward.app.fill")
                                    Text(theme.t("guide_show_me"))
                                        .font(theme.scaledFont(size: 14.5, weight: .bold))
                                }
                                .foregroundStyle(theme.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .sirajCardSurface(cornerRadius: 16)
                            }
                            .buttonStyle(.plain)
                        }

                        HStack(spacing: 12) {
                            if safeIdx > 0 {
                                Button {
                                    withAnimation(theme.motionEnabled ? .easeInOut(duration: 0.2) : nil) {
                                        stepIndex -= 1
                                    }
                                } label: {
                                    Text(theme.t("guide_back"))
                                        .font(theme.scaledFont(size: 14.5, weight: .bold))
                                        .foregroundStyle(theme.onSurface)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .sirajCardSurface(cornerRadius: 18)
                                }
                                .buttonStyle(.plain)
                            }

                            Button {
                                advance(stepsCount: steps.count)
                            } label: {
                                Text(primaryButtonLabel(isLastStep: safeIdx == steps.count - 1))
                                    .font(theme.scaledFont(size: 15, weight: .black))
                                    .foregroundStyle(theme.onPrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(theme.primary))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .background(theme.background.ignoresSafeArea())
                .navigationTitle(theme.t(currentTopic.titleKey))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(theme.t("close")) { dismiss() }
                    }
                }
            }
        }
    }

    private func stepCard(_ step: GuideStepSpec) -> some View {
        VStack(spacing: 22) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [theme.primaryContainer.opacity(theme.isDark ? 0.55 : 0.85), theme.surfaceContainer],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(theme.primary.opacity(0.22), lineWidth: 1)
                    )

                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(theme.primary.opacity(0.16))
                            .frame(width: 96, height: 96)
                        Circle()
                            .fill(theme.primary)
                            .frame(width: 68, height: 68)
                            .shadow(color: theme.primary.opacity(0.32), radius: 12, y: 6)

                        if let asset = step.accent {
                            Image(asset)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .foregroundStyle(theme.onPrimary)
                        } else {
                            Image(systemName: step.symbol)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(theme.onPrimary)
                        }
                    }

                    // Miniature UI chrome hint matching the topic
                    HStack(spacing: 8) {
                        Capsule().fill(theme.primary.opacity(0.45)).frame(width: 48, height: 6)
                        Capsule().fill(theme.outlineVariant.opacity(0.5)).frame(width: 28, height: 6)
                        Capsule().fill(theme.outlineVariant.opacity(0.5)).frame(width: 28, height: 6)
                    }
                }
            }
            .frame(height: 210)

            VStack(spacing: 10) {
                Text(theme.t(step.titleKey))
                    .font(theme.scaledFont(size: 21, weight: .black))
                    .foregroundStyle(theme.onSurface)
                    .multilineTextAlignment(.center)

                Text(theme.t(step.bodyKey))
                    .font(theme.scaledFont(size: 15))
                    .foregroundStyle(theme.onSurfaceVariant)
                    .lineSpacing(5)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 6)

            Spacer(minLength: 0)
        }
        .padding(.top, 8)
    }

    private var finishView: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.15))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 46))
                    .foregroundStyle(theme.primary)
            }
            Text(theme.t("guide_finish_title"))
                .font(theme.scaledFont(size: 24, weight: .black))
                .foregroundStyle(theme.onSurface)
            Text(theme.t("guide_finish_body"))
                .font(theme.scaledFont(size: 15))
                .foregroundStyle(theme.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Spacer()

            VStack(spacing: 10) {
                Button {
                    dismiss()
                    appState.selectedTab = .prayer
                } label: {
                    Text(theme.t("guide_finish_start"))
                        .font(theme.scaledFont(size: 15.5, weight: .black))
                        .foregroundStyle(theme.onPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(theme.primary))
                }
                .buttonStyle(.plain)

                Button {
                    dismiss()
                } label: {
                    Text(theme.t("guide_finish_hub"))
                        .font(theme.scaledFont(size: 14.5, weight: .bold))
                        .foregroundStyle(theme.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(theme.background.ignoresSafeArea())
    }

    private func primaryButtonLabel(isLastStep: Bool) -> String {
        if !isLastStep { return theme.t("next") }
        if isTourMode && currentTopic.next != nil { return theme.t("next") }
        return theme.t(isTourMode ? "guide_finish" : "guide_done")
    }

    private func advance(stepsCount: Int) {
        if stepIndex + 1 < stepsCount {
            withAnimation(theme.motionEnabled ? .easeInOut(duration: 0.22) : nil) {
                stepIndex += 1
            }
        } else {
            guideStore.markCompleted(currentTopic)
            if isTourMode, let nextTopic = currentTopic.next {
                withAnimation(theme.motionEnabled ? .easeInOut(duration: 0.22) : nil) {
                    currentTopic = nextTopic
                    stepIndex = 0
                }
            } else if isTourMode {
                showFinish = true
            } else {
                dismiss()
            }
        }
    }
}
