import SwiftUI
import SirajCore

enum ListenRoute: Hashable {
    case reciter(String)
    case rare(String)
}

private enum ListenFilterTab: String, CaseIterable, Identifiable {
    case all, offline, murattal, mujawwad
    var id: String { rawValue }
    var titleKey: String {
        switch self {
        case .all: return "listen_filter_all"
        case .offline: return "listen_filter_offline"
        case .murattal: return "listen_filter_murattal"
        case .mujawwad: return "listen_filter_mujawwad"
        }
    }
}

struct ListenHubView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    let audioStore: QuranAudioStore
    let onOpenPlayer: () -> Void

    @State private var searchQuery = ""
    @State private var showSearch = false
    @State private var filter: ListenFilterTab = .all
    @State private var chooserGroup: ReciterGroup?
    @State private var showAmbientSheet = false

    private var allGroups: [ReciterGroup] {
        ListenTitles.buildReciterGroups(
            language: theme.language,
            offlineSurahs: audioStore.offlineSurahCounts,
            offlineRare: audioStore.offlineRareCounts
        )
    }

    private var visibleGroups: [ReciterGroup] {
        let folded = ArabicSearchText.normalizeQuery(searchQuery)
        return allGroups.filter { group in
            let matchesFilter: Bool
            switch filter {
            case .all: matchesFilter = true
            case .offline: matchesFilter = group.offlineCount > 0
            case .murattal: matchesFilter = group.versions.contains { $0.style == "Murattal" || $0.isCollection }
            case .mujawwad: matchesFilter = group.versions.contains { $0.style == "Mujawwad" }
            }
            return matchesFilter && group.matches(foldedQuery: folded)
        }
    }

    private var groupedByLetter: [(letter: String, items: [ReciterGroup])] {
        var order: [String] = []
        var dict: [String: [ReciterGroup]] = [:]
        for g in visibleGroups {
            if dict[g.letter] == nil {
                order.append(g.letter)
                dict[g.letter] = []
            }
            dict[g.letter]?.append(g)
        }
        return order.map { ($0, dict[$0] ?? []) }
    }

    private var isBrowsing: Bool {
        searchQuery.trimmingCharacters(in: .whitespaces).isEmpty && filter == .all
    }

    private var featuredRare: [RareCollection] {
        ListeningCatalog.rareCollections.filter(\.isRare)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if showSearch {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(theme.primary)
                        TextField(theme.t("listen_search_hint"), text: $searchQuery)
                            .font(theme.scaledFont(size: 14.5))
                        if !searchQuery.isEmpty {
                            Button { searchQuery = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(theme.onSurfaceVariant)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 46)
                    .sirajCardSurface(cornerRadius: 18)
                }

                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ListenFilterTab.allCases) { tab in
                            let active = filter == tab
                            Button { filter = tab } label: {
                                Text(theme.t(tab.titleKey))
                                    .font(theme.scaledFont(size: 12.5, weight: active ? .bold : .medium))
                                    .foregroundStyle(active ? theme.onPrimary : theme.onSurface)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(active ? theme.primary : theme.surfaceVariant.opacity(0.6), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Now playing or Continue listening hero
                if isBrowsing && (audioStore.hasActiveListening || audioStore.lastSession != nil) {
                    continueListeningCard
                }

                // Featured rare recitations
                if isBrowsing && !featuredRare.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(theme.t("listen_rare_title"))
                                .font(theme.scaledFont(size: 17, weight: .black))
                                .foregroundStyle(theme.onSurface)
                            Text(theme.t("listen_rare_subtitle"))
                                .font(theme.scaledFont(size: 12.5))
                                .foregroundStyle(theme.onSurfaceVariant)
                        }
                        ForEach(featuredRare) { collection in
                            rareFeatureCard(collection)
                        }
                    }
                }

                // Reciters section header
                HStack {
                    Text(theme.t("listen_reciters_title"))
                        .font(theme.scaledFont(size: 17, weight: .black))
                        .foregroundStyle(theme.onSurface)
                    Spacer()
                    Text(theme.plural("listen_reciters_count", count: visibleGroups.count, theme.digits(String(visibleGroups.count))))
                        .font(theme.scaledFont(size: 12, weight: .semibold))
                        .foregroundStyle(theme.onSurfaceVariant)
                }

                if visibleGroups.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: filter == .offline ? "arrow.down.circle" : "magnifyingglass")
                            .font(.system(size: 32))
                            .foregroundStyle(theme.onSurfaceVariant.opacity(0.7))
                        Text(theme.t(filter == .offline ? "listen_empty_offline" : "listen_no_results"))
                            .font(theme.scaledFont(size: 14))
                            .foregroundStyle(theme.onSurfaceVariant)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 36)
                } else {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(groupedByLetter, id: \.letter) { section in
                            Text(section.letter)
                                .font(theme.scaledFont(size: 13, weight: .black))
                                .foregroundStyle(theme.primary)
                                .padding(.horizontal, 6)
                                .padding(.top, 6)

                            ForEach(section.items) { group in
                                reciterGroupRow(group)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 128)
        }
        .scrollIndicators(.hidden)
        .background(Color.clear)
        .navigationTitle(theme.t("listen_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showAmbientSheet = true
                } label: {
                    ZStack(alignment: .bottom) {
                        Image(audioStore.activeAmbient?.iconAssetName ?? "ic_ambient_off")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 21, height: 21)
                            .foregroundStyle(audioStore.activeAmbient != nil ? theme.primary : theme.onSurface)
                        if audioStore.activeAmbient != nil {
                            Circle()
                                .fill(theme.primary)
                                .frame(width: 5, height: 5)
                                .offset(y: 6)
                        }
                    }
                }
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSearch.toggle()
                        if !showSearch { searchQuery = "" }
                    }
                } label: {
                    Image(systemName: showSearch ? "xmark" : "magnifyingglass")
                        .foregroundStyle(theme.onSurface)
                }
            }
        }
        .navigationDestination(for: ListenRoute.self) { route in
            switch route {
            case .reciter(let id):
                ListenReciterView(
                    appState: appState,
                    audioStore: audioStore,
                    reciterId: id,
                    onOpenPlayer: onOpenPlayer
                )
            case .rare(let id):
                ListenRareView(
                    appState: appState,
                    audioStore: audioStore,
                    collectionId: id,
                    onOpenPlayer: onOpenPlayer
                )
            }
        }
        .sheet(item: $chooserGroup) { group in
            versionChooserSheet(group)
        }
        .sheet(isPresented: $showAmbientSheet) {
            AmbientSoundSheet(audioStore: audioStore)
        }
    }

    private var continueListeningCard: some View {
        let activeTrack = audioStore.currentListeningTrack
        let session = audioStore.lastSession
        let title = activeTrack?.title ?? session?.title ?? ""
        let artist = activeTrack?.artist ?? session?.artist ?? ""
        let sourceId = activeTrack?.sourceId ?? session?.sourceId ?? ""
        let artwork = activeTrack?.artworkAsset ?? ReciterPhotoCatalog.assetName(for: sourceId)
        let isPlaying = audioStore.listeningIsPlaying
        let badgeKey = activeTrack != nil ? (isPlaying ? "listen_now_playing" : "listen_paused") : "listen_continue"

        return Button {
            if activeTrack != nil {
                onOpenPlayer()
            } else {
                audioStore.resumeLastSession(surahs: appState.quranStore.surahs, language: theme.language)
                onOpenPlayer()
            }
        } label: {
            HStack(spacing: 14) {
                ReciterAvatarView(reciterId: sourceId, name: artist, photoAsset: artwork, size: 54, isSelected: true, isPlaying: isPlaying)

                VStack(alignment: .leading, spacing: 3) {
                    Text(theme.t(badgeKey))
                        .font(theme.scaledFont(size: 11, weight: .black))
                        .foregroundStyle(theme.primary)
                        .textCase(.uppercase)
                    Text(title)
                        .font(theme.scaledFont(size: 16, weight: .black))
                        .foregroundStyle(theme.onSurface)
                        .lineLimit(1)
                    Text(artist)
                        .font(theme.scaledFont(size: 13))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .lineLimit(1)
                }
                Spacer()
                Button {
                    if activeTrack != nil {
                        audioStore.toggleListeningPlayPause()
                    } else {
                        audioStore.resumeLastSession(surahs: appState.quranStore.surahs, language: theme.language)
                        onOpenPlayer()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(theme.primary)
                            .frame(width: 44, height: 44)
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(theme.onPrimary)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .sirajCardSurface(cornerRadius: 24, isElevated: true)
        }
        .buttonStyle(.plain)
    }

    private func rareFeatureCard(_ collection: RareCollection) -> some View {
        let isCurrent = audioStore.currentListeningTrack?.sourceId == collection.id
        let isPlaying = isCurrent && audioStore.listeningIsPlaying
        let mins = collection.totalSeconds / 60
        let hours = mins / 60
        let remMin = mins % 60
        let durationText = hours > 0
            ? theme.t("listen_duration_hm", theme.digits(String(hours)), theme.digits(String(remMin)))
            : theme.t("listen_duration_m", theme.digits(String(mins)))

        return NavigationLink(value: ListenRoute.rare(collection.id)) {
            HStack(spacing: 14) {
                ReciterAvatarView(
                    reciterId: collection.id,
                    name: collection.localizedName(language: theme.language),
                    photoAsset: collection.photoAsset,
                    size: 58,
                    isSelected: isCurrent,
                    isPlaying: isPlaying
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(theme.t("listen_rare_label"))
                        .font(theme.scaledFont(size: 10.5, weight: .black))
                        .foregroundStyle(theme.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(theme.primary.opacity(0.12), in: Capsule())

                    Text(collection.localizedName(language: theme.language))
                        .font(theme.scaledFont(size: 16, weight: .black))
                        .foregroundStyle(theme.onSurface)
                        .lineLimit(1)

                    Text("\(theme.plural("listen_recordings_count", count: collection.tracks.count, theme.digits(String(collection.tracks.count)))) • \(durationText)")
                        .font(theme.scaledFont(size: 12.5))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    if isCurrent {
                        audioStore.toggleListeningPlayPause()
                    } else {
                        audioStore.playRare(collection.id, surahs: appState.quranStore.surahs, language: theme.language)
                        onOpenPlayer()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(theme.primary.opacity(0.14))
                            .frame(width: 40, height: 40)
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(theme.primary)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(15)
            .sirajCardSurface(cornerRadius: 24, isElevated: true)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func reciterGroupRow(_ group: ReciterGroup) -> some View {
        let isCurrent = group.versions.contains { $0.id == audioStore.currentListeningTrack?.sourceId }
        let isPlaying = isCurrent && audioStore.listeningIsPlaying

        if group.versions.count > 1 {
            Button {
                chooserGroup = group
            } label: {
                reciterRowContent(group: group, isCurrent: isCurrent, isPlaying: isPlaying)
            }
            .buttonStyle(.plain)
        } else {
            let route: ListenRoute = group.primary.isCollection ? .rare(group.primary.id) : .reciter(group.primary.id)
            NavigationLink(value: route) {
                reciterRowContent(group: group, isCurrent: isCurrent, isPlaying: isPlaying)
            }
            .buttonStyle(.plain)
        }
    }

    private func reciterRowContent(group: ReciterGroup, isCurrent: Bool, isPlaying: Bool) -> some View {
        let subtitle: String = {
            if group.versions.count > 1 {
                let styles = group.versions.compactMap { v -> String? in
                    if v.riwayah == Reciter.warsh { return theme.t("listen_riwayah_warsh_short") }
                    if v.riwayah == Reciter.qalun { return theme.t("listen_riwayah_qalun_short") }
                    if v.style == "Mujawwad" { return theme.t("listen_filter_mujawwad") }
                    if v.style?.contains("Teacher") == true { return theme.t("reciter_picker_style_teacher") }
                    return theme.t("listen_filter_murattal")
                }
                return styles.joined(separator: " • ")
            } else if group.primary.isCollection {
                return "\(theme.t("listen_version_selected")) • \(theme.plural("listen_recordings_count", count: group.primary.total, theme.digits(String(group.primary.total))))"
            } else if group.offlineCount > 0 {
                return theme.t("listen_offline_desc", theme.digits(String(group.offlineCount)), theme.digits(String(group.primary.total)))
            } else {
                return theme.t("listen_version_complete")
            }
        }()

        return HStack(spacing: 12) {
            ReciterAvatarView(
                reciterId: group.key,
                name: group.name,
                photoAsset: group.photoAsset,
                size: 48,
                isSelected: isCurrent,
                isPlaying: isPlaying
            )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(group.name)
                        .font(theme.scaledFont(size: 15, weight: .bold))
                        .foregroundStyle(isCurrent ? theme.primary : theme.onSurface)
                        .lineLimit(1)
                    if group.offlineCount > 0 {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(theme.primary)
                    }
                }
                Text(subtitle)
                    .font(theme.scaledFont(size: 12.5))
                    .foregroundStyle(theme.onSurfaceVariant)
                    .lineLimit(1)
            }

            Spacer()

            if isPlaying {
                SirajEqualizerBars(isPlaying: true)
                    .padding(.trailing, 4)
            } else {
                Button {
                    let version = group.versions.first(where: { $0.id == audioStore.currentListeningTrack?.sourceId }) ?? group.primary
                    if version.id == audioStore.currentListeningTrack?.sourceId {
                        audioStore.toggleListeningPlayPause()
                    } else if version.isCollection {
                        audioStore.playRare(version.id, surahs: appState.quranStore.surahs, language: theme.language)
                        onOpenPlayer()
                    } else {
                        audioStore.playReciter(version.id, surahs: appState.quranStore.surahs, language: theme.language)
                        onOpenPlayer()
                    }
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(theme.primary.opacity(0.85))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .sirajCardSurface(cornerRadius: 18)
    }

    private func versionChooserSheet(_ group: ReciterGroup) -> some View {
        NavigationStack {
            List {
                ForEach(group.versions) { version in
                    let rec = Reciter.byId(version.id)
                    let label = versionLabel(rec)
                    NavigationLink(value: ListenRoute.reciter(version.id)) {
                        HStack(spacing: 12) {
                            ReciterAvatarView(reciterId: rec.id, name: group.name, photoAsset: group.photoAsset, size: 42)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(label)
                                    .font(theme.scaledFont(size: 15, weight: .bold))
                                    .foregroundStyle(theme.onSurface)
                                Text(version.offlineCount > 0
                                     ? theme.t("listen_offline_desc", theme.digits(String(version.offlineCount)), theme.digits("114"))
                                     : rec.riwayah)
                                    .font(theme.scaledFont(size: 12))
                                    .foregroundStyle(theme.onSurfaceVariant)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(group.name)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: ListenRoute.self) { route in
                if case .reciter(let id) = route {
                    ListenReciterView(
                        appState: appState,
                        audioStore: audioStore,
                        reciterId: id,
                        onOpenPlayer: {
                            chooserGroup = nil
                            onOpenPlayer()
                        }
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(theme.t("close")) { chooserGroup = nil }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func versionLabel(_ rec: Reciter) -> String {
        if rec.riwayah == Reciter.warsh { return theme.t("listen_riwayah_warsh") }
        if rec.riwayah == Reciter.qalun { return theme.t("listen_riwayah_qalun") }
        if rec.subInfo == "Mujawwad" { return theme.t("listen_filter_mujawwad") }
        if rec.subInfo?.contains("Teacher") == true { return theme.t("reciter_picker_style_teacher") }
        return "\(theme.t("listen_filter_murattal")) • \(theme.t("listen_riwayah"))"
    }
}

struct ListenReciterView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    let audioStore: QuranAudioStore
    let reciterId: String
    let onOpenPlayer: () -> Void

    @State private var query = ""
    @State private var confirmRemove = false

    private var reciter: Reciter { Reciter.byId(reciterId) }

    private var surahs: [Surah] {
        let all = appState.quranStore.surahs
        let q = query.trimmingCharacters(in: .whitespaces)
        if q.isEmpty { return all }
        return all.filter { SurahNames.matches($0, query: q) }
    }

    private var downloadedCount: Int {
        audioStore.downloadedSurahs[reciterId]?.count ?? 0
    }

    private var isDownloadingAll: Bool {
        audioStore.batchDownloadingSourceId == reciterId
    }

    var body: some View {
        let name = reciter.shortDisplayName(language: theme.language)
        let playingHere = audioStore.currentListeningTrack?.sourceId == reciterId
        let isPlayingThis = playingHere && audioStore.listeningIsPlaying

        ScrollView {
            VStack(spacing: 14) {
                // Hero
                VStack(spacing: 10) {
                    ReciterAvatarView(
                        reciterId: reciter.id,
                        name: name,
                        size: 92,
                        isSelected: playingHere,
                        isPlaying: isPlayingThis
                    )
                    Text(name)
                        .font(theme.scaledFont(size: 21, weight: .black))
                        .foregroundStyle(theme.onSurface)
                        .multilineTextAlignment(.center)
                    Text("\(reciter.localizedSubInfo(language: theme.language) ?? "") • \(reciter.riwayah)")
                        .font(theme.scaledFont(size: 13))
                        .foregroundStyle(theme.onSurfaceVariant)
                    if downloadedCount > 0 {
                        Text(downloadedCount >= 114
                             ? theme.t("listen_all_offline")
                             : theme.t("listen_offline_desc", theme.digits(String(downloadedCount)), theme.digits("114")))
                            .font(theme.scaledFont(size: 12, weight: .bold))
                            .foregroundStyle(theme.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(theme.primary.opacity(0.12), in: Capsule())
                    }
                }
                .padding(.top, 8)

                // Action pills
                HStack(spacing: 10) {
                    Button {
                        if playingHere {
                            audioStore.toggleListeningPlayPause()
                        } else {
                            audioStore.playReciter(reciterId, surahNumber: 1, surahs: appState.quranStore.surahs, language: theme.language)
                            onOpenPlayer()
                        }
                    } label: {
                        Label(theme.t(isPlayingThis ? "pause" : "play"), systemImage: isPlayingThis ? "pause.fill" : "play.fill")
                            .font(theme.scaledFont(size: 14, weight: .bold))
                            .foregroundStyle(theme.onPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(theme.primary, in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        audioStore.playReciter(reciterId, shuffle: true, surahs: appState.quranStore.surahs, language: theme.language)
                        onOpenPlayer()
                    } label: {
                        Label(theme.t("listen_shuffle"), systemImage: "shuffle")
                            .font(theme.scaledFont(size: 14, weight: .bold))
                            .foregroundStyle(theme.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(theme.primary.opacity(0.13), in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        if isDownloadingAll {
                            audioStore.stopDownloads()
                        } else if downloadedCount < 114 {
                            audioStore.downloadAllSurahs(reciterId: reciterId)
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(downloadedCount >= 114 ? theme.primary.opacity(0.16) : theme.surfaceVariant.opacity(0.7))
                                .frame(width: 46, height: 46)
                            Image(systemName: isDownloadingAll ? "stop.fill" : (downloadedCount >= 114 ? "checkmark.icloud.fill" : "icloud.and.arrow.down"))
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(theme.primary)
                        }
                    }
                    .buttonStyle(.plain)
                }

                if isDownloadingAll {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(theme.t("listen_downloading_progress", theme.digits(String(downloadedCount)), theme.digits("114")))
                            .font(theme.scaledFont(size: 12, weight: .bold))
                            .foregroundStyle(theme.primary)
                        ProgressView(value: Double(downloadedCount), total: 114)
                            .tint(theme.primary)
                    }
                }

                // Search surahs
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(theme.primary)
                    TextField(theme.t("listen_search_surah_hint"), text: $query)
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

                LazyVStack(spacing: 8) {
                    ForEach(surahs) { surah in
                        surahTrackRow(surah)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 128)
        }
        .scrollIndicators(.hidden)
        .background(Color.clear)
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(theme.t("listen_remove_downloads"), role: .destructive) {
                        confirmRemove = true
                    }
                    .disabled(downloadedCount == 0)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(theme.onSurface)
                }
            }
        }
        .alert(theme.t("listen_remove_title", name), isPresented: $confirmRemove) {
            Button(theme.t("listen_remove_confirm"), role: .destructive) {
                audioStore.removeDownloads(forReciter: reciterId)
            }
            Button(theme.t("listen_cancel"), role: .cancel) {}
        } message: {
            Text(theme.t("listen_remove_reciter_body"))
        }
    }

    private func surahTrackRow(_ surah: Surah) -> some View {
        let trackId = ListenTitles.surahTrackId(reciterId: reciterId, surahNumber: surah.number)
        let isCurrent = audioStore.currentListeningTrack?.id == trackId
        let isPlaying = isCurrent && audioStore.listeningIsPlaying
        let isDownloaded = audioStore.isSurahDownloaded(reciterId: reciterId, surah: surah.number)
        let dlKey = audioStore.downloadKey(reciterId: reciterId, surah: surah.number)
        let isDownloading = audioStore.activeDownloads[dlKey] != nil

        return HStack(spacing: 12) {
            Button {
                if isCurrent {
                    audioStore.toggleListeningPlayPause()
                } else {
                    audioStore.playReciter(reciterId, surahNumber: surah.number, surahs: appState.quranStore.surahs, language: theme.language)
                    onOpenPlayer()
                }
            } label: {
                HStack(spacing: 12) {
                    NumberStar(text: theme.digits(String(surah.number)), size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(SurahNames.forLanguage(surah, language: theme.language))
                            .font(theme.scaledFont(size: 15, weight: .bold))
                            .foregroundStyle(isCurrent ? theme.primary : theme.onSurface)
                            .lineLimit(1)
                        Text(theme.plural("ayah_count", count: surah.numberOfAyahs, theme.digits(String(surah.numberOfAyahs))))
                            .font(theme.scaledFont(size: 12))
                            .foregroundStyle(theme.onSurfaceVariant)
                    }
                    Spacer()
                    if isPlaying {
                        SirajEqualizerBars(isPlaying: true)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                if isDownloading {
                    audioStore.stopDownload(key: dlKey)
                } else if !isDownloaded {
                    audioStore.downloadSurah(reciterId: reciterId, surah: surah.number)
                }
            } label: {
                if isDownloading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(theme.primary)
                        .frame(width: 34, height: 34)
                } else {
                    Image(systemName: isDownloaded ? "checkmark.circle.fill" : "arrow.down.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(isDownloaded ? theme.primary : theme.onSurfaceVariant)
                        .frame(width: 34, height: 34)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .sirajCardSurface(cornerRadius: 16)
    }
}

struct ListenRareView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    let audioStore: QuranAudioStore
    let collectionId: String
    let onOpenPlayer: () -> Void

    @State private var confirmRemove = false

    private var collection: RareCollection {
        ListeningCatalog.rare(id: collectionId) ?? ListeningCatalog.abdulAzimZaher
    }

    private var downloadedCount: Int {
        audioStore.downloadedRare[collection.id]?.count ?? 0
    }

    private var isDownloadingAll: Bool {
        audioStore.batchDownloadingSourceId == collection.id
    }

    var body: some View {
        let name = collection.localizedName(language: theme.language)
        let playingHere = audioStore.currentListeningTrack?.sourceId == collection.id
        let isPlayingThis = playingHere && audioStore.listeningIsPlaying

        ScrollView {
            VStack(spacing: 14) {
                VStack(spacing: 10) {
                    ReciterAvatarView(
                        reciterId: collection.id,
                        name: name,
                        photoAsset: collection.photoAsset,
                        size: 92,
                        isSelected: playingHere,
                        isPlaying: isPlayingThis
                    )
                    Text(name)
                        .font(theme.scaledFont(size: 21, weight: .black))
                        .foregroundStyle(theme.onSurface)
                        .multilineTextAlignment(.center)
                    Text(theme.t("listen_selected_bio"))
                        .font(theme.scaledFont(size: 13))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                .padding(.top, 8)

                HStack(spacing: 10) {
                    Button {
                        if playingHere {
                            audioStore.toggleListeningPlayPause()
                        } else {
                            audioStore.playRare(collection.id, trackIndex: 0, surahs: appState.quranStore.surahs, language: theme.language)
                            onOpenPlayer()
                        }
                    } label: {
                        Label(theme.t(isPlayingThis ? "pause" : "play"), systemImage: isPlayingThis ? "pause.fill" : "play.fill")
                            .font(theme.scaledFont(size: 14, weight: .bold))
                            .foregroundStyle(theme.onPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(theme.primary, in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        audioStore.playRare(collection.id, shuffle: true, surahs: appState.quranStore.surahs, language: theme.language)
                        onOpenPlayer()
                    } label: {
                        Label(theme.t("listen_shuffle"), systemImage: "shuffle")
                            .font(theme.scaledFont(size: 14, weight: .bold))
                            .foregroundStyle(theme.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(theme.primary.opacity(0.13), in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        if isDownloadingAll {
                            audioStore.stopDownloads()
                        } else if downloadedCount < collection.tracks.count {
                            audioStore.downloadAllRare(collection)
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(downloadedCount >= collection.tracks.count ? theme.primary.opacity(0.16) : theme.surfaceVariant.opacity(0.7))
                                .frame(width: 46, height: 46)
                            Image(systemName: isDownloadingAll ? "stop.fill" : (downloadedCount >= collection.tracks.count ? "checkmark.icloud.fill" : "icloud.and.arrow.down"))
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(theme.primary)
                        }
                    }
                    .buttonStyle(.plain)
                }

                if isDownloadingAll {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(theme.t("listen_downloading_progress", theme.digits(String(downloadedCount)), theme.digits(String(collection.tracks.count))))
                            .font(theme.scaledFont(size: 12, weight: .bold))
                            .foregroundStyle(theme.primary)
                        ProgressView(value: Double(downloadedCount), total: Double(max(1, collection.tracks.count)))
                            .tint(theme.primary)
                    }
                }

                LazyVStack(spacing: 8) {
                    ForEach(Array(collection.tracks.enumerated()), id: \.element.id) { idx, track in
                        rareTrackRow(track: track, index: idx)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 128)
        }
        .scrollIndicators(.hidden)
        .background(Color.clear)
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(theme.t("listen_remove_downloads"), role: .destructive) {
                        confirmRemove = true
                    }
                    .disabled(downloadedCount == 0)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(theme.onSurface)
                }
            }
        }
        .alert(theme.t("listen_remove_title", name), isPresented: $confirmRemove) {
            Button(theme.t("listen_remove_confirm"), role: .destructive) {
                audioStore.removeDownloads(forCollection: collection)
            }
            Button(theme.t("listen_cancel"), role: .cancel) {}
        } message: {
            Text(theme.t("listen_remove_rare_body"))
        }
    }

    private func rareTrackRow(track: RareTrack, index: Int) -> some View {
        let isCurrent = audioStore.currentListeningTrack?.id == track.id
        let isPlaying = isCurrent && audioStore.listeningIsPlaying
        let isDownloaded = audioStore.isRareDownloaded(collectionId: collection.id, fileName: track.fileName)
        let dlKey = audioStore.downloadKey(rare: track)
        let isDownloading = audioStore.activeDownloads[dlKey] != nil
        let title = ListenTitles.rare(track, surahs: appState.quranStore.surahs, language: theme.language)
        let durMin = max(1, track.durationSec / 60)

        return HStack(spacing: 12) {
            Button {
                if isCurrent {
                    audioStore.toggleListeningPlayPause()
                } else {
                    audioStore.playRare(collection.id, trackIndex: index, surahs: appState.quranStore.surahs, language: theme.language)
                    onOpenPlayer()
                }
            } label: {
                HStack(spacing: 12) {
                    NumberStar(text: theme.digits(String(track.surahs.first ?? (index + 1))), size: 40)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(theme.scaledFont(size: 14.5, weight: .bold))
                            .foregroundStyle(isCurrent ? theme.primary : theme.onSurface)
                            .lineLimit(2)
                        HStack(spacing: 6) {
                            Text(theme.t(track.isWholeSurah ? "listen_rare_whole_badge" : "listen_rare_badge"))
                                .font(theme.scaledFont(size: 10.5, weight: .semibold))
                                .foregroundStyle(theme.primary)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(theme.primary.opacity(0.11), in: Capsule())
                            Text(theme.t("listen_duration_m", theme.digits(String(durMin))))
                                .font(theme.scaledFont(size: 11.5))
                                .foregroundStyle(theme.onSurfaceVariant)
                        }
                    }
                    Spacer()
                    if isPlaying {
                        SirajEqualizerBars(isPlaying: true)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                if isDownloading {
                    audioStore.stopDownload(key: dlKey)
                } else if !isDownloaded {
                    audioStore.downloadRareTrack(track)
                }
            } label: {
                if isDownloading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(theme.primary)
                        .frame(width: 34, height: 34)
                } else {
                    Image(systemName: isDownloaded ? "checkmark.circle.fill" : "arrow.down.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(isDownloaded ? theme.primary : theme.onSurfaceVariant)
                        .frame(width: 34, height: 34)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .sirajCardSurface(cornerRadius: 16)
    }
}
