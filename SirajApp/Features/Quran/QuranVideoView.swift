import AVFoundation
import AVKit
import Photos
import PhotosUI
import SirajCore
import SwiftUI

struct QuranVideoView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    let quranStore: QuranStore
    var initialSurah: Int = 1
    var initialAyah: Int = 1

    @State private var selectedSurah: Int = 1
    @State private var fromAyah: Int = 1
    @State private var toAyah: Int = 3
    @State private var reciterId: String = Reciter.defaultReciter.id
    @State private var background: QuranVideoBackground = .scene(.pattern)
    @State private var shape: VideoShape = .story
    @State private var quality: VideoQuality = .hd
    @State private var design = VideoDesign()
    @State private var surahAyahs: [Ayah] = []
    @State private var openingAyah: Ayah?
    @State private var underTexts: [Int: String] = [:]
    @State private var status: QuranVideoStatus = .idle
    @State private var exportTask: Task<Void, Never>?
    @State private var previewPlayer: AVPlayer?
    @State private var exportedPlayer: AVPlayer?
    @State private var isPreviewingVoice = false
    @State private var showSurahPicker = false
    @State private var showReciterPicker = false
    @State private var pickedPhotoItem: PhotosPickerItem?
    @State private var toastText: String?

    private var ayahReciters: [Reciter] {
        Reciter.readerReciters.filter { ReciterAudioURLs.hasAyahAudio($0.id) }
    }

    private var currentSurah: Surah? {
        quranStore.surahs.first { $0.number == selectedSurah }
    }

    private var currentReciter: Reciter {
        ayahReciters.first(where: { $0.id == reciterId }) ?? Reciter.defaultReciter
    }

    private var maxAyah: Int {
        max(1, currentSurah?.numberOfAyahs ?? 7)
    }

    private var previewParts: [VersePart] {
        QuranVideoPlanner.recitationParts(
            surah: selectedSurah,
            from: fromAyah,
            to: toAyah,
            ayahs: surahAyahs,
            opening: openingAyah
        )
    }

    private var previewScript: VideoScript {
        let parts = previewParts
        let perPart: Int64 = 4_000_000
        let verses = parts.enumerated().map { idx, part in
            VideoVerse(
                startUs: Int64(idx) * perPart,
                endUs: Int64(idx + 1) * perPart,
                text: part.text,
                number: part.number,
                under: part.number > 0 ? underTexts[part.global] : nil
            )
        }
        return VideoScript(
            verses: verses,
            labels: buildLabels(),
            design: design,
            durationUs: max(perPart, Int64(verses.count) * perPart)
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 20) {
                    previewStage

                    switch status {
                    case .fetching, .rendering:
                        workingCard
                    case .ready(let url, _):
                        readyCard(url: url)
                    case .failed(let msg):
                        failedCard(message: msg)
                        formSections
                    case .idle:
                        formSections
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 128)
            }
            .scrollIndicators(.hidden)

            if let toastText {
                Text(toastText)
                    .font(theme.scaledFont(size: 13, weight: .bold))
                    .foregroundStyle(theme.onPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(theme.primary, in: Capsule())
                    .padding(.bottom, 26)
            }
        }
        .background(Color.clear)
        .navigationTitle(theme.t("quran_video_title"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            selectedSurah = max(1, min(114, initialSurah))
            fromAyah = max(1, initialAyah)
            toAyah = min(maxAyah, fromAyah + 2)
            let saved = appState.settings.selectedReciterId
            reciterId = ReciterAudioURLs.hasAyahAudio(saved) ? saved : Reciter.defaultReciter.id
            openingAyah = await quranStore.ayah(surah: 1, ayah: 1, edition: .madinah)
            await reloadVerses()
        }
        .onDisappear {
            stopVoicePreview()
        }
        .onChange(of: selectedSurah) { _, _ in
            fromAyah = 1
            toAyah = min(maxAyah, 3)
            Task { await reloadVerses() }
        }
        .onChange(of: design.under) { _, _ in
            Task { await reloadUnderTexts() }
        }
        .onChange(of: pickedPhotoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    background = .photo(img)
                }
            }
        }
        .sheet(isPresented: $showSurahPicker) {
            surahPickerSheet
        }
        .sheet(isPresented: $showReciterPicker) {
            ReciterPickerSheet(reciters: ayahReciters, selectedId: reciterId) { picked in
                reciterId = picked.id
            }
        }
    }

    // MARK: - Live Preview Frame

    private var previewStage: some View {
        let activeShape: VideoShape = {
            if case .ready(_, let s) = status { return s }
            return shape
        }()
        let previewHeight: CGFloat = activeShape == .story ? 320 : (activeShape == .square ? 260 : 200)

        return ZStack {
            if case .ready = status, let exportedPlayer {
                VideoPlayer(player: exportedPlayer)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            } else {
                QuranVideoLivePreviewCanvas(
                    script: previewScript,
                    background: background,
                    paused: status.isWorking
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                if status.isWorking {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.black.opacity(0.45))
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                }
            }
        }
        .aspectRatio(CGFloat(activeShape.aspect), contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: previewHeight)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(theme.outlineVariant.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.22), radius: 14, y: 6)
    }

    // MARK: - Export State Cards

    private var workingCard: some View {
        let title: String
        let fraction: Double
        switch status {
        case .fetching(let done, let total):
            title = theme.t("quran_video_fetching", theme.digits(String(done)), theme.digits(String(total)))
            fraction = total > 0 ? Double(done) / Double(total) * 0.25 : 0
        case .rendering(let p):
            let pct = "\(theme.digits(String(Int((p * 100).rounded()))))%"
            title = theme.t("quran_video_rendering", pct)
            fraction = 0.25 + p * 0.75
        default:
            title = ""
            fraction = 0
        }

        return VStack(spacing: 12) {
            Text(title)
                .font(theme.scaledFont(size: 15, weight: .bold))
                .foregroundStyle(theme.onSurface)
            ProgressView(value: fraction, total: 1.0)
                .tint(theme.primary)
            Button(theme.t("quran_video_cancel")) {
                exportTask?.cancel()
                exportTask = nil
                status = .idle
            }
            .font(theme.scaledFont(size: 14, weight: .semibold))
            .foregroundStyle(theme.onSurfaceVariant)
        }
        .padding(18)
        .sirajCardSurface(cornerRadius: 22)
    }

    private func readyCard(url: URL) -> some View {
        VStack(spacing: 12) {
            Text(theme.t("quran_video_ready"))
                .font(theme.scaledFont(size: 17, weight: .black))
                .foregroundStyle(theme.onSurface)
            Text(theme.t("quran_video_ready_hint"))
                .font(theme.scaledFont(size: 13))
                .foregroundStyle(theme.onSurfaceVariant)

            HStack(spacing: 10) {
                Button {
                    saveVideoToPhotos(url)
                } label: {
                    Label(theme.t("quran_video_save"), systemImage: "square.and.arrow.down")
                        .font(theme.scaledFont(size: 14, weight: .bold))
                        .foregroundStyle(theme.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(theme.primary, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                ShareLink(item: url) {
                    Label(theme.t("quran_video_share"), systemImage: "square.and.arrow.up")
                        .font(theme.scaledFont(size: 14, weight: .bold))
                        .foregroundStyle(theme.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(theme.primary.opacity(0.14), in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }

            Button(theme.t("quran_video_make_another")) {
                exportedPlayer?.pause()
                exportedPlayer = nil
                status = .idle
            }
            .font(theme.scaledFont(size: 13.5, weight: .semibold))
            .foregroundStyle(theme.onSurfaceVariant)
            .padding(.top, 2)
        }
        .padding(18)
        .sirajCardSurface(cornerRadius: 22)
    }

    private func failedCard(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(theme.error)
            Text(message)
                .font(theme.scaledFont(size: 13))
                .foregroundStyle(theme.onSurface)
            Spacer()
        }
        .padding(14)
        .background(theme.error.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Form Sections

    private var formSections: some View {
        VStack(spacing: 20) {
            // 1. Verses & Recitation
            SirajSettingsSection(title: theme.t("quran_video_section_verses"), icon: "book.fill") {
                SirajSettingsRow(
                    icon: "text.book.closed.fill",
                    title: theme.t("quran_video_surah"),
                    value: currentSurah.map { SurahNames.forLanguage($0, language: theme.language) } ?? ""
                ) {
                    showSurahPicker = true
                }
                Divider().padding(.leading, 16)

                HStack {
                    Text(theme.t("quran_video_from"))
                        .font(theme.scaledFont(size: 14.5, weight: .semibold))
                    Spacer()
                    Stepper(
                        theme.digits(String(fromAyah)),
                        value: Binding(
                            get: { fromAyah },
                            set: { v in
                                fromAyah = max(1, min(maxAyah, v))
                                if toAyah < fromAyah { toAyah = fromAyah }
                                if toAyah - fromAyah + 1 > QuranVideoPlanner.maxVerses {
                                    toAyah = min(maxAyah, fromAyah + QuranVideoPlanner.maxVerses - 1)
                                }
                            }
                        ),
                        in: 1...maxAyah
                    )
                    .fixedSize()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Divider().padding(.leading, 16)

                let maxTo = min(maxAyah, fromAyah + QuranVideoPlanner.maxVerses - 1)
                HStack {
                    Text(theme.t("quran_video_to"))
                        .font(theme.scaledFont(size: 14.5, weight: .semibold))
                    Spacer()
                    Stepper(
                        theme.digits(String(toAyah)),
                        value: Binding(
                            get: { toAyah },
                            set: { v in toAyah = max(fromAyah, min(maxTo, v)) }
                        ),
                        in: fromAyah...maxTo
                    )
                    .fixedSize()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Divider().padding(.leading, 16)

                SirajSettingsRow(
                    icon: "mic.fill",
                    title: theme.t("quran_video_reciter"),
                    value: currentReciter.shortDisplayName(language: theme.language)
                ) {
                    showReciterPicker = true
                }

                Divider().padding(.leading, 16)

                Button {
                    toggleVoicePreview()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: isPreviewingVoice ? "stop.circle.fill" : "play.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(theme.primary)
                        Text(theme.t(isPreviewingVoice ? "quran_video_stop_voice" : "quran_video_play_voice"))
                            .font(theme.scaledFont(size: 14, weight: .bold))
                            .foregroundStyle(theme.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }

            // 2. Background
            SirajSettingsSection(title: theme.t("quran_video_section_background"), icon: "photo.on.rectangle.angled") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        bgTile(
                            title: theme.t("quran_video_scene_pattern"),
                            selected: background == .scene(.pattern)
                        ) {
                            LinearGradient(colors: [Color(hex: 0xFF124739), Color(hex: 0xFF04130F)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                .overlay(Image(systemName: "star.fill").foregroundStyle(Color(hex: 0xFFD4B26A).opacity(0.6)))
                        } onTap: { background = .scene(.pattern) }

                        bgTile(
                            title: theme.t("quran_video_scene_plain"),
                            selected: background == .scene(.plain)
                        ) {
                            Color(hex: 0xFF121216)
                        } onTap: { background = .scene(.plain) }

                        ForEach(VideoClip.allCases) { clip in
                            bgTile(
                                title: theme.t(clip.labelKey),
                                selected: background == .clip(clip)
                            ) {
                                Image(clip.previewImageAsset)
                                    .resizable()
                                    .scaledToFill()
                            } onTap: { background = .clip(clip) }
                        }

                        PhotosPicker(selection: $pickedPhotoItem, matching: .images) {
                            VStack(spacing: 6) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(theme.surfaceVariant.opacity(0.65))
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 22))
                                        .foregroundStyle(theme.primary)
                                }
                                .frame(width: 68, height: 84)
                                Text(theme.t("quran_video_gallery"))
                                    .font(theme.scaledFont(size: 11, weight: .semibold))
                                    .foregroundStyle(theme.onSurface)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(14)
                }
            }

            // 3. Design
            SirajSettingsSection(title: theme.t("quran_video_section_design"), icon: "textformat") {
                SirajSettingsToggleRow(
                    icon: "text.aligncenter",
                    title: theme.t("quran_video_show_surah"),
                    isOn: $design.showSurahName
                )
                Divider().padding(.leading, 16)
                SirajSettingsToggleRow(
                    icon: "person.wave.2.fill",
                    title: theme.t("quran_video_show_reciter"),
                    isOn: $design.showReciter
                )
                Divider().padding(.leading, 16)

                VStack(alignment: .leading, spacing: 8) {
                    Text(theme.t("quran_video_under"))
                        .font(theme.scaledFont(size: 14, weight: .semibold))
                    SirajSegmentedPills(options: VideoUnderText.allCases, selection: $design.under) { opt in
                        switch opt {
                        case .none: return theme.t("quran_video_under_none")
                        case .meaning: return theme.t("quran_video_under_meaning")
                        case .tafsir: return theme.t("quran_video_under_tafsir")
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider().padding(.leading, 16)

                VStack(alignment: .leading, spacing: 8) {
                    Text(theme.t("quran_video_text_size"))
                        .font(theme.scaledFont(size: 14, weight: .semibold))
                    SirajSegmentedPills(options: VideoTextSize.allCases, selection: $design.textSize) { opt in
                        switch opt {
                        case .small: return theme.t("quran_video_size_small")
                        case .medium: return theme.t("quran_video_size_medium")
                        case .large: return theme.t("quran_video_size_large")
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

            // 4. Video format
            SirajSettingsSection(title: theme.t("quran_video_section_video"), icon: "film.fill") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(theme.t("quran_video_shape"))
                        .font(theme.scaledFont(size: 14, weight: .semibold))
                    SirajSegmentedPills(options: VideoShape.allCases, selection: $shape) { s in
                        switch s {
                        case .story: return theme.t("quran_video_shape_story")
                        case .square: return theme.t("quran_video_shape_square")
                        case .wide: return theme.t("quran_video_shape_wide")
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider().padding(.leading, 16)

                VStack(alignment: .leading, spacing: 8) {
                    Text(theme.t("quran_video_quality"))
                        .font(theme.scaledFont(size: 14, weight: .semibold))
                    SirajSegmentedPills(options: VideoQuality.allCases, selection: $quality) { q in
                        q == .hd ? "720p" : "1080p"
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

            Button {
                startExport()
            } label: {
                Label(theme.t("quran_video_create"), systemImage: "film.stack.fill")
                    .font(theme.scaledFont(size: 16, weight: .black))
                    .foregroundStyle(theme.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(theme.primary, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(previewParts.isEmpty)
        }
    }

    private func bgTile<Thumb: View>(title: String, selected: Bool, @ViewBuilder thumb: () -> Thumb, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                thumb()
                    .frame(width: 68, height: 84)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(selected ? theme.primary : theme.outlineVariant.opacity(0.35), lineWidth: selected ? 2.5 : 1)
                    )
                Text(title)
                    .font(theme.scaledFont(size: 11, weight: selected ? .bold : .medium))
                    .foregroundStyle(selected ? theme.primary : theme.onSurface)
                    .lineLimit(1)
            }
            .frame(width: 72)
        }
        .buttonStyle(.plain)
    }

    private var surahPickerSheet: some View {
        NavigationStack {
            List(quranStore.surahs) { surah in
                Button {
                    selectedSurah = surah.number
                    showSurahPicker = false
                } label: {
                    HStack {
                        Text("\(theme.digits(String(surah.number))). \(SurahNames.forLanguage(surah, language: theme.language))")
                            .foregroundStyle(surah.number == selectedSurah ? theme.primary : theme.onSurface)
                            .fontWeight(surah.number == selectedSurah ? .bold : .regular)
                        Spacer()
                        if surah.number == selectedSurah {
                            Image(systemName: "checkmark").foregroundStyle(theme.primary)
                        }
                    }
                }
            }
            .navigationTitle(theme.t("quran_video_pick_surah"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(theme.t("close")) { showSurahPicker = false }
                }
            }
        }
    }

    // MARK: - Actions

    private func buildLabels() -> VideoLabels {
        let title = currentSurah.map { ListenTitles.surah($0, language: theme.language) } ?? ""
        let rangeText = fromAyah == toAyah
            ? theme.t("quran_video_ayah_n", theme.digits(String(fromAyah)))
            : theme.t("quran_video_label_range", theme.digits(String(fromAyah)), theme.digits(String(toAyah)))
        let reciterLine = theme.t("quran_video_label_reciter", currentReciter.shortDisplayName(language: theme.language))
        let madeWith = theme.t("quran_video_label_made_with", theme.t("app_name"))
        let underRtl = design.under == .tafsir || theme.isRTL
        return VideoLabels(surahTitle: title, rangeLabel: rangeText, reciterLine: reciterLine, madeWith: madeWith, underIsRtl: underRtl)
    }

    private func reloadVerses() async {
        surahAyahs = await quranStore.ayahsForSurah(selectedSurah, edition: .madinah)
        await reloadUnderTexts()
    }

    private func reloadUnderTexts() async {
        guard design.under != .none else {
            underTexts = [:]
            return
        }
        let editionId = design.under == .tafsir ? TafsirBook.builtInId : appState.settings.selectedTafsirEdition
        var map: [Int: String] = [:]
        for a in surahAyahs where a.numberInSurah >= fromAyah && a.numberInSurah <= toAyah {
            if let text = await quranStore.tafsirText(globalAyah: a.number, edition: editionId) {
                map[a.number] = text
            }
        }
        underTexts = map
    }

    private func toggleVoicePreview() {
        if isPreviewingVoice {
            stopVoicePreview()
            return
        }
        guard let url = URL(string: ReciterAudioURLs.ayahAudioURL(reciterId: reciterId, surah: selectedSurah, ayah: fromAyah)) else { return }
        let p = AVPlayer(url: url)
        previewPlayer = p
        isPreviewingVoice = true
        p.play()
    }

    private func stopVoicePreview() {
        previewPlayer?.pause()
        previewPlayer = nil
        isPreviewingVoice = false
    }

    private func startExport() {
        stopVoicePreview()
        let parts = previewParts
        guard !parts.isEmpty else { return }
        let labels = buildLabels()
        let curDesign = design
        let curBg = background
        let curShape = shape
        let curQuality = quality
        let curReciter = reciterId
        let curUnder = underTexts

        status = .fetching(done: 0, total: parts.count)
        exportTask?.cancel()
        exportTask = Task {
            do {
                let outURL = try await QuranVideoExportPipeline.exportVideo(
                    parts: parts,
                    reciterId: curReciter,
                    underTexts: curUnder,
                    labels: labels,
                    design: curDesign,
                    background: curBg,
                    shape: curShape,
                    quality: curQuality
                ) { update in
                    Task { @MainActor in
                        self.status = update
                    }
                }
                await MainActor.run {
                    self.exportedPlayer = AVPlayer(url: outURL)
                    self.status = .ready(url: outURL, shape: curShape)
                }
            } catch is CancellationError {
                await MainActor.run { self.status = .idle }
            } catch {
                await MainActor.run {
                    self.status = .failed(self.theme.t("quran_video_failed_offline"))
                }
            }
        }
    }

    private func saveVideoToPhotos(_ url: URL) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { auth in
            guard auth == .authorized || auth == .limited else {
                Task { @MainActor in showToast(theme.t("quran_video_save_failed")) }
                return
            }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { ok, _ in
                Task { @MainActor in
                    showToast(theme.t(ok ? "quran_video_saved" : "quran_video_save_failed"))
                }
            }
        }
    }

    private func showToast(_ text: String) {
        toastText = text
        Task {
            try? await Task.sleep(for: .seconds(2))
            if toastText == text { toastText = nil }
        }
    }
}

private struct QuranVideoLivePreviewCanvas: View {
    let script: VideoScript
    let background: QuranVideoBackground
    let paused: Bool

    @State private var startDate = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: paused)) { ctx in
            let elapsed = max(0, ctx.date.timeIntervalSince(startDate))
            let durSec = max(1.0, Double(script.durationUs) / 1_000_000.0)
            let timeUs = Int64(elapsed.truncatingRemainder(dividingBy: durSec) * 1_000_000.0)

            Canvas { graphics, size in
                let w = max(1, Int(size.width.rounded()))
                let h = max(1, Int(size.height.rounded()))
                let renderer = QuranVideoRenderer(width: w, height: h, script: script, background: background)
                graphics.withCGContext { cg in
                    renderer.draw(in: cg, timeUs: timeUs)
                }
            }
        }
    }
}
