import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// محددات نظام التصميم المستقبلي لتطبيق تَدْبِير.
///
/// Centralized Design Tokens for the Tadbeer Futuristic Digital Experience.
/// Contains standardized spacing, radii, border styles, glows, gradients,
/// and responsive layout constraints.
class AppTokens {
  AppTokens._();

  // ---------------------------------------------------------------------------
  // 📏 SPACING & INSETS (8-point geometric scale)
  // ---------------------------------------------------------------------------
  /// 2.0px - مسافة مجهرية
  static const double spaceMicro = 2.0;

  /// 4.0px - مسافة فائقة الصغر
  static const double spaceXxs = 4.0;

  /// 8.0px - مسافة صغيرة جداً
  static const double spaceXs = 8.0;

  /// 12.0px - مسافة صغيرة متوازنة
  static const double spaceSm = 12.0;

  /// 16.0px - المسافة القياسية المعتمدة
  static const double spaceMd = 16.0;

  /// 20.0px - مسافة واسعة مريحة
  static const double spaceLg = 20.0;

  /// 24.0px - مسافة قسم رئيسي
  static const double spaceXl = 24.0;

  /// 32.0px - مسافة فواصل عريضة
  static const double spaceXxl = 32.0;

  // ---------------------------------------------------------------------------
  // 🔘 CORNER RADII (High-tech curved geometry)
  // ---------------------------------------------------------------------------
  /// 6.0px - انحناء خفيف للشارات الدقيقة
  static const double radiusXs = 6.0;

  /// 10.0px - انحناء معتدل للأزرار والشرائح
  static const double radiusSm = 10.0;

  /// 14.0px - انحناء قياسي للأدوات وعناصر القوائم
  static const double radiusMd = 14.0;

  /// 18.0px - انحناء ناعم للبطاقات التفاعلية
  static const double radiusLg = 18.0;

  /// 24.0px - انحناء رحب للبطاقات البارزة والحوارات
  static const double radiusXl = 24.0;

  /// 30.0px - انحناء الحاويات الكبرى واللوحات السفلية
  static const double radiusXxl = 30.0;

  /// 999.0px - شكل كبسولي كامل (Pill)
  static const double radiusPill = 999.0;

  // ---------------------------------------------------------------------------
  // 📐 BORDER THICKNESS (Precision stroke styling)
  // ---------------------------------------------------------------------------
  /// 0.8px - خط شعري بالغ الدقة
  static const double borderHairline = 0.8;

  /// 1.2px - خط الحدود الافتراضي للبطاقات
  static const double borderRegular = 1.2;

  /// 1.8px - خط مؤكد للحالات النشطة والمركّزة
  static const double borderEmphasized = 1.8;

  /// 2.2px - خط عريض للتحديد المميز
  static const double borderActive = 2.2;

  // ---------------------------------------------------------------------------
  // 🌌 FUTURISTIC GLOWS & AMBIENT SHADOWS
  // ---------------------------------------------------------------------------

  /// يولد ظلاً هادئاً متعدد الطبقات مع وهج محيطي خفيف يعكس طابع المستقبل.
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

  /// وهج مركّز للبطاقات البارزة (Hero Cards) يعطي عمقاً رقمياً جذاباً.
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

  /// وهج نابض للحالات النشطة ومؤشرات الحالة الرقمية.
  static List<BoxShadow> pulseGlow({required Color color}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.35),
        blurRadius: 8,
        spreadRadius: 1,
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // 🎨 FUTURISTIC DIGITAL GRADIENTS
  // ---------------------------------------------------------------------------

  /// تدرج خلفية ناعم للبطاقات يمنح إحساساً بالسطح المصقول الرقمي.
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

  /// تدرج حواف هندسي مستقبلي لإطارات البطاقات.
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
