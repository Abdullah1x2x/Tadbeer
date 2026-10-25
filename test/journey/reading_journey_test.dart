import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/journey/reading_journey.dart';

void main() {
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
      expect(read.plan!.nextUnreadPage, 3);
    });

    test('reading every page completes the khatma', () {
      var j = const ReadingJourney().startPlan(7, monday);
      for (var p = 1; p <= mushafPageCount; p++) {
        j = j.recordPage(p, monday);
      }
      expect(j.plan, isNull);
      expect(j.completedKhatmas, 1);
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

      await store.startKhatma(30);
      await store.recordPageRead(1);
      await store.recordPageRead(2);
      final backup = store.exportSnapshot();
      expect(backup['readingJourney'], isA<Map>());

      // Reopening the same database restores the journey.
      await store.init(File('${tempDir.path}/data.json'), dbPath);
      expect(store.journey.plan?.readPages, {1, 2});

      // A backup brings it back after a reset.
      await store.resetAllData();
      expect(store.journey.plan, isNull);
      await store.replaceAllUserData(backup);
      expect(store.journey.plan?.readPages, {1, 2});
    });
  });
}
