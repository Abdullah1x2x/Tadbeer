import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/data/storage/user_database.dart';
import 'package:tadbeer/features/quran/widgets/quran_side_menu.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('side_menu_test_');
    final testFile = File('${tempDir.path}/test_side_menu.json');
    await UserDataStore.instance.init(testFile);
    await QuranRepository.instance.init();
  });

  tearDown(() async {
    await UserDatabase.instance.close();
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  Widget host({required int page, ValueChanged<int>? onSelect}) {
    return AppLocalizationScope(
      currentLanguage: AppLanguage.arabic,
      strings: const AppStrings(AppLanguage.arabic),
      onLanguageChanged: (_) {},
      child: MaterialApp(
        home: Scaffold(
          body: QuranSideMenu(
            currentPage: page,
            onPageSelected: onSelect ?? (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('QuranSideMenu auto-scrolls to active surah on open', (
    tester,
  ) async {
    // Page 518 is Surah 50 (سورة ق)
    await tester.pumpWidget(host(page: 518));
    await tester.pumpAndSettle();

    // Surah 50 should be in the viewport and visible
    expect(find.text('ق'), findsOneWidget);
    // Surah 1 (الفاتحة) is scrolled out of the initial viewport
    expect(find.text('الفاتحة'), findsNothing);
  });

  testWidgets('QuranSideMenu auto-scrolls to active juz when tab switched', (
    tester,
  ) async {
    // Page 518 is in Juz 26
    await tester.pumpWidget(host(page: 518));
    await tester.pumpAndSettle();

    // Switch to Juzs tab
    await tester.tap(find.text('الأجزاء'));
    await tester.pumpAndSettle();

    // Juz 26 should be visible in the viewport
    expect(find.text('ج ٢٦'), findsOneWidget);
    // Juz 1 should be scrolled out of view
    expect(find.text('ج ١'), findsNothing);
  });
}
