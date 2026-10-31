# 📖 Tadbeer (تَدْبِير) — Developer Guide

> **Practical technical guide for developers contributing to and maintaining the Tadbeer Flutter application.**  
> Derived strictly from the production codebase (`lib/`, `test/`, `assets/`).

---

> For the complete walkthrough of every project file, see the [project guide](docs/PROJECT_GUIDE.md) (Arabic).

## 1. Architectural Overview

Tadbeer is an **offline-first**, privacy-focused Flutter application designed for Quranic reflection (*Tadabbur*).

### Core Architectural Tenets
- **Offline-First:** All core reading, reflection, notes, bookmarks, and search run 100% locally with zero server reliance. The network permission (`android.permission.INTERNET`) is used strictly for streaming Quran recitation audio, with zero telemetry, analytics SDKs, or external ads.
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
- **Flutter SDK:** `3.47.6`
- **Dart SDK:** `^3.4.0`
- **Primary Targets:** Android & iOS (Linux, macOS, and Windows supported for local development and test automation via `sqflite_common_ffi`).

### Common Commands

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run static analysis (must report 0 issues)
dart analyze

# 3. Run automated tests (659 tests across 86 test files)
flutter test

# 4. Run application in debug mode
flutter run

# 5. Build release packages
# One APK per CPU architecture (about a third of the size of a universal APK)
flutter build apk --release --split-per-abi
# The app bundle for Google Play, which serves each device only what it needs
flutter build appbundle --release
```

---

## 3. Codebase Map (`lib/`)

Dependencies point one way only: `features` → `data` → `core`. `core` and `data` never import a feature; where the data layer needs a feature (the reminder scheduler), main wires it in through an interface (`ReminderScheduler`).

```text
lib/
├── app/                # App shell: bootstrap, navigation, localization, licenses
├── core/               # Foundations that know no app data (imports nothing above it)
│   ├── design_system/  # Tokens, cards, buttons, menus, icons
│   ├── motion/         # Motion and reduced-motion handling
│   ├── theme/          # The five colour themes and ThemeData
│   └── utils/          # Arabic normalization, root search, text direction
├── data/               # App data; depends only on core
│   ├── models/         # Data models and their repositories
│   ├── quran/          # Quran text, models and word meanings
│   └── storage/        # SQLite database and UserDataStore
├── features/           # One folder per feature; screens/, widgets/, data/ once it grows past six files
│   ├── audio/          # Ayah-by-ayah recitation, background playback, downloads
│   ├── ayah_links/     # Thematic links between ayahs, network view
│   ├── backup/         # AES-256 encrypted backup and restore
│   ├── bookmarks/      # Bookmarks screen
│   ├── books/          # Books and booklets library, PDF reader
│   ├── continue/       # Continue where you left off
│   ├── daily/          # Ayah of the day
│   ├── duas/           # Quranic duas, morning and evening adhkar, Ahlulbayt duas
│   ├── focus/          # Focus (contemplation) mode
│   ├── highlights/     # Highlights screen
│   ├── home/           # Home screen
│   ├── journey/        # Reading journey, streak, weekly goals, Mushaf map
│   ├── memorization/   # Memorization with Leitner boxes
│   ├── more/           # The More tab
│   ├── notes/          # Reflection notes, PDF and journal export
│   ├── onboarding/     # First launch: name, theme, tour and guides
│   ├── pathways/       # Curated contemplation pathways
│   ├── qibla/          # Qibla direction (GPS and compass)
│   ├── quran/          # Madinah Mushaf (QCF), page view, ayah actions
│   ├── reminders/      # Reminders and the notification scheduler
│   ├── search/         # Unified search and its providers
│   ├── settings/       # Settings
│   ├── share/          # Ayah cards to share
│   ├── tadbeer/        # The four-question reflection pause
│   ├── tasbeeh/        # Istighfar and tasbeeh counter
│   ├── widgets/        # Home-screen widget
│   └── word_meanings/  # Word meanings explorer
├── l10n/               # ARB translations (gen-l10n)
└── main.dart           # Entrypoint: bootstrap(), then runApp()
```

---

## 4. Key Subsystems

### 4.1. Responsive Quran Engine (`lib/features/quran/`)
- **Page Renderer (`QuranPageView`):** Renders all 604 pages from verified Tanzil Uthmani text (`assets/quran/quran_data.json`).
- **Zero-Overflow Layout:** Combines `LayoutBuilder` with `SingleChildScrollView`, `ConstrainedBox(minHeight: constraints.maxHeight)`, and `IntrinsicHeight`. When content fits, it naturally expands to fill the page; when font sizes are enlarged (up to 32pt) or rotated to landscape, text smoothly scrolls vertically without triggering `RenderFlex overflow`.
- **Dual-Page Spread:** On wide screens (`width >= 900`), automatically renders two adjacent pages side-by-side with an authentic center divider.
- **Typography:** Supports 5 selectable SIL OFL-1.1 fonts (`AmiriQuran`, `ScheherazadeNew`, `NotoNaskhArabic`, `Lateef`, `Harmattan`) via `UserDataStore.instance.setQuranFontFamily()`.
- **Highlighting:** Multi-word continuous highlights are rendered behind text using custom painter `AyahHighlightPainter`.
- **Ayah Markers:** `_ayahMarkers` in `quran_page_parts.dart` builds the bookmark, note, reflection and memorization icons once for both renderers. The flowing page shows them as a badge after the rosette; the Madinah page (`QcfPageBody.markersFor`) draws them above the ayah number in a zero-size `WidgetSpan`, so the printed line keeps its width.
- **Large Screens in Part Files:** Builders that do not call `setState` live in private extensions beside their screen (`quran_page_parts.dart`, `quran_screen_dialogs.dart`, and likewise for tasbeeh, settings and the book reader).

### 4.2. Local Database & Storage (`lib/data/storage/`)
Managed by `UserDatabase` in SQLite file `tadbeer_user_data.db` (`databaseVersion = 3`):
1. `reading_position`: Stores current page, surah, and ayah (single row invariant: `id = 1`).
2. `notes`: Reflection notes keyed by UUID.
3. `bookmarks`: Verses bookmarked for quick access.
4. `highlights`: Verses highlighted with color index (`0..3`).
5. `reminders`: Scheduled reading reminder configurations.
6. `ayah_links`: Thematic verse link networks and metadata.
7. `tadbeer_items`: 4-prompt structured reflection responses.
8. `user_settings`: Key-value application preferences.

Version 3 retired `tadabbur_items`: reflections used to be written to it and to `tadbeer_items`. On upgrade, rows only the old table holds are copied with `INSERT OR IGNORE`, then the table is dropped.

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
- **Light Diacritics:** Meanings carry light tashkeel; search strips diacritics through `ArabicSearchNormalizer.normalize()`, so plain queries still match.
- **Order:** `QuranRepository` merges the JSON with `customWordMeanings` and sorts everything by surah, then ayah, keeping the file order within an ayah.

### 4.5. Unified Search System & Phonetic Normalization (`lib/features/search/`)
- Driven by `SearchRegistry` querying 11 domains concurrently via `Future.wait` with per-provider `try/catch` error isolation:
  - Quran Ayahs, Curated Heritage Books, Reflection Notes, Tadbeer Pauses, Bookmarks, Highlights, Ayah Links, Duas, Guided Pathways, Reminders, and Word Meanings.
- **Phonetic-to-Standard Arabic Query Normalization:** Via `ArabicSearchNormalizer.normalizeSearchQuery`, commonly mis-typed or phonetically spelled queries (e.g. `هازا`, `هاذه`, `ذالك`, `لكن`, `رحمن`, `صلوه/صلاه`) are normalized to standard Uthmani and modern orthographic forms strictly inside the search input pipeline. Crucially, the immutable Quranic and classical text corpora remain 100% intact.
- **Root Search:** Supports morphological root search via `جذر:XXX` syntax (e.g. `جذر:صبر`).
- **Normalization:** All search matching utilizes `ArabicSearchNormalizer.normalize()`.

### 4.6. Futuristic Design System & Motion Engine (`lib/core/design_system/` & `lib/core/motion/`)
- **Centralized Tokens (`AppTokens`):** Standardizes geometric radii (`radiusSm: 8`, `radiusMd: 14`, `radiusLg: 20`, `radiusXl: 28`), subtle multi-layered borders, and ambient drop shadows.
- **High-Precision Components:** `FuturisticCard` providing subtle gradients and focus states, tactile `FuturisticButton`, status indicators (`FuturisticBadge`), and micro-interactive `FuturisticIconButton`.
- **Unified Motion Engine (`AppMotion`):** Calibrated durations (`fast: 120ms`, `normal: 200ms`, `slow: 350ms`), cubic curves (`easeOutCubic`, `easeInOutCubic`), and `ScaleOnPress` micro-feedback.
- **Reduced Motion Compliance:** Respects `MediaQuery.disableAnimationsOf(context)` via `AppMotion.isReduceMotion(context)` to protect motion-sensitive readers.

### 4.7. Digital Tasbeeh & Istighfar Sanctuary (`lib/features/tasbeeh/`)
- **Direct Dual Sections (`DhikrSection`):** Clean separation between **Istighfar** (`DhikrSection.istighfar`) and **Tasbeeh** (`DhikrSection.tasbeeh`).
- **Fixed Display Card Dimensions (`_buildFixedDhikrCard`):** Guaranteed fixed height to eliminate jitter or layout jumps when navigating between dhikrs.
- **Curated Dhikr Catalog (49 Authentic Formulas):** 20 Istighfar formulas and 29 Tasbeeh/Tahmeed/Takbeer/Salawat formulas.
- **Consolidated Model & Repository (`TasbeehRepository`):** Co-located within `tasbeeh_model.dart`, managing round counting, target cycles, daily counts, lifetime tallies, and auto-advance state locally in `tadbeer_tasbeeh_state.json`.
- **Easy Switching & Gestures:** Next/Previous buttons, directional chips, and one-tap copy with SnackBar confirmation.

### 4.8. Books & Booklets Library (`lib/features/books/`)
- **Curated Sections Included in App:**
  1. **Sayyed Hussein Al-Houthi Quranic Guidance Booklets («ملازم هدي القرآن الكريم»):** 91 unabridged booklets and lectures from the Quranic guidance series, safely organized under `assets/books/malazem/` to guarantee smooth builds across Android, iOS, and Linux.
  2. **Ahlulbayt Heritage («تراث وأدعية أهل البيت (عليهم السلام)»):** Open Islamic heritage books with in-app interactive reading and companion high-resolution PDF attachments: **Al-Sahifah Al-Sajjadiyah**, **Risalat Al-Huquq**, and **Nahj Al-Balagha** (consolidated cleanly in `heritage_data.dart`).
  3. **Quranic Sciences & Reflection («علوم وتدبر القرآن الكريم»):** Open public heritage works including **Akhlaq Hamalat Al-Quran** by Al-Ajurri, **Qawaid Wa Usul fi Tadabbur Al-Quran**, and **Al-Tibyan fi Adab Hamalat Al-Quran** by Imam Al-Nawawi.
- **Developer Extensibility (`lib/features/books/data/curated_books.dart`):** Easily declare new sections and books in Dart code via `BookSectionConfig` and `BookConfig` with PDF attachments, text files, or in-code chapters (`BookChapter`).
- **Reader & Document Viewer (`BookReaderScreen`):** Native interactive reading for chapters (font scaling, chapter index, copying) and external opening / sharing for PDF documents with automatic clean Arabic file naming.

### 4.9. Recitation (`lib/features/audio/`)
- **`QuranAudio`:** `playFrom(ayah)` plays on through the surah and beyond; `playAyah(ayah)` plays one ayah and stops. Each request takes a number, so a newer request cancels an older one still loading.
- **No Stalls:** Loading the first file times out after `QuranAudio.loadTimeout` (20 s); an error stops the engine; `toggle()` restarts the ayah when the engine is idle; next/previous skip the reflection pause.
- **Background Playback:** `RecitationHandler` (audio_service) mirrors the player in the notification; its stop button closes the recitation through `onStop`.

### 4.10. Ayah of the Day & Home-Screen Widget (`lib/features/daily/`, `lib/features/widgets/`)
- **Pool:** `AyahOfTheDay.pool` holds every ayah of at most `maxLetters` (170) letters: 6,128 of 6,236, all 114 surahs. Each day starts with a curated ayah from the Quranic duas or the pathways.
- **Widget:** `HomeWidgetSync` renders each ayah to an image (`WidgetAyahImage`, wrap width 300 for larger text). The picker shows `tadbeer_widget_preview.xml`, with the ayah in `res/font/amiri_quran.ttf` and sample khatma values.

### 4.11. Startup Permissions (`lib/features/reminders/startup_permissions.dart`)
- After onboarding, `MainShell` calls `StartupPermissions.askOnce`: an in-app explanation, then the notification and exact-alarm requests, once per install. Location stays on the Qibla screen.

---

## 5. Coding & Contribution Guidelines

1. **Documentation Standard:** Every class, method, getter, and helper must include an accurate Arabic `///` doc comment explaining its purpose. Place doc comments **before** annotations like `@override`.
2. **State Management:** Always read and update through `UserDataStore.instance`. Update in-memory lookups immediately, invoke `notifyListeners()`, and persist asynchronously.
3. **Responsive Invariance:** Any UI modifications in `QuranPageView` must be verified across small phones (320px width), tablets, and dual-page layouts to prevent `RenderFlex` overflows.
4. **Pre-Commit Verification:**
   ```bash
   dart analyze    # Must report "No issues found!"
   flutter test    # All tests must pass
   ```
