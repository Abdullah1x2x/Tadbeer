import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import '../core/design_system/app_icons.dart';

/// سمات الألوان التي يختارها المستخدم (الكحلي هو الافتراضي).
enum AppColorTheme {
  /// كحلي
  navy,

  /// زمردي
  emerald,

  /// عنابي
  burgundy,

  /// بني خشبي
  brown,

  /// تركوازي
  teal,
}

/// مجموعة ألوان سمة واحدة للوضعين الفاتح والداكن.
class ThemePalette {
  final Color lightBackground;
  final Color lightSurface;
  final Color lightPrimary;
  final Color lightPrimaryDark;
  final Color lightAccentGold;
  final Color lightTextPrimary;
  final Color lightTextSecondary;
  final Color lightBorder;
  final Color lightSelectedAyah;
  final Color darkBackground;
  final Color darkSurface;
  final Color darkPrimary;
  final Color darkPrimaryDark;
  final Color darkAccentGold;
  final Color darkTextPrimary;
  final Color darkTextSecondary;
  final Color darkBorder;
  final Color darkSelectedAyah;
  final Color cyberEmerald;
  final Color electricGold;
  final Color darkSurfaceElevated;
  final Color lightSurfaceElevated;
  final Color lightSurfaceLow;
  final Color lightSurfaceHigh;
  final Color lightSurfaceHighest;
  final Color darkSurfaceLowest;
  final Color darkSurfaceLow;
  final Color darkSurfaceHighest;
  final Color heroLightStart;
  final Color heroLightEnd;
  final Color heroDarkStart;
  final Color heroDarkEnd;
  final Color goldLight;
  final Color goldDeep;

  const ThemePalette({
    required this.lightBackground,
    required this.lightSurface,
    required this.lightPrimary,
    required this.lightPrimaryDark,
    required this.lightAccentGold,
    required this.lightTextPrimary,
    required this.lightTextSecondary,
    required this.lightBorder,
    required this.lightSelectedAyah,
    required this.darkBackground,
    required this.darkSurface,
    required this.darkPrimary,
    required this.darkPrimaryDark,
    required this.darkAccentGold,
    required this.darkTextPrimary,
    required this.darkTextSecondary,
    required this.darkBorder,
    required this.darkSelectedAyah,
    required this.cyberEmerald,
    required this.electricGold,
    required this.darkSurfaceElevated,
    required this.lightSurfaceElevated,
    required this.lightSurfaceLow,
    required this.lightSurfaceHigh,
    required this.lightSurfaceHighest,
    required this.darkSurfaceLowest,
    required this.darkSurfaceLow,
    required this.darkSurfaceHighest,
    required this.heroLightStart,
    required this.heroLightEnd,
    required this.heroDarkStart,
    required this.heroDarkEnd,
    required this.goldLight,
    required this.goldDeep,
  });

  static const ThemePalette navy = ThemePalette(
    lightBackground: Color(0xFFF7F5F0),
    lightSurface: Color(0xFFFFFFFF),
    lightPrimary: Color(0xFF1E3A5F),
    lightPrimaryDark: Color(0xFF132844),
    lightAccentGold: Color(0xFFB8913C),
    lightTextPrimary: Color(0xFF1A2233),
    lightTextSecondary: Color(0xFF586379),
    lightBorder: Color(0xFFE4E0D6),
    lightSelectedAyah: Color(0x40C9A24B),
    darkBackground: Color(0xFF0B1220),
    darkSurface: Color(0xFF131C2E),
    darkPrimary: Color(0xFF5B8BD0),
    darkPrimaryDark: Color(0xFF1E3A5F),
    darkAccentGold: Color(0xFFE3C06A),
    darkTextPrimary: Color(0xFFE8ECF3),
    darkTextSecondary: Color(0xFF9AA6BA),
    darkBorder: Color(0xFF253149),
    darkSelectedAyah: Color(0x4DE3C06A),
    cyberEmerald: Color(0xFF7FB0F0),
    electricGold: Color(0xFFE8C878),
    darkSurfaceElevated: Color(0xFF1A2539),
    lightSurfaceElevated: Color(0xFFFFFFFF),
    lightSurfaceLow: Color(0xFFFBFAF7),
    lightSurfaceHigh: Color(0xFFF0EDE5),
    lightSurfaceHighest: Color(0xFFE8E4DA),
    darkSurfaceLowest: Color(0xFF080D18),
    darkSurfaceLow: Color(0xFF0F1726),
    darkSurfaceHighest: Color(0xFF22304A),
    heroLightStart: Color(0xFF26497A),
    heroLightEnd: Color(0xFF132844),
    heroDarkStart: Color(0xFF1E3A5F),
    heroDarkEnd: Color(0xFF0F1D33),
    goldLight: Color(0xFFE8C878),
    goldDeep: Color(0xFFB8913C),
  );

