import SwiftUI
import SirajCore

struct QuranSettingsView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    let quranStore: QuranStore

    @State private var showTafsirLibrary = false

    private var edition: MushafEdition {
        MushafEdition.resolve(appState.settings.mushafEdition)
    }

    var body: some View {
        let fontScaleBinding = Binding<Double>(
            get: { appState.settings.quranFontSizeMultiplier },
            set: { val in appState.updateSettings { $0.quranFontSizeMultiplier = (val * 20).rounded() / 20 } }
        )
        let numeralBinding = Binding<Bool>(
            get: { appState.settings.isQuranNumeralException },
            set: { val in appState.updateSettings { $0.isQuranNumeralException = val } }
        )
        let dashboardCardBinding = Binding<Bool>(
            get: { appState.settings.isLastBookmarkOnDashboard },
            set: { val in appState.updateSettings { $0.isLastBookmarkOnDashboard = val } }
        )

        ScrollView {
            VStack(spacing: 22) {
                // 1. Mushaf edition
                SirajSettingsSection(title: theme.t("quran_mushaf_edition_header"), icon: "book.pages.fill") {
                    editionRow(.madinah, titleKey: "mushaf_name_madinah_v1", descKey: "quran_edition_madinah_desc")
                    Divider().padding(.leading, 16)
                    editionRow(.indopak, titleKey: "mushaf_name_indopak", descKey: "quran_edition_indopak_desc")
                    Divider().padding(.leading, 16)
                    editionRow(.shamarly, titleKey: "mushaf_name_shamarly", descKey: "quran_edition_shamarly_desc")
                }

                // 2. Font size + live edition preview
                SirajSettingsSection(title: theme.t("quran_font_size_header"), icon: "textformat.size") {
                    VStack(spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(theme.t("quran_font_size_title"))
                                    .font(theme.scaledFont(size: 15, weight: .bold))
                                    .foregroundStyle(theme.onSurface)
                                Text(theme.t("quran_font_size_desc"))
                                    .font(theme.scaledFont(size: 12))
                                    .foregroundStyle(theme.onSurfaceVariant)
                            }
                            Spacer()
                            Text("\(theme.digits(String(Int((appState.settings.quranFontSizeMultiplier * 100).rounded()))))%")
                                .font(theme.scaledFont(size: 12.5, weight: .black))
                                .foregroundStyle(theme.onPrimaryContainer)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(theme.primaryContainer, in: RoundedRectangle(cornerRadius: 8))
                        }

                        HStack(spacing: 10) {
                            Button {
                                appState.updateSettings { $0.quranFontSizeMultiplier = max(0.8, $0.quranFontSizeMultiplier - 0.05) }
                            } label: {
                                Text("A-")
                                    .font(.system(size: 13, weight: .black))
                                    .frame(width: 36, height: 36)
                                    .background(theme.surfaceVariant.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)

                            Slider(value: fontScaleBinding, in: 0.8...1.6, step: 0.05)
                                .tint(theme.primary)

                            Button {
                                appState.updateSettings { $0.quranFontSizeMultiplier = min(1.6, $0.quranFontSizeMultiplier + 0.05) }
                            } label: {
                                Text("A+")
                                    .font(.system(size: 14, weight: .black))
                                    .frame(width: 36, height: 36)
                                    .background(theme.surfaceVariant.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }

                        liveScriptPreview
                    }
                    .padding(14)
                }

                // 3. Reading layout & landscape
                SirajSettingsSection(title: theme.t("quran_scroll_direction_header"), icon: "rectangle.split.2x1") {
                    choiceRow(
                        title: theme.t("quran_scroll_direction_horizontal"),
                        subtitle: theme.t("settings_quran_scroll_horizontal_desc"),
                        selected: appState.settings.quranScrollDirection == "Horizontal"
                    ) {
                        appState.updateSettings { $0.quranScrollDirection = "Horizontal" }
                    }
                    Divider().padding(.leading, 16)
                    choiceRow(
                        title: theme.t("quran_scroll_direction_vertical"),
                        subtitle: theme.t("settings_quran_scroll_vertical_desc"),
                        selected: appState.settings.quranScrollDirection == "Vertical"
                    ) {
                        appState.updateSettings { $0.quranScrollDirection = "Vertical" }
                    }
                }

                SirajSettingsSection(title: theme.t("reader_landscape_header"), icon: "rectangle.landscape") {
                    choiceRow(
                        title: theme.t("reader_landscape_single"),
                        subtitle: theme.t("reader_landscape_single_desc"),
                        selected: appState.settings.quranLandscapeLayout != "Double"
                    ) {
                        appState.updateSettings { $0.quranLandscapeLayout = "Single" }
                    }
                    Divider().padding(.leading, 16)
                    choiceRow(
                        title: theme.t("reader_landscape_double"),
                        subtitle: theme.t("reader_landscape_double_desc"),
                        selected: appState.settings.quranLandscapeLayout == "Double"
                    ) {
                        appState.updateSettings { $0.quranLandscapeLayout = "Double" }
                    }
                }

                // 4. Page colour (Auto / Light / Dark + Day & Night swatches + live Mushaf preview)
                mushafPaperSection

                // 5. Numerals & Dashboard card
                SirajSettingsSection(title: theme.t("quran_numerals_header"), icon: "textformat.123") {
                    SirajSettingsToggleRow(
                        icon: "textformat.123",
                        title: theme.t("settings_quran_numeral_exception"),
                        subtitle: theme.t("settings_quran_numeral_desc"),
                        isOn: numeralBinding
                    )
                    Divider().padding(.leading, 16)
                    SirajSettingsToggleRow(
                        icon: "bookmark.fill",
                        title: theme.t("quran_continue_reading"),
                        subtitle: theme.t("quran_reading"),
                        isOn: dashboardCardBinding
                    )
                    Divider().padding(.leading, 16)
                    SirajSettingsToggleRow(
                        icon: "waveform",
                        title: theme.t("quran_player_progress_title"),
                        subtitle: theme.t("quran_player_progress_desc"),
                        isOn: Binding(
                            get: { appState.settings.isPlayerProgressBarEnabled },
                            set: { val in appState.updateSettings { $0.isPlayerProgressBarEnabled = val } }
                        )
                    )
                }

                // 6. Tafsir & Translation
                SirajSettingsSection(title: theme.t("quran_tafsir_offline_header"), icon: "books.vertical.fill") {
                    let book = TafsirBook.byId(appState.settings.selectedTafsirEdition)
                    SirajSettingsRow(
                        icon: "text.book.closed.fill",
                        title: theme.t("quran_tafsir_row"),
                        value: book?.title ?? appState.settings.selectedTafsirEdition
                    ) {
                        showTafsirLibrary = true
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 108)
        }
        .scrollIndicators(.hidden)
        .background(Color.clear)
        .navigationTitle(theme.t("settings_quran_mushaf"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTafsirLibrary) {
            TafsirLibraryView(
                appState: appState,
                quranStore: quranStore,
                onSelectBook: { bookId in
                    appState.updateSettings { $0.selectedTafsirEdition = bookId }
                    showTafsirLibrary = false
                }
            )
        }
    }

    private func editionRow(_ target: MushafEdition, titleKey: String, descKey: String) -> some View {
        choiceRow(
            title: theme.t(titleKey),
            subtitle: theme.t(descKey),
            selected: edition == target
        ) {
            appState.updateSettings { $0.mushafEdition = target.rawValue }
        }
    }

    private func choiceRow(title: String, subtitle: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(theme.scaledFont(size: 14.5, weight: .bold))
                        .foregroundStyle(theme.onSurface)
                    Text(subtitle)
                        .font(theme.scaledFont(size: 12))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(selected ? theme.primary : theme.outlineVariant)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var liveScriptPreview: some View {
        let scale = CGFloat(appState.settings.quranFontSizeMultiplier)
        let size = 21.0 * scale

        return VStack(spacing: 10) {
            Text(theme.t("quran_font_preview_label"))
                .font(theme.scaledFont(size: 11.5, weight: .bold))
                .foregroundStyle(theme.primary)

            Group {
                if edition == .shamarly {
                    VStack(spacing: 8) {
                        Text(ShamarlyText.quote("\u{0628}\u{0650}\u{0633}\u{06E1}\u{0645}\u{0650} \u{0671}\u{0644}\u{0644}\u{0651}\u{064E}\u{0647}\u{0650} \u{0671}\u{0644}\u{0631}\u{0651}\u{064E}\u{062D}\u{06E1}\u{0645}\u{064E}\u{0670}\u{0646}\u{0650} \u{0671}\u{0644}\u{0631}\u{0651}\u{064E}\u{062D}\u{0650}\u{064A}\u{0645}\u{0650} \u{0661}"))
                        Text(ShamarlyText.quote("\u{0671}\u{0644}\u{06E1}\u{062D}\u{064E}\u{0645}\u{06E1}\u{062F}\u{064F} \u{0644}\u{0650}\u{0644}\u{0651}\u{064E}\u{0647}\u{0650} \u{0631}\u{064E}\u{0628}\u{0651}\u{0650} \u{0671}\u{0644}\u{06E1}\u{0639}\u{064E}\u{0670}\u{0644}\u{064E}\u{0645}\u{0650}\u{064A}\u{0646}\u{064E} \u{0662}"))
                    }
                    .font(.custom("AmiriQuran-Regular", size: size))
                } else if edition == .indopak {
                    VStack(spacing: 8) {
                        Text("\u{0628}\u{0650}\u{0633}\u{0652}\u{0645}\u{0650} \u{0627}\u{0644}\u{0644}\u{0651}\u{0670}\u{0647}\u{0650} \u{0627}\u{0644}\u{0631}\u{0651}\u{064E}\u{062D}\u{0652}\u{0645}\u{0670}\u{0646}\u{0650} \u{0627}\u{0644}\u{0631}\u{0651}\u{064E}\u{062D}\u{0650}\u{06CC}\u{0652}\u{0645}\u{0650}")
                        Text("\u{0627}\u{064E}\u{0644}\u{0652}\u{062D}\u{064E}\u{0645}\u{0652}\u{062F}\u{064F} \u{0644}\u{0650}\u{0644}\u{0651}\u{0670}\u{0647}\u{0650} \u{0631}\u{064E}\u{0628}\u{0651}\u{0650} \u{0627}\u{0644}\u{0652}\u{0639}\u{0670}\u{0644}\u{064E}\u{0645}\u{0650}\u{06CC}\u{0652}\u{0646}\u{064E}")
                    }
                    .font(.custom("AlQuranIndoPakbyQuranWBW", size: size * 0.92))
                } else {
                    VStack(spacing: 8) {
                        Text(DigitalKhattText.forDisplay("بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِيمِ"))
                        HStack(spacing: 6) {
                            Text(DigitalKhattText.forDisplay("ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَـٰلَمِينَ"))
                            AyahEndSymbol(ayahNumber: 1, size: 22 * scale, color: MushafColors.mushafGold.color, textColor: theme.isDark ? MushafColors.mushafGold.color : Color(hex: 0xFF5D4037))
                        }
                    }
                    .font(.custom("DigitalKhattOldMadinaRegular", size: size))
                }
            }
            .foregroundStyle(theme.onSurface)
            .multilineTextAlignment(.center)
            .environment(\.layoutDirection, .rightToLeft)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(theme.surfaceVariant.opacity(0.32), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var mushafPaperSection: some View {
        let qTheme = appState.settings.quranTheme
        let dayOption = appState.settings.quranPaperColor
        let nightOption = appState.settings.quranDarkStyle
        let dayColors = MushafColors.resolvePrinted(isDark: false, isBlackMode: false, paperColor: dayOption)
        let nightColors = MushafColors.resolvePrinted(isDark: true, isBlackMode: appState.settings.isAmoled || nightOption == "Black", darkStyle: nightOption)

        let dayOptions: [(id: String, titleKey: String, descKey: String)] = [
            ("Yellowish", "settings_mushaf_color_yellowish_title", "settings_mushaf_color_yellowish_desc"),
            ("White", "settings_mushaf_color_white_title", "settings_mushaf_color_white_desc"),
            ("Sepia", "settings_mushaf_color_sepia_title", "settings_mushaf_color_sepia_desc")
        ]
        let nightOptions: [(id: String, titleKey: String, descKey: String)] = [
            ("Dark", "settings_mushaf_dark_charcoal_title", "settings_mushaf_dark_charcoal_desc"),
            ("Black", "settings_mushaf_dark_black_title", "settings_mushaf_dark_black_desc"),
            ("Navy", "settings_mushaf_dark_navy_title", "settings_mushaf_dark_navy_desc")
        ]

        return SirajSettingsSection(title: theme.t("settings_mushaf_appearance_header"), icon: "swatchpalette.fill") {
            VStack(spacing: 14) {
                if qTheme == "Light" {
                    paperPreviewCard(paper: dayColors.paper.color, ink: dayColors.ink.color, label: theme.t("settings_mushaf_theme_light_title"), compact: false, isCurrent: false)
                } else if qTheme == "Dark" {
                    paperPreviewCard(paper: nightColors.paper.color, ink: nightColors.ink.color, label: theme.t("settings_mushaf_theme_dark_title"), compact: false, isCurrent: false)
                } else {
                    HStack(spacing: 10) {
                        paperPreviewCard(paper: dayColors.paper.color, ink: dayColors.ink.color, label: theme.t("settings_mushaf_theme_light_title"), compact: true, isCurrent: !theme.isDark)
                        paperPreviewCard(paper: nightColors.paper.color, ink: nightColors.ink.color, label: theme.t("settings_mushaf_theme_dark_title"), compact: true, isCurrent: theme.isDark)
                    }
                }

                Picker("", selection: Binding(
                    get: { appState.settings.quranTheme },
                    set: { val in appState.updateSettings { $0.quranTheme = val } }
                )) {
                    Text(theme.t("settings_mushaf_theme_system_title")).tag("System")
                    Text(theme.t("settings_mushaf_theme_light_title")).tag("Light")
                    Text(theme.t("settings_mushaf_theme_dark_title")).tag("Dark")
                }
                .pickerStyle(.segmented)

                if qTheme != "Dark" {
                    paperSwatchGroup(
                        title: theme.t("quran_paper_color_title"),
                        options: dayOptions,
                        selectedId: dayOption,
                        colorsFor: { id in MushafColors.resolvePrinted(isDark: false, isBlackMode: false, paperColor: id) }
                    ) { picked in
                        appState.updateSettings { $0.quranPaperColor = picked }
                    }
                }

                if qTheme != "Light" {
                    if qTheme != "Dark" { Divider() }
                    paperSwatchGroup(
                        title: theme.t("quran_dark_mode_title"),
                        options: nightOptions,
                        selectedId: nightOption,
                        colorsFor: { id in MushafColors.resolvePrinted(isDark: true, isBlackMode: id == "Black", darkStyle: id) }
                    ) { picked in
                        appState.updateSettings { $0.quranDarkStyle = picked }
                    }

                    if appState.settings.isAmoled {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(theme.primary)
                            Text(theme.t("settings_mushaf_black_override"))
                                .font(theme.scaledFont(size: 12))
                                .foregroundStyle(theme.onSurfaceVariant)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(14)
        }
    }

    private func paperPreviewCard(paper: Color, ink: Color, label: String, compact: Bool, isCurrent: Bool) -> some View {
        VStack(spacing: compact ? 6 : 8) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(ink.opacity(0.85))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(ink.opacity(0.08), in: Capsule())
                Spacer()
                if isCurrent {
                    Text(theme.t("settings_mushaf_preview_now"))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(theme.onPrimary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(theme.primary, in: Capsule())
                }
            }

            Text("سُورَةُ الفَاتِحَةِ")
                .font(theme.amiriFont(size: compact ? 11 : 13, weight: .bold))
                .foregroundStyle(ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 3)
                .background(theme.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(theme.primary.opacity(0.5), lineWidth: 1))

            Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ")
                .font(theme.amiriFont(size: compact ? 12.5 : 17))
                .foregroundStyle(ink)
                .lineLimit(1)

            Text("ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ")
                .font(theme.amiriFont(size: compact ? 11.5 : 15))
                .foregroundStyle(ink)
                .lineLimit(1)
        }
        .padding(compact ? 10 : 14)
        .frame(maxWidth: .infinity)
        .background(paper, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(isCurrent ? theme.primary : ink.opacity(0.16), lineWidth: isCurrent ? 2 : 1)
        )
    }

    private func paperSwatchGroup(
        title: String,
        options: [(id: String, titleKey: String, descKey: String)],
        selectedId: String,
        colorsFor: @escaping (String) -> (paper: ArgbColor, ink: ArgbColor),
        onSelect: @escaping (String) -> Void
    ) -> some View {
        let activeDesc = options.first(where: { $0.id == selectedId })?.descKey ?? options[0].descKey
        return VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(theme.scaledFont(size: 13.5, weight: .bold))
                .foregroundStyle(theme.onSurface)

            HStack(spacing: 10) {
                ForEach(options, id: \.id) { opt in
                    let pair = colorsFor(opt.id)
                    let selected = opt.id == selectedId
                    Button {
                        onSelect(opt.id)
                    } label: {
                        VStack(spacing: 6) {
                            ZStack(alignment: .topTrailing) {
                                VStack(spacing: 5) {
                                    Text("بِسْمِ ٱللَّهِ")
                                        .font(theme.amiriFont(size: 14))
                                        .foregroundStyle(pair.ink.color)
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(pair.ink.color.opacity(0.22))
                                        .frame(width: 44, height: 2)
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(pair.ink.color.opacity(0.22))
                                        .frame(width: 30, height: 2)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 68)
                                .background(pair.paper.color, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .padding(selected ? 3 : 1)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(selected ? theme.primary : pair.ink.color.opacity(0.2), lineWidth: selected ? 2.2 : 1)
                                )

                                if selected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(theme.primary)
                                        .padding(5)
                                }
                            }
                            Text(theme.t(opt.titleKey))
                                .font(theme.scaledFont(size: 12, weight: selected ? .bold : .medium))
                                .foregroundStyle(selected ? theme.primary : theme.onSurface)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(theme.t(activeDesc))
                .font(theme.scaledFont(size: 12))
                .foregroundStyle(theme.onSurfaceVariant)
        }
    }
}
