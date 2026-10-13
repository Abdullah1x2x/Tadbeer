# Tadbeer (تَدْبِير)

[![License: MIT](https://img.shields.io/badge/License-MIT-emerald.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.22.0-02569B.svg?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%5E3.4.0-0175C2.svg?logo=dart)](https://dart.dev)
[![Tests](https://img.shields.io/badge/Tests-174%20passed-success.svg)](test/)
[![Offline](https://img.shields.io/badge/Offline--First-100%25-blueviolet.svg)](#privacy--offline-first)
[![Website](https://img.shields.io/badge/Website-GitHub%20Pages-informational.svg)](https://abdullah-alshami.github.io/Tadbeer/)

**[العربية](README.ar.md) | English**

> **Tadbeer is an open-source, offline-first Quranic application designed to shift the reader's journey from rapid recitation to deep contemplation (*Tadabbur*), thematic connection of verses, and practical everyday action.**

Official Website & Privacy Policy: **[abdullah-alshami.github.io/Tadbeer](https://abdullah-alshami.github.io/Tadbeer/)**

---

## ✨ Key Features

### 📖 Holy Quran Reader
- **Responsive Authentic Layout:** Digital reproduction of the Holy Quran featuring the verified Uthmani script from the Tanzil Project, Medinan layout, ornate Surah header banners, Bismillah headings, and authentic verse rosettes `﴿1﴾`.
- **5 Selectable Open-Source Quranic Fonts:** Crisp rendering using authentic fonts under the SIL Open Font License 1.1:
  - **Amiri Quran** (Dr. Khaled Hosny)
  - **Scheherazade New** (SIL International)
  - **Noto Naskh Arabic** (Google / Monotype)
  - **Lateef** (SIL International)
  - **Harmattan** (SIL International)
  - *Plus Amiri for headings, supplications, and UI elements.*
- **Customizable Font Sizing & Typography:** Fully adjustable font size (16.0pt to 32.0pt) accessible via a live slider in Settings and a quick-access modal button in the Quran reading toolbar.
- **Zero-Overflow Adaptive Geometry:** Adaptive layout engine using `LayoutBuilder` and `SingleChildScrollView`, guaranteeing zero `RenderFlex` overflow on small screens (320px width), foldables, tablets, and desktop displays.
- **Dual-Page Spread Layout:** Automatic side-by-side spread on tablets and wide viewports (`width >= 900dp`), mimicking an open physical Mushaf.

### 🌿 Reflection & Study Tools
- **Tadbeer Pause (وقفة تدبر):** Structured reflection worksheet anchored to individual verses with four foundational prompts: *What do I understand? What feeling does it evoke? What does it heal in me? What practical action will I take?*
- **Thematic Verse Links (روابط الآيات):** Thematic cross-referencing system linking related ayahs across surahs, viewable in both interactive topological network and sequential ordered list views.
- **Curated Thematic Pathways (المسارات التدبرية المقترحة):** Built-in pathways across major Quranic themes (e.g., Divine Names in Surah Al-Hashr, Prophetic Duas in Surah Al-Anbiya, Personal & Societal Transformation) with one-tap import.
- **Zero-Network QR Sharing:** Export and import Ayah Links offline via standard QR codes without cloud sync.
- **Reflections Journal (PDF & Markdown Export):** Personal contemplative journaling per ayah or general reflection, with single-note PDF export and periodic reflection journal archiving (weekly, monthly, or full archive) complete with reflection statistics.
- **Highlights & Bookmarks:** Four-color verse highlighting rendered smoothly via `AyahHighlightPainter`, plus instant reading bookmarks.

### 📚 Quranic Word Meanings (معاني كلمات القرآن)
- **Extensive Single-Word Lexicon:** Curated dataset of **6,465 single-word entries** covering all 604 pages and 114 surahs with 100% coverage.
- **Pure Lexical Definitions:** Focused lexical meanings in concise Arabic, free from extraneous commentary or speculative tafsir.
- **Authoritative Attributions:** Derived from [Quranpedia.net](https://quranpedia.net) (`Version 2026-10-10`, CC0-1.0), *Al-Mu'jam Al-Waseet* (Academy of the Arabic Language in Cairo), and classical lexicons (*Lisan Al-Arab*, *Maqayis Al-Lughah*, *Taj Al-Arus*, *Mufradat Al-Raghib*).
- **Synchronized Margin Panel:** Built-in collapsible reader panel updating dynamically on every page turn, alongside a dedicated standalone lexicon browser screen.

### 🤲 Duas & Unified Search
- **Quranic Duas:** Catalog of 88 direct Quranic supplications extracted directly from verified Uthmani text across 12 thematic categories, with multi-verse rosette markers and direct navigation to their exact page in the Mushaf.
- **Unified Global Search:** Extensible `SearchRegistry` querying 9 domains concurrently with error isolation and interactive filter chips.
- **Root & Morphological Search:** Instant root search via `جذر:XXX` syntax (e.g. `جذر:صبر` or `جذر:رحم`), matching across rich morphological variations across all 6,236 ayahs.
- **Offline Reminders:** Local scheduled notifications (`flutter_local_notifications` + `flutter_timezone`) for daily Quran reading and reflection routines, operating completely on-device without internet access.

---

## 🔒 Privacy & Offline-First

Tadbeer is built with **Privacy by Design**:
- **Zero Data Collection:** No personal data, device identifiers, or analytics are ever collected, transmitted, or sold.
- **100% Offline Operation:** Tadbeer does not request `android.permission.INTERNET` in its Android manifest and makes zero network requests.
- **Local SQLite Persistence:** All user notes, reflections, bookmarks, highlights, and links are stored locally on the user's device (`tadbeer_user_data.db`).
- **AES-256 Encrypted Backups:** User-controlled backup export and import (`.quranbackup`) encrypted locally using AES-256-CBC with a user-defined password, Gzip compression, and SHA-256 checksum integrity verification.

Official Privacy Policy is publicly available at: **[https://abdullah-alshami.github.io/Tadbeer/#privacy](https://abdullah-alshami.github.io/Tadbeer/#privacy)**

---

## 🛠️ Technology Stack

- **Framework:** [Flutter](https://flutter.dev/) (SDK `>=3.22.0`)
- **Language:** [Dart](https://dart.dev/) (SDK `^3.4.0`)
- **Database:** [SQLite](https://www.sqlite.org/) via `sqflite` (with `sqflite_common_ffi` for automated tests)
- **State Management:** Reactive Single Source of Truth cache extending Flutter's native `ChangeNotifier` (`UserDataStore`)
- **Typography:** 5 SIL OFL-1.1 Quranic fonts (`AmiriQuran`, `ScheherazadeNew`, `NotoNaskhArabic`, `Lateef`, `Harmattan`) + `Amiri` for interface
- **Encryption:** `encrypt` (AES-256-CBC) + `crypto` (SHA-256) + `archive` (Gzip)

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK: `3.22.0` or higher
- Dart SDK: `^3.4.0`

### Setup & Run

```bash
# Clone the repository
git clone https://github.com/Abdullah-Alshami/Tadbeer.git
cd Tadbeer

# Install dependencies
flutter pub get

# Run the app
flutter run
```

---

## 🧪 Testing & Verification

```bash
# Verify static analysis (0 warnings / 0 errors)
dart analyze

# Run all automated tests (174 tests, 23 test files, 100% passing)
flutter test

# Build production release packages
flutter build apk --release
flutter build appbundle --release
```

---

## 📁 Repository Structure

```text
tadbeer/
├── assets/                     # Bundled assets (~6.6MB total)
│   ├── fonts/                  # 5 Quran fonts + Amiri UI font (SIL OFL-1.1)
│   ├── icons/                  # Application icons & logo
│   └── quran/
│       ├── quran_data.json     # Verified Tanzil Uthmani text (2.0MB)
│       └── word_meanings.json  # 6,465 verified lexical entries (1.1MB)
├── lib/                        # Production Dart code (58 files)
│   ├── app/                    # App bootstrap, localization (ar/en), theme
│   ├── core/
│   │   ├── services/           # AES-256 crypto & local reminders
│   │   ├── storage/            # SQLite database & reactive UserDataStore
│   │   └── utils/              # Arabic root search & PDF export utilities
│   ├── features/               # Feature domain modules:
│   │   ├── ayah_links/         # Thematic verse links & network views
│   │   ├── backup/             # Encrypted backup & restore screen
│   │   ├── bookmarks/          # Bookmarks repository & screen
│   │   ├── duas/               # 88 Quranic duas catalog
│   │   ├── highlights/         # 4-color verse highlighting
│   │   ├── home/               # Dashboard & reading resume
│   │   ├── notes/              # Reflection notes & PDF journal export
│   │   ├── quran/              # Responsive Mushaf engine & page view
│   │   ├── reminders/          # Reading reminders scheduling
│   │   ├── search/             # Unified search registry & providers
│   │   ├── settings/           # Font family/size, theme, and about
│   │   ├── tadbeer/            # Tadbeer pause worksheet & intro
│   │   └── word_meanings/      # Word meanings explorer & sources
│   └── main.dart               # Entrypoint & service initialization
├── test/                       # Comprehensive test suite (174 tests, 23 files)
├── DEVELOPMENT_GUIDE.md        # Technical developer & maintenance guide
├── DEVELOPMENT_GUIDE.ar.md     # Arabic technical developer guide
├── ATTRIBUTION.md              # Attribution statements & source details
├── THIRD_PARTY_NOTICES.md      # Full third-party license notices
├── LICENSE                     # MIT License
└── index.html                  # Official GitHub Pages website & privacy policy
```

For detailed technical architecture, database schemas, and contribution guides, see:
- **[DEVELOPMENT_GUIDE.md](DEVELOPMENT_GUIDE.md)** (English)
- **[DEVELOPMENT_GUIDE.ar.md](DEVELOPMENT_GUIDE.ar.md)** (العربية)

---

## 📜 Licenses & Attribution

- **Application Code:** Licensed under the **[MIT License](LICENSE)**.
- **Quranic Text:** [Tanzil Project](https://tanzil.net/) (`CC-BY 3.0`).
- **Word Meanings:** [Quranpedia.net](https://quranpedia.net) (`CC0 1.0 Public Domain`) and classical Arabic lexicons in the public domain.
- **Typography:** All 5 Quranic and interface fonts are licensed under the **SIL Open Font License 1.1** (`OFL-1.1`).

Complete legal details and verbatim license texts are available in [ATTRIBUTION.md](ATTRIBUTION.md) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).