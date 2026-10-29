import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

/// أحجام خط المصحف الثلاثة: صغير 15.5، ومتوسط 18.5 (يطابق مصحف المدينة)، وكبير 22.
enum QuranFontSizeOption {
  small,

  medium,

  large;

  /// الحجم بالنقاط.
  double get fontSize {
    switch (this) {
      case QuranFontSizeOption.small:
        return 15.5;
      case QuranFontSizeOption.medium:
        return 18.5; // يطابق تخطيط مصحف المدينة
      case QuranFontSizeOption.large:
        return 22.0;
    }
  }

  String get labelArabic {
    switch (this) {
      case QuranFontSizeOption.small:
        return 'صغير';
      case QuranFontSizeOption.medium:
        return 'متوسط';
      case QuranFontSizeOption.large:
        return 'كبير';
    }
  }
}

/// خطوط المصحف المفتوحة المصدر المضمّنة في التطبيق.
enum QuranFontFamilyOption {
  scheherazade,

  notoNaskh,

  harmattan,

  lateef,

  amiriQuran;

  /// اسم الخط كما سُجّل في pubspec.
  String get fontFamily {
    switch (this) {
      case QuranFontFamilyOption.scheherazade:
        return 'ScheherazadeNew';
      case QuranFontFamilyOption.notoNaskh:
        return 'NotoNaskhArabic';
      case QuranFontFamilyOption.harmattan:
        return 'Harmattan';
      case QuranFontFamilyOption.lateef:
        return 'Lateef';
      case QuranFontFamilyOption.amiriQuran:
        return 'AmiriQuran';
    }
  }

  String get labelArabic {
    switch (this) {
      case QuranFontFamilyOption.scheherazade:
        return 'خط شهرزاد القرآني (موصى به)';
      case QuranFontFamilyOption.notoNaskh:
        return 'خط النسخ الواضح (نوتو)';
      case QuranFontFamilyOption.harmattan:
        return 'خط هرمتان القرآني';
      case QuranFontFamilyOption.lateef:
        return 'خط لطيف القرآني';
      case QuranFontFamilyOption.amiriQuran:
        return 'خط أميري القرآني';
    }
  }

  String get labelEnglish {
    switch (this) {
      case QuranFontFamilyOption.scheherazade:
        return 'Scheherazade New (Recommended)';
      case QuranFontFamilyOption.notoNaskh:
        return 'Noto Naskh Arabic';
      case QuranFontFamilyOption.harmattan:
        return 'Harmattan Quranic';
      case QuranFontFamilyOption.lateef:
        return 'Lateef Quranic';
      case QuranFontFamilyOption.amiriQuran:
        return 'Amiri Quranic';
    }
  }

  /// اسم الخط بلغة الواجهة.
  String getLabel(bool isArabic) => isArabic ? labelArabic : labelEnglish;

  /// ما يميّز الخط، بالعربية.
  String get subtitleArabic {
    switch (this) {
      case QuranFontFamilyOption.scheherazade:
        return 'رسم عثماني متكامل مع ضبط التشكيل والوقفات بدقة تامة';
      case QuranFontFamilyOption.notoNaskh:
        return 'خط نسخي فائق الوضوح ومريح للقراءة الطويلة على الشاشات';
      case QuranFontFamilyOption.harmattan:
        return 'تباعد عمودي مريح لعلامات الضبط والوقف المتراكبة';
      case QuranFontFamilyOption.lateef:
        return 'خط نسخي رشيق وهادئ بمسافات متوازنة';
      case QuranFontFamilyOption.amiriQuran:
        return 'الخط الكلاسيكي المستوحى من مصحف بولاق الأميري';
    }
  }

  /// ما يميّز الخط، بالإنجليزية.
  String get subtitleEnglish {
    switch (this) {
      case QuranFontFamilyOption.scheherazade:
        return 'Complete Uthmanic script with precise diacritics and pause marks';
      case QuranFontFamilyOption.notoNaskh:
        return 'Ultra-clear Naskh typeface designed for extended comfortable reading';
      case QuranFontFamilyOption.harmattan:
        return 'Spacious vertical metrics ideal for stacked Quranic annotations';
      case QuranFontFamilyOption.lateef:
        return 'Graceful, light Naskh style with harmonious spacing';
      case QuranFontFamilyOption.amiriQuran:
        return 'Classical typeface inspired by the historic Bulaq Amiri Mushaf';
    }
  }

