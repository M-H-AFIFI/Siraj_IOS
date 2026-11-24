import SwiftUI
import SirajCore

struct ReaderDestination: Identifiable, Hashable {
    let id = UUID()
    let page: Int
    let surahNumber: Int?
    let ayahNumber: Int?
}

enum QuranIndexRoute: Hashable {
    case bookmarks
    case settings
    case listen
    case khatma
    case video(surah: Int, ayah: Int)
}

private enum SearchFilterTab: CaseIterable {
    case all, surahs, ayat
}

struct SurahListView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    let quranStore: QuranStore
    let onOpenReader: (ReaderDestination) -> Void

    @State private var path = NavigationPath()
    @State private var searchQuery = ""
    @State private var isJuzView = false
    @State private var filterTab: SearchFilterTab = .all
    @State private var ayahSearchResults: [Ayah] = []
    @State private var isSearchingAyahs = false
    @State private var exactAyahResolved: Ayah?
    @State private var searchTask: Task<Void, Never>?

    private var edition: MushafEdition {
        MushafEdition.resolve(appState.settings.mushafEdition)
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if !quranStore.assetState.isReady {
                    QuranSetupView(quranStore: quranStore, appState: appState)
                } else {
                    mainIndexBody
                }
            }
            .background(Color.clear)
            .navigationTitle(theme.t("nav_quran"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        path.append(QuranIndexRoute.bookmarks)
                    } label: {
                        Image(systemName: "bookmark")
                            .foregroundStyle(theme.onSurface)
                    }
                    Button {
                        path.append(QuranIndexRoute.settings)
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(theme.onSurface)
                    }
                }
            }
            .navigationDestination(for: QuranIndexRoute.self) { route in
                switch route {
                case .bookmarks:
                    BookmarksView(
                        appState: appState,
                        quranStore: quranStore,
                        onOpenAyah: { surah, ayah in
                            let page = quranStore.pageForAyah(surah: surah, ayah: ayah, edition: edition)
                            onOpenReader(ReaderDestination(page: page, surahNumber: surah, ayahNumber: ayah))
                        }
                    )
                case .settings:
                    QuranSettingsView(appState: appState, quranStore: quranStore)
                case .listen:
                    ListenHubView(
                        appState: appState,
                        audioStore: appState.audioStore,
                        onOpenPlayer: { appState.showListenPlayer = true }
                    )
                case .khatma:
                    KhatmaView(
                        appState: appState,
                        khatmaStore: appState.khatmaStore,
                        onOpenReader: onOpenReader
                    )
                case .video(let surah, let ayah):
                    QuranVideoView(
                        appState: appState,
                        quranStore: quranStore,
                        initialSurah: surah,
                        initialAyah: ayah
                    )
                }
            }
            .task { consumeRequestedQuranRoute() }
            .onChange(of: appState.requestedQuranRoute) { _, _ in consumeRequestedQuranRoute() }
        }
    }

    private func consumeRequestedQuranRoute() {
        guard let route = appState.requestedQuranRoute else { return }
        appState.requestedQuranRoute = nil
        switch route {
        case "listen": path.append(QuranIndexRoute.listen)
        case "khatma": path.append(QuranIndexRoute.khatma)
        case "video": path.append(QuranIndexRoute.video(surah: 1, ayah: 1))
        default: break
        }
    }

    private var mainIndexBody: some View {
        let surahs = quranStore.surahs
        let isSearching = !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let filteredSurahs = filteredSurahList(from: surahs)
        let exactRef = isSearching ? QuranSearchParser.parseExactAyah(searchQuery, surahs: surahs) : nil
        let directPage = isSearching ? QuranSearchParser.parseDirectPage(searchQuery, totalPages: edition.totalPages) : nil
        let juzSummaries = quranStore.juzSummaries(for: edition)

        return ScrollView {
            LazyVStack(spacing: 10) {
                searchBar
                    .padding(.top, 4)

                if isSearching {
                    searchFilterChips(surahCount: filteredSurahs.count, ayahCount: ayahSearchResults.count)
                    searchResultsContent(
                        surahs: filteredSurahs,
                        allSurahs: surahs,
                        exactRef: exactRef,
                        directPage: directPage
                    )
                } else {
                    if let pos = quranStore.readingPosition {
                        continueReadingHero(position: pos, surahs: surahs)
                    }

                    // Listen Hub + Khatma quick cards
                    HStack(spacing: 10) {
                        Button {
                            path.append(QuranIndexRoute.listen)
                        } label: {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(theme.primary.opacity(0.14))
                                        .frame(width: 40, height: 40)
                                    Image("ic_quick_listen")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .foregroundStyle(theme.primary)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(theme.t("listen_card_badge"))
                                        .font(theme.scaledFont(size: 10.5, weight: .black))
                                        .foregroundStyle(theme.primary)
                                        .textCase(.uppercase)
                                    Text(theme.t("listen_card_title"))
                                        .font(theme.scaledFont(size: 13.5, weight: .bold))
                                        .foregroundStyle(theme.onSurface)
                                        .lineLimit(1)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(12)
                            .sirajCardSurface(cornerRadius: 20)
                        }
                        .buttonStyle(.plain)

                        Button {
                            path.append(QuranIndexRoute.video(surah: quranStore.readingPosition?.surahNumber ?? 1, ayah: quranStore.readingPosition?.ayahNumber ?? 1))
                        } label: {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(theme.gold.opacity(0.16))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "film.stack.fill")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(theme.primary)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(theme.t("quran_video_section_video"))
                                        .font(theme.scaledFont(size: 10.5, weight: .black))
                                        .foregroundStyle(theme.primary)
                                        .textCase(.uppercase)
                                    Text(theme.t("quran_video_title"))
                                        .font(theme.scaledFont(size: 13.5, weight: .bold))
                                        .foregroundStyle(theme.onSurface)
                                        .lineLimit(1)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(12)
                            .sirajCardSurface(cornerRadius: 20)
                        }
                        .buttonStyle(.plain)
                    }

                    KhatmaHeroCard(plan: appState.khatmaStore.plan(surahs: surahs)) {
                        path.append(QuranIndexRoute.khatma)
                    }
                    .padding(.bottom, 4)

                    if isJuzView {
                        ForEach(1...30, id: \.self) { juzNum in
                            let summary = juzSummaries.first { $0.number == juzNum }
                            juzRow(number: juzNum, summary: summary)
                        }
                    } else {
                        ForEach(surahs) { surah in
                            surahRow(surah)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 118)
        }
        .scrollIndicators(.hidden)
        .scrollCollapseTracker(
            enabled: appState.settings.isNavShrinkEnabled && !appState.settings.isNavAlwaysCompact,
            isCollapsed: Binding(
                get: { appState.isTabBarCollapsed },
                set: { appState.isTabBarCollapsed = $0 }
            )
        )
        .onChange(of: searchQuery) { _, newValue in
            runSearch(newValue)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(searchQuery.isEmpty ? theme.onSurfaceVariant : theme.primary)

                TextField(theme.t("quran_index_search_hint"), text: $searchQuery)
                    .font(theme.scaledFont(size: 14.5))
                    .foregroundStyle(theme.onSurface)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(theme.onSurfaceVariant)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .sirajCardSurface(cornerRadius: 20)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isJuzView.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isJuzView ? "book.pages" : "square.stack.3d.up")
                        .font(.system(size: 16, weight: .semibold))
                    Text(theme.t(isJuzView ? "quran_index_tab_juz" : "quran_index_tab_surahs"))
                        .font(theme.scaledFont(size: 12.5, weight: .bold))
                        .lineLimit(1)
                }
                .foregroundStyle(isJuzView ? theme.onPrimary : theme.primary)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(
                    isJuzView ? theme.primary : theme.primary.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func continueReadingHero(position: ReadingPosition, surahs: [Surah]) -> some View {
        let surahObj = surahs.first { $0.number == position.surahNumber }
        let name = surahObj.map { SurahNames.forLanguage($0, language: theme.language) }
            ?? theme.t("quran_surah_label", theme.digits(String(position.surahNumber)))
        let targetPage = edition.rawValue == position.edition
            ? position.page
            : quranStore.pageForAyah(surah: position.surahNumber, ayah: position.ayahNumber, edition: edition)

        return Button {
            onOpenReader(ReaderDestination(page: targetPage, surahNumber: position.surahNumber, ayahNumber: position.ayahNumber))
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.t("quran_continue_reading"))
                        .font(theme.scaledFont(size: 11, weight: .bold))
                        .foregroundStyle(theme.onPrimary.opacity(0.85))
                    Text(name)
                        .font(SurahNames.isArabicScript(theme.language) ? theme.amiriFont(size: 24, weight: .bold) : theme.scaledFont(size: 21, weight: .black))
                        .foregroundStyle(theme.onPrimary)
                        .lineLimit(1)
                    Text(theme.t(
                        "last_read_where",
                        theme.digits(String(position.ayahNumber)),
                        theme.digits(String(targetPage)),
                        theme.digits(String(QuranTables.juzForPage(targetPage, edition: edition)))
                    ))
                    .font(theme.scaledFont(size: 12.5, weight: .medium))
                    .foregroundStyle(theme.onPrimary.opacity(0.9))
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(theme.onPrimary.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: theme.isRTL ? "arrow.left" : "arrow.right")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(theme.onPrimary)
                }
            }
            .padding(18)
            .background(
                LinearGradient(
                    colors: [theme.primary, theme.primary.opacity(0.84)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private func surahRow(_ surah: Surah) -> some View {
        let isArabicScript = SurahNames.isArabicScript(theme.language)
        let isMakki = surah.isMeccan
        let revType = theme.t(isMakki ? "quran_polish_meccan" : "quran_polish_medinan")
        let startPage = QuranTables.pageForSurah(surah.number, edition: edition)
        let ayahsLabel = theme.plural("ayah_count", count: surah.numberOfAyahs, theme.digits(String(surah.numberOfAyahs)))

        return Button {
            onOpenReader(ReaderDestination(page: startPage, surahNumber: surah.number, ayahNumber: 1))
        } label: {
            HStack(spacing: 12) {
                NumberStar(text: theme.digits(String(surah.number)))

                VStack(alignment: .leading, spacing: 3) {
                    Text(SurahNames.forLanguage(surah, language: theme.language))
                        .font(isArabicScript ? theme.amiriFont(size: 20, weight: .bold) : theme.scaledFont(size: 16, weight: .bold))
                        .foregroundStyle(theme.onSurface)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(isMakki ? "ic_siraj_kaaba" : "ic_azkar_masjid")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 11, height: 11)
                            .foregroundStyle(isMakki ? theme.primary : theme.onSurfaceVariant)
                        Text(revType)
                            .font(theme.scaledFont(size: 11, weight: .bold))
                            .foregroundStyle(isMakki ? theme.primary : theme.onSurfaceVariant)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(
                        isMakki ? theme.primary.opacity(0.12) : theme.surfaceVariant.opacity(0.65),
                        in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 2) {
                    if !isArabicScript {
                        Text(surah.name)
                            .font(theme.amiriFont(size: 19, weight: .bold))
                            .foregroundStyle(theme.primary)
                            .lineLimit(1)
                    }
                    Text(ayahsLabel)
                        .font(theme.scaledFont(size: 11.5, weight: .bold))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .sirajCardSurface(cornerRadius: 18)
        }
        .buttonStyle(.plain)
    }

    private func juzRow(number: Int, summary: JuzSummary?) -> some View {
        let isArabicScript = SurahNames.isArabicScript(theme.language)
        let startPage = summary?.startPage ?? QuranTables.pageForJuz(number, edition: edition)
        let boundary = JuzBoundaries.starts[number - 1]

        return Button {
            onOpenReader(ReaderDestination(page: startPage, surahNumber: boundary.surah, ayahNumber: boundary.ayah))
        } label: {
            HStack(spacing: 12) {
                NumberStar(text: theme.digits(String(number)))

                VStack(alignment: .leading, spacing: 3) {
                    Text(theme.t("quran_juz_label", theme.digits(String(number))))
                        .font(isArabicScript ? theme.amiriFont(size: 19, weight: .bold) : theme.scaledFont(size: 16, weight: .bold))
                        .foregroundStyle(theme.onSurface)
                        .lineLimit(1)

                    if let summary {
                        let startName = SurahNames.forLanguage(arabicName: summary.startSurahName, latinName: summary.startSurahEnglishName, language: theme.language)
                        let endName = SurahNames.forLanguage(arabicName: summary.endSurahName, latinName: summary.endSurahEnglishName, language: theme.language)
                        let span: String = {
                            if summary.isWithinOneSurah {
                                return "\(startName) \(theme.digits(String(summary.startAyahInSurah)))–\(theme.digits(String(summary.endAyahInSurah)))"
                            }
                            let arrow = isArabicScript ? "←" : "→"
                            return "\(startName) \(theme.digits(String(summary.startAyahInSurah))) \(arrow) \(endName) \(theme.digits(String(summary.endAyahInSurah)))"
                        }()
                        Text(span)
                            .font(theme.scaledFont(size: 11.5, weight: .bold))
                            .foregroundStyle(theme.onSurfaceVariant)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(theme.t("quran_page_label", theme.digits(String(startPage))))
                        .font(theme.scaledFont(size: 12.5, weight: .black))
                        .foregroundStyle(theme.primary)
                    if let summary {
                        Text(theme.plural("ayah_count", count: summary.ayahCount, theme.digits(String(summary.ayahCount))))
                            .font(theme.scaledFont(size: 11, weight: .bold))
                            .foregroundStyle(theme.onSurfaceVariant)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .sirajCardSurface(cornerRadius: 18)
        }
        .buttonStyle(.plain)
    }

    private func searchFilterChips(surahCount: Int, ayahCount: Int) -> some View {
        HStack(spacing: 8) {
            filterChip(.all, title: theme.t("tfs_filter_all"))
            filterChip(.surahs, title: "\(theme.t("quran_index_section_surahs")) (\(theme.digits(String(surahCount))))")
            filterChip(.ayat, title: theme.t("quran_index_ayah_count", theme.digits(String(ayahCount))))
            Spacer()
        }
        .padding(.vertical, 2)
    }

    private func filterChip(_ tab: SearchFilterTab, title: String) -> some View {
        let selected = filterTab == tab
        return Button {
            filterTab = tab
        } label: {
            Text(title)
                .font(theme.scaledFont(size: 12, weight: .bold))
                .foregroundStyle(selected ? theme.onPrimary : theme.onSurfaceVariant)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    selected ? theme.primary : theme.surfaceVariant.opacity(0.6),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func searchResultsContent(
        surahs: [Surah],
        allSurahs: [Surah],
        exactRef: ExactAyahReference?,
        directPage: Int?
    ) -> some View {
        let showSurahs = filterTab == .all || filterTab == .surahs
        let showAyahs = filterTab == .all || filterTab == .ayat
        let normalizedQuery = ArabicSearchText.normalizeQuery(searchQuery)

        if showAyahs, let exactRef {
            let page = quranStore.pageForAyah(surah: exactRef.surahNumber, ayah: exactRef.ayahNumber, edition: edition)
            Button {
                onOpenReader(ReaderDestination(page: page, surahNumber: exactRef.surahNumber, ayahNumber: exactRef.ayahNumber))
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(SurahNames.forLanguage(exactRef.surah, language: theme.language)) · \(theme.t("quran_ayah_label", theme.digits(String(exactRef.ayahNumber))))")
                            .font(theme.scaledFont(size: 14, weight: .bold))
                            .foregroundStyle(theme.primary)
                        Spacer()
                        Text(theme.t("quran_page_label", theme.digits(String(page))))
                            .font(theme.scaledFont(size: 12, weight: .bold))
                            .foregroundStyle(theme.onSurfaceVariant)
                    }
                    if let snippet = exactAyahResolved?.textUthmani, !snippet.isEmpty {
                        Text(snippet)
                            .font(theme.amiriFont(size: 18))
                            .foregroundStyle(theme.onSurface)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .lineLimit(3)
                    }
                }
                .padding(14)
                .sirajCardSurface(cornerRadius: 18)
            }
            .buttonStyle(.plain)
        }

        if showAyahs, let directPage {
            let sNum = QuranTables.surahForPage(directPage, edition: edition)
            let sName = allSurahs.first(where: { $0.number == sNum }).map { SurahNames.forLanguage($0, language: theme.language) } ?? ""
            let juz = QuranTables.juzForPage(directPage, edition: edition)
            Button {
                onOpenReader(ReaderDestination(page: directPage, surahNumber: sNum, ayahNumber: nil))
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(theme.t("quran_page_label", theme.digits(String(directPage))))
                            .font(theme.scaledFont(size: 16, weight: .black))
                            .foregroundStyle(theme.primary)
                        Text("\(sName) · \(theme.t("quran_juz_label", theme.digits(String(juz))))")
                            .font(theme.scaledFont(size: 12.5))
                            .foregroundStyle(theme.onSurfaceVariant)
                    }
                    Spacer()
                    Image(systemName: theme.isRTL ? "arrow.left" : "arrow.right")
                        .foregroundStyle(theme.primary)
                }
                .padding(14)
                .sirajCardSurface(cornerRadius: 18)
            }
            .buttonStyle(.plain)
        }

        if showSurahs && !surahs.isEmpty {
            ForEach(surahs) { surah in
                surahRow(surah)
            }
        }

        if showAyahs {
            if isSearchingAyahs {
                HStack(spacing: 10) {
                    ProgressView().tint(theme.primary)
                    Text(theme.t("quran_index_searching"))
                        .font(theme.scaledFont(size: 13))
                        .foregroundStyle(theme.onSurfaceVariant)
                }
                .padding(.vertical, 16)
            } else if !ayahSearchResults.isEmpty {
                ForEach(ayahSearchResults) { ayah in
                    let sObj = allSurahs.first { $0.number == ayah.surahNumber }
                    let sName = sObj.map { SurahNames.forLanguage($0, language: theme.language) } ?? ""
                    let targetPage = quranStore.pageForAyah(surah: ayah.surahNumber, ayah: ayah.numberInSurah, edition: edition)
                    Button {
                        onOpenReader(ReaderDestination(page: targetPage, surahNumber: ayah.surahNumber, ayahNumber: ayah.numberInSurah))
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(theme.t("quran_index_ayah_result_label", sName, theme.digits(String(ayah.numberInSurah))))
                                    .font(theme.scaledFont(size: 12.5, weight: .bold))
                                    .foregroundStyle(theme.primary)
                                Spacer()
                                Text(theme.t("quran_index_page_short", theme.digits(String(targetPage))))
                                    .font(theme.scaledFont(size: 11.5, weight: .semibold))
                                    .foregroundStyle(theme.onSurfaceVariant)
                            }
                            highlightedAyahText(ayah.textUthmani, normalizedQuery: normalizedQuery)
                                .font(theme.amiriFont(size: 18))
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .lineLimit(3)
                        }
                        .padding(14)
                        .sirajCardSurface(cornerRadius: 18)
                    }
                    .buttonStyle(.plain)
                }
            } else if surahs.isEmpty && exactRef == nil && directPage == nil {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 28))
                        .foregroundStyle(theme.primary.opacity(0.65))
                    Text(theme.t("quran_polish_no_results_title"))
                        .font(theme.scaledFont(size: 16, weight: .bold))
                        .foregroundStyle(theme.onSurface)
                    Text(theme.t("quran_polish_no_results_body"))
                        .font(theme.scaledFont(size: 13))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 36)
            }
        }
    }

    private func highlightedAyahText(_ text: String, normalizedQuery: String) -> Text {
        let ranges = ArabicSearchText.matchRanges(in: text, normalizedQuery: normalizedQuery)
        guard !ranges.isEmpty else {
            return Text(text).foregroundColor(theme.onSurface)
        }
        var attr = AttributedString(text)
        attr.foregroundColor = theme.onSurface
        for r in ranges {
            if let lower = AttributedString.Index(r.lowerBound, within: attr),
               let upper = AttributedString.Index(r.upperBound, within: attr) {
                attr[lower..<upper].foregroundColor = theme.primary
                attr[lower..<upper].backgroundColor = theme.primary.opacity(0.16)
            }
        }
        return Text(attr)
    }

    private func filteredSurahList(from surahs: [Surah]) -> [Surah] {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return surahs }
        if let isMeccan = QuranSearchParser.revelationFilter(for: trimmed) {
            return surahs.filter { $0.isMeccan == isMeccan }
        }
        return surahs.filter { SurahNames.matches($0, query: trimmed) }
    }

    private func runSearch(_ raw: String) {
        searchTask?.cancel()
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            ayahSearchResults = []
            exactAyahResolved = nil
            isSearchingAyahs = false
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(160))
            guard !Task.isCancelled else { return }

            if let ref = QuranSearchParser.parseExactAyah(trimmed, surahs: quranStore.surahs) {
                exactAyahResolved = await quranStore.ayah(surah: ref.surahNumber, ayah: ref.ayahNumber, edition: edition)
            } else {
                exactAyahResolved = nil
            }

            let normalized = ArabicSearchText.normalizeQuery(trimmed)
            if normalized.count >= ArabicSearchText.minQueryLength {
                isSearchingAyahs = true
                let hits = await quranStore.searchAyahs(trimmed, limit: 50)
                if !Task.isCancelled {
                    ayahSearchResults = hits
                    isSearchingAyahs = false
                }
            } else {
                ayahSearchResults = []
                isSearchingAyahs = false
            }
        }
    }
}
