import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/data/storage/user_database.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/features/quran/screens/quran_page_view.dart';
import 'package:tadbeer/features/quran/screens/quran_screen.dart';
import 'package:tadbeer/features/quran/widgets/ayah_action_sheet.dart';
import 'package:tadbeer/features/quran/widgets/quran_side_menu.dart';
import 'package:tadbeer/features/search/search_screen.dart';
import 'package:tadbeer/core/design_system/app_icons.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late File testFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_toolbar_test_');
    testFile = File('${tempDir.path}/test_toolbar.json');
    await UserDataStore.instance.init(testFile);
    await QuranRepository.instance.init();
    await UserDataStore.instance.updateSettings(
      UserDataStore.instance.settings.copyWith(
        hideTadbeerIntroPermanently: true,
      ),
    );
  });

  tearDown(() async {
    await UserDatabase.instance.close();
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  Widget buildTestScreen() {
    return AppLocalizationScope(
      currentLanguage: AppLanguage.arabic,
      strings: const AppStrings(AppLanguage.arabic),
      onLanguageChanged: (_) {},
      child: const MaterialApp(home: QuranScreen(initialPage: 112)),
    );
  }

  group('QuranScreen Toolbar Layout & Interaction Tests', () {
    testWidgets(
      'Toolbar & bottom navigation bar are hidden by default and toggle on tap',
      (tester) async {
        await tester.pumpWidget(buildTestScreen());
        await tester.pumpAndSettle();

        final topBarOpacityFinder = find
            .descendant(
              of: find.byType(SafeArea),
              matching: find.byType(AnimatedOpacity),
            )
            .first;

        // 1. Hidden by default
        AnimatedOpacity opacityWidget = tester.widget(topBarOpacityFinder);
        expect(opacityWidget.opacity, 0.0);

        // 2. Tap page to reveal toolbar and bottom navigation bar
        await tester.tap(find.byType(QuranScreen));
        await tester.pumpAndSettle();

        opacityWidget = tester.widget(topBarOpacityFinder);
        expect(opacityWidget.opacity, 1.0);

        // 3. Tap page again to hide them
        await tester.tap(find.byType(QuranScreen));
        await tester.pumpAndSettle();

        opacityWidget = tester.widget(topBarOpacityFinder);
        expect(opacityWidget.opacity, 0.0);
      },
    );

    testWidgets('Swipe does NOT show toolbar automatically', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      final topBarOpacityFinder = find
          .descendant(
            of: find.byType(SafeArea),
            matching: find.byType(AnimatedOpacity),
          )
          .first;

      // Swipe horizontally to next page
      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();

      final opacityWidget = tester.widget<AnimatedOpacity>(topBarOpacityFinder);
      expect(opacityWidget.opacity, 0.0);
    });

    testWidgets(
      'Top bar has ☰ and action icons (without page button); Bottom bar has page navigation and jump dialog',
      (tester) async {
        await tester.pumpWidget(buildTestScreen());
        await tester.pumpAndSettle();

        // Tap to reveal toolbar & bottom bar
        await tester.tap(find.byType(QuranScreen));
        await tester.pumpAndSettle();

        // Top bar buttons
        final menuFinder = find.byIcon(AppIcons.list);
        final searchFinder = find.byIcon(AppIcons.magnifyingGlass);
        final meaningsTopFinder = find.byTooltip('معاني كلمات الصفحة');
        final fontSizeFinder = find.byIcon(AppIcons.textAa);

        expect(menuFinder, findsOneWidget);
        expect(searchFinder, findsOneWidget);
        expect(meaningsTopFinder, findsOneWidget);
        expect(fontSizeFinder, findsOneWidget);

        // Bottom navigation bar items
        final pageBadgeFinder = find.textContaining('ص ١١٢ من ٦٠٤');
        final prevPageFinder = find.byTooltip('الصفحة السابقة');
        final nextPageFinder = find.byTooltip('الصفحة التالية');
        final sliderFinder = find.byType(Slider);

        expect(pageBadgeFinder, findsOneWidget);
        expect(prevPageFinder, findsOneWidget);
        expect(nextPageFinder, findsOneWidget);
        expect(sliderFinder, findsOneWidget);

        // Verify obsolete items are NOT in toolbar
        expect(find.byIcon(AppIcons.dotsThreeVertical), findsNothing);
        expect(find.byIcon(AppIcons.arrowLeft), findsNothing);
        expect(find.byIcon(AppIcons.arrowRight), findsNothing);

        // Test ☰ opens Drawer
        await tester.tap(menuFinder);
        await tester.pumpAndSettle();
        expect(find.byType(QuranSideMenu), findsOneWidget);

        // Close Drawer
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        // Test Page jump dialog from bottom bar badge
        await tester.tap(pageBadgeFinder);
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('الانتقال إلى صفحة'), findsOneWidget);

        // Cancel dialog
        await tester.tap(find.text('إلغاء'));
        await tester.pumpAndSettle();

        // Test Search button opens SearchScreen
        await tester.tap(searchFinder);
        await tester.pumpAndSettle();
        expect(find.byType(SearchScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Word meanings window opens from bottom bar / top bar and dismisses when tapping outside',
      (tester) async {
        await tester.pumpWidget(buildTestScreen());
        await tester.pumpAndSettle();

        // Reveal controls
        await tester.tap(find.byType(QuranScreen));
        await tester.pumpAndSettle();

        // Open word meanings window via top bar button
        await tester.tap(find.byTooltip('معاني كلمات الصفحة'));
        await tester.pumpAndSettle();

        // Word meanings window is visible
        expect(find.textContaining('معاني كلمات صفحة'), findsOneWidget);

        // Tap outside the meanings window (e.g., at top area)
        await tester.tapAt(const Offset(200, 100));
        await tester.pumpAndSettle();

        // Window dismisses
        final panelFinder = find
            .descendant(
              of: find.byType(QuranScreen),
              matching: find.byType(AnimatedOpacity),
            )
            .last;
        final panelOpacity = tester.widget<AnimatedOpacity>(panelFinder);
        expect(panelOpacity.opacity, 0.0);
      },
    );

    testWidgets(
      'Tapping an Ayah opens nothing; a long press opens the rosette of actions',
      (tester) async {
        await tester.pumpWidget(buildTestScreen());
        await tester.pumpAndSettle();

        final qpv = tester.widget<QuranPageView>(find.byType(QuranPageView));
        final pageAyah = QuranRepository.instance.getPage(112).ayahs.first;

        // 1. Quick tap does NOT open AyahActionSheet
        qpv.onAyahTap?.call(pageAyah);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1500));
        await tester.pumpAndSettle();
        expect(find.byType(AyahActionSheet), findsNothing);

        // 2. Long press opens the rosette (the sheet is for screen readers)
        qpv.onAyahLongPress?.call(pageAyah);
        await tester.pumpAndSettle();
        expect(find.byType(AyahActionSheet), findsNothing);

        // Verify the options are present
        expect(find.text('وقفة تدبر'), findsOneWidget);
        expect(find.text('رابط آيات'), findsOneWidget);
        expect(find.text('ملاحظة'), findsOneWidget);
        expect(find.text('علامة'), findsOneWidget);
        expect(find.text('تمييز'), findsOneWidget);
        expect(find.text('نسخ'), findsOneWidget);

        // Tapping outside closes it
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(find.text('رابط آيات'), findsNothing);
      },
    );
  });
}
