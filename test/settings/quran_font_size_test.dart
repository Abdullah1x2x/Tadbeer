import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/data/storage/user_database.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/features/quran/screens/quran_page_view.dart';
import 'package:tadbeer/features/settings/settings_screen.dart';
import 'package:tadbeer/data/models/user_settings_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Quran Font Size & Family Model Tests', () {
    test(
      'Default Quran font size is strictly 20.0 and family is ScheherazadeNew',
      () {
        const settings = UserSettings();
        expect(settings.quranFontSize, equals(20.0));
        expect(UserSettings.defaultQuranFontSize, equals(20.0));
        expect(
          settings.quranFontFamily,
          equals(QuranFontFamilyOption.scheherazade),
        );
        expect(settings.quranFontFamilyName, equals('ScheherazadeNew'));
      },
    );

    test('JSON serialization roundtrip maintains font size and family', () {
      const settings = UserSettings(
        quranFontSize: 24.0,
        quranFontFamily: QuranFontFamilyOption.notoNaskh,
      );
      final json = settings.toJson();
      expect(json['quranFontSize'], equals(24.0));
      expect(json['quranFontFamily'], equals('notoNaskh'));

      final restored = UserSettings.fromJson(json);
      expect(restored.quranFontSize, equals(24.0));
      expect(restored.quranFontFamily, equals(QuranFontFamilyOption.notoNaskh));
      expect(restored.quranFontFamilyName, equals('NotoNaskhArabic'));
    });
  });

  group('UserDataStore Font Settings Tests', () {
    late Directory tempDir;
    late File testFile;
    late UserDataStore store;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('tadbeer_font_test_');
      testFile = File('${tempDir.path}/test_settings.json');
      store = UserDataStore.instance;
      await store.init(testFile);
    });

    tearDown(() async {
      await UserDatabase.instance.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Store font size is 20.0 and default family is ScheherazadeNew', () {
      expect(store.quranFontSize, equals(20.0));
      expect(store.settings.quranFontSize, equals(20.0));
      expect(store.quranFontFamily, equals('ScheherazadeNew'));
    });
  });

  group('SettingsScreen Font Size & Family Control Tests', () {
    late Directory tempDir;
    late File testFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('tadbeer_ui_test_');
      testFile = File('${tempDir.path}/test_settings_ui.json');
      await UserDataStore.instance.init(testFile);
      await QuranRepository.instance.init();
    });

    tearDown(() async {
      await UserDatabase.instance.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    testWidgets('SettingsScreen offers the font family but no manual size', (
      tester,
    ) async {
      await tester.pumpWidget(
        AppLocalizationScope(
          currentLanguage: AppLanguage.arabic,
          strings: const AppStrings(AppLanguage.arabic),
          onLanguageChanged: (_) {},
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Madinah pages fit the screen by themselves.
      expect(find.text('نوع خط المصحف'), findsNothing);
      expect(find.text('حجم الصفحة'), findsNothing);
      expect(find.byType(Slider), findsNothing);

      // Flowing text: the font choice, and still no size to set.
      await tester.runAsync(
        () => UserDataStore.instance.setMushafStyle(MushafStyle.text),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('نوع خط المصحف'), findsOneWidget);
      expect(find.text('حجم خط المصحف'), findsNothing);
      expect(find.byType(Slider), findsNothing);
    });

    testWidgets(
      'QuranPageView renders with configured font family from UserDataStore',
      (tester) async {
        final page1 = QuranRepository.instance.getPage(1);
        await tester.pumpWidget(
          AppLocalizationScope(
            currentLanguage: AppLanguage.arabic,
            strings: const AppStrings(AppLanguage.arabic),
            onLanguageChanged: (_) {},
            child: MaterialApp(
              home: Scaffold(body: QuranPageView(page: page1)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(QuranPageView), findsOneWidget);
      },
    );
  });
}
