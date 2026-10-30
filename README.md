<div align="center">

<img src="docs/assets/icons/app_logo.png" alt="Tadbeer logo" width="120">

# Tadbeer (تَدْبِير)

**From reading to reflection.** An open-source Quran app that works offline, with no ads and no tracking.

[![CI](https://github.com/Abdullah1x2x/Tadbeer/actions/workflows/ci.yml/badge.svg)](https://github.com/Abdullah1x2x/Tadbeer/actions/workflows/ci.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[Download](https://github.com/Abdullah1x2x/Tadbeer/releases) · [Website](https://abdullah-alshami.github.io/Tadbeer/) · [Project guide](docs/PROJECT_GUIDE.md) · [العربية](README.ar.md)

</div>

<p align="center">
  <img src="docs/assets/screenshots/home.jpg" alt="Home screen" width="23%">
  <img src="docs/assets/screenshots/mushaf.jpg" alt="Madinah Mushaf" width="23%">
  <img src="docs/assets/screenshots/menu.jpg" alt="Ayah menu" width="23%">
  <img src="docs/assets/screenshots/duas.jpg" alt="Duas" width="23%">
</p>

## Why Tadbeer?

The app helps you understand the Quran and act on it, not only read it. It is built around three tools:

- **Reflection pause:** four questions at any ayah that open its meanings.
- **Ayah links:** gather ayahs from different surahs into one theme and see them as a network.
- **Reflection pathways:** 15 themes, with an ayah and a question each day for at least seven days.

## Features

| Section | What it offers |
| --- | --- |
| **Mushaf** | 604 pages in the Madinah fonts or text fonts, smooth paging, a radial ayah menu and word meanings |
| **Listening** | 7 reciters, a whole surah or one ayah, and downloads for offline listening |
| **Journey** | Khatma plans, day streaks, goals, a Mushaf map and a monthly report |
| **Memorization** | Spaced review of the ayahs you memorize |
| **Duas** | Duas from the Quran, the Sunnah and the Ahlulbayt, with daily adhkar and counters |
| **Dhikr** | An istighfar and tasbeeh counter with auto counting |
| **Notes** | Notes on ayahs and a reflection journal, with export and save to device |
| **Library** | Books and booklets you read inside the app |
| **More** | Unified search, Qibla direction, reminders, a home-screen widget and encrypted backup |

The app explains itself with a first-launch tour, an animated guide for each section and a home screen walkthrough.

## Privacy

Your data stays on your device. No account, ads or analytics. The internet is used only for recitation, and approximate location only for the Qibla. See the [privacy policy](PRIVACY_POLICY.md).

## Getting started

You need Flutter 3.47.6 and the Android SDK. Full setup steps are in the [project guide](docs/PROJECT_GUIDE.md#2-تجهيز-جهازك-من-الصفر) (Arabic).

```bash
git clone https://github.com/Abdullah1x2x/Tadbeer.git
```

```bash
cd Tadbeer && flutter pub get && flutter run
```

```bash
flutter analyze && flutter test
```

## Documentation

| File | For |
| --- | --- |
| [Project guide](docs/PROJECT_GUIDE.md) (Arabic) | Start here: every file, and how to change any detail |
| [Development guide](DEVELOPMENT_GUIDE.md) | Systems summary and code standards |
| [Architecture guide](docs/ARCHITECTURE_AND_CODE_GUIDE.md) (Arabic) | A deeper look at the main systems |
| [Content guide](docs/CONTENT_GUIDE.md) (Arabic) | Adding duas, books and pathways |
| [Changelog](CHANGELOG.md) | What changed in each release |

## Contributing

Fixes and ideas are welcome through [issues](https://github.com/Abdullah1x2x/Tadbeer/issues) and pull requests. If you find an error in a religious text, please report it first.

## License and sources

The app code is under the [MIT License](LICENSE). Bundled content has its own sources and terms:

- Quran text: [Tanzil Project](https://tanzil.net).
- Mushaf fonts: King Fahd Glorious Quran Printing Complex.
- Word meanings: [Quranpedia](https://quranpedia.net).
- Full details are in [ATTRIBUTION.md](ATTRIBUTION.md) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
