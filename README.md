# Siraj for iOS

An offline-first SwiftUI Islamic app for iPhone, with no ads or tracking.

It includes prayer times with multiple calculation methods, Shafi and Hanafi Asr, high-latitude rules, offsets, iqama, and local adhan notifications with bundled and downloadable voices. The home screen has an animated sky card, a full-screen adhan alert, Lock Screen widgets, a Live Activity countdown, and 21 Home Screen widget faces including an interactive Tasbih counter, floral verse cards, clock dials, Hijri dates, moon phases, fasting times, and reading progress.

The Quran reader supports three Mushaf editions (Madinah, IndoPak, and Shamarly), ayah-by-ayah reading, bookmarks, notes, 17 tafsir and translation books, a Khatma planner, a verse video exporter, and an audio player with 75 reciters, rare recitations, and an ambient sound mixer.

The Worship tab brings together a live Qibla astrolabe compass, Hisn al-Muslim adhkar (140 chapters), a 33-bead tasbih, 110 prophetic hadiths, the 99 Names of Allah, a monthly Hijri calendar with astronomical moon phases and Islamic occasions, 24 live Quran radio stations, a fasting and imsakiah tracker, a zakat calculator with 36 currencies, and an interactive in-app guide. Everything is localized in English, Arabic, Turkish, and Urdu with RTL support, 15 color palettes, light/dark/AMOLED modes, glass cards, 17 live animated backgrounds, and 12 app icons.

## Building

You need Xcode 16+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
xcodegen generate --spec project.yml
swift test --package-path Packages/SirajCore
open Siraj.xcodeproj
```

Pushes to `main` run the macOS GitHub Actions workflow, which runs the `SirajCore` test suite and builds unsigned `Siraj-Sideload.ipa` (main app only, for signing with a free Apple ID) and `Siraj-Full.ipa` (with `SirajWidgets` and App Group).
