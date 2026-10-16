import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/app/theme.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/quran/data/quran_models.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';
import 'package:tadbeer/features/quran/screens/quran_page_view.dart';
import 'package:tadbeer/features/quran/widgets/surah_header_banner.dart';

Widget buildTestFrame(Widget child) {
  return AppLocalizationScope(
    currentLanguage: AppLanguage.arabic,
    strings: const AppStrings(AppLanguage.arabic),
    onLanguageChanged: (_) {},
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late File dataFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('visual_test_');
    dataFile = File('${tempDir.path}/test_user_data.json');
    await UserDataStore.instance.init(dataFile);
    await QuranRepository.instance.init();
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Responsive Mushaf Page Reader Visual & Structural Verification', () {
    testWidgets('Visual Verification: Page 1 (Al-Fatihah, framed)', (tester) async {
      final repo = QuranRepository.instance;
      final page1 = repo.getPage(1);
      expect(page1.ayahs.length, 7);
      expect(page1.ayahs.first.text, contains('بِسْمِ ٱللَّهِ'));

      await tester.pumpWidget(buildTestFrame(QuranPageView(pageNumber: 1)));
      await tester.pumpAndSettle();

      expect(find.byType(QuranPageView), findsOneWidget);
      expect(find.byType(SurahHeaderBanner), findsOneWidget);
      expect(find.text('سُورَةُ الفاتحة'), findsWidgets);
      expect(find.text('١'), findsWidgets);
      expect(find.textContaining('ٱلضَّآلِّينَ'), findsWidgets);
    });

    testWidgets('Visual Verification: Page 2 (Al-Baqarah 1-5, framed)', (tester) async {
      final repo = QuranRepository.instance;
      final page2 = repo.getPage(2);
      expect(page2.ayahs.length, 5);

      await tester.pumpWidget(buildTestFrame(QuranPageView(pageNumber: 2)));
      await tester.pumpAndSettle();

      expect(find.byType(QuranPageView), findsOneWidget);
      expect(find.byType(SurahHeaderBanner), findsOneWidget);
      expect(find.byType(BismillahBanner), findsOneWidget);
      expect(find.text('سُورَةُ البقرة'), findsWidgets);
      expect(find.text('٢'), findsWidgets);
      expect(find.textContaining('الٓمٓ'), findsWidgets);
      expect(find.textContaining('ٱلْمُفْلِحُونَ'), findsWidgets);
    });

    testWidgets('Visual Verification: Page 3 (Al-Baqarah 6-16, natural text flow)', (tester) async {
      final repo = QuranRepository.instance;
      final page3 = repo.getPage(3);
      expect(page3.ayahs.first.ayahNumber, 6);
      expect(page3.ayahs.last.ayahNumber, 16);

      await tester.pumpWidget(buildTestFrame(QuranPageView(pageNumber: 3)));
      await tester.pumpAndSettle();

      expect(find.byType(QuranPageView), findsOneWidget);
      // Continuous page does not begin a Surah, so no header banner
      expect(find.byType(SurahHeaderBanner), findsNothing);
      expect(find.textContaining('إِنَّ ٱلَّذِينَ كَفَرُوا'), findsWidgets);
      expect(find.textContaining('تُنذِرْهُمْ'), findsWidgets);
      expect(find.text('٣'), findsWidgets);
    });

    testWidgets('Visual Verification: Page 10 (Al-Baqarah 62-69)', (tester) async {
      await tester.pumpWidget(buildTestFrame(QuranPageView(pageNumber: 10)));
      await tester.pumpAndSettle();

      expect(find.byType(QuranPageView), findsOneWidget);
      expect(find.text('١٠'), findsWidgets);
    });

    testWidgets('Visual Verification: Page 100 (An-Nisa 135-140)', (tester) async {
      await tester.pumpWidget(buildTestFrame(QuranPageView(pageNumber: 100)));
      await tester.pumpAndSettle();

      expect(find.byType(QuranPageView), findsOneWidget);
      expect(find.text('١٠٠'), findsWidgets);
    });

    testWidgets('Visual Verification: Page 300 (Al-Kahf 54-61)', (tester) async {
      await tester.pumpWidget(buildTestFrame(QuranPageView(pageNumber: 300)));
      await tester.pumpAndSettle();

      expect(find.byType(QuranPageView), findsOneWidget);
      expect(find.text('٣٠٠'), findsWidgets);
    });

    testWidgets('Visual Verification: Page 604 (Surahs 112, 113, 114)', (tester) async {
      await tester.pumpWidget(buildTestFrame(QuranPageView(pageNumber: 604)));
      await tester.pumpAndSettle();

      expect(find.byType(QuranPageView), findsOneWidget);
      // Three distinct Surahs start on page 604
      expect(find.byType(SurahHeaderBanner), findsNWidgets(3));
      expect(find.byType(BismillahBanner), findsNWidgets(3));
      expect(find.text('سُورَةُ الإخلاص'), findsWidgets);
      expect(find.text('سُورَةُ الفلق'), findsOneWidget);
      expect(find.text('سُورَةُ الناس'), findsOneWidget);
      expect(find.text('٦٠٤'), findsWidgets);
    });

    testWidgets('Interactivity Verification: Ayah callbacks execute correctly', (tester) async {
      Ayah? tappedAyah;
      Ayah? longPressedAyah;

      final page1 = QuranRepository.instance.getPage(1);
      final firstAyah = page1.ayahs.first;

      await tester.pumpWidget(
        buildTestFrame(
          QuranPageView(
            page: page1,
            onAyahTap: (a) => tappedAyah = a,
            onAyahLongPress: (a) => longPressedAyah = a,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final qpv = tester.widget<QuranPageView>(find.byType(QuranPageView));
      qpv.onAyahTap?.call(firstAyah);
      qpv.onAyahLongPress?.call(firstAyah);

      expect(tappedAyah?.id, 1);
      expect(longPressedAyah?.id, 1);
      expect(find.byType(QuranPageView), findsOneWidget);
    });

    testWidgets('SurahHeaderBanner adapts styling and colors between Light and Dark mode', (tester) async {
      final repo = QuranRepository.instance;
      final surah1 = repo.getSurah(1);

      // 1. Light Mode
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(body: SurahHeaderBanner(surah: surah1)),
        ),
      );
      await tester.pumpAndSettle();

      final lightTitleText = tester.widget<Text>(find.text('سُورَةُ ${surah1.name}'));
      expect(lightTitleText.style?.color, equals(AppColors.mushafQuranText));

      // 2. Dark Mode
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(body: SurahHeaderBanner(surah: surah1)),
        ),
      );
      await tester.pumpAndSettle();

      final darkTitleText = tester.widget<Text>(find.text('سُورَةُ ${surah1.name}'));
      expect(darkTitleText.style?.color, equals(AppColors.darkTextPrimary));
    });
  });
}

