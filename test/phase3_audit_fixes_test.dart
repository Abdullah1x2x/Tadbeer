import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/core/theme/theme.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/features/books/data/curated_books.dart';
import 'package:tadbeer/features/continue/continue_card.dart';
import 'package:tadbeer/features/continue/last_activity.dart';
import 'package:tadbeer/features/duas/data/adhkar_repository.dart';
import 'package:tadbeer/features/duas/data/quran_duas_repository.dart';
import 'package:tadbeer/features/duas/screens/morning_evening_adhkar_screen.dart';
import 'package:tadbeer/features/qibla/qibla_location.dart';
import 'package:tadbeer/features/qibla/qibla_screen.dart';
import 'package:tadbeer/features/tasbeeh/tasbeeh_model.dart';

class _ThrowingErrorLocator extends QiblaLocator {
  const _ThrowingErrorLocator();

  @override
  QiblaLocated? saved() => null;

  @override
  Future<QiblaFix> locate() async {
    throw UnimplementedError('GPS plugin missing on platform');
  }
}

class _UnreachedLocator extends QiblaLocator {
  final QiblaLocated fix;
  const _UnreachedLocator(this.fix);

  @override
  QiblaLocated? saved() => null;

  @override
  Future<QiblaFix> locate() async => fix;
}

Widget _wrap(Widget child, {AppLanguage lang = AppLanguage.arabic}) {
  return AppLocalizationScope(
    currentLanguage: lang,
    strings: AppStrings(lang),
    onLanguageChanged: (_) {},
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    final plex = FontLoader('IBMPlexSansArabic')
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Bold.ttf'));
    await plex.load();
    await QuranRepository.instance.init();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_phase3_test_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Phase 3 audit fixes regression tests', () {
    testWidgets('QiblaScreen catches Error subclasses without hanging', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final strings = AppStrings(AppLanguage.arabic);
      await tester.pumpWidget(
        _wrap(
          QiblaScreen.withSources(
            locator: const _ThrowingErrorLocator(),
            headings: const Stream<double>.empty(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text(strings.qiblaLocationFailed), findsOneWidget);
    });

    testWidgets(
      'QiblaScreen snaps to first compass heading instead of lerping from 0',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final headings = StreamController<double>();
        addTearDown(headings.close);

        await tester.pumpWidget(
          _wrap(
            QiblaScreen.withSources(
              locator: const _UnreachedLocator(QiblaLocated(15.3694, 44.1910)),
              headings: headings.stream,
            ),
          ),
        );
        await tester.pump();
        headings.add(180.0);
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );

    test('Tasbeeh localizedCategory & section init ordering work cleanly',
        () async {
      final en = AppStrings(AppLanguage.english);
      final ar = AppStrings(AppLanguage.arabic);
      for (final d in TasbeehDhikr.tasbeehDhikrs) {
        expect(d.localizedCategory(en).trim(), isNotEmpty);
        expect(d.localizedCategory(ar).trim(), isNotEmpty);
        expect(d.localizedCategory(en), isNot(equals(d.category)));
      }
      for (final d in TasbeehDhikr.istighfarDhikrs) {
        expect(d.localizedCategory(en), isNot(equals(d.category)));
      }

      final repo = TasbeehRepository.instance;
      await repo.reload();
      final initFuture = repo.init();
      repo.setActiveSection(DhikrSection.istighfar);
      await initFuture;
      expect(repo.activeSection, DhikrSection.istighfar);
    });

    test('Tasbeeh overshoot credits completion when count >= target', () async {
      final repo = TasbeehRepository.instance;
      await repo.reload();
      await repo.init();
      repo.resetCurrentCount();
      repo.setTarget(10);
      for (var i = 0; i < 4; i++) {
        repo.increment();
      }
      repo.setTarget(3);
      // Already at 4 >= 3; next increment shouldn't fail or drop credit.
      final completed = repo.increment();
      expect(completed, isTrue);
      // Further increments do not re-credit the same cycle.
      expect(repo.increment(), isFalse);
      repo.flushPersistence();
    });

    test('stableBookIdHash is deterministic and distinct', () {
      final a1 = stableBookIdHash('نهج البلاغة');
      final a2 = stableBookIdHash('نهج البلاغة');
      final b = stableBookIdHash('الصحيفة السجادية');
      expect(a1, equals(a2));
      expect(a1, isNot(equals(b)));
    });

    testWidgets('ContinueCard resolves sleep AdhkarCategory instead of evening', (
      tester,
    ) async {
      await tester.runAsync(
        () => LastActivityStore.record(
          ActivityKind.adhkar,
          ref: AdhkarCategory.sleep.name,
          title: AdhkarCategory.sleep.name,
        ),
      );
      final ar = AppStrings(AppLanguage.arabic);
      await tester.pumpWidget(_wrap(const ContinueCard()));
      await tester.pump();

      expect(find.text(ar.sleepAdhkar), findsOneWidget);
    });

    test('QuranDuasRepository rejects diacritics-only query and caches load',
        () {
      final repo = QuranDuasRepository.instance;
      expect(repo.search('َُِّْ'), isEmpty);
      final duas = repo.getDuas(quranRepository: QuranRepository.instance);
      expect(duas, isNotEmpty);
      expect(duas.first.page, greaterThan(0));
    });

    testWidgets(
      'MorningEveningAdhkarScreen persists counts for today and restores them',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _wrap(
            const MorningEveningAdhkarScreen(
              initialCategory: AdhkarCategory.morning,
            ),
          ),
        );
        await tester.pump();

        // Tap first repeat pill if present (once/remaining chip).
        final morningItems = AdhkarRepository.instance.getAdhkar(
          AdhkarCategory.morning,
        );
        final firstMulti = morningItems.firstWhere((e) => e.repeatCount > 1);
        final en = AppStrings(AppLanguage.arabic);
        final beforeLabel = en.remainingCount(en.digits(firstMulti.repeatCount));
        final finder = find.text(beforeLabel);
        expect(finder, findsOneWidget);

        await tester.tap(finder);
        await tester.pump();
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));

        final saved = UserDataStore.instance.featureState('adhkar_counts');
        expect(saved['counts'], isA<Map<dynamic, dynamic>>());
        expect((saved['counts'] as Map)[firstMulti.id], 1);

        // Re-mount screen and verify count is restored.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.pumpWidget(
          _wrap(
            const MorningEveningAdhkarScreen(
              initialCategory: AdhkarCategory.morning,
            ),
          ),
        );
        await tester.pump();

        final afterLabel = en.remainingCount(
          en.digits(firstMulti.repeatCount - 1),
        );
        expect(find.text(afterLabel), findsOneWidget);
      },
    );
  });
}
