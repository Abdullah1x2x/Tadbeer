# 📖 Tadbeer (تَدْبِير) — Developer Guide

> **Practical technical guide for developers contributing to and maintaining the Tadbeer Flutter application.**  
> Derived strictly from the production codebase (`lib/`, `test/`, `assets/`).

---

## 1. Architectural Overview

Tadbeer is an **offline-first**, privacy-focused Flutter application designed for Quranic reflection (*Tadabbur*).

### Core Architectural Tenets
- **Offline-First:** Zero network dependencies. The app does not declare `android.permission.INTERNET`, includes zero telemetry or analytics SDKs, and runs completely locally.
- **Single Source of Truth:** `UserDataStore` (a singleton extending `ChangeNotifier`) acts as the central in-memory reactive cache. Modifying user data immediately updates $O(1)$ memory lookup maps, notifies UI listeners, and asynchronously persists changes to SQLite (`tadbeer_user_data.db`) and a JSON backup snapshot.
- **Responsive Quran Layout:** Digital Quran rendering built with `LayoutBuilder` and `SingleChildScrollView` to guarantee zero `RenderFlex` overflows across all device form factors (small phones, foldables, tablets in portrait/landscape, and dual-page spreads).
- **5 Open-Source Quranic Fonts:** Independent typography using SIL OFL-1.1 fonts (`AmiriQuran`, `ScheherazadeNew`, `NotoNaskhArabic`, `Lateef`, `Harmattan`).

```text
[UI Widgets] ──▶ [Domain Repositories] ──▶ [UserDataStore (ChangeNotifier)]
                                                    │
                   ┌────────────────────────────────┴────────────────────────────────┐
                   ▼                                                                 ▼
      [In-Memory Cache & UI Repaints]                                [Local SQLite: tadbeer_user_data.db]
```

---

## 2. Quick Start & Toolchain

### Requirements
- **Flutter SDK:** `>=3.22.0`
- **Dart SDK:** `^3.4.0`
- **Primary Targets:** Android & iOS (Linux, macOS, and Windows supported for local development and test automation via `sqflite_common_ffi`).

### Common Commands

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run static analysis (must report 0 issues)
dart analyze

# 3. Run automated tests (210 tests across 24 test files - 100% passing)
flutter test

# 4. Run application in debug mode
flutter run

