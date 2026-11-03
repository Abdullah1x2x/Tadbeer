import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/features/quran/screens/quran_page_view.dart';
import 'package:tadbeer/features/quran/screens/quran_screen.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_spread_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
  });

  tearDownAll(() => tempDir.delete(recursive: true));

  Widget app(int page) => AppLocalizationScope(
    currentLanguage: AppLanguage.arabic,
    strings: AppStrings(AppLanguage.arabic),
    onLanguageChanged: (_) {},
    child: MaterialApp(home: QuranScreen(initialPage: page)),
  );

  /// The pages on screen, right to left.
  List<int> shownPages(WidgetTester tester) {
    final view = tester.view;
    final screen = view.physicalSize / view.devicePixelRatio;
    final finder = find.byType(QuranPageView);
    final shown = [
      for (final element in finder.evaluate())
        if (tester.getCenter(find.byWidget(element.widget)).dx > 0 &&
            tester.getCenter(find.byWidget(element.widget)).dx < screen.width)
          element.widget as QuranPageView,
    ];
    shown.sort(
      (a, b) => tester
          .getCenter(find.byWidget(b))
          .dx
          .compareTo(tester.getCenter(find.byWidget(a)).dx),
    );
    return [for (final w in shown) w.pageNumber ?? w.page!.pageNumber];
  }

  testWidgets('a wide screen shows facing pages and each swipe changes both', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(4));
    await tester.pump();
    expect(shownPages(tester), [3, 4]);

    await tester.fling(find.byType(PageView), const Offset(600, 0), 1500);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(shownPages(tester), [5, 6]);
  });

  testWidgets('rotating keeps the reader on the same page', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(4));
    await tester.pump();

    tester.view.physicalSize = const Size(800, 1200);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(shownPages(tester), [4]);
  });
}
