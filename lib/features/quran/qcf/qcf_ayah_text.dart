import 'package:flutter/material.dart';

import '../../../data/quran/quran_models.dart';
import 'qcf_fonts.dart';
import 'qcf_layout.dart';
import 'qcf_page_body.dart';

/// حروف آية بخط مصحف المدينة جاهزة للرسم: رموزها واسم خط صفحتها.
///
/// The ayah's words are its glyphs in the Madinah Mushaf, ending with the
/// printed ayah-number marker; every page there ends on a whole ayah, so
/// they all come from the ayah's page, drawn in that page's font.
class QcfGlyphs {
  /// The glyph codes, words separated by spaces.
  final String text;

  final int page;

  const QcfGlyphs._(this.text, this.page);

  /// The [ayah]'s glyphs, or null until the layout and its page's font
  /// are loaded (see [prepare]).
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

  /// Loads what [of] needs for [ayah]; true once its glyphs can be drawn.
  static Future<bool> prepare(Ayah ayah) async {
    await QcfLayout.instance.init();
    return await QcfFonts.instance.ensurePage(ayah.page) && of(ayah) != null;
  }

  /// The look of the glyphs at [fontSize] of an ordinary page, with lines
  /// [height] apart; opening pages are scaled to match.
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

/// آية واحدة بخط مصحف المدينة، تلتف أسطرها حسب المساحة.
///
/// The ayah's words are its glyphs in the Madinah Mushaf, ending with the
/// printed ayah-number marker; every page there ends on a whole ayah, so
/// they all come from the ayah's page. Until the layout and that page's
/// font are ready, and if they cannot be loaded, [fallback] shows instead.
class QcfAyahText extends StatefulWidget {
  final Ayah ayah;

  /// Font size of an ordinary page's glyphs; opening pages are scaled to
  /// match.
  final double fontSize;

  final Color color;

  /// Line height relative to [fontSize].
  final double height;

  /// Shown while the glyphs load, or if they cannot be drawn.
  final Widget fallback;

  /// ينشئ نص الآية بخط مصحف المدينة.
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
    // Drawn at once when the glyphs are already loaded, as when the ayah
    // is opened from its page in the Mushaf.
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
