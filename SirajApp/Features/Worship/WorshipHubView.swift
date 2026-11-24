import SwiftUI
import UIKit
import SirajCore

enum WorshipRoute: Hashable {
    case azkar(String)
    case tasbih
    case hadith(String?)
    case names
    case listen
}

struct WorshipHubView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    let worshipStore: WorshipStore
    let onOpenListenPlayer: () -> Void

    @State private var path = NavigationPath()
    @State private var searchQuery = ""
    @State private var selectedTab: AzkarFilterTab = .all
    @State private var showHijriSheet = false
    @State private var pendingToolTitle: String?
    @Namespace private var filterPillNamespace

    private var heroCategory: AzkarCategory {
        let hour = Calendar.current.component(.hour, from: appState.currentTime)
        return AzkarCategory.suggested(forHour: hour)
    }

    private var foldedQuery: String {
        ArabicSearchText.normalizeQuery(searchQuery)
    }

    private var filteredCategories: [AzkarCategory] {
        AzkarCategory.allCases.filter { cat in
            selectedTab.matches(category: cat) && (
                foldedQuery.isEmpty || [cat.titleAr, cat.titleEn, cat.titleTr, cat.titleUr]
                    .contains { ArabicSearchText.normalize($0).contains(foldedQuery) }
            )
        }
    }

    private var filteredChapters: [AzkarChapter] {
        let westernNumber = Int(DigitFormatter.toWestern(foldedQuery))
        return worshipStore.catalog.chapters.filter { chapter in
            guard selectedTab.matches(chapterTitle: chapter.title) else { return false }
            if foldedQuery.isEmpty { return true }
            if chapter.number == westernNumber { return true }
            if ArabicSearchText.normalize(chapter.title).contains(foldedQuery) { return true }
            if let localized = worshipStore.catalog.chapterTitles[chapter.title] {
                return [localized.en, localized.tr, localized.ur]
                    .contains { ArabicSearchText.normalize($0).contains(foldedQuery) }
            }
            return false
        }
    }

    private var isLargeText: Bool {
        appState.settings.textScale >= 1.2
    }

    private var twoColGrid: [GridItem] {
        if isLargeText {
            return [GridItem(.flexible())]
        }
        return [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    screenHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .padding(.bottom, 14)

                    heroWirdCard
                        .padding(.horizontal, 16)

                    toolsSection
                        .padding(.top, 22)

                    searchField
                        .padding(.horizontal, 16)
                        .padding(.top, 22)

                    Section {
                        if !filteredCategories.isEmpty {
                            sectionHeader(
                                title: theme.t("categories"),
                                subtitle: nil,
                                trailing: theme.plural(
                                    "azkar_category_count",
                                    count: filteredCategories.count,
                                    theme.digits(String(filteredCategories.count))
                                )
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 14)
                            .padding(.bottom, 10)

                            LazyVGrid(columns: twoColGrid, spacing: 12) {
                                ForEach(filteredCategories) { cat in
                                    categoryCard(cat)
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        if !filteredChapters.isEmpty {
                            sectionHeader(
                                title: theme.t("azkar_chapters_title"),
                                subtitle: theme.t("azkar_chapter_source_badge"),
                                trailing: theme.t("azkar_chapters_count", theme.digits(String(filteredChapters.count)))
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 22)
                            .padding(.bottom, 10)

                            ForEach(filteredChapters) { chapter in
                                chapterCard(chapter)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 5)
                            }
                        }

                        if filteredCategories.isEmpty && filteredChapters.isEmpty {
                            emptyResultsView
                                .padding(.horizontal, 24)
                                .padding(.vertical, 40)
                        }
                    } header: {
                        pinnedFilterBar
                    }
                }
                .padding(.bottom, 124)
            }
            .scrollIndicators(.hidden)
            .scrollCollapseTracker(
                enabled: appState.settings.isNavShrinkEnabled && !appState.settings.isNavAlwaysCompact,
                isCollapsed: Binding(
                    get: { appState.isTabBarCollapsed },
                    set: { appState.isTabBarCollapsed = $0 }
                )
            )
            .background(Color.clear)
            .navigationBarHidden(true)
            .navigationDestination(for: WorshipRoute.self) { route in
                switch route {
                case .azkar(let key):
                    AzkarDetailView(appState: appState, worshipStore: worshipStore, categoryKey: key)
                case .tasbih:
                    TasbihView(appState: appState, worshipStore: worshipStore)
                case .hadith(let initialId):
                    HadithLibraryView(appState: appState, initialHadithId: initialId)
                case .names:
                    NamesOfAllahView(appState: appState, worshipStore: worshipStore)
                case .listen:
                    ListenHubView(appState: appState, audioStore: appState.audioStore, onOpenPlayer: onOpenListenPlayer)
                }
            }
            .navigationDestination(for: ListenRoute.self) { route in
                switch route {
                case .reciter(let reciterId):
                    ListenReciterView(appState: appState, audioStore: appState.audioStore, reciterId: reciterId, onOpenPlayer: onOpenListenPlayer)
                case .rare(let collectionId):
                    ListenRareView(appState: appState, audioStore: appState.audioStore, collectionId: collectionId, onOpenPlayer: onOpenListenPlayer)
                }
            }
            .sheet(isPresented: $showHijriSheet) {
                HijriDateSheetView(appState: appState)
            }
            .alert(pendingToolTitle ?? "", isPresented: Binding(
                get: { pendingToolTitle != nil },
                set: { if !$0 { pendingToolTitle = nil } }
            )) {
                Button(theme.t("close"), role: .cancel) {}
            } message: {
                Text(theme.t("tab_coming_soon_azkar"))
            }
        }
        .onAppear {
            worshipStore.refreshForToday()
            consumeRequestedRoute()
        }
        .onChange(of: appState.requestedWorshipRoute) { _, _ in
            consumeRequestedRoute()
        }
    }

    private func consumeRequestedRoute() {
        guard let route = appState.requestedWorshipRoute else { return }
        appState.requestedWorshipRoute = nil
        path = NavigationPath()
        path.append(route)
    }

    // MARK: - Header & Hero

    private var screenHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(theme.t("azkar_screen_title"))
                .font(theme.scaledFont(size: 28, weight: .black))
                .foregroundStyle(theme.onBackground)
            Text(theme.t("azkar_screen_verse"))
                .font(theme.scaledFont(size: 14, weight: .semibold))
                .foregroundStyle(theme.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var heroWirdCard: some View {
        let cat = heroCategory
        let completion = worshipStore.completion(for: cat)
        let meta: (titleKey: String, descKey: String, badgeKey: String) = {
            switch cat {
            case .morning: return ("reminders_morning_azkar_title", "azkar_card_morning_desc", "azkar_card_morning_badge")
            case .evening: return ("reminders_evening_azkar_title", "azkar_card_evening_desc", "azkar_card_evening_badge")
            case .afterPrayer: return ("azkar_card_after_prayer_title", "azkar_card_after_prayer_desc", "azkar_card_after_prayer_badge")
            default: return ("azkar_card_sleep_title", "azkar_card_sleep_desc", "azkar_card_sleep_badge")
            }
        }()
        let soft = theme.primary.opacity(theme.isDark ? 0.16 : 0.10)
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)

        return Button {
            if appState.settings.isHapticEnabled {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            path.append(WorshipRoute.azkar(cat.rawValue))
        } label: {
            ZStack(alignment: .topTrailing) {
                categoryGlyph(for: cat, size: 110, tint: theme.primary.opacity(0.10))
                    .rotationEffect(.degrees(-12))
                    .padding(.top, 10)
                    .padding(.trailing, 10)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6) {
                        categoryGlyph(for: cat, size: 15, tint: theme.primary)
                        Text(theme.t(meta.badgeKey))
                            .font(theme.scaledFont(size: 11.5, weight: .black))
                            .foregroundStyle(theme.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(soft))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(theme.primary.opacity(0.35), lineWidth: 0.8))

                    Text(theme.t(meta.titleKey))
                        .font(theme.scaledFont(size: 22, weight: .black))
                        .foregroundStyle(theme.onSurface)
                        .padding(.top, 16)

                    Text(theme.t(meta.descKey))
                        .font(theme.scaledFont(size: 14))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 4)

                    if completion.total > 0 {
                        HStack(spacing: 12) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(soft)
                                    Capsule()
                                        .fill(theme.primary)
                                        .frame(width: max(0, geo.size.width * completion.fraction))
                                }
                            }
                            .frame(height: 6)

                            Text(theme.t("azkar_progress_of", theme.digits(String(completion.done)), theme.digits(String(completion.total))))
                                .font(theme.scaledFont(size: 12, weight: .bold))
                                .foregroundStyle(theme.primary)
                        }
                        .padding(.top, 16)
                    }

                    HStack(spacing: 8) {
                        if completion.isComplete {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 15, weight: .bold))
                        }
                        Text(theme.t(completion.isComplete ? "azkar_hero_done" : (completion.isStarted ? "azkar_hero_continue" : "azkar_start_reading")))
                            .font(theme.scaledFont(size: 14, weight: .black))
                        if !completion.isComplete {
                            Image(systemName: theme.isRTL ? "arrow.left" : "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                    }
                    .foregroundStyle(completion.isComplete ? theme.primary : theme.onPrimary)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(completion.isComplete ? soft : theme.primary)
                    )
                    .padding(.top, 18)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(22)
            }
            .background {
                if !theme.isGlass {
                    shape.fill(
                        LinearGradient(
                            colors: [theme.primaryContainer.opacity(theme.isDark ? 0.55 : 0.88), theme.surface],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                } else {
                    shape.fill(
                        LinearGradient(
                            colors: [theme.primary.opacity(theme.isDark ? 0.20 : 0.12), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .sirajCardSurface(cornerRadius: 28, isElevated: true)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tools Section

    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(theme.t("hub_section_title"))
                .font(theme.scaledFont(size: 20, weight: .black))
                .foregroundStyle(theme.onBackground)
                .padding(.horizontal, 20)

            listenFeaturedCard
                .padding(.horizontal, 16)

            radioFeaturedCard
                .padding(.horizontal, 16)

            let toolGrid: [GridItem] = isLargeText
                ? [GridItem(.flexible())]
                : [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

            LazyVGrid(columns: toolGrid, spacing: 10) {
                toolCard(icon: "ic_quick_tasbih", titleKey: "nav_tasbih", descKey: "hub_tasbih_desc") {
                    path.append(WorshipRoute.tasbih)
                }
                toolCard(icon: "ic_siraj_hijri_calendar", titleKey: "hub_calendar_title", descKey: "hub_calendar_desc") {
                    showHijriSheet = true
                }
                toolCard(icon: "ic_siraj_fasting", titleKey: "hub_fasting_title", descKey: "hub_fasting_desc") {
                    pendingToolTitle = theme.t("hub_fasting_title")
                }
                toolCard(icon: "ic_siraj_zakat_coin", titleKey: "hub_zakat_title", descKey: "hub_zakat_desc") {
                    pendingToolTitle = theme.t("hub_zakat_title")
                }
                toolCard(icon: "ic_siraj_hadith", titleKey: "hub_hadith_title", descKey: "hub_hadith_desc") {
                    path.append(WorshipRoute.hadith(nil))
                }
                toolCard(icon: "ic_siraj_allah_word", titleKey: "hub_names_title", descKey: "hub_names_desc") {
                    path.append(WorshipRoute.names)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var listenFeaturedCard: some View {
        let audio = appState.audioStore
        let soft = theme.primary.opacity(theme.isDark ? 0.16 : 0.10)
        let activeTrack = audio.currentListeningTrack
        let isPlaying = audio.hasActiveListening && audio.listeningIsPlaying

        return Button {
            if appState.settings.isHapticEnabled {
                UISelectionFeedbackGenerator().selectionChanged()
            }
            path.append(WorshipRoute.listen)
        } label: {
            HStack(spacing: 12) {
                if let track = activeTrack {
                    ReciterAvatarView(
                        reciterId: track.sourceId,
                        name: track.artist,
                        photoAsset: track.artworkAsset,
                        size: 54
                    )
                    .overlay {
                        if isPlaying {
                            Circle()
                                .fill(Color.black.opacity(0.38))
                                .overlay(SirajEqualizerBars(isPlaying: true, color: .white))
                        }
                    }
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(soft)
                            .frame(width: 54, height: 54)
                        Image("ic_quick_listen")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .foregroundStyle(theme.primary)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(theme.primary)
                            .frame(width: 6, height: 6)
                        Text(theme.t(isPlaying ? "listen_now_playing" : "listen_card_badge"))
                            .font(theme.scaledFont(size: 11, weight: .bold))
                            .foregroundStyle(theme.primary)
                    }

                    HStack(spacing: 6) {
                        Text(activeTrack?.artist ?? theme.t("listen_card_title"))
                            .font(theme.scaledFont(size: 15, weight: .black))
                            .foregroundStyle(theme.onSurface)
                            .lineLimit(1)

                        Text(theme.t("listen_card_all"))
                            .font(theme.scaledFont(size: 10, weight: .bold))
                            .foregroundStyle(theme.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(RoundedRectangle(cornerRadius: 8).fill(theme.primary.opacity(0.12)))
                    }

                    Text(activeTrack?.title ?? theme.t("listen_card_subtitle"))
                        .font(theme.scaledFont(size: 12))
                        .foregroundStyle(theme.outline)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    if activeTrack != nil {
                        audio.toggleListeningPlayPause()
                    } else {
                        path.append(WorshipRoute.listen)
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(isPlaying ? theme.primary : soft)
                            .frame(width: 42, height: 42)
                        Image(systemName: activeTrack == nil ? "headphones" : (isPlaying ? "pause.fill" : "play.fill"))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(isPlaying ? theme.onPrimary : theme.primary)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .sirajCardSurface(cornerRadius: 22, isElevated: isPlaying)
        }
        .buttonStyle(.plain)
    }

    private var radioFeaturedCard: some View {
        let soft = theme.primary.opacity(theme.isDark ? 0.16 : 0.10)

        return Button {
            pendingToolTitle = theme.t("radio_live_title")
        } label: {
            HStack(spacing: 12) {
                Image("radio_quran")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 54, height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(theme.primary)
                            .frame(width: 6, height: 6)
                        Text(theme.t("radio_live_badge"))
                            .font(theme.scaledFont(size: 11, weight: .semibold))
                            .foregroundStyle(theme.primary)
                        if !isLargeText {
                            Text("•")
                                .font(theme.scaledFont(size: 11))
                                .foregroundStyle(theme.outlineVariant)
                            Text(theme.t("radio_now_on_air"))
                                .font(theme.scaledFont(size: 11))
                                .foregroundStyle(theme.outline)
                                .lineLimit(1)
                        }
                    }

                    HStack(spacing: 6) {
                        Text(theme.t("radio_live_title"))
                            .font(theme.scaledFont(size: 15, weight: .black))
                            .foregroundStyle(theme.onSurface)
                            .lineLimit(1)

                        HStack(spacing: 2) {
                            Text(theme.t("radio_more_stations_chip"))
                                .font(theme.scaledFont(size: 10, weight: .bold))
                            Image(systemName: theme.isRTL ? "chevron.left" : "chevron.right")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundStyle(theme.primary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 8).fill(theme.primary.opacity(0.12)))
                    }

                    Text(theme.t("radio_tap_to_browse_channels"))
                        .font(theme.scaledFont(size: 12))
                        .foregroundStyle(theme.outline)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    Circle()
                        .fill(soft)
                        .frame(width: 42, height: 42)
                    Image(systemName: "radio")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(theme.primary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .sirajCardSurface(cornerRadius: 22)
        }
        .buttonStyle(.plain)
    }

    private func toolCard(icon: String, titleKey: String, descKey: String, action: @escaping () -> Void) -> some View {
        let soft = theme.primary.opacity(theme.isDark ? 0.16 : 0.10)

        return Button {
            if appState.settings.isHapticEnabled {
                UISelectionFeedbackGenerator().selectionChanged()
            }
            action()
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(soft)
                        .frame(width: 40, height: 40)
                    Image(icon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundStyle(theme.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.t(titleKey))
                        .font(theme.scaledFont(size: 14, weight: .black))
                        .foregroundStyle(theme.onSurface)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(theme.t(descKey))
                        .font(theme.scaledFont(size: 11))
                        .foregroundStyle(theme.outline)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
            .sirajCardSurface(cornerRadius: 20)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Search & Pinned Filters

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(theme.primary)
            TextField(theme.t("azkar_search_hint"), text: $searchQuery)
                .font(theme.scaledFont(size: 14.5))
                .foregroundStyle(theme.onSurface)
            if !searchQuery.isEmpty {
                Button { searchQuery = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(theme.outline)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(theme.t("adhkar_search_clear"))
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 48)
        .sirajCardSurface(cornerRadius: 18)
    }

    private var pinnedFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AzkarFilterTab.allCases) { tab in
                    let isSelected = selectedTab == tab
                    Button {
                        if appState.settings.isHapticEnabled {
                            UISelectionFeedbackGenerator().selectionChanged()
                        }
                        if theme.motionEnabled {
                            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                                selectedTab = tab
                            }
                        } else {
                            selectedTab = tab
                        }
                    } label: {
                        Text(tab.label(language: theme.language))
                            .font(theme.scaledFont(size: 13.5, weight: .semibold))
                            .foregroundStyle(isSelected ? theme.onPrimary : theme.onSurface)
                            .padding(.horizontal, 18)
                            .frame(height: 40)
                            .background {
                                if isSelected {
                                    Capsule()
                                        .fill(theme.primary)
                                        .shadow(color: theme.primary.opacity(0.4), radius: 6, y: 2)
                                        .matchedGeometryEffect(id: "azkarFilterPill", in: filterPillNamespace)
                                } else {
                                    Capsule()
                                        .fill(theme.isGlass ? Color.clear : theme.surface)
                                        .overlay(Capsule().strokeBorder(theme.outlineVariant.opacity(0.55), lineWidth: 1))
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(
            theme.isLiveBackground || theme.isGlass
                ? AnyShapeStyle(.ultraThinMaterial)
                : AnyShapeStyle(theme.background.opacity(0.96))
        )
    }

    // MARK: - Categories & Chapters

    private func sectionHeader(title: String, subtitle: String?, trailing: String?) -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(theme.scaledFont(size: 20, weight: .black))
                    .foregroundStyle(theme.onBackground)
                if let subtitle {
                    Text(subtitle)
                        .font(theme.scaledFont(size: 12))
                        .foregroundStyle(theme.outline)
                }
            }
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(theme.scaledFont(size: 12, weight: .bold))
                    .foregroundStyle(theme.outline)
            }
        }
    }

    private func categoryCard(_ cat: AzkarCategory) -> some View {
        let completion = worshipStore.completion(for: cat)
        let soft = theme.primary.opacity(theme.isDark ? 0.16 : 0.10)
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)

        return Button {
            if appState.settings.isHapticEnabled {
                UISelectionFeedbackGenerator().selectionChanged()
            }
            path.append(WorshipRoute.azkar(cat.rawValue))
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(soft)
                            .frame(width: 42, height: 42)
                        categoryGlyph(for: cat, size: 22, tint: theme.primary)
                    }
                    Spacer()
                    if completion.isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(theme.primary)
                    }
                }

                Spacer(minLength: 12)

                Text(cat.title(language: theme.language))
                    .font(theme.scaledFont(size: 15.5, weight: .black))
                    .foregroundStyle(theme.onSurface)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(theme.t(cat.purposeKey))
                    .font(theme.scaledFont(size: 11.5))
                    .foregroundStyle(theme.outline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 2)

                if completion.isStarted {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(soft)
                            Capsule()
                                .fill(theme.primary)
                                .frame(width: max(0, geo.size.width * completion.fraction))
                        }
                    }
                    .frame(height: 4)
                    .padding(.top, 10)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
            .sirajCardSurface(cornerRadius: 22, isElevated: completion.isComplete)
            .overlay(
                shape.strokeBorder(completion.isComplete ? theme.primary.opacity(0.55) : Color.clear, lineWidth: completion.isComplete ? 1.2 : 0)
            )
        }
        .buttonStyle(.plain)
    }

    private func chapterCard(_ chapter: AzkarChapter) -> some View {
        let isArabic = theme.language.hasPrefix("ar")
        let localized = worshipStore.catalog.localizedChapterTitle(chapter.title, language: theme.language)
        let duaCountText = theme.plural("azkar_chapter_duas", count: chapter.count, theme.digits(String(chapter.count)))

        return Button {
            if appState.settings.isHapticEnabled {
                UISelectionFeedbackGenerator().selectionChanged()
            }
            path.append(WorshipRoute.azkar(chapter.title))
        } label: {
            HStack(spacing: 14) {
                HisnStarNumberBadge(numberText: theme.digits(String(chapter.number)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(isArabic ? chapter.title : localized)
                        .font(theme.scaledFont(size: 15, weight: .bold))
                        .foregroundStyle(theme.onSurface)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if !isArabic && localized != chapter.title {
                        Text(chapter.title)
                            .font(theme.scaledFont(size: 12))
                            .foregroundStyle(theme.primary.opacity(0.85))
                            .lineLimit(1)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "book")
                            .font(.system(size: 11))
                            .foregroundStyle(theme.outline)
                        Text(duaCountText)
                            .font(theme.scaledFont(size: 11.5))
                            .foregroundStyle(theme.outline)
                    }
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: theme.isRTL ? "arrow.left" : "arrow.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.primary.opacity(0.7))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .sirajCardSurface(cornerRadius: 20)
        }
        .buttonStyle(.plain)
    }

    private var emptyResultsView: some View {
        let soft = theme.primary.opacity(theme.isDark ? 0.16 : 0.10)
        return VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(soft)
                    .frame(width: 64, height: 64)
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(theme.primary)
            }
            Text(theme.t("azkar_no_results", searchQuery.trimmingCharacters(in: .whitespaces)))
                .font(theme.scaledFont(size: 15, weight: .bold))
                .foregroundStyle(theme.onSurface)
                .multilineTextAlignment(.center)
            Text(theme.t("adhkar_no_results_hint"))
                .font(theme.scaledFont(size: 13.5))
                .foregroundStyle(theme.onSurfaceVariant)
                .multilineTextAlignment(.center)

            HStack(spacing: 10) {
                if selectedTab != .all && !foldedQuery.isEmpty {
                    Button {
                        selectedTab = .all
                    } label: {
                        Text(theme.t("adhkar_search_everywhere"))
                            .font(theme.scaledFont(size: 13.5, weight: .bold))
                            .foregroundStyle(theme.onPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(theme.primary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    searchQuery = ""
                } label: {
                    Label(theme.t("adhkar_search_clear"), systemImage: "xmark")
                        .font(theme.scaledFont(size: 13.5, weight: .semibold))
                        .foregroundStyle(theme.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(theme.primary.opacity(0.35), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func categoryGlyph(for cat: AzkarCategory, size: CGFloat, tint: Color) -> some View {
        switch cat {
        case .morning:
            Image(systemName: "sun.max.fill").font(.system(size: size * 0.85, weight: .semibold)).foregroundStyle(tint)
        case .evening:
            Image(systemName: "moon.stars.fill").font(.system(size: size * 0.85, weight: .semibold)).foregroundStyle(tint)
        case .sleep:
            Image(systemName: "moon.zzz.fill").font(.system(size: size * 0.85, weight: .semibold)).foregroundStyle(tint)
        case .wakeUp:
            Image(systemName: "sunrise.fill").font(.system(size: size * 0.85, weight: .semibold)).foregroundStyle(tint)
        case .afterPrayer:
            assetGlyph("ic_azkar_carpet", size: size, tint: tint)
        case .mosque:
            assetGlyph("ic_siraj_eid_mosque", size: size, tint: tint)
        case .ruqiya:
            Image(systemName: "shield.fill").font(.system(size: size * 0.85, weight: .semibold)).foregroundStyle(tint)
        case .grief:
            assetGlyph("ic_azkar_grief", size: size, tint: tint)
        case .debt:
            assetGlyph("ic_azkar_debt", size: size, tint: tint)
        case .travel:
            Image(systemName: "airplane").font(.system(size: size * 0.85, weight: .semibold)).foregroundStyle(tint)
        case .hajj:
            assetGlyph("ic_siraj_kaaba", size: size, tint: tint)
        case .rabbana:
            assetGlyph("ic_siraj_dua_hands", size: size, tint: tint)
        case .essential:
            Image(systemName: "heart.fill").font(.system(size: size * 0.85, weight: .semibold)).foregroundStyle(tint)
        case .missedRakah:
            assetGlyph("ic_azkar_missed_rakah", size: size, tint: tint)
        }
    }

    private func assetGlyph(_ name: String, size: CGFloat, tint: Color) -> some View {
        Image(name)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(tint)
    }
}

private struct HisnStarNumberBadge: View {
    @Environment(\.sirajTheme) private var theme
    let numberText: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(theme.primary.opacity(0.10))
                .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(theme.primary.opacity(0.35), lineWidth: 1))
                .frame(width: 31, height: 31)
                .rotationEffect(.degrees(45))

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(theme.primary.opacity(0.14))
                .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(theme.primary.opacity(0.50), lineWidth: 1))
                .frame(width: 31, height: 31)

            Text(numberText)
                .font(theme.scaledFont(size: numberText.count > 2 ? 11 : 13, weight: .black))
                .foregroundStyle(theme.primary)
        }
        .frame(width: 42, height: 42)
    }
}
