import 'package:flutter/material.dart';

import '../../../core/utils/arabic_search_normalizer.dart';
import '../../../data/quran/quran_models.dart';
import 'qcf_fonts.dart';
import 'qcf_layout.dart';
import 'qcf_page_body.dart';

/// آية بخط مصحف المدينة جاهزة للرسم: رموزها واسم خط صفحتها.
///
/// كلماتها رموز في خط صفحتها تنتهي بعلامة رقم الآية؛ وكل صفحة في المدينة تنتهي
/// بآية كاملة، فكلها من صفحة الآية.
class QcfGlyphs {
  /// رموز الكلمات، بينها مسافات.
  final String text;

  final int page;

  const QcfGlyphs._(this.text, this.page);

  /// رموز [ayah]، أو null حتى يُحمّل التخطيط وخط صفحتها (انظر [prepare]).
  static QcfGlyphs? of(Ayah ayah) {
    if (!QcfLayout.instance.isReady ||
        !QcfFonts.instance.isPageLoaded(ayah.page)) {
      return null;
    }
    final words = [
      for (final line in QcfLayout.instance.page(ayah.page))
        for (final word in line.words)
          if (word.surah == ayah.surahNumber && word.ayah == ayah.ayahNumber)
            word.code,
    ];
    return words.isEmpty ? null : QcfGlyphs._('${words.join(' ')} ', ayah.page);
  }

  /// رموز المقطع [excerpt] من [ayah]، أو null إن لم تطابق كلماته كلمات الآية.
  ///
  /// النص المكتوب بالرسم الإملائي يطابق رسم المصحف (انظر [_skeleton]).
  static QcfGlyphs? ofExcerpt(Ayah ayah, String excerpt) {
    if (!QcfLayout.instance.isReady ||
        !QcfFonts.instance.isPageLoaded(ayah.page)) {
      return null;
    }
    final codes = excerptCodes(ayah, excerpt);
    return codes == null ? null : QcfGlyphs._('${codes.join(' ')} ', ayah.page);
  }

  /// رموز كلمات [excerpt] في [ayah]، ومعها علامة الآية إن بلغ آخرها.
  static List<String>? excerptCodes(Ayah ayah, String excerpt) {
    final all = [
      for (final line in QcfLayout.instance.page(ayah.page))
        for (final word in line.words)
          if (word.surah == ayah.surahNumber && word.ayah == ayah.ayahNumber)
            word,
    ];
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
    return await QcfFonts.instance.ensurePage(ayah.page) && of(ayah) != null;
  }

  /// نمط الرموز بحجم [fontSize] للصفحة العادية وتباعد أسطر [height]؛ وصفحتا
  /// البداية تُكبّران لتطابقا.
  TextStyle style({
    required double fontSize,
    required double height,
    required Color color,
    List<Shadow>? shadows,
  }) {
    final scale = QcfPageBody.glyphScale(page);
    return TextStyle(
      fontFamily: QcfFonts.familyFor(page),
      fontSize: fontSize * scale,
      height: height / scale,
      wordSpacing: QcfPageBody.wordSpacingFor(page, fontSize * scale),
      color: color,
      shadows: shadows,
    );
  }
}

/// آية بخط مصحف المدينة، تلتف أسطرها بحسب المساحة.
///
/// حتى يجهز التخطيط وخط صفحتها، أو إن تعذّر تحميلهما، يظهر [fallback].
class QcfAyahText extends StatefulWidget {
  final Ayah ayah;

  /// حجم خط الصفحة العادية؛ وصفحتا البداية تُكبّران لتطابقا.
  final double fontSize;

  final Color color;

  /// تباعد الأسطر نسبةً إلى [fontSize].
  final double height;

  /// يظهر أثناء التحميل، أو إن تعذّر الرسم.
  final Widget fallback;

  const QcfAyahText({
    super.key,
    required this.ayah,
    required this.fontSize,
    required this.color,
    required this.fallback,
    this.height = 1.9,
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
    textAlign: TextAlign.center,
    textDirection: TextDirection.rtl,
    style: glyphs.style(
      fontSize: widget.fontSize,
      height: widget.height,
      color: widget.color,
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
