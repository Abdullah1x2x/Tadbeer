import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/core/storage/user_database.dart';
import 'package:tadbeer/features/notes/note_model.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';
import 'package:tadbeer/features/quran/screens/quran_page_view.dart';
import 'package:tadbeer/features/quran/widgets/ayah_action_sheet.dart';
import 'package:tadbeer/features/tadbeer/tadbeer_intro_screen.dart';
import 'package:tadbeer/core/design_system/app_icons.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late File dataFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('marker_test_');
    dataFile = File('${tempDir.path}/test_user_data.json');
    await UserDataStore.instance.init(dataFile);
    await QuranRepository.instance.init();
  });

  tearDown(() async {
    await UserDatabase.instance.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget wrapWithApp(Widget child) {
    return AppLocalizationScope(
      currentLanguage: AppLanguage.arabic,
      strings: const AppStrings(AppLanguage.arabic),
      onLanguageChanged: (_) {},
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('QuranPageView Ayah Indicator Icons Tests', () {
    testWidgets('Normal State: displays no bookmark or note icon', (
      tester,
    ) async {
      final page1 = QuranRepository.instance.getPage(1);
      await tester.pumpWidget(wrapWithApp(QuranPageView(page: page1)));
      await tester.pumpAndSettle();

      expect(find.byIcon(AppIcons.bookmarkSimpleFill), findsNothing);
      expect(find.byIcon(AppIcons.notePencil), findsNothing);
    });

    testWidgets('Bookmarked State: displays bookmark icon next to ayah', (
      tester,
    ) async {
      final page1 = QuranRepository.instance.getPage(1);
      final ayah = QuranRepository.instance.getAyah(1, 1)!;
      await tester.runAsync(() async {
        await UserDataStore.instance.toggleBookmark(ayah);
      });

      await tester.pumpWidget(wrapWithApp(QuranPageView(page: page1)));
      await tester.pumpAndSettle();

      expect(find.byIcon(AppIcons.bookmarkSimpleFill), findsOneWidget);
      expect(find.byIcon(AppIcons.notePencil), findsNothing);
    });

    testWidgets('Note State: displays note icon next to ayah', (tester) async {
      final page1 = QuranRepository.instance.getPage(1);
      final ayah = QuranRepository.instance.getAyah(1, 1)!;
      await tester.runAsync(() async {
        await UserDataStore.instance.saveNote(
          type: NoteType.ayah,
          content: 'تدبر الآية',
          ayahId: 1,
          surahNumber: 1,
          ayahNumber: 1,
          page: 1,
          ayahText: ayah.text,
        );
      });

      await tester.pumpWidget(wrapWithApp(QuranPageView(page: page1)));
      await tester.pumpAndSettle();

      expect(find.byIcon(AppIcons.notePencil), findsOneWidget);
      expect(find.byIcon(AppIcons.bookmarkSimpleFill), findsNothing);
    });

    testWidgets(
      'Bookmarked + Note State: displays both bookmark and note icons',
      (tester) async {
        final page1 = QuranRepository.instance.getPage(1);
        final ayah = QuranRepository.instance.getAyah(1, 1)!;
        await tester.runAsync(() async {
          await UserDataStore.instance.toggleBookmark(ayah);
          await UserDataStore.instance.saveNote(
            type: NoteType.ayah,
            content: 'تدبر الآية',
            ayahId: 1,
            surahNumber: 1,
            ayahNumber: 1,
            page: 1,
            ayahText: ayah.text,
          );
        });

        await tester.pumpWidget(wrapWithApp(QuranPageView(page: page1)));
        await tester.pumpAndSettle();

        expect(find.byIcon(AppIcons.bookmarkSimpleFill), findsOneWidget);
        expect(find.byIcon(AppIcons.notePencil), findsOneWidget);
      },
    );
  });

  group('AyahActionSheet Centering & All 7 Actions Tests', () {
    testWidgets('Action sheet renders all 7 actions in equal Expanded slots', (
      tester,
    ) async {
      final ayah = QuranRepository.instance.getAyah(1, 1)!;

      await tester.pumpWidget(wrapWithApp(AyahActionSheet(ayah: ayah)));
      await tester.pumpAndSettle();

      expect(find.text('وقفة تدبر'), findsOneWidget);
      expect(find.text('رابط آيات'), findsOneWidget);
      expect(find.text('ملاحظة'), findsOneWidget);
      expect(find.text('حفظ'), findsOneWidget);
      expect(find.text('تمييز'), findsOneWidget);
      expect(find.text('نسخ'), findsOneWidget);
      expect(find.text('مشاركة'), findsOneWidget);

      final actionsRowFinder = find.byWidgetPredicate(
        (w) =>
            w is Row &&
            w.mainAxisAlignment == MainAxisAlignment.spaceEvenly &&
            w.children.length == 7,
      );
      expect(actionsRowFinder, findsOneWidget);

      final row = tester.widget<Row>(actionsRowFinder);
      for (final child in row.children) {
        expect(child, isA<Expanded>());
      }
    });
  });

  group('TadbeerIntroScreen Checkbox Offset Tests', () {
    testWidgets('Checkbox option is raised upwards with reduced top spacing', (
      tester,
    ) async {
      await tester.pumpWidget(wrapWithApp(const TadbeerIntroScreen()));
      await tester.pumpAndSettle();

      expect(find.text('لا تظهر لي هذه النافذة مرة أخرى'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final hasReducedSpacing = sizedBoxes.any((box) => box.height == 6.0);
      expect(
        hasReducedSpacing,
        isTrue,
        reason:
            'Intro screen option must be raised by ~10px using SizedBox(height: 6)',
      );
    });
  });
}