  static const ThemePalette emerald = ThemePalette(
    lightBackground: Color(0xFFF5F7F3),
    lightSurface: Color(0xFFFFFFFF),
    lightPrimary: Color(0xFF1E5B47),
    lightPrimaryDark: Color(0xFF123D2F),
    lightAccentGold: Color(0xFFB8913C),
    lightTextPrimary: Color(0xFF17241D),
    lightTextSecondary: Color(0xFF55665C),
    lightBorder: Color(0xFFDFE5DD),
    lightSelectedAyah: Color(0x40C9A24B),
    darkBackground: Color(0xFF0A110D),
    darkSurface: Color(0xFF121C16),
    darkPrimary: Color(0xFF4FAF86),
    darkPrimaryDark: Color(0xFF1E5B47),
    darkAccentGold: Color(0xFFE3C06A),
    darkTextPrimary: Color(0xFFE6EFE9),
    darkTextSecondary: Color(0xFF98AA9F),
    darkBorder: Color(0xFF223329),
    darkSelectedAyah: Color(0x4DE3C06A),
    cyberEmerald: Color(0xFF6FD3A4),
    electricGold: Color(0xFFE8C878),
    darkSurfaceElevated: Color(0xFF18251D),
    lightSurfaceElevated: Color(0xFFFFFFFF),
    lightSurfaceLow: Color(0xFFFAFBF8),
    lightSurfaceHigh: Color(0xFFEDF1EA),
    lightSurfaceHighest: Color(0xFFE4EAE1),
    darkSurfaceLowest: Color(0xFF07100B),
    darkSurfaceLow: Color(0xFF0E1812),
    darkSurfaceHighest: Color(0xFF203127),
    heroLightStart: Color(0xFF22684F),
    heroLightEnd: Color(0xFF123D2F),
    heroDarkStart: Color(0xFF1E5B47),
    heroDarkEnd: Color(0xFF0E2A20),
    goldLight: Color(0xFFE8C878),
    goldDeep: Color(0xFFB8913C),
  );

  static const ThemePalette burgundy = ThemePalette(
    lightBackground: Color(0xFFFAF6F1),
    lightSurface: Color(0xFFFFFFFF),
    lightPrimary: Color(0xFF7A2E3B),
    lightPrimaryDark: Color(0xFF561F29),
    lightAccentGold: Color(0xFFB07A3C),
    lightTextPrimary: Color(0xFF2A1A1D),
    lightTextSecondary: Color(0xFF6E5A5E),
    lightBorder: Color(0xFFEADFDA),
    lightSelectedAyah: Color(0x40D09A60),
    darkBackground: Color(0xFF160E10),
    darkSurface: Color(0xFF22171A),
    darkPrimary: Color(0xFFD27A88),
    darkPrimaryDark: Color(0xFF7A2E3B),
    darkAccentGold: Color(0xFFDDB06A),
    darkTextPrimary: Color(0xFFF1E6E8),
    darkTextSecondary: Color(0xFFB49EA3),
    darkBorder: Color(0xFF3A272C),
    darkSelectedAyah: Color(0x4DDDB06A),
    cyberEmerald: Color(0xFFF0A1AE),
    electricGold: Color(0xFFE7B77A),
    darkSurfaceElevated: Color(0xFF2A1D21),
    lightSurfaceElevated: Color(0xFFFFFFFF),
    lightSurfaceLow: Color(0xFFFCFAF7),
    lightSurfaceHigh: Color(0xFFF3ECE6),
    lightSurfaceHighest: Color(0xFFEBE2DA),
    darkSurfaceLowest: Color(0xFF100A0C),
    darkSurfaceLow: Color(0xFF1B1215),
    darkSurfaceHighest: Color(0xFF36262B),
    heroLightStart: Color(0xFF8E3747),
    heroLightEnd: Color(0xFF561F29),
    heroDarkStart: Color(0xFF6A2633),
    heroDarkEnd: Color(0xFF2E1218),
    goldLight: Color(0xFFE7B77A),
    goldDeep: Color(0xFFB07A3C),
  );

