import SwiftUI
import SirajCore

struct AyahActionsSheet: View {
    @Environment(\.sirajTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    let ayah: Ayah
    let surahName: String
    let pageNumber: Int
    let edition: MushafEdition
    let isBookmarked: Bool
    let onToggleBookmark: (String?) -> Void
    let onOpenTafsir: () -> Void
    let onOpenNote: () -> Void
    let onCopy: () -> Void

    @State private var copied = false
    @State private var showBookmarkPrompt = false
    @State private var bookmarkName = ""

    var body: some View {
        let ayahDigits = theme.digits(String(ayah.numberInSurah))
        let juz = JuzBoundaries.juzOf(surah: ayah.surahNumber, ayah: ayah.numberInSurah)
        let locationLine = [
            theme.t("quran_ayah_label", ayahDigits),
            theme.t("quran_page_label", theme.digits(String(pageNumber))),
            theme.t("quran_juz_label", theme.digits(String(juz)))
        ].joined(separator: " • ")

        ScrollView {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    NumberStar(text: ayahDigits, size: 46)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(surahName)
                            .font(theme.scaledFont(size: 16, weight: .bold))
                            .foregroundStyle(theme.onSurface)
                            .lineLimit(1)
                        Text(locationLine)
                            .font(theme.scaledFont(size: 12.5))
                            .foregroundStyle(theme.onSurfaceVariant)
                            .lineLimit(1)
                    }
                    Spacer()
                }

                AyahQuoteView(
                    ayah: ayah,
                    edition: edition,
                    fontSize: 21,
                    color: theme.onSurface,
                    alignment: .center,
                    lineLimit: 4
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .sirajCardSurface(cornerRadius: 20)

                Button(action: onOpenTafsir) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(theme.primary.opacity(0.13))
                                .frame(width: 40, height: 40)
                            Image(systemName: "book.pages.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(theme.primary)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(theme.t("tfs_action_card_title"))
                                .font(theme.scaledFont(size: 15, weight: .bold))
                                .foregroundStyle(theme.onSurface)
                            Text(theme.t("tfs_action_card_sub"))
                                .font(theme.scaledFont(size: 12.5))
                                .foregroundStyle(theme.onSurfaceVariant)
                                .lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: theme.isRTL ? "chevron.left" : "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(theme.onSurfaceVariant)
                    }
                    .padding(14)
                    .sirajCardSurface(cornerRadius: 18)
                }
                .buttonStyle(.plain)

                HStack(spacing: 6) {
                    actionTile(
                        icon: isBookmarked ? "bookmark.fill" : "bookmark",
                        label: theme.t(isBookmarked ? "quran_polish_action_bookmarked" : "quran_polish_action_bookmark"),
                        active: isBookmarked
                    ) {
                        if isBookmarked {
                            onToggleBookmark(nil)
                            dismiss()
                        } else {
                            showBookmarkPrompt = true
                        }
                    }

                    actionTile(
                        icon: "square.and.pencil",
                        label: theme.t("quran_polish_action_note"),
                        active: false,
                        action: onOpenNote
                    )

                    actionTile(
                        icon: copied ? "checkmark" : "doc.on.doc",
                        label: theme.t(copied ? "quran_polish_action_copied" : "quran_action_copy"),
                        active: copied
                    ) {
                        onCopy()
                        copied = true
                        Task {
                            try? await Task.sleep(for: .milliseconds(1600))
                            copied = false
                        }
                    }

                    ShareLink(item: "\(ayah.textUthmani)\n\n\(surahName) (\(ayah.numberInSurah)) - \(theme.t("tfs_share_signature"))") {
                        actionTileLabel(
                            icon: "square.and.arrow.up",
                            label: theme.t("quran_action_share"),
                            active: false
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .alert(theme.t("quran_polish_bookmark_dialog_title"), isPresented: $showBookmarkPrompt) {
            TextField(theme.t("quran_polish_bookmark_dialog_label"), text: $bookmarkName)
            Button(theme.t("quran_polish_save")) {
                let clean = bookmarkName.trimmingCharacters(in: .whitespacesAndNewlines)
                onToggleBookmark(clean.isEmpty ? nil : clean)
                dismiss()
            }
            Button(theme.t("quran_polish_cancel"), role: .cancel) {}
        }
    }

    private func actionTile(icon: String, label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            actionTileLabel(icon: icon, label: label, active: active)
        }
        .buttonStyle(.plain)
    }

    private func actionTileLabel(icon: String, label: String, active: Bool) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(active ? theme.primary : theme.primary.opacity(0.11))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(active ? theme.onPrimary : theme.primary)
            }
            Text(label)
                .font(theme.scaledFont(size: 11.5, weight: active ? .bold : .medium))
                .foregroundStyle(active ? theme.primary : theme.onSurface)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TafsirSheet: View {
    @Environment(\.sirajTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    let appState: AppState
    let quranStore: QuranStore
    let initialAyah: Ayah
    let edition: MushafEdition

    @State private var currentAyah: Ayah
    @State private var tafsirBody: String?
    @State private var isLoading = true
    @State private var showLibrary = false

    init(appState: AppState, quranStore: QuranStore, initialAyah: Ayah, edition: MushafEdition) {
        self.appState = appState
        self.quranStore = quranStore
        self.initialAyah = initialAyah
        self.edition = edition
        _currentAyah = State(initialValue: initialAyah)
    }

    private var selectedBookId: String {
        appState.settings.selectedTafsirEdition
    }

    private var selectedBook: TafsirBook {
        TafsirBook.byId(selectedBookId) ?? TafsirBook.all[0]
    }

    private var downloadedBooks: [TafsirBook] {
        TafsirBook.all.filter { $0.isBuiltIn || quranStore.downloadedTafsirs.contains($0.id) }
    }

    var body: some View {
        let surahName = quranStore.surahs.first(where: { $0.number == currentAyah.surahNumber })
            .map { SurahNames.forLanguage($0, language: theme.language) }
            ?? theme.t("quran_surah_label", theme.digits(String(currentAyah.surahNumber)))
        let reference = theme.t("tfs_sheet_reference", surahName, theme.digits(String(currentAyah.numberInSurah)))
        let fontScale = CGFloat(appState.settings.tafsirFontScale)

        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(theme.primary.opacity(0.14))
                        .frame(width: 40, height: 40)
                    Image(systemName: "book.fill")
                        .foregroundStyle(theme.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedBook.title)
                        .font(theme.scaledFont(size: 15, weight: .black))
                        .foregroundStyle(theme.onSurface)
                        .lineLimit(1)
                    Text(reference)
                        .font(theme.scaledFont(size: 12, weight: .bold))
                        .foregroundStyle(theme.primary)
                        .lineLimit(1)
                }
                Spacer()

                if let text = tafsirBody, !text.isEmpty {
                    Button {
                        UIPasteboard.general.string = "\(reference)\n\n\(text)"
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .foregroundStyle(theme.onSurfaceVariant)
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.plain)

                    ShareLink(item: "\(reference)\n\(selectedBook.title)\n\n\(text)\n\n\(theme.t("tfs_share_signature"))") {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(theme.onSurfaceVariant)
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.plain)
                }

                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(theme.onSurfaceVariant)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 10)

            HStack(spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(downloadedBooks) { book in
                            let selected = book.id == selectedBookId
                            Button {
                                appState.updateSettings { $0.selectedTafsirEdition = book.id }
                            } label: {
                                HStack(spacing: 4) {
                                    if selected {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 11, weight: .bold))
                                    }
                                    Text(book.shortTitle)
                                        .font(theme.scaledFont(size: 12.5, weight: selected ? .bold : .medium))
                                }
                                .foregroundStyle(selected ? theme.onPrimary : theme.onSurface)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    selected ? theme.primary : theme.surfaceVariant.opacity(0.6),
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        Button { showLibrary = true } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "books.vertical")
                                    .font(.system(size: 12))
                                Text(theme.t("tfs_sheet_library"))
                                    .font(theme.scaledFont(size: 12.5, weight: .bold))
                            }
                            .foregroundStyle(theme.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(theme.primary.opacity(0.4), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: 0) {
                    Button {
                        appState.updateSettings { $0.tafsirFontScale = max(0.8, $0.tafsirFontScale - 0.1) }
                    } label: {
                        Text("A-")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundStyle(theme.onSurface)
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.plain)

                    Button {
                        appState.updateSettings { $0.tafsirFontScale = min(1.6, $0.tafsirFontScale + 0.1) }
                    } label: {
                        Text("A+")
                            .font(.system(size: 13.5, weight: .black))
                            .foregroundStyle(theme.primary)
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.plain)
                }
                .background(theme.surfaceVariant.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 10)

            Divider().background(theme.outlineVariant.opacity(0.25))

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if !currentAyah.textUthmani.isEmpty {
                        AyahQuoteView(
                            ayah: currentAyah,
                            edition: edition,
                            fontSize: 21,
                            color: theme.onSurface,
                            alignment: .trailing
                        )
                        .padding(14)
                        .background(theme.primary.opacity(theme.isDark ? 0.12 : 0.06), in: RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(theme.primary.opacity(0.20), lineWidth: 1))
                    }

                    if isLoading {
                        ProgressView()
                            .tint(theme.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 36)
                    } else if let text = tafsirBody, !text.isEmpty {
                        let paragraphs = text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                        VStack(alignment: selectedBook.isArabicScript ? .trailing : .leading, spacing: 12 * fontScale) {
                            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, para in
                                Text(para)
                                    .font(selectedBook.isArabicScript
                                          ? theme.amiriFont(size: 18 * fontScale)
                                          : theme.scaledFont(size: 16 * fontScale))
                                    .foregroundStyle(theme.onSurface.opacity(0.94))
                                    .lineSpacing(selectedBook.isArabicScript ? 10 * fontScale : 6 * fontScale)
                                    .multilineTextAlignment(selectedBook.isArabicScript ? .trailing : .leading)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: selectedBook.isArabicScript ? .trailing : .leading)
                            }
                        }
                        .environment(\.layoutDirection, selectedBook.isArabicScript ? .rightToLeft : .leftToRight)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 28))
                                .foregroundStyle(theme.onSurfaceVariant)
                            Text(theme.t("tfs_empty"))
                                .font(theme.scaledFont(size: 14))
                                .foregroundStyle(theme.onSurfaceVariant)
                                .multilineTextAlignment(.center)
                            Button(theme.t("quran_polish_tafsir_other_book")) {
                                showLibrary = true
                            }
                            .font(theme.scaledFont(size: 13.5, weight: .bold))
                            .foregroundStyle(theme.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    }
                }
                .padding(18)
            }

            Divider().background(theme.outlineVariant.opacity(0.25))

            HStack(spacing: 10) {
                Button {
                    Task { await stepAyah(delta: -1) }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: theme.isRTL ? "chevron.right" : "chevron.left")
                        Text(theme.t("quran_prev_ayah"))
                            .font(theme.scaledFont(size: 13.5, weight: .semibold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(theme.onSurface)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(theme.surfaceVariant.opacity(0.6), in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(currentAyah.number <= 1)

                Button {
                    Task { await stepAyah(delta: 1) }
                } label: {
                    HStack(spacing: 4) {
                        Text(theme.t("quran_next_ayah"))
                            .font(theme.scaledFont(size: 13.5, weight: .semibold))
                            .lineLimit(1)
                        Image(systemName: theme.isRTL ? "chevron.left" : "chevron.right")
                    }
                    .foregroundStyle(theme.onSurface)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(theme.surfaceVariant.opacity(0.6), in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(currentAyah.number >= JuzBoundaries.totalAyahs)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task(id: "\(currentAyah.number)-\(selectedBookId)") {
            await loadCommentary()
        }
        .sheet(isPresented: $showLibrary) {
            TafsirLibraryView(
                appState: appState,
                quranStore: quranStore,
                onSelectBook: { bookId in
                    appState.updateSettings { $0.selectedTafsirEdition = bookId }
                    showLibrary = false
                }
            )
        }
    }

    private func loadCommentary() async {
        isLoading = true
        if currentAyah.number <= 0,
           let resolved = await quranStore.ayah(surah: currentAyah.surahNumber, ayah: currentAyah.numberInSurah, edition: edition) {
            currentAyah = resolved
        }
        if currentAyah.number > 0 {
            tafsirBody = await quranStore.tafsirText(globalAyah: currentAyah.number, edition: selectedBookId)
        } else {
            tafsirBody = nil
        }
        isLoading = false
    }

    private func stepAyah(delta: Int) async {
        let nextGlobal = min(JuzBoundaries.totalAyahs, max(1, currentAyah.number + delta))
        if let next = await quranStore.ayahByGlobalNumber(nextGlobal, edition: edition) {
            currentAyah = next
        }
    }
}

private enum TafsirFilterKind: CaseIterable {
    case all, onDevice, ar, en, tr, ur

    var languageCode: String? {
        switch self {
        case .ar: return "ar"
        case .en: return "en"
        case .tr: return "tr"
        case .ur: return "ur"
        default: return nil
        }
    }

    var titleKey: String {
        switch self {
        case .all: return "tfs_filter_all"
        case .onDevice: return "tfs_filter_downloaded"
        case .ar: return "tfs_lang_ar"
        case .en: return "tfs_lang_en"
        case .tr: return "tfs_lang_tr"
        case .ur: return "tfs_lang_ur"
        }
    }
}

struct TafsirLibraryView: View {
    @Environment(\.sirajTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    let appState: AppState
    let quranStore: QuranStore
    let onSelectBook: (String) -> Void

    @State private var query = ""
    @State private var filter: TafsirFilterKind = .all
    @State private var activeDownloadId: String?
    @State private var downloadProgress: Double = 0
    @State private var failedIds: Set<String> = []
    @State private var bookToRemove: TafsirBook?

    private var onDevice: Set<String> {
        quranStore.downloadedTafsirs.union([TafsirBook.builtInId])
    }

    private var visibleBooks: [TafsirBook] {
        let folded = ArabicSearchText.normalizeQuery(query)
        return TafsirBook.all.filter { book in
            let matchesQuery = folded.isEmpty
                || ArabicSearchText.normalize(book.title).contains(folded)
                || ArabicSearchText.normalize(book.shortTitle).contains(folded)
                || ArabicSearchText.normalize(book.author).contains(folded)
            let matchesFilter: Bool
            switch filter {
            case .all: matchesFilter = true
            case .onDevice: matchesFilter = onDevice.contains(book.id)
            default: matchesFilter = book.language == filter.languageCode
            }
            return matchesQuery && matchesFilter
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    summaryCard
                    searchField
                    filterRow

                    if visibleBooks.isEmpty {
                        Text(theme.t(filter == .onDevice && query.isEmpty ? "tfs_no_results_downloaded" : "tfs_no_results"))
                            .font(theme.scaledFont(size: 14))
                            .foregroundStyle(theme.onSurfaceVariant)
                            .padding(.vertical, 32)
                    } else {
                        ForEach(visibleBooks) { book in
                            bookRow(book)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .navigationTitle(theme.t("tfs_library_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(theme.t("close")) { dismiss() }
                }
            }
            .alert(
                theme.t("tfs_remove_title", bookToRemove?.title ?? ""),
                isPresented: Binding(get: { bookToRemove != nil }, set: { if !$0 { bookToRemove = nil } })
            ) {
                Button(theme.t("tfs_remove_confirm"), role: .destructive) {
                    if let book = bookToRemove {
                        bookToRemove = nil
                        if appState.settings.selectedTafsirEdition == book.id {
                            appState.updateSettings { $0.selectedTafsirEdition = TafsirBook.builtInId }
                        }
                        Task { await quranStore.deleteTafsir(edition: book.id) }
                    }
                }
                Button(theme.t("tfs_cancel"), role: .cancel) { bookToRemove = nil }
            } message: {
                Text(theme.t("tfs_remove_body"))
            }
        }
    }

    private var summaryCard: some View {
        let total = TafsirBook.all.count
        let count = onDevice.count
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(theme.primary.opacity(0.15), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: Double(count) / Double(max(1, total)))
                        .stroke(theme.primary, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(theme.digits("\(count)/\(total)"))
                        .font(.system(size: 11.5, weight: .black))
                        .foregroundStyle(theme.primary)
                }
                .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 3) {
                    Text(theme.t("tfs_summary_label"))
                        .font(theme.scaledFont(size: 12, weight: .bold))
                        .foregroundStyle(theme.primary)
                    Text(count >= total
                         ? theme.t("tfs_all_downloaded")
                         : (count <= 1
                            ? theme.t("tfs_only_builtin")
                            : theme.t("tfs_count_of_total", theme.digits(String(count)), theme.digits(String(total)))))
                        .font(theme.scaledFont(size: 14.5, weight: .black))
                        .foregroundStyle(theme.onSurface)
                }
                Spacer()
            }

            if let activeId = activeDownloadId, let book = TafsirBook.byId(activeId) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(book.shortTitle) • \(theme.t("tfs_percent", theme.digits(String(Int((downloadProgress * 100).rounded())))))")
                        .font(theme.scaledFont(size: 12))
                        .foregroundStyle(theme.onSurfaceVariant)
                    ProgressView(value: downloadProgress, total: 1.0)
                        .tint(theme.primary)
                }
            }
        }
        .padding(16)
        .sirajCardSurface(cornerRadius: 24)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(theme.primary)
            TextField(theme.t("tafsir_search_hint"), text: $query)
                .font(theme.scaledFont(size: 14))
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(theme.onSurfaceVariant)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .sirajCardSurface(cornerRadius: 16)
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TafsirFilterKind.allCases, id: \.self) { entry in
                    let count: Int = {
                        switch entry {
                        case .all: return TafsirBook.all.count
                        case .onDevice: return onDevice.count
                        default: return TafsirBook.all.filter { $0.language == entry.languageCode }.count
                        }
                    }()
                    let selected = filter == entry
                    Button { filter = entry } label: {
                        Text(theme.t("tfs_chip_count", theme.t(entry.titleKey), theme.digits(String(count))))
                            .font(theme.scaledFont(size: 12, weight: .bold))
                            .foregroundStyle(selected ? theme.onPrimary : theme.onSurface)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(selected ? theme.primary : theme.surfaceVariant.opacity(0.6), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func bookRow(_ book: TafsirBook) -> some View {
        let isSelected = appState.settings.selectedTafsirEdition == book.id
        let isDownloaded = onDevice.contains(book.id)
        let isDownloading = activeDownloadId == book.id
        let hasFailed = failedIds.contains(book.id)

        return Button {
            if isDownloaded {
                onSelectBook(book.id)
            } else if activeDownloadId == nil {
                startBookDownload(book)
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill((isSelected || isDownloaded ? theme.primary : theme.surfaceVariant).opacity(0.16))
                        .frame(width: 40, height: 48)
                    Image(systemName: "book.closed.fill")
                        .foregroundStyle(isSelected || isDownloaded ? theme.primary : theme.onSurfaceVariant)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(book.title)
                        .font(theme.scaledFont(size: 14.5, weight: .bold))
                        .foregroundStyle(theme.onSurface)
                        .lineLimit(1)
                    Text(book.author)
                        .font(theme.scaledFont(size: 12))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isDownloading {
                    ProgressView()
                        .tint(theme.primary)
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(theme.primary)
                } else if isDownloaded {
                    if !book.isBuiltIn {
                        Menu {
                            Button(theme.t("tfs_menu_remove"), role: .destructive) {
                                bookToRemove = book
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundStyle(theme.onSurfaceVariant)
                                .frame(width: 32, height: 32)
                        }
                    } else {
                        Text(theme.t("tfs_state_builtin"))
                            .font(theme.scaledFont(size: 11, weight: .bold))
                            .foregroundStyle(theme.primary)
                    }
                } else if hasFailed {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(theme.error)
                } else {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(theme.primary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .sirajCardSurface(cornerRadius: 18)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(isSelected ? theme.primary.opacity(0.55) : Color.clear, lineWidth: 1.2)
            )
        }
        .buttonStyle(.plain)
    }

    private func startBookDownload(_ book: TafsirBook) {
        activeDownloadId = book.id
        downloadProgress = 0
        failedIds.remove(book.id)
        Task {
            do {
                try await quranStore.downloadTafsir(edition: book.id) { p in
                    downloadProgress = p
                }
                activeDownloadId = nil
                onSelectBook(book.id)
            } catch {
                activeDownloadId = nil
                failedIds.insert(book.id)
            }
        }
    }
}

struct QuranNavigatorSheet: View {
    @Environment(\.sirajTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    let appState: AppState
    let quranStore: QuranStore
    let currentPage: Int
    let edition: MushafEdition
    let initialTab: Int
    let onSelectPage: (Int) -> Void
    let onSelectAyah: (Int, Int, Int) -> Void

    @State private var selectedTab: Int
    @State private var query = ""

    init(
        appState: AppState,
        quranStore: QuranStore,
        currentPage: Int,
        edition: MushafEdition,
        initialTab: Int,
        onSelectPage: @escaping (Int) -> Void,
        onSelectAyah: @escaping (Int, Int, Int) -> Void
    ) {
        self.appState = appState
        self.quranStore = quranStore
        self.currentPage = currentPage
        self.edition = edition
        self.initialTab = initialTab
        self.onSelectPage = onSelectPage
        self.onSelectAyah = onSelectAyah
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        let surahs = quranStore.surahs
        let currentSurahNum = QuranTables.surahForPage(currentPage, edition: edition)
        let currentSurah = surahs.first { $0.number == currentSurahNum }
        let currentJuz = QuranTables.juzForPage(currentPage, edition: edition)
        let directPage = QuranSearchParser.parseDirectPage(query, totalPages: edition.totalPages)
        let exactRef = QuranSearchParser.parseExactAyah(query, surahs: surahs)

        NavigationStack {
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(theme.t("quran_index_title"))
                            .font(theme.scaledFont(size: 20, weight: .black))
                            .foregroundStyle(theme.onSurface)
                        Text(theme.t(
                            "quran_index_position",
                            currentSurah.map { SurahNames.forLanguage($0, language: theme.language) } ?? "",
                            theme.digits(String(currentPage)),
                            theme.digits(String(currentJuz))
                        ))
                        .font(theme.scaledFont(size: 12, weight: .bold))
                        .foregroundStyle(theme.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(theme.primary.opacity(0.11), in: Capsule())
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(theme.onSurfaceVariant)
                            .frame(width: 34, height: 34)
                            .background(theme.surfaceVariant.opacity(0.7), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(query.isEmpty ? theme.onSurfaceVariant : theme.primary)
                    TextField(theme.t("quran_index_search_hint"), text: $query)
                        .font(theme.scaledFont(size: 14))
                    if !query.isEmpty {
                        Button { query = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(theme.onSurfaceVariant)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 44)
                .sirajCardSurface(cornerRadius: 16)
                .padding(.horizontal, 18)

                if query.trimmingCharacters(in: .whitespaces).isEmpty {
                    Picker("", selection: $selectedTab) {
                        Text(theme.t("quran_index_tab_surahs")).tag(0)
                        Text(theme.t("quran_index_tab_juz")).tag(1)
                        Text(theme.t("quran_index_tab_bookmarks")).tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 18)
                }

                ScrollView {
                    LazyVStack(spacing: 8) {
                        if let exactRef {
                            let page = quranStore.pageForAyah(surah: exactRef.surahNumber, ayah: exactRef.ayahNumber, edition: edition)
                            Button {
                                onSelectAyah(exactRef.surahNumber, exactRef.ayahNumber, page)
                            } label: {
                                HStack {
                                    Text("\(SurahNames.forLanguage(exactRef.surah, language: theme.language)) · \(theme.t("quran_ayah_label", theme.digits(String(exactRef.ayahNumber))))")
                                        .font(theme.scaledFont(size: 14.5, weight: .bold))
                                        .foregroundStyle(theme.primary)
                                    Spacer()
                                    Text(theme.t("quran_page_label", theme.digits(String(page))))
                                        .font(theme.scaledFont(size: 12, weight: .semibold))
                                        .foregroundStyle(theme.onSurfaceVariant)
                                }
                                .padding(14)
                                .sirajCardSurface(cornerRadius: 16)
                            }
                            .buttonStyle(.plain)
                        }

                        if let directPage {
                            Button {
                                onSelectPage(directPage)
                            } label: {
                                HStack {
                                    Text(theme.t("quran_page_label", theme.digits(String(directPage))))
                                        .font(theme.scaledFont(size: 15, weight: .black))
                                        .foregroundStyle(theme.primary)
                                    Spacer()
                                    Image(systemName: theme.isRTL ? "arrow.left" : "arrow.right")
                                        .foregroundStyle(theme.primary)
                                }
                                .padding(14)
                                .sirajCardSurface(cornerRadius: 16)
                            }
                            .buttonStyle(.plain)
                        }

                        if !query.trimmingCharacters(in: .whitespaces).isEmpty {
                            let matches = surahs.filter { SurahNames.matches($0, query: query) }
                            ForEach(matches) { surah in
                                navSurahRow(surah, isCurrent: surah.number == currentSurahNum)
                            }
                        } else if selectedTab == 0 {
                            ForEach(surahs) { surah in
                                navSurahRow(surah, isCurrent: surah.number == currentSurahNum)
                            }
                        } else if selectedTab == 1 {
                            ForEach(JuzInfo.all) { info in
                                navJuzCard(info, isCurrent: info.number == currentJuz)
                            }
                        } else {
                            if quranStore.bookmarks.isEmpty {
                                Text(theme.t("quran_no_bookmarks"))
                                    .font(theme.scaledFont(size: 14))
                                    .foregroundStyle(theme.onSurfaceVariant)
                                    .padding(.vertical, 36)
                            } else {
                                ForEach(quranStore.bookmarks) { bm in
                                    Button {
                                        let page = bm.pageNumber ?? quranStore.pageForAyah(surah: bm.surahNumber, ayah: bm.ayahNumber, edition: edition)
                                        onSelectAyah(bm.surahNumber, bm.ayahNumber, page)
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: bm.isPageBookmark ? "book.fill" : "bookmark.fill")
                                                .foregroundStyle(theme.primary)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(bm.name ?? bm.surahName)
                                                    .font(theme.scaledFont(size: 14.5, weight: .bold))
                                                    .foregroundStyle(theme.onSurface)
                                                Text(theme.t("reader_page_bookmark_detail", bm.surahName, theme.digits(String(bm.ayahNumber))))
                                                    .font(theme.scaledFont(size: 12))
                                                    .foregroundStyle(theme.onSurfaceVariant)
                                            }
                                            Spacer()
                                            Button {
                                                quranStore.removeBookmark(bm)
                                            } label: {
                                                Image(systemName: "trash")
                                                    .font(.system(size: 14))
                                                    .foregroundStyle(theme.error.opacity(0.7))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(14)
                                        .sirajCardSurface(cornerRadius: 16)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 24)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func navSurahRow(_ surah: Surah, isCurrent: Bool) -> some View {
        let startPage = QuranTables.pageForSurah(surah.number, edition: edition)
        return Button {
            onSelectAyah(surah.number, 1, startPage)
        } label: {
            HStack(spacing: 12) {
                NumberStar(text: theme.digits(String(surah.number)), size: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text(SurahNames.forLanguage(surah, language: theme.language))
                        .font(SurahNames.isArabicScript(theme.language) ? theme.amiriFont(size: 18, weight: .bold) : theme.scaledFont(size: 15, weight: .bold))
                        .foregroundStyle(isCurrent ? theme.primary : theme.onSurface)
                    Text(theme.t("quran_page_label", theme.digits(String(startPage))))
                        .font(theme.scaledFont(size: 11.5))
                        .foregroundStyle(theme.onSurfaceVariant)
                }
                Spacer()
                if isCurrent {
                    Text(theme.t("quran_index_current"))
                        .font(theme.scaledFont(size: 10.5, weight: .bold))
                        .foregroundStyle(theme.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(theme.primary.opacity(0.12), in: Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .sirajCardSurface(cornerRadius: 16)
        }
        .buttonStyle(.plain)
    }

    private func navJuzCard(_ info: JuzInfo, isCurrent: Bool) -> some View {
        let startPage = QuranTables.pageForJuz(info.number, edition: edition)
        let hizb1 = info.number * 2 - 1
        let hizb2 = info.number * 2
        let hizb1Page = QuranTables.pageForHizb(hizb1, edition: edition)
        let hizb2Page = QuranTables.pageForHizb(hizb2, edition: edition)

        return VStack(alignment: .leading, spacing: 8) {
            Button {
                onSelectPage(startPage)
            } label: {
                HStack(spacing: 12) {
                    NumberStar(text: theme.digits(String(info.number)), size: 38)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(theme.isRTL ? info.arabicOrdinal : theme.t("quran_index_juz_title", theme.digits(String(info.number))))
                            .font(theme.scaledFont(size: 15, weight: .bold))
                            .foregroundStyle(isCurrent ? theme.primary : theme.onSurface)
                        Text(info.surahRange)
                            .font(theme.scaledFont(size: 11.5))
                            .foregroundStyle(theme.onSurfaceVariant)
                    }
                    Spacer()
                    Text(theme.t("quran_index_page_short", theme.digits(String(startPage))))
                        .font(theme.scaledFont(size: 12.5, weight: .black))
                        .foregroundStyle(theme.primary)
                }
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                hizbPill(hizb: hizb1, page: hizb1Page)
                hizbPill(hizb: hizb2, page: hizb2Page)
            }
        }
        .padding(12)
        .sirajCardSurface(cornerRadius: 16)
    }

    private func hizbPill(hizb: Int, page: Int) -> some View {
        Button {
            onSelectPage(page)
        } label: {
            Text(theme.t("quran_index_hizb", theme.digits(String(hizb)), theme.digits(String(page))))
                .font(theme.scaledFont(size: 11.5, weight: .semibold))
                .foregroundStyle(theme.onSurfaceVariant)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(theme.surfaceVariant.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
