import SwiftUI
import SirajCore

struct ReciterAvatarView: View {
    @Environment(\.sirajTheme) private var theme
    let reciterId: String
    let name: String
    var photoAsset: String? = nil
    var size: CGFloat = 48
    var isSelected: Bool = false
    var showBorder: Bool = true
    var isPlaying: Bool = false

    private var resolvedAsset: String? {
        photoAsset ?? ReciterPhotoCatalog.assetName(for: reciterId)
    }

    var body: some View {
        ZStack {
            if let asset = resolvedAsset {
                Image(asset)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [theme.primaryContainer, theme.surfaceVariant],
                            center: .center,
                            startRadius: 2,
                            endRadius: size * 0.65
                        )
                    )
                Text(monogram(for: name))
                    .font(.system(size: size * 0.34, weight: .bold))
                    .foregroundStyle(theme.onSurface)
            }
        }
        .frame(width: size, height: size)
        .overlay {
            if showBorder {
                Circle()
                    .strokeBorder(
                        (isSelected || isPlaying) ? theme.primary : theme.outlineVariant.opacity(0.42),
                        lineWidth: (isSelected || isPlaying) ? 2 : 1
                    )
            }
        }
        .shadow(
            color: (isSelected || isPlaying) ? theme.primary.opacity(0.26) : .clear,
            radius: (isSelected || isPlaying) ? 5 : 0
        )
    }

    private func monogram(for raw: String) -> String {
        let stripped = raw
            .replacingOccurrences(of: "الشيخ", with: "")
            .replacingOccurrences(of: "Sheikh", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = stripped.split(separator: " ").filter { !$0.isEmpty }
        if parts.isEmpty { return String(raw.prefix(2)) }
        if parts.count == 1 { return String(parts[0].prefix(2)) }
        let a = parts[0].hasPrefix("ال") ? String(parts[0].dropFirst(2).prefix(1)) : String(parts[0].prefix(1))
        let b = parts[1].hasPrefix("ال") ? String(parts[1].dropFirst(2).prefix(1)) : String(parts[1].prefix(1))
        return "\(a).\(b)"
    }
}

struct SirajEqualizerBars: View {
    @Environment(\.sirajTheme) private var theme
    let isPlaying: Bool
    var color: Color? = nil
    var barWidth: CGFloat = 3
    var height: CGFloat = 14

    var body: some View {
        let tint = color ?? theme.primary
        if isPlaying && theme.motionEnabled {
            TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                bars(tint: tint, levels: [
                    0.35 + 0.65 * abs(sin(t * 5.2)),
                    0.30 + 0.70 * abs(sin(t * 6.4 + 1.1)),
                    0.35 + 0.65 * abs(sin(t * 4.8 + 2.3))
                ])
            }
        } else {
            bars(tint: tint, levels: [0.35, 0.75, 0.50])
        }
    }

    private func bars(tint: Color, levels: [Double]) -> some View {
        HStack(alignment: .bottom, spacing: 2.5) {
            ForEach(0..<3, id: \.self) { idx in
                RoundedRectangle(cornerRadius: barWidth / 2)
                    .fill(tint)
                    .frame(width: barWidth, height: max(3, height * CGFloat(levels[idx])))
            }
        }
        .frame(height: height, alignment: .bottom)
    }
}

struct WavyProgressBar: View {
    @Environment(\.sirajTheme) private var theme
    let progress: Double
    let isPlaying: Bool
    var onSeek: ((Double) -> Void)? = nil
    var onDragChange: ((Double?) -> Void)? = nil
    var strokeWidth: CGFloat = 3.5
    var amplitude: CGFloat = 3.2
    var wavelength: CGFloat = 26
    var height: CGFloat = 24

    @State private var dragProgress: Double?

