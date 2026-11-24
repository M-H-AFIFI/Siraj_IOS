import SwiftUI
import UIKit
import SirajCore

struct QuranRadioArtwork: View {
    let station: QuranRadioStation
    var size: CGFloat = 56
    var cornerRadius: CGFloat = 16
    var showEqualizer: Bool = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        ZStack {
            if station.isEmblemArtwork {
                shape.fill(Color(argbHex: 0xFFFCF9F2))
                Image(station.artworkAsset)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.12)
            } else {
                Image(station.artworkAsset)
                    .resizable()
                    .scaledToFill()
            }

            if showEqualizer {
                shape.fill(Color.black.opacity(0.42))
                SirajEqualizerBars(isPlaying: true, color: .white, barWidth: max(2.5, size * 0.055), height: max(12, size * 0.28))
            }
        }
        .frame(width: size, height: size)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Color.white.opacity(0.18), lineWidth: 0.7))
    }
}

struct QuranRadioView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    let radioStore: QuranRadioStore
    let onOpenPlayer: () -> Void

    @State private var selectedFilter: QuranRadioFilter = .all
    @State private var searchQuery = ""
    @State private var isSearchOpen = false
    @Namespace private var filterNamespace

    private var filteredStations: [QuranRadioStation] {
        QuranRadioStation.filter(selectedFilter, query: searchQuery)
    }

    private var pinnedStations: [QuranRadioStation] {
        let pinnedSet = Set(radioStore.pinnedStationIds)
        return filteredStations.filter { pinnedSet.contains($0.id) }
    }

    private var broadcastStations: [QuranRadioStation] {
        let pinnedSet = Set(radioStore.pinnedStationIds)
        return filteredStations.filter { $0.kind == .broadcast && !pinnedSet.contains($0.id) }
    }

    private var reciterStations: [QuranRadioStation] {
        let pinnedSet = Set(radioStore.pinnedStationIds)
        return filteredStations.filter { $0.kind == .channel && !$0.isTopical && !pinnedSet.contains($0.id) }
    }

    private var topicalStations: [QuranRadioStation] {
        let pinnedSet = Set(radioStore.pinnedStationIds)
        return filteredStations.filter { $0.isTopical && !pinnedSet.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                headerBanner

                if isSearchOpen {
                    searchBar
                }

                if radioStore.activeStation == nil, let last = radioStore.lastStation, searchQuery.isEmpty {
                    lastListenedCard(last)
                }

                filterBar

                if filteredStations.isEmpty {
                    emptyState
                } else {
                    if !pinnedStations.isEmpty {
                        stationSection(title: theme.t("radio_section_pinned"), stations: pinnedStations)
                    }
                    if !broadcastStations.isEmpty {
                        stationSection(title: theme.t("radio_section_broadcasts"), stations: broadcastStations)
                    }
                    if !reciterStations.isEmpty {
                        stationSection(title: theme.t("radio_filter_reciters"), stations: reciterStations)
                    }
                    if !topicalStations.isEmpty {
                        stationSection(title: theme.t("radio_filter_tafsir_sunnah"), stations: topicalStations)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 130)
        }
        .scrollIndicators(.hidden)
        .background(Color.clear)
        .navigationTitle(theme.t("radio_live_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(theme.motionEnabled ? .easeInOut(duration: 0.2) : nil) {
                        isSearchOpen.toggle()
                        if !isSearchOpen { searchQuery = "" }
                    }
                } label: {
                    Image(systemName: isSearchOpen ? "xmark.circle.fill" : "magnifyingglass")
                        .foregroundStyle(theme.primary)
                }
            }
        }
    }

    private var headerBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(theme.primary.opacity(theme.isDark ? 0.20 : 0.12))
                    .frame(width: 46, height: 46)
                Image(systemName: "radio")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(theme.primary)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(radioStore.isPlaying ? theme.primary : theme.gold)
                        .frame(width: 7, height: 7)
                    Text(theme.t(radioStore.isPlaying ? "radio_live_now" : "radio_live_badge"))
                        .font(theme.scaledFont(size: 11.5, weight: .bold))
                        .foregroundStyle(theme.primary)
                }
                Text(theme.t("radio_hero_subtitle"))
                    .font(theme.scaledFont(size: 13))
                    .foregroundStyle(theme.onSurfaceVariant)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .sirajCardSurface(cornerRadius: 22)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(theme.primary)
            TextField(theme.t("radio_search_hint"), text: $searchQuery)
                .font(theme.scaledFont(size: 14.5))
                .foregroundStyle(theme.onSurface)
            if !searchQuery.isEmpty {
                Button { searchQuery = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(theme.outline)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 46)
        .sirajCardSurface(cornerRadius: 16)
    }

    private func lastListenedCard(_ station: QuranRadioStation) -> some View {
        Button {
            if appState.settings.isHapticEnabled {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            radioStore.playStation(station)
        } label: {
            HStack(spacing: 12) {
                QuranRadioArtwork(station: station, size: 52, cornerRadius: 14)

                VStack(alignment: .leading, spacing: 3) {
                    Text(theme.t("radio_last_listened"))
                        .font(theme.scaledFont(size: 11, weight: .bold))
                        .foregroundStyle(theme.primary)
                    Text(station.localizedName(language: theme.language))
                        .font(theme.scaledFont(size: 15, weight: .black))
                        .foregroundStyle(theme.onSurface)
                        .lineLimit(1)
                    Text(theme.t("radio_resume_listening"))
                        .font(theme.scaledFont(size: 12))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    Circle()
                        .fill(theme.primary)
                        .frame(width: 40, height: 40)
                    Image(systemName: "play.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(theme.onPrimary)
                }
            }
            .padding(14)
            .sirajCardSurface(cornerRadius: 22, isElevated: true)
        }
        .buttonStyle(.plain)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(QuranRadioFilter.allCases) { filter in
                    let active = selectedFilter == filter
                    Button {
                        if appState.settings.isHapticEnabled {
                            UISelectionFeedbackGenerator().selectionChanged()
                        }
                        withAnimation(theme.motionEnabled ? .spring(response: 0.32, dampingFraction: 0.82) : nil) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(theme.t(filter.titleKey))
                            .font(theme.scaledFont(size: 13, weight: .semibold))
                            .foregroundStyle(active ? theme.onPrimary : theme.onSurface)
                            .padding(.horizontal, 16)
                            .frame(height: 36)
                            .background {
                                if active {
                                    Capsule()
                                        .fill(theme.primary)
                                        .matchedGeometryEffect(id: "radioFilterPill", in: filterNamespace)
                                } else {
                                    Capsule()
                                        .fill(theme.isGlass ? Color.clear : theme.surface)
                                        .overlay(Capsule().strokeBorder(theme.outlineVariant.opacity(0.5), lineWidth: 1))
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func stationSection(title: String, stations: [QuranRadioStation]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(theme.scaledFont(size: 16, weight: .black))
                .foregroundStyle(theme.onBackground)
                .padding(.horizontal, 4)
                .padding(.top, 4)

            VStack(spacing: 10) {
                ForEach(stations) { station in
                    stationRow(station)
                }
            }
        }
    }

    private func stationRow(_ station: QuranRadioStation) -> some View {
        let isActive = radioStore.activeStation?.id == station.id
        let isPlaying = isActive && radioStore.isPlaying
        let isBusy = isActive && (radioStore.isBuffering || radioStore.isReconnecting)
        let isError = isActive && radioStore.hasError
        let isPinned = radioStore.isPinned(station.id)
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)

        return HStack(spacing: 12) {
            Button {
                if appState.settings.isHapticEnabled {
                    UISelectionFeedbackGenerator().selectionChanged()
                }
                if isActive {
                    onOpenPlayer()
                } else {
                    radioStore.playStation(station)
                }
            } label: {
                HStack(spacing: 12) {
                    QuranRadioArtwork(station: station, size: 54, cornerRadius: 14, showEqualizer: isPlaying)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(station.localizedName(language: theme.language))
                                .font(theme.scaledFont(size: 14.5, weight: .bold))
                                .foregroundStyle(isActive ? theme.primary : theme.onSurface)
                                .lineLimit(1)
                            if isPlaying {
                                Text(theme.t("radio_live_badge"))
                                    .font(theme.scaledFont(size: 9.5, weight: .black))
                                    .foregroundStyle(theme.onPrimary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(theme.primary))
                            }
                        }

                        Text(statusSubtitle(for: station, isActive: isActive, isPlaying: isPlaying, isBusy: isBusy, isError: isError))
                            .font(theme.scaledFont(size: 12))
                            .foregroundStyle(isError ? theme.error : (isActive ? theme.primary.opacity(0.9) : theme.onSurfaceVariant))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        if station.hasPlace {
                            Text(station.localizedLocation(language: theme.language))
                                .font(theme.scaledFont(size: 11, weight: .medium))
                                .foregroundStyle(theme.outline)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            HStack(spacing: 6) {
                Button {
                    if appState.settings.isHapticEnabled {
                        UISelectionFeedbackGenerator().selectionChanged()
                    }
                    radioStore.togglePin(station.id)
                } label: {
                    Image(systemName: isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isPinned ? theme.primary : theme.outline)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(theme.t(isPinned ? "radio_unpin" : "radio_pin"))

                Button {
                    if appState.settings.isHapticEnabled {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    if isError {
                        radioStore.retryActive()
                    } else {
                        radioStore.togglePlayPause(station)
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(isActive ? theme.primary : theme.primary.opacity(theme.isDark ? 0.18 : 0.11))
                            .frame(width: 40, height: 40)
                        if isBusy {
                            ProgressView()
                                .tint(isActive ? theme.onPrimary : theme.primary)
                        } else if isError {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(theme.onPrimary)
                        } else {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(isActive ? theme.onPrimary : theme.primary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .sirajCardSurface(cornerRadius: 20, isElevated: isActive)
        .overlay(
            shape.strokeBorder(isActive ? theme.primary.opacity(0.55) : Color.clear, lineWidth: isActive ? 1.2 : 0)
        )
    }

    private func statusSubtitle(
        for station: QuranRadioStation,
        isActive: Bool,
        isPlaying: Bool,
        isBusy: Bool,
        isError: Bool
    ) -> String {
        if isError { return theme.t("radio_error") }
        if isActive && radioStore.isReconnecting { return theme.t("radio_reconnecting") }
        if isBusy { return theme.t("radio_now_on_air") }
        if isPlaying, let np = radioStore.nowPlaying { return np }
        return station.localizedDescription(language: theme.language)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "radio")
                .font(.system(size: 36))
                .foregroundStyle(theme.outline)
            Text(theme.t("radio_no_results"))
                .font(theme.scaledFont(size: 15, weight: .semibold))
                .foregroundStyle(theme.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

struct QuranRadioPlayerView: View {
    @Environment(\.sirajTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    let appState: AppState
    let radioStore: QuranRadioStore

    @State private var showSleepSheet = false

    var body: some View {
        let station = radioStore.activeStation ?? radioStore.lastStation ?? QuranRadioStation.stations[0]
        let isPinned = radioStore.isPinned(station.id)
        let isBusy = radioStore.isBuffering || radioStore.isReconnecting

        ZStack {
            theme.background.ignoresSafeArea()
            Image(station.artworkAsset)
                .resizable()
                .scaledToFill()
                .blur(radius: 56)
                .opacity(theme.isDark ? 0.28 : 0.16)
                .ignoresSafeArea()

            LinearGradient(
                colors: [theme.background.opacity(0.45), theme.background.opacity(0.94)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    topBar(station: station)

                    ZStack(alignment: .topTrailing) {
                        QuranRadioArtwork(station: station, size: 248, cornerRadius: 30)
                            .shadow(color: Color.black.opacity(theme.isDark ? 0.45 : 0.18), radius: 22, y: 12)
                            .scaleEffect(radioStore.isPlaying ? 1.0 : 0.94)
                            .animation(theme.motionEnabled ? .spring(response: 0.45, dampingFraction: 0.8) : nil, value: radioStore.isPlaying)

                        HStack(spacing: 5) {
                            Circle()
                                .fill(radioStore.isPlaying ? Color(argbHex: 0xFF34D399) : theme.gold)
                                .frame(width: 7, height: 7)
                            Text(theme.t("radio_live_badge"))
                                .font(theme.scaledFont(size: 11, weight: .black))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.black.opacity(0.62)))
                        .padding(14)
                    }
                    .padding(.top, 4)

                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(station.localizedName(language: theme.language))
                                .font(theme.scaledFont(size: 22, weight: .black))
                                .foregroundStyle(theme.onSurface)
                                .lineLimit(2)
                            Text(station.localizedDescription(language: theme.language))
                                .font(theme.scaledFont(size: 14))
                                .foregroundStyle(theme.onSurfaceVariant)
                                .lineLimit(2)
                        }
                        Spacer()
                        Button {
                            if appState.settings.isHapticEnabled {
                                UISelectionFeedbackGenerator().selectionChanged()
                            }
                            radioStore.togglePin(station.id)
                        } label: {
                            Image(systemName: isPinned ? "pin.fill" : "pin")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(isPinned ? theme.primary : theme.onSurfaceVariant)
                                .frame(width: 44, height: 44)
                                .sirajCardSurface(cornerRadius: 22)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(theme.t(isPinned ? "radio_unpin" : "radio_pin"))
                    }

                    // Live chips: now-playing metadata & sleep timer
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(theme.primary)
                                    .frame(width: 7, height: 7)
                                Text(radioStore.nowPlaying ?? theme.t(radioStore.isReconnecting ? "radio_reconnecting" : "radio_now_on_air"))
                                    .font(theme.scaledFont(size: 12, weight: .semibold))
                                    .foregroundStyle(theme.primary)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(theme.primary.opacity(0.13), in: Capsule())

                            Button { showSleepSheet = true } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "moon.zzz")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text(sleepChipText)
                                        .font(theme.scaledFont(size: 12, weight: .semibold))
                                        .lineLimit(1)
                                }
                                .foregroundStyle(radioStore.hasSleepTimer ? theme.primary : theme.onSurfaceVariant)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    (radioStore.hasSleepTimer ? theme.primary.opacity(0.13) : theme.surfaceContainerHigh.opacity(0.75)),
                                    in: Capsule()
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if radioStore.hasError {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(theme.error)
                            Text(theme.t("radio_error"))
                                .font(theme.scaledFont(size: 12.5))
                                .foregroundStyle(theme.onSurface)
                            Spacer()
                            Button(theme.t("setup_retry")) {
                                radioStore.retryActive()
                            }
                            .font(theme.scaledFont(size: 12.5, weight: .bold))
                            .foregroundStyle(theme.primary)
                        }
                        .padding(12)
                        .background(theme.error.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
                    }

                    // Live wave indicator
                    VStack(spacing: 6) {
                        WavyProgressBar(
                            progress: radioStore.isPlaying ? 1.0 : 0.0,
                            isPlaying: radioStore.isPlaying,
                            onSeek: nil,
                            height: 24
                        )
                        HStack {
                            Text(theme.t("radio_live_now"))
                                .font(theme.scaledFont(size: 11.5, weight: .bold))
                                .foregroundStyle(theme.primary)
                            Spacer()
                            Text(station.localizedLocation(language: theme.language))
                                .font(theme.scaledFont(size: 11.5, weight: .medium))
                                .foregroundStyle(theme.onSurfaceVariant)
                        }
                    }

                    // Primary transport
                    HStack(spacing: 32) {
                        Button {
                            if appState.settings.isHapticEnabled { UISelectionFeedbackGenerator().selectionChanged() }
                            radioStore.skip(delta: -1)
                        } label: {
                            Image(systemName: theme.isRTL ? "forward.end.fill" : "backward.end.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(theme.onSurface)
                                .frame(width: 52, height: 52)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(theme.t("player_previous_station"))

                        Button {
                            if appState.settings.isHapticEnabled { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
                            radioStore.togglePlayPause(station)
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(theme.primary)
                                    .frame(width: 72, height: 72)
                                    .shadow(color: theme.primary.opacity(0.32), radius: 14, y: 6)
                                if isBusy {
                                    ProgressView()
                                        .tint(theme.onPrimary)
                                } else {
                                    Image(systemName: radioStore.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundStyle(theme.onPrimary)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        Button {
                            if appState.settings.isHapticEnabled { UISelectionFeedbackGenerator().selectionChanged() }
                            radioStore.skip(delta: 1)
                        } label: {
                            Image(systemName: theme.isRTL ? "backward.end.fill" : "forward.end.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(theme.onSurface)
                                .frame(width: 52, height: 52)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(theme.t("player_next_station"))
                    }
                    .padding(.vertical, 4)

                    // Action row: All stations + Stop
                    HStack(spacing: 12) {
                        Button {
                            dismiss()
                            appState.selectedTab = .azkar
                            appState.requestedWorshipRoute = .radio
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "list.bullet")
                                Text(theme.t("player_all_stations"))
                                    .font(theme.scaledFont(size: 13.5, weight: .bold))
                            }
                            .foregroundStyle(theme.onSurface)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .sirajCardSurface(cornerRadius: 22)
                        }
                        .buttonStyle(.plain)

                        Button {
                            radioStore.stop()
                            dismiss()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "stop.fill")
                                Text(theme.t("radio_stop"))
                                    .font(theme.scaledFont(size: 13.5, weight: .bold))
                            }
                            .foregroundStyle(theme.error)
                            .padding(.horizontal, 18)
                            .frame(height: 44)
                            .sirajCardSurface(cornerRadius: 22)
                        }
                        .buttonStyle(.plain)
                    }

                    if let next = radioStore.upNextStation {
                        upNextCard(next)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 36)
            }
            .scrollIndicators(.hidden)
        }
        .sheet(isPresented: $showSleepSheet) {
            radioSleepSheet
        }
    }

    private func topBar(station: QuranRadioStation) -> some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(theme.onSurface)
                    .frame(width: 40, height: 40)
                    .sirajCardSurface(cornerRadius: 20)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(theme.t("player_minimise"))

            Spacer()

            VStack(spacing: 2) {
                Text(
                    station.hasPlace
                        ? theme.t("player_live_from", station.localizedLocation(language: theme.language))
                        : theme.t("radio_live_badge")
                )
                .font(theme.scaledFont(size: 12, weight: .bold))
                .foregroundStyle(theme.primary)
                .lineLimit(1)
            }

            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
    }

    private func upNextCard(_ station: QuranRadioStation) -> some View {
        Button {
            radioStore.playStation(station)
        } label: {
            HStack(spacing: 12) {
                QuranRadioArtwork(station: station, size: 46, cornerRadius: 12)
                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.t("player_up_next_label"))
                        .font(theme.scaledFont(size: 11, weight: .bold))
                        .foregroundStyle(theme.primary)
                    Text(station.localizedName(language: theme.language))
                        .font(theme.scaledFont(size: 14, weight: .bold))
                        .foregroundStyle(theme.onSurface)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: theme.isRTL ? "chevron.left" : "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.outline)
            }
            .padding(12)
            .sirajCardSurface(cornerRadius: 18)
        }
        .buttonStyle(.plain)
    }

    private var sleepChipText: String {
        if let mins = radioStore.sleepRemainingMinutes() {
            return theme.t("player_sleep_remaining", theme.digits(String(mins)))
        }
        return theme.t("player_sleep_timer")
    }

    private var radioSleepSheet: some View {
        NavigationStack {
            List {
                ForEach([15, 30, 45, 60], id: \.self) { mins in
                    Button {
                        radioStore.setSleepTimer(minutes: mins)
                        showSleepSheet = false
                    } label: {
                        HStack {
                            Text(theme.t("player_sleep_minutes", theme.digits(String(mins))))
                                .foregroundStyle(theme.onSurface)
                            Spacer()
                            Image(systemName: "clock")
                                .foregroundStyle(theme.primary)
                        }
                    }
                }
                if radioStore.hasSleepTimer {
                    Button(role: .destructive) {
                        radioStore.cancelSleepTimer()
                        showSleepSheet = false
                    } label: {
                        Text(theme.t("player_sleep_off"))
                    }
                }
            }
            .navigationTitle(theme.t("player_sleep_timer"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(theme.t("close")) { showSleepSheet = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct QuranRadioMiniPlayer: View {
    @Environment(\.sirajTheme) private var theme
    let radioStore: QuranRadioStore
    let onOpenPlayer: () -> Void

    var body: some View {
        if let station = radioStore.activeStation {
            let isBusy = radioStore.isBuffering || radioStore.isReconnecting
            HStack(spacing: 10) {
                Button(action: onOpenPlayer) {
                    HStack(spacing: 10) {
                        ZStack(alignment: .bottomTrailing) {
                            QuranRadioArtwork(station: station, size: 40, cornerRadius: 11)
                            Circle()
                                .fill(radioStore.isPlaying ? Color(argbHex: 0xFF22C55E) : theme.gold)
                                .frame(width: 9, height: 9)
                                .overlay(Circle().stroke(theme.surface, lineWidth: 1.5))
                                .offset(x: 2, y: 2)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(station.localizedName(language: theme.language))
                                .font(theme.scaledFont(size: 13.5, weight: .bold))
                                .foregroundStyle(theme.onSurface)
                                .lineLimit(1)
                            Text(
                                radioStore.hasError
                                    ? theme.t("radio_error")
                                    : (radioStore.nowPlaying ?? theme.t(radioStore.isReconnecting ? "radio_reconnecting" : "radio_live_now"))
                            )
                            .font(theme.scaledFont(size: 11.5))
                            .foregroundStyle(radioStore.hasError ? theme.error : theme.primary)
                            .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                HStack(spacing: 4) {
                    Button {
                        if radioStore.hasError {
                            radioStore.retryActive()
                        } else {
                            radioStore.togglePlayPause(station)
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(theme.primary.opacity(0.14))
                                .frame(width: 34, height: 34)
                            if isBusy {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(theme.primary)
                            } else {
                                Image(systemName: radioStore.hasError ? "arrow.clockwise" : (radioStore.isPlaying ? "pause.fill" : "play.fill"))
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(theme.primary)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        radioStore.stop()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(theme.onSurfaceVariant)
                            .frame(width: 30, height: 34)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(theme.t("radio_stop"))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .sirajCardSurface(cornerRadius: 22, isElevated: true)
            .padding(.horizontal, 14)
        }
    }
}
