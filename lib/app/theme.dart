import 'package:flutter/material.dart';

/// Central color system for Tadbeer (تَدْبِير).
///
/// Crafted for prolonged, serene reading with dignified aesthetics inspired by
/// classical Mushaf paper, deep forest green, and antique gold accents.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // ☀️ LIGHT MODE PALETTE
  // ---------------------------------------------------------------------------
  static const Color lightBackground = Color(0xFFF6F3EA);
  static const Color lightSurface = Color(0xFFEDE8DA);
  static const Color lightPrimary = Color(0xFF29483A);
  static const Color lightPrimaryDark = Color(0xFF1C3329);
  static const Color lightAccentGold = Color(0xFFA88A55);
  static const Color lightTextPrimary = Color(0xFF292824);
  static const Color lightTextSecondary = Color(0xFF565248);
  static const Color lightBorder = Color(0xFFD4CBB8);
  static const Color lightSelectedAyah = Color(0x42B89745);

  // ---------------------------------------------------------------------------
  // 🌙 DARK MODE PALETTE
  // ---------------------------------------------------------------------------
  static const Color darkBackground = Color(0xFF121713);
  static const Color darkSurface = Color(0xFF1C241F);
  static const Color darkPrimary = Color(0xFF3D6652);
  static const Color darkPrimaryDark = Color(0xFF29483A);
  static const Color darkAccentGold = Color(0xFFC0A66B);
  static const Color darkTextPrimary = Color(0xFFE7E2D7);
  static const Color darkTextSecondary = Color(0xFFAAA69C);
  static const Color darkBorder = Color(0xFF384139);
  static const Color darkSelectedAyah = Color(0x52C0A66B);

  // ---------------------------------------------------------------------------
  // 📖 MUSHAF PAGE (Fixed across both Light and Dark modes)
  // ---------------------------------------------------------------------------
  static const Color mushafBackground = Color(0xFFF1EBDD);
  static const Color mushafQuranText = Color(0xFF292824);

  // ---------------------------------------------------------------------------
  // BACKWARD-COMPATIBILITY ALIASES
  // (Maintained so existing call-sites seamlessly map to the authoritative palette)
  // ---------------------------------------------------------------------------
  static const Color olive = lightPrimary; // #29483A
  static const Color oliveDark = lightPrimaryDark; // #1C3329
  static const Color oliveSoft = darkPrimary; // #3D6652
  static const Color oliveLight = darkPrimary; // #3D6652

  static const Color comsilkLight = lightBackground; // #F6F3EA
  static const Color comsilk = lightSurface; // #EDE8DA

  static const Color darkSurfaceVariant = darkBorder; // #384139

  static const Color dayQuranText = lightTextPrimary; // #292824
  static const Color nightQuranText = darkTextPrimary; // #E7E2D7
  static const Color daySubtitle = lightTextSecondary; // #6F6B61
  static const Color nightSubtitle = darkTextSecondary; // #AAA69C

  // ---------------------------------------------------------------------------
  // AYAH HIGHLIGHT PALETTE
  // (Calm, dignified tones harmonized with the new palette)
  // ---------------------------------------------------------------------------
  static const List<Color> highlightColors = [
    Color(0x5529483A), // Deep Forest green highlight
    Color(0x55A88A55), // Warm Accent Gold highlight
    Color(0x55A8B89F), // Sage / Olive highlight
    Color(0x55A67C68), // Earthy Rose highlight
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
}

/// Application theme definitions for Tadbeer.
///
/// Implements Material 3 specifications configured with the authoritative
/// warm parchment, deep forest green, and antique gold palette.
class AppTheme {
  AppTheme._();

  /// System-safe modern Arabic and Latin UI font fallbacks
  static const List<String> uiFontFallbacks = [
    'Noto Sans Arabic',
    'Segoe UI',
    'Roboto',
    'Cairo',
    'sans-serif',
  ];