5. **Interface Text:** Every visible string goes in `lib/l10n/app_ar.arb` and `app_en.arb` (then `flutter gen-l10n`) and is read through `context.l10n`; no inline `isArabic ? … : …` text. Pass numbers as `int` and let `AppStrings` localize the digits.
6. **Preserve Sanctity & Offline Guarantee:** Never introduce external network requests, third-party analytics, or unverified changes to Quranic datasets in `assets/quran/`.

---

## 6. Declarative Pure-Dart Content Extension Architecture

> 💡 **For the unified, comprehensive reference manual covering all models and content registries with full code examples, see:**  
> **[`docs/CONTENT_GUIDE.md`](docs/CONTENT_GUIDE.md)**.

The codebase has been refactored to eliminate hardcoded UI checks and burdensome database migrations for static and curated content. All extensible features are exposed via **strongly typed, modular Dart configuration files** equipped with detailed Arabic developer guidelines in their header doc comments.

### 6.1. Adding Sections, Books, & Booklets (`lib/features/books/data/curated_books.dart`)

Developers can declare new sections, associate companion PDFs or text files, or write interactive in-app chapters directly in Dart:

#### A. Adding a New Section with a PDF Booklet:
1. Place the PDF file in `assets/books/` (e.g. `assets/books/tafseer_fatiha.pdf`).
2. Add the section entry to `curatedBookSections` in `curated_books.dart`:

```dart
BookSectionConfig(
  name: 'ملازم التدبر',
  description: 'ملازم دورات التدبر وتفسير الآيات',
  icon: Icons.folder_special_rounded,
  color: Color(0xFF2E6F4D),
  countLabel: 'ملزمة مدارسة معتمدة',
  seriesFilterList: ['سلسلة مدارسة السور', 'سلسلة المفاهيم'],
  books: [
    BookConfig(
      id: 'tadbeer_fatiha_guide',
      title: 'ملزمة مدارسة سورة الفاتحة',
      subtitle: 'دليل عملي في تدبر السبع المثاني',
      author: 'مركز تدبر',
      assetPath: 'assets/books/tafseer_fatiha.pdf',
      estimatedMinutes: 30,
      icon: Icons.auto_stories_rounded,
      badgeText: 'ملزمة مصورة PDF',
      badgeColor: Color(0xFF1B5E20),
    ),
  ],
),
```

#### B. Adding In-Code Chapters (No External File Needed):
```dart
BookConfig(
  id: 'custom_book_1',
  title: 'مفاتيح تدبر القرآن الكريم',
  subtitle: 'قواعد منهجية في فهم الذكر الحكيم',
  author: 'د. خالد السبت',
  estimatedMinutes: 40,
  icon: Icons.menu_book_rounded,
  badgeText: 'قراءة نصية تفاعلية',
  badgeColor: Color(0xFF1E3A8A),
  chapters: [
    BookChapter(
      title: 'الفصل الأول: معنى التدبر وغايته',
      summary: 'الفرق بين التلاوة المجردة والتدبر العملي',
      content: 'Chapter body text goes here...',
    ),
  ],
),
```

