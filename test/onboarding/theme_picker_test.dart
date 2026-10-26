import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/app.dart';
import 'package:tadbeer/app/theme.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/onboarding/theme_picker_screen.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';
import 'package:tadbeer/features/settings/user_settings_model.dart';
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

  testWidgets('a new install picks a look, then sees the welcome', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const TadbeerApp());
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ThemePickerScreen), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('عنابي'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 500));
    expect(UserDataStore.instance.settings.colorTheme, AppColorTheme.burgundy);
    expect(AppColors.lightPrimary, ThemePalette.burgundy.lightPrimary);

    await tester.tap(find.text('داكن'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(UserDataStore.instance.settings.themeMode, ThemeMode.dark);

    await tester.tap(find.text('ابدأ'));
    // Saving the choice is real I/O; the welcome opens once it is done.
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
    expect(tester.takeException(), isNull);
  });

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
}
