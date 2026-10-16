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
    'QuranPageView renders scroll indicators and keeps hint arrow visible until reaching bottom',
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

      final scrollable = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView));
      final controller = scrollable.controller!;

      // 1. Initially at top: chevron down icon is visible
      final chevronFinder = find.byIcon(Icons.keyboard_arrow_down_rounded);
      expect(chevronFinder, findsOneWidget);

      // 2. Scroll partway down (not reaching the bottom yet)
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -60));
      await tester.pumpAndSettle();

      // Verify chevron down icon REMAINS visible because there is still content below
      expect(chevronFinder, findsOneWidget);

      // 3. Jump all the way to the bottom
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();

      // When reaching the bottom, chevron indicator is hidden
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);

      // 4. Scroll back up to the top
      controller.jumpTo(0.0);
      await tester.pumpAndSettle();

      // Verify chevron reappears when scrolled back up
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    },
  );
}
