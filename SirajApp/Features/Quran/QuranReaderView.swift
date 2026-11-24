import SwiftUI
import SirajCore

struct QuranReaderView: View {
    @Environment(\.sirajTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    let appState: AppState
    let quranStore: QuranStore
    let initialDestination: ReaderDestination

    @State private var currentPage: Int
    @State private var currentSurahNumber: Int
    @State private var selectedAyahNumber: Int?
    @State private var isImmersive = false
    @State private var showNavigator = false
    @State private var navigatorInitialTab = 0
    @State private var showSettingsSheet = false
    @State private var ayahForActions: Ayah?
    @State private var ayahForTafsir: Ayah?
    @State private var ayahForNote: Ayah?
    @State private var noteDraft = ""
    @State private var surahAyahs: [Ayah] = []
    @State private var bookmarkBounce: CGFloat = 1.0
    @State private var toastMessage: String?

    init(appState: AppState, quranStore: QuranStore, initialDestination: ReaderDestination) {
        self.appState = appState
        self.quranStore = quranStore
        self.initialDestination = initialDestination
        let ed = MushafEdition.resolve(appState.settings.mushafEdition)
        let clampedPage = min(ed.totalPages, max(1, initialDestination.page))
        _currentPage = State(initialValue: clampedPage)
        _currentSurahNumber = State(initialValue: initialDestination.surahNumber ?? QuranTables.surahForPage(clampedPage, edition: ed))
        _selectedAyahNumber = State(initialValue: initialDestination.ayahNumber)
    }

    private var edition: MushafEdition {
        MushafEdition.resolve(appState.settings.mushafEdition)
    }

    private var isPageView: Bool {
        appState.settings.isQuranPageView
    }

    private var isReaderDark: Bool {
        switch appState.settings.quranTheme {
        case "Light": return false
        case "Dark": return true
        default: return theme.isDark
        }
    }

    private var isMushafBlack: Bool {
        isReaderDark && (appState.settings.quranDarkStyle.lowercased() == "black" || appState.settings.isAmoled)
    }

    private var resolvedPaper: (paper: Color, ink: Color) {
        let pair = MushafColors.resolvePrinted(
            isDark: isReaderDark,
            isBlackMode: isMushafBlack,
            paperColor: appState.settings.quranPaperColor,
            darkStyle: appState.settings.quranDarkStyle
        )
        return (pair.paper.color, pair.ink.color)
    }

    private var accentColor: Color {
        theme.primary
    }

    private var currentSurah: Surah? {
        let sNum = isPageView ? QuranTables.surahForPage(currentPage, edition: edition) : currentSurahNumber
        return quranStore.surahs.first { $0.number == sNum }
    }

    private var pageOpeningAyah: (surah: Int, ayah: Int)? {
        if let p = quranStore.mushafPage(pageNumber: currentPage, edition: edition),
           let open = p.openingAyah {
            return open
        }
        if let a = surahAyahs.first(where: { ($0.scriptPage ?? $0.page) == currentPage }) {
            return (a.surahNumber, a.numberInSurah)
        }
        return (QuranTables.surahForPage(currentPage, edition: edition), 1)
    }

    private var isCurrentPageBookmarked: Bool {
        guard let open = pageOpeningAyah else { return false }
        return quranStore.isBookmarked(surah: open.surah, ayah: open.ayah)
    }

    var body: some View {
        let colors = resolvedPaper
        let isArabicTitle = SurahNames.isArabicScript(theme.language)
        let surahTitle = currentSurah.map { SurahNames.forLanguage($0, language: theme.language) }
            ?? theme.t("quran_surah_label", theme.digits(String(currentSurahNumber)))

        GeometryReader { geo in
            let isLandscapeDouble = geo.size.width > geo.size.height
                && geo.size.width >= 680
                && appState.settings.quranLandscapeLayout == "Double"

            ZStack {
                colors.paper.ignoresSafeArea()

                if isPageView {
                    pageReaderContent(
                        colors: colors,
                        isLandscapeDouble: isLandscapeDouble,
                        viewportHeight: geo.size.height,
                        topInset: isImmersive ? 8 : 66,
                        bottomInset: isImmersive ? 8 : 76
                    )
                } else {
                    ayahByAyahContent(colors: colors)
                }

                if !isImmersive {
                    VStack(spacing: 0) {
                        readerTopBar(
                            surahTitle: surahTitle,
                            surahNumber: currentSurah?.number ?? currentSurahNumber,
                            isArabicTitle: isArabicTitle,
                            colors: colors
                        )
                        Spacer()
                        readerBottomBar(surahTitle: surahTitle, colors: colors)
                    }
                    .transition(.opacity)
                }

                if let toastMessage {
                    VStack {
                        Spacer()
                        Text(toastMessage)
                            .font(theme.scaledFont(size: 13, weight: .bold))
                            .foregroundStyle(theme.onPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(theme.primary, in: Capsule())
                            .padding(.bottom, isImmersive ? 36 : 94)
                    }
                    .transition(.opacity)
                }
            }
            .preferredColorScheme(isReaderDark ? .dark : .light)
        }
        .onChange(of: currentPage) { _, newPage in
            let clamped = min(edition.totalPages, max(1, newPage))
            let sNum = QuranTables.surahForPage(clamped, edition: edition)
            currentSurahNumber = sNum
            let openAyah = quranStore.mushafPage(pageNumber: clamped, edition: edition)?.openingAyah
            quranStore.saveReadingPosition(
                surah: openAyah?.surah ?? sNum,
                ayah: openAyah?.ayah ?? 1,
                page: clamped,
                edition: edition
            )
            prefetchNeighbors(around: clamped)
        }
        .onChange(of: appState.settings.mushafEdition) { _, _ in
            let target = quranStore.pageForAyah(surah: currentSurahNumber, ayah: selectedAyahNumber ?? 1, edition: edition)
            currentPage = min(edition.totalPages, max(1, target))
            Task { await reloadSurahAyahs() }
        }
        .task {
            prefetchNeighbors(around: currentPage)
            await reloadSurahAyahs()
            let sNum = currentSurah?.number ?? currentSurahNumber
            quranStore.saveReadingPosition(
                surah: sNum,
                ayah: selectedAyahNumber ?? 1,
                page: currentPage,
                edition: edition
            )
        }
        .sheet(isPresented: $showNavigator) {
            QuranNavigatorSheet(
                appState: appState,
                quranStore: quranStore,
                currentPage: currentPage,
                edition: edition,
                initialTab: navigatorInitialTab,
                onSelectPage: { page in
                    currentPage = min(edition.totalPages, max(1, page))
                    currentSurahNumber = QuranTables.surahForPage(currentPage, edition: edition)
                    selectedAyahNumber = nil
                    showNavigator = false
                    Task { await reloadSurahAyahs() }
                },
                onSelectAyah: { surah, ayah, page in
                    currentSurahNumber = surah
                    selectedAyahNumber = ayah
                    currentPage = min(edition.totalPages, max(1, page))
                    showNavigator = false
                    Task { await reloadSurahAyahs() }
                }
            )
        }
        .sheet(item: $ayahForActions) { ayah in
            let sName = quranStore.surahs.first(where: { $0.number == ayah.surahNumber })
                .map { SurahNames.forLanguage($0, language: theme.language) } ?? surahTitle
            AyahActionsSheet(
                ayah: ayah,
                surahName: sName,
                pageNumber: ayah.scriptPage ?? quranStore.pageForAyah(surah: ayah.surahNumber, ayah: ayah.numberInSurah, edition: edition),
                edition: edition,
                isBookmarked: quranStore.isBookmarked(surah: ayah.surahNumber, ayah: ayah.numberInSurah),
                onToggleBookmark: { customName in
                    let added = quranStore.toggleBookmark(
                        surah: ayah.surahNumber,
                        ayah: ayah.numberInSurah,
                        surahName: sName,
                        name: customName
                    )
                    showToast(added ? theme.t("quran_polish_action_bookmarked") : theme.t("quran_action_remove_bookmark"))
                },
                onOpenTafsir: {
                    ayahForActions = nil
                    Task {
                        try? await Task.sleep(for: .milliseconds(220))
                        ayahForTafsir = ayah
                    }
                },
                onOpenNote: {
                    ayahForActions = nil
                    noteDraft = ""
                    Task {
                        try? await Task.sleep(for: .milliseconds(220))
                        ayahForNote = ayah
                    }
                },
                onCopy: {
                    UIPasteboard.general.string = "\(ayah.textUthmani)\n(\(sName): \(ayah.numberInSurah))"
                }
            )
        }
        .sheet(item: $ayahForTafsir) { ayah in
            TafsirSheet(
                appState: appState,
                quranStore: quranStore,
                initialAyah: ayah,
                edition: edition
            )
        }
        .sheet(item: $ayahForNote) { ayah in
            noteEditorSheet(for: ayah)
        }
        .sheet(isPresented: $showSettingsSheet) {
            NavigationStack {
                QuranSettingsView(appState: appState, quranStore: quranStore)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(theme.t("close")) {
                                showSettingsSheet = false
                            }
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private func pageReaderContent(
        colors: (paper: Color, ink: Color),
        isLandscapeDouble: Bool,
        viewportHeight: CGFloat,
        topInset: CGFloat,
        bottomInset: CGFloat
    ) -> some View {
        let total = edition.totalPages
        if isLandscapeDouble {
            let spreadCount = (total + 1) / 2
            let spreadBinding = Binding<Int>(
                get: { max(1, (currentPage + 1) / 2) },
                set: { newSpread in currentPage = min(total, max(1, newSpread * 2 - 1)) }
            )
            TabView(selection: spreadBinding) {
                ForEach(1...spreadCount, id: \.self) { spread in
                    let rightPage = spread * 2 - 1
                    let leftPage = spread * 2
                    HStack(spacing: 4) {
                        if leftPage <= total {
                            mushafPageItem(pageNumber: leftPage, colors: colors)
                        } else {
                            colors.paper
                        }
                        Divider().background(accentColor.opacity(0.25))
                        mushafPageItem(pageNumber: rightPage, colors: colors)
                    }
                    .padding(.top, topInset)
                    .padding(.bottom, bottomInset)
                    .tag(spread)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .environment(\.layoutDirection, .rightToLeft)
        } else if appState.settings.quranScrollDirection == "Vertical" {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(1...total, id: \.self) { pageNum in
                            mushafPageItem(pageNumber: pageNum, colors: colors)
                                .frame(height: max(560, viewportHeight - topInset - bottomInset - 30))
                                .id(pageNum)
                                .onAppear {
                                    currentPage = pageNum
                                }
                        }
                    }
                    .padding(.top, topInset)
                    .padding(.bottom, bottomInset)
                }
                .onAppear {
                    proxy.scrollTo(currentPage, anchor: .top)
                }
            }
        } else {
            TabView(selection: $currentPage) {
                ForEach(1...total, id: \.self) { pageNum in
                    mushafPageItem(pageNumber: pageNum, colors: colors)
                        .padding(.top, topInset)
                        .padding(.bottom, bottomInset)
                        .tag(pageNum)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .environment(\.layoutDirection, .rightToLeft)
        }
    }

    private func mushafPageItem(pageNumber: Int, colors: (paper: Color, ink: Color)) -> some View {
        let isBm: Bool = {
            if let page = quranStore.mushafPage(pageNumber: pageNumber, edition: edition) {
                return quranStore.bookmarks.contains { bm in
                    page.ayahs.contains { $0.surahNumber == bm.surahNumber && $0.numberInSurah == bm.ayahNumber }
                }
            }
            return false
        }()

        return MushafPageView(
            pageNumber: pageNumber,
            edition: edition,
            quranStore: quranStore,
            paperColor: colors.paper,
            inkColor: colors.ink,
            accentColor: accentColor,
            isDarkPage: isReaderDark,
            isBookmarked: isBm,
            highlightSurah: selectedAyahNumber != nil ? currentSurahNumber : nil,
            highlightAyah: appState.settings.quranHighlightMode == "none" ? nil : selectedAyahNumber,
            onTapPage: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isImmersive.toggle()
                }
            },
            onAyahLongPress: { surah, ayah in
                Task {
                    let full = await quranStore.ayah(surah: surah, ayah: ayah, edition: edition)
                        ?? Ayah(number: 0, surahNumber: surah, numberInSurah: ayah, textUthmani: "", page: pageNumber, scriptPage: pageNumber)
                    selectedAyahNumber = ayah
                    currentSurahNumber = surah
                    ayahForActions = full
                }
            }
        )
    }

    private func ayahByAyahContent(colors: (paper: Color, ink: Color)) -> some View {
        let surahTitle = currentSurah.map { SurahNames.forLanguage($0, language: theme.language) }
            ?? theme.t("quran_surah_label", theme.digits(String(currentSurahNumber)))

        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    OrnamentalSurahBanner(
                        name: surahTitle,
                        accentColor: accentColor,
                        textColor: colors.ink
                    )
                    .padding(.horizontal, 18)
                    .padding(.bottom, 6)

                    ForEach(surahAyahs) { ayah in
                        ayahListRow(ayah: ayah, surahName: surahTitle, colors: colors)
                            .id(ayah.numberInSurah)
                    }

                    surahNavigationFooter
                }
                .padding(.top, isImmersive ? 16 : 74)
                .padding(.bottom, 110)
            }
            .onAppear {
                if let target = selectedAyahNumber {
                    proxy.scrollTo(target, anchor: .top)
                }
            }
        }
    }

    private func ayahListRow(ayah: Ayah, surahName: String, colors: (paper: Color, ink: Color)) -> some View {
        let isBookmarked = quranStore.isBookmarked(surah: ayah.surahNumber, ayah: ayah.numberInSurah)
        let isHighlighted = selectedAyahNumber == ayah.numberInSurah && appState.settings.quranHighlightMode != "none"
        let scale = CGFloat(appState.settings.quranFontSizeMultiplier)
        let baseSize: CGFloat = edition == .indopak ? 20 : 21

        return VStack(alignment: .trailing, spacing: 12) {
            HStack {
                HStack(spacing: 4) {
                    if isBookmarked {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(accentColor)
                    }
                    Text("\(theme.digits(String(ayah.surahNumber))):\(theme.digits(String(ayah.numberInSurah)))")
                        .font(theme.scaledFont(size: 12, weight: .bold))
                        .foregroundStyle(accentColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(accentColor.opacity(0.11), in: Capsule())

                Spacer()

                HStack(spacing: 6) {
                    Button {
                        _ = quranStore.toggleBookmark(surah: ayah.surahNumber, ayah: ayah.numberInSurah, surahName: surahName)
                    } label: {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 16))
                            .foregroundStyle(isBookmarked ? accentColor : accentColor.opacity(0.65))
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.plain)

                    Button {
                        ayahForTafsir = ayah
                    } label: {
                        Image(systemName: "book.pages")
                            .font(.system(size: 16))
                            .foregroundStyle(accentColor.opacity(0.75))
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.plain)

                    Button {
                        selectedAyahNumber = ayah.numberInSurah
                        ayahForActions = ayah
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 16))
                            .foregroundStyle(accentColor.opacity(0.75))
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(alignment: .bottom, spacing: 6) {
                AyahQuoteView(
                    ayah: ayah,
                    edition: edition,
                    fontSize: baseSize * scale,
                    color: colors.ink,
                    alignment: .trailing
                )
            }

            if appState.settings.isShowTranslation, let translation = ayah.translation, !translation.isEmpty {
                Text(translation)
                    .font(theme.scaledFont(size: 15 * scale, weight: .medium))
                    .foregroundStyle(colors.ink.opacity(0.75))
                    .frame(maxWidth: .infinity, alignment: theme.isRTL ? .trailing : .leading)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(isHighlighted ? accentColor.opacity(isReaderDark ? 0.16 : 0.08) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(isHighlighted ? accentColor.opacity(0.26) : Color.clear, lineWidth: 1)
                )
        )
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.25)) {
                isImmersive.toggle()
            }
        }
        .onLongPressGesture {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            selectedAyahNumber = ayah.numberInSurah
            ayahForActions = ayah
        }
        .overlay(alignment: .bottom) {
            Divider()
                .background(colors.ink.opacity(0.10))
                .padding(.horizontal, 36)
        }
    }

