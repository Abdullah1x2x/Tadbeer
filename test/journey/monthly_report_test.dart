import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/features/journey/monthly_report.dart';

void main() {
  late Directory tempDir;

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
    tempDir = await Directory.systemTemp.createTemp('tadbeer_report_test_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('counts only the given month', () async {
    final store = UserDataStore.instance;
    await store.recordPageRead(10, now: DateTime(2026, 10, 3));
    await store.recordPageRead(11, now: DateTime(2026, 10, 3));
    await store.recordPageRead(12, now: DateTime(2026, 10, 9));
    await store.recordPageRead(13, now: DateTime(2026, 9, 30));
    await store.markActiveDay(now: DateTime(2026, 10, 20));

    final stats = MonthStats.of(store, DateTime(2026, 10, 25));
    expect(stats.pages, 3);
    expect(stats.activeDays, 3);
  });

  testWidgets('the report card renders without overflow', (tester) async {
    await tester.pumpWidget(
      AppLocalizationScope(
        currentLanguage: AppLanguage.arabic,
        strings: const AppStrings(AppLanguage.arabic),
        onLanguageChanged: (_) {},
        child: const MaterialApp(
          home: Center(
            child: MonthlyReportCard(
              stats: MonthStats(
                pages: 412,
                activeDays: 28,
                reflections: 37,
                memorized: 120,
                khatmas: 2,
              ),
              monthTitle: 'أكتوبر ٢٠٢٦',
              width: 360,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('تقرير الشهر'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
