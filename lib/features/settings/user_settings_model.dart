import 'package:flutter/material.dart';

/// خيارات حجم خط المصحف الثلاثة القياسية (صغير، متوسط، كبير).
///
/// Exactly three Quran font-size options as required by Tadbeer typography specifications:
/// 1. صغير (Small: 19.0pt, fewer pages than 604)
/// 2. متوسط (Medium: 23.0pt, baseline reproducing 604 Medina Mushaf pages)
/// 3. كبير (Large: 28.0pt, more pages than 604)
enum QuranFontSizeOption {
  /// حجم خط صغير.
  small,

  /// حجم خط متوسط (القياسي لمصحف المدينة).
  medium,

  /// حجم خط كبير.
  large;

  /// قيمة حجم الخط بالنقاط المقابلة للخيار المحدد.
  double get fontSize {
    switch (this) {
      case QuranFontSizeOption.small:
        return 15.5;
      case QuranFontSizeOption.medium:
        return 18.5; // Reference Medina Mushaf layout
      case QuranFontSizeOption.large:
        return 22.0;
    }
  }

  /// التسمية العربية لخيار حجم الخط.
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

/// خيارات عائلات الخطوط القرآنية مفتوحة المصدر المدمجة محلياً في التطبيق.
///
/// Open-source Quranic fonts bundled offline in Tadbeer.
enum QuranFontFamilyOption {
  /// خط شهرزاد الجديد.
  scheherazade,

  /// خط نوتو نسخ العربي.
  notoNaskh,

  /// خط هرمتان القرآني.
  harmattan,

  /// خط لطيف القرآني.
  lateef,

  /// خط أميري القرآني.
  amiriQuran;

  /// المعرّف البرمجي لعائلة الخط المسجل في التطبيق.
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

  /// الاسم العربي المعروض لعائلة الخط في شاشة الإعدادات.
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

  /// الاسم المعروض باللغة الإنجليزية لعائلة الخط.
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

  /// يعيد اسم عائلة الخط المناسب بناءً على لغة التطبيق.
  String getLabel(bool isArabic) => isArabic ? labelArabic : labelEnglish;

  /// الوصف التوضيحي لمزايا عائلة الخط باللغة العربية.
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

  /// الوصف التوضيحي لمزايا عائلة الخط باللغة الإنجليزية.
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

  /// يعيد الوصف التوضيحي للخط بناءً على لغة التطبيق.
  String getSubtitle(bool isArabic) =>
      isArabic ? subtitleArabic : subtitleEnglish;
}

/// نموذج إعدادات المستخدم المحفوظة محلياً (المظهر، اللغة، الخطوط، الترحيب).
class UserSettings {
  /// الحجم الافتراضي لخط المصحف بالنقاط.
  static const double defaultQuranFontSize = 20.0;

  /// الحد الأدنى المسموح به لحجم خط المصحف.
  static const double minQuranFontSize = 16.0;

  /// الحد الأقصى المسموح به لحجم خط المصحف.
  static const double maxQuranFontSize = 32.0;

  /// وضع المظهر الحالي (فاتح، داكن، أو حسب النظام).
  final ThemeMode themeMode;

  /// رمز لغة واجهة التطبيق (مثل 'ar' أو 'en').
  final String languageCode;

  /// ما إذا كان المستخدم قد اختار إخفاء شاشة الترحيب بالتدبر نهائياً.
  ///
  /// Whether the user has chosen to permanently dismiss the Tadbeer Intro.
  /// IMPORTANT:
  /// Once set to true, the introduction is NEVER shown again, and no option
  /// is provided to re-enable it, as specified in the Tadbeer requirements.
  final bool hideTadbeerIntroPermanently;

  /// خاصية توافقية مع الإصدارات السابقة لإخفاء شاشة الترحيب.
  ///
  /// Backward compatibility getter
  bool get hideTadabburIntroPermanently => hideTadbeerIntroPermanently;

  /// خيار حجم خط المصحف القياسي.
  final QuranFontSizeOption quranFontOption;

  /// عائلة خط المصحف المختارة.
  final QuranFontFamilyOption quranFontFamily;

  /// حجم خط المصحف المخصص بالنقاط.
  final double quranFontSize;

  /// حجم خط عرض الآيات في شاشة روابط الآيات.
  final double ayahLinkFontSize;

  /// اسم عائلة خط المصحف المختارة للاستخدام المباشر في الأنماط النصية.
  String get quranFontFamilyName => quranFontFamily.fontFamily;

  /// ينشئ كائن إعدادات المستخدم بالقيم المحددة أو الافتراضية.
  const UserSettings({
    this.themeMode = ThemeMode.light,
    this.languageCode = 'ar',
    bool hideTadbeerIntroPermanently = false,
    bool? hideTadabburIntroPermanently,
    this.quranFontOption = QuranFontSizeOption.medium,
    this.quranFontFamily = QuranFontFamilyOption.scheherazade,
    this.quranFontSize = defaultQuranFontSize,
    this.ayahLinkFontSize = 18.0,
  }) : hideTadbeerIntroPermanently =
           hideTadabburIntroPermanently ?? hideTadbeerIntroPermanently;

  /// يحول إعدادات المستخدم إلى خريطة بيانات JSON للحفظ المحلي.
  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'languageCode': languageCode,
    'hideTadbeerIntroPermanently': hideTadbeerIntroPermanently,
    'hideTadabburIntroPermanently': hideTadbeerIntroPermanently,
    'quranFontOption': quranFontOption.name,
    'quranFontFamily': quranFontFamily.name,
    'quranFontSize': quranFontSize,
    'ayahLinkFontSize': ayahLinkFontSize,
  };

  /// ينشئ كائن إعدادات المستخدم من خريطة بيانات JSON المحفوظة.
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
      ayahLinkFontSize: (json['ayahLinkFontSize'] as num?)?.toDouble() ?? 18.0,
    );
  }

  /// ينشئ نسخة محدثة من إعدادات المستخدم مع تعديل الحقول الممررة.
  UserSettings copyWith({
    ThemeMode? themeMode,
    String? languageCode,
    bool? hideTadbeerIntroPermanently,
    bool? hideTadabburIntroPermanently,
    QuranFontSizeOption? quranFontOption,
    QuranFontFamilyOption? quranFontFamily,
    double? quranFontSize,
    double? ayahLinkFontSize,
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
      ayahLinkFontSize: ayahLinkFontSize ?? this.ayahLinkFontSize,
    );
  }
}
