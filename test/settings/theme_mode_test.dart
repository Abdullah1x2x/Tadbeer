import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/data/storage/user_database.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/features/settings/settings_screen.dart';
import 'package:tadbeer/core/design_system/app_icons.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsScreen Theme Mode Selector Tests', () {
    late Directory tempDir;
    late File testFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('tadbeer_theme_test_');
      testFile = File('${tempDir.path}/test_settings_theme.json');
      await UserDataStore.instance.init(testFile);
      await QuranRepository.instance.init();
    });

    tearDown(() async {
      await UserDatabase.instance.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    testWidgets(
      'SettingsScreen renders all 3 theme option buttons (Light, Dark, System)',
      (tester) async {
        await tester.pumpWidget(
          AppLocalizationScope(
            currentLanguage: AppLanguage.arabic,
            strings: const AppStrings(AppLanguage.arabic),
            onLanguageChanged: (_) {},
            child: const MaterialApp(home: SettingsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Verify section header and theme title
        expect(find.text('المظهر'), findsOneWidget);
        expect(find.text('السمة'), findsOneWidget);

        // Verify all 3 theme buttons are rendered
        expect(find.text('فاتح'), findsWidgets);
        expect(find.text('داكن'), findsOneWidget);
        expect(find.text('تلقائي'), findsOneWidget);

        // Verify the 3 theme icons are rendered
        expect(find.byIcon(AppIcons.sun), findsOneWidget);
        expect(find.byIcon(AppIcons.moon), findsOneWidget);
        expect(find.byIcon(AppIcons.circleHalf), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping Dark theme button updates UserDataStore to ThemeMode.dark',
      (tester) async {
        await tester.pumpWidget(
          AppLocalizationScope(
            currentLanguage: AppLanguage.arabic,
            strings: const AppStrings(AppLanguage.arabic),
            onLanguageChanged: (_) {},
            child: const MaterialApp(home: SettingsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Default should be Light
        expect(
          UserDataStore.instance.settings.themeMode,
          equals(ThemeMode.light),
        );

        // Tap the Dark theme button
        await tester.tap(find.byIcon(AppIcons.moon));
        await tester.pumpAndSettle();

        // Verify UserDataStore updated to dark
        expect(
          UserDataStore.instance.settings.themeMode,
          equals(ThemeMode.dark),
        );
      },
    );

    testWidgets(
      'Tapping System theme button updates UserDataStore to ThemeMode.system',
      (tester) async {
        await tester.pumpWidget(
          AppLocalizationScope(
            currentLanguage: AppLanguage.arabic,
            strings: const AppStrings(AppLanguage.arabic),
            onLanguageChanged: (_) {},
            child: const MaterialApp(home: SettingsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Tap the System theme button
        await tester.tap(find.byIcon(AppIcons.circleHalf));
        await tester.pumpAndSettle();

        // Verify UserDataStore updated to system
        expect(
          UserDataStore.instance.settings.themeMode,
          equals(ThemeMode.system),
        );

        // Tap back to Light
        await tester.tap(find.byIcon(AppIcons.sun));
        await tester.pumpAndSettle();

        expect(
          UserDataStore.instance.settings.themeMode,
          equals(ThemeMode.light),
        );
      },
    );

    testWidgets(
      'SettingsScreen renders localized theme labels in English locale',
      (tester) async {
        await tester.pumpWidget(
          AppLocalizationScope(
            currentLanguage: AppLanguage.english,
            strings: const AppStrings(AppLanguage.english),
            onLanguageChanged: (_) {},
            child: const MaterialApp(home: SettingsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Appearance'), findsOneWidget);
        expect(find.text('Theme'), findsOneWidget);
        expect(find.text('Light'), findsWidgets);
        expect(find.text('Dark'), findsOneWidget);
        expect(find.text('System'), findsOneWidget);
      },
    );
  });
}
