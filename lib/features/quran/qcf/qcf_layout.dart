/// تخطيط صفحات مصحف المدينة (مجمع الملك فهد، الإصدار الأول).
///
/// كل صفحة في مصحف المدينة المطبوع ١٥ سطراً (٨ في الصفحتين الأوليين)، وكل كلمة
/// رمز واحد في خط QCF للصفحة، فالسطر المرسوم من رموزه يطابق المطبوع تماماً.
/// التخطيط والخطوط كلاهما مضمّنان في التطبيق.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

/// كلمة واحدة من المصحف: محرف في خط صفحتها.
class QcfWord {
  final int surah;
  final int ayah;

  /// الرمز (حرف أو حرفان) في خط الصفحة.
  final String code;

  /// هل هي علامة رقم الآية في آخرها.
  final bool isEnd;

  const QcfWord(this.surah, this.ayah, this.code, {this.isEnd = false});
}

enum QcfLineKind { words, surahHeader, basmala }

/// سطر من الصفحة.
class QcfLine {
  final QcfLineKind kind;

  /// السورة التي يفتتحها سطر العنوان أو البسملة.
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

/// يحمّل تخطيط أسطر الصفحات الـ٦٠٤.
class QcfLayout {
  QcfLayout._();

  static final QcfLayout instance = QcfLayout._();

  static const assetPath = 'assets/quran/qcf_v1_layout.json.gz';

  List<List<QcfLine>>? _pages;
  Future<void>? _loading;

  bool get isReady => _pages != null;

  /// يحمّل التخطيط مرة واحدة؛ وكل استدعاء بعدها يعيد نفس الـ future.
  Future<void> init() => _loading ??= _load();

  Future<void> _load() async {
    final data = await rootBundle.load(assetPath);
    final json = utf8.decode(gzip.decode(data.buffer.asUint8List()));
    _pages = parse(jsonDecode(json) as List);
  }

  /// أسطر [page] (1..604)؛ فارغة حتى ينتهي [init].
  List<QcfLine> page(int page) {
    final pages = _pages;
    if (pages == null || page < 1 || page > pages.length) return const [];
    return pages[page - 1];
  }

  /// يقرأ الصيغة المختصرة: قائمة صفحات، كل منها قائمة أسطر. السطر `["h",
  /// surah]` أو `["b", surah]` أو قائمة كلمات `[surah, ayah, glyph]` بعنصر رابع
  /// `1` لعلامات آخر الآية.
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