    private var surahNavigationFooter: some View {
        HStack {
            if currentSurahNumber > 1 {
                Button {
                    currentSurahNumber -= 1
                    selectedAyahNumber = 1
                    currentPage = QuranTables.pageForSurah(currentSurahNumber, edition: edition)
                    Task { await reloadSurahAyahs() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: theme.isRTL ? "arrow.right" : "arrow.left")
                        Text(theme.t("back"))
                            .font(theme.scaledFont(size: 14, weight: .bold))
                    }
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(accentColor.opacity(0.35), lineWidth: 1.2))
                }
                .buttonStyle(.plain)
            }
            Spacer()
            if currentSurahNumber < 114 {
                Button {
                    currentSurahNumber += 1
                    selectedAyahNumber = 1
                    currentPage = QuranTables.pageForSurah(currentSurahNumber, edition: edition)
                    Task { await reloadSurahAyahs() }
                } label: {
                    HStack(spacing: 6) {
                        Text(theme.t("next"))
                            .font(theme.scaledFont(size: 14, weight: .black))
                        Image(systemName: theme.isRTL ? "arrow.left" : "arrow.right")
                    }
                    .foregroundStyle(theme.onPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(accentColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
    }

    private func readerTopBar(
        surahTitle: String,
        surahNumber: Int,
        isArabicTitle: Bool,
        colors: (paper: Color, ink: Color)
    ) -> some View {
        let islandBg: Color = {
            if isMushafBlack { return Color(hex: 0xFF141418) }
            if isReaderDark { return colors.paper.opacity(0.92) }
            return Color.white.opacity(0.88)
        }()
        let border = colors.ink.opacity(isReaderDark ? 0.14 : 0.11)
        let corner: CGFloat = appState.settings.navBarStyle == .compact ? 24 : 16
        let juzNum = QuranTables.juzForPage(currentPage, edition: edition)

        return HStack(spacing: 8) {
            Button { dismiss() } label: {
                Image(systemName: theme.isRTL ? "arrow.right" : "arrow.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(colors.ink)
                    .frame(width: 48, height: 48)
                    .background(islandBg, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: corner, style: .continuous).strokeBorder(border, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button {
                navigatorInitialTab = 0
                showNavigator = true
            } label: {
                HStack(spacing: 8) {
                    Text(theme.digits(String(surahNumber)))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(accentColor)
                        .frame(width: 32, height: 32)
                        .background(accentColor.opacity(isReaderDark ? 0.22 : 0.13), in: RoundedRectangle(cornerRadius: corner > 20 ? 16 : 10))

                    VStack(alignment: .leading, spacing: 1) {
                        Text(surahTitle)
                            .font(isArabicTitle ? theme.amiriFont(size: isPageView ? 20 : 18, weight: .bold) : theme.scaledFont(size: 15, weight: .bold))
                            .foregroundStyle(colors.ink)
                            .lineLimit(1)
                        if !isPageView {
                            Text("\(theme.t("quran_juz_label", theme.digits(String(juzNum)))) • \(theme.t("quran_page_label", theme.digits(String(currentPage))))")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(colors.ink.opacity(0.65))
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(colors.ink.opacity(0.55))
                }
                .padding(.horizontal, 10)
                .frame(height: 48)
                .background(islandBg, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: corner, style: .continuous).strokeBorder(border, lineWidth: 1))
            }
            .buttonStyle(.plain)

            HStack(spacing: 0) {
                Button {
                    togglePageBookmark(surahTitle: surahTitle)
                } label: {
                    Image(systemName: isCurrentPageBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(isCurrentPageBookmarked ? accentColor : colors.ink)
                        .scaleEffect(bookmarkBounce)
                        .frame(width: 40, height: 48)
                }
                .buttonStyle(.plain)

                Button {
                    appState.updateSettings { $0.isQuranPageView.toggle() }
                    Task { await reloadSurahAyahs() }
                } label: {
                    Image(systemName: isPageView ? "list.bullet" : "book.pages")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(colors.ink)
                        .frame(width: 40, height: 48)
                }
                .buttonStyle(.plain)

                Button {
                    showSettingsSheet = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(colors.ink)
                        .frame(width: 40, height: 48)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 2)
            .background(islandBg, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: corner, style: .continuous).strokeBorder(border, lineWidth: 1))
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .shadow(color: Color.black.opacity(isReaderDark ? 0 : 0.08), radius: 6, y: 2)
    }

    private func readerBottomBar(surahTitle: String, colors: (paper: Color, ink: Color)) -> some View {
        let barBg: Color = isMushafBlack ? Color(hex: 0xFF141418) : (isReaderDark ? colors.paper.opacity(0.94) : Color.white.opacity(0.92))
        let border = colors.ink.opacity(isReaderDark ? 0.14 : 0.11)
        let juz = QuranTables.juzForPage(currentPage, edition: edition)

        return HStack(spacing: 12) {
            Button {
                navigatorInitialTab = 2
                showNavigator = true
            } label: {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .frame(width: 40, height: 40)
                    .background(accentColor.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(theme.t("quran_page_label", theme.digits(String(currentPage)))) · \(theme.t("quran_juz_label", theme.digits(String(juz))))")
                    .font(theme.scaledFont(size: 13, weight: .bold))
                    .foregroundStyle(colors.ink)
                Text(editionTitle)
                    .font(theme.scaledFont(size: 11))
                    .foregroundStyle(colors.ink.opacity(0.62))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                Task {
                    if let open = pageOpeningAyah,
                       let ayah = await quranStore.ayah(surah: open.surah, ayah: open.ayah, edition: edition) {
                        ayahForTafsir = ayah
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "text.book.closed")
                        .font(.system(size: 14, weight: .semibold))
                    Text(theme.t("quran_action_tafsir"))
                        .font(theme.scaledFont(size: 12.5, weight: .bold))
                }
                .foregroundStyle(theme.onPrimary)
                .padding(.horizontal, 14)
                .frame(height: 38)
                .background(accentColor, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(barBg, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(border, lineWidth: 1))
        .shadow(color: Color.black.opacity(isReaderDark ? 0 : 0.10), radius: 10, y: 3)
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }

    private var editionTitle: String {
        switch edition {
        case .madinah: return theme.t("mushaf_name_madinah_v1")
        case .indopak: return theme.t("mushaf_name_indopak")
        case .shamarly: return theme.t("mushaf_name_shamarly")
        }
    }

    private func togglePageBookmark(surahTitle: String) {
        guard let open = pageOpeningAyah else { return }
        let label = theme.t("reader_page_bookmark_name", theme.digits(String(currentPage)))
        let added = quranStore.toggleBookmark(
            surah: open.surah,
            ayah: open.ayah,
            surahName: surahTitle,
            pageNumber: currentPage,
            name: label
        )
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        showToast(added ? theme.t("reader_page_bookmarked", theme.digits(String(currentPage))) : theme.t("reader_page_bookmark_removed"))
        if added && !appState.settings.isReduceMotionEnabled {
            bookmarkBounce = 0.65
            withAnimation(.spring(response: 0.35, dampingFraction: 0.45)) {
                bookmarkBounce = 1.0
            }
        }
    }

    private func showToast(_ text: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            toastMessage = text
        }
        Task {
            try? await Task.sleep(for: .seconds(1.8))
            if toastMessage == text {
                withAnimation(.easeInOut(duration: 0.2)) {
                    toastMessage = nil
                }
            }
        }
    }

    private func prefetchNeighbors(around page: Int) {
        let total = edition.totalPages
        let ed = edition
        Task {
            for offset in [-1, 1, -2, 2] {
                let p = page + offset
                if p >= 1 && p <= total {
                    _ = await quranStore.loadMushafPageAsync(pageNumber: p, edition: ed)
                }
            }
        }
    }

    private func reloadSurahAyahs() async {
        let sNum = currentSurahNumber
        let ed = edition
        let transEd = appState.settings.isShowTranslation ? appState.settings.selectedTafsirEdition : nil
        surahAyahs = await quranStore.ayahsForSurah(sNum, edition: ed, translationEdition: transEd)
    }

    private func noteEditorSheet(for ayah: Ayah) -> some View {
        let existing = quranStore.notesForAyah(surah: ayah.surahNumber, ayah: ayah.numberInSurah)
        return NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                if !existing.isEmpty {
                    Text(theme.t("quran_existing_notes"))
                        .font(theme.scaledFont(size: 13, weight: .bold))
                        .foregroundStyle(theme.primary)
                    ForEach(existing) { note in
                        Text(note.content)
                            .font(theme.scaledFont(size: 14))
                            .foregroundStyle(theme.onSurface)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .sirajCardSurface(cornerRadius: 14)
                    }
                }
                TextEditor(text: $noteDraft)
                    .font(theme.scaledFont(size: 15))
                    .frame(minHeight: 140)
                    .padding(10)
                    .background(theme.surfaceVariant.opacity(0.45), in: RoundedRectangle(cornerRadius: 14))
                Spacer()
            }
            .padding(18)
            .navigationTitle(theme.t("quran_add_note"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(theme.t("settings_cancel")) { ayahForNote = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(theme.t("settings_save")) {
                        quranStore.addNote(surah: ayah.surahNumber, ayah: ayah.numberInSurah, content: noteDraft)
                        ayahForNote = nil
                    }
                    .disabled(noteDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