    var body: some View {
        let shown = min(1.0, max(0.0, dragProgress ?? progress))
        GeometryReader { geo in
            let w = max(1, geo.size.width)
            let midY = geo.size.height / 2
            let splitX = w * CGFloat(shown)

            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isPlaying || !theme.motionEnabled)) { ctx in
                let phase = (isPlaying && theme.motionEnabled) ? ctx.date.timeIntervalSinceReferenceDate * 4.2 : 0
                Canvas { canvas, size in
                    let amp: CGFloat = (isPlaying && theme.motionEnabled) ? amplitude : 0

                    // Remaining flat track
                    if splitX < size.width - 2 {
                        var rem = Path()
                        rem.move(to: CGPoint(x: splitX + 4, y: midY))
                        rem.addLine(to: CGPoint(x: size.width, y: midY))
                        canvas.stroke(
                            rem,
                            with: .color(theme.outlineVariant.opacity(0.45)),
                            style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                        )
                    }

                    // Active wavy track
                    if splitX > 1 {
                        var wave = Path()
                        let steps = max(8, Int(splitX / 2.5))
                        for i in 0...steps {
                            let x = splitX * CGFloat(i) / CGFloat(steps)
                            let y = midY + amp * sin((x / wavelength) * .pi * 2 - CGFloat(phase))
                            if i == 0 { wave.move(to: CGPoint(x: x, y: y)) }
                            else { wave.addLine(to: CGPoint(x: x, y: y)) }
                        }
                        canvas.stroke(
                            wave,
                            with: .color(theme.primary),
                            style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
                        )
                    }

                    // Thumb handle
                    let thumbH = max(12, height * 0.56)
                    let thumbRect = CGRect(x: max(0, min(size.width - 4, splitX - 2)), y: midY - thumbH / 2, width: 4, height: thumbH)
                    canvas.fill(Path(roundedRect: thumbRect, cornerRadius: 2), with: .color(theme.primary))
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        guard onSeek != nil else { return }
                        let frac = min(1.0, max(0.0, Double(val.location.x / w)))
                        dragProgress = frac
                        onDragChange?(frac)
                    }
                    .onEnded { val in
                        guard let onSeek else { return }
                        let frac = min(1.0, max(0.0, Double(val.location.x / w)))
                        dragProgress = nil
                        onDragChange?(nil)
                        onSeek(frac)
                    }
            )
        }
        .frame(height: height)
        .environment(\.layoutDirection, .leftToRight)
    }
}