# 5. Build release packages
flutter build apk --release
flutter build appbundle --release
```

---

## 3. Codebase File Map (`lib/` — 64 Files)

```text
lib/
├── app/                              # Application bootstrap & theming (3 files)
│   ├── app.dart                      # Root TadbeerApp widget & navigator key
│   ├── localization.dart             # Dual-language string tables (Arabic & English)
│   └── theme.dart                    # AppColors, typography, and theme definitions
│
├── core/                             # Core infrastructure & shared services (8 files)
│   ├── services/
│   │   ├── backup_crypto_service.dart # AES-256 backup encryption, compression & verification
│   │   └── local_reminder_service.dart# Offline scheduled notification service
│   ├── storage/
│   │   ├── user_database.dart         # Local SQLite manager (tadbeer_user_data.db)
│   │   └── user_data_store.dart       # Reactive in-memory cache (ChangeNotifier singleton)
│   └── utils/
│       ├── arabic_root_search_helper.dart # Root extraction & morphological matcher
│       ├── arabic_search_normalizer.dart  # Diacritic stripping & Arabic normalization
│       ├── note_pdf_exporter.dart        # Formatted single-note PDF exporter
│       └── tadbeer_journal_exporter.dart # Reflection journal exporter (PDF & Markdown)
│
├── features/                         # Feature domain modules (52 files)
│   ├── ayah_links/                   # Thematic verse relationship graph (11 files)
│   │   ├── ayah_link_detail_screen.dart, ayah_link_model.dart, ayah_link_repository.dart
│   │   ├── ayah_links_screen.dart, curated_pathways.dart
│   │   ├── views/ (ayah_link_network_view.dart, ayah_link_ordered_view.dart)
│   │   └── widgets/ (add_verse, picker, qr_dialog, create_link)
│   ├── backup/                       # Encrypted backup UI (backup_screen.dart)
│   ├── bookmarks/                    # Reading bookmarks (model, repo, screen - 3 files)
│   ├── duas/                         # Comprehensive Duas & Adhkar module (13 files)
│   │   ├── duas_screen.dart          # Organized main hub for all duas & adhkar sections
│   │   ├── quran_dua.dart, quran_duas_repository.dart, quran_duas_screen.dart, quran_dua_card.dart # 88 Quranic Duas
│   │   ├── adhkar_model.dart, adhkar_repository.dart, morning_evening_adhkar_screen.dart # Morning & Evening Adhkar
│   │   ├── ahlulbayt_dua_model.dart, ahlulbayt_duas_repository.dart # Ahlulbayt & Sahifah Sajjadiyah repo
│   │   ├── ahlulbayt_duas_screen.dart, ahlulbayt_dua_reader_screen.dart # Ahlulbayt duas browser & reader
│   │   └── sunnah_duas_repository.dart, general_duas_list_screen.dart # Prophetic & Comprehensive Duas
│   ├── home/                         # Home dashboard & resume banner (home_screen.dart)
│   ├── notes/                        # Reflection notes (model, repo, editor, screen - 4 files)
│   ├── quran/                        # Mushaf rendering engine & page data (8 files)
│   │   ├── data/ (quran_models.dart, quran_repository.dart)
│   │   ├── screens/ (quran_page_view.dart, quran_screen.dart)
│   │   └── widgets/ (ayah_action_sheet, quran_side_menu, surah_header_banner, word_meanings_panel)
│   ├── reminders/                    # Offline reading reminders (model, screen - 2 files)
│   ├── search/                       # Unified search system (providers, registry, screen - 3 files)
│   ├── settings/                     # Appearance, font sizing/family, about (model, screen - 2 files)
│   ├── tadbeer/                      # 4-prompt reflection worksheet (model, intro, sheet - 3 files)
│   ├── tasbeeh/                      # Electronic tasbeeh & Istighfar counter (model, repo, screen - 3 files)
│   └── word_meanings/                # Word meanings lexicon browser (word_meanings_screen.dart)
│
└── main.dart                         # Entrypoint & asynchronous engine bootstrap
```

---

## 4. Key Subsystems

### 4.1. Responsive Quran Engine (`lib/features/quran/`)
- **Page Renderer (`QuranPageView`):** Renders all 604 pages from verified Tanzil Uthmani text (`assets/quran/quran_data.json`).
- **Zero-Overflow Layout:** Combines `LayoutBuilder` with `SingleChildScrollView`, `ConstrainedBox(minHeight: constraints.maxHeight)`, and `IntrinsicHeight`. When content fits, it naturally expands to fill the page; when font sizes are enlarged (up to 32pt) or rotated to landscape, text smoothly scrolls vertically without triggering `RenderFlex overflow`.
- **Dual-Page Spread:** On wide screens (`width >= 900`), automatically renders two adjacent pages side-by-side with an authentic center divider.
- **Typography:** Supports 5 selectable SIL OFL-1.1 fonts (`AmiriQuran`, `ScheherazadeNew`, `NotoNaskhArabic`, `Lateef`, `Harmattan`) via `UserDataStore.instance.setQuranFontFamily()`.
- **Highlighting:** Multi-word continuous highlights are rendered behind text using custom painter `AyahHighlightPainter`.

### 4.2. Local Database & Storage (`lib/core/storage/`)
Managed by `UserDatabase` in SQLite file `tadbeer_user_data.db` (`databaseVersion = 1`):
1. `reading_position`: Stores current page, surah, and ayah (single row invariant: `id = 1`).
2. `notes`: Reflection notes keyed by UUID.
3. `bookmarks`: Verses bookmarked for quick access.
4. `highlights`: Verses highlighted with color index (`0..3`).
5. `reminders`: Scheduled reading reminder configurations.
6. `ayah_links`: Thematic verse link networks and metadata.
7. `tadbeer_items`: 4-prompt structured reflection responses.
8. `tadabbur_items`: Dual-write fallback compatibility table.
9. `user_settings`: Key-value application preferences.

### 4.3. Encrypted Backup Container (`.quranbackup`)
Managed by `BackupCryptoService`:
- **Format:** Self-contained JSON container with Base64 fields: `magic`, `version`, `salt`, `iv`, `checksum`, and `cipher`.
- **Key Derivation:** Cryptographically secure 16-byte random salt and 16-byte IV; 256-bit AES key derived via `SHA-256(password + salt)`.
- **Cipher:** AES-256 in CBC mode.
- **Compression & Integrity:** Payload is compressed using Gzip, with pre-compression SHA-256 checksum validation preventing corrupt or tampered restoration.

### 4.4. Quranic Word Meanings (`assets/quran/word_meanings.json`)
- **Dataset:** 6,465 approved single-word lexical entries covering all 604 pages and 114 surahs with 100% coverage.
- **Single-Word Invariant:** Every entry strictly satisfies `!word.contains(' ')` (no multi-word compounds).
- **License:** Sourced from Quranpedia.net (2026-10-10) under CC0 1.0 Public Domain.

### 4.5. Unified Search System (`lib/features/search/`)
- Driven by `SearchRegistry` querying 9 domains concurrently via `Future.wait` with per-provider `try/catch` error isolation:
  - Quran Ayahs, Reflection Notes, Tadbeer Pauses, Bookmarks, Highlights, Ayah Links, Duas, Reminders, and Word Meanings.
- **Root Search:** Supports morphological root search via `جذر:XXX` syntax (e.g. `جذر:صبر`).
- **Normalization:** All search matching utilizes `ArabicSearchNormalizer.normalize()`.

### 4.6. Digital Tasbeeh & Istighfar Sanctuary (`lib/features/tasbeeh/`)
- **Direct Dual Sections (`DhikrSection`):** Clean separation between **Istighfar** (`DhikrSection.istighfar`) and **Tasbeeh** (`DhikrSection.tasbeeh`).
- **Fixed Display Card Dimensions (`_buildFixedDhikrCard`):** Guaranteed fixed height to eliminate jitter or layout jumps when navigating between dhikrs.
- **Curated Dhikr Catalog (49 Authentic Formulas):** 20 Istighfar formulas and 29 Tasbeeh/Tahmeed/Takbeer/Salawat formulas.
- **State Repository (`TasbeehRepository`):** Manages round counting, target cycles, daily counts, lifetime tallies, and auto-advance state locally in `tadbeer_tasbeeh_state.json`.
- **Easy Switching & Gestures:** Next/Previous buttons, directional chips, and one-tap copy with SnackBar confirmation.

### 4.7. Books & Booklets Library (`lib/features/books/`)
- **Curated Sections Included in App:**
  1. **Sayyed Hussein Al-Houthi Booklets («ملازم السيد حسين الحوثي»):** 86 unabridged booklets and lectures from the Quranic guidance series, safely organized under `assets/books/malazem/` to guarantee smooth builds across Android, iOS, and Linux.
  2. **Ahlulbayt Heritage («تراث وأدعية أهل البيت (عليهم السلام)»):** Open Islamic heritage books with in-app interactive reading and companion high-resolution PDF attachments: **Al-Sahifah Al-Sajjadiyah**, **Risalat Al-Huquq**, and **Nahj Al-Balagha**.
  3. **Quranic Sciences & Reflection («علوم وتدبر القرآن الكريم»):** Open public heritage works including **Akhlaq Hamalat Al-Quran** by Al-Ajurri, **Qawaid Wa Usul fi Tadabbur Al-Quran**, and **Al-Tibyan fi Adab Hamalat Al-Quran** by Imam Al-Nawawi.
- **Developer Extensibility (`lib/features/books/curated_books.dart`):** Easily declare new sections and books in Dart code via `BookSectionConfig` and `BookConfig` with PDF attachments, text files, or in-code chapters (`BookChapter`).
- **Reader & Document Viewer (`BookReaderScreen`):** Native interactive reading for chapters (font scaling, chapter index, copying) and external opening / sharing for PDF documents with automatic clean Arabic file naming.

---

## 5. Coding & Contribution Guidelines

1. **Documentation Standard:** Every class, method, getter, and helper must include an accurate Arabic `///` doc comment explaining its purpose. Place doc comments **before** annotations like `@override`.
2. **State Management:** Always read and update through `UserDataStore.instance`. Update in-memory lookups immediately, invoke `notifyListeners()`, and persist asynchronously.
3. **Responsive Invariance:** Any UI modifications in `QuranPageView` must be verified across small phones (320px width), tablets, and dual-page layouts to prevent `RenderFlex` overflows.
4. **Pre-Commit Verification:**
   ```bash
   dart analyze    # Must report "No issues found!"
   flutter test    # All 210 tests must pass
   ```
5. **Preserve Sanctity & Offline Guarantee:** Never introduce external network requests, third-party analytics, or unverified changes to Quranic datasets in `assets/quran/`.
