import SwiftUI
import SirajCore

struct QuranSetupView: View {
    @Environment(\.sirajTheme) private var theme
    let quranStore: QuranStore
    let appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Spacer().frame(height: 18)

                ZStack {
                    Circle()
                        .fill(theme.primary.opacity(0.14))
                        .frame(width: 96, height: 96)
                    Image("ic_nav_quran_filled")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .foregroundStyle(theme.primary)
                }

                VStack(spacing: 8) {
                    Text(theme.t("setup_title"))
                        .font(theme.scaledFont(size: 24, weight: .black))
                        .foregroundStyle(theme.onSurface)

                    Text(theme.t("setup_body"))
                        .font(theme.scaledFont(size: 14))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 320)
                }

                VStack(spacing: 14) {
                    switch quranStore.assetState {
                    case .checking:
                        ProgressView()
                            .tint(theme.primary)
                            .padding(.vertical, 16)

                    case .needsDownload:
                        VStack(spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "wifi")
                                    .font(.system(size: 17))
                                    .foregroundStyle(theme.primary)
                                Text(theme.t("rdl_large_download_note"))
                                    .font(theme.scaledFont(size: 13))
                                    .foregroundStyle(theme.onSurfaceVariant)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(14)
                            .background(theme.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                            Button {
                                quranStore.startInstall(includePageFonts: true)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "icloud.and.arrow.down.fill")
                                    Text(theme.t("tfs_action_download"))
                                        .font(theme.scaledFont(size: 15, weight: .bold))
                                }
                                .foregroundStyle(theme.onPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(theme.primary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }

                    case .downloading(let stage, let progress, let received, let total):
                        progressCard(
                            title: stage == .database ? theme.t("setup_title") : theme.t("mushaf_name_madinah_v1"),
                            detail: theme.t("setup_progress_bytes", formatMB(received), formatMB(total)),
                            progress: progress,
                            showCancel: true
                        )

                    case .unpacking(let stage, let progress):
                        progressCard(
                            title: stage == .database ? theme.t("setup_title") : theme.t("mushaf_name_madinah_v1"),
                            detail: "\(theme.digits(String(Int((progress * 100).rounded()))))%",
                            progress: progress,
                            showCancel: false
                        )

                    case .failed:
                        VStack(spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(theme.error)
                                Text(theme.t("setup_failed_body"))
                                    .font(theme.scaledFont(size: 13))
                                    .foregroundStyle(theme.onSurface)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(14)
                            .background(theme.error.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                            Button {
                                quranStore.startInstall(includePageFonts: true)
                            } label: {
                                Text(theme.t("setup_retry"))
                                    .font(theme.scaledFont(size: 15, weight: .bold))
                                    .foregroundStyle(theme.onPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(theme.primary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }

                    case .ready:
                        EmptyView()
                    }
                }
                .padding(18)
                .sirajCardSurface(cornerRadius: 24)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
    }

    private func progressCard(title: String, detail: String, progress: Double, showCancel: Bool) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text(title)
                    .font(theme.scaledFont(size: 14, weight: .bold))
                    .foregroundStyle(theme.onSurface)
                Spacer()
                Text(detail)
                    .font(theme.scaledFont(size: 12.5, weight: .semibold))
                    .foregroundStyle(theme.primary)
            }
            ProgressView(value: progress, total: 1.0)
                .tint(theme.primary)
            if showCancel {
                Button(theme.t("settings_cancel")) {
                    quranStore.cancelInstall()
                }
                .font(theme.scaledFont(size: 13.5, weight: .semibold))
                .foregroundStyle(theme.onSurfaceVariant)
                .padding(.top, 2)
            }
        }
    }

    private func formatMB(_ bytes: Int64) -> String {
        let mb = Double(max(0, bytes)) / (1024.0 * 1024.0)
        return String(format: "%.1f MB", mb)
    }
}
