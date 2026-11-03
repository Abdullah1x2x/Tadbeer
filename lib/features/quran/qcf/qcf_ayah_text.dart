import 'package:flutter/material.dart';

import '../../../core/utils/arabic_search_normalizer.dart';
import '../../../data/models/user_settings_model.dart';
import '../../../data/quran/quran_models.dart';
import '../../../data/storage/user_data_store.dart';
import 'qcf_fonts.dart';
import 'qcf_layout.dart';
import 'qcf_page_body.dart';

/// آية بخط مصحف المدينة الذي اختاره القارئ، جاهزة للرسم.
///
/// بخطوط مجمع الملك فهد كلماتها رموز في خط صفحتها تنتهي بعلامة رقم الآية؛ وبخط
/// Digital Khatt نص بخط واحد. وكل صفحة في المدينة تنتهي بآية كاملة، فكلها من
/// صفحة واحدة.
class QcfGlyphs {
  /// رموز الكلمات، بينها مسافات.
  final String text;

  final int page;

  final MadinahFont font;

  const QcfGlyphs._(this.text, this.page, this.font);

  static MadinahFont get _font => UserDataStore.instance.settings.madinahFont;

  /// هل جهز تخطيط [font] وخط صفحة [ayah].
  static bool _isReady(Ayah ayah, MadinahFont font) =>
      QcfLayout.of(font).isReady &&
      (font == MadinahFont.digitalKhatt ||
          QcfFonts.instance.isPageLoaded(ayah.page));

  /// كلمات [ayah] في تخطيط [font].
  static List<QcfWord> _words(Ayah ayah, MadinahFont font) {
    final layout = QcfLayout.of(font);
    // صفحات الطبعة الحديثة قد تقدّم آية أو تؤخرها عن صفحة التطبيق.
    final pages = font == MadinahFont.digitalKhatt
        ? [ayah.page, ayah.page - 1, ayah.page + 1]
        : [ayah.page];
    for (final page in pages) {
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

  /// رموز [ayah]، أو null حتى يُحمّل التخطيط وخط صفحتها (انظر [prepare]).
  static QcfGlyphs? of(Ayah ayah) {
    final font = _font;
    if (!_isReady(ayah, font)) return null;
    final words = _words(ayah, font);
    return words.isEmpty
        ? null
        : QcfGlyphs._(
            '${words.map((w) => w.code).join(' ')} ',
            ayah.page,
            font,
          );
  }

  /// رموز المقطع [excerpt] من [ayah]، أو null إن لم تطابق كلماته كلمات الآية.
  ///
  /// النص المكتوب بالرسم الإملائي يطابق رسم المصحف (انظر [_skeleton]).
  static QcfGlyphs? ofExcerpt(Ayah ayah, String excerpt) {
    final font = _font;
    if (!_isReady(ayah, font)) return null;
    final codes = excerptCodes(ayah, excerpt);
    return codes == null
        ? null
        : QcfGlyphs._('${codes.join(' ')} ', ayah.page, font);
  }

  /// رموز كلمات [excerpt] في [ayah]، ومعها علامة الآية إن بلغ آخرها.
  static List<String>? excerptCodes(Ayah ayah, String excerpt) {
    final all = _words(ayah, _font);
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
    final font = _font;
    await QcfLayout.of(font).init();
    if (font == MadinahFont.kingFahd &&
        !await QcfFonts.instance.ensurePage(ayah.page)) {
      return false;
    }
    return of(ayah) != null;
  }

  /// نمط الرموز بحجم [fontSize] للصفحة العادية وتباعد أسطر [height]؛ وصفحتا
  /// البداية تُكبّران لتطابقا.
  TextStyle style({
    required double fontSize,
    required double height,
    required Color color,
    List<Shadow>? shadows,
  }) {
    if (font == MadinahFont.digitalKhatt) {
      return TextStyle(
        fontFamily: QcfPageBody.digitalKhattFamily,
        fontSize: fontSize,
        height: height,
        color: color,
        shadows: shadows,
      );
    }
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
