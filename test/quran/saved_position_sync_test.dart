import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/data/models/user_settings_model.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/features/quran/screens/quran_page_view.dart';
import 'package:tadbeer/features/quran/screens/quran_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_sync_test_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await UserDataStore.instance.setMushafStyle(MushafStyle.text);
    await QuranRepository.instance.init();
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  int? shownPage(WidgetTester tester) =>
      tester.widget<QuranPageView>(find.byType(QuranPageView).first).pageNumber;

  testWidgets('saving a setting leaves the page; a new position moves it', (
    tester,
  ) async {
    final controls = ValueNotifier(true);
    addTearDown(controls.dispose);
    await tester.pumpWidget(
      AppLocalizationScope(
        currentLanguage: AppLanguage.arabic,
        strings: const AppStrings(AppLanguage.arabic),
        onLanguageChanged: (_) {},
        child: MaterialApp(
          home: QuranScreen(initialPage: 10, controlsVisible: controls),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(shownPage(tester), 10);

    // The reciter is saved like this; the store tells every listener.
    await tester.runAsync(
      () => UserDataStore.instance.saveFeatureState('quran_audio', {
        'reciter': 'ar.husary',
      }),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(shownPage(tester), 10);

    await tester.runAsync(
      () => UserDataStore.instance.saveReadingPosition(
        page: 20,
        surahNumber: 2,
        ayahNumber: 142,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(shownPage(tester), 20);
  });
}
