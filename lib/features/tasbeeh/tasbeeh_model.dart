import 'data/curated_dhikrs.dart';

export 'data/curated_dhikrs.dart';

/// أقسام أذكار السبحة والمحراب (استغفار وتسبيح).
enum DhikrSection {
  /// قسم الاستغفار والتوبة.
  istighfar,

  /// قسم التسبيح والتحميد والذكر.
  tasbeeh,
}

/// امتداد مساعد لقسم الذكر يوفر المسميات العربية البسيطة والمباشرة.
extension DhikrSectionX on DhikrSection {
  /// عنوان القسم.
  String get title {
    switch (this) {
      case DhikrSection.istighfar:
        return 'الاستغفار';
      case DhikrSection.tasbeeh:
        return 'التسبيح';
    }
  }

  /// العنوان القصير للعرض في الأزرار والتبويبات.
  String get shortTitle => title;
}

/// نموذج بيانات الأذكار والاستغفار والتسبيح للسبحة الإلكترونية.
class TasbeehDhikr {
  final String id;
  final String arabicText;
  final String englishTranslation;
  final String virtue;
  final String category;
  final int defaultTarget;
  final DhikrSection section;

  /// ينشئ ذكراً أو صيغة استغفار وتسبيح.
  const TasbeehDhikr({
    required this.id,
    required this.arabicText,
    required this.englishTranslation,
    required this.virtue,
    required this.category,
    this.defaultTarget = 33,
    this.section = DhikrSection.tasbeeh,
  });

  /// ما إذا كان الذكر يتبع لقسم الاستغفار.
  bool get isIstighfar => section == DhikrSection.istighfar;

  /// ما إذا كان الذكر يتبع لقسم التسبيح.
  bool get isTasbeeh => section == DhikrSection.tasbeeh;

  /// التصنيفات المعتمدة: استغفار وتسبيح فقط دون أي تعقيد.
  static const List<String> categories = [
    'الكل',
    'استغفار',
    'تسبيح',
  ];

  /// قائمة صيغ الاستغفار فقط.
  static List<TasbeehDhikr> get istighfarDhikrs =>
      defaultDhikrs.where((d) => d.section == DhikrSection.istighfar).toList();

  /// قائمة صيغ التسبيح فقط.
  static List<TasbeehDhikr> get tasbeehDhikrs =>
      defaultDhikrs.where((d) => d.section == DhikrSection.tasbeeh).toList();

  /// باقة الأذكار والصيغ المعتمدة (49 صيغة موثقة: 20 استغفار و 29 تسبيح).
  /// يمكن للمطور إضافة أو تعديل الأذكار في ملف: [curatedDhikrs]
  static const List<TasbeehDhikr> defaultDhikrs = curatedDhikrs;
}
