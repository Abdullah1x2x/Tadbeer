import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/core/theme/theme.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/features/ayah_links/data/curated_pathways.dart';
import 'package:tadbeer/features/pathways/guided_pathways_screen.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/core/design_system/app_icons.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_paths_test_');
    await UserDataStore.instance.init(
      File('${tempDir.path}/data.json'),
      '${tempDir.path}/user.db',
    );
    await QuranRepository.instance.init();
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('progress is saved and restored from a backup', () async {
    final store = UserDataStore.instance;
    await GuidedPathwayProgress.completeDay('names_of_allah', 0);
    await GuidedPathwayProgress.completeDay('names_of_allah', 1);
    final backup = store.exportSnapshot();

    await store.resetAllData();
    expect(GuidedPathwayProgress.completedDays('names_of_allah'), isEmpty);

    await store.replaceAllUserData(backup);
    expect(GuidedPathwayProgress.completedDays('names_of_allah'), {0, 1});
  });

  testWidgets('completing today unlocks the next day', (tester) async {
    final pathway = CuratedPathwaysRegistry.pathways.first;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: PathwayJourneyScreen(pathway: pathway),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('أتممت اليوم'), findsOneWidget);
    await tester.runAsync(
      () => GuidedPathwayProgress.completeDay(pathway.id, 0),
    );
    await tester.pumpAndSettle();

    expect(GuidedPathwayProgress.completedDays(pathway.id), {0});
    // Day 2 is now the open card.
    expect(find.text('أتممت اليوم'), findsOneWidget);
    expect(find.byIcon(AppIcons.check), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  test('completeDay marks streak day and uncompleteDay/resetPathway revert', () async {
    final day0 = DateTime(2026, 10, 19, 8);
    await GuidedPathwayProgress.completeDay('names_of_allah', 0, now: day0);
    expect(UserDataStore.instance.journey.streak(day0), 1);

    await GuidedPathwayProgress.uncompleteDay('names_of_allah', 0);
    expect(GuidedPathwayProgress.completedDays('names_of_allah'), isEmpty);

    await GuidedPathwayProgress.completeDay('names_of_allah', 0, now: day0);
    await GuidedPathwayProgress.resetPathway('names_of_allah');
    expect(GuidedPathwayProgress.completedDays('names_of_allah'), isEmpty);
  });

  testWidgets(
    'dismissing reflection sheet does not complete day even with prior note, saving does',
    (tester) async {
      final pathway = CuratedPathwaysRegistry.pathways.first;
      final first = pathway.verses.first;
      await tester.runAsync(
        () => UserDataStore.instance.saveTadbeer(
          surahNumber: first.surah,
          ayahNumber: first.ayah,
          answers: {1: 'تأمل سابق'},
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: PathwayJourneyScreen(pathway: pathway),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('وقفة تدبر'));
      await tester.tap(find.text('وقفة تدبر'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('إغلاق'));
      await tester.pumpAndSettle();
      expect(GuidedPathwayProgress.completedDays(pathway.id), isEmpty);

      await tester.ensureVisible(find.text('وقفة تدبر'));
      await tester.tap(find.text('وقفة تدبر'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'وقفتي الجديدة');
      await tester.ensureVisible(find.text('حفظ ما كتبت الآن وإنهاء'));
      await tester.runAsync(() async {
        await tester.tap(find.text('حفظ ما كتبت الآن وإنهاء'));
        // Real disk writes: slow CI runners need more than a fixed short wait.
        for (var i = 0;
            i < 50 && GuidedPathwayProgress.completedDays(pathway.id).isEmpty;
            i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      });
      await tester.pumpAndSettle();
      expect(GuidedPathwayProgress.completedDays(pathway.id), {0});
    },
  );

  testWidgets('completed day expands to show reflection summary and undo', (
    tester,
  ) async {
    final pathway = CuratedPathwaysRegistry.pathways.first;
    final first = pathway.verses.first;
    await tester.runAsync(() async {
      await UserDataStore.instance.saveTadbeer(
        surahNumber: first.surah,
        ayahNumber: first.ayah,
        answers: {1: 'أثر عظيم في القلب'},
      );
      await GuidedPathwayProgress.completeDay(pathway.id, 0);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: PathwayJourneyScreen(pathway: pathway),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.textContaining('اليوم ١'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('اليوم ١'));
    await tester.pumpAndSettle();

    expect(find.text('وقفتي'), findsOneWidget);
    expect(find.textContaining('أثر عظيم في القلب'), findsOneWidget);

    await tester.ensureVisible(find.text('تراجع'));
    await tester.runAsync(() async {
      await tester.tap(find.text('تراجع'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(GuidedPathwayProgress.completedDays(pathway.id), isEmpty);
  });

  testWidgets('completing all days shows restart action and resets pathway', (
    tester,
  ) async {
    final pathway = CuratedPathwaysRegistry.pathways.first;
    await tester.runAsync(() async {
      for (var i = 0; i < pathway.verses.length; i++) {
        await GuidedPathwayProgress.completeDay(pathway.id, i);
      }
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: PathwayJourneyScreen(pathway: pathway),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('أتممت المسار، بارك الله فيك'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('إعادة المسار'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(GuidedPathwayProgress.completedDays(pathway.id), isEmpty);
  });

  testWidgets('GuidedPathwaysScreen status filters show matching pathways', (
    tester,
  ) async {
    final first = CuratedPathwaysRegistry.pathways.first;
    final second = CuratedPathwaysRegistry.pathways[1];
    await tester.runAsync(() async {
      for (var i = 0; i < first.verses.length; i++) {
        await GuidedPathwayProgress.completeDay(first.id, i);
      }
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const GuidedPathwaysScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('مكتمل'));
    await tester.pumpAndSettle();
    expect(find.text(first.title), findsOneWidget);
    expect(find.text(second.title), findsNothing);

    await tester.tap(find.text('قيد التقدم'));
    await tester.pumpAndSettle();
    expect(find.text(first.title), findsNothing);
    expect(find.text(second.title), findsNothing);
  });
}