  /// إعدادات السمة الفاتحة (النهارية) للتطبيق.
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.lightBackground,
      hoverColor: AppColors.lightPrimary.withValues(alpha: 0.06),
      focusColor: AppColors.lightPrimary.withValues(alpha: 0.10),
      splashColor: AppColors.lightPrimary.withValues(alpha: 0.12),
      highlightColor: AppColors.lightPrimary.withValues(alpha: 0.05),
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.lightPrimary,
        onPrimary: Colors.white,
        secondary: AppColors.lightAccentGold,
        onSecondary: Colors.white,
        tertiary: AppColors.lightPrimaryDark,
        onTertiary: Colors.white,
        error: Color(0xFFBA1A1A),
        onError: Colors.white,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        surfaceContainerHighest: AppColors.lightSurface,
        surfaceContainer: AppColors.lightSurface,
        onSurfaceVariant: AppColors.lightTextSecondary,
        outline: AppColors.lightBorder,
        outlineVariant: AppColors.lightBorder,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.lightBackground,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lightPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightPrimary,
          side: const BorderSide(color: AppColors.lightPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.lightPrimary,
            width: 1.5,
          ),
        ),
      ),
      textTheme: _buildTextTheme(
        base.textTheme,
        AppColors.lightTextPrimary,
        AppColors.lightTextSecondary,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// إعدادات السمة الداكنة (الليلية) للتطبيق.
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.darkBackground,
      hoverColor: AppColors.darkPrimary.withValues(alpha: 0.08),
      focusColor: AppColors.darkPrimary.withValues(alpha: 0.12),
      splashColor: AppColors.darkPrimary.withValues(alpha: 0.12),
      highlightColor: AppColors.darkPrimary.withValues(alpha: 0.06),
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.darkPrimary,
        onPrimary: Colors.white,
        secondary: AppColors.darkAccentGold,
        onSecondary: Colors.black,
        tertiary: AppColors.darkPrimaryDark,
        onTertiary: Colors.white,
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        surfaceContainerHighest: AppColors.darkSurface,
        surfaceContainer: AppColors.darkSurface,
        onSurfaceVariant: AppColors.darkTextSecondary,
        outline: AppColors.darkBorder,
        outlineVariant: AppColors.darkBorder,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.darkBackground,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          side: const BorderSide(color: AppColors.darkPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.darkPrimary,
            width: 1.5,
          ),
        ),
      ),
      textTheme: _buildTextTheme(
        base.textTheme,
        AppColors.darkTextPrimary,
        AppColors.darkTextSecondary,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
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
        fontFamilyFallback: uiFontFallbacks,
        fontWeight: FontWeight.bold,
        color: textColor,
        fontSize: 26,
      ),
      headlineMedium: TextStyle(
        fontFamilyFallback: uiFontFallbacks,
        fontWeight: FontWeight.bold,
        color: textColor,
        fontSize: 22,
      ),
      titleLarge: TextStyle(
        fontFamilyFallback: uiFontFallbacks,
        fontWeight: FontWeight.bold,
        color: textColor,
        fontSize: 19,
      ),
      titleMedium: TextStyle(
        fontFamilyFallback: uiFontFallbacks,
        fontWeight: FontWeight.w600,
        color: textColor,
        fontSize: 16,
      ),
      titleSmall: TextStyle(
        fontFamilyFallback: uiFontFallbacks,
        fontWeight: FontWeight.w600,
        color: subtitleColor,
        fontSize: 14,
      ),
      bodyLarge: TextStyle(
        fontFamilyFallback: uiFontFallbacks,
        color: textColor,
        fontSize: 15,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamilyFallback: uiFontFallbacks,
        color: textColor,
        fontSize: 14,
        height: 1.45,
      ),
      bodySmall: TextStyle(
        fontFamilyFallback: uiFontFallbacks,
        color: subtitleColor,
        fontSize: 12,
      ),
      labelLarge: TextStyle(
        fontFamilyFallback: uiFontFallbacks,
        fontWeight: FontWeight.bold,
        color: textColor,
        fontSize: 14,
      ),
      labelMedium: TextStyle(
        fontFamilyFallback: uiFontFallbacks,
        color: subtitleColor,
        fontSize: 12,
      ),
    );
  }
}
