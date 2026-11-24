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

    var outlineAssetName: String? {
        switch self {
        case .prayer: return "ic_nav_prayer"
        case .quran: return "ic_nav_quran"
        case .qibla: return "ic_nav_qibla"
        case .azkar: return "ic_nav_azkar"
        case .settings: return nil
        }
    }

    var filledAssetName: String? {
        switch self {
        case .prayer: return "ic_nav_prayer_filled"
        case .quran: return "ic_nav_quran_filled"
        case .qibla: return "ic_nav_qibla_filled"
        case .azkar: return "ic_nav_azkar_filled"
        case .settings: return nil
        }
    }
}

struct FloatingTabBar: View {
    @Environment(\.sirajTheme) private var theme
    @Binding var selectedTab: SirajTab
    var isCollapsed: Bool = false
    @Namespace private var pillNamespace

    var body: some View {
        let collapsed = theme.settings.isNavAlwaysCompact || (theme.settings.isNavShrinkEnabled && isCollapsed)
        let isRoundedStyle = theme.settings.navBarStyle == .rounded
        let dockHeight: CGFloat = collapsed ? 52 : 68
        let horizontalInset: CGFloat = collapsed ? 56 : 12
        let cornerRadius: CGFloat = isRoundedStyle ? (collapsed ? 18 : 22) : dockHeight / 2
        let pillWidth: CGFloat = collapsed ? 44 : 64
        let pillHeight: CGFloat = collapsed ? 36 : 32
        let pillCorner: CGFloat = isRoundedStyle ? (collapsed ? 11 : 12) : pillHeight / 2
        let dockShape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let pillShape = RoundedRectangle(cornerRadius: pillCorner, style: .continuous)

        let selectedColor = theme.primary
        let idleColor = theme.onSurfaceVariant.opacity(theme.isDark ? 0.85 : 0.78)
        let pillFillColor = theme.isGlass
            ? theme.primary.opacity(theme.isDark ? 0.28 : 0.18)
            : (theme.isDark ? theme.primary.opacity(0.20) : theme.primary.opacity(0.12))

        ZStack(alignment: .bottom) {
            if !theme.isLiveBackground {
                LinearGradient(
                    stops: [
                        .init(color: theme.background.opacity(0.0), location: 0.0),
                        .init(color: theme.background.opacity(0.78), location: 0.45),
                        .init(color: theme.background.opacity(0.96), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: dockHeight + 30)
                .allowsHitTesting(false)
            }

            HStack(spacing: 0) {
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
                        VStack(spacing: collapsed ? 0 : 2) {
                            ZStack {
                                if isSelected {
                                    activePill(
                                        shape: pillShape,
                                        fill: pillFillColor,
                                        accent: selectedColor
                                    )
                                    .frame(width: pillWidth, height: pillHeight)
                                    .matchedGeometryEffect(id: "active_tab_pill", in: pillNamespace)
                                }
                                tabIcon(for: tab, selected: isSelected)
                                    .frame(width: 24, height: 24)
                                    .foregroundStyle(isSelected ? selectedColor : idleColor)
                            }
                            .frame(width: pillWidth, height: pillHeight)

                            if !collapsed {
                                Text(theme.t(tab.titleKey))
                                    .font(.system(size: min(11 * theme.textScale, 13.2), weight: isSelected ? .bold : .medium))
                                    .foregroundStyle(isSelected ? selectedColor : idleColor)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("tab_\(tab.titleKey)")
                }
            }
            .padding(.horizontal, isRoundedStyle ? 6 : 4)
            .frame(height: dockHeight)
            .background {
                if theme.isGlass {
                    let spec = SirajGlassSpec.resolve(theme: theme)
                    ZStack {
                        if spec.usesMaterial {
                            dockShape.fill(theme.glassFinish == .frosted ? .regularMaterial : .ultraThinMaterial)
                        }
                        dockShape.fill(spec.elevatedTint)
                        dockShape.fill(
                            LinearGradient(
                                colors: [spec.innerSheen, .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                    }
                } else {
                    dockShape.fill(theme.isBlack ? Color(argbHex: 0xFF101014) : theme.surfaceContainerHigh)
                }
            }
            .overlay {
                dockShape.strokeBorder(
                    LinearGradient(
                        colors: theme.isGlass
                            ? [Color.white.opacity(theme.isDark ? 0.36 : 0.82), theme.primary.opacity(0.28)]
                            : [theme.gold.opacity(theme.isDark ? 0.36 : 0.42), theme.outlineVariant.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.0
                )
            }
            .shadow(color: Color.black.opacity(theme.isDark ? 0.44 : 0.14), radius: 14, x: 0, y: 6)
            .padding(.horizontal, horizontalInset)
            .padding(.bottom, 8)
            .animation(theme.motionEnabled ? .spring(response: 0.32, dampingFraction: 0.82) : nil, value: collapsed)
        }
    }

    @ViewBuilder
    private func activePill(shape: RoundedRectangle, fill: Color, accent: Color) -> some View {
        if theme.isGlass {
            shape
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.28), location: 0.0),
                            .init(color: fill, location: 0.45),
                            .init(color: accent.opacity(0.24), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    shape.strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.56), location: 0.0),
                                .init(color: Color.white.opacity(0.14), location: 0.52),
                                .init(color: accent.opacity(0.36), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.05
                    )
                }
        } else {
            shape
                .fill(fill)
                .overlay {
                    shape.strokeBorder(accent.opacity(0.20), lineWidth: 1.0)
                }
        }
    }

    @ViewBuilder
    private func tabIcon(for tab: SirajTab, selected: Bool) -> some View {
        if let name = selected ? tab.filledAssetName : tab.outlineAssetName {
            Image(name)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: selected ? "gearshape.fill" : "gearshape")
                .font(.system(size: 20, weight: selected ? .semibold : .regular))
        }
    }
}

struct ScrollCollapseTracker: ViewModifier {
    let onDelta: (CGFloat) -> Void
    @State private var lastY: CGFloat?

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y
            } action: { oldY, newY in
                if newY <= 8 {
                    onDelta(-100)
                    lastY = newY
                    return
                }
                let prev = lastY ?? oldY
                let delta = newY - prev
                if abs(delta) > 18 {
                    onDelta(delta)
                    lastY = newY
                }
            }
        } else {
            content
        }
    }
}

extension View {
    func scrollCollapseTracker(enabled: Bool, isCollapsed: Binding<Bool>) -> some View {
        modifier(
            ScrollCollapseTracker { delta in
                guard enabled else {
                    if isCollapsed.wrappedValue { isCollapsed.wrappedValue = false }
                    return
                }
                if delta > 0 && !isCollapsed.wrappedValue {
                    isCollapsed.wrappedValue = true
                } else if delta < 0 && isCollapsed.wrappedValue {
                    isCollapsed.wrappedValue = false
                }
            }
        )
    }
}