  static const ThemePalette brown = ThemePalette(
    lightBackground: Color(0xFFF8F3EA),
    lightSurface: Color(0xFFFFFDF8),
    lightPrimary: Color(0xFF6B4E32),
    lightPrimaryDark: Color(0xFF4A3522),
    lightAccentGold: Color(0xFFB8863B),
    lightTextPrimary: Color(0xFF2B2118),
    lightTextSecondary: Color(0xFF6D6052),
    lightBorder: Color(0xFFE6DCCB),
    lightSelectedAyah: Color(0x40C9A24B),
    darkBackground: Color(0xFF14100B),
    darkSurface: Color(0xFF1F1912),
    darkPrimary: Color(0xFFC79A6B),
    darkPrimaryDark: Color(0xFF6B4E32),
    darkAccentGold: Color(0xFFE0B56A),
    darkTextPrimary: Color(0xFFEFE6DA),
    darkTextSecondary: Color(0xFFAFA08D),
    darkBorder: Color(0xFF352B20),
    darkSelectedAyah: Color(0x4DE0B56A),
    cyberEmerald: Color(0xFFE2B98A),
    electricGold: Color(0xFFE6C07F),
    darkSurfaceElevated: Color(0xFF271F17),
    lightSurfaceElevated: Color(0xFFFFFFFF),
    lightSurfaceLow: Color(0xFFFBF8F1),
    lightSurfaceHigh: Color(0xFFF1EADD),
    lightSurfaceHighest: Color(0xFFE8DFCE),
    darkSurfaceLowest: Color(0xFF0F0C08),
    darkSurfaceLow: Color(0xFF191410),
    darkSurfaceHighest: Color(0xFF33291F),
    heroLightStart: Color(0xFF7D5C3C),
    heroLightEnd: Color(0xFF4A3522),
    heroDarkStart: Color(0xFF5E442C),
    heroDarkEnd: Color(0xFF261B12),
    goldLight: Color(0xFFE6C07F),
    goldDeep: Color(0xFFB8863B),
  );

  static const ThemePalette teal = ThemePalette(
    lightBackground: Color(0xFFF3F7F7),
    lightSurface: Color(0xFFFFFFFF),
    lightPrimary: Color(0xFF115E67),
    lightPrimaryDark: Color(0xFF0B4248),
    lightAccentGold: Color(0xFFB58E45),
    lightTextPrimary: Color(0xFF132427),
    lightTextSecondary: Color(0xFF54686B),
    lightBorder: Color(0xFFDCE6E6),
    lightSelectedAyah: Color(0x40C9A24B),
    darkBackground: Color(0xFF0B1416),
    darkSurface: Color(0xFF132022),
    darkPrimary: Color(0xFF4FB3B6),
    darkPrimaryDark: Color(0xFF115E67),
    darkAccentGold: Color(0xFFE3C07A),
    darkTextPrimary: Color(0xFFE3EEEF),
    darkTextSecondary: Color(0xFF98AEB0),
    darkBorder: Color(0xFF213335),
    darkSelectedAyah: Color(0x4DE3C07A),
    cyberEmerald: Color(0xFF6FD6D6),
    electricGold: Color(0xFFE8CB8A),
    darkSurfaceElevated: Color(0xFF192A2D),
    lightSurfaceElevated: Color(0xFFFFFFFF),
    lightSurfaceLow: Color(0xFFF9FBFB),
    lightSurfaceHigh: Color(0xFFEAF1F1),
    lightSurfaceHighest: Color(0xFFE1EAEA),
    darkSurfaceLowest: Color(0xFF081012),
    darkSurfaceLow: Color(0xFF0F1A1C),
    darkSurfaceHighest: Color(0xFF22383B),
    heroLightStart: Color(0xFF16737D),
    heroLightEnd: Color(0xFF0B4248),
    heroDarkStart: Color(0xFF115E67),
    heroDarkEnd: Color(0xFF08282C),
    goldLight: Color(0xFFE8CB8A),
    goldDeep: Color(0xFFB58E45),
  );

