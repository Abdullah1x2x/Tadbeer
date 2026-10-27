import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/app/theme.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/journey/journey_screen.dart';
import 'package:tadbeer/features/journey/monthly_report.dart';
import 'package:tadbeer/features/journey/reading_journey.dart';
import 'package:tadbeer/features/journey/streak_reminder.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';

/// The streak counts calendar days, its reminder speaks only when the
/// streak is at stake, and the journey screen's texts and report follow
/// the reader's language and theme.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A journey active on each of [days] days ending on [last].
  ReadingJourney activeFor(int days, DateTime last) {
    var j = const ReadingJourney();
    for (var i = 0; i < days; i++) {
      j = j.markActive(DateTime(last.year, last.month, last.day - i, 10));
    }
    return j;
  }

  group('streak', () {
    test('counts calendar days across months and clock changes', () {
      // Spans the spring and autumn clock changes in many countries.
      for (final last in [
        DateTime(2026, 3, 31, 9),
        DateTime(2026, 4, 1, 9),
        DateTime(2026, 10, 27, 9),
        DateTime(2026, 11, 2, 9),
        DateTime(2027, 1, 1, 9),
      ]) {
        expect(activeFor(10, last).streak(last), 10, reason: '$last');
      }
      expect(
        activeFor(400, DateTime(2027, 3, 1)).streak(DateTime(2027, 3, 1)),
        400,
      );
    });

    test('is at risk only while today has no activity', () {
      final today = DateTime(2026, 10, 27, 20);
      final yesterday = DateTime(2026, 10, 26, 20);
      final j = activeFor(3, yesterday);
      expect(j.streak(today), 3);
      expect(j.streakAtRisk(today), isTrue);
      expect(j.markActive(today).streakAtRisk(today), isFalse);
      expect(const ReadingJourney().streakAtRisk(today), isFalse);
    });

    test('the last seven days follow the calendar', () {
      final now = DateTime(2026, 3, 30, 12);
      var j = const ReadingJourney();
      for (var i = 0; i < 7; i++) {
        j = j.recordPage(i + 1, DateTime(2026, 3, 30 - i, 8));
      }
      expect(j.lastSevenDays(now), [1, 1, 1, 1, 1, 1, 1]);
    });
  });

  group('streak notices', () {
    test('tonight, while the streak is at stake', () {
      final now = DateTime(2026, 10, 27, 15);
      final j = activeFor(4, DateTime(2026, 10, 26));
      expect(streakNotices(j, now, hour: 21, minute: 0), [
        StreakNotice(DateTime(2026, 10, 27, 21), 4),
      ]);
    });

    test('tomorrow, once today counts', () {
      final now = DateTime(2026, 10, 27, 15);
      final j = activeFor(5, now);
      expect(streakNotices(j, now, hour: 21, minute: 0), [
        StreakNotice(DateTime(2026, 10, 28, 21), 5),
      ]);
    });

    test('none after tonight\'s time, or with no streak', () {
      final late = DateTime(2026, 10, 27, 22);
      expect(
        streakNotices(
          activeFor(2, DateTime(2026, 10, 26)),
          late,
          hour: 21,
          minute: 0,
        ),
        isEmpty,
      );
      expect(
        streakNotices(const ReadingJourney(), late, hour: 21, minute: 0),
        isEmpty,
      );
    });
  });

  test('the khatma lengths read as Arabic counts days', () {
    const l10n = AppStrings(AppLanguage.arabic);
    expect(l10n.daysCount(7), '٧ أيام');
    expect(l10n.daysCount(15), '١٥ يومًا');
    expect(l10n.daysCount(90), '٩٠ يومًا');
    expect(l10n.khatmaInDays(7), 'ختمة في ٧ أيام');
    expect(l10n.khatmaInDays(30), 'ختمة في ٣٠ يومًا');
    expect(l10n.streakAtRiskTitle(3), contains('٣ أيام'));
  });

  group('with the store', () {
    late Directory tempDir;

    setUpAll(() async {
      final plex = FontLoader('IBMPlexSansArabic')
        ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'))
        ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Bold.ttf'));
      await plex.load();
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('tadbeer_streak_');
      await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
      await QuranRepository.instance.init();
    });

    tearDown(() {
      AppColors.use(AppColorTheme.navy);
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    Widget app(Widget home) => AppLocalizationScope(
      currentLanguage: AppLanguage.arabic,
      strings: const AppStrings(AppLanguage.arabic),
      onLanguageChanged: (_) {},
      child: MaterialApp(theme: AppTheme.lightTheme, home: home),
    );

    testWidgets('starting a khatma asks when to remind of the portion', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(const JourneyScreen()));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('ابدأ الختمة'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(UserDataStore.instance.journey.plan, isNotNull);
      expect(find.text('متى نذكّرك بوردك يومياً؟'), findsOneWidget);
    });

    testWidgets('the streak reminder switch shows when it is on', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(const JourneyScreen()));
      await tester.pumpAndSettle();
      final tile = find.text('نبّهني قبل أن تنقطع السلسلة');
      await tester.scrollUntilVisible(
        tile,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      Switch toggle() => tester.widget<Switch>(find.byType(Switch));
      expect(toggle().value, isFalse);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text('متى نذكّرك إن لم تقرأ في يومك؟'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text('OK'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(toggle().value, isTrue);
      expect(find.textContaining('كل مساء'), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.byType(Switch));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(toggle().value, isFalse);
    });

    testWidgets('the monthly report takes the selected theme', (tester) async {
      Color glow() {
        final box = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(MonthlyReportCard),
                matching: find.byType(Container),
              )
              .first,
        );
        final gradient =
            (box.decoration! as BoxDecoration).gradient! as RadialGradient;
        return gradient.colors.first;
      }

      Future<void> pumpReport(AppColorTheme theme) async {
        AppColors.use(theme);
        await tester.pumpWidget(
          app(
            Scaffold(
              body: MonthlyReportCard(
                stats: const MonthStats(
                  pages: 1,
                  activeDays: 1,
                  reflections: 0,
                  memorized: 0,
                  khatmas: 0,
                ),
                monthTitle: 'أكتوبر',
                width: 360,
              ),
            ),
          ),
        );
      }

      await pumpReport(AppColorTheme.emerald);
      expect(glow(), ThemePalette.emerald.heroLightStart);
      await pumpReport(AppColorTheme.burgundy);
      expect(glow(), ThemePalette.burgundy.heroLightStart);
    });
  });
}
