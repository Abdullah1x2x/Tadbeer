import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../../../data/quran/quran_models.dart';
import '../../../data/quran/quran_repository.dart';

/// نوع علامة الهامش في صفحة المصحف.
enum MarginStampType {
  juz,

  hizb,

  quarter,

  half,

  threeQuarters,

  /// موضع سجدة تلاوة.
  sajdah,
}

/// علامة هامش زخرفية (قنديل) في صفحة المصحف.
class MarginStampData {
  final MarginStampType type;

  /// النص داخل العلامة.
  final String label;

  final int ayahNumber;

  final int surahNumber;

  const MarginStampData({
    required this.type,
    required this.label,
    required this.ayahNumber,
    required this.surahNumber,
  });

  /// علامات الهامش لصفحة [page].
  static List<MarginStampData> forPage(QuranPage page) {
    final stamps = <MarginStampData>[];
    if (page.ayahs.isEmpty) return stamps;

    for (int i = 0; i < page.ayahs.length; i++) {
      final ayah = page.ayahs[i];

      // ١. مواضع السجود.
      if (ayah.isSajdah) {
        stamps.add(
          MarginStampData(
            type: MarginStampType.sajdah,
            label: 'سَجْدَة ۩',
            ayahNumber: ayah.ayahNumber,
            surahNumber: ayah.surahNumber,
          ),
        );
      }

      // ٢. بدايات الأجزاء والأحزاب والأرباع.
      bool isQuarterStart = false;
      if (i > 0) {
        isQuarterStart = ayah.quarter != page.ayahs[i - 1].quarter;
      } else if (ayah.id > 1 && QuranRepository.instance.isLoaded) {
        final all = QuranRepository.instance.allAyahs;
        if (ayah.id - 2 < all.length) {
          final prevAyah = all[ayah.id - 2];
          isQuarterStart = ayah.quarter != prevAyah.quarter;
        }
      }

      // لا يتكرر نفس الربع في الصفحة.
      if (!isQuarterStart ||
          stamps.any((s) => s.type != MarginStampType.sajdah)) {
        continue;
      }

      final q = ayah.quarter;
      if (q % 8 == 1) {
        stamps.add(
          MarginStampData(
            type: MarginStampType.juz,
            label: 'الجزء ${ArabicSearchNormalizer.toArabicDigits(ayah.juz)}',
            ayahNumber: ayah.ayahNumber,
            surahNumber: ayah.surahNumber,
          ),
        );
      } else if (q % 4 == 1) {
        stamps.add(
          MarginStampData(
            type: MarginStampType.hizb,
            label: 'الحزب ${ArabicSearchNormalizer.toArabicDigits(ayah.hizb)}',
            ayahNumber: ayah.ayahNumber,
            surahNumber: ayah.surahNumber,
          ),
        );
      } else if (q % 4 == 2) {
        stamps.add(
          MarginStampData(
            type: MarginStampType.quarter,
            label: 'رُبْع الحزب',
            ayahNumber: ayah.ayahNumber,
            surahNumber: ayah.surahNumber,
          ),
        );
      } else if (q % 4 == 3) {
        stamps.add(
          MarginStampData(
            type: MarginStampType.half,
            label: 'نِصْف الحزب',
            ayahNumber: ayah.ayahNumber,
            surahNumber: ayah.surahNumber,
          ),
        );
      } else if (q % 4 == 0) {
        stamps.add(
          MarginStampData(
            type: MarginStampType.threeQuarters,
            label: 'ثلاثة أرباع',
            ayahNumber: ayah.ayahNumber,
            surahNumber: ayah.surahNumber,
          ),
        );
      }
    }

    return stamps;
  }
}

/// قنديل الهامش الزخرفي المستدير.
class MarginStampMedallion extends StatelessWidget {
  final MarginStampData stamp;

  final bool isDark;

  final MushafPalette palette;

