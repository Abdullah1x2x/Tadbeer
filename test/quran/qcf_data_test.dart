import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
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
}
