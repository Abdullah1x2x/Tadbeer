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

  /// Word lines drawn in Digital Khatt (the basmala is a plain line).
  Iterable<RenderParagraph> lines(WidgetTester tester) => tester
      .renderObjectList<RenderParagraph>(find.byType(RichText))
      .where((p) => inDigitalKhatt(p.text))
      .where((p) => !p.text.toPlainText().contains('بِسْمِ ٱللَّهِ'));

  for (final page in [3, 501, 502, 604]) {
    testWidgets('page $page fills the width without overflowing', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
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
