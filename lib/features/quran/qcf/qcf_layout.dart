/// تخطيط صفحات مصحف المدينة (الطبعة الحديثة، بنص DigitalKhatt).
///
/// كل صفحة في مصحف المدينة المطبوع ١٥ سطراً (٨ في الصفحة الأولى)، وكل كلمة نص
/// يُرسم بخط Digital Khatt الواحد. يُبنى بـ tool/dk/build_layout.py.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';

/// كلمة واحدة من المصحف بنص Digital Khatt.
class QcfWord {
  final int surah;
  final int ayah;

  /// نص الكلمة كما يرسمه الخط.
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

  static const assetPath = 'assets/quran/dk_layout.json.gz';

  List<List<QcfLine>>? _pages;
  Future<void>? _loading;

  bool get isReady => _pages != null;

  /// يحمّل التخطيط مرة واحدة؛ وكل استدعاء بعدها يعيد نفس الـ future.
  Future<void> init() => _loading ??= _load();

  Future<void> _load() async {
    final data = await rootBundle.load(assetPath);
    final compressed = data.buffer.asUint8List();
    // خيط منفصل: فك الملف وفهرسة الآيات لئلا يتقطع مسار الواجهة.
    final result = await Isolate.run(() {
      final pages =
          parse(jsonDecode(utf8.decode(gzip.decode(compressed))) as List);
      final index = <(int, int), int>{};
      for (var p = 0; p < pages.length; p++) {
        for (final line in pages[p]) {
          for (final w in line.words) {
            index[(w.surah, w.ayah)] = p + 1;
          }
        }
      }
      return (pages, index);
    });
    _pages = result.$1;
    _pageOf = result.$2;
  }

  Map<(int, int), int>? _pageOf;

  /// صفحة الآية [surah]:[ayah] في هذا التخطيط، أو null قبل [init].
  ///
  /// صفحات الطبعة الحديثة قد تقدّم آية أو تؤخرها عن صفحات بيانات التطبيق.
  int? pageOf(int surah, int ayah) {
    if (_pageOf != null) return _pageOf![(surah, ayah)];
    final pages = _pages;
    if (pages == null) return null;
    final index = _pageOf ??= {
      for (var p = 0; p < pages.length; p++)
        for (final line in pages[p])
          for (final w in line.words) (w.surah, w.ayah): p + 1,
    };
    return index[(surah, ayah)];
  }

  /// أسطر [page] (1..604)؛ فارغة حتى ينتهي [init].
  List<QcfLine> page(int page) {
    final pages = _pages;
    if (pages == null || page < 1 || page > pages.length) return const [];
    return pages[page - 1];
  }

  /// يقرأ الصيغة المختصرة: قائمة صفحات، كل منها قائمة أسطر. السطر `["h",
  /// surah]` أو `["b", surah]` أو قائمة كلمات `[surah, ayah, text]` بعنصر رابع
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
