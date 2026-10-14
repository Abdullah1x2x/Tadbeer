/// تصنيف الذكر (صباح أو مساء).
enum AdhkarCategory {
  /// أذكار الصباح المشروعة.
  morning,

  /// أذكار المساء المشروعة.
  evening,
}

/// نموذج يمثل الذكر الشريف مع تكراره وفضيلته.
class AdhkarItem {
  /// المعرف الفريد للذكر.
  final String id;

  /// القسم (صباح أو مساء).
  final AdhkarCategory category;

  /// نص الذكر المبارك بالرسم المشكول.
  final String text;

  /// عدد مرات التكرار المأثورة.
  final int repeatCount;

  /// فضيلة الذكر أو أثره المأثور.
  final String virtue;

  /// مصدر الذكر أو تخريجه.
  final String source;

  const AdhkarItem({
    required this.id,
    required this.category,
    required this.text,
    required this.repeatCount,
    required this.virtue,
    required this.source,
  });

  /// هل الذكر من أذكار الصباح؟
  bool get isMorning => category == AdhkarCategory.morning;

  /// هل الذكر من أذكار المساء؟
  bool get isEvening => category == AdhkarCategory.evening;
}
