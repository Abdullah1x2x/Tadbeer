import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/core/theme/theme.dart';
import 'package:tadbeer/core/design_system/app_icons.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/features/duas/data/adhkar_repository.dart';
import 'package:tadbeer/features/duas/screens/morning_evening_adhkar_screen.dart';
import 'package:tadbeer/features/tasbeeh/tasbeeh_model.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    final plex = FontLoader('IBMPlexSansArabic')
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Bold.ttf'));
    await plex.load();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_streak_sets_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
  });

  tearDown(() {
    TasbeehRepository.instance.onTargetReached = null;
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  bool activeToday() =>
      UserDataStore.instance.journey.isActiveOn(DateTime.now());

  test('a tasbeeh round reports reaching its target once', () {
    final repo = TasbeehRepository.instance;
    var reached = 0;
    repo.onTargetReached = () => reached++;
    repo.setTarget(33);
    repo.resetCurrentCount();
    for (var i = 0; i < 32; i++) {
      repo.increment();
    }
    expect(reached, 0);
    repo.increment();
    expect(reached, 1);
    repo.increment();
    expect(reached, 1);
  });

  testWidgets('finishing the morning adhkar counts the day', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AppLocalizationScope(
        currentLanguage: AppLanguage.arabic,
        strings: const AppStrings(AppLanguage.arabic),
        onLanguageChanged: (_) {},
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MorningEveningAdhkarScreen(
            initialCategory: AdhkarCategory.morning,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(activeToday(), isFalse);

    final total = AdhkarRepository.instance
        .getAdhkar(AdhkarCategory.morning)
        .fold<int>(0, (sum, item) => sum + item.repeatCount);
    // Unfinished counters show a tap icon; finished ones a check.
    final counter = find.byIcon(AppIcons.handTap).hitTestable();
    for (var taps = 0; taps < total; taps++) {
      // Scroll until an unfinished dhikr's counter is on screen.
      for (var s = 0; s < 40 && counter.evaluate().isEmpty; s++) {
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pump(const Duration(milliseconds: 300));
      }
      await tester.tap(counter.first);
      await tester.pump(const Duration(milliseconds: 200));
      if (taps < total - 1) expect(activeToday(), isFalse);
    }

    await tester.pump(const Duration(milliseconds: 500));
    expect(activeToday(), isTrue);
    expect(find.text('أتممت الأذكار، واحتُسب يومك في رحلتك'), findsOneWidget);
  });
}
