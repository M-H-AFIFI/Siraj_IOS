import SwiftUI
import SirajCore

struct AboutSirajView: View {
    @Environment(\.sirajTheme) private var theme

    private var versionString: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        return theme.tf("about_version", theme.digits(short))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(theme.primary.opacity(0.14))
                            .frame(width: 96, height: 96)
                        SirajEmblemMark(height: 62, tint: theme.gold)
                    }

                    Text(theme.t("app_name"))
                        .font(theme.scaledFont(size: 26, weight: .black))
                        .foregroundStyle(theme.onSurface)

                    Text(versionString)
                        .font(theme.scaledFont(size: 13, weight: .semibold))
                        .foregroundStyle(theme.primary)

                    Text(theme.t("about_siraj_badge"))
                        .font(theme.scaledFont(size: 12.5))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(theme.surfaceVariant))
                }
                .frame(maxWidth: .infinity)
                .padding(22)
                .sirajCardSurface(cornerRadius: 24)

                SirajSettingsSection(title: theme.t("about_story_title")) {
                    Text(theme.t("about_story_body"))
                        .font(theme.scaledFont(size: 14))
                        .foregroundStyle(theme.onSurface)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }

                VStack(spacing: 12) {
                    pillarCard(icon: "heart.fill", title: theme.t("about_pillar1_title"), desc: theme.t("about_pillar1_desc"))
                    pillarCard(icon: "lock.shield.fill", title: theme.t("about_pillar2_title"), desc: theme.t("about_pillar2_desc"))
                    pillarCard(icon: "checkmark.seal.fill", title: theme.t("about_pillar3_title"), desc: theme.t("about_pillar3_desc"))
                }

                VStack(spacing: 10) {
                    Text(theme.t("about_duaa_text"))
                        .font(theme.scaledFont(size: 13.5))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                }
                .padding(18)
                .frame(maxWidth: .infinity)
                .sirajCardSurface(cornerRadius: 20)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 108)
        }
        .background(Color.clear)
        .navigationTitle(theme.t("about_siraj_screen_title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func pillarCard(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.primary)
                .frame(width: 38, height: 38)
                .background(Circle().fill(theme.primary.opacity(0.12)))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(theme.scaledFont(size: 15, weight: .bold))
                    .foregroundStyle(theme.onSurface)
                Text(desc)
                    .font(theme.scaledFont(size: 13))
                    .foregroundStyle(theme.onSurfaceVariant)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .sirajCardSurface(cornerRadius: 20)
    }
}
