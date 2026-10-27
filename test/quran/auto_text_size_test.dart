import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/theme.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';
import 'package:tadbeer/features/quran/qcf/qcf_fonts.dart';
import 'package:tadbeer/features/quran/qcf/qcf_layout.dart';
import 'package:tadbeer/features/quran/screens/quran_page_view.dart';
import 'package:tadbeer/features/settings/user_settings_model.dart';

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
      expect(size, inInclusiveRange(18, 32), reason: '$width');
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