---

### 6.2. Adding Istighfar & Tasbeeh Formulas (`lib/features/tasbeeh/data/curated_dhikrs.dart`)

To add a formula to the electronic counter, append an item to `curatedDhikrs`:

```dart
// 1. Adding an Istighfar formula:
TasbeehDhikr(
  id: 'istighfar_custom_1',
  arabicText: 'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ الَّذِي لا إِلَهَ إِلا هُوَ الرَّحْمَنُ الرَّحِيمُ وَأَتُوبُ إِلَيْهِ',
  englishTranslation: 'I seek forgiveness from Allah...',
  virtue: 'Documented virtue and reward...',
  category: 'استغفار',
  defaultTarget: 70, // 33, 70, or 100
  section: DhikrSection.istighfar, // Automatically routes to Istighfar tab
),

// 2. Adding a Tasbeeh formula:
TasbeehDhikr(
  id: 'tasbeeh_custom_1',
  arabicText: 'سُبْحَانَ اللَّهِ وَالْحَمْدُ لِلَّهِ وَلا إِلَهَ إِلا اللَّهُ وَاللَّهُ أَكْبَرُ وَلا حَوْلَ وَلا قُوَّةَ إِلا بِاللَّهِ',
  englishTranslation: 'Glory be to Allah, and all praise is due to Allah...',
  virtue: 'Virtue and spiritual benefit...',
  category: 'تسبيح',
  defaultTarget: 33,
  section: DhikrSection.tasbeeh, // Automatically routes to Tasbeeh tab
),
```

