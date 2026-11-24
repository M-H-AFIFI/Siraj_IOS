import Foundation

public struct AdhanSkyAtmosphere: Sendable, Equatable {
    public let skyTheme: SkyColors
    public let isDaytime: Bool
    public let isCrescent: Bool
    public let showStars: Bool
    public let warmth: Double
    public let duskUndersideGlow: Double
    public let sunElevationRatio: Double
    public let starDensity: Double
    public let moteStrength: Double
    public let horizonGlowColor: ArgbColor
    public let horizonGlowAlpha: Double
}

public enum AdhanSkySpec {
    public static func atmosphere(for prayer: PrayerType) -> AdhanSkyAtmosphere {
        switch prayer {
        case .fajr:
            return AdhanSkyAtmosphere(
                skyTheme: SkyPalettes.fajrSubhSadiq,
                isDaytime: false, isCrescent: true, showStars: true,
                warmth: 0.35, duskUndersideGlow: 0.22, sunElevationRatio: 0.0, starDensity: 0.55,
                moteStrength: 0.0,
                horizonGlowColor: .hex(0xFF93B8E8), horizonGlowAlpha: 0.24
            )
        case .sunrise:
            let sky = SkyPalettes.sunriseGolden
            return AdhanSkyAtmosphere(
                skyTheme: sky,
                isDaytime: true, isCrescent: false, showStars: false,
                warmth: 0.86, duskUndersideGlow: 0.65, sunElevationRatio: 0.25, starDensity: 0.0,
                moteStrength: 0.72,
                horizonGlowColor: sky.orbGlow, horizonGlowAlpha: 0.30
            )
        case .dhuhr:
            let sky = SkyPalettes.dhuhrZenith
            return AdhanSkyAtmosphere(
                skyTheme: sky,
                isDaytime: true, isCrescent: false, showStars: false,
                warmth: 0.12, duskUndersideGlow: 0.0, sunElevationRatio: 0.95, starDensity: 0.0,
                moteStrength: 0.28,
                horizonGlowColor: sky.orbGlow, horizonGlowAlpha: 0.16
            )
        case .asr:
            return AdhanSkyAtmosphere(
                skyTheme: SkyPalettes.afternoon,
                isDaytime: true, isCrescent: false, showStars: false,
                warmth: 0.78, duskUndersideGlow: 0.36, sunElevationRatio: 0.48, starDensity: 0.0,
                moteStrength: 0.85,
                horizonGlowColor: .hex(0xFFFFB74D), horizonGlowAlpha: 0.30
            )
        case .maghrib:
            return AdhanSkyAtmosphere(
                skyTheme: SkyPalettes.maghribDusk,
                isDaytime: false, isCrescent: true, showStars: true,
                warmth: 0.92, duskUndersideGlow: 0.86, sunElevationRatio: 0.0, starDensity: 0.42,
                moteStrength: 0.35,
                horizonGlowColor: .hex(0xFFE8743B), horizonGlowAlpha: 0.36
            )
        case .isha:
            return AdhanSkyAtmosphere(
                skyTheme: SkyPalettes.ishaNightfall,
                isDaytime: false, isCrescent: true, showStars: true,
                warmth: 0.0, duskUndersideGlow: 0.0, sunElevationRatio: 0.0, starDensity: 0.88,
                moteStrength: 0.0,
                horizonGlowColor: .hex(0xFF94A3B8), horizonGlowAlpha: 0.12
            )
        }
    }

    public static func colors(for prayer: PrayerType) -> SkyColors {
        atmosphere(for: prayer).skyTheme
    }
}
