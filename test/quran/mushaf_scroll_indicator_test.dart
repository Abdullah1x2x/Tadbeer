import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';
import 'package:tadbeer/features/quran/screens/quran_page_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('scroll_ind_test_');
    final dataFile = File('${tempDir.path}/test_user_data.json');
    await UserDataStore.instance.init(dataFile);
    await QuranRepository.instance.init();
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets(
    'QuranPageView renders RawScrollbar and scroll indicators when content overflows',
    (tester) async {
      final page = QuranRepository.instance.getPage(100);

      // Constrain height tightly to guarantee overflow
      await tester.binding.setSurfaceSize(const Size(380, 420));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuranPageView(
              page: page,
              pageNumber: 100,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify RawScrollbar is present
      expect(find.byType(RawScrollbar), findsOneWidget);

      // Verify the chevron down icon indicator is displayed
      final chevronFinder = find.byIcon(Icons.keyboard_arrow_down_rounded);
      expect(chevronFinder, findsOneWidget);

      // Tap on chevron to trigger smooth scroll
      await tester.tap(chevronFinder);
      await tester.pumpAndSettle();

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    },
  );
}
