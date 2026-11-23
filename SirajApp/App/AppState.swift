import Foundation
import Observation
import WidgetKit
import SirajCore

@MainActor
@Observable
public final class AppState {
    public let store: UserDataStore
    public let localizer: SirajLocalizer
    public var settings: SettingsSnapshot
    public var onboardingComplete: Bool
    public var selectedTab: SirajTab = .prayer
    public var pinnedSkyTime: Date?
    public var activeAdhanAlert: PrayerType?
    public var requestedRoute: String?
    public var prayerDay: PrayerDay
    public var hijriDate: HijriDate
    public var upcomingOccasions: [DatedOccasion]
    public var isUITesting: Bool = false

    public var onSettingsChangedForAlerts: ((SettingsSnapshot, Place) -> Void)?

    public init(store: UserDataStore? = nil, localizer: SirajLocalizer? = nil) {
        let appGroup = Bundle.main.object(forInfoDictionaryKey: "SirajAppGroupID") as? String
        let resolvedStore = store ?? UserDataStore(appGroupId: appGroup)
        let resolvedLoc = localizer ?? SirajLocalizer(bundle: .main, subdirectory: "Data")

        self.store = resolvedStore
        self.localizer = resolvedLoc

        let loadedSettings = resolvedStore.loadSettings()
        self.settings = loadedSettings
        self.onboardingComplete = resolvedStore.loadOnboardingComplete()

        let now = Date()
        let place = loadedSettings.cachedLocation ?? .cairoDefault
        let day = PrayerCalculator.today(place: place, settings: loadedSettings.calculationSettings, now: now)
        let hijriCal = SirajHijriCalendar.forSettings(
            method: loadedSettings.hijriMethod,
            countryCode: place.resolvedCountryCode,
            adjustment: loadedSettings.hijriAdjustment
        )
        let todayCivil = place.today(at: now)
        self.prayerDay = day
        self.hijriDate = hijriCal.toHijri(todayCivil)
        self.upcomingOccasions = IslamicOccasions.upcoming(from: todayCivil, calendar: hijriCal)

        applyLaunchArguments(ProcessInfo.processInfo.arguments)
    }

    public var currentTime: Date {
        pinnedSkyTime ?? Date()
    }

    public var activePlace: Place {
        settings.cachedLocation ?? .cairoDefault
    }

    public var hijriCalendar: SirajHijriCalendar {
        SirajHijriCalendar.forSettings(
            method: settings.hijriMethod,
            countryCode: activePlace.resolvedCountryCode,
            adjustment: settings.hijriAdjustment
        )
    }

    public func updateSettings(_ mutate: (inout SettingsSnapshot) -> Void) {
        var copy = settings
        mutate(&copy)
        settings = copy
        if !isUITesting {
            store.saveSettings(copy)
        }
        refreshPrayers()
        WidgetCenter.shared.reloadAllTimelines()
        onSettingsChangedForAlerts?(copy, activePlace)
    }

    public func completeOnboarding() {
        onboardingComplete = true
        if !isUITesting {
            store.saveOnboardingComplete(true)
            store.saveSettings(settings)
        }
        refreshPrayers()
        WidgetCenter.shared.reloadAllTimelines()
        onSettingsChangedForAlerts?(settings, activePlace)
    }

    public func refreshPrayers() {
        let now = currentTime
        let place = activePlace
        prayerDay = PrayerCalculator.today(place: place, settings: settings.calculationSettings, now: now)
        let cal = hijriCalendar
        let civil = place.today(at: now)
        hijriDate = cal.toHijri(civil)
        upcomingOccasions = IslamicOccasions.upcoming(from: civil, calendar: cal)
    }

    public func applyLaunchArguments(_ args: [String]) {
        guard args.contains("--uitesting") else { return }
        isUITesting = true
        var snap = SettingsSnapshot()
        snap.cachedLocation = .cairoDefault
        snap.calculationMethod = "Egyptian"
        snap.madhab = "Shafi"
        snap.isReduceMotionEnabled = true

        onboardingComplete = args.contains("--skip-onboarding")

        for arg in args {
            if arg.hasPrefix("--sky-time=") {
                let raw = String(arg.dropFirst("--sky-time=".count))
                let iso = ISO8601DateFormatter()
                iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let parsed = iso.date(from: raw) ?? ISO8601DateFormatter().date(from: raw)
                if let parsed { pinnedSkyTime = parsed }
            } else if arg.hasPrefix("--locale=") {
                snap.language = String(arg.dropFirst("--locale=".count))
            } else if arg.hasPrefix("--theme=") {
                switch String(arg.dropFirst("--theme=".count)).lowercased() {
                case "light":
                    snap.themeMode = .light
                    snap.isAmoled = false
                case "dark":
                    snap.themeMode = .dark
                    snap.isAmoled = false
                case "black", "amoled":
                    snap.themeMode = .dark
                    snap.isAmoled = true
                default:
                    snap.themeMode = .system
                }
            } else if arg.hasPrefix("--palette=") {
                snap.themePalette = SirajPalettes.canonicalId(String(arg.dropFirst("--palette=".count)))
            } else if arg == "--glass" {
                snap.isGlassUi = true
                snap.glassFinish = .clear
            } else if arg.hasPrefix("--live-theme=") {
                snap.isLiveBackgroundEnabled = true
                snap.liveTheme = String(arg.dropFirst("--live-theme=".count))
            } else if arg.hasPrefix("--show-adhan-alert=") {
                let raw = String(arg.dropFirst("--show-adhan-alert=".count)).uppercased()
                activeAdhanAlert = PrayerType(rawValue: raw) ?? .fajr
            } else if arg.hasPrefix("--open-route=") {
                requestedRoute = String(arg.dropFirst("--open-route=".count)).lowercased()
                selectedTab = .settings
            }
        }

        settings = snap
        refreshPrayers()
    }
}