---

### 6.3. Adding & Correcting Quran Word Meanings (`lib/data/quran/custom_word_meanings.dart`)

Instead of manually editing the 1.1MB `word_meanings.json` file, add entries to `customWordMeanings`:

```dart
CustomWordMeaningConfig(
  surah: 1, // Surah number (1 to 114)
  ayah: 2,  // Ayah number
  word: 'الْحَمْدُ', // Quranic word
  meaning: 'الثناء بالجميل على جهة التبجيل والتعظيم لله عز وجل وحده.',
  sourceName: 'السراج في بيان غريب القرآن', // Optional lexicon reference
),
```
*`QuranRepository` automatically maps the entry to the correct Mushaf page (1–604) and indexes it into the global search engine, word meanings explorer, and the slide-up Mushaf panel.*

---

### 6.4. Adding & Updating Duas and Adhkar (`lib/features/duas/`)

Duas repositories are cleanly separated into dedicated source files:

1. **Ahlulbayt & Sahifah Sajjadiyah Duas (`lib/features/duas/data/ahlulbayt_duas_repository.dart`):**  
   Append to `defaultDuas`:
   ```dart
   AhlulbaytDua(
     id: 'dua_custom',
     title: 'Supplication Title',
     attributedTo: 'Imam Name (AS)',
     category: 'Category',
     summary: 'Context and timing summary...',
     content: 'Full Arabic diacritized text as a single unified piece...',
   ),
   ```
2. **Prophetic & Comprehensive Duas (`lib/features/duas/data/sunnah_duas_repository.dart`):**  
   Append to `sunnahDuas` or `jawamiDuas`:
   ```dart
   GeneralDuaItem(
     id: 'sunnah_custom',
     title: 'Title',
     text: 'Dua text...',
     occasion: 'Occasion or situation',
     source: 'Hadith Reference',
     isSunnah: true,
   ),
   ```
3. **Morning & Evening Adhkar (`lib/features/duas/data/adhkar_repository.dart`):**  
   Append to `morningAdhkar` or `eveningAdhkar`:
   ```dart
   AdhkarItem(
     id: 'adhkar_custom',
     text: 'Adhkar text...',
     repeatCount: 3,
     virtue: 'Virtue description...',
     source: 'Reference',
   ),
   ```
4. **Quranic Duas Catalog (`lib/features/duas/data/quran_duas_repository.dart`):**  
   Append to `_catalog` via `_DuaCatalogEntry`:
   ```dart
   _DuaCatalogEntry(
     surahNumber: 2,
     startAyah: 201,
     endAyah: 201,
     text: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
     theme: DuaTheme.guidance,
   ),
   ```

---

### 6.5. Adding Thematic Ayah Pathways (`lib/features/ayah_links/data/curated_pathways.dart`)

To propose ready-to-import thematic pathways connecting verses across the Quran, append to `CuratedPathwaysRegistry.pathways`:

```dart
CuratedPathway(
  id: 'pathway_custom',
  title: 'سنة التدافع ونصرة الحق',
  description: 'Thematic reflection pathway exploring the divine law of check and balance.',
  category: 'السنن الإلهية',
  verses: [
    CuratedPathwayVerse(
      surah: 2,
      ayah: 251,
      note: 'Reflection prompt for verse 2:251...',
    ),
    CuratedPathwayVerse(
      surah: 22,
      ayah: 40,
      note: 'Reflection prompt for verse 22:40...',
    ),
  ],
),
```

*The pathway instantly appears in the Ayah Links screen, complete with topological graph views and one-tap import.*
