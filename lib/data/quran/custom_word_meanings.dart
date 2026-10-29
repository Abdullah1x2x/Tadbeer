import 'quran_models.dart';

// معاني كلمات يضيفها المطور أو يصحّحها، دون تعديل ملف JSON.
// أضف عنصراً إلى [customWordMeanings]، فيُربط بصفحته ويُفهرس في البحث والمصحف
// تلقائياً. مثال:
//
//   CustomWordMeaningConfig(
//     surah: 1,
//     ayah: 2,
//     word: 'الْحَمْدُ',
//     meaning: 'الثناء بالجميل على جهة التبجيل والتعظيم لله وحده.',
//     sourceName: 'السراج في بيان غريب القرآن',
//   ),

/// معنى كلمة يضيفه المطور.
class CustomWordMeaningConfig {
  final int surah;

  final int ayah;

  /// الكلمة كما وردت في الآية.
  final String word;

  /// المعنى الميسّر.
  final String meaning;

  /// المعنى الأصلي أو المرجع التفصيلي.
  final String? originalMeaning;

  /// اسم المعجم؛ الافتراضي "المعجم الوسيط".
  final String? sourceName;

  /// رابط المصدر.
  final String? sourceUrl;

  /// أقوال المفسرين أو ملاحظات.
  final String? notes;

  const CustomWordMeaningConfig({
    required this.surah,
    required this.ayah,
    required this.word,
    required this.meaning,
    this.originalMeaning,
    this.sourceName,
    this.sourceUrl,
    this.notes,
  });

  /// [QuranWordMeaning] مربوطاً بالصفحة [pageNumber].
  QuranWordMeaning toQuranWordMeaning(int pageNumber) {
    return QuranWordMeaning(
      surah: surah,
      ayah: ayah,
      word: word,
      meaning: meaning,
      originalMeaning: originalMeaning ?? meaning,
      sourceId: 999, // معرّف الإضافات البرمجية المخصصة
      sourceName: sourceName ?? 'المعجم الوسيط، مجمع اللغة العربية بالقاهرة',
      sourceUrl: sourceUrl,
      page: pageNumber,
      status: 'approved',
      notes: notes,
    );
  }
}

/// المعاني المضافة أو المصحّحة، تُدمج في المصحف وشاشة معاني الكلمات.
final List<CustomWordMeaningConfig> customWordMeanings = [
  // أضف المعاني هنا.
];
