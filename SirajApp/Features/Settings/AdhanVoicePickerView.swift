import SwiftUI
import SirajCore

struct AdhanVoicePickerView: View {
    @Environment(\.sirajTheme) private var theme
    let appState: AppState
    let audioEngine: AdhanAudioEngine
    var isFajrMode = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text(theme.t(isFajrMode ? "fajr_adhan_pick_note" : "adhan_voices_note"))
                    .font(theme.scaledFont(size: 13.5))
                    .foregroundStyle(theme.onSurfaceVariant)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)

                if isFajrMode {
                    SirajSettingsSection(title: theme.t("fajr_adhan_title")) {
                        ForEach(Array(AdhanCatalog.fajrRecordings.enumerated()), id: \.element.id) { idx, voice in
                            voiceRow(voice, selected: isFajrSelected(voice)) {
                                selectFajr(voice)
                            }
                            if idx < AdhanCatalog.fajrRecordings.count - 1 {
                                Divider().padding(.leading, 16)
                            }
                        }
                    }
                } else {
                    let mosqueGroups = AdhanCatalog.groups.filter(\.isMosque)
                    let reciterGroups = AdhanCatalog.groups.filter { !$0.isMosque }

                    groupSection(title: theme.t("adhan_voices_mosques"), groups: mosqueGroups)
                    groupSection(title: theme.t("adhan_voices_muezzins"), groups: reciterGroups)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 108)
        }
        .background(Color.clear)
        .navigationTitle(theme.t(isFajrMode ? "fajr_adhan_pick" : "reminders_select_azan_voice"))
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            if !audioEngine.isPlayingFullAdhan {
                audioEngine.stop()
            }
        }
    }

    @ViewBuilder
    private func groupSection(title: String, groups: [AdhanGroup]) -> some View {
        let voices = groups.flatMap { group in
            AdhanCatalog.voices.filter { $0.group == group.key }
        }
        if !voices.isEmpty {
            SirajSettingsSection(title: title) {
                ForEach(Array(voices.enumerated()), id: \.element.id) { idx, voice in
                    let selected = AdhanVoiceResolver.findVoice(appState.settings.azanSound).id == voice.id
                    voiceRow(voice, selected: selected) {
                        selectRegular(voice)
                    }
                    if idx < voices.count - 1 {
                        Divider().padding(.leading, 16)
                    }
                }
            }
        }
    }

    private func isFajrSelected(_ voice: AdhanVoice) -> Bool {
        let resolved = AdhanVoiceResolver.fajrVoice(
            for: appState.settings.azanSound,
            preferredFajrId: appState.settings.fajrAdhanVoice
        )
        return resolved.id == voice.id
    }

    private func selectRegular(_ voice: AdhanVoice) {
        appState.updateSettings { $0.azanSound = voice.id }
        if !audioEngine.isDownloaded(voice) {
            Task {
                await audioEngine.downloadVoice(voice)
                appState.onSettingsChangedForAlerts?(appState.settings, appState.activePlace)
            }
        }
    }

    private func selectFajr(_ voice: AdhanVoice) {
        appState.updateSettings {
            $0.fajrAdhanEnabled = true
            $0.fajrAdhanVoice = voice.id
        }
        if !audioEngine.isDownloaded(voice) {
            Task {
                await audioEngine.downloadVoice(voice)
                appState.onSettingsChangedForAlerts?(appState.settings, appState.activePlace)
            }
        }
    }

    private func voiceRow(_ voice: AdhanVoice, selected: Bool, onSelect: @escaping () -> Void) -> some View {
        let downloaded = audioEngine.isDownloaded(voice)
        let downloading = audioEngine.downloadingVoiceIds.contains(voice.id)
        let failed = audioEngine.failedVoiceIds.contains(voice.id)
        let playing = audioEngine.playingVoiceId == voice.id && !audioEngine.isPlayingFullAdhan
        let sizeMB = max(0.1, Double(voice.estimatedSizeBytes) / 1_048_576.0)
        let sizeLabel = theme.tf("rdl_unit_mb", theme.digits(String(format: "%.1f", sizeMB)))

        return HStack(spacing: 12) {
            Button(action: onSelect) {
                HStack(spacing: 12) {
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 21))
                        .foregroundStyle(selected ? theme.primary : theme.outline)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(voice.localizedTitle(language: theme.language))
                            .font(theme.scaledFont(size: 14.5, weight: selected ? .bold : .semibold))
                            .foregroundStyle(theme.onSurface)
                            .multilineTextAlignment(.leading)

                        HStack(spacing: 6) {
                            if let variant = voice.localizedVariant(language: theme.language), !variant.isEmpty {
                                Text(variant)
                                    .font(theme.scaledFont(size: 11.5))
                                    .foregroundStyle(theme.onSurfaceVariant)
                            }
                            if downloaded {
                                Text(theme.t("adhan_voice_offline"))
                                    .font(theme.scaledFont(size: 11, weight: .semibold))
                                    .foregroundStyle(theme.primary)
                            } else if failed {
                                Text(theme.t("adhan_voice_failed"))
                                    .font(theme.scaledFont(size: 11, weight: .semibold))
                                    .foregroundStyle(.red)
                            } else {
                                Text(sizeLabel)
                                    .font(theme.scaledFont(size: 11))
                                    .foregroundStyle(theme.onSurfaceVariant)
                            }
                        }
                    }
                    Spacer(minLength: 4)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if downloading {
                ProgressView()
                    .frame(width: 34, height: 34)
            } else if !downloaded {
                Button {
                    Task {
                        await audioEngine.downloadVoice(voice)
                        appState.onSettingsChangedForAlerts?(appState.settings, appState.activePlace)
                    }
                } label: {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 22))
                        .foregroundStyle(theme.primary)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
            }

            Button {
                audioEngine.playPreview(voiceId: voice.id, volume: appState.settings.adhanVolume)
            } label: {
                Image(systemName: playing ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(playing ? theme.gold : theme.primary)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