  /// ما يميّز الخط، بلغة الواجهة.
  String getSubtitle(bool isArabic) =>
      isArabic ? subtitleArabic : subtitleEnglish;
}

/// طريقة عرض المصحف.
enum MushafStyle {
  /// صفحات مصحف المدينة بخط مجمع الملك فهد كما في المطبوع؛ العرض الأساسي.
  madinah,

  /// نص عثماني متدفق بالخط المختار؛ لا يحتاج تحميلاً.
  text,
}

/// إعدادات القارئ المحفوظة على الجهاز: المظهر واللغة والخطوط والقراءة.
class UserSettings {
  /// حجم خط المصحف الافتراضي بالنقاط.
  static const double defaultQuranFontSize = 20.0;

  /// أصغر حجم، يبقى معه التشكيل وعلامات الوقف واضحة.
  static const double minQuranFontSize = 16.0;

  /// أكبر حجم؛ في مصحف المدينة يعني ضعف الصفحة مع التفاف الأسطر.
  static const double maxQuranFontSize = 40.0;

  /// أصغر تصغير للنص المتدفق، نسبةً إلى حجمه التلقائي.
  static const double minFlowingTextScale = 0.8;

  /// أكبر تكبير للنص المتدفق.
  static const double maxFlowingTextScale = 1.4;

  final ThemeMode themeMode;

  /// رمز لغة الواجهة ('ar' أو 'en').
  final String languageCode;

  /// أخفى القارئ شاشة الترحيب نهائياً؛ لا تعود ولا يوجد خيار لإظهارها.
  final bool hideTadbeerIntroPermanently;

  /// الاسم القديم، يبقى للتوافق.
  bool get hideTadabburIntroPermanently => hideTadbeerIntroPermanently;

  final QuranFontSizeOption quranFontOption;

  final QuranFontFamilyOption quranFontFamily;

  /// حجم خط المصحف بالنقاط.
  final double quranFontSize;

  /// تكبير القارئ للنص المتدفق فوق حجمه التلقائي (١ = بلا تكبير).
  final double flowingTextScale;

  /// حجم خط الآيات في شاشة روابط الآيات.
  final double ayahLinkFontSize;

  final MushafPaperTone mushafPaperTone;

  final AppColorTheme colorTheme;

  final MushafStyle mushafStyle;

  /// هل اختار القارئ ثيماً؛ قبل ذلك يفتح التثبيت الجديد على منتقي الثيم. الإعدادات المحفوظة قبل وجود هذا الحقل تُعدّ اختياراً.
  final bool themeChosen;

  /// الاسم الذي يناديه به التذكير؛ فارغ إن لم يكتبه. يبقى على الجهاز فقط.
  final String userName;

  /// اسم خط المصحف للاستخدام المباشر في أنماط النص.
  String get quranFontFamilyName => quranFontFamily.fontFamily;

