import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/storage/user_data_store.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../data/quran_models.dart';

/// Decorative banner rendered at the beginning of each Surah in the Quran reader.
///
/// Faithfully reproduces the authentic aesthetic of the Madinah Mushaf Surah Header band:
/// - Crisp, architectural double-rule gold frame with soft Mushaf paper background.
/// - Symmetrical subtle Islamic corner ties with micro-rosettes.
/// - Top and bottom center Islamic diamond crests.
/// - Lateral pointed palmette finials on the edges.
/// - Central Surah title flanked gracefully by fine horizontal arabesque rules and diamond motifs.
/// - Seamless integrated metadata on the right and an authentic circular seal (خاتم السورة) on the left.
/// - Strictly maintains existing height, margins, and 15pt font size.
/// لافتة زخرفية تعرض في مطلع كل سورة في المصحف الشريف بطابع المصحف المدني.
class SurahHeaderBanner extends StatelessWidget {
  final Surah surah;

  /// ينشئ لافتة ترويسة السورة القرآنية.
  const SurahHeaderBanner({super.key, required this.surah});

  /// يبني ترويسة السورة المزخرفة مع اسم السورة ونوعها وعدد آياتها ورقمها.
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final goldColor = isDark
        ? AppColors.darkAccentGold
        : AppColors.lightAccentGold;
    final titleColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.mushafQuranText;
    final metaColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 2),
      child: CustomPaint(
        painter: _SurahFramePainter(isDark: isDark),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              // Surah Revelation Type & Ayah Count (seamlessly integrated into the band)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${surah.isMeccan ? "مكية" : "مدنية"} · ${ArabicSearchNormalizer.toArabicDigits(surah.ayahCount)} آيات',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: metaColor,
                      height: 1.2,
                    ),
                  ),
                ],
              ),

              // Central Surah Title with fine decorative rules and subtle Islamic diamond motifs
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildFlankRule(goldColor, isLeft: false),
                  const SizedBox(width: 3),
                  Text(
                    '❖',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 7.5,
                      color: goldColor.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'سُورَةُ ${surah.name}',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '❖',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 7.5,
                      color: goldColor.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 3),
                  _buildFlankRule(goldColor, isLeft: true),
                ],
              ),

              // Surah Number inside an authentic miniature seal medallion (خاتم السورة)
              CustomPaint(
                painter: _SurahSealPainter(isDark: isDark),
                child: Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  child: Text(
                    ArabicSearchNormalizer.toArabicDigits(surah.number),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: goldColor,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  /// يبني الخط الزخرفي الجانبي المتدرج المحيط باسم السورة.
  Widget _buildFlankRule(Color color, {required bool isLeft}) {
    return Container(
      width: 14,
      height: 0.7,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLeft
              ? [color.withValues(alpha: 0.6), color.withValues(alpha: 0.0)]
              : [color.withValues(alpha: 0.0), color.withValues(alpha: 0.6)],
        ),
      ),
    );
  }
}

/// Custom painter rendering the authentic miniature seal medallion (خاتم السورة).
/// رسام مخصص يرسم خاتم السورة الدائري المصغر الذي يضم رقم السورة.
class _SurahSealPainter extends CustomPainter {
  final bool isDark;

  /// ينشئ رسام خاتم السورة الدائري.
  const _SurahSealPainter({required this.isDark});

  /// يرسم دوائر ونقاط خاتم السورة الزخرفية على لوحة الرسم.
  @override
  void paint(Canvas canvas, Size size) {
    final goldColor = isDark
        ? AppColors.darkAccentGold
        : AppColors.lightAccentGold;
    final innerGold = goldColor.withValues(alpha: isDark ? 0.7 : 0.65);

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background fill
    final bgPaint = Paint()
      ..color = isDark ? AppColors.darkBackground : AppColors.mushafBackground
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 0.5, bgPaint);

