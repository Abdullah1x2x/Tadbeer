import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/core/theme/theme.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/features/onboarding/tour/home_walkthrough.dart';
import 'package:tadbeer/features/onboarding/tour/section_guide.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_guides_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<BuildContext> pumpHost(
    WidgetTester tester, {
    required bool dark,
  }) async {
    late BuildContext context;
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppLocalizationScope(
        currentLanguage: AppLanguage.arabic,
        strings: const AppStrings(AppLanguage.arabic),
        onLanguageChanged: (_) {},
        child: MaterialApp(
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(key: HomeWalkthrough.searchBar, height: 40),
                Expanded(
                  child: Builder(
                    builder: (c) {
                      context = c;
                      return SizedBox.expand(key: HomeWalkthrough.ayahCard);
                    },
                  ),
                ),
                SizedBox(key: HomeWalkthrough.quranCard, height: 80),
                SizedBox(key: HomeWalkthrough.homeTab, height: 40),
                SizedBox(key: HomeWalkthrough.moreTab, height: 40),
              ],
            ),
          ),
        ),
      ),
    );
    return context;
  }

  Future<void> frames(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';

    testWidgets('every guide fits a small phone with large text ($mode)', (
      tester,
    ) async {
      final context = await pumpHost(tester, dark: dark);
      for (final topic in GuideTopic.values) {
        await tester.runAsync(() async {
          SectionGuide.show(context, topic).ignore();
          await Future<void>.delayed(const Duration(milliseconds: 60));
        });
        await frames(tester);
        expect(tester.takeException(), isNull, reason: topic.name);
        Navigator.of(context).pop();
        await frames(tester);
      }
    });

    testWidgets('the walkthrough fits a small phone with large text ($mode)', (
      tester,
    ) async {
      final context = await pumpHost(tester, dark: dark);
      await tester.runAsync(() async {
        HomeWalkthrough.show(context).ignore();
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await frames(tester);
      for (var i = 0; i < 5; i++) {
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('التالي'));
        await frames(tester);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
