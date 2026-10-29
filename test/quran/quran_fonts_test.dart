import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/data/storage/user_database.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/features/quran/screens/quran_page_view.dart';
import 'package:tadbeer/data/models/user_settings_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late File testFile;

  setUpAll(() async {
    await QuranRepository.instance.init();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_fonts_test_');
    testFile = File('${tempDir.path}/test_settings.json');
    await UserDataStore.instance.init(testFile);
  });

  tearDown(() async {
    await UserDatabase.instance.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Open-Source Quran Fonts & Asset Verification', () {
    test('1. All bundled open-source Quran and UI font files exist', () {
      for (final fileName in [
        'ScheherazadeNew-Regular.ttf',
        'NotoNaskhArabic-Regular.ttf',
        'Harmattan-Regular.ttf',
        'Lateef-Regular.ttf',
        'AmiriQuran-Regular.ttf',
        'Amiri-Regular.ttf',
        'Amiri-Bold.ttf',
      ]) {
        final fontFile = File('assets/fonts/$fileName');
        expect(fontFile.existsSync(), isTrue, reason: '$fileName must exist');
        expect(fontFile.lengthSync(), greaterThan(50000));
      }
    });

    test(
      '2. Default Quran font family is ScheherazadeNew and can be switched',
      () async {
        expect(UserDataStore.instance.quranFontFamily, 'ScheherazadeNew');

        await UserDataStore.instance.setQuranFontFamily(
          QuranFontFamilyOption.notoNaskh,
        );
        expect(UserDataStore.instance.quranFontFamily, 'NotoNaskhArabic');

        await UserDataStore.instance.setQuranFontFamily(
          QuranFontFamilyOption.harmattan,
        );
        expect(UserDataStore.instance.quranFontFamily, 'Harmattan');

        await UserDataStore.instance.setQuranFontFamily(
          QuranFontFamilyOption.lateef,
        );
        expect(UserDataStore.instance.quranFontFamily, 'Lateef');

        await UserDataStore.instance.setQuranFontFamily(
          QuranFontFamilyOption.amiriQuran,
        );
        expect(UserDataStore.instance.quranFontFamily, 'AmiriQuran');
      },
    );

    test('3. Authentic Tanzil coverage across all 6,236 ayat with diacritics', () {
      final repo = QuranRepository.instance;
      expect(repo.allAyahs.length, 6236);

      for (final ayah in repo.allAyahs) {
        expect(
          ayah.text.trim().isNotEmpty,
          isTrue,
          reason:
              'Ayah ${ayah.surahNumber}:${ayah.ayahNumber} must have non-empty text',
        );
        expect(ayah.rawText.isNotEmpty, isTrue);
      }
    });

    testWidgets(
      '4. QuranPageView renders cleanly across all 5 Quran font families',
      (tester) async {
        final page1 = QuranRepository.instance.getPage(1);

        for (final option in QuranFontFamilyOption.values) {
          await tester.runAsync(() async {
            await UserDataStore.instance.setQuranFontFamily(option);
          });

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
        }
      },
    );
  });
}
