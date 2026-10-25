import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/theme.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/focus/focus_mode_screen.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_focus_test_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('shows one verse and swipes to the next', (tester) async {
    final first = QuranRepository.instance.getAyah(1, 1)!;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: FocusModeScreen(startAyah: first),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('سُورَةُ الفاتحة'), findsWidgets);
    expect(find.text('وقفة تدبر'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(400, 0), 1500);
    await tester.pump(const Duration(seconds: 1));
    final state = tester.widget<PageView>(find.byType(PageView));
    expect(state.controller!.page!.round(), 1);

    // Moving from Al-Fatiha 7 to Al-Baqarah 1 completes page 1.
    final pv = tester.widget<PageView>(find.byType(PageView)).controller!;
    pv.jumpToPage(6);
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() async {
      pv.jumpToPage(7);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump(const Duration(seconds: 1));
    expect(
      UserDataStore.instance.journey.dailyPages.values.any(
        (pages) => pages.contains(1),
      ),
      isTrue,
    );

    // Breathing circle toggles on.
    await tester.tap(find.byTooltip('تنفّس بهدوء'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('شهيق…'), findsOneWidget);

    // Unmount so the looping animations stop before the test ends.
    await tester.pumpWidget(const SizedBox());
  });
}
