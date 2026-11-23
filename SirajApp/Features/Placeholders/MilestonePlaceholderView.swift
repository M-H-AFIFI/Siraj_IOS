import SwiftUI
import SirajCore

public struct MilestonePlaceholderView: View {
    @Environment(\.sirajTheme) private var theme
    let iconAsset: String
    let titleKey: String
    let descriptionKey: String

    public init(iconAsset: String, titleKey: String, descriptionKey: String) {
        self.iconAsset = iconAsset
        self.titleKey = titleKey
        self.descriptionKey = descriptionKey
    }

    public var body: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.14))
                    .frame(width: 96, height: 96)
                Image(iconAsset)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .foregroundStyle(theme.primary)
            }
            Text(theme.t(titleKey))
                .font(theme.scaledFont(size: 24, weight: .bold))
                .foregroundStyle(theme.onBackground)
            Text(theme.t(descriptionKey))
                .font(theme.scaledFont(size: 15))
                .foregroundStyle(theme.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Spacer()
        }
        .padding(.bottom, 96)
    }
}
