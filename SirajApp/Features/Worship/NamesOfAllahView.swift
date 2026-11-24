import SwiftUI
import UIKit
import SirajCore

struct NamesOfAllahView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    let worshipStore: WorshipStore

    @State private var searchQuery = ""
    @State private var selectedNumber: Int?

    private var names: [AllahName] {
        worshipStore.allahNames
    }

    private var nameOfTheDay: AllahName? {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: appState.currentTime) ?? 1
        return AllahNamesCatalog.nameOfTheDay(from: names, dayOfYear: dayOfYear)
    }

    private var filteredNames: [AllahName] {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return names }
        return names.filter { name in
            SearchFolding.matchesFolded(
                query: searchQuery,
                fields: [
                    name.nameAr, name.transliteration,
                    name.meaningEn, name.descriptionEn,
                    name.meaningAr, name.descriptionAr,
                    name.meaningTr, name.descriptionTr,
                    name.meaningUr, name.descriptionUr
                ]
            )
        }
    }

    private var gridColumns: [GridItem] {
        let minWidth: CGFloat = appState.settings.textScale >= 1.2 ? 240 : 156
        return [GridItem(.adaptive(minimum: minWidth), spacing: 12)]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, let hero = nameOfTheDay {
                    nameOfTheDayCard(hero)
                }

                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(theme.primary)
                    TextField(theme.t("names_of_allah_search_hint"), text: $searchQuery)
                        .font(theme.scaledFont(size: 14.5))
                        .foregroundStyle(theme.onSurface)
                    if !searchQuery.isEmpty {
                        Button { searchQuery = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(theme.outline)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(theme.t("tools_names_clear_search"))
                    }
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 48)
                .sirajCardSurface(cornerRadius: 18, isElevated: true)

                if filteredNames.isEmpty {
                    VStack(spacing: 8) {
                        Text(theme.t("tools_names_empty_title"))
                            .font(theme.scaledFont(size: 16, weight: .bold))
                            .foregroundStyle(theme.onSurface)
                            .multilineTextAlignment(.center)
                        Text(theme.t("tools_names_empty_body"))
                            .font(theme.scaledFont(size: 14))
                            .foregroundStyle(theme.onSurfaceVariant)
                            .multilineTextAlignment(.center)
                        Button {
                            searchQuery = ""
                        } label: {
                            Text(theme.t("tools_names_clear_search"))
                                .font(theme.scaledFont(size: 14, weight: .bold))
                                .foregroundStyle(theme.primary)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                } else {
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        ForEach(filteredNames) { name in
                            nameGridCard(name)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
        .background(Color.clear)
        .navigationTitle(theme.t("names_of_allah_title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: Binding(
            get: { selectedNumber != nil },
            set: { if !$0 { selectedNumber = nil } }
        )) {
            if let num = selectedNumber {
                NameDetailSheet(
                    names: names,
                    number: num,
                    onSelectNumber: { selectedNumber = $0 }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private func nameOfTheDayCard(_ name: AllahName) -> some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)
        let soft = theme.primary.opacity(theme.isDark ? 0.16 : 0.10)

        return Button {
            selectedNumber = name.number
        } label: {
            ZStack(alignment: .topTrailing) {
                Image("ic_siraj_allah_word")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 118, height: 118)
                    .foregroundStyle(theme.primary.opacity(0.09))
                    .rotationEffect(.degrees(-12))
                    .padding(.top, 8)
                    .padding(.trailing, 8)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(theme.primary)
                        Text(theme.t("names_day_badge"))
                            .font(theme.scaledFont(size: 11.5, weight: .black))
                            .foregroundStyle(theme.primary)
                        Text(theme.digits(String(name.number)))
                            .font(theme.scaledFont(size: 11.5, weight: .bold))
                            .foregroundStyle(theme.primary.opacity(0.7))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(soft))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(theme.primary.opacity(0.35), lineWidth: 0.8))

                    Text(name.nameAr)
                        .font(theme.amiriFont(size: 40, weight: .bold))
                        .foregroundStyle(theme.primary)
                        .padding(.top, 10)

                    if !theme.language.hasPrefix("ar") {
                        Text(name.transliteration)
                            .font(theme.scaledFont(size: 16, weight: .black))
                            .foregroundStyle(theme.onSurface)
                            .padding(.top, 2)
                    }

                    Text(name.meaning(language: theme.language))
                        .font(theme.scaledFont(size: 14))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 3)

                    Divider()
                        .overlay(theme.primary.opacity(0.22))
                        .padding(.vertical, 14)

                    Text(theme.t("names_hadith_text"))
                        .font(theme.scaledFont(size: 12.5, weight: .semibold))
                        .foregroundStyle(theme.onSurface)
                        .multilineTextAlignment(.leading)

                    Text(theme.t("names_hadith_source"))
                        .font(theme.scaledFont(size: 11.5))
                        .foregroundStyle(theme.primary)
                        .padding(.top, 3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }
            .background {
                if !theme.isGlass {
                    shape.fill(
                        LinearGradient(
                            colors: [theme.primaryContainer.opacity(theme.isDark ? 0.55 : 0.85), theme.surface],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                } else {
                    shape.fill(
                        LinearGradient(
                            colors: [theme.primary.opacity(theme.isDark ? 0.16 : 0.10), .clear],
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

    private func nameGridCard(_ name: AllahName) -> some View {
        let soft = theme.primary.opacity(theme.isDark ? 0.16 : 0.10)
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)

        return Button {
            if appState.settings.isHapticEnabled {
                UISelectionFeedbackGenerator().selectionChanged()
            }
            selectedNumber = name.number
        } label: {
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [soft, .clear], startPoint: .top, endPoint: .bottom)
                    .clipShape(shape)

                Text(theme.digits(String(name.number)))
                    .font(theme.scaledFont(size: 11, weight: .black))
                    .foregroundStyle(theme.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(soft))
                    .padding(10)

                VStack(spacing: 3) {
                    Text(name.nameAr)
                        .font(theme.amiriFont(size: 28, weight: .bold))
                        .foregroundStyle(theme.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    if !theme.language.hasPrefix("ar") {
                        Text(name.transliteration)
                            .font(theme.scaledFont(size: 13.5, weight: .black))
                            .foregroundStyle(theme.onSurface)
                            .lineLimit(1)
                    }

                    Text(name.meaning(language: theme.language))
                        .font(theme.scaledFont(size: 12))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.top, 34)
                .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, minHeight: 168)
            .sirajCardSurface(cornerRadius: 22)
        }
        .buttonStyle(.plain)
    }
}

private struct NameDetailSheet: View {
    @Environment(\.sirajTheme) private var theme
    let names: [AllahName]
    let number: Int
    let onSelectNumber: (Int) -> Void

    var body: some View {
        guard let index = names.firstIndex(where: { $0.number == number }) else {
            return AnyView(EmptyView())
        }
        let name = names[index]
        let soft = theme.primary.opacity(theme.isDark ? 0.16 : 0.10)
        let previous = index > 0 ? names[index - 1] : nil
        let next = index + 1 < names.count ? names[index + 1] : nil
        let shareBody = "\(name.nameAr)\n\(name.transliteration)\n\(name.meaning(language: theme.language))\n\n\(name.description(language: theme.language))"

        return AnyView(
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(soft)
                                .frame(width: 44, height: 44)
                                .overlay(Circle().strokeBorder(theme.primary.opacity(0.4), lineWidth: 1))
                            Text(theme.digits(String(name.number)))
                                .font(theme.scaledFont(size: 14, weight: .black))
                                .foregroundStyle(theme.primary)
                        }

                        Text(name.nameAr)
                            .font(theme.amiriFont(size: 46, weight: .bold))
                            .foregroundStyle(theme.primary)
                            .multilineTextAlignment(.center)

                        if !theme.language.hasPrefix("ar") {
                            Text(name.transliteration)
                                .font(theme.scaledFont(size: 17, weight: .black))
                                .foregroundStyle(theme.onSurface)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [theme.primaryContainer.opacity(theme.isDark ? 0.45 : 0.75), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )

                    if !theme.language.hasPrefix("ar") {
                        Text(name.meaning(language: theme.language))
                            .font(theme.scaledFont(size: 16, weight: .bold))
                            .foregroundStyle(theme.onSurface)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(soft))
                    }

                    Text(name.description(language: theme.language))
                        .font(theme.scaledFont(size: 16))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)

                    ShareLink(item: shareBody) {
                        Label(theme.t("quran_action_share"), systemImage: "square.and.arrow.up")
                            .font(theme.scaledFont(size: 13.5, weight: .semibold))
                            .foregroundStyle(theme.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(soft))
                    }
                    .buttonStyle(.plain)

                    HStack {
                        Button {
                            if let previous {
                                UISelectionFeedbackGenerator().selectionChanged()
                                onSelectNumber(previous.number)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: theme.isRTL ? "chevron.right" : "chevron.left")
                                Text(theme.t("previous"))
                                    .font(theme.scaledFont(size: 14, weight: .bold))
                            }
                            .foregroundStyle(previous != nil ? theme.primary : theme.outline.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                        .disabled(previous == nil)

                        Spacer()

                        Text(theme.digits("\(name.number) / \(names.count)"))
                            .font(theme.scaledFont(size: 12.5, weight: .semibold))
                            .foregroundStyle(theme.onSurfaceVariant)

                        Spacer()

                        Button {
                            if let next {
                                UISelectionFeedbackGenerator().selectionChanged()
                                onSelectNumber(next.number)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(theme.t("next"))
                                    .font(theme.scaledFont(size: 14, weight: .bold))
                                Image(systemName: theme.isRTL ? "chevron.left" : "chevron.right")
                            }
                            .foregroundStyle(next != nil ? theme.primary : theme.outline.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                        .disabled(next == nil)
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
        )
    }
}
