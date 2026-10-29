import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// قيم التصميم الموحّدة: المسافات والانحناءات وسماكة الإطارات والظلال
/// والتدرجات.
class AppTokens {
  AppTokens._();

  // المسافات (على مقياس 8 نقاط)
  static const double spaceMicro = 2.0;

  static const double spaceXxs = 4.0;

  static const double spaceXs = 8.0;

  static const double spaceSm = 12.0;

  /// المسافة القياسية.
  static const double spaceMd = 16.0;

  static const double spaceLg = 20.0;

  /// مسافة بين الأقسام.
  static const double spaceXl = 24.0;

  static const double spaceXxl = 32.0;

  // انحناء الزوايا
  /// للشارات الصغيرة.
  static const double radiusXs = 6.0;

  /// للأزرار والشرائح.
  static const double radiusSm = 10.0;

  /// للأدوات وعناصر القوائم.
  static const double radiusMd = 14.0;

  /// للبطاقات التفاعلية.
  static const double radiusLg = 18.0;

  /// للبطاقات البارزة والحوارات.
  static const double radiusXl = 24.0;

  /// للحاويات الكبيرة واللوحات السفلية.
  static const double radiusXxl = 30.0;

  /// كبسولة كاملة.
  static const double radiusPill = 999.0;

  // سماكة الإطارات
  /// خط شعري.
  static const double borderHairline = 0.8;

  /// إطار البطاقات الافتراضي.
  static const double borderRegular = 1.2;

  /// للحالات النشطة والمركّزة.
  static const double borderEmphasized = 1.8;

  /// للتحديد البارز.
  static const double borderActive = 2.2;

  // الظلال والوهج

  /// ظل هادئ متعدد الطبقات للبطاقات.
  static List<BoxShadow> cardShadow({
    required bool isDark,
    Color? glowColor,
    double opacity = 1.0,
  }) {
    if (isDark) {
      final glow = glowColor ?? AppColors.darkPrimary;
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.45 * opacity),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: glow.withValues(alpha: 0.12 * opacity),
          blurRadius: 20,
          spreadRadius: -2,
          offset: const Offset(0, 2),
        ),
      ];
    } else {
      final glow = glowColor ?? AppColors.lightPrimary;
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04 * opacity),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: glow.withValues(alpha: 0.05 * opacity),
          blurRadius: 14,
          spreadRadius: -1,
          offset: const Offset(0, 4),
        ),
      ];
    }
  }

  /// وهج أقوى للبطاقات البارزة.
  static List<BoxShadow> heroGlow({
    required bool isDark,
    required Color accentColor,
  }) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.50 : 0.06),
        blurRadius: 20,
        offset: const Offset(0, 6),
      ),
      BoxShadow(
        color: accentColor.withValues(alpha: isDark ? 0.22 : 0.12),
        blurRadius: 28,
        spreadRadius: -4,
        offset: const Offset(0, 4),
      ),
    ];
  }

  /// وهج لمؤشرات الحالة النشطة.
  static List<BoxShadow> pulseGlow({required Color color}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.35),
        blurRadius: 8,
        spreadRadius: 1,
      ),
    ];
  }

  // التدرجات

  /// تدرج خفيف لسطح البطاقات.
  static LinearGradient subtleSurfaceGradient({
    required bool isDark,
    Color? baseColor,
    Color? tintColor,
  }) {
    final bg =
        baseColor ?? (isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final tint =
        tintColor ??
        (isDark
            ? AppColors.darkPrimary.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.40));

    return LinearGradient(
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
      colors: [Color.alphaBlend(tint, bg), bg],
    );
  }

  /// تدرج لإطارات البطاقات.
  static LinearGradient borderGradient({
    required bool isDark,
    required Color accentColor,
    double startAlpha = 0.55,
    double endAlpha = 0.15,
  }) {
    return LinearGradient(
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
      colors: [
        accentColor.withValues(alpha: startAlpha),
        (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(
          alpha: endAlpha,
        ),
      ],
    );
  }
}
