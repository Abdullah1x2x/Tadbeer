/// تخطيط صفحات مصحف المدينة (مجمع الملك فهد، الإصدار الأول).
///
/// Each page of the printed Madinah Mushaf is 15 lines (8 on the first two
/// pages). Every word is one glyph of that page's QCF font, so a line drawn
/// from its glyphs matches the print exactly. The layout ships with the app;
/// only the fonts are downloaded.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

/// كلمة واحدة من المصحف: محرف في خط صفحتها.
class QcfWord {
  final int surah;
  final int ayah;

  /// The glyph (one or two characters) in the page's font.
  final String code;

  /// Whether this is the ayah-number marker that ends the ayah.
  final bool isEnd;

  const QcfWord(this.surah, this.ayah, this.code, {this.isEnd = false});
}

enum QcfLineKind { words, surahHeader, basmala }

/// سطر من سطور الصفحة.
class QcfLine {
  final QcfLineKind kind;

  /// The surah a header or basmala line opens.
  final int surah;

  final List<QcfWord> words;

  const QcfLine.words(this.words) : kind = QcfLineKind.words, surah = 0;

  const QcfLine.header(this.surah)
    : kind = QcfLineKind.surahHeader,
      words = const [];

  const QcfLine.basmala(this.surah)
    : kind = QcfLineKind.basmala,
      words = const [];
}

/// Loads and serves the line layout of all 604 pages.
class QcfLayout {
  QcfLayout._();

  static final QcfLayout instance = QcfLayout._();

  static const assetPath = 'assets/quran/qcf_v1_layout.json.gz';

  List<List<QcfLine>>? _pages;
  Future<void>? _loading;

  bool get isReady => _pages != null;

  /// Loads the layout once; later calls return the same future.
  Future<void> init() => _loading ??= _load();

  Future<void> _load() async {
    final data = await rootBundle.load(assetPath);
    final json = utf8.decode(gzip.decode(data.buffer.asUint8List()));
    _pages = parse(jsonDecode(json) as List);
  }

  /// The lines of [page] (1-604); empty until [init] completes.
  List<QcfLine> page(int page) {
    final pages = _pages;
    if (pages == null || page < 1 || page > pages.length) return const [];
    return pages[page - 1];
  }

  /// Parses the compact format: a list of pages, each a list of lines. A line
  /// is `["h", surah]`, `["b", surah]`, or a list of words
  /// `[surah, ayah, glyph]` with a fourth element `1` on ayah-end markers.
  static List<List<QcfLine>> parse(List raw) => [
    for (final page in raw)
      [
        for (final line in page as List)
          if (line is List && line.isNotEmpty && line.first == 'h')
            QcfLine.header(line[1] as int)
          else if (line is List && line.isNotEmpty && line.first == 'b')
            QcfLine.basmala(line[1] as int)
          else
            QcfLine.words([
              for (final w in line as List)
                QcfWord(
                  w[0] as int,
                  w[1] as int,
                  w[2] as String,
                  isEnd: (w as List).length > 3,
                ),
            ]),
      ],
  ];
}
