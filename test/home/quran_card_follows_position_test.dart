import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/app/theme.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/home/home_screen.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    final plex = FontLoader('IBMPlexSansArabic')
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Bold.ttf'));
    await plex.load();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_home_card_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('the Mushaf card follows the reading position', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppLocalizationScope(
        currentLanguage: AppLanguage.arabic,
        strings: const AppStrings(AppLanguage.arabic),
        onLanguageChanged: (_) {},
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('صفحة ١'), findsWidgets);

    await tester.runAsync(
      () => UserDataStore.instance.saveReadingPosition(
        page: 300,
        surahNumber: 16,
        ayahNumber: 90,
      ),
    );
    await tester.pump();
    expect(find.textContaining('صفحة ٣٠٠'), findsOneWidget);
  });

  testWidgets('the Mushaf card offers to start until something is read', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppLocalizationScope(
        currentLanguage: AppLanguage.arabic,
        strings: const AppStrings(AppLanguage.arabic),
        onLanguageChanged: (_) {},
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('ابدأ الآن'), findsOneWidget);
    expect(find.text('استئناف القراءة'), findsNothing);

    // Reading a page saves the position after counting it.
    await tester.runAsync(() async {
      await UserDataStore.instance.recordPageRead(1);
      await UserDataStore.instance.saveReadingPosition(
        page: 2,
        surahNumber: 2,
        ayahNumber: 1,
      );
    });
    await tester.pump();
    expect(find.text('استئناف القراءة'), findsOneWidget);
    expect(find.text('ابدأ الآن'), findsNothing);
  });

  test('a khatma not begun offers to start; one under way resumes', () async {
    final store = UserDataStore.instance;
    await store.recordPageRead(1);
    expect(store.readingNotStarted, isFalse);
    await store.startKhatma(30, startPage: 50);
    expect(store.readingNotStarted, isTrue);
    await store.recordPageRead(50);
    expect(store.readingNotStarted, isFalse);
  });
}
