import XCTest

final class ScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    private func capture(name: String, args: [String], settleSeconds: TimeInterval = 1.2) {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"] + args
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15), "App failed to launch for \(name)")
        Thread.sleep(forTimeInterval: settleSeconds)

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        app.terminate()
    }

    func test01OnboardingWelcome() {
        capture(
            name: "01_onboarding_welcome",
            args: [
                "--sky-time=2026-03-15T10:30:00Z",
                "--locale=en",
                "--theme=light",
                "--palette=Emerald"
            ]
        )
    }

    func test02PrayerFajrDark() {
        capture(
            name: "02_prayer_fajr_dark",
            args: [
                "--skip-onboarding",
                "--sky-time=2026-03-15T02:55:00Z",
                "--locale=en",
                "--theme=dark",
                "--palette=Emerald"
            ]
        )
    }

    func test03PrayerDhuhrLight() {
        capture(
            name: "03_prayer_dhuhr_light",
            args: [
                "--skip-onboarding",
                "--sky-time=2026-03-15T10:15:00Z",
                "--locale=en",
                "--theme=light",
                "--palette=Emerald"
            ]
        )
    }

    func test04PrayerMaghribGlass() {
        capture(
            name: "04_prayer_maghrib_glass",
            args: [
                "--skip-onboarding",
                "--sky-time=2026-03-15T16:10:00Z",
                "--locale=en",
                "--theme=dark",
                "--palette=Gold",
                "--glass"
            ]
        )
    }

    func test05PrayerIshaAmoledLive() {
        capture(
            name: "05_prayer_isha_amoled_live",
            args: [
                "--skip-onboarding",
                "--sky-time=2026-03-15T18:30:00Z",
                "--locale=en",
                "--theme=black",
                "--palette=RoyalIndigo",
                "--live-theme=NightStars"
            ]
        )
    }

    func test06PrayerArabicRTL() {
        capture(
            name: "06_prayer_arabic_rtl",
            args: [
                "--skip-onboarding",
                "--sky-time=2026-03-15T13:30:00Z",
                "--locale=ar",
                "--theme=dark",
                "--palette=TealCaspian"
            ]
        )
    }

    func test07AdhanAlertFajr() {
        capture(
            name: "07_adhan_alert_fajr",
            args: [
                "--skip-onboarding",
                "--sky-time=2026-03-15T02:55:00Z",
                "--locale=en",
                "--theme=dark",
                "--palette=Emerald",
                "--show-adhan-alert=fajr"
            ],
            settleSeconds: 1.5
        )
    }

    func test08AppearancePalettes() {
        capture(
            name: "08_appearance_palettes",
            args: [
                "--skip-onboarding",
                "--sky-time=2026-03-15T10:15:00Z",
                "--locale=en",
                "--theme=light",
                "--palette=Emerald",
                "--open-route=appearance"
            ],
            settleSeconds: 1.5
        )
    }

    func test09RemindersSettings() {
        capture(
            name: "09_reminders_settings",
            args: [
                "--skip-onboarding",
                "--sky-time=2026-03-15T10:15:00Z",
                "--locale=en",
                "--theme=dark",
                "--palette=Emerald",
                "--open-route=reminders"
            ],
            settleSeconds: 1.5
        )
    }

    func test10WidgetGallery() {
        capture(
            name: "10_widget_gallery",
            args: [
                "--skip-onboarding",
                "--sky-time=2026-03-15T10:15:00Z",
                "--locale=en",
                "--theme=dark",
                "--palette=Gold",
                "--open-route=widgets"
            ],
            settleSeconds: 1.5
        )
    }
}
