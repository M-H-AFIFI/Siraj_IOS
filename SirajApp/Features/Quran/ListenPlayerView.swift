import SwiftUI
import SirajCore

struct ListenPlayerView: View {
    @Environment(\.sirajTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    let appState: AppState
    let audioStore: QuranAudioStore

    @State private var dragFraction: Double?
    @State private var showAmbientSheet = false
    @State private var showSleepSheet = false

    private let speeds: [Float] = [0.75, 1.0, 1.25, 1.5, 2.0]

    var body: some View {
        let track = audioStore.currentListeningTrack
        let duration = audioStore.listeningDurationSec
        let position = dragFraction.map { $0 * duration } ?? audioStore.listeningPositionSec

        ZStack {
            // Soft blurred portrait backdrop
            theme.background.ignoresSafeArea()
            if let asset = track?.artworkAsset {
                Image(asset)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 56)
                    .opacity(theme.isDark ? 0.28 : 0.16)
                    .ignoresSafeArea()
            }
            LinearGradient(
                colors: [theme.background.opacity(0.45), theme.background.opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if let track {
                ScrollView {
                    VStack(spacing: 18) {
                        topBar(artist: track.artist)

                        // Large artwork
                        ZStack {
                            if let asset = track.artworkAsset {
                                Image(asset)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 248, height: 248)
                                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                            } else {
                                ReciterAvatarView(reciterId: track.sourceId, name: track.artist, size: 220, isSelected: true, isPlaying: audioStore.listeningIsPlaying)
                            }
                        }
                        .shadow(color: Color.black.opacity(theme.isDark ? 0.45 : 0.18), radius: 22, y: 12)
                        .scaleEffect(audioStore.listeningIsPlaying ? 1.0 : 0.94)
                        .animation(theme.motionEnabled ? .spring(response: 0.45, dampingFraction: 0.8) : nil, value: audioStore.listeningIsPlaying)
                        .padding(.top, 6)

                        // Title + artist + download
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(track.title)
                                    .font(theme.scaledFont(size: 22, weight: .black))
                                    .foregroundStyle(theme.onSurface)
                                    .lineLimit(2)
                                Text(track.artist)
                                    .font(theme.scaledFont(size: 15, weight: .medium))
                                    .foregroundStyle(theme.onSurfaceVariant)
                                    .lineLimit(1)
                            }
                            Spacer()
                            currentTrackDownloadButton(track)
                        }

                        // Status pills
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                statusPill(
                                    icon: audioStore.listeningIsLocal ? "checkmark.icloud.fill" : "cloud",
                                    label: theme.t(audioStore.listeningIsLocal ? "listen_state_offline" : "listen_streaming")
                                )
                                if audioStore.hasSleepTimer {
                                    Button { showSleepSheet = true } label: {
                                        statusPill(icon: "moon.zzz.fill", label: sleepLabel)
                                    }
                                    .buttonStyle(.plain)
                                }
                                if let amb = audioStore.activeAmbient {
                                    Button { showAmbientSheet = true } label: {
                                        HStack(spacing: 5) {
                                            Image(amb.iconAssetName)
                                                .renderingMode(.template)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 14, height: 14)
                                            Text(theme.t(amb.labelKey))
                                                .font(theme.scaledFont(size: 12, weight: .semibold))
                                        }
                                        .foregroundStyle(theme.primary)
                                        .padding(.horizontal, 11)
                                        .padding(.vertical, 6)
                                        .background(theme.primary.opacity(0.13), in: Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        if audioStore.listeningHasError {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(theme.error)
                                Text(theme.t("listen_error"))
                                    .font(theme.scaledFont(size: 12.5))
                                    .foregroundStyle(theme.onSurface)
                                Spacer()
                                Button(theme.t("setup_retry")) {
                                    audioStore.toggleListeningPlayPause()
                                }
                                .font(theme.scaledFont(size: 12.5, weight: .bold))
                                .foregroundStyle(theme.primary)
                            }
                            .padding(12)
                            .background(theme.error.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
                        }

                        // Wavy scrubber + times
                        VStack(spacing: 4) {
                            WavyProgressBar(
                                progress: duration > 0 ? (dragFraction ?? (position / duration)) : 0,
                                isPlaying: audioStore.listeningIsPlaying,
                                onSeek: duration > 0 ? { frac in audioStore.seekListening(toSeconds: frac * duration) } : nil,
                                onDragChange: { dragFraction = $0 },
                                height: 28
                            )
                            HStack {
                                Text(formatClock(position))
                                Spacer()
                                Text(duration > 0 ? "-\(formatClock(max(0, duration - position)))" : "--:--")
                            }
                            .font(theme.scaledFont(size: 12, weight: .semibold))
                            .foregroundStyle(theme.onSurfaceVariant)
                        }

                        // Primary transport
                        HStack {
                            Button { audioStore.toggleListeningShuffle() } label: {
                                Image(systemName: "shuffle")
                                    .font(.system(size: 19, weight: .semibold))
                                    .foregroundStyle(audioStore.listeningShuffle ? theme.primary : theme.onSurfaceVariant)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Button { audioStore.previousListeningTrack() } label: {
                                Image(systemName: theme.isRTL ? "forward.end.fill" : "backward.end.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(theme.onSurface)
                                    .frame(width: 48, height: 48)
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Button { audioStore.toggleListeningPlayPause() } label: {
                                ZStack {
                                    Circle()
                                        .fill(theme.primary)
                                        .frame(width: 68, height: 68)
                                        .shadow(color: theme.primary.opacity(0.32), radius: 12, y: 6)
                                    if audioStore.listeningIsBuffering {
                                        ProgressView()
                                            .tint(theme.onPrimary)
                                    } else {
                                        Image(systemName: audioStore.listeningIsPlaying ? "pause.fill" : "play.fill")
                                            .font(.system(size: 26, weight: .bold))
                                            .foregroundStyle(theme.onPrimary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Button { audioStore.nextListeningTrack() } label: {
                                Image(systemName: theme.isRTL ? "backward.end.fill" : "forward.end.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(theme.onSurface)
                                    .frame(width: 48, height: 48)
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Button { audioStore.cycleListeningRepeat() } label: {
                                Image(systemName: audioStore.listeningRepeat == .one ? "repeat.1" : "repeat")
                                    .font(.system(size: 19, weight: .semibold))
                                    .foregroundStyle(audioStore.listeningRepeat == .off ? theme.onSurfaceVariant : theme.primary)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                        }

                        // Secondary controls (-10s, Speed, Sleep Timer, +10s)
                        HStack(spacing: 10) {
                            secondaryBtn(icon: "gobackward.10") { audioStore.seekListening(deltaSeconds: -10) }

                            Menu {
                                ForEach(speeds, id: \.self) { sp in
                                    Button {
                                        audioStore.setListeningSpeed(sp)
                                    } label: {
                                        HStack {
                                            Text(speedString(sp))
                                            if abs(audioStore.listeningSpeed - sp) < 0.01 {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "speedometer")
                                    Text(speedString(audioStore.listeningSpeed))
                                        .font(theme.scaledFont(size: 13, weight: .bold))
                                }
                                .foregroundStyle(abs(audioStore.listeningSpeed - 1.0) > 0.01 ? theme.primary : theme.onSurface)
                                .padding(.horizontal, 12)
                                .frame(height: 40)
                                .sirajCardSurface(cornerRadius: 20)
                            }

                            Button { showSleepSheet = true } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "moon.zzz")
                                    Text(audioStore.hasSleepTimer ? sleepLabel : theme.t("player_sleep_timer"))
                                        .font(theme.scaledFont(size: 12.5, weight: .semibold))
                                        .lineLimit(1)
                                }
                                .foregroundStyle(audioStore.hasSleepTimer ? theme.primary : theme.onSurface)
                                .padding(.horizontal, 12)
                                .frame(height: 40)
                                .sirajCardSurface(cornerRadius: 20)
                            }
                            .buttonStyle(.plain)

                            secondaryBtn(icon: "goforward.10") { audioStore.seekListening(deltaSeconds: 10) }
                        }

                        // Up next
                        if let next = audioStore.nextListeningTrack {
                            Button {
                                audioStore.nextListeningTrack()
                            } label: {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(theme.t("player_up_next_label"))
                                            .font(theme.scaledFont(size: 11, weight: .black))
                                            .foregroundStyle(theme.primary)
                                            .textCase(.uppercase)
                                        Text(next.title)
                                            .font(theme.scaledFont(size: 14.5, weight: .bold))
                                            .foregroundStyle(theme.onSurface)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Image(systemName: theme.isRTL ? "chevron.left" : "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(theme.onSurfaceVariant)
                                }
                                .padding(14)
                                .sirajCardSurface(cornerRadius: 20)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 10)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
            } else {
                VStack {
                    Button(theme.t("close")) { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showAmbientSheet) {
            AmbientSoundSheet(audioStore: audioStore)
        }
        .sheet(isPresented: $showSleepSheet) {
            sleepTimerSheet
        }
    }

    private func topBar(artist: String) -> some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(theme.onSurface)
                    .frame(width: 42, height: 42)
                    .sirajCardSurface(cornerRadius: 21)
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 1) {
                Text(theme.t("listen_playing_from"))
                    .font(theme.scaledFont(size: 11, weight: .semibold))
                    .foregroundStyle(theme.onSurfaceVariant)
                Text(artist)
                    .font(theme.scaledFont(size: 13.5, weight: .bold))
                    .foregroundStyle(theme.onSurface)
                    .lineLimit(1)
            }

            Spacer()

            Button { showAmbientSheet = true } label: {
                Image(audioStore.activeAmbient?.iconAssetName ?? "ic_ambient_off")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(audioStore.activeAmbient != nil ? theme.primary : theme.onSurface)
                    .frame(width: 42, height: 42)
                    .sirajCardSurface(cornerRadius: 21)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func currentTrackDownloadButton(_ track: ListeningTrack) -> some View {
        let isDownloaded: Bool = {
            switch track.kind {
            case .surah: return audioStore.isSurahDownloaded(reciterId: track.sourceId, surah: track.surahNumber)
            case .rare: return audioStore.isRareDownloaded(collectionId: track.sourceId, fileName: track.fileName ?? "")
            }
        }()
        let dlKey = track.kind == .surah
            ? audioStore.downloadKey(reciterId: track.sourceId, surah: track.surahNumber)
            : track.id
        let isDownloading = audioStore.activeDownloads[dlKey] != nil

        Button {
            if isDownloading {
                audioStore.stopDownload(key: dlKey)
            } else if !isDownloaded {
                if track.kind == .surah {
                    audioStore.downloadSurah(reciterId: track.sourceId, surah: track.surahNumber)
                } else if let col = ListeningCatalog.rare(id: track.sourceId),
                          let rare = col.tracks.first(where: { $0.id == track.id }) {
                    audioStore.downloadRareTrack(rare)
                }
            }
        } label: {
            if isDownloading {
                ProgressView()
                    .tint(theme.primary)
                    .frame(width: 40, height: 40)
            } else {
                Image(systemName: isDownloaded ? "checkmark.circle.fill" : "arrow.down.circle")
                    .font(.system(size: 24))
                    .foregroundStyle(isDownloaded ? theme.primary : theme.onSurfaceVariant)
                    .frame(width: 40, height: 40)
            }
        }
        .buttonStyle(.plain)
    }

    private func statusPill(icon: String, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(label)
                .font(theme.scaledFont(size: 12, weight: .semibold))
        }
        .foregroundStyle(theme.onSurfaceVariant)
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .background(theme.surfaceVariant.opacity(0.55), in: Capsule())
    }

    private func secondaryBtn(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.onSurface)
                .frame(width: 42, height: 40)
                .sirajCardSurface(cornerRadius: 20)
        }
        .buttonStyle(.plain)
    }

    private var sleepLabel: String {
        if audioStore.sleepAtEndOfTrack {
            return theme.t("player_sleep_at_end")
        }
        if let end = audioStore.sleepEndDate {
            let mins = max(1, Int(ceil(end.timeIntervalSinceNow / 60)))
            return theme.t("player_sleep_remaining", theme.t("listen_duration_m", theme.digits(String(mins))))
        }
        return ""
    }

    private var sleepTimerSheet: some View {
        NavigationStack {
            List {
                ForEach([10, 15, 30, 45, 60], id: \.self) { mins in
                    Button {
                        audioStore.setSleepTimer(minutes: mins)
                        showSleepSheet = false
                    } label: {
                        Text(theme.t("player_sleep_minutes", theme.digits(String(mins))))
                            .foregroundStyle(theme.onSurface)
                    }
                }
                Button {
                    audioStore.setSleepAtEndOfTrack()
                    showSleepSheet = false
                } label: {
                    HStack {
                        Text(theme.t("player_sleep_end_of_track"))
                            .foregroundStyle(theme.onSurface)
                        Spacer()
                        if audioStore.sleepAtEndOfTrack {
                            Image(systemName: "checkmark").foregroundStyle(theme.primary)
                        }
                    }
                }
                if audioStore.hasSleepTimer {
                    Button(theme.t("player_sleep_off"), role: .destructive) {
                        audioStore.cancelSleepTimer()
                        showSleepSheet = false
                    }
                }
            }
            .navigationTitle(theme.t("player_sleep_timer"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(theme.t("close")) { showSleepSheet = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func speedString(_ sp: Float) -> String {
        let raw = sp == Float(Int(sp)) ? "\(Int(sp))" : String(format: "%g", sp)
        return "\(theme.digits(raw))×"
    }

    private func formatClock(_ sec: Double) -> String {
        let total = max(0, Int(sec.rounded(.down)))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return theme.digits(String(format: "%d:%02d:%02d", h, m, s))
        }
        return theme.digits(String(format: "%d:%02d", m, s))
    }
}

struct AmbientSoundSheet: View {
    @Environment(\.sirajTheme) private var theme
    let audioStore: QuranAudioStore

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(theme.t("ambient_title"))
                        .font(theme.scaledFont(size: 20, weight: .black))
                        .foregroundStyle(theme.onSurface)
                    Text(theme.t("ambient_subtitle"))
                        .font(theme.scaledFont(size: 12.5))
                        .foregroundStyle(theme.onSurfaceVariant)
                }
                Spacer()
                if audioStore.activeAmbient != nil {
                    Button(theme.t("ambient_off")) {
                        audioStore.chooseAmbient(nil)
                    }
                    .font(theme.scaledFont(size: 13.5, weight: .bold))
                    .foregroundStyle(theme.primary)
                }
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(AmbientSound.allCases) { sound in
                    let selected = audioStore.activeAmbient == sound
                    let state = audioStore.ambientStates[sound] ?? .absent
                    Button {
                        if state == .failed {
                            audioStore.downloadAmbient(sound)
                            audioStore.chooseAmbient(sound)
                        } else {
                            audioStore.chooseAmbient(sound)
                        }
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                if state == .downloading {
                                    ProgressView()
                                        .tint(theme.primary)
                                } else {
                                    Image(sound.iconAssetName)
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 26, height: 26)
                                        .foregroundStyle(selected ? theme.onPrimary : theme.primary)
                                }
                            }
                            .frame(width: 44, height: 44)
                            .background(selected ? theme.primary : theme.primary.opacity(0.11), in: Circle())

                            Text(theme.t(sound.labelKey))
                                .font(theme.scaledFont(size: 12.5, weight: selected ? .bold : .semibold))
                                .foregroundStyle(selected ? theme.primary : theme.onSurface)
                                .lineLimit(1)

                            if state == .absent {
                                let mb = String(format: "%.1f", Double(sound.bytes) / 1_048_576.0)
                                Text(theme.t("ambient_download_size", theme.digits(mb)))
                                    .font(theme.scaledFont(size: 10.5))
                                    .foregroundStyle(theme.onSurfaceVariant)
                            } else if state == .failed {
                                Text(theme.t("ambient_failed"))
                                    .font(theme.scaledFont(size: 10.5))
                                    .foregroundStyle(theme.error)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(selected ? theme.primary.opacity(0.12) : theme.surfaceVariant.opacity(0.45))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(selected ? theme.primary : theme.outlineVariant.opacity(0.3), lineWidth: selected ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            if audioStore.activeAmbient != nil {
                VStack(alignment: .leading, spacing: 6) {
                    Text(theme.t("ambient_volume"))
                        .font(theme.scaledFont(size: 13, weight: .bold))
                        .foregroundStyle(theme.onSurface)
                    HStack(spacing: 10) {
                        Image(systemName: "speaker.wave.1.fill")
                            .foregroundStyle(theme.onSurfaceVariant)
                        Slider(
                            value: Binding(
                                get: { Double(audioStore.ambientVolume) },
                                set: { audioStore.setAmbientVolume(Float($0)) }
                            ),
                            in: 0.05...1.0
                        )
                        .tint(theme.primary)
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundStyle(theme.primary)
                    }
                }
            }

            Text(theme.t("ambient_credit"))
                .font(theme.scaledFont(size: 11))
                .foregroundStyle(theme.onSurfaceVariant)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer(minLength: 0)
        }
        .padding(22)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
