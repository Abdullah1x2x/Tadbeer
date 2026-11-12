import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/data/models/user_settings_model.dart';
import 'package:tadbeer/data/quran/quran_models.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/data/storage/user_database.dart';
import 'package:tadbeer/features/quran/qcf/qcf_ayah_text.dart';
import 'package:tadbeer/features/quran/qcf/qcf_layout.dart';
import 'package:tadbeer/features/quran/screens/quran_screen.dart';
import 'package:tadbeer/features/quran/widgets/quran_side_menu.dart';

Widget _wrapApp(
  Widget child, {
  AppLanguage language = AppLanguage.arabic,
}) {
  return AppLocalizationScope(
    currentLanguage: language,
    strings: AppStrings(language),
    onLanguageChanged: (_) {},
    child: MaterialApp(home: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('phase1_quran_test_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await UserDataStore.instance.resetAllData();
    await QuranRepository.instance.init();
    await QcfLayout.instance.init();
  });

  tearDown(() async {
    await UserDatabase.instance.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('QcfAyahText resolves glyphs for ayahs shifted across page boundaries', (
    tester,
  ) async {
    final repo = QuranRepository.instance;
    final layout = QcfLayout.instance;
    Ayah? boundaryAyah;
    for (var p = 1; p <= 604 && boundaryAyah == null; p++) {
      for (final ayah in repo.getPage(p).ayahs) {
        final qcfPage = layout.pageOf(ayah.surahNumber, ayah.ayahNumber);
        if (qcfPage != null && qcfPage != ayah.page) {
          boundaryAyah = ayah;
          break;
        }
      }
    }

    expect(boundaryAyah, isNotNull);

    await tester.pumpWidget(
      _wrapApp(
        Scaffold(
          body: QcfAyahText(
            ayah: boundaryAyah!,
            fontSize: 20,
            color: Colors.black,
            fallback: const Text('FALLBACK_SENTINEL'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('FALLBACK_SENTINEL'), findsNothing);
    expect(find.byType(RichText), findsWidgets);
  });

  testWidgets('QuranScreen uses LTR UI chrome in English while keeping Mushaf PageView RTL', (
    tester,
  ) async {
    await tester.runAsync(
      () => UserDataStore.instance.setMushafStyle(MushafStyle.text),
    );

    await tester.pumpWidget(
      _wrapApp(
        const QuranScreen(initialPage: 1),
        language: AppLanguage.english,
      ),
    );
    await tester.pump();

    final scaffoldContext = tester.element(find.byType(Scaffold));
    final pagerContext = tester.element(
      find.byKey(const ValueKey('mushaf_pager_false')),
    );
    expect(Directionality.of(scaffoldContext), TextDirection.ltr);
    expect(Directionality.of(pagerContext), TextDirection.rtl);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('QuranScreen survives narrow-to-wide resize and TickerMode pause without PageController errors', (
    tester,
  ) async {
    await tester.runAsync(
      () => UserDataStore.instance.setMushafStyle(MushafStyle.text),
    );
    tester.view.physicalSize = const Size(420, 820);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      TickerMode(
        enabled: true,
        child: _wrapApp(const QuranScreen(initialPage: 1)),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('mushaf_pager_false')), findsOneWidget);

    tester.view.physicalSize = const Size(1200, 900);
    await tester.pump();
    expect(find.byKey(const ValueKey('mushaf_pager_true')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      TickerMode(
        enabled: false,
        child: _wrapApp(const QuranScreen(initialPage: 1)),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(
      TickerMode(
        enabled: true,
        child: _wrapApp(const QuranScreen(initialPage: 1)),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('QuranSideMenu searches surahs by English transliteration in English mode', (
    tester,
  ) async {
    final surahs = QuranRepository.instance.surahs;
    final kahf = surahs.firstWhere((s) => s.number == 18);
    final baqarah = surahs.firstWhere((s) => s.number == 2);

    await tester.pumpWidget(
      _wrapApp(
        Scaffold(
          body: QuranSideMenu(
            currentPage: 1,
            onPageSelected: (_) {},
          ),
        ),
        language: AppLanguage.english,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Kahf');
    await tester.pumpAndSettle();

    expect(find.text(kahf.name), findsOneWidget);
    expect(find.text(baqarah.name), findsNothing);
  });
}
