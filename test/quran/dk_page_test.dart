import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/core/theme/theme.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/features/quran/qcf/qcf_layout.dart';
import 'package:tadbeer/features/quran/qcf/qcf_page_body.dart';
import 'package:tadbeer/features/quran/screens/quran_page_view.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dk = FontLoader(QcfPageBody.digitalKhattFamily)
      ..addFont(rootBundle.load('assets/fonts/DigitalKhattV2.otf'));
    await dk.load();
    await QcfLayout.instance.init();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_dk_page_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  bool inDigitalKhatt(InlineSpan span) =>
      span is TextSpan &&
      (span.style?.fontFamily == QcfPageBody.digitalKhattFamily ||
          (span.children ?? const []).any(inDigitalKhatt));

  /// The font size of the Digital Khatt span within [span].
  double? dkSize(InlineSpan span) {
    if (span is! TextSpan) return null;
    if (span.style?.fontFamily == QcfPageBody.digitalKhattFamily) {
      return span.style?.fontSize;
    }
    for (final child in span.children ?? const <InlineSpan>[]) {
      final size = dkSize(child);
      if (size != null) return size;
    }
    return null;
  }

  /// Word lines drawn in Digital Khatt (the basmala is a plain line).
  Iterable<RenderParagraph> lines(WidgetTester tester) => tester
      .renderObjectList<RenderParagraph>(find.byType(RichText))
      .where((p) => inDigitalKhatt(p.text))
      .where((p) => !p.text.toPlainText().contains('بِسْمِ ٱللَّهِ'));

  // A typical phone, and a narrow one (Galaxy S9, 360 wide) with the system
  // font enlarged: the page is sized by its width, so the font setting must not
  // push the lines past the edges.
  for (final (screen, textScale) in [
    (const Size(412, 915), 1.0),
    (const Size(360, 740), 1.3),
  ]) {
    // Page 4 at 412px dropped the last word of two lines.
    for (final page in [3, 4, 501, 502, 604]) {
      testWidgets('page $page fills ${screen.width.toInt()}px at text scale '
          '$textScale without overflowing', (tester) async {
        tester.view.physicalSize = screen;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = textScale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(body: QuranPageView(pageNumber: page)),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        final body = tester.getSize(find.byType(QcfPageBody));
        final drawn = lines(tester).toList();
        expect(drawn, isNotEmpty);
        // The text's own width, after any squeeze, as it shows on screen.
        double shown(RenderParagraph p) =>
            p.getMaxIntrinsicWidth(double.infinity) *
            p.getTransformTo(null).storage[0];
        for (final p in drawn) {
          // The last word never wraps onto a hidden second line.
          expect(p.didExceedMaxLines, isFalse);
          // A word line never spills over the page, so nothing is cut off.
          expect(shown(p), lessThanOrEqualTo(body.width + 1));
        }
        // Most lines are stretched to the full width, as in print; the last
        // page's three short surahs end mostly in centred lines.
        if (page != 604) {
          final full = drawn.where((p) => shown(p) >= body.width * 0.97);
          expect(full.length, greaterThanOrEqualTo(drawn.length ~/ 2));
        }
      });
    }
  }

  /// Each word line as drawn: its text with the kashida and its own width.
  Future<List<(String, double)>> drawnLines(
    WidgetTester tester,
    int page,
    Size screen,
  ) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: QuranPageView(pageNumber: page)),
      ),
    );
    await tester.pump();
    return [
      for (final p in lines(tester))
        (
          p.text.toPlainText(includeSemanticsLabels: false),
          p.getMaxIntrinsicWidth(double.infinity),
        ),
    ];
  }

  testWidgets('every screen draws the same lines, only scaled', (tester) async {
    addTearDown(tester.view.reset);
    final phone = await drawnLines(tester, 4, const Size(360, 740));
    final tablet = await drawnLines(tester, 4, const Size(800, 1280));
    final landscape = await drawnLines(tester, 4, const Size(800, 360));
    expect(tablet, phone);
    expect(landscape, phone);
  });

  // The lines are laid out at one fixed width, so one screen checks them for
  // every device: no word drops, spills over the page or touches the next.
  testWidgets('no line in the mushaf drops, spills or crowds a word', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    final problems = <String>[];
    for (var page = 1; page <= 604; page++) {
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(page),
          theme: AppTheme.lightTheme,
          home: Scaffold(body: QuranPageView(pageNumber: page)),
        ),
      );
      await tester.pump();
      final body = tester.getSize(find.byType(QcfPageBody));
      for (final p in lines(tester)) {
        final scale = p.getTransformTo(null).storage[0];
        if (p.didExceedMaxLines) problems.add('page $page: a word wrapped');
        if (p.getMaxIntrinsicWidth(double.infinity) * scale >
            body.width + 0.5) {
          problems.add('page $page: a line spills over');
        }
        final text = p.text.toPlainText(includeSemanticsLabels: false);
        final size = dkSize(p.text)!;
        final space = TextPainter(
          text: TextSpan(
            text: ' ',
            style: TextStyle(
              fontFamily: QcfPageBody.digitalKhattFamily,
              fontSize: size,
            ),
          ),
          textDirection: TextDirection.rtl,
        )..layout();
        for (var i = 0; i < text.length; i++) {
          if (text[i] != ' ') continue;
          final gap = p.getBoxesForSelection(
            TextSelection(baseOffset: i, extentOffset: i + 1),
          );
          // Never narrower than the font's own space.
          if (gap.isNotEmpty && gap.first.toRect().width < space.width - 0.01) {
            problems.add('page $page: words too close');
          }
        }
        space.dispose();
      }
    }
    expect(problems, isEmpty);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
