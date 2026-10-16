import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/ayah_links/ayah_link_repository.dart';
import 'package:tadbeer/features/bookmarks/bookmark_model.dart';
import 'package:tadbeer/features/bookmarks/bookmarks_screen.dart';
import 'package:tadbeer/features/highlights/highlight_model.dart';
import 'package:tadbeer/features/highlights/highlights_screen.dart';
import 'package:tadbeer/features/home/home_screen.dart';
import 'package:tadbeer/features/notes/note_model.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';
import 'package:tadbeer/features/reminders/reminder_model.dart';
import 'package:tadbeer/features/reminders/reminders_screen.dart';
import 'package:tadbeer/features/search/search_provider.dart';
import 'package:tadbeer/features/search/search_screen.dart';

class _CustomTestSearchProvider implements SearchProvider {
  final bool shouldThrow;

  const _CustomTestSearchProvider({this.shouldThrow = false});

  @override
  String get id => 'custom_test';

  @override
  String getSectionTitle(BuildContext context) => 'قسم تجريبي مخصص';

  @override
  IconData get icon => Icons.extension_rounded;

  @override
  Future<List<SearchResultItem>> search(
    String query,
    BuildContext context,
  ) async {
    if (shouldThrow) {
      throw Exception('Simulated custom search provider failure');
    }

    if (query.contains('تجريبي') || query.contains('test')) {
      return [
        SearchResultItem(
          id: 'custom_1',
          providerId: id,
          sectionTitle: getSectionTitle(context),
          title: 'عنصر بحث تجريبي',
          snippet: 'محتوى تجريبي للتحقق من قابلية التوسع',
          icon: icon,
          onTap: (_) {},
        ),
      ];
    }
    return [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File dataFile;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_unified_search_test_');
    dataFile = File('${tempDir.path}/test_user_data.json');
    await UserDataStore.instance.init(dataFile);
    await QuranRepository.instance.init();
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() {
    SearchRegistry.instance.resetToDefaults();
  });

  Widget buildTestWidget(Widget child) {
    return AppLocalizationScope(
      currentLanguage: AppLanguage.arabic,
      strings: const AppStrings(AppLanguage.arabic),
      onLanguageChanged: (_) {},
      child: MaterialApp(
        home: Directionality(textDirection: TextDirection.rtl, child: child),
      ),
    );
  }

  group('SearchRegistry Architecture & Extensibility Tests', () {
    test('Registry initializes with all 9 built-in providers', () {
      final registry = SearchRegistry.instance;
      expect(registry.providers.length, equals(9));
      expect(registry.getProvider('quran'), isNotNull);
      expect(registry.getProvider('notes'), isNotNull);
      expect(registry.getProvider('tadbeer'), isNotNull);
      expect(registry.getProvider('bookmarks'), isNotNull);
      expect(registry.getProvider('highlights'), isNotNull);
      expect(registry.getProvider('ayah_links'), isNotNull);
      expect(registry.getProvider('duas'), isNotNull);
      expect(registry.getProvider('reminders'), isNotNull);
      expect(registry.getProvider('word_meanings'), isNotNull);
    });

    test('Registry supports dynamic registration and unregistration', () {
      final registry = SearchRegistry.instance;
      const customProvider = _CustomTestSearchProvider();

      registry.register(customProvider);
      expect(registry.getProvider('custom_test'), isNotNull);
      expect(registry.providers.length, equals(10));

      registry.unregister('custom_test');
      expect(registry.getProvider('custom_test'), isNull);
      expect(registry.providers.length, equals(9));
    });

    testWidgets('Extensible: Custom provider integrates seamlessly into searchAll', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(const SizedBox()));
      final context = tester.element(find.byType(SizedBox));

      final registry = SearchRegistry.instance;
      registry.register(const _CustomTestSearchProvider());

      final results = await registry.searchAll('تجريبي', context);
      expect(
        results.any((r) => r.providerId == 'custom_test'),
        isTrue,
      );
    });

    testWidgets('Error isolation: A failing provider does not abort other providers', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(const SizedBox()));
      final context = tester.element(find.byType(SizedBox));

      final registry = SearchRegistry.instance;
      registry.register(
        const _CustomTestSearchProvider(shouldThrow: true),
      );

      final results = await registry.searchAll('الله', context);
      expect(results.isNotEmpty, isTrue);
      expect(
        results.any((r) => r.providerId == 'quran'),
        isTrue,
      );
    });

    testWidgets('Targeted provider search: providerId filter restricts execution', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(const SizedBox()));
      final context = tester.element(find.byType(SizedBox));

      final registry = SearchRegistry.instance;
      final results = await registry.searchAll(
        'الله',
        context,
        providerId: 'quran',
      );

      expect(results.isNotEmpty, isTrue);
      expect(
        results.every((r) => r.providerId == 'quran'),
        isTrue,
      );
    });
  });

  group('Built-in Providers Unit & Normalization Tests', () {
    testWidgets('NotesSearchProvider finds note with and without diacritics', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        await UserDataStore.instance.saveNote(
          id: 'test_note_search',
          type: NoteType.free,
          title: 'تَدَبُّرٌ فِي آيَاتِ الرَّحْمَةِ',
          content: 'وَاسْتَحْضَارُ لُطْفِ اللَّهِ بِنَا',
        );
      });

      await tester.pumpWidget(buildTestWidget(const SizedBox()));
      final context = tester.element(find.byType(SizedBox));

      final provider = SearchRegistry.instance.getProvider('notes')!;
      final results = await provider.search('الرحمة', context);
      expect(results.isNotEmpty, isTrue);
      expect(results.any((r) => r.id == 'note_test_note_search'), isTrue);
    });

    testWidgets('TadbeerSearchProvider finds reflections by answered questions', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        await UserDataStore.instance.saveTadbeer(
          surahNumber: 1,
          ayahNumber: 1,
          answers: {
            1: 'البسملة مفتاح لكل بركة وخير',
            2: '',
            3: '',
            4: '',
          },
        );
      });

      await tester.pumpWidget(buildTestWidget(const SizedBox()));
      final context = tester.element(find.byType(SizedBox));

      final provider = SearchRegistry.instance.getProvider('tadbeer')!;
      final results = await provider.search('مفتاح لكل بركة', context);
      expect(results.isNotEmpty, isTrue);
      expect(results.first.surahNumber, equals(1));
      expect(results.first.ayahNumber, equals(1));
    });

    testWidgets('BookmarksSearchProvider finds bookmark by surah and ayah', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        await UserDataStore.instance.putBookmark(
          BookmarkItem(
            id: 'test_bm_search',
            ayahId: 1,
            surahNumber: 1,
            ayahNumber: 2,
            page: 1,
            createdAt: DateTime.now(),
          ),
        );
      });

      await tester.pumpWidget(buildTestWidget(const SizedBox()));
      final context = tester.element(find.byType(SizedBox));

      final provider = SearchRegistry.instance.getProvider('bookmarks')!;
      final results = await provider.search('الفاتحة', context);
      expect(results.isNotEmpty, isTrue);
      expect(results.first.ayahNumber, equals(2));
    });

    testWidgets('HighlightsSearchProvider finds highlight by verse text', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        await UserDataStore.instance.putHighlight(
          HighlightItem(
            id: 'test_hl_search',
            ayahId: 1,
            surahNumber: 1,
            ayahNumber: 1,
            page: 1,
            colorIndex: 0,
            createdAt: DateTime.now(),
          ),
        );
      });

      await tester.pumpWidget(buildTestWidget(const SizedBox()));
      final context = tester.element(find.byType(SizedBox));

      final provider = SearchRegistry.instance.getProvider('highlights')!;
      final results = await provider.search('الرحمن الرحيم', context);
      expect(results.isNotEmpty, isTrue);
      expect(results.first.ayahNumber, equals(1));
    });

    testWidgets('AyahLinksSearchProvider finds link by title', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        final repo = AyahLinkRepository();
        await repo.createLink(
          title: 'رابط الصبر والشكر في القرآن',
          description: 'مجموعة من الآيات الجامعة بين فضيلتي الصبر والشكر',
        );
      });

      await tester.pumpWidget(buildTestWidget(const SizedBox()));
      final context = tester.element(find.byType(SizedBox));

      final provider = SearchRegistry.instance.getProvider('ayah_links')!;
      final results = await provider.search('الصبر والشكر', context);
      expect(results.isNotEmpty, isTrue);
    });

    testWidgets('RemindersSearchProvider finds reminder by title', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        await UserDataStore.instance.putReminder(
          ReminderItem(
            id: 'test_rem_search',
            title: 'تلاوة سورة الكهف يوم الجمعة',
            hour: 9,
            minute: 30,
            repeatMode: ReminderRepeatMode.daily,
            createdAt: DateTime.now(),
          ),
        );
      });

      await tester.pumpWidget(buildTestWidget(const SizedBox()));
      final context = tester.element(find.byType(SizedBox));

      final provider = SearchRegistry.instance.getProvider('reminders')!;
      final results = await provider.search('سورة الكهف', context);
      expect(results.isNotEmpty, isTrue);
      expect(results.first.title, contains('سورة الكهف'));
    });
  });

  group('UI Flow & Section Search Tests', () {
    testWidgets('SearchScreen renders input, filter chips, and executes query', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(const SearchScreen()));
      await tester.pumpAndSettle();

      // Verify search input field exists
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      // Verify filter chips exist
      expect(find.text('الكل'), findsOneWidget);
      expect(find.text('المصحف'), findsOneWidget);
      expect(find.text('الملاحظات'), findsOneWidget);
      expect(find.text('التدبر'), findsOneWidget);

      // Enter query "الرحمن"
      await tester.enterText(textFieldFinder, 'الرحمن');
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      // Should show results
      expect(find.byType(Card), findsWidgets);

      // Clear search via clear icon
      final clearIconFinder = find.byIcon(Icons.clear);
      expect(clearIconFinder, findsOneWidget);
      await tester.tap(clearIconFinder);
      await tester.pumpAndSettle();

      // Results should be cleared
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('BookmarksScreen local search filters bookmarks', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(const BookmarksScreen()));
      await tester.pumpAndSettle();

      // Search field is displayed since bookmarks exist
      expect(find.byType(TextField), findsOneWidget);

      // Filter by a non-matching query
      await tester.enterText(find.byType(TextField), 'كلمة_غير_موجودة_نهائيا');
      await tester.pumpAndSettle();

      // Empty results message displayed
      expect(find.text('لا توجد نتائج مطابقة'), findsOneWidget);
    });

    testWidgets('HighlightsScreen local search filters highlights', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(const HighlightsScreen()));
      await tester.pumpAndSettle();

      // Search field is displayed since highlights exist
      expect(find.byType(TextField), findsOneWidget);

      // Filter by non-matching query
      await tester.enterText(find.byType(TextField), 'لا_يوجد_أي_تطابق_هنا');
      await tester.pumpAndSettle();

      expect(find.text('لا توجد نتائج مطابقة'), findsOneWidget);
    });

    testWidgets('RemindersScreen local search filters reminders', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(const RemindersScreen()));
      await tester.pumpAndSettle();

      // Search field is displayed since reminders exist
      expect(find.byType(TextField), findsOneWidget);

      // Filter by non-matching query
      await tester.enterText(find.byType(TextField), 'تنبيه_غير_موجود_قطعا');
      await tester.pumpAndSettle();

      expect(find.text('لا توجد نتائج مطابقة'), findsOneWidget);
    });

    testWidgets('HomeScreen prominent search bar navigates to SearchScreen', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        await UserDataStore.instance.updateSettings(
          UserDataStore.instance.settings.copyWith(
            hideTadbeerIntroPermanently: true,
          ),
        );
      });

      await tester.pumpWidget(buildTestWidget(const HomeScreen()));
      await tester.pumpAndSettle();

      // Prominent search entry bar is rendered
      final searchBarFinder = find.text('ابحث في القرآن، الملاحظات، التدبر، والمزيد...');
      expect(searchBarFinder, findsOneWidget);

      // Tap global search bar
      await tester.tap(searchBarFinder);
      await tester.pumpAndSettle();

      // Navigated to SearchScreen
      expect(find.byType(SearchScreen), findsOneWidget);
    });

    testWidgets('HomeScreen top bar does not render search button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(const HomeScreen()));
      await tester.pumpAndSettle();

      // Top bar search button was removed per user request
      final topBarSearchFinder = find.byTooltip('البحث');
      expect(topBarSearchFinder, findsNothing);
    });

    testWidgets('HomeScreen tune filter icon opens filter bottom sheet', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(const HomeScreen()));
      await tester.pumpAndSettle();

      final tuneIconFinder = find.byIcon(Icons.tune_rounded);
      expect(tuneIconFinder, findsOneWidget);

      await tester.tap(tuneIconFinder);
      await tester.pumpAndSettle();

      // Bottom sheet with title is displayed
      expect(find.text('تصفية نطاق البحث'), findsOneWidget);
    });

    testWidgets('SearchScreen switching filter chips dynamically updates results', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(const SearchScreen()));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, 'الرحمن');
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsWidgets);

      // Tap "المصحف" FilterChip to filter by Quran
      final quranChipFinder = find.widgetWithText(FilterChip, 'المصحف');
      expect(quranChipFinder, findsOneWidget);
      await tester.tap(quranChipFinder);
      await tester.pumpAndSettle();

      // Results still show Quran matches under single section
      expect(find.byType(Card), findsWidgets);

      // Tap "المصحف" again to deselect back to All
      await tester.tap(quranChipFinder);
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('SearchScreen opens with initialProviderId and populates section', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(const SearchScreen(initialProviderId: 'notes')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SearchScreen), findsOneWidget);
      final notesChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'الملاحظات'),
      );
      expect(notesChip.selected, isTrue);
    });

    testWidgets('SearchScreen renders full Quran ayah snippet without maxLines truncation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(const SearchScreen()));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, 'بعوضة');
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      // Find Surah Al-Baqarah Ayah 26
      expect(find.textContaining('سورة البقرة · الآية ٢٦'), findsOneWidget);

      // Verify the ayah snippet Text widget has no maxLines truncation constraint
      final ayah = QuranRepository.instance.getAyah(2, 26);
      expect(ayah, isNotNull);
      final snippetFinder = find.text('﴿ ${ayah!.text} ﴾');
      expect(snippetFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(snippetFinder);
      expect(textWidget.maxLines, isNull);
    });
  });
}

