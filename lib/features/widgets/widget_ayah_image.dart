import 'package:flutter/material.dart';

import '../../data/quran/quran_models.dart';
import '../quran/qcf/qcf_ayah_text.dart';

/// الآية مرسومة صورةً لودجت الشاشة الرئيسية.
///
/// الودجت لا يستطيع استخدام خطوط التطبيق، فتُرسم الآية هنا بخط المصحف المختار
/// وتُعطى له صورة شفافة: خطوط مصحف المدينة بعلامة آيتها إن مُرّرت [glyphs]،
/// وإلا خط [font] بين قوسين. ارتفاع الصورة بقدر النص تماماً، ليكبّرها الودجت
/// بقدر مساحته.
class WidgetAyahImage extends StatelessWidget {
  final Ayah ayah;

  /// الآية بخطوط مصحف المدينة، حين يكون هو المختار.
  final QcfGlyphs? glyphs;

  /// خط النص المتدفق، يُستخدم دون [glyphs].
  final String font;

  /// العرض الذي يلتف عنده النص.
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

  /// اللوحة التي تتسع لنص [ayah].
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
