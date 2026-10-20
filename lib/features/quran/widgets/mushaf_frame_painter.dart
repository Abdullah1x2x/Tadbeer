import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../data/quran_models.dart';
import '../data/quran_repository.dart';

/// نوع علامة الهامش في صفحة المصحف الشريف.
enum MarginStampType {
  /// بداية جزء جديد.
  juz,

  /// بداية حزب جديد.
  hizb,

  /// ربع الحزب.
  quarter,

  /// نصف الحزب.
  half,

  /// ثلاثة أرباع الحزب.
  threeQuarters,

  /// سجدة تلاوة.
  sajdah,
}

/// نموذج يمثل بيانات علامة الهامش الزخرفية (القنديل) لصفحة المصحف.
class MarginStampData {
  /// نوع علامة الهامش.
  final MarginStampType type;

  /// النص المعروض داخل علامة الهامش.
  final String label;

  /// رقم الآية المقترنة بالعلامة.
  final int ayahNumber;

  /// رقم السورة المقترنة بالعلامة.
  final int surahNumber;

  /// ينشئ كائناً يمثل علامة الهامش.
  const MarginStampData({
    required this.type,
    required this.label,
    required this.ayahNumber,
    required this.surahNumber,
  });

  /// يستخرج علامات الهوامش المستحقة لصفحة مصحف معينة.
  static List<MarginStampData> forPage(QuranPage page) {
    final stamps = <MarginStampData>[];
    if (page.ayahs.isEmpty) return stamps;

    for (int i = 0; i < page.ayahs.length; i++) {
      final ayah = page.ayahs[i];

      // 1. فحص مواضع السجود
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

      // 2. فحص بدايات الأجزاء والأحزاب والأرباع
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

      // للتحقق من عدم تكرار إضافة نفس الربع على الصفحة
      if (!isQuarterStart || stamps.any((s) => s.type != MarginStampType.sajdah)) {
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

/// ودجت يرسم قنديل الهامش الزخرفي المستدير لصفحة المصحف الشريف.
class MarginStampMedallion extends StatelessWidget {
  /// بيانات علامة الهامش.
  final MarginStampData stamp;

  /// ما إذا كان الوضع الليلي مفعلاً.
  final bool isDark;

  /// ينشئ ودجت قنديل الهامش.
  const MarginStampMedallion({
    super.key,
    required this.stamp,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final goldColor =
        isDark ? AppColors.darkAccentGold : AppColors.lightAccentGold;
    final primaryColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightPrimary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
      child: CustomPaint(
        painter: _MarginMedallionPainter(
          isDark: isDark,
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

/// رسام قنديل الهامش البيضاوي/المفصص المذهب.
class _MarginMedallionPainter extends CustomPainter {
  final bool isDark;
  final bool isSajdah;

  const _MarginMedallionPainter({
    required this.isDark,
    required this.isSajdah,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final goldColor =
        isDark ? AppColors.darkAccentGold : AppColors.lightAccentGold;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12.0));

    // خلفية القنديل
    final bgPaint = Paint()
      ..color = (isDark ? AppColors.darkSurface : AppColors.mushafBackground)
          .withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, bgPaint);

    // إطار مذهب ناعم
    final borderPaint = Paint()
      ..color = goldColor.withValues(alpha: isDark ? 0.75 : 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawRRect(rrect, borderPaint);

    // إطار داخلي دقيق
    final innerRRect = rrect.deflate(2.0);
    final innerPaint = Paint()
      ..color = goldColor.withValues(alpha: isDark ? 0.35 : 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawRRect(innerRRect, innerPaint);

    // حليات ماسية بالأطراف
    final midY = size.height / 2;
    final diamondPaint = Paint()
      ..color = goldColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(2.0, midY), 1.0, diamondPaint);
    canvas.drawCircle(Offset(size.width - 2.0, midY), 1.0, diamondPaint);
  }

  @override
  bool shouldRepaint(covariant _MarginMedallionPainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.isSajdah != isSajdah;
  }
}

/// رسام إطار صفحة المصحف المدني (الصفحات من 3 إلى 604).
///
/// يعتمد على الرسم المتجهي بالمسارات للحفاظ على الحدة على كافة الشاشات،
/// مع قصر إعادة الرسم على تغير السمة (فاتح/داكن) لتحسين أداء تقليب الصفحات.
class MushafPageFramePainter extends CustomPainter {
  /// ما إذا كان الوضع الليلي مفعلاً.
  final bool isDark;

  /// ينشئ رسام إطار صفحة المصحف الشريف.
  const MushafPageFramePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final goldColor =
        isDark ? AppColors.darkAccentGold : AppColors.lightAccentGold;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final outerRect = Rect.fromLTWH(0.5, 0.5, size.width - 1.0, size.height - 1.0);

    // 1. خلفية الورق الأصيلة (Mushaf Parchment Tint)
    final bgPaint = Paint()
      ..color = isDark ? AppColors.darkSurface : AppColors.mushafBackground
      ..style = PaintingStyle.fill;
    canvas.drawRect(outerRect, bgPaint);

    // 2. الإطار الخارجي الرفيع
    final outerBorderPaint = Paint()
      ..color = borderColor.withValues(alpha: isDark ? 0.7 : 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85;
    canvas.drawRect(outerRect, outerBorderPaint);

    // سنون الأركان الخارجية الدقيقة (Corner Finials)
    const finialLen = 4.0;
    final finialPaint = Paint()
      ..color = goldColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;

    // الزوايا الأربع
    canvas.drawLine(const Offset(0.5, -finialLen), const Offset(0.5, 0.5), finialPaint);
    canvas.drawLine(const Offset(-finialLen, 0.5), const Offset(0.5, 0.5), finialPaint);

    canvas.drawLine(Offset(size.width - 0.5, -finialLen), Offset(size.width - 0.5, 0.5), finialPaint);
    canvas.drawLine(Offset(size.width + finialLen, 0.5), Offset(size.width - 0.5, 0.5), finialPaint);

    canvas.drawLine(Offset(0.5, size.height + finialLen), Offset(0.5, size.height - 0.5), finialPaint);
    canvas.drawLine(Offset(-finialLen, size.height - 0.5), Offset(0.5, size.height - 0.5), finialPaint);

    canvas.drawLine(Offset(size.width - 0.5, size.height + finialLen), Offset(size.width - 0.5, size.height - 0.5), finialPaint);
    canvas.drawLine(Offset(size.width + finialLen, size.height - 0.5), Offset(size.width - 0.5, size.height - 0.5), finialPaint);

    // 3. الإطار المذهب الداخلي المزدوج (على بعد 4.0 بكسل من الخارجي)
    const marginInset = 4.0;
    final innerOuterRect = outerRect.deflate(marginInset);
    final goldOuterPaint = Paint()
      ..color = goldColor.withValues(alpha: isDark ? 0.75 : 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(innerOuterRect, goldOuterPaint);

    const goldGap = 2.0;
    final innerInnerRect = innerOuterRect.deflate(goldGap);
    final goldInnerPaint = Paint()
      ..color = goldColor.withValues(alpha: isDark ? 0.45 : 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    canvas.drawRect(innerInnerRect, goldInnerPaint);

    // 4. زوايا الأرابيسك الإسلامية الأربع المذهبة (Islamic Corner Knotwork)
    _drawCornerArabesque(canvas, innerOuterRect.topLeft, goldColor, 1, 1);
    _drawCornerArabesque(canvas, innerOuterRect.topRight, goldColor, -1, 1);
    _drawCornerArabesque(canvas, innerOuterRect.bottomLeft, goldColor, 1, -1);
    _drawCornerArabesque(canvas, innerOuterRect.bottomRight, goldColor, -1, -1);
  }

  /// ترسم عقدة زخرفية إسلامية في ركن الإطار.
  void _drawCornerArabesque(
    Canvas canvas,
    Offset corner,
    Color goldColor,
    double dxSign,
    double dySign,
  ) {
    final knotPaint = Paint()
      ..color = goldColor.withValues(alpha: isDark ? 0.7 : 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;

    final fillPaint = Paint()
      ..color = goldColor.withValues(alpha: isDark ? 0.85 : 0.9)
      ..style = PaintingStyle.fill;

    const kSize = 10.0;
    final knotPath = Path()
      ..moveTo(corner.dx + dxSign * 1.5, corner.dy + dySign * 1.5)
      ..lineTo(corner.dx + dxSign * kSize, corner.dy + dySign * 1.5)
      ..lineTo(corner.dx + dxSign * 1.5, corner.dy + dySign * kSize)
      ..close();

    canvas.drawPath(knotPath, knotPaint);

    // نقطة ماسية مركزية في قلب زاوية الركن
    final diamondCenter = Offset(
      corner.dx + dxSign * 4.0,
      corner.dy + dySign * 4.0,
    );
    canvas.drawCircle(diamondCenter, 1.1, fillPaint);
  }

  @override
  bool shouldRepaint(covariant MushafPageFramePainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}

