import SwiftUI
import SirajCore

struct BookmarksView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    let quranStore: QuranStore
    let onOpenAyah: (Int, Int) -> Void

    @State private var selectedTab = 0
    @State private var editingNote: QuranNote?
    @State private var editedContent = ""

    var body: some View {
        VStack(spacing: 12) {
            Picker("", selection: $selectedTab) {
                Text(tabTitle(theme.t("quran_action_bookmarks"), count: quranStore.bookmarks.count)).tag(0)
                Text(tabTitle(theme.t("bookmarks_saved_notes"), count: quranStore.notes.count)).tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 18)
            .padding(.top, 8)

            if selectedTab == 0 {
                bookmarksList
            } else {
                notesList
            }
        }
        .background(Color.clear)
        .navigationTitle(theme.t("bookmarks_screen_title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingNote) { note in
            NavigationStack {
                VStack {
                    TextEditor(text: $editedContent)
                        .font(theme.scaledFont(size: 15))
                        .frame(minHeight: 160)
                        .padding(10)
                        .background(theme.surfaceVariant.opacity(0.45), in: RoundedRectangle(cornerRadius: 14))
                    Spacer()
                }
                .padding(18)
                .navigationTitle(theme.t("bookmarks_edit_note"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(theme.t("settings_cancel")) { editingNote = nil }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(theme.t("settings_save")) {
                            quranStore.updateNote(note, content: editedContent)
                            editingNote = nil
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    @ViewBuilder
    private var bookmarksList: some View {
        if quranStore.bookmarks.isEmpty {
            VStack(spacing: 12) {
                Spacer()
                Image(systemName: "bookmark")
                    .font(.system(size: 48))
                    .foregroundStyle(theme.outline.opacity(0.5))
                Text(theme.t("quran_no_bookmarks"))
                    .font(theme.scaledFont(size: 15, weight: .medium))
                    .foregroundStyle(theme.outline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(quranStore.bookmarks) { bm in
                        Button {
                            onOpenAyah(bm.surahNumber, bm.ayahNumber)
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(theme.primary.opacity(0.12))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: bm.isPageBookmark ? "book.fill" : "bookmark.fill")
                                        .foregroundStyle(theme.primary)
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    if let page = bm.pageNumber {
                                        Text(theme.t("reader_page_bookmark_name", theme.digits(String(page))))
                                            .font(theme.scaledFont(size: 15.5, weight: .black))
                                            .foregroundStyle(theme.onSurface)
                                        Text(theme.t("reader_page_bookmark_detail", bm.surahName, theme.digits(String(bm.ayahNumber))))
                                            .font(theme.scaledFont(size: 12.5))
                                            .foregroundStyle(theme.onSurfaceVariant)
                                    } else {
                                        Text(bm.surahName)
                                            .font(theme.scaledFont(size: 15.5, weight: .black))
                                            .foregroundStyle(theme.onSurface)
                                        Text(theme.t("quran_ayah_label", theme.digits(String(bm.ayahNumber))))
                                            .font(theme.scaledFont(size: 12.5))
                                            .foregroundStyle(theme.onSurfaceVariant)
                                        if let custom = bm.name, !custom.isEmpty {
                                            Text(custom)
                                                .font(theme.scaledFont(size: 12.5, weight: .semibold))
                                                .foregroundStyle(theme.primary)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Button {
                                    quranStore.removeBookmark(bm)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(theme.error.opacity(0.7))
                                        .frame(width: 36, height: 36)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(14)
                            .sirajCardSurface(cornerRadius: 20)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 108)
            }
            .scrollIndicators(.hidden)
        }
    }

    @ViewBuilder
    private var notesList: some View {
        if quranStore.notes.isEmpty {
            VStack(spacing: 12) {
                Spacer()
                Image(systemName: "note.text")
                    .font(.system(size: 48))
                    .foregroundStyle(theme.outline.opacity(0.5))
                Text(theme.t("quran_polish_action_note_description"))
                    .font(theme.scaledFont(size: 15, weight: .medium))
                    .foregroundStyle(theme.outline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(quranStore.notes) { note in
                        let sName = quranStore.surahs.first(where: { $0.number == note.surahNumber })
                            .map { SurahNames.forLanguage($0, language: theme.language) }
                            ?? theme.t("surah_number_fallback", theme.digits(String(note.surahNumber)))
                        Button {
                            onOpenAyah(note.surahNumber, note.ayahNumber)
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("\(sName) • \(theme.t("ayah_number_label", theme.digits(String(note.ayahNumber))))")
                                        .font(theme.scaledFont(size: 12, weight: .bold))
                                        .foregroundStyle(theme.primary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(theme.primary.opacity(0.11), in: RoundedRectangle(cornerRadius: 8))

                                    Spacer()

                                    Button {
                                        editedContent = note.content
                                        editingNote = note
                                    } label: {
                                        Image(systemName: "pencil")
                                            .font(.system(size: 14))
                                            .foregroundStyle(theme.onSurfaceVariant)
                                            .frame(width: 30, height: 30)
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        quranStore.deleteNote(note)
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.system(size: 14))
                                            .foregroundStyle(theme.error.opacity(0.7))
                                            .frame(width: 30, height: 30)
                                    }
                                    .buttonStyle(.plain)
                                }

                                Text(note.content)
                                    .font(theme.scaledFont(size: 15))
                                    .foregroundStyle(theme.onSurface)
                                    .lineLimit(6)
                                    .multilineTextAlignment(.leading)

                                Text(Date(timeIntervalSince1970: note.timestamp).formatted(date: .abbreviated, time: .shortened))
                                    .font(theme.scaledFont(size: 11))
                                    .foregroundStyle(theme.outline)
                            }
                            .padding(16)
                            .sirajCardSurface(cornerRadius: 20)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 108)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func tabTitle(_ title: String, count: Int) -> String {
        count > 0 ? "\(title) (\(theme.digits(String(count))))" : title
    }
}
