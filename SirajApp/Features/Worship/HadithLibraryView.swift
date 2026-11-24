import SwiftUI
import UIKit
import SirajCore

struct HadithLibraryView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    let initialHadithId: String?

    @State private var searchQuery = ""
    @State private var selectedCategory: String?
    @State private var detailHadith: OfflineDailyHadith?
    @State private var showCopiedToast = false

    private var allHadiths: [OfflineDailyHadith] {
        DailyQuotesCatalog.hadiths
    }

    private var categories: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for h in allHadiths {
            let cat = h.localizedCategory(language: theme.language)
            if seen.insert(cat).inserted {
                result.append(cat)
            }
        }
        return result
    }

    private var filteredHadiths: [OfflineDailyHadith] {
        allHadiths.filter { h in
            let matchCat = selectedCategory == nil || h.localizedCategory(language: theme.language) == selectedCategory
            let matchSearch = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || SearchFolding.matchesFolded(
                query: searchQuery,
                fields: [
                    h.titleAr, h.textAr, h.titleEn, h.translationEn,
                    h.localizedTranslation(language: theme.language) ?? "",
                    h.localizedTitle(language: theme.language),
                    h.categoryAr, h.categoryEn, h.localizedCategory(language: theme.language)
                ]
            )
            return matchCat && matchSearch
        }
    }

    var body: some View {
        let isArabic = theme.language.hasPrefix("ar")

        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(theme.outline)
                    TextField(theme.t("hadith_search_hint"), text: $searchQuery)
                        .font(theme.scaledFont(size: 14.5))
                        .foregroundStyle(theme.onSurface)
                    if !searchQuery.isEmpty {
                        Button { searchQuery = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(theme.outline)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(theme.t("tools_hadith_clear_search"))
                    }
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 48)
                .sirajCardSurface(cornerRadius: 16, isElevated: true)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 6)

                // Category Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        let allLabel = theme.t("hadith_filter_all", theme.digits(String(allHadiths.count)))
                        categoryChip(title: allLabel, selected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        ForEach(categories, id: \.self) { category in
                            categoryChip(title: category, selected: selectedCategory == category) {
                                selectedCategory = (selectedCategory == category) ? nil : category
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                }

                // Hadith Cards
                ScrollView {
                    LazyVStack(spacing: 14) {
                        if filteredHadiths.isEmpty {
                            hadithEmptyState
                        } else {
                            ForEach(filteredHadiths) { hadith in
                                hadithCard(hadith, isArabic: isArabic)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
            }

            if showCopiedToast {
                Text(theme.t("hadith_copied"))
                    .font(theme.scaledFont(size: 13, weight: .bold))
                    .foregroundStyle(theme.onPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(theme.primary))
                    .padding(.bottom, 104)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Color.clear)
        .navigationTitle(theme.t("hub_hadith_title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let initialHadithId, detailHadith == nil {
                detailHadith = allHadiths.first { $0.id == initialHadithId }
            }
        }
        .sheet(item: $detailHadith) { hadith in
            HadithDetailSheet(
                hadith: hadith,
                showExplanation: appState.settings.isShowVirtues,
                shareText: shareBody(for: hadith),
                onCopy: { copyHadith(hadith) }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private func categoryChip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(theme.scaledFont(size: 13, weight: selected ? .bold : .medium))
                .foregroundStyle(selected ? theme.onPrimary : theme.onSurface)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(selected ? theme.primary : (theme.isGlass ? Color.clear : theme.surfaceVariant.opacity(0.6)))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(selected ? Color.clear : theme.outlineVariant.opacity(0.45), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func hadithCard(_ hadith: OfflineDailyHadith, isArabic: Bool) -> some View {
        let isUrdu = theme.language.hasPrefix("ur")

        return Button {
            detailHadith = hadith
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 8) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(theme.primary.opacity(0.12))
                                .frame(width: 34, height: 34)
                            Text(theme.digits(hadith.id))
                                .font(theme.scaledFont(size: 13.5, weight: .black))
                                .foregroundStyle(theme.primary)
                        }
                        Text(hadith.localizedTitle(language: theme.language))
                            .font(theme.scaledFont(size: 15.5, weight: .black))
                            .foregroundStyle(theme.onSurface)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 4)

                    Text(hadith.localizedCategory(language: theme.language))
                        .font(theme.scaledFont(size: 11, weight: .bold))
                        .foregroundStyle(theme.primary)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(theme.primaryContainer.opacity(0.35))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(theme.primary.opacity(0.25), lineWidth: 0.8)
                        )
                }

                Text(hadith.textAr)
                    .font(theme.amiriFont(size: 19))
                    .foregroundStyle(theme.onSurface)
                    .lineSpacing(9)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(isArabic ? 4 : 3)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .environment(\.layoutDirection, .rightToLeft)

                if let translation = hadith.localizedTranslation(language: theme.language) {
                    let rtl = isUrdu && hadith.hasOwnTranslation(language: theme.language)
                    Text(translation)
                        .font(theme.scaledFont(size: 13))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .lineSpacing(3)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .environment(\.layoutDirection, rtl ? .rightToLeft : .leftToRight)
                }

                HStack(alignment: .center) {
                    Text(isArabic ? hadith.referenceAr : hadith.referenceEn)
                        .font(theme.scaledFont(size: 11.5, weight: .medium))
                        .foregroundStyle(theme.outline)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 4) {
                        Button {
                            copyHadith(hadith)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 15))
                                .foregroundStyle(theme.outline)
                                .frame(width: 34, height: 34)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(theme.t("quran_action_copy"))

                        ShareLink(item: shareBody(for: hadith)) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 15))
                                .foregroundStyle(theme.primary)
                                .frame(width: 34, height: 34)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(theme.t("quran_action_share"))
                    }
                }
            }
            .padding(18)
            .sirajCardSurface(cornerRadius: 22)
        }
        .buttonStyle(.plain)
    }

    private var hadithEmptyState: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.10))
                    .frame(width: 64, height: 64)
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(theme.primary)
            }
            Text(theme.t("tools_hadith_empty_title"))
                .font(theme.scaledFont(size: 16, weight: .bold))
                .foregroundStyle(theme.onSurface)
                .multilineTextAlignment(.center)
            Text(theme.t("tools_hadith_empty_body"))
                .font(theme.scaledFont(size: 14))
                .foregroundStyle(theme.onSurfaceVariant)
                .multilineTextAlignment(.center)
            Button {
                searchQuery = ""
                selectedCategory = nil
            } label: {
                Text(theme.t("tools_hadith_clear_search"))
                    .font(theme.scaledFont(size: 14, weight: .bold))
                    .foregroundStyle(theme.primary)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func shareBody(for hadith: OfflineDailyHadith) -> String {
        var lines = [hadith.localizedTitle(language: theme.language), "", hadith.textAr]
        if let tr = hadith.localizedTranslation(language: theme.language) {
            lines.append("")
            lines.append(tr)
        }
        lines.append("")
        lines.append(theme.isRTL ? hadith.referenceAr : hadith.referenceEn)
        lines.append("")
        lines.append("- \(theme.t("tools_hadith_shared_via"))")
        return lines.joined(separator: "\n")
    }

    private func copyHadith(_ hadith: OfflineDailyHadith) {
        UIPasteboard.general.string = "\(hadith.textAr)\n\n\(hadith.referenceAr)"
        withAnimation(.easeInOut(duration: 0.2)) { showCopiedToast = true }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.easeInOut(duration: 0.2)) { showCopiedToast = false }
        }
    }
}

