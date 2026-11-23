import SwiftUI
import SirajCore

public struct LiveThemeBackdrop: View {
    @Environment(\.sirajTheme) private var theme
    @Environment(\.scenePhase) private var scenePhase

    let themeId: String
    let intensity: LiveBackgroundIntensity
    let activePrayer: PrayerType?

    public init(themeId: String, intensity: LiveBackgroundIntensity, activePrayer: PrayerType? = nil) {
        self.themeId = themeId
        self.intensity = intensity
        self.activePrayer = activePrayer
    }

    public var body: some View {
        let def = LiveThemeCatalog.definition(for: themeId)
        let palette = theme.isBlack ? def.amoled : (theme.isDark ? def.dark : def.light)
        let paused = !theme.motionEnabled || scenePhase != .active

        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: paused)) { timeline in
            let t = paused ? 12.0 : timeline.date.timeIntervalSinceReferenceDate * intensity.motionScale
            Canvas { ctx, size in
                drawBaseGradient(ctx: &ctx, size: size, palette: palette)
                drawScene(ctx: &ctx, size: size, id: def.id, palette: palette, t: t, alphaScale: intensity.detailAlphaScale)
                drawVeil(ctx: &ctx, size: size, palette: palette)
            }
        }
    }

    private func drawBaseGradient(ctx: inout GraphicsContext, size: CGSize, palette: LiveSceneColors) {
        let rect = CGRect(origin: .zero, size: size)
        let grad = Gradient(colors: [
            Color(argbHex: palette.skyTop),
            Color(argbHex: palette.skyUpperMid),
            Color(argbHex: palette.skyLowerMid),
            Color(argbHex: palette.skyHorizon)
        ])
        ctx.fill(Path(rect), with: .linearGradient(grad, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
    }

    private func drawVeil(ctx: inout GraphicsContext, size: CGSize, palette: LiveSceneColors) {
        let baseOpacity = theme.isBlack ? 0.20 : (theme.isDark ? 0.16 : 0.18)
        let veilOpacity = min(0.45, max(0.04, baseOpacity + intensity.veilAdjustment))
        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(argbHex: palette.veilColor).opacity(veilOpacity)))
    }

    private func drawScene(
        ctx: inout GraphicsContext,
        size: CGSize,
        id: String,
        palette: LiveSceneColors,
        t: Double,
        alphaScale: Double
    ) {
        switch id {
        case "DesertDunes":
            LiveScenesNature.drawDesertDunes(ctx: &ctx, size: size, palette: palette, t: t, alpha: alphaScale)
        case "SeaWaves":
            LiveScenesNature.drawSeaWaves(ctx: &ctx, size: size, palette: palette, t: t, alpha: alphaScale)
        case "Aurora":
            LiveScenesNature.drawAurora(ctx: &ctx, size: size, palette: palette, t: t, alpha: alphaScale)
        case "NightStars":
            LiveScenesNature.drawNightStars(ctx: &ctx, size: size, palette: palette, t: t, alpha: alphaScale)
        case "RosePetals":
            LiveScenesNature.drawRosePetals(ctx: &ctx, size: size, palette: palette, t: t, alpha: alphaScale)
        case "Snow":
            LiveScenesNature.drawSnow(ctx: &ctx, size: size, palette: palette, t: t, alpha: alphaScale)
        case "PurpleButterflies":
            LiveScenesNature.drawButterflies(ctx: &ctx, size: size, palette: palette, t: t, alpha: alphaScale)
        case "Rings":
            LiveScenesAmbient.drawRings(ctx: &ctx, size: size, palette: palette, t: t, alpha: alphaScale)
        case "Circles":
            LiveScenesAmbient.drawCircles(ctx: &ctx, size: size, palette: palette, t: t, alpha: alphaScale)
        case "Particles":
            LiveScenesAmbient.drawParticles(ctx: &ctx, size: size, palette: palette, t: t, alpha: alphaScale)
        case "LavaLamp":
            LiveScenesAmbient.drawLavaLamp(ctx: &ctx, size: size, palette: palette, t: t, alpha: alphaScale)
        case "Space":
            LiveScenesAmbient.drawSpace(ctx: &ctx, size: size, palette: palette, t: t, alpha: alphaScale)
        case "Silk":
            LiveScenesStudio.drawSilk(ctx: &ctx, size: size, palette: palette, t: t, alpha: alphaScale)
        case "Contours":
            LiveScenesStudio.drawContours(ctx: &ctx, size: size, palette: palette, t: t, alpha: alphaScale)
        case "Mosaic":
            LiveScenesStudio.drawMosaic(ctx: &ctx, size: size, palette: palette, t: t, alpha: alphaScale)
        case "Waves":
            LiveScenesStudio.drawWaves(ctx: &ctx, size: size, palette: palette, t: t, alpha: alphaScale)
        case "Harvest":
            LiveScenesStudio.drawHarvest(ctx: &ctx, size: size, palette: palette, t: t, alpha: alphaScale)
        default:
            LiveScenesNature.drawDesertDunes(ctx: &ctx, size: size, palette: palette, t: t, alpha: alphaScale)
        }
    }
}