  const UserSettings({
    this.themeMode = ThemeMode.light,
    this.languageCode = 'ar',
    bool hideTadbeerIntroPermanently = false,
    bool? hideTadabburIntroPermanently,
    this.quranFontOption = QuranFontSizeOption.medium,
    this.quranFontFamily = QuranFontFamilyOption.scheherazade,
    this.quranFontSize = defaultQuranFontSize,
    this.flowingTextScale = 1.0,
    this.ayahLinkFontSize = 18.0,
    this.mushafPaperTone = MushafPaperTone.classic,
    this.colorTheme = AppColorTheme.navy,
    this.mushafStyle = MushafStyle.madinah,
    this.themeChosen = false,
    this.userName = '',
  }) : hideTadbeerIntroPermanently =
           hideTadabburIntroPermanently ?? hideTadbeerIntroPermanently;

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'languageCode': languageCode,
    'hideTadbeerIntroPermanently': hideTadbeerIntroPermanently,
    'hideTadabburIntroPermanently': hideTadbeerIntroPermanently,
    'quranFontOption': quranFontOption.name,
    'quranFontFamily': quranFontFamily.name,
    'quranFontSize': quranFontSize,
    'flowingTextScale': flowingTextScale,
    'ayahLinkFontSize': ayahLinkFontSize,
    'mushafPaperTone': mushafPaperTone.name,
    'colorTheme': colorTheme.name,
    'mushafStyle': mushafStyle.name,
    'themeChosen': themeChosen,
    'userName': userName,
  };

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    ThemeMode mode;
    switch (json['themeMode'] as String?) {
      case 'light':
        mode = ThemeMode.light;
        break;
      case 'dark':
        mode = ThemeMode.dark;
        break;
      default:
        mode = ThemeMode.system;
    }

    QuranFontSizeOption fontOpt = QuranFontSizeOption.medium;
    final optionStr = json['quranFontOption'] as String?;
    if (optionStr != null) {
      fontOpt = QuranFontSizeOption.values.firstWhere(
        (e) => e.name == optionStr,
        orElse: () => QuranFontSizeOption.medium,
      );
    }

    QuranFontFamilyOption familyOpt = QuranFontFamilyOption.scheherazade;
    final familyStr = json['quranFontFamily'] as String?;
    if (familyStr != null) {
      familyOpt = QuranFontFamilyOption.values.firstWhere(
        (e) => e.name == familyStr || e.fontFamily == familyStr,
        orElse: () => QuranFontFamilyOption.scheherazade,
      );
    }

    double quranSize = UserSettings.defaultQuranFontSize;
    if (json['quranFontSize'] != null) {
      final fs = (json['quranFontSize'] as num).toDouble();
      quranSize = fs.clamp(
        UserSettings.minQuranFontSize,
        UserSettings.maxQuranFontSize,
      );
    }

    return UserSettings(
      themeMode: mode,
      languageCode: json['languageCode'] as String? ?? 'ar',
      hideTadbeerIntroPermanently:
          json['hideTadbeerIntroPermanently'] as bool? ??
          json['hideTadabburIntroPermanently'] as bool? ??
          false,
      quranFontOption: fontOpt,
      quranFontFamily: familyOpt,
      quranFontSize: quranSize,
      flowingTextScale: ((json['flowingTextScale'] as num?)?.toDouble() ?? 1.0)
          .clamp(minFlowingTextScale, maxFlowingTextScale),
      ayahLinkFontSize: (json['ayahLinkFontSize'] as num?)?.toDouble() ?? 18.0,
      colorTheme: AppColorTheme.values.firstWhere(
        (e) => e.name == json['colorTheme'],
        orElse: () => AppColorTheme.navy,
      ),
      mushafPaperTone: MushafPaperTone.values.firstWhere(
        (e) => e.name == json['mushafPaperTone'],
        orElse: () => MushafPaperTone.classic,
      ),
      mushafStyle: MushafStyle.values.firstWhere(
        (e) => e.name == json['mushafStyle'],
        orElse: () => MushafStyle.madinah,
      ),
      themeChosen: json['themeChosen'] as bool? ?? true,
      userName: json['userName'] as String? ?? '',
    );
  }

  UserSettings copyWith({
    ThemeMode? themeMode,
    String? languageCode,
    bool? hideTadbeerIntroPermanently,
    bool? hideTadabburIntroPermanently,
    QuranFontSizeOption? quranFontOption,
    QuranFontFamilyOption? quranFontFamily,
    double? quranFontSize,
    double? flowingTextScale,
    double? ayahLinkFontSize,
    MushafPaperTone? mushafPaperTone,
    AppColorTheme? colorTheme,
    MushafStyle? mushafStyle,
    bool? themeChosen,
    String? userName,
  }) {
    final newQuranFontSize = quranFontSize != null
        ? quranFontSize.clamp(minQuranFontSize, maxQuranFontSize)
        : this.quranFontSize;

    return UserSettings(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      hideTadbeerIntroPermanently:
          hideTadbeerIntroPermanently ??
          hideTadabburIntroPermanently ??
          this.hideTadbeerIntroPermanently,
      quranFontOption: quranFontOption ?? this.quranFontOption,
      quranFontFamily: quranFontFamily ?? this.quranFontFamily,
      quranFontSize: newQuranFontSize,
      flowingTextScale:
          flowingTextScale?.clamp(minFlowingTextScale, maxFlowingTextScale) ??
          this.flowingTextScale,
      ayahLinkFontSize: ayahLinkFontSize ?? this.ayahLinkFontSize,
      mushafPaperTone: mushafPaperTone ?? this.mushafPaperTone,
      colorTheme: colorTheme ?? this.colorTheme,
      mushafStyle: mushafStyle ?? this.mushafStyle,
      themeChosen: themeChosen ?? this.themeChosen,
      userName: userName?.trim() ?? this.userName,
    );
  }
}
