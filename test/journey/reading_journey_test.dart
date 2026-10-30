import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/data/models/reading_journey.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final monday = DateTime(2026, 10, 19, 9);

  group('ReadingJourney', () {
    test('records pages per day without duplicates', () {
      var j = const ReadingJourney();
      j = j.recordPage(5, monday).recordPage(5, monday).recordPage(6, monday);
      expect(j.pagesOn(monday), 2);
      expect(j.totalPages, 2);
    });

    test('streak counts consecutive days and survives an unread morning', () {
      var j = const ReadingJourney();
      for (var i = 0; i < 3; i++) {
        j = j.recordPage(1, monday.add(Duration(days: i)));
      }
      final wednesday = monday.add(const Duration(days: 2));
      expect(j.streak(wednesday), 3);
      // Thursday morning, nothing read yet: the streak is not broken.
      expect(j.streak(wednesday.add(const Duration(days: 1))), 3);
      // A missed day breaks it.
      expect(j.streak(wednesday.add(const Duration(days: 2))), 0);
    });

    test('khatma plan computes the daily portion and progress', () {
      final j = const ReadingJourney().startPlan(30, monday);
      expect(j.plan!.pagesPerDay, 21);
      expect(j.plan!.dayNumber(monday), 1);
      // Nothing is overdue on the first day.
      expect(j.plan!.expectedPagesBefore(monday), 0);
      expect(
        j.plan!.expectedPagesBefore(monday.add(const Duration(days: 2))),
        42,
      );
      final read = j.recordPage(1, monday).recordPage(2, monday);
      expect(read.plan!.progress, closeTo(2 / 604, 1e-9));
      expect(read.plan!.currentPage, 3);
    });

    test('only the page the khatma points at moves it forward', () {
      var j = const ReadingJourney().startPlan(30, monday, startPage: 192);
      expect(j.plan!.currentPage, 192);

      // Browsing another page counts for today but not for the khatma.
      j = j.recordPage(50, monday);
      expect(j.pagesOn(monday), 1);
      expect(j.plan!.currentPage, 192);
      expect(j.plan!.advanced, 0);

      j = j.recordPage(192, monday).recordPage(193, monday);
      expect(j.plan!.currentPage, 194);
      expect(j.plan!.advanced, 2);
    });

    test('a khatma started mid-Mushaf completes at the last page', () {
      var j = const ReadingJourney().startPlan(10, monday, startPage: 505);
      expect(j.plan!.totalPages, 100);
      expect(j.plan!.pagesPerDay, 10);

      j = j.moveKhatmaTo(604);
      expect(j.plan!.progress, closeTo(99 / 100, 1e-9));

      j = j.recordPage(604, monday);
      expect(j.plan, isNull);
      expect(j.completedKhatmas, 1);
    });

    test('a glance at the last page does not complete the khatma', () {
      final j = const ReadingJourney()
          .startPlan(30, monday)
          .recordPage(604, monday);
      expect(j.plan, isNotNull);
      expect(j.completedKhatmas, 0);
    });

    test('moving before the start makes that page the start', () {
      final j = const ReadingJourney()
          .startPlan(30, monday, startPage: 100)
          .moveKhatmaTo(40);
      expect(j.plan!.startPage, 40);
      expect(j.plan!.advanced, 0);
      expect(j.plan!.totalPages, 565);
    });

    test('moving the position by hand counts the pages before it', () {
      final j = const ReadingJourney()
          .startPlan(30, monday, startPage: 100)
          .moveKhatmaTo(150);
      expect(j.plan!.currentPage, 150);
      expect(j.plan!.advanced, 50);
    });

    test('marking the portion done advances by a day of pages', () {
      final j = const ReadingJourney()
          .startPlan(30, monday)
          .completePortion(monday);
      expect(j.plan!.currentPage, 22);
      expect(j.pagesOn(monday), 21);
    });

    test('reading every page completes the khatma', () {
      var j = const ReadingJourney().startPlan(7, monday);
      for (var p = 1; p <= mushafPageCount; p++) {
        j = j.recordPage(p, monday);
      }
      expect(j.plan, isNull);
      expect(j.completedKhatmas, 1);
    });

    test('reflection or memorization days keep the streak', () {
      var j = const ReadingJourney().recordPage(1, monday);
      j = j.markActive(monday.add(const Duration(days: 1)));
      expect(j.streak(monday.add(const Duration(days: 1))), 2);
    });

    test('migrates an older scattered-pages plan', () {
      final old = {
        'plan': {
          'startDate': '2026-10-19',
          'days': 30,
          'readPages': [1, 192, 193],
          'lastPage': 193,
        },
      };
      final plan = ReadingJourney.fromJson(old).plan!;
      expect(plan.currentPage, 194);
      expect(plan.advanced, 3);
    });

    test('round-trips through JSON', () {
      final j = const ReadingJourney()
          .startPlan(15, monday)
          .recordPage(10, monday)
          .recordPage(11, monday.add(const Duration(days: 1)));
      final restored = ReadingJourney.fromJson(j.toJson());
      expect(restored.toJson(), j.toJson());
    });
  });

  group('UserDataStore journey persistence', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('tadbeer_journey_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('saves to the database and is restored from a backup', () async {
      final store = UserDataStore.instance;
      final dbPath = '${tempDir.path}/user.db';
      await store.init(File('${tempDir.path}/data.json'), dbPath);
      await QuranRepository.instance.init();

      await store.startKhatma(30);
      await store.recordPageRead(1);
      await store.recordPageRead(2);
      final backup = store.exportSnapshot();
      expect(backup['readingJourney'], isA<Map>());

      // Reopening the same database restores the journey.
      await store.init(File('${tempDir.path}/data.json'), dbPath);
      expect(store.journey.plan?.currentPage, 3);

      // A backup brings it back after a reset.
      await store.resetAllData();
      expect(store.journey.plan, isNull);
      await store.replaceAllUserData(backup);
      expect(store.journey.plan?.currentPage, 3);
    });
  });
}
