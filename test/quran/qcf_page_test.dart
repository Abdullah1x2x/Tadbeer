import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/theme.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/quran/data/quran_models.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';
import 'package:tadbeer/features/quran/qcf/qcf_fonts.dart';
import 'package:tadbeer/features/quran/qcf/qcf_layout.dart';
import 'package:tadbeer/features/quran/qcf/qcf_page_body.dart';
import 'package:tadbeer/features/quran/screens/quran_page_view.dart';
import 'package:tadbeer/features/settings/user_settings_model.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_qcf_page_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
  });

  tearDown(() async {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    required Size size,
    double? fontSize,
    ValueChanged<Ayah>? onTap,
  }) async {
    await tester.runAsync(() async {
      await QcfLayout.instance.init();
      await QcfFonts.instance.ensurePage(3);
    });
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: QuranPageView(
            pageNumber: 3,
            fontSize: fontSize,
            onAyahTap: onTap,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Whether [span] or any span inside it uses the page's Mushaf font.
  bool usesMushafFont(InlineSpan span) =>
      span.style?.fontFamily == QcfFonts.familyFor(3) ||
      (span is TextSpan && (span.children ?? const []).any(usesMushafFont));

  /// Paragraphs drawn with the page's Mushaf font.
  Iterable<RenderParagraph> mushafLines(WidgetTester tester) => tester
      .renderObjectList<RenderParagraph>(find.byType(RichText))
      .where((p) => usesMushafFont(p.text));

  for (final size in const [Size(360, 640), Size(412, 915), Size(800, 1280)]) {
    testWidgets('the printed page fits a ${size.width.toInt()} wide screen', (
      tester,
    ) async {
      await pumpPage(tester, size: size);
      expect(find.byType(QcfPageBody), findsOneWidget);
      final lines = mushafLines(tester).toList();
      expect(lines, hasLength(15));
      for (final line in lines) {
        expect(line.didExceedMaxLines, isFalse);
        expect(line.size.width, lessThanOrEqualTo(size.width));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('enlarging reflows the words instead of clipping lines', (
    tester,
  ) async {
    await pumpPage(tester, size: const Size(360, 640), fontSize: 36);
    final paragraphs = mushafLines(tester).toList();
    // Fifteen printed lines become a few wrapped paragraphs.
    expect(paragraphs.length, lessThan(15));
    expect(paragraphs.first.size.width, lessThanOrEqualTo(360));
    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a line selects its ayah', (tester) async {
    Ayah? tapped;
    await pumpPage(
      tester,
      size: const Size(412, 915),
      onTap: (a) => tapped = a,
    );
    final line = mushafLines(tester).elementAt(4);
    await tester.tapAt(line.localToGlobal(line.size.center(Offset.zero)));
    await tester.pump(const Duration(milliseconds: 600));
    expect(tapped, isNotNull);
    expect(tapped!.surahNumber, 2);
    expect(tapped!.ayahNumber, inInclusiveRange(6, 16));
  });

  testWidgets('the flowing text view is the alternative', (tester) async {
    await tester.runAsync(
      () => UserDataStore.instance.setMushafStyle(MushafStyle.text),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: QuranPageView(pageNumber: 3)),
      ),
    );
    await tester.pump();
    expect(find.byType(QcfPageBody), findsNothing);
  });
}
