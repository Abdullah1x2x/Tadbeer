import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/features/quran/qcf/qcf_fonts.dart';
import 'package:tadbeer/features/quran/qcf/qcf_layout.dart';
import 'package:tadbeer/features/quran/qcf/qcf_widest_lines.g.dart';

/// Each page font is drawn for its own line breaks, so every printed line has
/// about the same width. A line far wider or shorter than the rest of its page
/// means a word sits on the wrong line, and the whole page renders smaller.
void main() {
  testWidgets('every line fits its page font, and the widest table agrees', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await QcfLayout.instance.init();
      for (var p = 3; p <= QcfFonts.pageCount; p++) {
        await QcfFonts.instance.ensurePage(p);
      }
    });

    final wrongLines = <String>[];
    final staleWidest = <String>[];
    for (var p = 3; p <= QcfFonts.pageCount; p++) {
      final widths = [
        for (final line in QcfLayout.instance.page(p))
          if (line.words.isNotEmpty)
            (TextPainter(
              text: TextSpan(
                text: line.words.map((w) => w.code).join(' '),
                style: TextStyle(
                  fontFamily: QcfFonts.familyFor(p),
                  fontSize: 100,
                ),
              ),
              textDirection: TextDirection.rtl,
            )..layout()).width,
      ];
      final sorted = [...widths]..sort();
      final median = sorted[sorted.length ~/ 2];
      // The last pages end short surahs on short lines, as printed.
      if (p <= 601) {
        for (final (i, w) in widths.indexed) {
          if (w > median * 1.06 || w < median * 0.85) {
            wrongLines.add('page $p line ${i + 1}');
          }
        }
      }
      final widest = sorted.last;
      if ((kQcfWidestLines[p]! - widest).abs() > 1) {
        staleWidest.add('$p: ${widest.toStringAsFixed(1)}');
      }
    }
    expect(wrongLines, isEmpty);
    expect(staleWidest, isEmpty);
  });
}