  const MarginStampMedallion({
    super.key,
    required this.stamp,
    required this.isDark,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    // السجدة تبقى ذهبية، والباقي بلون الإطار.
    final goldColor = isDark
        ? AppColors.darkAccentGold
        : AppColors.lightAccentGold;
    final primaryColor = isDark ? AppColors.darkTextPrimary : palette.frame;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
      child: CustomPaint(
        painter: _MarginMedallionPainter(
          isDark: isDark,
          palette: palette,
          isSajdah: stamp.type == MarginStampType.sajdah,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Text(
            stamp.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: stamp.type == MarginStampType.sajdah
                  ? goldColor
                  : primaryColor,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

/// يرسم القنديل المفصّص المذهّب.
class _MarginMedallionPainter extends CustomPainter {
  final bool isDark;
  final MushafPalette palette;
  final bool isSajdah;

  const _MarginMedallionPainter({
    required this.isDark,
    required this.palette,
    required this.isSajdah,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final frameColor = palette.frame;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12.0));

    final bgPaint = Paint()
      ..color = palette.page.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, bgPaint);

    final borderPaint = Paint()
      ..color = frameColor.withValues(alpha: isDark ? 0.75 : 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawRRect(rrect, borderPaint);

    final innerRRect = rrect.deflate(2.0);
    final innerPaint = Paint()
      ..color = frameColor.withValues(alpha: isDark ? 0.35 : 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawRRect(innerRRect, innerPaint);

    // حليات ماسية في الأطراف.
    final midY = size.height / 2;
    final diamondPaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(2.0, midY), 1.0, diamondPaint);
    canvas.drawCircle(Offset(size.width - 2.0, midY), 1.0, diamondPaint);
  }

  @override
  bool shouldRepaint(covariant _MarginMedallionPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.palette != palette ||
        oldDelegate.isSajdah != isSajdah;
  }
}

/// إطار صفحة المصحف (الصفحات 3..604) بلون إطار الثيم.
///
/// رسم متجهي حادّ في كل الشاشات، ولا يُعاد إلا بتغيّر الثيم أو الوضع أو لون
/// الورق، فيبقى التقليب سريعاً.
class MushafPageFramePainter extends CustomPainter {
  final bool isDark;

  final MushafPalette palette;

  const MushafPageFramePainter({required this.isDark, required this.palette});

  @override
  void paint(Canvas canvas, Size size) {
    final frameColor = palette.frame;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final outerRect = Rect.fromLTWH(
      0.5,
      0.5,
      size.width - 1.0,
      size.height - 1.0,
    );

    // ١. لون الورق.
    final bgPaint = Paint()
      ..color = palette.page
      ..style = PaintingStyle.fill;
    canvas.drawRect(outerRect, bgPaint);

    // ٢. الإطار الخارجي الرفيع.
    final outerBorderPaint = Paint()
      ..color = borderColor.withValues(alpha: isDark ? 0.7 : 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85;
    canvas.drawRect(outerRect, outerBorderPaint);

    // نهايات دقيقة في الأركان الخارجية.
    const finialLen = 4.0;
    final finialPaint = Paint()
      ..color = frameColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;

    canvas.drawLine(
      const Offset(0.5, -finialLen),
      const Offset(0.5, 0.5),
      finialPaint,
    );
    canvas.drawLine(
      const Offset(-finialLen, 0.5),
      const Offset(0.5, 0.5),
      finialPaint,
    );

    canvas.drawLine(
      Offset(size.width - 0.5, -finialLen),
      Offset(size.width - 0.5, 0.5),
      finialPaint,
    );
    canvas.drawLine(
      Offset(size.width + finialLen, 0.5),
      Offset(size.width - 0.5, 0.5),
      finialPaint,
    );

    canvas.drawLine(
      Offset(0.5, size.height + finialLen),
      Offset(0.5, size.height - 0.5),
      finialPaint,
    );
    canvas.drawLine(
      Offset(-finialLen, size.height - 0.5),
      Offset(0.5, size.height - 0.5),
      finialPaint,
    );

    canvas.drawLine(
      Offset(size.width - 0.5, size.height + finialLen),
      Offset(size.width - 0.5, size.height - 0.5),
      finialPaint,
    );
    canvas.drawLine(
      Offset(size.width + finialLen, size.height - 0.5),
      Offset(size.width - 0.5, size.height - 0.5),
      finialPaint,
    );

    // ٣. الإطار المذهب الداخلي المزدوج، على بعد 4 بكسل من الخارجي.
    const marginInset = 4.0;
    final innerOuterRect = outerRect.deflate(marginInset);
    final goldOuterPaint = Paint()
      ..color = frameColor.withValues(alpha: isDark ? 0.75 : 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(innerOuterRect, goldOuterPaint);

    const goldGap = 2.0;
    final innerInnerRect = innerOuterRect.deflate(goldGap);
    final goldInnerPaint = Paint()
      ..color = frameColor.withValues(alpha: isDark ? 0.45 : 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    canvas.drawRect(innerInnerRect, goldInnerPaint);

    // ٤. زخارف الأركان الأربعة.
    _drawCornerArabesque(canvas, innerOuterRect.topLeft, frameColor, 1, 1);
    _drawCornerArabesque(canvas, innerOuterRect.topRight, frameColor, -1, 1);
    _drawCornerArabesque(canvas, innerOuterRect.bottomLeft, frameColor, 1, -1);
    _drawCornerArabesque(
      canvas,
      innerOuterRect.bottomRight,
      frameColor,
      -1,
      -1,
    );
  }

  /// زخرفة إسلامية في ركن الإطار.
  void _drawCornerArabesque(
    Canvas canvas,
    Offset corner,
    Color frameColor,
    double dxSign,
    double dySign,
  ) {
    final knotPaint = Paint()
      ..color = frameColor.withValues(alpha: isDark ? 0.7 : 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;

    final fillPaint = Paint()
      ..color = frameColor.withValues(alpha: isDark ? 0.85 : 0.9)
      ..style = PaintingStyle.fill;

    const kSize = 10.0;
    final knotPath = Path()
      ..moveTo(corner.dx + dxSign * 1.5, corner.dy + dySign * 1.5)
      ..lineTo(corner.dx + dxSign * kSize, corner.dy + dySign * 1.5)
      ..lineTo(corner.dx + dxSign * 1.5, corner.dy + dySign * kSize)
      ..close();

    canvas.drawPath(knotPath, knotPaint);

    // نقطة ماسية في قلب الركن.
    final diamondCenter = Offset(
      corner.dx + dxSign * 4.0,
      corner.dy + dySign * 4.0,
    );
    canvas.drawCircle(diamondCenter, 1.1, fillPaint);
  }

  @override
  bool shouldRepaint(covariant MushafPageFramePainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.palette != palette;
  }
}
