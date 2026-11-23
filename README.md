# Siraj for iOS

An offline-first Islamic companion for iPhone, built in Swift and SwiftUI.

## What is included

- **Prayer times** calculated identically to the Android and Windows apps (Adhan 1.2.1 with all calculation methods, Shafi/Hanafi madhabs, high-latitude rules, minute offsets, and iqama intervals), verified against the 27,000-row reference dataset.
- **Hijri calendar & moon phase** across country calendars (Umm al-Qura using the JDK table, Egypt, Diyanet, sighting, naked eye, MABIMS) with manual adjustment and upcoming Islamic occasions.
- **Animated sky card**: continuous 24-hour sky gradient, twilights, solar arc, stars and shooting stars, clouds, water reflection, moon phase, skyline lamps, iqama and in-prayer states, and rolling countdown.
- **Adhan & reminders**: local notification scheduling within iOS's 64-notification sliding window refreshed on launch and via background refresh, 30-second muezzin clips on the lock screen, downloadable HQ and Fajr recordings, full-screen Adhan alert view, pre-prayer reminders, suggested reminders, and custom reminders.
- **Widgets & Live Activity**: Lock Screen accessories (24/7 offline auto-advancing countdown), opportunistic Dynamic Island / Lock Screen Live Activity, configurable Home Screen widgets, and an in-app Widget Gallery.
- **Visual design**: 15 color palettes, Light/Dark/AMOLED Black, Glass UI (Clear, Satin, Frosted), 17 animated live backdrops, custom floating pill tab bar, 12 selectable app icons, and four languages (`en`, `ar`, `tr`, `ur`) with full RTL support.

## Project layout

```text
project.yml                 XcodeGen specification (generates Siraj.xcodeproj)
Packages/SirajCore/         Pure Swift core: prayer, Hijri, sky, alerts, settings, tests
SirajApp/                   SwiftUI app target (full and sideload configurations)
SirajWidgets/               WidgetKit Home/Lock Screen widgets and Live Activity
SirajUITests/               Automated Simulator screenshot suite
.github/workflows/ios.yml   CI: unit tests, Simulator screenshots, and unsigned .ipa builds
```

## Building

Requires Xcode 16+ on macOS and [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
xcodegen generate --spec project.yml
swift test --package-path Packages/SirajCore
open Siraj.xcodeproj
```

Every push runs the macOS GitHub Actions workflow, which executes `SirajCoreTests`, captures iPhone Simulator screenshots, and uploads unsigned `Siraj-Sideload.ipa` (main app, ready for Sideloadly or AltStore with a free Apple ID) and `Siraj-Full.ipa` (main app with widgets and App Group) artifacts.
