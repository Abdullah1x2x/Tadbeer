/// نموذج يمثل دعاءً مأثوراً عن أهل البيت (عليهم السلام).
class AhlulbaytDua {
  /// المعرف الفريد للدعاء.
  final String id;

  /// عنوان الدعاء (مثلاً: دعاء كميل، دعاء مكارم الأخلاق).
  final String title;

  /// المنسوب إليه (مثلاً: أمير المؤمنين علي بن أبي طالب، الإمام زين العابدين).
  final String attributedTo;

  /// تصنيف الدعاء (مثلاً: الصحيفة السجادية، ليلة الجمعة، قضاء الحوائج، أدعية جامعة).
  final String category;

  /// نبذة عن الدعاء وفضله ومناسبته.
  final String summary;

  /// النص الشريف الكامل للدعاء مقسماً إلى فقرات لسهولة القراءة والتدبر.
  final List<String> paragraphs;

  /// النص الكامل مجمعاً.
  String get fullText => paragraphs.join('\n\n');

  const AhlulbaytDua({
    required this.id,
    required this.title,
    required this.attributedTo,
    required this.category,
    required this.summary,
    required this.paragraphs,
  });
}