  /// مجموعة الألوان المقابلة للسمة.
  static ThemePalette of(AppColorTheme theme) {
    switch (theme) {
      case AppColorTheme.navy:
        return navy;
      case AppColorTheme.emerald:
        return emerald;
      case AppColorTheme.burgundy:
        return burgundy;
      case AppColorTheme.brown:
        return brown;
      case AppColorTheme.teal:
        return teal;
    }
  }
}

/// Central color system for Tadbeer (تَدْبِير).
///
/// The colors come from the selected [AppColorTheme] (night navy and
/// burnished gold by default). Names stay the same across themes, so every
/// screen follows the user's choice; call [use] to switch.
class AppColors {
  AppColors._();

  static ThemePalette _p = ThemePalette.navy;
  static AppColorTheme _theme = AppColorTheme.navy;

  /// السمة الحالية.
  static AppColorTheme get theme => _theme;

  /// يبدّل مجموعة الألوان؛ يعيد true إذا تغيّرت.
  static bool use(AppColorTheme theme) {
    if (theme == _theme) return false;
    _theme = theme;
    _p = ThemePalette.of(theme);
    return true;
  }

  static Color get lightBackground => _p.lightBackground;
  static Color get lightSurface => _p.lightSurface;
  static Color get lightPrimary => _p.lightPrimary;
  static Color get lightPrimaryDark => _p.lightPrimaryDark;
  static Color get lightAccentGold => _p.lightAccentGold;
  static Color get lightTextPrimary => _p.lightTextPrimary;
  static Color get lightTextSecondary => _p.lightTextSecondary;
  static Color get lightBorder => _p.lightBorder;
  static Color get lightSelectedAyah => _p.lightSelectedAyah;
  static Color get darkBackground => _p.darkBackground;
  static Color get darkSurface => _p.darkSurface;
  static Color get darkPrimary => _p.darkPrimary;
  static Color get darkPrimaryDark => _p.darkPrimaryDark;
  static Color get darkAccentGold => _p.darkAccentGold;
  static Color get darkTextPrimary => _p.darkTextPrimary;
  static Color get darkTextSecondary => _p.darkTextSecondary;
  static Color get darkBorder => _p.darkBorder;
  static Color get darkSelectedAyah => _p.darkSelectedAyah;
  static Color get cyberEmerald => _p.cyberEmerald;
  static Color get electricGold => _p.electricGold;
  static Color get darkSurfaceElevated => _p.darkSurfaceElevated;
  static Color get lightSurfaceElevated => _p.lightSurfaceElevated;
  static Color get lightSurfaceLow => _p.lightSurfaceLow;
  static Color get lightSurfaceHigh => _p.lightSurfaceHigh;
  static Color get lightSurfaceHighest => _p.lightSurfaceHighest;
  static Color get darkSurfaceLowest => _p.darkSurfaceLowest;
  static Color get darkSurfaceLow => _p.darkSurfaceLow;
  static Color get darkSurfaceHighest => _p.darkSurfaceHighest;

  // Status tones, mid-luminance so they read on both light and dark.
  static const Color statusSuccess = Color(0xFF3F9A72);
  static const Color statusWarning = Color(0xFFD39B32);
  static const Color statusError = Color(0xFFD0574E);
  static const Color statusInfo = Color(0xFF4F86C6);

  // ---------------------------------------------------------------------------
  // 📖 MUSHAF PAGE (classic paper tone in light mode)
  // ---------------------------------------------------------------------------
  static const Color mushafBackground = Color(0xFFF8F4EA);
  static Color get mushafQuranText => _p.lightTextPrimary;

