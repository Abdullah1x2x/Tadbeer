import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/core/theme/theme.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/features/quran/qcf/qcf_fonts.dart';
import 'package:tadbeer/features/quran/qcf/qcf_layout.dart';
import 'package:tadbeer/features/quran/screens/quran_page_view.dart';
import 'package:tadbeer/features/quran/widgets/text_scale_control.dart';
import 'package:tadbeer/data/models/user_settings_model.dart';

/// The Mushaf sizes itself to every screen, with nothing to set by hand.
void main() {
  late Directory tempDir;

  const screens = {
    'small phone': Size(320, 568),
    'phone': Size(360, 640),
    'large phone': Size(412, 915),
    'big phone': Size(430, 932),
    'phone on its side': Size(915, 412),
    'tablet': Size(800, 1280),
    'tablet on its side': Size(1280, 800),
  };

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await QcfLayout.instance.init();
    for (final page in [1, 2, 3, 50, 51]) {
      await QcfFonts.instance.ensurePage(page);
    }
    final amiri = FontLoader('Amiri')
      ..addFont(rootBundle.load('assets/fonts/Amiri-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Amiri-Bold.ttf'));
    final scheherazade = FontLoader('ScheherazadeNew')
      ..addFont(rootBundle.load('assets/fonts/ScheherazadeNew-Regular.ttf'));
    await Future.wait([amiri.load(), scheherazade.load()]);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_auto_size_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<void> pumpPage(
    WidgetTester tester,
    Size size, {
    int page = 50,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(body: QuranPageView(pageNumber: page)),
      ),
    );
    await tester.pump();
  }

  /// The font size the ayahs are drawn at, in the given family.
  double drawnSize(WidgetTester tester, String family) {
    double? found;
    bool visit(InlineSpan span) {
      if (span.style?.fontFamily == family && span.style?.fontSize != null) {
        found = span.style!.fontSize;
        return false;
      }
      if (span is TextSpan) {
        for (final c in span.children ?? const <InlineSpan>[]) {
          if (!visit(c)) return false;
        }
      }
      return true;
    }

    for (final p in tester.renderObjectList<RenderParagraph>(
      find.byType(RichText),
    )) {
      if (!visit(p.text)) break;
    }
    return found!;
  }

  test('the flowing size grows with the screen within reading bounds', () {
    var last = 0.0;
    for (final width in const <double>[280, 320, 360, 412, 600, 800, 1280]) {
      final size = QuranPageView.textSizeFor(width);
      expect(size, inInclusiveRange(16, 28), reason: '$width');
      expect(size, greaterThanOrEqualTo(last), reason: '$width');
      last = size;
    }
  });

  for (final MapEntry(key: name, value: screen) in screens.entries) {
    testWidgets('the Madinah page fits a $name', (tester) async {
      await pumpPage(tester, screen);
      expect(tester.takeException(), isNull);
      for (final page in [1, 2]) {
        await pumpPage(tester, screen, page: page);
        expect(tester.takeException(), isNull, reason: 'page $page');
      }
    });

    testWidgets('the flowing text sizes itself on a $name', (tester) async {
      await tester.runAsync(
        () => UserDataStore.instance.setMushafStyle(MushafStyle.text),
      );
      // A page of ayahs only, with no basmala banner of its own size.
      await pumpPage(tester, screen, page: 51);
      final family = UserDataStore.instance.settings.quranFontFamilyName;
      final page = tester.getSize(find.byType(QuranPageView)).width;
      expect(drawnSize(tester, family), QuranPageView.textSizeFor(page));
      expect(tester.takeException(), isNull);
    });
  }

  Future<void> setScale(WidgetTester tester, double scale) => tester.runAsync(
    () => UserDataStore.instance.updateSettings(
      UserDataStore.instance.settings.copyWith(flowingTextScale: scale),
    ),
  );

  testWidgets('the reader can enlarge the flowing text, and it still fits', (
    tester,
  ) async {
    await tester.runAsync(
      () => UserDataStore.instance.setMushafStyle(MushafStyle.text),
    );
    for (final screen in [screens['small phone']!, screens['tablet']!]) {
      await setScale(tester, 1.4);
      await pumpPage(tester, screen, page: 51);
      final family = UserDataStore.instance.settings.quranFontFamilyName;
      final page = tester.getSize(find.byType(QuranPageView)).width;
      expect(
        drawnSize(tester, family),
        closeTo(QuranPageView.textSizeFor(page) * 1.4, 0.01),
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('the Madinah pages ignore the enlargement', (tester) async {
    await pumpPage(tester, screens['large phone']!);
    final before = drawnSize(tester, QcfFonts.familyFor(50));
    await setScale(tester, 1.4);
    await pumpPage(tester, screens['large phone']!);
    expect(drawnSize(tester, QcfFonts.familyFor(50)), before);
  });

  testWidgets('the size control steps within its bounds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: TextScaleControl()),
      ),
    );
    IconButton button(String tip) => tester.widget<IconButton>(
      find.ancestor(of: find.byTooltip(tip), matching: find.byType(IconButton)),
    );
    Future<void> tap(String tip, int times) async {
      for (var i = 0; i < times; i++) {
        await tester.runAsync(() async {
          await tester.tap(find.byTooltip(tip));
          await Future<void>.delayed(const Duration(milliseconds: 20));
        });
        await tester.pump();
      }
    }

    // At the automatic size there is nothing to reset.
    expect(button('الحجم الافتراضي').onPressed, isNull);
    await tap('تصغير الخط', 5);
    expect(UserDataStore.instance.settings.flowingTextScale, 0.8);
    expect(button('تصغير الخط').onPressed, isNull);
    expect(find.text('٨٠٪'), findsOneWidget);

    await tap('تكبير الخط أكثر', 10);
    expect(UserDataStore.instance.settings.flowingTextScale, 1.4);
    expect(button('تكبير الخط أكثر').onPressed, isNull);
    expect(find.text('١٤٠٪'), findsOneWidget);

    await tap('تصغير الخط', 1);
    expect(UserDataStore.instance.settings.flowingTextScale, 1.3);

    await tap('الحجم الافتراضي', 1);
    expect(UserDataStore.instance.settings.flowingTextScale, 1.0);
    expect(button('الحجم الافتراضي').onPressed, isNull);
  });

  test('the enlargement is saved and kept within bounds', () {
    final saved = const UserSettings().copyWith(flowingTextScale: 0.9);
    expect(UserSettings.fromJson(saved.toJson()).flowingTextScale, 0.9);
    expect(
      UserSettings.fromJson({'flowingTextScale': 5}).flowingTextScale,
      1.4,
    );
    expect(
      UserSettings.fromJson({'flowingTextScale': 0.1}).flowingTextScale,
      0.8,
    );
    expect(UserSettings.fromJson({}).flowingTextScale, 1.0);
  });

  testWidgets('larger system text still fits', (tester) async {
    for (final screen in [screens['small phone']!, screens['large phone']!]) {
      await pumpPage(tester, screen, textScale: 1.3);
      expect(tester.takeException(), isNull);
      await tester.runAsync(
        () => UserDataStore.instance.setMushafStyle(MushafStyle.text),
      );
      await pumpPage(tester, screen, textScale: 1.3);
      expect(tester.takeException(), isNull);
      await tester.runAsync(
        () => UserDataStore.instance.setMushafStyle(MushafStyle.madinah),
      );
    }
  });
}
