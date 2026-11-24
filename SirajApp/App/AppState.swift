import Foundation
import Observation
import WidgetKit
import SirajCore

@MainActor
@Observable
final class AppState {
    let store: UserDataStore
    let localizer: SirajLocalizer
    let quranStore: QuranStore
    let audioStore: QuranAudioStore
    let khatmaStore: KhatmaStore
    let worshipStore: WorshipStore
    let radioStore: QuranRadioStore
    let fastingStore: FastingStore
    let guideStore: GuideStore
    var settings: SettingsSnapshot
    var onboardingComplete: Bool
    var selectedTab: SirajTab = .prayer
    var isTabBarCollapsed: Bool = false
    var pinnedSkyTime: Date?
    var activeAdhanAlert: PrayerType?
    var isAdhanAlertTest = false
    var activeReader: ReaderDestination?
    var showListenPlayer = false
    var showRadioPlayer = false
    var requestedRoute: String?
    var requestedQuranRoute: String?
    var requestedWorshipRoute: WorshipRoute?
    var prayerDay: PrayerDay
    var hijriDate: HijriDate
    var upcomingOccasions: [DatedOccasion]
    var isUITesting: Bool = false

    var onSettingsChangedForAlerts: ((SettingsSnapshot, Place) -> Void)?

    init(store: UserDataStore? = nil, localizer: SirajLocalizer? = nil) {
        let appGroup = Bundle.main.object(forInfoDictionaryKey: "SirajAppGroupID") as? String
        let resolvedStore = store ?? UserDataStore(appGroupId: appGroup)
        let resolvedLoc = localizer ?? SirajLocalizer(bundle: .main, subdirectory: "Data")

        self.store = resolvedStore
        self.localizer = resolvedLoc
        self.quranStore = QuranStore(userStore: resolvedStore)
        self.audioStore = QuranAudioStore(userStore: resolvedStore)
        self.khatmaStore = KhatmaStore(userStore: resolvedStore)
        self.worshipStore = WorshipStore(userStore: resolvedStore)
        self.radioStore = QuranRadioStore(userStore: resolvedStore)
        self.fastingStore = FastingStore(userStore: resolvedStore)
        self.guideStore = GuideStore(userStore: resolvedStore)

        let radio = self.radioStore
        let audio = self.audioStore
        audio.onWillStartPlaying = { [weak radio] in
            radio?.pauseForOtherAudio()
        }
        radio.onWillStartPlaying = { [weak audio] in
            audio?.pauseForAdhan()
        }
        audio.remotePlayFallback = { [weak radio] in
            guard let radio, radio.hasMiniPlayer, !radio.isPlaying else { return }
            radio.toggleActivePlayPause()
        }
        audio.remotePauseFallback = { [weak radio] in
            guard let radio, radio.hasMiniPlayer else { return }
            radio.pause()
        }
        audio.remoteToggleFallback = { [weak radio] in
            guard let radio, radio.hasMiniPlayer else { return }
            radio.toggleActivePlayPause()
        }
        audio.remoteNextFallback = { [weak radio] in
            guard let radio, radio.hasMiniPlayer else { return }
            radio.skip(delta: 1)
        }
        audio.remotePrevFallback = { [weak radio] in
            guard let radio, radio.hasMiniPlayer else { return }
            radio.skip(delta: -1)
        }

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

    var currentTime: Date {
        pinnedSkyTime ?? Date()
    }

    var activePlace: Place {
        settings.cachedLocation ?? .cairoDefault
    }

    var hijriCalendar: SirajHijriCalendar {
        SirajHijriCalendar.forSettings(
            method: settings.hijriMethod,
            countryCode: activePlace.resolvedCountryCode,
            adjustment: settings.hijriAdjustment
        )
    }

    func updateSettings(_ mutate: (inout SettingsSnapshot) -> Void) {
        let old = settings
        var copy = settings
        mutate(&copy)
        guard copy != old else { return }
        settings = copy
        if !isUITesting {
            store.saveSettings(copy)
        }
        refreshPrayers()

        let widgetsChanged = old.cachedLocation != copy.cachedLocation
            || old.calculationSettings != copy.calculationSettings
            || old.hijriMethod != copy.hijriMethod
            || old.hijriAdjustment != copy.hijriAdjustment
            || old.themePalette != copy.themePalette
            || old.themeMode != copy.themeMode
            || old.isAmoled != copy.isAmoled
            || old.language != copy.language
            || old.hourFormat != copy.hourFormat
            || old.numeralSystem != copy.numeralSystem
        if widgetsChanged {
            WidgetCenter.shared.reloadAllTimelines()
        }

        let alertsChanged = old.alertScheduleConfig != copy.alertScheduleConfig
            || old.cachedLocation != copy.cachedLocation
            || old.azanSound != copy.azanSound
            || old.fajrAdhanEnabled != copy.fajrAdhanEnabled
            || old.fajrAdhanVoice != copy.fajrAdhanVoice
            || old.language != copy.language
            || old.hourFormat != copy.hourFormat
            || old.numeralSystem != copy.numeralSystem
            || old.liveActivityEnabled != copy.liveActivityEnabled
            || old.themePalette != copy.themePalette
        if alertsChanged {
            onSettingsChangedForAlerts?(copy, activePlace)
        }
    }

    func completeOnboarding() {
        onboardingComplete = true
        if !isUITesting {
            store.saveOnboardingComplete(true)
            store.saveSettings(settings)
        }
        refreshPrayers()
        WidgetCenter.shared.reloadAllTimelines()
        onSettingsChangedForAlerts?(settings, activePlace)
    }

    func refreshPrayers() {
        let now = currentTime
        let place = activePlace
        prayerDay = PrayerCalculator.today(place: place, settings: settings.calculationSettings, now: now)
        let cal = hijriCalendar
        let civil = place.today(at: now)
        hijriDate = cal.toHijri(civil)
        upcomingOccasions = IslamicOccasions.upcoming(from: civil, calendar: cal)
    }

    func navigateForGuideTopic(_ topic: GuideTopic) {
        switch topic {
        case .reading, .search:
            selectedTab = .quran
        case .listening, .bookmarks, .tafsir:
            if quranStore.assetState.isReady {
                let page = quranStore.readingPosition.map {
                    quranStore.pageForAyah(
                        surah: $0.surahNumber,
                        ayah: $0.ayahNumber,
                        edition: MushafEdition.resolve(settings.mushafEdition)
                    )
                } ?? 1
                activeReader = ReaderDestination(page: page, surahNumber: quranStore.readingPosition?.surahNumber, ayahNumber: quranStore.readingPosition?.ayahNumber)
            } else {
                selectedTab = .quran
            }
        case .mushaf, .downloads:
            selectedTab = .settings
            requestedRoute = "quran_settings"
        case .library:
            selectedTab = .quran
            requestedQuranRoute = "listen"
        case .khatma:
            selectedTab = .quran
            requestedQuranRoute = "khatma"
        case .adhkar:
            selectedTab = .azkar
        case .hadith:
            selectedTab = .azkar
            requestedWorshipRoute = .hadith(nil)
        case .radio:
            selectedTab = .azkar
            requestedWorshipRoute = .radio
        case .prayer:
            selectedTab = .settings
            requestedRoute = "reminders"
        case .qibla:
            selectedTab = .qibla
        case .tasbih:
            selectedTab = .azkar
            requestedWorshipRoute = .tasbih
        case .calendar:
            selectedTab = .azkar
            requestedWorshipRoute = .calendar
        case .widgets:
            selectedTab = .settings
            requestedRoute = "widgets"
        case .appearance:
            selectedTab = .settings
            requestedRoute = "appearance"
        }
    }

    func applyLaunchArguments(_ args: [String]) {
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
