# Tadbeer (تَدْبِير)

[![License: MIT](https://img.shields.io/badge/License-MIT-emerald.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.22.0-02569B.svg?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%5E3.4.0-0175C2.svg?logo=dart)](https://dart.dev)
[![Tests](https://img.shields.io/badge/Tests-653%20passed-success.svg)](test/)
[![Offline](https://img.shields.io/badge/Offline--First-100%25-blueviolet.svg)](#privacy--offline-first)
[![Website](https://img.shields.io/badge/Website-GitHub%20Pages-informational.svg)](https://abdullah-alshami.github.io/Tadbeer/)

**[العربية](README.ar.md) | English**

> **Tadbeer is an open-source, offline-first Quranic application designed to shift the reader's journey from rapid recitation to deep contemplation (*Tadabbur*), thematic connection of verses, and practical everyday action.**

Official Website & Privacy Policy: **[abdullah-alshami.github.io/Tadbeer](https://abdullah-alshami.github.io/Tadbeer/)**

---

## ✨ Key Features

### 💎 Futuristic Design & Motion System
- **Advanced Digital Design System (`lib/core/design_system/`):** High-precision geometric `FuturisticCard` with layered depths and subdued borders, interactive `FuturisticButton`, status indicators (`FuturisticBadge`), and tactile `FuturisticIconButton`.
- **Unified Motion Engine (`lib/core/motion/app_motion.dart`):** Consistent durations (`fast: 120ms`, `normal: 200ms`, `slow: 350ms`), calibrated curves (`easeOutCubic`, `easeInOutCubic`), and responsive `ScaleOnPress` micro-interactions.
- **Accessibility & Reduced Motion:** Full compliance with `MediaQuery.disableAnimationsOf(context)` across all animated controls to provide instant transitions for motion-sensitive users.

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
- **Ayah Markers in the Madinah Mushaf:** Bookmark, note, reflection and memorization icons sit above the ayah number on the King Fahd (QCF) pages without touching the printed line width.
- **Recitation, Surah or Single Ayah:** The headphones button in the toolbar plays on through the surah; *Listen* in an ayah's long-press menu plays that ayah alone. Playback recovers from stalls: loading times out after 20 seconds, an error stops the player cleanly, and a player the system paused restarts the ayah.

### 🌅 Ayah of the Day & Home-Screen Widget
- **Verses from the Whole Mushaf:** The reflection card and the widget draw from every ayah that fits them (6,128 of 6,236 across all 114 surahs), led each day by a curated dua or pathway verse.
- **Larger Verse Text:** The ayah is drawn larger on the home card and in the widget.
- **Widget Preview:** The phone's widget picker shows the ayah in the Amiri Quran font with the khatma progress, in the app's language.

### 📿 Istighfar & Tasbeeh (Digital Counter & Daily Dhikr)
- **Direct & Uncomplicated Dual Sections:** Pure and simple division into **Istighfar** (20 formulas) and **Tasbeeh** (29 formulas) without nested or excessive subcategories.
- **Fixed-Height Dhikr Card (No Jitter or Jumping):** The dhikr card maintains an exact, invariant height regardless of text length, keeping the circular counter and screen elements completely stationary during swiping.
- **49 Authentic Prophetic & Quranic Formulas:** Carefully selected formulas with documented virtues and references, featuring smooth internal scrolling for longer texts.
- **Direct Navigation & Quick Copy:** Previous/Next arrows, horizontal swipe gestures, and a single-tap button to copy the dhikr text to the clipboard.
- **Smart Auto-Advance Mode:** Optional automated progression to the next dhikr when reaching the target (33 or 100) with celebration haptics.
- **Interactive Touch Counter with Haptics:** Fluid circular counter with light haptics, cycle target options (33, 100, free count), and persistently saved daily and lifetime totals.

### 📚 Books & Study Booklets (Custom Sections & Attachments)
- **Custom Categorized Sections:** Create and manage distinct study sections (e.g., Tadbeer Guides, Tafsir Books, Course Notes) to organize your personal reading library.
- **Local File Attachments (PDF & Text):** Easily attach and import PDF documents and text files (`.txt`, `.md`) directly from your device, safely stored in offline application documents.
- **Built-in Dedicated Reader & Sharing:** Clean reading interface with dynamic font resizing, chapter/outline navigation, external PDF app opening, and offline document sharing.

### 🧭 Guided First Launch
- **App Tour:** A short animated tour of the Mushaf, reflection, listening and the daily journey.
- **Section Guides:** Each main section explains itself on first visit, and the guide button replays it.
- **Home Walkthrough:** A spotlight on the real home widgets after the tour, replayable from Settings.

### 🌿 Reflection & Study Tools
- **Tadbeer Pause (وقفة تدبر):** Structured reflection worksheet anchored to individual verses with four foundational prompts: *What do I understand? What feeling does it evoke? What does it heal in me? What practical action will I take?*
- **Thematic Verse Links (روابط الآيات):** Thematic cross-referencing system linking related ayahs across surahs, viewable in both interactive topological network and sequential ordered list views.
- **Overhauled Ayah Link Picker:** Streamlined, responsive bottom sheet dialog for quickly searching, selecting, and attaching verses to thematic pathways with real-time validation.
- **Curated Thematic Pathways (المسارات التدبرية المقترحة):** Built-in pathways across major Quranic themes (e.g., Divine Names in Surah Al-Hashr, Prophetic Duas in Surah Al-Anbiya, Personal & Societal Transformation) with one-tap import.
- **Reflections Journal (PDF & Markdown Export):** Personal contemplative journaling per ayah or general reflection, with single-note PDF export and periodic reflection journal archiving (weekly, monthly, or full archive) complete with reflection statistics.
- **Highlights & Bookmarks:** Four-color verse highlighting rendered smoothly via `AyahHighlightPainter`, plus instant reading bookmarks.

### 📚 Quranic Word Meanings (معاني كلمات القرآن)
- **Extensive Single-Word Lexicon:** Curated dataset of **6,465 single-word entries** covering all 604 pages and 114 surahs with 100% coverage.
- **Pure Lexical Definitions:** Focused lexical meanings in concise Arabic, free from extraneous commentary or speculative tafsir.
- **Authoritative Attributions:** Derived from [Quranpedia.net](https://quranpedia.net) (`Version 2026-10-10`), *Al-Mu'jam Al-Waseet* (Academy of the Arabic Language in Cairo), and classical lexicons (*Lisan Al-Arab*, *Maqayis Al-Lughah*, *Taj Al-Arus*, *Mufradat Al-Raghib*).
- **Synchronized Margin Panel:** Built-in collapsible reader panel updating dynamically on every page turn, alongside a dedicated standalone lexicon browser screen.
- **Light Diacritics & Mushaf Order:** Meanings carry light tashkeel (shadda, tanween and the vowels a reader could misread) and are listed by surah and ayah; search still matches text typed without diacritics.

### 🤲 Organized Duas & Adhkar Section
- **Quranic Duas:** Catalog of **89 direct Quranic supplications** extracted directly from verified Uthmani text across 12 thematic categories, with multi-verse rosette markers and direct navigation to their exact page in the Mushaf.
- **Daily Adhkar Beyond Morning & Evening:** Sleep, waking, after prayer and mosque adhkar with counters.
- **Interactive Morning & Evening Adhkar:** Authentic fortress of the Muslim supplications with responsive per-dhikr countdown counters, instant copy, and documented virtues and sources.
- **Ahlulbayt & Sahifah Sajjadiyah Duas (Complete Unabridged Texts):** Dedicated spiritual reader presenting each supplication as a single unified continuous text without segmented cuts, with font resizing and instant copying, featuring:
  - *Dua Makarim al-Akhlaq* (Noble Moral Traits by Imam Ali Zayn al-Abidin)
  - *Dua Ahl al-Thughoor* (Protection for Muslim Borders and Guardians by Imam Zayn al-Abidin)
  - *Dua Kumayl ibn Ziyad* (Taught by Imam Ali for Friday Eve and mid-Sha'ban)
  - *Dua al-Nudbah* (Supplication of Longing on Friday Mornings and Eids)
  - *Dua al-Tawassul* (Supplication of Intercession through the Prophet and his Holy Progeny)
  - *Imam Hussein's Dua on Day of Arafah* (Profound prayer of monotheism and gratitude)
  - *Dua al-Jawshan al-Kabir* (The 1,000 Divine Names and Attributes for safety and protection)
  - *Imam al-Sadiq's Dua for Needs* ("O Allah, make me fear You as though I see You...")
  - *Sayyidah Fatimah al-Zahra's Dua* ("O Living, O Sustainer, by Your mercy I seek help...")
  - *Additional Revered Duas:* Dua al-Faraj, Dua al-Sabah of Imam Ali, Dua al-Ahd, Al-Munajat al-Sha'baniyyah, and Dua Yastasheer.
- **Prophetic & Comprehensive Duas:** Curated authentic supplications for distress, grief, debts, and righteousness in this life and the hereafter.
- **Unified Global Search:** Extensible `SearchRegistry` querying 11 domains concurrently with error isolation and interactive filter chips.
- **Phonetic-to-Standard Arabic Query Normalization:** Intelligent query normalizer in `ArabicSearchNormalizer` resolving common phonetic spellings (e.g. هازا -> هذا، ذالك -> ذلك، صلاه -> صلاة، رحمن -> رحمن) strictly within search inputs while preserving 100% untouched integrity of authentic Quranic text and classical heritage collections.
- **Root & Morphological Search:** Instant root search via `جذر:XXX` syntax (e.g. `جذر:صبر` or `جذر:رحم`), matching across rich morphological variations across all 6,236 ayahs.
- **Offline Reminders:** Local scheduled notifications (`flutter_local_notifications` + `flutter_timezone`) for daily Quran reading and reflection routines, operating completely on-device without internet access. On first launch the app explains why, then asks once for notification and alarm permissions.

### 📿 Digital Tasbeeh & Istighfar Sanctuary
- **Simplified Dual Sections:** Direct switching between **Istighfar** (Seeking Forgiveness) and **Tasbeeh** (Glorification).
- **Jitter-Free Fixed Display:** Card height is fixed to eliminate visual bouncing when stepping through supplications.
- **49 Curated Authentic Formulas:** 20 Istighfar formulas and 29 Tasbeeh/Tahmeed/Takbeer/Salawat formulas.
- **Flexible Target Cycles & Smart Auto-Counter:** Supports preset targets (33, 100) or open count, with **smart dynamic auto-counting** calibrated to supplication word length, fine-tuning pace controls (+ / -), and automatic transition to the next dhikr upon target completion.

### 📚 Books & Booklets Library
- **«ملازم هدي القرآن الكريم» (86 Unabridged Booklets):** Complete library of lectures and Quranic guidance booklets by Sayyed Hussein Badreddin Al-Houthi, categorized with clean Arabic titles across series (*Ma'rifat Allah*, *Madih al-Quran*, *Ramadan Lessons*, Surah Studies, Worship & Supplications, and Major Discourses).
- **«تراث وأدعية أهل البيت (عليهم السلام)» (Ahlulbayt Heritage):** Public domain Islamic heritage works with in-app interactive reading and high-resolution companion PDF documents:
  - *Al-Sahifah Al-Sajjadiyah* (The Psalms of Islam by Imam Zayn al-Abidin).
  - *Risalat Al-Huquq* (The Treatise on Rights).
  - *Nahj Al-Balagha* (Peak of Eloquence: Sermons, Letters, and Wisdom of Imam Ali).
- **«علوم وتدبر القرآن الكريم» (Quranic Sciences & Reflection):** Open classical heritage works including *Akhlaq Hamalat Al-Quran* by Al-Ajurri, *Principles of Quranic Reflection*, and *Al-Tibyan* by Imam Al-Nawawi.
- **Pure-Dart Extensibility:** Built upon declarative, modular Dart registry files with detailed instructions, enabling any developer to easily add sections, PDF booklets, tasbeeh items, word meanings, duas, or ayah pathways without database schema changes; see [Content Guide](docs/CONTENT_GUIDE.md) and [Developer Guide](DEVELOPMENT_GUIDE.md#6-declarative-pure-dart-content-extension-architecture).

---

## 🔒 Privacy & Offline-First

Tadbeer is built with **Privacy by Design**:
- **Zero Data Collection:** No personal data, device identifiers, or analytics are ever collected, transmitted, or sold.
- **Offline-First:** Everything runs on the device without a connection. The only network use is audio recitation: `android.permission.INTERNET` is requested solely to stream or download recitations, on the user's request, from `cdn.islamic.network`, which receives the device's IP address and the requested file name only.
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

# Run all automated tests (653 tests, 86 test files)
flutter test

# Build production release packages
# One APK per CPU architecture (about a third of the size of a universal APK)
flutter build apk --release --split-per-abi
# The app bundle for Google Play, which serves each device only what it needs
flutter build appbundle --release
```

---

## 📁 Repository Structure

```text
tadbeer/
├── assets/                     # Bundled assets (~130MB, most of it the 604 Madinah Mushaf page fonts)
│   ├── fonts/                  # 5 Quran fonts + Amiri UI font (SIL OFL-1.1)
│   ├── icons/                  # Application icons & logo
│   └── quran/
│       ├── quran_data.json     # Verified Tanzil Uthmani text (2.0MB)
│       └── word_meanings.json  # 6,465 verified lexical entries, lightly diacritized
├── lib/
│   ├── app/                # App shell: bootstrap, navigation, localization, licenses
│   ├── core/               # Foundations that know no app data (imports nothing above it)
│   │   ├── design_system/  # Tokens, cards, buttons, menus, icons
│   │   ├── motion/         # Motion and reduced-motion handling
│   │   ├── theme/          # The five colour themes and ThemeData
│   │   └── utils/          # Arabic normalization, root search, text direction
│   ├── data/               # App data; depends only on core
│   │   ├── models/         # Data models and their repositories
│   │   ├── quran/          # Quran text, models and word meanings
│   │   └── storage/        # SQLite database and UserDataStore
│   ├── features/           # One folder per feature; screens/, widgets/, data/ once it grows past six files
│   │   ├── audio/          # Ayah-by-ayah recitation, background playback, downloads
│   │   ├── ayah_links/     # Thematic links between ayahs, network view
│   │   ├── backup/         # AES-256 encrypted backup and restore
│   │   ├── bookmarks/      # Bookmarks screen
│   │   ├── books/          # Books and booklets library, PDF reader
│   │   ├── continue/       # Continue where you left off
│   │   ├── daily/          # Ayah of the day
│   │   ├── duas/           # Quranic duas, morning and evening adhkar, Ahlulbayt duas
│   │   ├── focus/          # Focus (contemplation) mode
│   │   ├── highlights/     # Highlights screen
│   │   ├── home/           # Home screen
│   │   ├── journey/        # Reading journey, streak, weekly goals, Mushaf map
│   │   ├── memorization/   # Memorization with Leitner boxes
│   │   ├── more/           # The More tab
│   │   ├── notes/          # Reflection notes, PDF and journal export
│   │   ├── onboarding/     # First launch: name and theme
│   │   ├── pathways/       # Curated contemplation pathways
│   │   ├── qibla/          # Qibla direction (GPS and compass)
│   │   ├── quran/          # Madinah Mushaf (QCF), page view, ayah actions
│   │   ├── reminders/      # Reminders and the notification scheduler
│   │   ├── search/         # Unified search and its providers
│   │   ├── settings/       # Settings
│   │   ├── share/          # Ayah cards to share
│   │   ├── tadbeer/        # The four-question reflection pause
│   │   ├── tasbeeh/        # Istighfar and tasbeeh counter
│   │   ├── widgets/        # Home-screen widget
│   │   └── word_meanings/  # Word meanings explorer
│   ├── l10n/               # ARB translations (gen-l10n)
│   └── main.dart           # Entrypoint: bootstrap(), then runApp()
├── test/                       # Comprehensive test suite (653 tests, 86 files)
│   ├── design_system/          # Design system component tests (Cards, Buttons, Badges)
│   ├── motion/                 # Motion engine & reduced-motion accessibility tests
│   └── ...                     # Comprehensive unit & widget tests across all features
├── docs/                       # Official website (index.html) & privacy policy (privacy.html), GitHub Pages
│   ├── ARCHITECTURE_AND_CODE_GUIDE.md # Comprehensive engineering & architectural guide
│   └── CONTENT_GUIDE.md        # Content addition & extension manual for developers
├── DEVELOPMENT_GUIDE.md        # Technical developer & maintenance guide
├── DEVELOPMENT_GUIDE.ar.md     # Arabic technical developer guide
├── ATTRIBUTION.md              # Attribution statements & source details
├── THIRD_PARTY_NOTICES.md      # Full third-party license notices
├── LICENSE                     # MIT License
```

For detailed technical architecture, database schemas, and contribution guides, see:
- **[CONTENT_GUIDE.md](docs/CONTENT_GUIDE.md)** (Developer manual for adding duas, dhikrs, books, and word meanings)
- **[DEVELOPMENT_GUIDE.md](DEVELOPMENT_GUIDE.md)** (English)
- **[DEVELOPMENT_GUIDE.ar.md](DEVELOPMENT_GUIDE.ar.md)** (العربية)

---

## 📜 Licenses & Attribution

- **Application Code:** Licensed under the **[MIT License](LICENSE)**.
- **Quranic Text:** [Tanzil Project](https://tanzil.net/) (`CC-BY 3.0`).
- **Word Meanings:** [Quranpedia.net](https://quranpedia.net) under its [data license](https://quranpedia.net/dumps/LICENSE.md); contemporary works remain with their authors and publishers.
- **Typography:** All Quranic text and interface fonts are licensed under the **SIL Open Font License 1.1** (`OFL-1.1`), with the full text in `assets/fonts/OFL.txt`.
- **Madinah Mushaf fonts and layout:** King Fahd Complex and Quran Foundation, under their own terms.

Complete legal details and verbatim license texts are available in [ATTRIBUTION.md](ATTRIBUTION.md) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).