import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/app/theme.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/home/home_screen.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';
import 'package:tadbeer/features/tadbeer/commitment_card.dart';
import 'package:tadbeer/features/tadbeer/my_reflections_screen.dart';
import 'package:tadbeer/features/tadbeer/tadbeer_model.dart';

void main() {
  late Directory tempDir;
  final store = UserDataStore.instance;
  final tomorrow = DateTime.now().add(const Duration(days: 1));

  setUpAll(() async {
    final plex = FontLoader('IBMPlexSansArabic')
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Bold.ttf'));
    await plex.load();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_commitments_');
    await store.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<void> reflect(int surah, int ayah, Map<int, String> answers) =>
      store.saveTadbeer(surahNumber: surah, ayahNumber: ayah, answers: answers);

  group('commitments', () {
    test('a commitment is asked about from the next day', () async {
      await reflect(2, 255, {
        1: 'الحي القيوم',
        3: 'أقرأ آية الكرسي بعد الصلاة',
      });
      final item = store.getTadbeer(2, 255)!;
      expect(item.commitment, 'أقرأ آية الكرسي بعد الصلاة');
      expect(item.commitmentAt, isNotNull);
      expect(store.pendingCommitment(), isNull);
      expect(store.pendingCommitment(now: tomorrow)?.ayahKey, '2:255');
      // A week on, it is no longer brought up.
      expect(
        store.pendingCommitment(
          now: DateTime.now().add(const Duration(days: 9)),
        ),
        isNull,
      );
    });

    test('a reflection without a commitment is never asked about', () async {
      await reflect(1, 1, {1: 'بسم الله'});
      expect(store.getTadbeer(1, 1)!.commitment, isNull);
      expect(store.pendingCommitment(now: tomorrow), isNull);
    });

    test('"I did it" and "Not yet" both put it away', () async {
      await reflect(2, 255, {3: 'أ'});
      await reflect(3, 8, {3: 'ب'});
      await store.setCommitmentDone(2, 255, done: true);
      expect(store.getTadbeer(2, 255)!.commitmentDone, isTrue);
      expect(store.pendingCommitment(now: tomorrow)?.ayahKey, '3:8');
      await store.setCommitmentAsked(3, 8);
      expect(store.getTadbeer(3, 8)!.commitmentDone, isFalse);
      expect(store.pendingCommitment(now: tomorrow), isNull);
    });

    test(
      'editing other answers keeps the state; a new one starts over',
      () async {
        await reflect(2, 255, {3: 'أ'});
        await store.setCommitmentDone(2, 255, done: true);
        await reflect(2, 255, {1: 'جديد', 3: 'أ'});
        expect(store.getTadbeer(2, 255)!.commitmentDone, isTrue);
        await reflect(2, 255, {1: 'جديد', 3: 'ب'});
        final item = store.getTadbeer(2, 255)!;
        expect(item.commitmentDone, isFalse);
        expect(item.commitmentAsked, isFalse);
      },
    );

    test('the state survives saving and loading', () async {
      await reflect(2, 255, {3: 'أ'});
      await store.setCommitmentDone(2, 255, done: true);
      final restored = TadbeerItem.fromJson(store.getTadbeer(2, 255)!.toJson());
      expect(restored.commitmentDone, isTrue);
      expect(restored.commitmentAsked, isTrue);
      expect(restored.commitmentAt, store.getTadbeer(2, 255)!.commitmentAt);
    });
  });

  Widget app(Widget child) => AppLocalizationScope(
    currentLanguage: AppLanguage.arabic,
    strings: const AppStrings(AppLanguage.arabic),
    onLanguageChanged: (_) {},
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
    ),
  );

  testWidgets('the home card shows nothing without a pending commitment', (
    tester,
  ) async {
    await tester.pumpWidget(app(const CommitmentCard()));
    expect(find.text('هل فعلته؟'), findsNothing);
  });

  testWidgets('my reflections lists them and marks a commitment done', (
    tester,
  ) async {
    await tester.runAsync(() => reflect(2, 255, {1: 'الحي القيوم', 3: 'أذكر'}));
    await tester.pumpWidget(app(const MyReflectionsScreen()));
    await tester.pump();
    expect(find.text('الحي القيوم\nأذكر'), findsOneWidget);
    expect(find.textContaining('باقٍ'), findsOneWidget);

    await tester.tap(find.text('ما التزمت به'));
    await tester.pumpAndSettle();
    expect(find.text('أذكر'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.byTooltip('فعلته'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(store.getTadbeer(2, 255)!.commitmentDone, isTrue);
    expect(find.byTooltip('ليس بعد'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the home tile opens my reflections', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppLocalizationScope(
        currentLanguage: AppLanguage.arabic,
        strings: const AppStrings(AppLanguage.arabic),
        onLanguageChanged: (_) {},
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final tile = find.text('وقفاتي');
    await tester.ensureVisible(tile);
    await tester.pump();
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.byType(MyReflectionsScreen), findsOneWidget);
  });
}
