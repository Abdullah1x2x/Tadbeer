import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/features/quran/screens/quran_page_view.dart';
import 'package:tadbeer/features/quran/screens/quran_screen.dart';

Widget buildFrame(Widget child, {Size size = const Size(390, 844)}) {
  return AppLocalizationScope(
    currentLanguage: AppLanguage.arabic,
    strings: const AppStrings(AppLanguage.arabic),
    onLanguageChanged: (_) {},
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: size.width, height: size.height, child: child),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late File dataFile;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('responsive_test_');
    dataFile = File('${tempDir.path}/test_user_data.json');
    await UserDataStore.instance.init(dataFile);
    await QuranRepository.instance.init();
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Comprehensive Device Form Factor & Responsive Layout Tests', () {
    testWidgets(
      '1. Small phone portrait (320x568) - Zero RenderFlex overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildFrame(QuranPageView(pageNumber: 3), size: const Size(320, 568)),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(QuranPageView), findsOneWidget);
      },
    );

    testWidgets(
      '2. Large phone portrait (412x915) - Zero RenderFlex overflow',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildFrame(QuranPageView(pageNumber: 1), size: const Size(412, 915)),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(QuranPageView), findsOneWidget);
      },
    );

    testWidgets('3. Phone in landscape (800x360) - Zero RenderFlex overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildFrame(QuranPageView(pageNumber: 2), size: const Size(800, 360)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(QuranPageView), findsOneWidget);
    });

    testWidgets('4. Foldable unfolded (700x840) - Zero RenderFlex overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(700, 840);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildFrame(QuranPageView(pageNumber: 604), size: const Size(700, 840)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(QuranPageView), findsOneWidget);
    });

    testWidgets('5. Tablet portrait (820x1180) - Zero RenderFlex overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(820, 1180);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildFrame(QuranPageView(pageNumber: 10), size: const Size(820, 1180)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(QuranPageView), findsOneWidget);
    });

    testWidgets(
      '6. Wide screen dual-page spread (>= 900px) - Renders spread without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          AppLocalizationScope(
            currentLanguage: AppLanguage.arabic,
            strings: const AppStrings(AppLanguage.arabic),
            onLanguageChanged: (_) {},
            child: const MaterialApp(home: QuranScreen(initialPage: 4)),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // In dual-page spread on wide screens >= 900px, two QuranPageView widgets are rendered side by side
        expect(find.byType(QuranPageView), findsNWidgets(2));
      },
    );

    testWidgets(
      '7. Maximum font size (32.0pt) on small screen - Scrollable and Zero overflow',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildFrame(
            QuranPageView(pageNumber: 604, fontSize: 32.0),
            size: const Size(360, 640),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(QuranPageView), findsOneWidget);

        // Verify page is smoothly scrollable vertically
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -200),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
