import SwiftUI
import SirajCore

struct SirajGlassSpec {
    let cardTint: Color
    let elevatedTint: Color
    let pillTint: Color
    let topRim: Color
    let bottomRim: Color
    let innerSheen: Color
    let ambientPrimary: Color
    let ambientSecondary: Color
    let dropShadow: Color
    let usesMaterial: Bool

    static func resolve(theme: SirajResolvedTheme) -> SirajGlassSpec {
        let finish = theme.glassFinish
        let isDark = theme.isDark
        let isBlack = theme.isBlack
        let perf = theme.settings.isGlassPerformanceMode

        func pick(_ clear: Double, _ satin: Double, _ frosted: Double) -> Double {
            switch finish {
            case .clear: return clear
            case .satin: return satin
            case .frosted: return frosted
            }
        }

        if isBlack {
            return SirajGlassSpec(
                cardTint: Color.white.opacity(pick(0.065, 0.085, 0.105)),
                elevatedTint: Color(argbHex: 0xFF141824).opacity(pick(0.76, 0.82, 0.88)),
                pillTint: Color(argbHex: 0xFF181D29).opacity(pick(0.68, 0.76, 0.84)),
                topRim: Color.white.opacity(pick(0.42, 0.34, 0.24)),
                bottomRim: theme.primary.opacity(pick(0.28, 0.22, 0.16)),
                innerSheen: Color.white.opacity(pick(0.14, 0.11, 0.07)),
                ambientPrimary: theme.primary.opacity(0.16),
                ambientSecondary: theme.gold.opacity(0.10),
                dropShadow: Color.black.opacity(0.55),
                usesMaterial: !perf
            )
        } else if isDark {
            return SirajGlassSpec(
                cardTint: Color.white.opacity(pick(0.08, 0.10, 0.13)),
                elevatedTint: theme.surface.opacity(pick(0.72, 0.80, 0.86)),
                pillTint: theme.surfaceVariant.opacity(pick(0.68, 0.76, 0.84)),
                topRim: Color.white.opacity(pick(0.38, 0.30, 0.22)),
                bottomRim: theme.primary.opacity(pick(0.26, 0.20, 0.15)),
                innerSheen: Color.white.opacity(pick(0.13, 0.10, 0.06)),
                ambientPrimary: theme.primary.opacity(0.22),
                ambientSecondary: theme.secondary.opacity(0.16),
                dropShadow: Color.black.opacity(0.42),
                usesMaterial: !perf
            )
        } else {
            return SirajGlassSpec(
                cardTint: Color.white.opacity(pick(0.54, 0.66, 0.78)),
                elevatedTint: Color.white.opacity(pick(0.72, 0.82, 0.90)),
                pillTint: Color.white.opacity(pick(0.66, 0.76, 0.86)),
                topRim: Color.white.opacity(pick(0.92, 0.82, 0.70)),
                bottomRim: theme.primary.opacity(pick(0.22, 0.18, 0.14)),
                innerSheen: Color.white.opacity(pick(0.48, 0.36, 0.24)),
                ambientPrimary: theme.primary.opacity(0.18),
                ambientSecondary: theme.gold.opacity(0.14),
                dropShadow: Color.black.opacity(0.10),
                usesMaterial: !perf
            )
        }
    }
}

struct SirajCardSurfaceModifier: ViewModifier {
    @Environment(\.sirajTheme) private var theme
    let cornerRadius: CGFloat
    let isElevated: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if theme.isGlass {
            let spec = SirajGlassSpec.resolve(theme: theme)
            content
                .background {
                    ZStack {
                        if spec.usesMaterial {
                            shape.fill(theme.glassFinish == .frosted ? .regularMaterial : .ultraThinMaterial)
                        }
                        shape.fill(isElevated ? spec.elevatedTint : spec.cardTint)
                        shape.fill(
                            LinearGradient(
                                colors: [spec.innerSheen, .clear],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                    }
                }
                .overlay {
                    shape.strokeBorder(
                        LinearGradient(
                            colors: [spec.topRim, spec.bottomRim],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
                }
                .shadow(color: spec.dropShadow, radius: isElevated ? 16 : 10, x: 0, y: isElevated ? 8 : 4)
        } else if theme.isLiveBackground {
            let fillAlpha: Double = theme.isBlack ? 0.72 : (theme.isDark ? 0.76 : 0.82)
            content
                .background {
                    shape.fill(.ultraThinMaterial)
                        .overlay(shape.fill(theme.surface.opacity(fillAlpha)))
                }
                .overlay {
                    shape.strokeBorder(theme.outlineVariant.opacity(0.55), lineWidth: 1)
                }
        } else {
            content
                .background(shape.fill(isElevated ? theme.surfaceContainerHigh : theme.surface))
                .overlay {
                    shape.strokeBorder(theme.outlineVariant.opacity(theme.isDark ? 0.45 : 0.55), lineWidth: 1)
                }
                .shadow(
                    color: Color.black.opacity(theme.isDark ? 0.24 : 0.05),
                    radius: isElevated ? 12 : 6,
                    x: 0,
                    y: isElevated ? 5 : 2
                )
        }
    }
}

extension View {
    func sirajCardSurface(cornerRadius: CGFloat = 24, isElevated: Bool = false) -> some View {
        modifier(SirajCardSurfaceModifier(cornerRadius: cornerRadius, isElevated: isElevated))
    }
}

struct SirajRootBackdrop: View {
    @Environment(\.sirajTheme) private var theme
    var activePrayer: PrayerType? = nil

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            if theme.isLiveBackground {
                LiveThemeBackdrop(
                    themeId: theme.settings.liveTheme,
                    intensity: theme.settings.liveBackgroundIntensity,
                    isTimeSyncEnabled: theme.settings.isWeatherBackgroundEnabled,
                    activePrayer: activePrayer
                )
                .ignoresSafeArea()
            } else if theme.isGlass {
                glassAmbientBackdrop
                    .ignoresSafeArea()
            }
        }
    }

    private var glassAmbientBackdrop: some View {
        let spec = SirajGlassSpec.resolve(theme: theme)
        return GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                RadialGradient(
                    colors: [spec.ambientPrimary, .clear],
                    center: .topLeading,
                    startRadius: 20,
                    endRadius: max(w, h) * 0.75
                )
                RadialGradient(
                    colors: [spec.ambientSecondary, .clear],
                    center: .bottomTrailing,
                    startRadius: 20,
                    endRadius: max(w, h) * 0.7
                )
                if theme.settings.isGlassMesh || theme.glassFinish == .frosted {
                    RadialGradient(
                        colors: [theme.primaryContainer.opacity(theme.isDark ? 0.16 : 0.24), .clear],
                        center: UnitPoint(x: 0.75, y: 0.3),
                        startRadius: 10,
                        endRadius: w * 0.65
                    )
                }
            }
        }
    }
}
