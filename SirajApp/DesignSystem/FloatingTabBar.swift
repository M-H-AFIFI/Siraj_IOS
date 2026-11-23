import SwiftUI
import SirajCore

enum SirajTab: Int, CaseIterable, Identifiable, Sendable {
    case prayer = 0
    case quran = 1
    case qibla = 2
    case azkar = 3
    case settings = 4

    var id: Int { rawValue }

    var titleKey: String {
        switch self {
        case .prayer: return "nav_prayer"
        case .quran: return "nav_quran"
        case .qibla: return "nav_qibla"
        case .azkar: return "nav_azkar"
        case .settings: return "nav_settings"
        }
    }

    var customAssetName: String? {
        switch self {
        case .prayer: return "ic_nav_prayer"
        case .quran: return "ic_nav_quran"
        case .qibla: return "ic_nav_qibla"
        case .azkar: return "ic_nav_azkar"
        case .settings: return nil
        }
    }
}

struct FloatingTabBar: View {
    @Environment(\.sirajTheme) private var theme
    @Binding var selectedTab: SirajTab
    var isCompact: Bool = false
    @Namespace private var pillNamespace

    var body: some View {
        let compact = isCompact || theme.settings.isNavAlwaysCompact || theme.settings.navBarStyle == .compact
        let capsule = Capsule()

        HStack(spacing: 4) {
            ForEach(SirajTab.allCases) { tab in
                let isSelected = selectedTab == tab
                Button {
                    if theme.settings.isHapticEnabled {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    if theme.motionEnabled {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                            selectedTab = tab
                        }
                    } else {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: compact ? 0 : 4) {
                        ZStack {
                            if isSelected {
                                Capsule()
                                    .fill(theme.primary.opacity(theme.isDark ? 0.24 : 0.16))
                                    .frame(width: 56, height: 32)
                                    .matchedGeometryEffect(id: "active_tab_pill", in: pillNamespace)
                            }
                            tabIcon(for: tab, selected: isSelected)
                                .frame(width: 22, height: 22)
                                .foregroundStyle(isSelected ? theme.primary : theme.onSurfaceVariant)
                        }
                        .frame(height: 32)

                        if !compact {
                            Text(theme.t(tab.titleKey))
                                .font(.system(size: min(11 * theme.textScale, 14), weight: isSelected ? .bold : .medium))
                                .foregroundStyle(isSelected ? theme.primary : theme.onSurfaceVariant)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, compact ? 8 : 7)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("tab_\(tab.titleKey)")
            }
        }
        .padding(.horizontal, 10)
        .background {
            if theme.isGlass {
                let spec = SirajGlassSpec.resolve(theme: theme)
                ZStack {
                    if spec.usesMaterial {
                        capsule.fill(.ultraThinMaterial)
                    }
                    capsule.fill(spec.pillTint)
                }
            } else {
                capsule.fill(theme.isBlack ? Color(argbHex: 0xFF101014) : theme.surface)
            }
        }
        .overlay {
            capsule.strokeBorder(
                LinearGradient(
                    colors: [theme.gold.opacity(0.45), theme.primary.opacity(0.35)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.0
            )
        }
        .shadow(color: Color.black.opacity(theme.isDark ? 0.45 : 0.14), radius: 16, x: 0, y: 8)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func tabIcon(for tab: SirajTab, selected: Bool) -> some View {
        if let asset = tab.customAssetName {
            Image(asset)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: selected ? "gearshape.fill" : "gearshape")
                .font(.system(size: 19, weight: selected ? .semibold : .regular))
        }
    }
}
