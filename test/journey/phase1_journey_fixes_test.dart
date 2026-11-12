import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/data/models/reading_journey.dart';
import 'package:tadbeer/data/models/reminder_model.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/data/storage/user_database.dart';
import 'package:tadbeer/features/journey/journey_screen.dart';
import 'package:tadbeer/features/journey/portion_reminder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('phase1_journey_test_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await UserDataStore.instance.resetAllData();
    await QuranRepository.instance.init();
  });

  tearDown(() async {
    await UserDatabase.instance.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('portionNotices does not subtract skipped past day-0 pages from remaining', () {
    final start = DateTime(2026, 5, 1);
    final now = DateTime(2026, 5, 10, 14, 0);
    final journey = ReadingJourney(
      plan: KhatmaPlan(startDate: start, days: 30, advanced: 580),
    );

    final notices = portionNotices(journey, now, hour: 8, minute: 0);
    expect(notices, [
      PortionNotice(DateTime(2026, 5, 11, 8, 0), 21),
      PortionNotice(DateTime(2026, 5, 12, 8, 0), 3),
    ]);
  });

  test('KhatmaPlan clamps invalid bounds and avoids legacy fromJson modulo wrap-around', () {
    final clampedLow = KhatmaPlan(
      startDate: DateTime(2026, 5, 1),
      days: 0,
      startPage: 999,
      advanced: -5,
    );
    expect(clampedLow.days, 1);
    expect(clampedLow.startPage, mushafPageCount);
    expect(clampedLow.currentPage, mushafPageCount);
    expect(clampedLow.advanced, 0);

    final clampedHigh = KhatmaPlan(
      startDate: DateTime(2026, 5, 1),
      days: 9999,
    );
    expect(clampedHigh.days, 3650);

    final legacyEnd = KhatmaPlan.fromJson({
      'startDate': '2026-05-01T00:00:00.000',
      'days': 10,
      'lastPage': mushafPageCount,
      'readPages': List.filled(10, 1),
    });
    expect(legacyEnd.startPage, 595);
    expect(legacyEnd.currentPage, mushafPageCount);
    expect(legacyEnd.advanced, 10);

    // Started near the end and carried on from page 1.
    final legacyWrapped = KhatmaPlan.fromJson({
      'startDate': '2026-05-01T00:00:00.000',
      'days': 10,
      'lastPage': 10,
      'readPages': List.filled(20, 1),
    });
    expect(legacyWrapped.startPage, 595);
    expect(legacyWrapped.currentPage, 11);
  });

  test('cancelKhatma automatically disables khatma_daily_portion reminder', () async {
    final store = UserDataStore.instance;
    await store.startKhatma(30);
    await store.putReminder(
      ReminderItem(
        id: portionReminderId,
        title: 'ورد اليوم',
        hour: 20,
        minute: 0,
        isEnabled: true,
        repeatMode: ReminderRepeatMode.daily,
        createdAt: DateTime(2026, 5, 1),
      ),
    );
    expect(
      store.reminders.firstWhere((r) => r.id == portionReminderId).isEnabled,
      isTrue,
    );

    await store.cancelKhatma();

    expect(store.journey.plan, isNull);
    expect(
      store.reminders.firstWhere((r) => r.id == portionReminderId).isEnabled,
      isFalse,
    );
  });

  testWidgets('StartKhatmaCard recalculates daily pages hint when starting from current position', (
    tester,
  ) async {
    final store = UserDataStore.instance;
    await tester.runAsync(
      () => store.saveReadingPosition(page: 305, surahNumber: 19, ayahNumber: 1),
    );
    final l10n = AppStrings(AppLanguage.arabic);

    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AppLocalizationScope(
        currentLanguage: AppLanguage.arabic,
        strings: l10n,
        onLanguageChanged: (_) {},
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: JourneyScreen(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(l10n.pagesPerDayHint(21)), findsOneWidget);

    await tester.ensureVisible(find.text(l10n.fromMyPosition(305)));
    await tester.tap(find.text(l10n.fromMyPosition(305)));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text(l10n.pagesPerDayHint(10)), findsOneWidget);
  });
}
