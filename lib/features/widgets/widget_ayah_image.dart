import 'package:flutter/material.dart';

import '../quran/data/quran_models.dart';

/// آية اليوم كما تُرسم صورةً لودجت الشاشة الرئيسية.
///
/// Widgets cannot use the app's fonts, so the ayah is drawn here in the
/// Quranic font and handed to the widget as a transparent image. The image
/// is exactly as tall as the text, so the widget can scale it to fill
/// whatever space it has.
class WidgetAyahImage extends StatelessWidget {
  final Ayah ayah;

  /// Width the text wraps at, in logical pixels.
  static const width = 360.0;

  const WidgetAyahImage({super.key, required this.ayah});

  static const _gold = Color(0xFFE2C27A);

  static TextSpan _span(Ayah ayah) => TextSpan(
    style: const TextStyle(
      fontFamily: 'AmiriQuran',
      fontSize: 22,
      height: 1.9,
      color: Colors.white,
      shadows: [Shadow(color: Color(0x66000000), blurRadius: 8)],
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
  static Size sizeFor(Ayah ayah) {
    final painter = TextPainter(
      text: _span(ayah),
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
      size: sizeFor(ayah),
      child: Center(
        child: Text.rich(
          _span(ayah),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}
