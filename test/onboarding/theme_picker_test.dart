import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/app.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/core/theme/theme.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/features/onboarding/name_screen.dart';
import 'package:tadbeer/features/onboarding/theme_picker_screen.dart';
import 'package:tadbeer/features/onboarding/tour/tour_screen.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/data/models/user_settings_model.dart';
import 'package:tadbeer/features/tadbeer/tadbeer_intro_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_picker_test_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
  });

  tearDown(() {
    AppColors.use(AppColorTheme.navy);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('settings saved before the picker existed count as chosen', () {
    expect(const UserSettings().themeChosen, isFalse);
    expect(
      UserSettings.fromJson(const {'themeMode': 'dark'}).themeChosen,
      isTrue,
    );
    final saved = const UserSettings().copyWith(themeChosen: false).toJson();
    expect(UserSettings.fromJson(saved).themeChosen, isFalse);
  });

  testWidgets(
    'a new install gives a name, picks a look, then sees the welcome',
    (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const TadbeerApp());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(NameScreen), findsOneWidget);
      // Continue stays off until a name is typed.
      final next = find.widgetWithText(FilledButton, 'متابعة');
      expect(tester.widget<FilledButton>(next).onPressed, isNull);
      await tester.enterText(find.byType(TextField), '  أحمد ');
      await tester.pump();
      await tester.tap(next);
      for (
        var i = 0;
        i < 20 && find.byType(ThemePickerScreen).evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(seconds: 1));
      expect(UserDataStore.instance.settings.userName, 'أحمد');
      expect(find.byType(ThemePickerScreen), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('عنابي'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        UserDataStore.instance.settings.colorTheme,
        AppColorTheme.burgundy,
      );
      expect(AppColors.lightPrimary, ThemePalette.burgundy.lightPrimary);

      await tester.tap(find.text('داكن'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(UserDataStore.instance.settings.themeMode, ThemeMode.dark);

      await tester.tap(find.text('ابدأ'));
      // Saving the choice is real I/O; the tour opens once it is done.
      for (
        var i = 0;
        i < 20 && find.byType(TourScreen).evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(TourScreen), findsOneWidget);
      expect(TourScreen.seen, isFalse);

      // Skipping the tour leads to the welcome, and the tour is not shown again.
      await tester.tap(find.text('تخطٍّ'));
      for (
        var i = 0;
        i < 20 && find.byType(TadbeerIntroScreen).evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(seconds: 2));
      expect(UserDataStore.instance.settings.themeChosen, isTrue);
      expect(find.byType(TadbeerIntroScreen), findsOneWidget);
      expect(TourScreen.seen, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the welcome comes in and ends fully shown', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TadbeerIntroScreen()));
    await tester.pump(const Duration(milliseconds: 100));
    final early = tester
        .widgetList<FadeTransition>(find.byType(FadeTransition))
        .map((f) => f.opacity.value)
        .toList();
    expect(early.any((o) => o < 1), isTrue);

    await tester.pump(const Duration(seconds: 2));
    final late = tester
        .widgetList<FadeTransition>(find.byType(FadeTransition))
        .map((f) => f.opacity.value);
    expect(late.every((o) => o == 1), isTrue);
  });

  testWidgets('with less motion the welcome shows at once', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: TadbeerIntroScreen()),
      ),
    );
    await tester.pump();
    final opacities = tester
        .widgetList<FadeTransition>(find.byType(FadeTransition))
        .map((f) => f.opacity.value);
    expect(opacities.every((o) => o == 1), isTrue);
  });

  testWidgets('the name can be skipped', (tester) async {
    await tester.pumpWidget(
      AppLocalizationScope(
        currentLanguage: AppLanguage.arabic,
        strings: const AppStrings(AppLanguage.arabic),
        onLanguageChanged: (_) {},
        child: MaterialApp(
          home: NameScreen(next: (_) => const Scaffold(body: Text('next'))),
        ),
      ),
    );
    await tester.tap(find.widgetWithText(TextButton, 'تخطّي'));
    // One frame to start the page transition, then let it run.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('next'), findsOneWidget);
    expect(UserDataStore.instance.settings.userName, isEmpty);
  });

  test('reminders address the reader by name', () {
    const ar = AppStrings(AppLanguage.arabic);
    const en = AppStrings(AppLanguage.english);
    expect(
      ar.toReader('أحمد', ar.reminderQuranBody),
      'أحمد، حان وقت تلاوة وتدبّر القرآن الكريم',
    );
    expect(ar.toReader('  ', ar.reminderQuranBody), ar.reminderQuranBody);
    expect(
      en.toReader('Sara', en.reminderAdhkarBody),
      'Sara, it’s time for your adhkar; remind your heart of Allah',
    );
    expect(
      ar.toReader('أحمد', ar.portionLeftTitle(5)),
      'أحمد، بقي من وردك اليوم ٥ صفحة',
    );
  });

  test('the name is saved, trimmed, and absent in old settings', () {
    final named = const UserSettings().copyWith(userName: '  ليلى ');
    expect(named.userName, 'ليلى');
    expect(UserSettings.fromJson(named.toJson()).userName, 'ليلى');
    expect(UserSettings.fromJson(const {'themeMode': 'dark'}).userName, '');
  });
}