private struct HadithDetailSheet: View {
    @Environment(\.sirajTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    let hadith: OfflineDailyHadith
    let showExplanation: Bool
    let shareText: String
    let onCopy: () -> Void

    var body: some View {
        let isUrdu = theme.language.hasPrefix("ur")

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(theme.isRTL ? hadith.narratorAr : hadith.narratorEn)
                        .font(theme.scaledFont(size: 12, weight: .bold))
                        .foregroundStyle(theme.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(theme.primaryContainer.opacity(0.5))
                        )

                    Text(hadith.textAr)
                        .font(theme.amiriFont(size: 21))
                        .foregroundStyle(theme.onSurface)
                        .lineSpacing(11)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .multilineTextAlignment(.trailing)
                        .environment(\.layoutDirection, .rightToLeft)

                    if let translation = hadith.localizedTranslation(language: theme.language) {
                        let own = hadith.hasOwnTranslation(language: theme.language)
                        let rtl = isUrdu && own
                        Text(translation)
                            .font(theme.scaledFont(size: 14.5))
                            .foregroundStyle(theme.onSurfaceVariant)
                            .lineSpacing(rtl ? 8 : 5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .environment(\.layoutDirection, rtl ? .rightToLeft : .leftToRight)

                        if !own {
                            Text(theme.t("translation_pending_notice"))
                                .font(theme.scaledFont(size: 11.5))
                                .foregroundStyle(theme.outline)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 10).fill(theme.surfaceVariant.opacity(0.5)))
                        }
                    }

                    if showExplanation, let explanation = hadith.localizedExplanation(language: theme.language) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(theme.t("hadith_explanation_heading"))
                                .font(theme.scaledFont(size: 12, weight: .bold))
                                .foregroundStyle(theme.primary)
                            Text(explanation)
                                .font(theme.scaledFont(size: 13.5))
                                .foregroundStyle(theme.onSurfaceVariant)
                                .lineSpacing(4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.surfaceVariant.opacity(0.45)))
                    }

                    Text(theme.isRTL ? hadith.referenceAr : hadith.referenceEn)
                        .font(theme.scaledFont(size: 12, weight: .bold))
                        .foregroundStyle(theme.outline)
                }
                .padding(20)
            }
            .navigationTitle(hadith.localizedTitle(language: theme.language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button(action: onCopy) {
                        Image(systemName: "doc.on.doc")
                    }
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(theme.t("close")) { dismiss() }
                }
            }
        }
    }
}
