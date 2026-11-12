import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/app.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/core/design_system/design_system.dart';
import 'package:tadbeer/data/models/user_settings_model.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/data/storage/user_database.dart';
import 'package:tadbeer/features/quran/qcf/qcf_layout.dart';
import 'package:tadbeer/features/quran/screens/quran_page_view.dart';
import 'package:tadbeer/features/quran/screens/quran_screen.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_spread_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
    await QcfLayout.instance.init();
  });

  tearDownAll(() async {
    await UserDatabase.instance.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget app(int page) => AppLocalizationScope(
    currentLanguage: AppLanguage.arabic,
    strings: AppStrings(AppLanguage.arabic),
    onLanguageChanged: (_) {},
    child: MaterialApp(
      scrollBehavior: const TadbeerScrollBehavior(),
      home: QuranScreen(key: ValueKey(page), initialPage: page),
    ),
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

  FuturisticIconButton bottomButtonByTooltip(
    WidgetTester tester,
    String tooltip,
  ) =>
      tester.widget<FuturisticIconButton>(
        find.ancestor(
          of: find.byTooltip(tooltip),
          matching: find.byType(FuturisticIconButton),
        ),
      );

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

  testWidgets(
    'bottom bar Next/Previous buttons step cleanly across two-page spreads from odd and even pages and respect boundaries',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.runAsync(
        () => UserDataStore.instance.setMushafStyle(MushafStyle.text),
      );

      final l10n = AppStrings(AppLanguage.arabic);
      await tester.pumpWidget(app(1));
      await tester.pump();
      expect(shownPages(tester), [1, 2]);

      // Reveal top & bottom bars.
      await tester.tap(find.byType(QuranScreen));
      await tester.pumpAndSettle();

      expect(bottomButtonByTooltip(tester, l10n.previousPage).isEnabled, isFalse);
      expect(bottomButtonByTooltip(tester, l10n.nextPage).isEnabled, isTrue);

      // Even on odd page 1, Next must move to [3, 4] rather than staying on [1, 2].
      await tester.tap(find.byTooltip(l10n.nextPage));
      await tester.pumpAndSettle();
      expect(shownPages(tester), [3, 4]);
      expect(find.textContaining('ص ٣ من ٦٠٤'), findsOneWidget);
      expect(bottomButtonByTooltip(tester, l10n.previousPage).isEnabled, isTrue);
      expect(bottomButtonByTooltip(tester, l10n.nextPage).isEnabled, isTrue);

      // Jump to even page 4 inside spread [3, 4] via dialog: page 4 stays selected.
      await tester.tap(find.textContaining('ص ٣ من ٦٠٤'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '4');
      await tester.tap(find.text(l10n.go));
      await tester.pumpAndSettle();
      expect(shownPages(tester), [3, 4]);
      expect(find.textContaining('ص ٤ من ٦٠٤'), findsOneWidget);

      // From even page 4, Previous must return to [1, 2] rather than staying on [3, 4].
      await tester.tap(find.byTooltip(l10n.previousPage));
      await tester.pumpAndSettle();
      expect(shownPages(tester), [1, 2]);
      expect(find.textContaining('ص ١ من ٦٠٤'), findsOneWidget);

      // At final spread [603, 604], Next is disabled even when starting on odd page 603.
      await tester.pumpWidget(app(603));
      await tester.pump();
      await tester.tap(find.byType(QuranScreen));
      await tester.pumpAndSettle();
      expect(shownPages(tester), [603, 604]);
      expect(bottomButtonByTooltip(tester, l10n.nextPage).isEnabled, isFalse);
      expect(bottomButtonByTooltip(tester, l10n.previousPage).isEnabled, isTrue);

      await tester.tap(find.byTooltip(l10n.previousPage));
      await tester.pumpAndSettle();
      expect(shownPages(tester), [601, 602]);
    },
  );

  Future<void> mouseFling(
    WidgetTester tester,
    Finder finder,
    Offset offset, {
    Offset? startAt,
  }) async {
    var elapsed = Duration.zero;
    const stepDelay = Duration(milliseconds: 16);
    final origin = startAt ?? tester.getCenter(finder);
    final gesture = await tester.startGesture(
      origin,
      kind: PointerDeviceKind.mouse,
    );
    const steps = 6;
    for (var i = 0; i < steps; i++) {
      elapsed += stepDelay;
      await gesture.moveBy(offset / steps.toDouble(), timeStamp: elapsed);
      await tester.pump(stepDelay);
    }
    elapsed += stepDelay;
    await gesture.up(timeStamp: elapsed);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets(
    'mouse dragging turns two-page QCF Madinah spreads forward and backward smoothly',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.runAsync(
        () => UserDataStore.instance.setMushafStyle(MushafStyle.madinah),
      );
      await tester.pumpWidget(app(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(shownPages(tester), [1, 2]);

      await mouseFling(
        tester,
        find.byType(PageView),
        const Offset(500, 0),
        startAt: const Offset(300, 360),
      );
      expect(shownPages(tester), [3, 4]);
      expect(tester.takeException(), isNull);

      await mouseFling(
        tester,
        find.byType(PageView),
        const Offset(500, 0),
        startAt: const Offset(300, 360),
      );
      expect(shownPages(tester), [5, 6]);
      expect(tester.takeException(), isNull);

      await mouseFling(
        tester,
        find.byType(PageView),
        const Offset(-500, 0),
        startAt: const Offset(960, 360),
      );
      expect(shownPages(tester), [3, 4]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'desktop keyboard arrows turn spreads in RTL direction and stay inactive in dialogs',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.runAsync(
        () => UserDataStore.instance.setMushafStyle(MushafStyle.text),
      );
      await tester.pumpWidget(app(1));
      await tester.pump();
      expect(shownPages(tester), [1, 2]);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(shownPages(tester), [3, 4]);

      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();
      expect(shownPages(tester), [5, 6]);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(shownPages(tester), [3, 4]);

      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pumpAndSettle();
      expect(shownPages(tester), [1, 2]);

      // Opening jump-to-page dialog must not let ArrowLeft flip pages behind the modal.
      await tester.tap(find.byType(QuranScreen));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('ص ١ من ٦٠٤'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(shownPages(tester), [1, 2]);

      // Jumping directly to even page 2 on same spread updates badge without snapping back.
      await tester.enterText(find.byType(TextField), '2');
      await tester.tap(find.text(AppStrings(AppLanguage.arabic).go));
      await tester.pumpAndSettle();
      expect(shownPages(tester), [1, 2]);
      expect(find.textContaining('ص ٢ من ٦٠٤'), findsOneWidget);
    },
  );
}
