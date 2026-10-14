import '../../quran/data/quran_models.dart';

// =============================================================================
// 📖 سجل مفردات وتفسير غريب القرآن الكريم — المخصص للمطور
// =============================================================================
//
// 💡 كيف تضيف أو تُصحح معنى كلمة قرآنية غريبة؟
// -------------------------------------------------------------
// أضف عنصراً جديداً إلى قائمة [customWordMeanings] أدناه باستخدام [CustomWordMeaningConfig]:
// وسيقوم النظام تلقائياً بربطها برقم صفحة المصحف (من 1 إلى 604) وفهرستها في محرك البحث
// وشاشات المصحف وغريب القرآن بدون الحاجة لتعديل ملف JSON الضخم أو شاشات التطبيق.
//
// مثال:
// -----
// CustomWordMeaningConfig(
//   surah: 1, // رقم السورة (مثال: 1 للفاتحة)
//   ayah: 2,  // رقم الآية
//   word: 'الْحَمْدُ', // الكلمة القرآنية كما وردت في الآية
//   meaning: 'الثناء بالجميل على جهة التبجيل والتعظيم لله عز وجل وحده.', // الشرح والبيان
//   sourceName: 'السراج في بيان غريب القرآن', // المصدر المعجمي (اختياري)
// ),
// =============================================================================

/// تكوين مدخل معنى كلمة قرآنية يضيفه المطور في التطبيق.
class CustomWordMeaningConfig {
  /// رقم السورة (1 إلى 114).
  final int surah;

  /// رقم الآية داخل السورة.
  final int ayah;

  /// المفردة أو اللفظة القرآنية.
  final String word;

  /// معنى المفردة أو تفسيرها الميسر.
  final String meaning;

  /// المعنى الأصلي أو المرجع التفصيلي (اختياري).
  final String? originalMeaning;

  /// اسم المعجم أو المرجع (اختياري، الافتراضي: 'المعجم الوسيط، مجمع اللغة العربية بالقاهرة').
  final String? sourceName;

  /// رابط المعجم أو التوثيق (اختياري).
  final String? sourceUrl;

  /// ملاحظات أو أقوال أهل التفسير (اختياري).
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

  /// تحويل المدخل إلى نموذج QuranWordMeaning وربطه بصفحة المصحف تلقائياً.
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

/// قائمة معاني الكلمات والمفردات القرآنية المضافة أو المصححة برمجياً من قبل المطور.
/// تضاف المفردات هنا وسيقوم التطبيق بدمجها فوراً في المصحف وشاشة غريب القرآن.
final List<CustomWordMeaningConfig> customWordMeanings = [
  // يمكن للمطور إضافة أي مفردة قرآنية جديدة هنا مباشرة
];
