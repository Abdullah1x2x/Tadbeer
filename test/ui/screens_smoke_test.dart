import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/app/main_shell.dart';
import 'package:tadbeer/app/theme.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/ayah_links/ayah_links_screen.dart';
import 'package:tadbeer/features/backup/backup_screen.dart';
import 'package:tadbeer/features/bookmarks/bookmarks_screen.dart';
import 'package:tadbeer/features/books/books_screen.dart';
import 'package:tadbeer/features/duas/ahlulbayt_duas_screen.dart';
import 'package:tadbeer/features/duas/duas_screen.dart';
import 'package:tadbeer/features/duas/morning_evening_adhkar_screen.dart';
import 'package:tadbeer/features/duas/quran_duas_screen.dart';
import 'package:tadbeer/features/focus/focus_mode_screen.dart';
import 'package:tadbeer/features/group_khatma/group_khatma_screen.dart';
import 'package:tadbeer/features/highlights/highlights_screen.dart';
import 'package:tadbeer/features/home/home_screen.dart';
import 'package:tadbeer/features/journey/journey_screen.dart';
import 'package:tadbeer/features/journey/mushaf_map_screen.dart';
import 'package:tadbeer/features/memorization/memorization_screen.dart';
import 'package:tadbeer/features/more/more_screen.dart';
import 'package:tadbeer/features/notes/note_editor_screen.dart';
import 'package:tadbeer/features/notes/notes_screen.dart';
import 'package:tadbeer/features/pathways/guided_pathways_screen.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';
import 'package:tadbeer/features/quran/screens/quran_screen.dart';
import 'package:tadbeer/features/reminders/reminders_screen.dart';
import 'package:tadbeer/features/search/search_screen.dart';
import 'package:tadbeer/features/settings/settings_screen.dart';
import 'package:tadbeer/features/tasbeeh/tasbeeh_screen.dart';
import 'package:tadbeer/features/word_meanings/word_meanings_screen.dart';

/// Opens every screen at a small and a regular phone size, in light and dark
/// mode, with some user data present, and fails on any error or overflow.
/// Loads the app's real Arabic fonts; the default test font draws every
/// glyph as a wide box, which would report overflows that never happen.
Future<void> _loadAppFonts() async {
  const families = {
    'Amiri': ['Amiri-Regular.ttf', 'Amiri-Bold.ttf'],
    'IBMPlexSansArabic': [
      'IBMPlexSansArabic-Regular.ttf',
      'IBMPlexSansArabic-Medium.ttf',
      'IBMPlexSansArabic-SemiBold.ttf',
      'IBMPlexSansArabic-Bold.ttf',
    ],
    'ScheherazadeNew': ['ScheherazadeNew-Regular.ttf'],
    'NotoNaskhArabic': ['NotoNaskhArabic-Regular.ttf'],
    'Harmattan': ['Harmattan-Regular.ttf'],
    'Lateef': ['Lateef-Regular.ttf'],
    'AmiriQuran': ['AmiriQuran-Regular.ttf'],
  };
  for (final e in families.entries) {
    final loader = FontLoader(e.key);
    for (final file in e.value) {
      loader.addFont(rootBundle.load('assets/fonts/$file'));
    }
    await loader.load();
  }
}

void main() {
  late Directory tempDir;

  setUpAll(_loadAppFonts);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_smoke_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
    final store = UserDataStore.instance;
    await store.startKhatma(30);
    await store.recordPageRead(192);
    await store.toggleBookmark(QuranRepository.instance.getAyah(2, 255)!);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  final screens = <String, Widget Function()>{
    'MainShell': () => const MainShell(),
    'Home': () => const HomeScreen(),
    'Quran': () => const QuranScreen(initialPage: 1),
    'Tasbeeh': () => const TasbeehScreen(),
    'Duas': () => const DuasScreen(),
    'QuranDuas': () => const QuranDuasScreen(),
    'Adhkar': () => const MorningEveningAdhkarScreen(),
    'AhlulbaytDuas': () => const AhlulbaytDuasScreen(),
    'More': () => const MoreScreen(),
    'Notes': () => const NotesScreen(),
    'NoteEditor': () => const NoteEditorScreen(),
    'Search': () => const SearchScreen(),
    'Bookmarks': () => const BookmarksScreen(),
    'Highlights': () => const HighlightsScreen(),
    'Reminders': () => const RemindersScreen(),
    'Backup': () => const BackupScreen(),
    'Settings': () => const SettingsScreen(),
    'Journey': () => const JourneyScreen(),
    'MushafMap': () => const MushafMapScreen(),
    'Pathways': () => const GuidedPathwaysScreen(),
    'Memorization': () => const MemorizationScreen(),
    'WordMeanings': () => const WordMeaningsScreen(),
    'AyahLinks': () => const AyahLinksScreen(),
    'Books': () => const BooksScreen(),
    'GroupKhatma': () => const GroupKhatmaScreen(),
    'Focus': () =>
        FocusModeScreen(startAyah: QuranRepository.instance.getAyah(2, 255)!),
  };

  const sizes = [Size(360, 640), Size(412, 915)];

  for (final entry in screens.entries) {
    for (final dark in [false, true]) {
      for (final size in sizes) {
        final mode = dark ? 'dark' : 'light';
        testWidgets(
          '${entry.key} renders cleanly ($mode, ${size.width.toInt()}x${size.height.toInt()})',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);

            await tester.pumpWidget(
              AppLocalizationScope(
                currentLanguage: AppLanguage.arabic,
                strings: const AppStrings(AppLanguage.arabic),
                onLanguageChanged: (_) {},
                child: MaterialApp(
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                  home: Directionality(
                    textDirection: TextDirection.rtl,
                    child: entry.value(),
                  ),
                ),
              ),
            );
            // Some screens animate forever, so pump a fixed time instead of
            // waiting to settle.
            await tester.pump(const Duration(seconds: 1));
            await tester.pump(const Duration(seconds: 1));
            expect(tester.takeException(), isNull);

            // Unmount so timers and looping animations stop.
            await tester.pumpWidget(const SizedBox());
            await tester.pump(const Duration(seconds: 7));
          },
        );
      }
    }
  }
}