  // ---------------------------------------------------------------------------
  // 🌅 SIGNATURE GRADIENTS
  // ---------------------------------------------------------------------------
  /// تدرج الهوية المستخدم في الرؤوس والأزرار البارزة.
  static LinearGradient heroGradient(bool isDark) => LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: isDark
        ? [_p.heroDarkStart, _p.heroDarkEnd]
        : [_p.heroLightStart, _p.heroLightEnd],
  );

  /// تدرج ذهبي للعناصر المميزة والشارات.
  static LinearGradient get goldGradient => LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [_p.goldLight, _p.goldDeep],
  );

  // ---------------------------------------------------------------------------
  // BACKWARD-COMPATIBILITY ALIASES
  // (Maintained so existing call-sites seamlessly map to the current palette)
  // ---------------------------------------------------------------------------
  static Color get olive => lightPrimary;
  static Color get oliveDark => lightPrimaryDark;
  static Color get oliveSoft => darkPrimary;
  static Color get oliveLight => darkPrimary;

  static Color get comsilkLight => lightBackground;
  static Color get comsilk => lightSurfaceHigh;

  static Color get darkSurfaceVariant => darkBorder;

  static Color get dayQuranText => lightTextPrimary;
  static Color get nightQuranText => darkTextPrimary;
  static Color get daySubtitle => lightTextSecondary;
  static Color get nightSubtitle => darkTextSecondary;

  // ---------------------------------------------------------------------------
  // AYAH HIGHLIGHT PALETTE
  // (Light, translucent tones that keep Quranic text fully legible)
  // ---------------------------------------------------------------------------
  static const List<Color> highlightColors = [
    Color(0x555B8BD0), // Sky navy highlight
    Color(0x55E3C06A), // Gold highlight
    Color(0x5576B39A), // Mint highlight
    Color(0x55D99A9A), // Rose highlight
  ];

  // ---------------------------------------------------------------------------
  // DYNAMIC CONTEXT HELPERS
  // ---------------------------------------------------------------------------

  /// إرجاع لون خلفية الشاشة المناسب للوضع الفاتح أو الداكن.
  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkBackground
      : lightBackground;

  /// إرجاع لون البطاقات والأسطح المناسب للوضع الفاتح أو الداكن.
  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkSurface
      : lightSurface;

  /// إرجاع اللون الأساسي للتطبيق حسب السمة الحالية.
  static Color primary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkPrimary
      : lightPrimary;

  /// إرجاع لون النص الأساسي حسب السمة الحالية.
  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkTextPrimary
      : lightTextPrimary;

  /// إرجاع لون الإطارات والفواصل حسب السمة الحالية.
  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkBorder
      : lightBorder;

  /// إرجاع لون النص الثانوي حسب السمة الحالية.
  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkTextSecondary
      : lightTextSecondary;

  /// إرجاع اللون الذهبي المميز حسب السمة الحالية.
  static Color accentGold(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkAccentGold
      : lightAccentGold;

  /// إرجاع لون تحديد الآية المختارة حسب السمة الحالية.
  static Color selectedAyah(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkSelectedAyah
      : lightSelectedAyah;

  /// إرجاع لون السطح المرتفع حسب السمة الحالية.
  static Color surfaceElevated(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkSurfaceElevated
      : lightSurfaceElevated;
}

/// لون ورق المصحف الذي يختاره المستخدم للقراءة.
enum MushafPaperTone {
  /// ورق المصحف الكلاسيكي الفاتح.
  classic,

  /// ورق سيبيا دافئ يخفف وهج الشاشة أثناء القراءة الطويلة.
  sepia,
}

/// ألوان صفحة المصحف المحسوبة من السمة ولون الورق المختار.
///
/// Instances are canonical constants, so painters can compare them by
/// identity in `shouldRepaint`.
class MushafPalette {
  /// لون المساحة المحيطة بالصفحة.
  final Color outer;

  /// لون ورق الصفحة نفسها.
  final Color page;

  /// لون الشريط الأوسط في تدرج ترويسة السورة.
  final Color band;

  /// لون النص القرآني.
  final Color text;

  const MushafPalette._({
    required this.outer,
    required this.page,
    required this.band,
    required this.text,
  });

  static final MushafPalette classicLight = MushafPalette._(
    outer: AppColors.mushafBackground,
    page: AppColors.mushafBackground,
    band: AppColors.lightSurface,
    text: AppColors.mushafQuranText,
  );

  static final MushafPalette classicDark = MushafPalette._(
    outer: AppColors.darkBackground,
    page: AppColors.darkSurface,
    band: AppColors.darkSurface,
    text: AppColors.darkTextPrimary,
  );

  static const MushafPalette sepiaLight = MushafPalette._(
    outer: Color(0xFFEAD9B8),
    page: Color(0xFFEAD9B8),
    band: Color(0xFFE0CCA6),
    text: Color(0xFF3B2F1E),
  );

  static const MushafPalette sepiaDark = MushafPalette._(
    outer: Color(0xFF120F0A),
    page: Color(0xFF1B1610),
    band: Color(0xFF1B1610),
    text: Color(0xFFDDD0B6),
  );

  /// إرجاع ألوان الصفحة المناسبة للوضع الحالي ولون الورق المختار.
  static MushafPalette of({
    required bool isDark,
    required MushafPaperTone tone,
  }) {
    switch (tone) {
      case MushafPaperTone.classic:
        return isDark ? classicDark : classicLight;
      case MushafPaperTone.sepia:
        return isDark ? sepiaDark : sepiaLight;
    }
  }
}

/// Application theme definitions for Tadbeer.
///
/// Material 3 theme built from the navy and gold palette: soft rounded
/// shapes, shadow-based depth instead of borders, and tactile state feedback
/// (sparkle ripples, gold focus rings, animated selection) on every control.
class AppTheme {
  AppTheme._();

  /// خط العناوين والنصوص الكبيرة (عناوين الشاشات، والحوارات، والأدعية).
  static const String appFontFamily = 'Amiri';

  /// خط الواجهة: الأزرار والقوائم والنصوص العادية.
  static const String uiFontFamily = 'IBMPlexSansArabic';

  /// System-safe modern Arabic and Latin UI font fallbacks
  static const List<String> uiFontFallbacks = [
    'Noto Sans Arabic',
    'Segoe UI',
    'Roboto',
    'Cairo',
    'sans-serif',
  ];

  /// انحناء البطاقات.
  static const double cardRadius = 20;

  /// انحناء الأزرار وحقول الإدخال.
  static const double controlRadius = 16;

  /// انحناء الحوارات واللوحات السفلية.
  static const double sheetRadius = 28;

  /// إعدادات السمة الفاتحة (النهارية) للتطبيق.
  static ThemeData get lightTheme => _build(Brightness.light);

  /// إعدادات السمة الداكنة (الليلية) للتطبيق.
  static ThemeData get darkTheme => _build(Brightness.dark);

  /// يبني السمة الكاملة للوضع المحدد من لوحة الألوان الموحدة.
  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final background = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final elevated = isDark
        ? AppColors.darkSurfaceElevated
        : AppColors.lightSurfaceElevated;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final gold = isDark ? AppColors.darkAccentGold : AppColors.lightAccentGold;
    final text = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subtext = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final shadow = isDark
        ? Colors.black.withValues(alpha: 0.6)
        : AppColors.lightPrimary.withValues(alpha: 0.10);
    final onPrimary = Colors.white;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primary.withValues(alpha: isDark ? 0.24 : 0.12),
      onPrimaryContainer: isDark ? AppColors.darkTextPrimary : primary,
      secondary: gold,
      onSecondary: isDark ? AppColors.darkBackground : Colors.white,
      secondaryContainer: gold.withValues(alpha: isDark ? 0.22 : 0.16),
      onSecondaryContainer: text,
      tertiary: isDark ? AppColors.cyberEmerald : AppColors.lightPrimaryDark,
      onTertiary: isDark ? AppColors.darkBackground : Colors.white,
      error: isDark ? const Color(0xFFFF8A80) : const Color(0xFFC0392B),
      onError: isDark ? const Color(0xFF3B0A06) : Colors.white,
      surface: surface,
      onSurface: text,
      surfaceContainerLowest: isDark
          ? AppColors.darkSurfaceLowest
          : AppColors.lightSurfaceElevated,
      surfaceContainerLow: isDark
          ? AppColors.darkSurfaceLow
          : AppColors.lightSurfaceLow,
      surfaceContainer: surface,
      surfaceContainerHigh: isDark
          ? AppColors.darkSurfaceElevated
          : AppColors.lightSurfaceHigh,
      surfaceContainerHighest: isDark
          ? AppColors.darkSurfaceHighest
          : AppColors.lightSurfaceHighest,
      onSurfaceVariant: subtext,
      outline: border,
      outlineVariant: border,
      shadow: shadow,
      surfaceTint: Colors.transparent,
    );

    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: uiFontFamily,
      colorScheme: colorScheme,
    );

    TextStyle label(double size, {FontWeight weight = FontWeight.bold}) =>
        TextStyle(
          fontFamily: uiFontFamily,
          fontFamilyFallback: uiFontFallbacks,
          fontWeight: weight,
          fontSize: size,
        );

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(controlRadius),
    );

    // Pressed controls dim slightly so every tap is visibly acknowledged.
    WidgetStateProperty<Color?> overlay(Color color) =>
        WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return color.withValues(alpha: 0.16);
          }
          if (states.contains(WidgetState.hovered)) {
            return color.withValues(alpha: 0.08);
          }
          if (states.contains(WidgetState.focused)) {
            return color.withValues(alpha: 0.12);
          }
          return null;
        });

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      scaffoldBackgroundColor: background,
      canvasColor: background,
      // InkRipple: InkSparkle's shader costs a frame on every tap.
      splashFactory: InkRipple.splashFactory,
      hoverColor: primary.withValues(alpha: 0.06),
      focusColor: gold.withValues(alpha: 0.14),
      splashColor: primary.withValues(alpha: 0.14),
      highlightColor: primary.withValues(alpha: 0.06),
      shadowColor: shadow,
      // Back, close and menu buttons use the same Phosphor set as the rest.
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (_) => const Icon(AppIcons.arrowLeft),
        closeButtonIconBuilder: (_) => const Icon(AppIcons.x),
        drawerButtonIconBuilder: (_) => const Icon(AppIcons.list),
        endDrawerButtonIconBuilder: (_) => const Icon(AppIcons.list),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: shadow,
        elevation: isDark ? 0 : 2,
        margin: const EdgeInsets.symmetric(vertical: 6),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: isDark ? BorderSide(color: border, width: 1) : BorderSide.none,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: shadow,
        centerTitle: true,
        iconTheme: IconThemeData(color: primary),
        actionsIconTheme: IconThemeData(color: primary),
        titleTextStyle: label(
          20,
        ).copyWith(fontFamily: appFontFamily, color: text),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.horizontal(
            end: Radius.circular(sheetRadius),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: elevated,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: shadow,
        titleTextStyle: label(
          19,
        ).copyWith(fontFamily: appFontFamily, color: text),
        contentTextStyle: label(
          14,
          weight: FontWeight.normal,
        ).copyWith(color: text, height: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(sheetRadius),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: elevated,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(sheetRadius),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: border,
          elevation: isDark ? 0 : 3,
          shadowColor: primary.withValues(alpha: 0.35),
          textStyle: label(15),
          minimumSize: const Size(64, 50),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: controlShape,
          animationDuration: const Duration(milliseconds: 180),
        ).copyWith(overlayColor: overlay(onPrimary)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          textStyle: label(15),
          minimumSize: const Size(64, 50),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: controlShape,
        ).copyWith(overlayColor: overlay(onPrimary)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: label(14),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ).copyWith(overlayColor: overlay(primary)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary.withValues(alpha: 0.5), width: 1.4),
          textStyle: label(15),
          minimumSize: const Size(64, 50),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: controlShape,
        ).copyWith(overlayColor: overlay(primary)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ).copyWith(overlayColor: overlay(primary)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: gold,
        foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? AppColors.darkSurfaceLow
            : AppColors.lightSurfaceLow,
        labelStyle: label(14, weight: FontWeight.normal),
        floatingLabelStyle: label(14).copyWith(color: primary),
        hintStyle: label(
          14,
          weight: FontWeight.normal,
        ).copyWith(color: subtext.withValues(alpha: 0.8)),
        prefixIconColor: subtext,
        suffixIconColor: subtext,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: inputBorder(border),
        enabledBorder: inputBorder(border),
        focusedBorder: inputBorder(gold, 2),
        errorBorder: inputBorder(colorScheme.error),
        focusedErrorBorder: inputBorder(colorScheme.error, 2),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurfaceHigh,
        selectedColor: primary,
        secondarySelectedColor: primary,
        checkmarkColor: onPrimary,
        labelStyle: label(13, weight: FontWeight.w600).copyWith(color: text),
        secondaryLabelStyle: label(13).copyWith(color: onPrimary),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: const StadiumBorder(),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.white : subtext,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? gold : border,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        thumbIcon: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Icon(AppIcons.check, size: 16, color: gold)
              : null,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? gold : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(
          isDark ? AppColors.darkBackground : Colors.white,
        ),
        side: BorderSide(color: subtext, width: 1.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? gold : subtext,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: gold,
        inactiveTrackColor: border,
        thumbColor: gold,
        overlayColor: gold.withValues(alpha: 0.18),
        valueIndicatorColor: primary,
        valueIndicatorTextStyle: label(13).copyWith(color: onPrimary),
        trackHeight: 5,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: gold,
        linearTrackColor: border,
        circularTrackColor: border,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: primary,
        textColor: text,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shadowColor: shadow,
        height: 68,
        indicatorColor: gold.withValues(alpha: isDark ? 0.22 : 0.20),
        indicatorShape: const StadiumBorder(),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? primary : subtext,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) =>
              label(
                12,
                weight: states.contains(WidgetState.selected)
                    ? FontWeight.bold
                    : FontWeight.w600,
              ).copyWith(
                color: states.contains(WidgetState.selected)
                    ? primary
                    : subtext,
              ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: subtext,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? primary
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? onPrimary : text,
          ),
          side: WidgetStateProperty.all(BorderSide(color: border)),
          shape: WidgetStateProperty.all(controlShape),
          textStyle: WidgetStateProperty.all(label(13)),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: subtext,
        indicatorColor: gold,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        overlayColor: overlay(primary),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: gold, width: 3),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
        ),
        labelStyle: label(14),
        unselectedLabelStyle: label(14, weight: FontWeight.normal),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: elevated,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: shadow,
        textStyle: label(14, weight: FontWeight.w600).copyWith(color: text),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceHighest : AppColors.lightPrimary,
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: label(
          12,
          weight: FontWeight.w600,
        ).copyWith(color: Colors.white),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? AppColors.darkSurfaceHighest
            : AppColors.lightPrimaryDark,
        actionTextColor: AppColors.electricGold,
        elevation: 6,
        contentTextStyle: label(
          14,
          weight: FontWeight.w600,
        ).copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: gold,
        textColor: isDark ? AppColors.darkBackground : Colors.white,
      ),
      iconTheme: IconThemeData(color: primary),
      textTheme: _buildTextTheme(base.textTheme, text, subtext),
      dividerTheme: DividerThemeData(
        color: border.withValues(alpha: isDark ? 0.8 : 1),
        thickness: 1,
        space: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// بناء أنماط النصوص الموحدة مع خطوط احتياطية متوافقة مع العربية واللاتينية.
  static TextTheme _buildTextTheme(
    TextTheme base,
    Color textColor,
    Color subtitleColor,
  ) {
    return base.copyWith(
      headlineLarge: TextStyle(
        fontFamily: appFontFamily,
        fontFamilyFallback: uiFontFallbacks,
        fontWeight: FontWeight.bold,
        color: textColor,
        fontSize: 26,
      ),
      headlineMedium: TextStyle(
        fontFamily: appFontFamily,
        fontFamilyFallback: uiFontFallbacks,
        fontWeight: FontWeight.bold,
        color: textColor,
        fontSize: 22,
      ),
      titleLarge: TextStyle(
        fontFamily: appFontFamily,
        fontFamilyFallback: uiFontFallbacks,
        fontWeight: FontWeight.bold,
        color: textColor,
        fontSize: 19,
      ),
      titleMedium: TextStyle(
        fontFamily: uiFontFamily,
        fontFamilyFallback: uiFontFallbacks,
        fontWeight: FontWeight.w600,
        color: textColor,
        fontSize: 16,
      ),
      titleSmall: TextStyle(
        fontFamily: uiFontFamily,
        fontFamilyFallback: uiFontFallbacks,
        fontWeight: FontWeight.w600,
        color: subtitleColor,
        fontSize: 14,
      ),
      bodyLarge: TextStyle(
        fontFamily: uiFontFamily,
        fontFamilyFallback: uiFontFallbacks,
        color: textColor,
        fontSize: 15,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: uiFontFamily,
        fontFamilyFallback: uiFontFallbacks,
        color: textColor,
        fontSize: 14,
        height: 1.45,
      ),
      bodySmall: TextStyle(
        fontFamily: uiFontFamily,
        fontFamilyFallback: uiFontFallbacks,
        color: subtitleColor,
        fontSize: 12,
      ),
      labelLarge: TextStyle(
        fontFamily: uiFontFamily,
        fontFamilyFallback: uiFontFallbacks,
        fontWeight: FontWeight.bold,
        color: textColor,
        fontSize: 14,
      ),
      labelMedium: TextStyle(
        fontFamily: uiFontFamily,
        fontFamilyFallback: uiFontFallbacks,
        color: subtitleColor,
        fontSize: 12,
      ),
    );
  }
}
