import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/continue/last_activity.dart';
import 'package:tadbeer/features/journey/weekly_goals.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_goals_test_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('the week starts on Saturday', () {
    // 2026-10-25 is a Sunday; its week started on Saturday the 24th.
    expect(
      WeeklyGoals.weekStart(DateTime(2026, 10, 25, 9)),
      DateTime(2026, 10, 24),
    );
    expect(
      WeeklyGoals.weekStart(DateTime(2026, 10, 24)),
      DateTime(2026, 10, 24),
    );
    expect(
      WeeklyGoals.weekStart(DateTime(2026, 10, 30)),
      DateTime(2026, 10, 24),
    );
  });

  test('counts only this week’s pages and keeps saved goals', () async {
    final store = UserDataStore.instance;
    await store.recordPageRead(5, now: DateTime(2026, 10, 23)); // last week
    await store.recordPageRead(6, now: DateTime(2026, 10, 24));
    await store.recordPageRead(7, now: DateTime(2026, 10, 25));
    expect(WeeklyGoals.pagesThisWeek(store, DateTime(2026, 10, 25, 20)), 2);

    await const WeeklyGoals(pages: 70, reflections: 5).save();
    expect(WeeklyGoals.load().pages, 70);
    expect(WeeklyGoals.load().reflections, 5);
  });

  test('keeps the latest activity per section, newest first', () async {
    await LastActivityStore.record(
      ActivityKind.adhkar,
      ref: 'morning',
      title: 'morning',
    );
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await LastActivityStore.record(
      ActivityKind.book,
      ref: 'b1',
      title: 'كتاب',
      position: 2,
    );
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await LastActivityStore.record(
      ActivityKind.adhkar,
      ref: 'evening',
      title: 'evening',
    );

    final recent = LastActivityStore.recent();
    expect(recent.map((a) => a.kind), [ActivityKind.adhkar, ActivityKind.book]);
    expect(recent.first.ref, 'evening');
    expect(recent.last.position, 2);
  });
}
