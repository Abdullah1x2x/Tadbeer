import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/theme.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';
import 'package:tadbeer/features/quran/screens/quran_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_modes_test_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
    await UserDataStore.instance.saveReadingPosition(
      page: 100,
      surahNumber: 5,
      ayahNumber: 1,
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Widget host(Widget child) =>
      MaterialApp(theme: AppTheme.lightTheme, home: child);

  testWidgets('viewing a verse never moves the reading position', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const QuranScreen(targetSurahNumber: 2, targetAyahNumber: 255)),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(UserDataStore.instance.readingPosition.page, 100);
    expect(find.text('أكمل القراءة من هنا'), findsOneWidget);

    // The user can choose to make it the reading position.
    await tester.tap(find.text('أكمل القراءة من هنا'));
    await tester.pump(const Duration(seconds: 1));
    expect(UserDataStore.instance.readingPosition.page, 42);
  });

  testWidgets('reading mode counts a page when moving forward past it', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const QuranScreen(initialPage: 50, readingMode: true)),
    );
    await tester.pump(const Duration(seconds: 1));

    // Spend real time on the page before moving on.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 3100)),
    );
    final controller = tester
        .widget<PageView>(find.byType(PageView))
        .controller!;
    controller.jumpToPage(50);
    await tester.pump(const Duration(seconds: 1));

    final today = UserDataStore.instance.journey.pagesOn(DateTime.now());
    expect(today, 1);
    expect(UserDataStore.instance.readingPosition.page, 51);
    expect(find.text('احتُسبت صفحة ٥٠'), findsOneWidget);

    // Moving forward again immediately does not count the skimmed page.
    controller.jumpToPage(51);
    await tester.pump(const Duration(seconds: 2));
    expect(UserDataStore.instance.journey.pagesOn(DateTime.now()), 1);
  });
}
