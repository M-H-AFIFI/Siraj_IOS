# Siraj for iOS

A native SwiftUI Islamic app for iPhone.

Right now this includes prayer time calculations (multiple calculation methods, Shafi/Hanafi, high-latitude rules, offsets, and iqama), Hijri calendars and moon phases, an animated sky card on the prayer screen, onboarding, themes (15 palettes, light/dark/AMOLED, glass, and live animated backgrounds), and English, Arabic, Turkish, and Urdu with RTL support.

Adhan playback and notifications, widgets, Quran, Qibla, and Azkar are still in progress.

## Building

You need Xcode 16+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
xcodegen generate --spec project.yml
swift test --package-path Packages/SirajCore
open Siraj.xcodeproj
```

Pushes to `main` run the macOS GitHub Actions workflow to execute `SirajCore` tests and build both `Siraj` and `SirajSideload` (a main-app-only scheme that can be signed with a free Apple ID).
