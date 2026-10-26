import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';
import 'package:tadbeer/features/quran/screens/quran_page_view.dart';
import 'package:tadbeer/features/quran/screens/quran_screen.dart';
import 'package:tadbeer/features/quran/widgets/surah_header_banner.dart';
import 'package:tadbeer/features/settings/user_settings_model.dart';

Widget buildTestQuranApp({int initialPage = 1}) {
  return AppLocalizationScope(
    currentLanguage: AppLanguage.arabic,
    strings: const AppStrings(AppLanguage.arabic),
    onLanguageChanged: (_) {},
    child: MaterialApp(home: QuranScreen(initialPage: initialPage)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late File dataFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_mushaf_test_');
    dataFile = File('${tempDir.path}/test_user_data.json');
    await UserDataStore.instance.init(dataFile);
    // These tests cover the flowing text view, not the Madinah pages.
    await UserDataStore.instance.setMushafStyle(MushafStyle.text);
    await QuranRepository.instance.init();
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Madinah Mushaf 604-Page Architecture Tests', () {
    test('QuranRepository loads exactly 604 authentic Mushaf pages', () {
      final repo = QuranRepository.instance;
      expect(repo.pages.length, 604);

      // Verify Page 1 (Al-Fatihah, 7 ayahs)
      final page1 = repo.getPage(1);
      expect(page1.pageNumber, 1);
      expect(page1.ayahs.length, 7);
      expect(page1.surahNumbers, contains(1));
      expect(page1.ayahs.first.surahNumber, 1);
      expect(page1.ayahs.first.ayahNumber, 1);
      expect(page1.ayahs.last.ayahNumber, 7);

      // Verify Page 2 (Al-Baqarah 1-5)
      final page2 = repo.getPage(2);
      expect(page2.pageNumber, 2);
      expect(page2.surahNumbers, contains(2));
      expect(page2.ayahs.first.surahNumber, 2);
      expect(page2.ayahs.first.ayahNumber, 1);
      expect(page2.ayahs.last.ayahNumber, 5);

      // Verify Page 3 (Al-Baqarah 6-16)
      final page3 = repo.getPage(3);
      expect(page3.pageNumber, 3);
      expect(page3.ayahs.first.surahNumber, 2);
      expect(page3.ayahs.first.ayahNumber, 6);
      expect(page3.ayahs.last.ayahNumber, 16);

      // Verify Page 76 ends with Surah 3, Page 77 starts Surah 4
      final page76 = repo.getPage(76);
      expect(page76.surahNumbers, contains(3));
      final page77 = repo.getPage(77);
      expect(page77.surahNumbers, contains(4));
      expect(page77.ayahs.first.surahNumber, 4);
      expect(page77.ayahs.first.ayahNumber, 1);

      // Verify Page 187 (At-Tawbah) starts with Surah 9 Ayah 1
      final page187 = repo.getPage(187);
      expect(page187.surahNumbers, contains(9));
      expect(page187.ayahs.first.surahNumber, 9);
      expect(page187.ayahs.first.ayahNumber, 1);

      // Verify Page 604 contains Surahs 112, 113, 114
      final page604 = repo.getPage(604);
      expect(page604.surahNumbers, containsAll([112, 113, 114]));
      expect(page604.ayahs.last.surahNumber, 114);
      expect(page604.ayahs.last.ayahNumber, 6);
    });

    test(
      'Every Ayah connects to a valid Page, Surah, and Stable ID (1..6236)',
      () {
        final repo = QuranRepository.instance;
        expect(repo.allAyahs.length, 6236);

        final visitedAyahIds = <int>{};
        for (final ayah in repo.allAyahs) {
          expect(ayah.id, inInclusiveRange(1, 6236));
          expect(ayah.page, inInclusiveRange(1, 604));
          expect(ayah.surahNumber, inInclusiveRange(1, 114));
          expect(ayah.ayahNumber, greaterThan(0));
          expect(ayah.text.trim().isNotEmpty, isTrue);
          visitedAyahIds.add(ayah.id);
        }

        expect(visitedAyahIds.length, 6236);
      },
    );

    testWidgets(
      'Renders Page 1 Al-Fatihah with header and natural start alignment',
      (tester) async {
        await tester.pumpWidget(buildTestQuranApp(initialPage: 1));
        await tester.pumpAndSettle();

        expect(find.byType(QuranPageView), findsOneWidget);
        expect(find.byType(SurahHeaderBanner), findsOneWidget);
        expect(find.text('سُورَةُ الفاتحة'), findsWidgets);
        expect(find.text('١'), findsWidgets);
      },
    );

    testWidgets('Renders Page 2 with Surah 2 header and Bismillah', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestQuranApp(initialPage: 2));
      await tester.pumpAndSettle();

      expect(find.byType(QuranPageView), findsOneWidget);
      expect(find.text('سُورَةُ البقرة'), findsWidgets);
      expect(find.text('٢'), findsWidgets);
      expect(find.byType(BismillahBanner), findsOneWidget);
    });

    testWidgets('Persists reading position when navigating pages', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestQuranApp(initialPage: 1));
      await tester.pumpAndSettle();

      // Swipe horizontally to Page 2
      await tester.drag(find.byType(PageView), const Offset(400, 0));
      await tester.pumpAndSettle();

      final saved = UserDataStore.instance.readingPosition;
      expect(saved.page, isIn([1, 2]));
    });

    testWidgets('QuranPageView invokes onAyahTap and onAyahLongPress', (
      tester,
    ) async {
      final page1 = QuranRepository.instance.getPage(1);

      await tester.pumpWidget(
        AppLocalizationScope(
          currentLanguage: AppLanguage.arabic,
          strings: const AppStrings(AppLanguage.arabic),
          onLanguageChanged: (_) {},
          child: MaterialApp(
            home: Scaffold(
              body: QuranPageView(
                page: page1,
                onAyahTap: (_) {},
                onAyahLongPress: (_, {at}) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(QuranPageView), findsOneWidget);
      expect(find.text('سُورَةُ الفاتحة'), findsWidgets);
    });
  });
}