struct QuranMiniPlayer: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    let audioStore: QuranAudioStore
    let onOpenReader: (ReaderDestination) -> Void
    let onOpenListenPlayer: () -> Void

    var body: some View {
        if audioStore.hasActiveListening, let track = audioStore.currentListeningTrack {
            miniBar(
                title: track.title,
                chipText: nil,
                subtitle: track.artist,
                reciterId: track.sourceId,
                photoAsset: track.artworkAsset,
                isPlaying: audioStore.listeningIsPlaying,
                isOffline: audioStore.listeningIsLocal,
                progress: audioStore.listeningProgress,
                onTap: onOpenListenPlayer,
                onPlayPause: { audioStore.toggleListeningPlayPause() },
                onPrev: { audioStore.previousListeningTrack() },
                onNext: { audioStore.nextListeningTrack() },
                onClose: { audioStore.stopListening() }
            )
        } else if audioStore.readerActive {
            let reciter = Reciter.byId(audioStore.readerReciterId)
            let surahTitle: String = {
                if !audioStore.readerSurahName.isEmpty { return audioStore.readerSurahName }
                if let s = appState.quranStore.surahs.first(where: { $0.number == audioStore.readerSurah }) {
                    return SurahNames.forLanguage(s, language: theme.language)
                }
                return theme.t("surah_number_fallback", theme.digits(String(audioStore.readerSurah)))
            }()
            miniBar(
                title: surahTitle,
                chipText: theme.t("quran_ayah_label", theme.digits(String(audioStore.readerAyah))),
                subtitle: reciter.shortDisplayName(language: theme.language),
                reciterId: reciter.id,
                photoAsset: reciter.photoAssetName,
                isPlaying: audioStore.readerIsPlaying,
                isOffline: audioStore.readerIsOfflineSource,
                progress: audioStore.readerProgress,
                onTap: {
                    let ed = MushafEdition.resolve(appState.settings.mushafEdition)
                    let page = appState.quranStore.pageForAyah(surah: audioStore.readerSurah, ayah: audioStore.readerAyah, edition: ed)
                    onOpenReader(ReaderDestination(page: page, surahNumber: audioStore.readerSurah, ayahNumber: audioStore.readerAyah))
                },
                onPlayPause: { audioStore.toggleReaderPlayPause() },
                onPrev: { audioStore.previousReaderAyah() },
                onNext: { audioStore.nextReaderAyah() },
                onClose: { audioStore.stopReader() }
            )
        }
    }

    private func miniBar(
        title: String,
        chipText: String?,
        subtitle: String,
        reciterId: String,
        photoAsset: String?,
        isPlaying: Bool,
        isOffline: Bool,
        progress: Double,
        onTap: @escaping () -> Void,
        onPlayPause: @escaping () -> Void,
        onPrev: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 10) {
            Button(action: onTap) {
                HStack(spacing: 10) {
                    ReciterAvatarView(
                        reciterId: reciterId,
                        name: subtitle,
                        photoAsset: photoAsset,
                        size: 40,
                        isSelected: false,
                        isPlaying: isPlaying
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(title)
                                .font(theme.scaledFont(size: 13.5, weight: .bold))
                                .foregroundStyle(theme.onSurface)
                                .lineLimit(1)
                            if let chipText {
                                Text(chipText)
                                    .font(theme.scaledFont(size: 10.5, weight: .bold))
                                    .foregroundStyle(theme.primary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(theme.primary.opacity(0.12), in: Capsule())
                                    .lineLimit(1)
                            }
                        }
                        HStack(spacing: 4) {
                            Text(subtitle)
                                .font(theme.scaledFont(size: 11.5))
                                .foregroundStyle(theme.onSurfaceVariant)
                                .lineLimit(1)
                            if isOffline {
                                Image(systemName: "checkmark.icloud.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(theme.primary)
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            HStack(spacing: 2) {
                Button(action: onPrev) {
                    Image(systemName: theme.isRTL ? "forward.end.fill" : "backward.end.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .frame(width: 30, height: 34)
                }
                .buttonStyle(.plain)

                Button(action: onPlayPause) {
                    ZStack {
                        Circle()
                            .stroke(theme.primary.opacity(0.20), lineWidth: 2.5)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(theme.primary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Circle()
                            .fill(theme.primary)
                            .padding(3)
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(theme.onPrimary)
                    }
                    .frame(width: 38, height: 38)
                }
                .buttonStyle(.plain)

                Button(action: onNext) {
                    Image(systemName: theme.isRTL ? "backward.end.fill" : "forward.end.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .frame(width: 30, height: 34)
                }
                .buttonStyle(.plain)

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .frame(width: 26, height: 34)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .sirajCardSurface(cornerRadius: 24, isElevated: true)
        .padding(.horizontal, 14)
    }
}

struct AudioOptionsSheet: View {
    @Environment(\.sirajTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    let appState: AppState
    let audioStore: QuranAudioStore
    let surahNumber: Int
    let surahName: String
    let ayahNumber: Int
    let onOpenReciterPicker: () -> Void

    private var reciter: Reciter {
        Reciter.byId(appState.settings.selectedReciterId)
    }

    var body: some View {
        let isDownloaded = audioStore.isSurahDownloaded(reciterId: reciter.id, surah: surahNumber)
        let dlKey = audioStore.downloadKey(reciterId: reciter.id, surah: surahNumber)
        let dlProgress = audioStore.activeDownloads[dlKey]

        ScrollView {
            VStack(spacing: 18) {
                // 1. Who is playing
                Button {
                    dismiss()
                    onOpenReciterPicker()
                } label: {
                    HStack(spacing: 14) {
                        ReciterAvatarView(reciterId: reciter.id, name: reciter.shortDisplayName(language: theme.language), size: 52, isSelected: true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(reciter.shortDisplayName(language: theme.language))
                                .font(theme.scaledFont(size: 16, weight: .black))
                                .foregroundStyle(theme.onSurface)
                                .lineLimit(1)
                            let ref = theme.t("ply_reference", surahName, theme.digits(String(ayahNumber)))
                            let sub = [ref, reciter.localizedSubInfo(language: theme.language)].compactMap { $0 }.joined(separator: " • ")
                            Text(sub)
                                .font(theme.scaledFont(size: 12.5))
                                .foregroundStyle(theme.onSurfaceVariant)
                                .lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(theme.primary)
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                // 2. Transport
                if audioStore.readerDurationSec > 0 {
                    VStack(spacing: 4) {
                        WavyProgressBar(
                            progress: audioStore.readerProgress,
                            isPlaying: audioStore.readerIsPlaying,
                            onSeek: { frac in
                                audioStore.seekReader(toSeconds: frac * audioStore.readerDurationSec)
                            }
                        )
                        HStack {
                            Text(formatClock(audioStore.readerPositionSec))
                            Spacer()
                            Text(formatClock(audioStore.readerDurationSec))
                        }
                        .font(theme.scaledFont(size: 11.5, weight: .semibold))
                        .foregroundStyle(theme.onSurfaceVariant)
                    }
                }

                HStack(spacing: 0) {
                    transportBtn(icon: "gobackward.10") { audioStore.seekReader(deltaSeconds: -10) }
                    Spacer()
                    transportBtn(icon: theme.isRTL ? "forward.end.fill" : "backward.end.fill") { audioStore.previousReaderAyah() }
                    Spacer()
                    Button {
                        if audioStore.readerActive {
                            audioStore.toggleReaderPlayPause()
                        } else {
                            let s = appState.quranStore.surahs.first { $0.number == surahNumber }
                            audioStore.playReaderAyah(
                                surah: surahNumber,
                                ayah: ayahNumber,
                                reciterId: reciter.id,
                                surahName: surahName,
                                surahAyahCount: s?.numberOfAyahs ?? 7
                            )
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(theme.primary)
                                .frame(width: 62, height: 62)
                            Image(systemName: audioStore.readerIsPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(theme.onPrimary)
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    transportBtn(icon: theme.isRTL ? "backward.end.fill" : "forward.end.fill") { audioStore.nextReaderAyah() }
                    Spacer()
                    transportBtn(icon: "goforward.10") { audioStore.seekReader(deltaSeconds: 10) }
                }
                .padding(.horizontal, 8)

                // 3. Scope pills
                VStack(alignment: .leading, spacing: 8) {
                    Text(theme.t("ply_scope_label"))
                        .font(theme.scaledFont(size: 12.5, weight: .bold))
                        .foregroundStyle(theme.onSurfaceVariant)
                    SirajSegmentedPills(
                        options: PlaybackScope.allCases,
                        selection: Binding(
                            get: { audioStore.readerScope },
                            set: { audioStore.readerScope = $0 }
                        )
                    ) { scope in
                        switch scope {
                        case .singleAyah: return theme.t("ply_scope_repeat")
                        case .page: return theme.t("ply_scope_page")
                        case .surah: return theme.t("ply_scope_surah")
                        case .continuous: return theme.t("ply_scope_continuous")
                        }
                    }
                }

                // Speed & repeat row
                VStack(spacing: 12) {
                    HStack {
                        Text(theme.t("listen_speed"))
                            .font(theme.scaledFont(size: 14, weight: .semibold))
                            .foregroundStyle(theme.onSurface)
                        Spacer()
                        HStack(spacing: 6) {
                            ForEach([Float(0.75), 1.0, 1.25, 1.5, 2.0], id: \.self) { sp in
                                let active = abs(audioStore.readerSpeed - sp) < 0.01
                                Button {
                                    audioStore.setReaderSpeed(sp)
                                } label: {
                                    Text(speedLabel(sp))
                                        .font(theme.scaledFont(size: 12, weight: active ? .bold : .medium))
                                        .foregroundStyle(active ? theme.onPrimary : theme.onSurfaceVariant)
                                        .padding(.horizontal, 9)
                                        .padding(.vertical, 5)
                                        .background(active ? theme.primary : theme.surfaceVariant.opacity(0.6), in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)

                    Divider().padding(.leading, 16)

                    SirajSettingsToggleRow(
                        icon: "highlighter",
                        title: theme.t("ply_highlight_row"),
                        subtitle: theme.t("ply_highlight_desc"),
                        isOn: Binding(
                            get: { appState.settings.quranHighlightMode != "none" },
                            set: { on in appState.updateSettings { $0.quranHighlightMode = on ? "ayah" : "none" } }
                        )
                    )

                    Divider().padding(.leading, 16)

                    Button {
                        if dlProgress != nil {
                            audioStore.stopDownload(key: dlKey)
                        } else if !isDownloaded {
                            audioStore.downloadSurah(reciterId: reciter.id, surah: surahNumber)
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: isDownloaded ? "checkmark.icloud.fill" : "icloud.and.arrow.down")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(theme.primary)
                                .frame(width: 34, height: 34)
                                .background(Circle().fill(theme.primary.opacity(0.12)))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(theme.t(isDownloaded ? "ply_downloaded_title" : "ply_download_title"))
                                    .font(theme.scaledFont(size: 14.5, weight: .semibold))
                                    .foregroundStyle(theme.onSurface)
                                Text(dlProgress != nil
                                     ? theme.t("ply_downloading", theme.digits(String(Int((dlProgress ?? 0) * 100))))
                                     : theme.t(isDownloaded ? "ply_downloaded_sub" : "ply_download_sub"))
                                    .font(theme.scaledFont(size: 12))
                                    .foregroundStyle(theme.onSurfaceVariant)
                            }
                            Spacer()
                            if dlProgress != nil {
                                ProgressView()
                                    .tint(theme.primary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .sirajCardSurface(cornerRadius: 22)
            }
            .padding(20)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func transportBtn(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(theme.onSurface)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
    }

    private func speedLabel(_ sp: Float) -> String {
        let raw = sp == Float(Int(sp)) ? "\(Int(sp))" : String(format: "%g", sp)
        return "\(theme.digits(raw))×"
    }

    private func formatClock(_ sec: Double) -> String {
        let total = max(0, Int(sec.rounded(.down)))
        let m = total / 60
        let s = total % 60
        return theme.digits(String(format: "%d:%02d", m, s))
    }
}

private enum ReciterPickerFilter: String, CaseIterable, Identifiable {
    case all, murattal, mujawwad, teacher
    var id: String { rawValue }
    var titleKey: String {
        switch self {
        case .all: return "reciter_picker_filter_all"
        case .murattal: return "reciter_picker_filter_murattal"
        case .mujawwad: return "reciter_picker_filter_mujawwad"
        case .teacher: return "reciter_picker_filter_teacher"
        }
    }
}

struct ReciterPickerSheet: View {
    @Environment(\.sirajTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    let reciters: [Reciter]
    let selectedId: String
    let onSelect: (Reciter) -> Void

    @State private var query = ""
    @State private var filter: ReciterPickerFilter = .all

    private var filtered: [Reciter] {
        let folded = ArabicSearchText.normalizeQuery(query)
        return reciters.filter { rec in
            let matchesStyle: Bool
            switch filter {
            case .all: matchesStyle = true
            case .murattal: matchesStyle = rec.subInfo == "Murattal"
            case .mujawwad: matchesStyle = rec.subInfo == "Mujawwad"
            case .teacher: matchesStyle = rec.subInfo?.contains("Teacher") == true
            }
            if !matchesStyle { return false }
            if folded.isEmpty { return true }
            return [rec.name, rec.englishName, rec.nameTr ?? "", rec.nameUr ?? ""].contains {
                ArabicSearchText.normalize($0).contains(folded)
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(theme.primary)
                    TextField(theme.t("reciter_picker_search_hint"), text: $query)
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
                .padding(.horizontal, 16)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ReciterPickerFilter.allCases) { f in
                            let active = filter == f
                            Button { filter = f } label: {
                                Text(theme.t(f.titleKey))
                                    .font(theme.scaledFont(size: 12.5, weight: active ? .bold : .medium))
                                    .foregroundStyle(active ? theme.onPrimary : theme.onSurface)
                                    .padding(.horizontal, 13)
                                    .padding(.vertical, 7)
                                    .background(active ? theme.primary : theme.surfaceVariant.opacity(0.6), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                if filtered.isEmpty {
                    VStack(spacing: 10) {
                        Text(theme.t("reciter_picker_empty_title"))
                            .font(theme.scaledFont(size: 16, weight: .bold))
                            .foregroundStyle(theme.onSurface)
                        Text(theme.t("reciter_picker_empty_body"))
                            .font(theme.scaledFont(size: 13))
                            .foregroundStyle(theme.onSurfaceVariant)
                        Button(theme.t("reciter_picker_empty_clear")) {
                            query = ""
                            filter = .all
                        }
                        .font(theme.scaledFont(size: 13.5, weight: .bold))
                        .foregroundStyle(theme.primary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(filtered) { rec in
                                let selected = rec.id == selectedId
                                Button {
                                    onSelect(rec)
                                    dismiss()
                                } label: {
                                    HStack(spacing: 12) {
                                        ReciterAvatarView(reciterId: rec.id, name: rec.shortDisplayName(language: theme.language), size: 46, isSelected: selected)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(rec.shortDisplayName(language: theme.language))
                                                .font(theme.scaledFont(size: 15, weight: .bold))
                                                .foregroundStyle(selected ? theme.primary : theme.onSurface)
                                                .lineLimit(1)
                                            if let sub = rec.localizedSubInfo(language: theme.language) {
                                                Text("\(sub) • \(rec.riwayah)")
                                                    .font(theme.scaledFont(size: 12))
                                                    .foregroundStyle(theme.onSurfaceVariant)
                                                    .lineLimit(1)
                                            }
                                        }
                                        Spacer()
                                        if selected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundStyle(theme.primary)
                                        }
                                    }
                                    .padding(12)
                                    .sirajCardSurface(cornerRadius: 18)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                    }
                }
            }
            .background(theme.background.ignoresSafeArea())
            .navigationTitle(theme.t("reciter_picker_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(theme.t("reciter_picker_close")) { dismiss() }
                }
            }
        }
    }
}
