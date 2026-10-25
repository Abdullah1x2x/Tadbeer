import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Central color system for Tadbeer (تَدْبِير).
///
/// Night navy and burnished gold: a deep, dignified base for long reading
/// sessions, with gold reserved for highlights and interactive emphasis.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // ☀️ LIGHT MODE PALETTE
  // ---------------------------------------------------------------------------
  static const Color lightBackground = Color(0xFFF7F5F0);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF1E3A5F);
  static const Color lightPrimaryDark = Color(0xFF132844);
  static const Color lightAccentGold = Color(0xFFB8913C);
  static const Color lightTextPrimary = Color(0xFF1A2233);
  static const Color lightTextSecondary = Color(0xFF586379);
  static const Color lightBorder = Color(0xFFE4E0D6);
  static const Color lightSelectedAyah = Color(0x40C9A24B);

  // ---------------------------------------------------------------------------
  // 🌙 DARK MODE PALETTE
  // ---------------------------------------------------------------------------
  static const Color darkBackground = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF131C2E);
  static const Color darkPrimary = Color(0xFF5B8BD0);
  static const Color darkPrimaryDark = Color(0xFF1E3A5F);
  static const Color darkAccentGold = Color(0xFFE3C06A);
  static const Color darkTextPrimary = Color(0xFFE8ECF3);
  static const Color darkTextSecondary = Color(0xFF9AA6BA);
  static const Color darkBorder = Color(0xFF253149);
  static const Color darkSelectedAyah = Color(0x4DE3C06A);

  // ---------------------------------------------------------------------------
  // ⚡ DIGITAL ACCENTS & ELEVATIONS
  // ---------------------------------------------------------------------------
  // Bright sky blue and luminous gold for active states and highlights.
  static const Color cyberEmerald = Color(0xFF7FB0F0);
  static const Color electricGold = Color(0xFFE8C878);
  static const Color darkSurfaceElevated = Color(0xFF1A2539);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);

  // Status tones, mid-luminance so they read on both light and dark.
  static const Color statusSuccess = Color(0xFF3F9A72);
  static const Color statusWarning = Color(0xFFD39B32);
  static const Color statusError = Color(0xFFD0574E);
  static const Color statusInfo = Color(0xFF4F86C6);

  // ---------------------------------------------------------------------------
  // 🧱 TONAL SURFACE LAYERS (lowest → highest)
  // ---------------------------------------------------------------------------
  static const Color lightSurfaceLow = Color(0xFFFBFAF7);
  static const Color lightSurfaceHigh = Color(0xFFF0EDE5);
  static const Color lightSurfaceHighest = Color(0xFFE8E4DA);
  static const Color darkSurfaceLowest = Color(0xFF080D18);
  static const Color darkSurfaceLow = Color(0xFF0F1726);
  static const Color darkSurfaceHighest = Color(0xFF22304A);

  // ---------------------------------------------------------------------------
  // 📖 MUSHAF PAGE (classic paper tone in light mode)
  // ---------------------------------------------------------------------------
  static const Color mushafBackground = Color(0xFFF8F4EA);
  static const Color mushafQuranText = Color(0xFF1A2233);

  // ---------------------------------------------------------------------------
  // 🌅 SIGNATURE GRADIENTS
  // ---------------------------------------------------------------------------
  /// تدرج الهوية الكحلي المستخدم في الرؤوس والأزرار البارزة.
  static LinearGradient heroGradient(bool isDark) => LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: isDark
        ? const [Color(0xFF1E3A5F), Color(0xFF0F1D33)]
        : const [Color(0xFF26497A), Color(0xFF132844)],
  );

  /// تدرج ذهبي للعناصر المميزة والشارات.
  static const LinearGradient goldGradient = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [Color(0xFFE8C878), Color(0xFFB8913C)],
  );

  // ---------------------------------------------------------------------------
  // BACKWARD-COMPATIBILITY ALIASES
  // (Maintained so existing call-sites seamlessly map to the authoritative palette)
  // ---------------------------------------------------------------------------
  static const Color olive = lightPrimary;
  static const Color oliveDark = lightPrimaryDark;
  static const Color oliveSoft = darkPrimary;
  static const Color oliveLight = darkPrimary;

  static const Color comsilkLight = lightBackground;
  static const Color comsilk = lightSurfaceHigh;

  static const Color darkSurfaceVariant = darkBorder;

  static const Color dayQuranText = lightTextPrimary;
  static const Color nightQuranText = darkTextPrimary;
  static const Color daySubtitle = lightTextSecondary;
  static const Color nightSubtitle = darkTextSecondary;

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

  static const MushafPalette classicLight = MushafPalette._(
    outer: AppColors.mushafBackground,
    page: AppColors.mushafBackground,
    band: AppColors.lightSurface,
    text: AppColors.mushafQuranText,
  );

  static const MushafPalette classicDark = MushafPalette._(
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

  /// الخط العربي الموحد لواجهة التطبيق بالكامل
  static const String appFontFamily = 'Amiri';

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
    final text = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
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
      fontFamily: appFontFamily,
      colorScheme: colorScheme,
    );

    TextStyle label(double size, {FontWeight weight = FontWeight.bold}) =>
        TextStyle(
          fontFamily: appFontFamily,
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
      splashFactory: InkSparkle.splashFactory,
      hoverColor: primary.withValues(alpha: 0.06),
      focusColor: gold.withValues(alpha: 0.14),
      splashColor: primary.withValues(alpha: 0.14),
      highlightColor: primary.withValues(alpha: 0.06),
      shadowColor: shadow,
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: shadow,
        elevation: isDark ? 0 : 2,
        margin: const EdgeInsets.symmetric(vertical: 6),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: isDark
              ? BorderSide(color: border, width: 1)
              : BorderSide.none,
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
        titleTextStyle: label(20).copyWith(color: text),
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
        titleTextStyle: label(19).copyWith(color: text),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : subtext,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? gold
              : border,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        thumbIcon: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Icon(Icons.check_rounded, size: 16, color: gold)
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
          (states) => label(
            12,
            weight: states.contains(WidgetState.selected)
                ? FontWeight.bold
                : FontWeight.w600,
          ).copyWith(
            color: states.contains(WidgetState.selected) ? primary : subtext,
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
            (states) => states.contains(WidgetState.selected) ? onPrimary : text,
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
        textStyle: label(12, weight: FontWeight.w600).copyWith(
          color: Colors.white,
        ),
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
        fontFamily: appFontFamily,
        fontFamilyFallback: uiFontFallbacks,
        fontWeight: FontWeight.w600,
        color: textColor,
        fontSize: 16,
      ),
      titleSmall: TextStyle(
        fontFamily: appFontFamily,
        fontFamilyFallback: uiFontFallbacks,
        fontWeight: FontWeight.w600,
        color: subtitleColor,
        fontSize: 14,
      ),
      bodyLarge: TextStyle(
        fontFamily: appFontFamily,
        fontFamilyFallback: uiFontFallbacks,
        color: textColor,
        fontSize: 15,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: appFontFamily,
        fontFamilyFallback: uiFontFallbacks,
        color: textColor,
        fontSize: 14,
        height: 1.45,
      ),
      bodySmall: TextStyle(
        fontFamily: appFontFamily,
        fontFamilyFallback: uiFontFallbacks,
        color: subtitleColor,
        fontSize: 12,
      ),
      labelLarge: TextStyle(
        fontFamily: appFontFamily,
        fontFamilyFallback: uiFontFallbacks,
        fontWeight: FontWeight.bold,
        color: textColor,
        fontSize: 14,
      ),
      labelMedium: TextStyle(
        fontFamily: appFontFamily,
        fontFamilyFallback: uiFontFallbacks,
        color: subtitleColor,
        fontSize: 12,
      ),
    );
  }
}
