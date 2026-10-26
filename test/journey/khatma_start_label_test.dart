import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/app/theme.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/journey/journey_screen.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';

void main() {
  late Directory tempDir;

  // The real fonts, so text measures as it does in the app.
  setUpAll(() async {
    final amiri = FontLoader('Amiri')
      ..addFont(rootBundle.load('assets/fonts/Amiri-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Amiri-Bold.ttf'));
    await amiri.load();
    final plex = FontLoader('IBMPlexSansArabic')
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Bold.ttf'));
    await plex.load();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_start_label_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<void> pumpJourney(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppLocalizationScope(
        currentLanguage: AppLanguage.arabic,
        strings: const AppStrings(AppLanguage.arabic),
        onLanguageChanged: (_) {},
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const JourneyScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('a new khatma offers to start, not to continue', (tester) async {
    await tester.runAsync(() => UserDataStore.instance.startKhatma(30));
    await pumpJourney(tester);
    expect(find.text('ابدأ الآن'), findsOneWidget);
    expect(find.textContaining('أكمل من صفحة'), findsNothing);
  });

  testWidgets('a khatma from the reader’s page names that page', (
    tester,
  ) async {
    await tester.runAsync(
      () => UserDataStore.instance.startKhatma(30, startPage: 50),
    );
    await pumpJourney(tester);
    expect(find.text('ابدأ من صفحة ٥٠'), findsOneWidget);
  });

  testWidgets('once reading has begun it offers to continue', (tester) async {
    await tester.runAsync(() async {
      final store = UserDataStore.instance;
      await store.startKhatma(30);
      await store.recordPageRead(1);
      await store.saveReadingPosition(page: 2, surahNumber: 2, ayahNumber: 1);
    });
    await pumpJourney(tester);
    expect(find.text('أكمل من صفحة ٢'), findsOneWidget);
    expect(find.text('ابدأ الآن'), findsNothing);
  });
}
