import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/core/theme/theme.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/features/memorization/memorization_model.dart';
import 'package:tadbeer/features/memorization/memorization_screen.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';

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
      final c = HifzCard(box: 4, due: day0).grade(remembered: false, now: day0);
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
      expect(find.text('أتقنت جميع الآيات (١)! بارك الله فيك.'), findsOneWidget);
    });

    test(
      'summary separates memorized (box >= 3) from in-progress per surah',
      () async {
        await HifzStore.toggle(2, 1, now: day0);
        await HifzStore.grade(1, 1, remembered: true, now: day0);
        await HifzStore.grade(
          1,
          1,
          remembered: true,
          now: day0.add(const Duration(days: 1)),
        );
        await HifzStore.grade(
          1,
          1,
          remembered: true,
          now: day0.add(const Duration(days: 4)),
        );

        final s = HifzStore.summary(now: day0);
        expect(s.memorizedCount, 1);
        expect(s.inProgressCount, 1);
        expect(s.memorizedInSurah(1), 1);
        expect(s.inProgressInSurah(1), 0);
        expect(s.memorizedInSurah(2), 0);
        expect(s.inProgressInSurah(2), 1);
        expect(s.dueInSurah(2), 1);
        expect(s.due, [(2, 1)]);
        expect(s.trackedInSurah(1), [(1, 1)]);
      },
    );

    test('same-day repeat grading does not inflate box above due date', () async {
      await HifzStore.grade(1, 2, remembered: true, now: day0);
      expect(HifzStore.card(1, 2)?.box, 1);
      expect(HifzStore.card(1, 2)?.due, DateTime(2026, 10, 20));

      // Repeating "mastered" on the same day keeps box at 1 instead of jumping.
      await HifzStore.grade(1, 2, remembered: true, now: day0);
      expect(HifzStore.card(1, 2)?.box, 1);
      expect(HifzStore.card(1, 2)?.due, DateTime(2026, 10, 20));

      // Grading on or after due advances normally.
      await HifzStore.grade(
        1,
        2,
        remembered: true,
        now: day0.add(const Duration(days: 1)),
      );
      expect(HifzStore.card(1, 2)?.box, 2);
    });

    test('remove deletes a tracked verse cleanly', () async {
      await HifzStore.toggle(1, 3, now: day0);
      expect(HifzStore.contains(1, 3), isTrue);

      await HifzStore.remove(1, 3);
      expect(HifzStore.contains(1, 3), isFalse);
      expect(HifzStore.card(1, 3), isNull);
    });

    test('hifzWordsOf skips waqf symbols and single-word hint stays partial', () {
      expect(hifzWordsOf('بِسْمِ ۖ اللَّهِ ۚ'), ['بِسْمِ', 'اللَّهِ']);
      expect(hifzSingleWordHint('مُدْهَآمَّتَانِ'), 'مُ');
      expect(hifzSingleWordHint('صٓ'), 'صٓ');
    });

    testWidgets('empty HifzSessionScreen renders safely without range error', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HifzSessionScreen(verses: []),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('أحسنت! انتهت الجلسة'), findsOneWidget);
      expect(find.text('لا مراجعة مستحقة اليوم'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('single-word verse hides full word and hides reveal-word', (
      tester,
    ) async {
      final ayah = QuranRepository.instance.getAyah(55, 64)!;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HifzSessionScreen(verses: [(55, 64)]),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('${hifzSingleWordHint(ayah.text)} …'),
        findsOneWidget,
      );
      expect(find.textContaining(ayah.text), findsNothing);
      expect(find.text('كلمة إضافية'), findsNothing);

      await tester.tap(find.text('اضغط لكشف الآية'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('full')), findsOneWidget);
    });

    testWidgets('reveal-next-word progressively reveals multi-word verses', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HifzSessionScreen(verses: [(1, 1)]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('كلمة إضافية'), findsOneWidget);
      await tester.tap(find.text('كلمة إضافية'));
      await tester.pumpAndSettle();

      // After revealing 2 words of a 4-word ayah, button remains until 1 left.
      expect(find.text('كلمة إضافية'), findsOneWidget);
    });

    testWidgets('MemorizationScreen shows in-progress badge and filters surahs', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await HifzStore.toggle(2, 1, now: day0);
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MemorizationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('قيد الحفظ: ١'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'البقرة');
      await tester.pumpAndSettle();
      expect(find.textContaining('البقرة'), findsWidgets);
      expect(find.textContaining('الفاتحة'), findsNothing);
    });
  });
}
