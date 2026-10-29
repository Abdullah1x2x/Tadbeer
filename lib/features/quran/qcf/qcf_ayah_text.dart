import 'package:flutter/material.dart';

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
