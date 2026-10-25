import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/app/theme.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/home/home_screen.dart';
import 'package:tadbeer/features/journey/journey_screen.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';
import 'package:tadbeer/features/settings/settings_screen.dart';
import 'package:tadbeer/features/settings/user_settings_model.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    final amiri = FontLoader('Amiri')
      ..addFont(rootBundle.load('assets/fonts/Amiri-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Amiri-Bold.ttf'));
    await amiri.load();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_theme_test_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
  });

  tearDown(() {
    // AppColors is global: always leave the default palette for other tests.
    AppColors.use(AppColorTheme.navy);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('the chosen theme is saved and switches the colors', () {
    const settings = UserSettings(colorTheme: AppColorTheme.burgundy);
    final restored = UserSettings.fromJson(settings.toJson());
    expect(restored.colorTheme, AppColorTheme.burgundy);

    expect(AppColors.use(AppColorTheme.burgundy), isTrue);
    expect(AppColors.lightPrimary, ThemePalette.burgundy.lightPrimary);
    expect(AppColors.use(AppColorTheme.burgundy), isFalse);
    expect(
      AppTheme.lightTheme.colorScheme.primary,
      ThemePalette.burgundy.lightPrimary,
    );
  });

  for (final theme in AppColorTheme.values) {
    for (final dark in [false, true]) {
      testWidgets('main screens render in ${theme.name} (dark: $dark)', (
        tester,
      ) async {
        AppColors.use(theme);
        for (final screen in const [
          HomeScreen(),
          JourneyScreen(),
          SettingsScreen(),
        ]) {
          await tester.pumpWidget(
            AppLocalizationScope(
              currentLanguage: AppLanguage.arabic,
              strings: const AppStrings(AppLanguage.arabic),
              onLanguageChanged: (_) {},
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                home: screen,
              ),
            ),
          );
          await tester.pump(const Duration(seconds: 1));
          expect(tester.takeException(), isNull);
        }
      });
    }
  }
}
