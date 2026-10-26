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

  /// Lets the database writes that follow a counted page finish.
  /// Each write in the chain (count the page, save the position, move the
  /// khatma) is real I/O that resumes on the next pump.
  Future<void> settleWrites(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
  }

  testWidgets('a verse opened from search moves nothing until it is read', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const QuranScreen(targetSurahNumber: 2, targetAyahNumber: 255)),
    );
    await tester.pump(const Duration(seconds: 1));
    await settleWrites(tester);
    // A glance at a search result keeps the reading place.
    expect(UserDataStore.instance.readingPosition.page, 100);
    expect(find.text('أكمل القراءة من هنا'), findsNothing);

    // Staying to read it makes it the reading place.
    await tester.pump(const Duration(seconds: 40));
    await settleWrites(tester);
    expect(UserDataStore.instance.readingPosition.page, 42);
  });

  testWidgets('a page counts when moving forward past it', (tester) async {
    await tester.pumpWidget(host(const QuranScreen(initialPage: 50)));
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
    await settleWrites(tester);

    expect(UserDataStore.instance.journey.pagesOn(DateTime.now()), 1);
    expect(UserDataStore.instance.readingPosition.page, 51);

    // Moving forward again at once neither counts the skimmed page nor
    // moves the reading place.
    controller.jumpToPage(51);
    await tester.pump(const Duration(seconds: 2));
    await settleWrites(tester);
    expect(UserDataStore.instance.journey.pagesOn(DateTime.now()), 1);
    expect(UserDataStore.instance.readingPosition.page, 51);
  });

  testWidgets('the page on screen counts after a while without turning it', (
    tester,
  ) async {
    await tester.pumpWidget(host(const QuranScreen(initialPage: 50)));
    await tester.pump(const Duration(seconds: 39));
    expect(UserDataStore.instance.journey.pagesOn(DateTime.now()), 0);
    await tester.pump(const Duration(seconds: 2));
    expect(UserDataStore.instance.journey.pagesOn(DateTime.now()), 1);
    expect(
      UserDataStore.instance.journey.dailyPages.values.single,
      contains(50),
    );
  });

  testWidgets('a hidden reader does not count the page', (tester) async {
    await tester.pumpWidget(
      host(
        const TickerMode(enabled: false, child: QuranScreen(initialPage: 50)),
      ),
    );
    await tester.pump(const Duration(seconds: 41));
    expect(UserDataStore.instance.journey.pagesOn(DateTime.now()), 0);
  });
}
