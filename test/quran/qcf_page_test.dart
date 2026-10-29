import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/core/theme/theme.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/data/quran/quran_models.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/features/quran/qcf/qcf_fonts.dart';
import 'package:tadbeer/features/quran/qcf/qcf_layout.dart';
import 'package:tadbeer/features/quran/qcf/qcf_page_body.dart';
import 'package:tadbeer/features/quran/screens/quran_page_view.dart';
import 'package:tadbeer/data/models/user_settings_model.dart';

void main() {
  late Directory tempDir;

  // Loaded in real time before any test: a page preloads its neighbours'
  // fonts, which under a test's fake time would start and never finish.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await QcfLayout.instance.init();
    for (var page = 1; page <= 4; page++) {
      await QcfFonts.instance.ensurePage(page);
    }
  });

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
    int page = 3,
    double? fontSize,
    ValueChanged<Ayah>? onTap,
  }) async {
    await tester.runAsync(() async {
      await QcfLayout.instance.init();
      await QcfFonts.instance.ensurePage(page);
    });
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: QuranPageView(
            pageNumber: page,
            fontSize: fontSize,
            onAyahTap: onTap,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// The span that sets [page]'s Mushaf font, if [span] contains it.
  TextSpan? mushafSpan(InlineSpan span, int page) {
    if (span is! TextSpan) return null;
    if (span.style?.fontFamily == QcfFonts.familyFor(page)) return span;
    for (final child in span.children ?? const <InlineSpan>[]) {
      final found = mushafSpan(child, page);
      if (found != null) return found;
    }
    return null;
  }

  /// Paragraphs drawn with the page's Mushaf font.
  Iterable<RenderParagraph> mushafLines(WidgetTester tester, {int page = 3}) =>
      tester
          .renderObjectList<RenderParagraph>(find.byType(RichText))
          .where((p) => mushafSpan(p.text, page) != null);

  /// Font size of [page]'s lines as laid out.
  double mushafFontSize(WidgetTester tester, int page) => mushafSpan(
    mushafLines(tester, page: page).first.text,
    page,
  )!.style!.fontSize!;

  // Median word height per unit of font size, measured from the glyphs.
  const wordHeight = {1: 0.889, 2: 0.834, 3: 1.036};

  testWidgets('the basmala is drawn in the Mushaf script', (tester) async {
    await pumpPage(tester, size: const Size(412, 915), page: 2);
    final basmala = find.byWidgetPredicate(
      (w) =>
          w is Text &&
          w.data == '\uFB51\uFB52\uFB53\uFB54' &&
          w.style?.fontFamily == QcfFonts.familyFor(1),
    );
    expect(basmala, findsOneWidget);
    expect(find.text('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the first page sets its words no further apart than others', (
    tester,
  ) async {
    double gap(int page, double size) {
      final g = String.fromCharCode(0xFB51);
      double width(String text) {
        final painter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              fontFamily: QcfFonts.familyFor(page),
              fontSize: size,
              wordSpacing: QcfPageBody.wordSpacingFor(page, size),
            ),
          ),
          textDirection: TextDirection.rtl,
        )..layout();
        return painter.width;
      }

      return width('$g $g') - width('$g$g');
    }

    for (final page in [1, 2, 3]) {
      expect(gap(page, 100), closeTo(4, 1.2), reason: 'page $page');
    }
  });

  for (final page in [1, 2]) {
    testWidgets('page $page keeps its lines together', (tester) async {
      await pumpPage(tester, size: const Size(412, 915), page: page);
      final size = mushafFontSize(tester, page);
      final tops = [
        for (final line in mushafLines(tester, page: page))
          line.localToGlobal(Offset.zero).dy,
      ]..sort();
      for (var i = 1; i < tops.length; i++) {
        expect(tops[i] - tops[i - 1], closeTo(size * 1.9, 1), reason: '$i');
      }
    });
  }

  for (final size in const [Size(360, 640), Size(412, 915), Size(800, 1280)]) {
    testWidgets(
      'the opening pages read as large as the rest (${size.width.toInt()} wide)',
      (tester) async {
        await pumpPage(tester, size: size);
        final ordinary = mushafFontSize(tester, 3) * wordHeight[3]!;
        for (final page in [1, 2]) {
          await pumpPage(tester, size: size, page: page);
          final letters = mushafFontSize(tester, page) * wordHeight[page]!;
          expect(
            letters / ordinary,
            // Page 3 is among the largest ordinary pages; 0.93 catches the
            // opening pages shrunk by too tight a width limit.
            inInclusiveRange(0.93, 1.1),
            reason: 'page $page',
          );
          for (final line in mushafLines(tester, page: page)) {
            expect(line.didExceedMaxLines, isFalse);
            expect(line.size.width, lessThanOrEqualTo(size.width * 0.9));
          }
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

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
