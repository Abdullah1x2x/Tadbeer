import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/theme.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/memorization/memorization_model.dart';
import 'package:tadbeer/features/memorization/memorization_screen.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';

void main() {
  final day0 = DateTime(2026, 10, 19, 8);

  group('HifzCard', () {
    test('success moves up a box with growing gaps', () {
      var c = HifzCard(box: 0, due: day0);
      c = c.grade(remembered: true, now: day0);
      expect(c.box, 1);
      expect(c.due, DateTime(2026, 10, 20));
      c = c.grade(remembered: true, now: day0);
      expect(c.box, 2);
      expect(c.due, DateTime(2026, 10, 22));
    });

    test('failure goes back to box 1, due tomorrow', () {
      final c = HifzCard(
        box: 4,
        due: day0,
      ).grade(remembered: false, now: day0);
      expect(c.box, 1);
      expect(c.due, DateTime(2026, 10, 20));
    });

    test('the top box stays at a 30 day gap', () {
      final c = HifzCard(
        box: HifzCard.maxBox,
        due: day0,
      ).grade(remembered: true, now: day0);
      expect(c.box, HifzCard.maxBox);
      expect(c.due, DateTime(2026, 11, 18));
    });
  });

  group('HifzStore', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('tadbeer_hifz_test_');
      await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
      await QuranRepository.instance.init();
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('due verses come back on their day in Mushaf order', () async {
      await HifzStore.grade(2, 5, remembered: false, now: day0);
      await HifzStore.grade(1, 7, remembered: true, now: day0);
      expect(HifzStore.dueToday(now: day0), isEmpty);
      expect(HifzStore.dueToday(now: day0.add(const Duration(days: 1))), [
        (1, 7),
        (2, 5),
      ]);
    });

    test('toggling adds a verse due today, then removes it', () async {
      await HifzStore.toggle(2, 255, now: day0);
      expect(HifzStore.contains(2, 255), isTrue);
      expect(HifzStore.dueToday(now: day0), [(2, 255)]);
      await HifzStore.toggle(2, 255, now: day0);
      expect(HifzStore.contains(2, 255), isFalse);
    });

    test('memorizing a verse keeps the day streak', () async {
      await HifzStore.grade(1, 1, remembered: true, now: day0);
      expect(UserDataStore.instance.journey.streak(day0), 1);
    });

    testWidgets('a session reveals a verse and records the grade', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HifzSessionScreen(verses: [(1, 1)]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('اضغط لكشف الآية'), findsOneWidget);
      await tester.tap(find.text('اضغط لكشف الآية'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('أتقنتها'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(HifzStore.card(1, 1)?.box, 1);
      expect(find.text('أحسنت! انتهت الجلسة'), findsOneWidget);
    });
  });
}
