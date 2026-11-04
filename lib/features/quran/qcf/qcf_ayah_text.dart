import 'package:flutter/material.dart';

import '../../../core/utils/arabic_search_normalizer.dart';
import '../../../data/quran/quran_models.dart';
import 'qcf_layout.dart';
import 'qcf_page_body.dart';

/// آية بخط مصحف المدينة (Digital Khatt) جاهزة للرسم.
///
/// كلماتها نص بخط واحد تنتهي بعلامة رقم الآية؛ وكل صفحة في المدينة تنتهي بآية
/// كاملة، فكلها من صفحة واحدة.
class QcfGlyphs {
  /// نص الكلمات، بينها مسافات.
  final String text;

  const QcfGlyphs._(this.text);

  /// كلمات [ayah] في التخطيط.
  static List<QcfWord> _words(Ayah ayah) {
    final layout = QcfLayout.instance;
    // صفحات الطبعة الحديثة قد تقدّم آية أو تؤخرها عن صفحة بيانات التطبيق.
    for (final page in [ayah.page, ayah.page - 1, ayah.page + 1]) {
      final words = [
        for (final line in layout.page(page))
          for (final word in line.words)
            if (word.surah == ayah.surahNumber && word.ayah == ayah.ayahNumber)
              word,
      ];
      if (words.isNotEmpty) return words;
    }
    return const [];
  }

  /// نص [ayah]، أو null حتى يُحمّل التخطيط (انظر [prepare]).
  static QcfGlyphs? of(Ayah ayah) {
    if (!QcfLayout.instance.isReady) return null;
    final words = _words(ayah);
    return words.isEmpty
        ? null
        : QcfGlyphs._('${words.map((w) => w.code).join(' ')} ');
  }

  /// رموز المقطع [excerpt] من [ayah]، أو null إن لم تطابق كلماته كلمات الآية.
  ///
  /// النص المكتوب بالرسم الإملائي يطابق رسم المصحف (انظر [_skeleton]).
  static QcfGlyphs? ofExcerpt(Ayah ayah, String excerpt) {
    if (!QcfLayout.instance.isReady) return null;
    final codes = excerptCodes(ayah, excerpt);
    return codes == null ? null : QcfGlyphs._('${codes.join(' ')} ');
  }

  /// رموز كلمات [excerpt] في [ayah]، ومعها علامة الآية إن بلغ آخرها.
  static List<String>? excerptCodes(Ayah ayah, String excerpt) {
    final all = _words(ayah);
    final ayahWords = _skeletonWords(ayah.text);
    final wanted = _skeletonWords(excerpt);
    if (wanted.isEmpty) return null;
    // الآية كاملة، وإن اختلف تقسيم كلماتها («يا أيها» و«يأيها»).
    if (ayahWords.join() == wanted.join()) {
      return [for (final w in all) w.code];
    }
    final words = [
      for (final w in all)
        if (!w.isEnd) w,
    ];
    if (ayahWords.length != words.length) return null;
    for (var start = 0; start + wanted.length <= words.length; start++) {
      var same = true;
      for (var i = 0; same && i < wanted.length; i++) {
        same = ayahWords[start + i] == wanted[i];
      }
      if (!same) continue;
      final end = start + wanted.length;
      return [
        for (final w in words.sublist(start, end)) w.code,
        if (end == words.length)
          for (final w in all)
            if (w.isEnd) w.code,
      ];
    }
    return null;
  }

  /// حروف المد والهمز تختلف بين الرسمين، فتُقارن الكلمات بما عداها؛ وعلامات
  /// الوقف المنفصلة لا تُعد كلمات.
  static List<String> _skeletonWords(String text) => [
    for (final word in text.split(RegExp(r'\s+')))
      if (ArabicSearchNormalizer.normalize(word).isNotEmpty) _skeleton(word),
  ];

  static String _skeleton(String word) =>
      ArabicSearchNormalizer.normalize(word)
          .replaceAll(RegExp('[اأإآٱءئؤىيوة]'), '');

  /// يحمّل ما يحتاجه [of] للآية [ayah]؛ true متى أمكن رسمها.
  static Future<bool> prepare(Ayah ayah) async {
    await QcfLayout.instance.init();
    return of(ayah) != null;
  }

  /// نمط النص بحجم [fontSize] وتباعد أسطر [height].
  TextStyle style({
    required double fontSize,
    required double height,
    required Color color,
    List<Shadow>? shadows,
  }) => TextStyle(
    fontFamily: QcfPageBody.digitalKhattFamily,
    fontSize: fontSize,
    height: height,
    color: color,
    shadows: shadows,
  );
}

/// آية بخط مصحف المدينة، تلتف أسطرها بحسب المساحة.
///
/// حتى يجهز التخطيط، أو إن لم توجد الآية فيه، يظهر [fallback].
class QcfAyahText extends StatefulWidget {
  final Ayah ayah;

  final double fontSize;

  final Color color;

  /// تباعد الأسطر نسبةً إلى [fontSize].
  final double height;

  /// يظهر أثناء التحميل، أو إن تعذّر الرسم.
  final Widget fallback;

  final TextAlign textAlign;
  final List<Shadow>? shadows;
  final int? maxLines;
  final TextOverflow? overflow;

  const QcfAyahText({
    super.key,
    required this.ayah,
    required this.fontSize,
    required this.color,
    required this.fallback,
    this.height = 1.9,
    this.textAlign = TextAlign.center,
    this.shadows,
    this.maxLines,
    this.overflow,
  });

  @override
  State<QcfAyahText> createState() => _QcfAyahTextState();
}

class _QcfAyahTextState extends State<QcfAyahText> {
  late Future<bool> _ready;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(QcfAyahText old) {
    super.didUpdateWidget(old);
    if (old.ayah.id != widget.ayah.id) _prepare();
  }

  void _prepare() {
    _ready = QcfGlyphs.prepare(widget.ayah);
  }

  Widget _text(QcfGlyphs glyphs) => Text(
    semanticsLabel: widget.ayah.text,
    glyphs.text,
    textAlign: widget.textAlign,
    textDirection: TextDirection.rtl,
    maxLines: widget.maxLines,
    overflow: widget.overflow,
    style: glyphs.style(
      fontSize: widget.fontSize,
      height: widget.height,
      color: widget.color,
      shadows: widget.shadows,
    ),
  );

  @override
  Widget build(BuildContext context) {
    // تُرسم فوراً إن كانت الرموز محمّلة، كما حين تُفتح الآية من صفحتها في
    // المصحف.
    final glyphs = QcfGlyphs.of(widget.ayah);
    if (glyphs != null) return _text(glyphs);
    return FutureBuilder<bool>(
      future: _ready,
      builder: (context, _) {
        final glyphs = QcfGlyphs.of(widget.ayah);
        return glyphs == null ? widget.fallback : _text(glyphs);
      },
    );
  }
}
