# Siraj for iOS

A native SwiftUI Islamic app for iPhone.

Right now this includes prayer times (multiple calculation methods, Shafi/Hanafi, high-latitude rules, offsets, and iqama), Hijri calendars and moon phases, an animated sky card, local adhan notifications and audio playback (bundled and downloadable voices, Fajr adhan, and a full-screen adhan alert), Lock Screen widgets, Live Activity, configurable Home Screen widgets, onboarding, themes (15 palettes, light/dark/AMOLED, glass, live animated backgrounds, and 12 app icons), and English, Arabic, Turkish, and Urdu with RTL support.

Quran, Qibla, and Azkar are still being built.

## Building

You need Xcode 16+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
xcodegen generate --spec project.yml
swift test --package-path Packages/SirajCore
open Siraj.xcodeproj
```

Pushes to `main` run the macOS GitHub Actions workflow, which runs `SirajCore` tests, captures iPhone Simulator screenshots, and uploads unsigned `Siraj-Sideload.ipa` (main app only, for signing with a free Apple ID) and `Siraj-Full.ipa` (with `SirajWidgets` and App Group).