    // Outer hairline circle
    final outerPaint = Paint()
      ..color = goldColor.withValues(alpha: isDark ? 0.65 : 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;
    canvas.drawCircle(center, radius - 0.5, outerPaint);

    // Inner delicate circle
    final innerPaint = Paint()
      ..color = innerGold.withValues(alpha: isDark ? 0.35 : 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.45;
    canvas.drawCircle(center, radius - 2.0, innerPaint);

    // 4 cardinal micro-dots at 0, 90, 180, 270 degrees
    final dotPaint = Paint()
      ..color = goldColor.withValues(alpha: isDark ? 0.65 : 0.75)
      ..style = PaintingStyle.fill;
    const dotR = 0.55;
    final rMid = radius - 1.25;
    canvas.drawCircle(Offset(center.dx, center.dy - rMid), dotR, dotPaint);
    canvas.drawCircle(Offset(center.dx, center.dy + rMid), dotR, dotPaint);
    canvas.drawCircle(Offset(center.dx - rMid, center.dy), dotR, dotPaint);
    canvas.drawCircle(Offset(center.dx + rMid, center.dy), dotR, dotPaint);
  }

  /// يحدد ما إذا كان يلزم إعادة رسم الخاتم عند تغير الوضع الليلي أو النهاري.
  @override
  bool shouldRepaint(covariant _SurahSealPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

/// Custom painter rendering the authentic Madinah Mushaf cartouche frame.
/// رسام مخصص يرسم الإطار الزخرفي الذهبي المزدوج لترويسة السورة.
class _SurahFramePainter extends CustomPainter {
  final bool isDark;

  /// ينشئ رسام إطار ترويسة السورة.
  const _SurahFramePainter({required this.isDark});

  /// يرسم خلفية الترويسة والإطار الذهبي المزدوج والزخارف الجانبية والركنية.
  @override
  void paint(Canvas canvas, Size size) {
    final goldColor = isDark
        ? AppColors.darkAccentGold
        : AppColors.lightAccentGold;
    final innerGold = goldColor.withValues(alpha: isDark ? 0.7 : 0.65);

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2.5));

    // 1. Serene paper background tint matching authentic Madinah Mushaf parchment
    final fillColors = isDark
        ? [
            AppColors.darkBackground,
            AppColors.darkSurface,
            AppColors.darkBackground,
          ]
        : [
            AppColors.mushafBackground,
            AppColors.lightSurface,
            AppColors.mushafBackground,
          ];
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: fillColors,
      ).createShader(rect);
    canvas.drawRRect(rrect, fillPaint);

    // 2. Primary outer hairline gold border (0.8px)
    final outerPaint = Paint()
      ..color = goldColor.withValues(alpha: isDark ? 0.65 : 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRRect(rrect, outerPaint);

    // 3. Delicate inner hairline rule (0.45px at 2.2px inset)
    const inset = 2.2;
    final innerRRect = rrect.deflate(inset);
    final innerPaint = Paint()
      ..color = innerGold.withValues(alpha: isDark ? 0.35 : 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.45;
    canvas.drawRRect(innerRRect, innerPaint);

    // 4. Subtle corner ties connecting outer and inner rules
    final tiePaint = Paint()
      ..color = goldColor.withValues(alpha: isDark ? 0.45 : 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Top-left corner tie
    canvas.drawLine(
      Offset(rect.left + inset, rect.top),
      Offset(rect.left, rect.top + inset),
      tiePaint,
    );
    // Top-right corner tie
    canvas.drawLine(
      Offset(rect.right - inset, rect.top),
      Offset(rect.right, rect.top + inset),
      tiePaint,
    );
    // Bottom-left corner tie
    canvas.drawLine(
      Offset(rect.left + inset, rect.bottom),
      Offset(rect.left, rect.bottom - inset),
      tiePaint,
    );
    // Bottom-right corner tie
    canvas.drawLine(
      Offset(rect.right - inset, rect.bottom),
      Offset(rect.right, rect.bottom - inset),
      tiePaint,
    );

    // Micro corner dots (at inner corner vertex)
    final cornerDotPaint = Paint()
      ..color = goldColor.withValues(alpha: isDark ? 0.55 : 0.65)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(rect.left + inset + 0.8, rect.top + inset + 0.8),
      0.65,
      cornerDotPaint,
    );
    canvas.drawCircle(
      Offset(rect.right - inset - 0.8, rect.top + inset + 0.8),
      0.65,
      cornerDotPaint,
    );
    canvas.drawCircle(
      Offset(rect.left + inset + 0.8, rect.bottom - inset - 0.8),
      0.65,
      cornerDotPaint,
    );
    canvas.drawCircle(
      Offset(rect.right - inset - 0.8, rect.bottom - inset - 0.8),
      0.65,
      cornerDotPaint,
    );

    // 5. Center top & bottom subtle Islamic diamond crests
    final ornamentPaint = Paint()
      ..color = goldColor.withValues(alpha: isDark ? 0.65 : 0.75)
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;

    // Top center micro-diamond
    final topDiamond = Path()
      ..moveTo(centerX, rect.top - 1.0)
      ..lineTo(centerX + 2.0, rect.top + 0.5)
      ..lineTo(centerX, rect.top + 2.0)
      ..lineTo(centerX - 2.0, rect.top + 0.5)
      ..close();
    canvas.drawPath(topDiamond, ornamentPaint);

    // Bottom center micro-diamond
    final bottomDiamond = Path()
      ..moveTo(centerX, rect.bottom + 1.0)
      ..lineTo(centerX + 2.0, rect.bottom - 0.5)
      ..lineTo(centerX, rect.bottom - 2.0)
      ..lineTo(centerX - 2.0, rect.bottom - 0.5)
      ..close();
    canvas.drawPath(bottomDiamond, ornamentPaint);

    // 6. Delicate lateral pointed palmette finials on left & right sides
    final centerY = size.height / 2;
    final finialStrokePaint = Paint()
      ..color = goldColor.withValues(alpha: isDark ? 0.6 : 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.55;

    // Right lateral finial
    final rightPalmette = Path()
      ..moveTo(rect.right - 0.8, centerY - 3.5)
      ..quadraticBezierTo(
        rect.right - 3.8,
        centerY,
        rect.right - 0.8,
        centerY + 3.5,
      );
    canvas.drawPath(rightPalmette, finialStrokePaint);
    canvas.drawCircle(Offset(rect.right - 2.0, centerY), 0.8, ornamentPaint);

    // Left lateral finial
    final leftPalmette = Path()
      ..moveTo(rect.left + 0.8, centerY - 3.5)
      ..quadraticBezierTo(
        rect.left + 3.8,
        centerY,
        rect.left + 0.8,
        centerY + 3.5,
      );
    canvas.drawPath(leftPalmette, finialStrokePaint);
    canvas.drawCircle(Offset(rect.left + 2.0, centerY), 0.8, ornamentPaint);
  }

  /// يحدد ما إذا كان يلزم إعادة رسم الإطار عند تغير الوضع الليلي أو النهاري.
  @override
  bool shouldRepaint(covariant _SurahFramePainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}

/// Decorative Basmalah banner shown between Surahs (except Surah 1 & 9).
/// لافتة البسملة التي تعرض في مطلع السور (باستثناء سورتي الفاتحة والتوبة).
class BismillahBanner extends StatelessWidget {
  /// ينشئ ودجت لافتة البسملة.
  const BismillahBanner({super.key});

  /// يبني نص البسملة متمركزاً بالخط القرآني المختار.
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fontFamily = UserDataStore.instance.quranFontFamily;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Center(
        child: Text(
          'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 17,
            color: isDark ? AppColors.darkTextPrimary : AppColors.mushafQuranText,
          ),
        ),
      ),
    );
  }
}
