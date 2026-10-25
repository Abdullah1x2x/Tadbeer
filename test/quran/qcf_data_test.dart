import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/features/quran/qcf/qcf_fonts.dart';
import 'package:tadbeer/features/quran/qcf/qcf_layout.dart';

void main() {
  test('parses headers, basmalas and words with ayah-end markers', () {
    final pages = QcfLayout.parse(
      jsonDecode('''
      [[["h", 2], ["b", 2], [[2, 1, "a"], [2, 1, "b", 1]]]]
      ''') as List,
    );
    final lines = pages.single;
    expect(lines.map((l) => l.kind), [
      QcfLineKind.surahHeader,
      QcfLineKind.basmala,
      QcfLineKind.words,
    ]);
    expect(lines.first.surah, 2);
    expect(lines.last.words.map((w) => w.code), ['a', 'b']);
    expect(lines.last.words.map((w) => w.isEnd), [false, true]);
  });

  test('the bundled layout has every page with 15 lines', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await QcfLayout.instance.init();
    expect(QcfLayout.instance.page(1), hasLength(8));
    expect(QcfLayout.instance.page(2), hasLength(8));
    for (var p = 3; p <= 604; p++) {
      expect(QcfLayout.instance.page(p), hasLength(15), reason: 'page $p');
    }
    // An-Nisa's header closes page 76 and its basmala opens page 77.
    expect(QcfLayout.instance.page(76).last.kind, QcfLineKind.surahHeader);
    expect(QcfLayout.instance.page(77).first.kind, QcfLineKind.basmala);
    final words = [
      for (var p = 1; p <= 604; p++)
        for (final l in QcfLayout.instance.page(p)) ...l.words,
    ];
    expect(words.where((w) => w.isEnd), hasLength(6236));
  });

  test('every page has its bundled font', () {
    for (var p = 1; p <= QcfFonts.pageCount; p++) {
      expect(
        File(QcfFonts.assetFor(p)).existsSync(),
        isTrue,
        reason: 'page $p',
      );
    }
  });
}
