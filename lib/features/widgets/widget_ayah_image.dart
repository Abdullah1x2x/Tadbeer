import 'package:flutter/material.dart';

import '../quran/data/quran_models.dart';
import '../quran/qcf/qcf_ayah_text.dart';

/// آية اليوم كما تُرسم صورةً لودجت الشاشة الرئيسية.
///
/// Widgets cannot use the app's fonts, so the ayah is drawn here in the
/// selected Mushaf's font and handed to the widget as a transparent image:
/// the Madinah glyphs with their printed ayah marker when [glyphs] is
/// given, or the flowing text's [font] between brackets. The image is
/// exactly as tall as the text, so the widget can scale it to fill
/// whatever space it has.
class WidgetAyahImage extends StatelessWidget {
  final Ayah ayah;

  /// The ayah in the Madinah Mushaf's glyphs, when that Mushaf is chosen.
  final QcfGlyphs? glyphs;

  /// The flowing text's font, used without [glyphs].
  final String font;

  /// Width the text wraps at, in logical pixels.
  static const width = 360.0;

  const WidgetAyahImage({
    super.key,
    required this.ayah,
    required this.font,
    this.glyphs,
  });

  static const _gold = Color(0xFFE2C27A);
  static const _shadows = [Shadow(color: Color(0x66000000), blurRadius: 8)];

  static TextSpan _span(Ayah ayah, QcfGlyphs? glyphs, String font) =>
      glyphs != null
      ? TextSpan(
          text: glyphs.text,
          style: glyphs.style(
            fontSize: 22,
            height: 1.9,
            color: Colors.white,
            shadows: _shadows,
          ),
        )
      : _flowing(ayah, font);

  static TextSpan _flowing(Ayah ayah, String font) => TextSpan(
    style: TextStyle(
      fontFamily: font,
      fontSize: 22,
      height: 1.9,
      color: Colors.white,
      shadows: _shadows,
    ),
    children: [
      const TextSpan(
        text: '﴿ ',
        style: TextStyle(color: _gold),
      ),
      TextSpan(text: ayah.text),
      const TextSpan(
        text: ' ﴾',
        style: TextStyle(color: _gold),
      ),
    ],
  );

  /// The canvas that fits [ayah]'s text.
  static Size sizeFor(Ayah ayah, {QcfGlyphs? glyphs, required String font}) {
    final painter = TextPainter(
      text: _span(ayah, glyphs, font),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    )..layout(maxWidth: width);
    final size = Size(width, painter.height.ceilToDouble() + 4);
    painter.dispose();
    return size;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: sizeFor(ayah, glyphs: glyphs, font: font),
      child: Center(
        child: Text.rich(
          _span(ayah, glyphs, font),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}
