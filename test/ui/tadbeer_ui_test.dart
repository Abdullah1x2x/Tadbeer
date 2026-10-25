import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/app.dart';
import 'package:tadbeer/core/design_system/design_system.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';
import 'package:tadbeer/features/duas/duas_screen.dart';
import 'package:tadbeer/features/home/home_screen.dart';
import 'package:tadbeer/features/tadbeer/tadbeer_intro_screen.dart';
import 'package:tadbeer/features/notes/note_editor_screen.dart';
import 'package:tadbeer/features/notes/notes_screen.dart';
import 'package:tadbeer/features/quran/screens/quran_screen.dart';
import 'package:tadbeer/features/search/search_screen.dart';
import 'package:tadbeer/features/settings/settings_screen.dart';
import 'package:tadbeer/features/tasbeeh/tasbeeh_screen.dart';

/// Opacity of the floating bar's wrapper (0 while it is hidden for reading).
double barOpacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find
          .ancestor(
            of: find.byType(FloatingNavBar),
            matching: find.byType(Opacity),
          )
          .first,
    )
    .opacity;

void main() {
  late Directory tempDir;
  late File dataFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_ui_test_');
    dataFile = File('${tempDir.path}/test_user_data.json');
    await UserDataStore.instance.init(dataFile);
    await QuranRepository.instance.init();
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Tadbeer UI Flow Tests', () {
    testWidgets(
      'First Launch Shows Tadabbur Intro Screen with Verified Verse and Checkbox',
      (WidgetTester tester) async {
        await tester.pumpWidget(const TadbeerApp());
        await tester.pumpAndSettle();

        // Should show TadbeerIntroScreen
        expect(find.byType(TadbeerIntroScreen), findsOneWidget);
        // Should show checkbox "لا تظهر لي هذه النافذة مرة أخرى" (default: false)
        final checkboxTextFinder = find.text('لا تظهر لي هذه النافذة مرة أخرى');
        expect(checkboxTextFinder, findsOneWidget);
        final checkboxFinder = find.byType(Checkbox);
        final checkbox = tester.widget<Checkbox>(checkboxFinder);
        expect(checkbox.value, isFalse);

        // Should show continue button "متابعة"
        final continueFinder = find.text('متابعة');
        expect(continueFinder, findsOneWidget);
        await tester.ensureVisible(continueFinder);

        // Tapping "متابعة" without checking checkbox navigates to HomeScreen without permanent hiding
        await tester.tap(continueFinder);
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(
          UserDataStore.instance.settings.hideTadbeerIntroPermanently,
          isFalse,
        );
      },
    );

    testWidgets(
      'Checking "لا تظهر لي هذه النافذة مرة أخرى" and tapping "متابعة" persists permanent hiding',
      (WidgetTester tester) async {
        await tester.pumpWidget(const TadbeerApp());
        await tester.pumpAndSettle();

        expect(find.byType(TadbeerIntroScreen), findsOneWidget);

        // Tap the checkbox
        final checkboxFinder = find.byType(Checkbox);
        await tester.ensureVisible(checkboxFinder);
        await tester.tap(checkboxFinder);
        await tester.pumpAndSettle();
        expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);

        // Tap "متابعة" within runAsync because saving preference executes disk I/O
        final continueButton = find.text('متابعة');
        await tester.ensureVisible(continueButton);
        await tester.runAsync(() async {
          await tester.tap(continueButton);
          await Future.delayed(const Duration(milliseconds: 200));
        });
        await tester.pumpAndSettle();

        // Should now be on HomeScreen
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(
          UserDataStore.instance.settings.hideTadbeerIntroPermanently,
          isTrue,
        );

        // On next app start, should directly open HomeScreen
        await tester.pumpWidget(const TadbeerApp());
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(TadbeerIntroScreen), findsNothing);
      },
    );

    testWidgets('HomeScreen Displays Main Sections and Reading Position', (
      WidgetTester tester,
    ) async {
      // Ensure intro is hidden
      await tester.runAsync(() async {
        await UserDataStore.instance.updateSettings(
          UserDataStore.instance.settings.copyWith(
            hideTadbeerIntroPermanently: true,
          ),
        );
      });

      await tester.pumpWidget(const TadbeerApp());
      await tester.pumpAndSettle();

      // Check App Title
      expect(find.text('تَدْبِير'), findsOneWidget);

      // Check Main Sections (only the selected tab shows its name in the bar)
      expect(find.text('المصحف'), findsOneWidget);
      expect(find.text('الملاحظات'), findsOneWidget);

      // The floating bar puts the main sections side by side; icon-only
      // items stay reachable through their tooltips.
      expect(find.byType(FloatingNavBar), findsOneWidget);
      for (final label in [
        'الرئيسية',
        'المصحف',
        'الاستغفار',
        'الأدعية',
        'المزيد',
      ]) {
        expect(find.byTooltip(label), findsOneWidget);
      }

      // Verify side menu button is removed and settings button replaced it
      expect(find.byIcon(Icons.menu_rounded), findsNothing);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      // Verify tapping settings button opens SettingsScreen
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets(
      'QuranScreen top bar is hidden by default and toggles on tap with Search and Page jump',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          await UserDataStore.instance.updateSettings(
            UserDataStore.instance.settings.copyWith(
              hideTadbeerIntroPermanently: true,
            ),
          );
        });

        await tester.pumpWidget(const TadbeerApp());
        await tester.pumpAndSettle();

        // Tap Quran card on Home
        await tester.tap(find.text('المصحف').first);
        await tester.pumpAndSettle();

        // Should be on QuranScreen
        expect(find.byType(QuranScreen), findsOneWidget);

        // 1. As a tab, the reader opens with its bars (and the bottom
        // navigation) visible so the reader can see how to leave.
        final animatedOpacityFinder = find.descendant(
          of: find.byType(SafeArea),
          matching: find.byType(AnimatedOpacity),
        ).first;
        AnimatedOpacity opacityWidget = tester.widget(animatedOpacityFinder);
        expect(opacityWidget.opacity, 1.0);
        expect(barOpacity(tester), 1.0);

        // 2. Tapping the page hides the reading bars and the bottom bar...
        await tester.tapAt(const Offset(30, 80));
        await tester.pumpAndSettle();
        opacityWidget = tester.widget(animatedOpacityFinder);
        expect(opacityWidget.opacity, 0.0);
        expect(barOpacity(tester), 0.0);

        // ...and tapping again brings them back.
        await tester.tapAt(const Offset(30, 80));
        await tester.pumpAndSettle();
        opacityWidget = tester.widget(animatedOpacityFinder);
        expect(opacityWidget.opacity, 1.0);
        expect(barOpacity(tester), 1.0);

        // Verify Search button and Page Number button exist
        expect(find.byTooltip('البحث'), findsOneWidget);
        expect(find.textContaining('ص '), findsWidgets);

        // 3. Tap Page Number button to open jump-to-page dialog
        final pageButtonFinder = find
            .descendant(
              of: find.byType(QuranScreen),
              matching: find.textContaining('ص '),
            )
            .first;
        await tester.tap(pageButtonFinder);
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);

        // Cancel dialog
        await tester.tap(find.text('إلغاء'));
        await tester.pumpAndSettle();

        // 4. Tap page margin to hide reading bars again
        await tester.tapAt(const Offset(30, 80));
        await tester.pumpAndSettle();
        opacityWidget = tester.widget(animatedOpacityFinder);
        expect(opacityWidget.opacity, 0.0);

        // Reveal again to test search navigation
        await tester.tapAt(const Offset(30, 80));
        await tester.pumpAndSettle();

        // Tapping Search opens SearchScreen
        await tester.tap(find.byTooltip('البحث'));
        await tester.pumpAndSettle();
        expect(find.byType(SearchScreen), findsOneWidget);

        // Back returns to QuranScreen
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.byType(QuranScreen), findsOneWidget);

        // Returning from QuranScreen goes back to HomeScreen
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );

    testWidgets('Bottom bar switches between the main sections', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        await UserDataStore.instance.updateSettings(
          UserDataStore.instance.settings.copyWith(
            hideTadbeerIntroPermanently: true,
          ),
        );
      });

      await tester.pumpWidget(const TadbeerApp());
      await tester.pumpAndSettle();

      Finder tab(String label) => find.byTooltip(label);

      await tester.tap(tab('المصحف'));
      await tester.pumpAndSettle();
      expect(find.byType(QuranScreen), findsOneWidget);

      await tester.tap(tab('الاستغفار'));
      await tester.pumpAndSettle();
      expect(find.byType(TasbeehScreen), findsOneWidget);
      // A tab has nothing to go back to, so no back arrow is shown.
      expect(find.byType(BackButton), findsNothing);

      await tester.tap(tab('الأدعية'));
      await tester.pumpAndSettle();
      expect(find.byType(DuasScreen), findsOneWidget);

      // System back from a tab returns to Home.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('NotesScreen opens NoteEditorScreen and saves a new note', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        await UserDataStore.instance.updateSettings(
          UserDataStore.instance.settings.copyWith(
            hideTadbeerIntroPermanently: true,
          ),
        );
      });

      await tester.pumpWidget(const TadbeerApp());
      await tester.pumpAndSettle();

      // Open Notes from Home
      await tester.ensureVisible(find.text('الملاحظات'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الملاحظات'));
      await tester.pumpAndSettle();
      expect(find.byType(NotesScreen), findsOneWidget);

      // Tap Add Note FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Should be on NoteEditorScreen
      expect(find.byType(NoteEditorScreen), findsOneWidget);
      expect(find.text('ملاحظة حرة'), findsOneWidget);

      // Enter title and content
      final titleField = find.byType(TextField).first;
      final contentField = find.byType(TextField).last;

      await tester.enterText(titleField, 'وقفة تدبرية');
      await tester.enterText(contentField, 'تأمل في عظمة الخالق سبحانه وتعالى');
      await tester.pumpAndSettle();

      // Tap Save button in AppBar within runAsync for real disk I/O
      final saveButton = find.byIcon(Icons.check);
      expect(saveButton, findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(saveButton);
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();

      // Should return to NotesScreen
      expect(find.byType(NotesScreen), findsOneWidget);
      expect(find.text('وقفة تدبرية'), findsOneWidget);
    });

    testWidgets(
      'TadbeerIntroScreen adapts gracefully to small phone viewport without overflow',
      (WidgetTester tester) async {
        // Set small phone screen size (360x600)
        tester.view.physicalSize = const Size(360, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const TadbeerApp());
        await tester.pumpAndSettle();

        expect(find.byType(TadbeerIntroScreen), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
        expect(find.text('متابعة'), findsOneWidget);
        expect(find.text('لا تظهر لي هذه النافذة مرة أخرى'), findsOneWidget);
      },
    );

    testWidgets(
      'HomeScreen adapts gracefully to small phone viewport (360x600) without overflow',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          await UserDataStore.instance.updateSettings(
            UserDataStore.instance.settings.copyWith(
              hideTadbeerIntroPermanently: true,
            ),
          );
        });

        // Set small phone screen size (360x600)
        tester.view.physicalSize = const Size(360, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const TadbeerApp());
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
        // Only the selected tab (Home) shows its name in the bar.
        expect(find.text('المصحف'), findsOneWidget);
        expect(find.text('الأدعية'), findsOneWidget);
        expect(find.text('معاني الكلمات'), findsOneWidget);
        expect(find.text('الملاحظات'), findsOneWidget);
        expect(find.text('روابط الآيات'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Secondary tools live in the "More" tab.
        await tester.tap(find.byTooltip('المزيد'));
        await tester.pumpAndSettle();
        for (final label in [
          'الملاحظات',
          'المحفوظات',
          'المميزة',
          'التنبيهات',
          'النسخ الاحتياطي',
        ]) {
          await tester.scrollUntilVisible(
            find.text(label),
            120,
            scrollable: find.byType(Scrollable).first,
          );
          expect(find.text(label), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  });
}

