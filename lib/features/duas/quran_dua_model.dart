import 'package:flutter/foundation.dart';

import '../../core/utils/arabic_search_normalizer.dart';

/// يمثل مقطع آية قرآنية فردية ضمن دعاء قرآني.
///
/// Represents an individual verse segment within a Quranic supplication.
@immutable
class QuranDuaVerse {
  /// رقم الآية داخل السورة.
  ///
  /// Authentic Ayah number within the Surah (1-based).
  final int ayahNumber;

  /// النص الكامل للآية بالتشكيل التام.
  ///
  /// Full text of this verse with complete diacritics.
  final String text;

  /// ينشئ كائن آية ضمن دعاء قرآني.
  const QuranDuaVerse({required this.ayahNumber, required this.text});
}

/// نموذج غير قابل للتغيير يمثل دعاءً قرآنياً موثقاً مع بيانات السورة والتصنيف.
///
/// Immutable Model representing an authentic Quranic supplication (دعاء من القرآن).
///
/// EDUCATIONAL NOTE:
/// Quranic Text & Data Integrity:
/// 1. Verbatim Sourcing: [duaText] strictly holds the verbatim text with complete
///    diacritics as provided in the canonical catalog.
/// 2. Immutability: All fields are final and strictly read-only.
/// 3. Clear Categorization: Distinguishes direct prayers from Isti'adha, Dhikr,
///    and contextual verses, and preserves all authentic alerts and classifications.
/// 4. Multi-Ayah Precision: Preserves individual [verses] with authentic ayah numbers
///    and provides [formattedTextWithMarkers] for clear verse-by-verse presentation.
@immutable
class QuranDua {
  /// المعرّف التسلسلي الفريد للدعاء.
  ///
  /// Unique sequential identifier (1-based, 1 to 88).
  final int id;

  /// رقم السورة في المصحف الشريف.
  ///
  /// Canonical Quran Surah number in the Holy Quran (1-114).
  final int surahNumber;

  /// اسم السورة باللغة العربية.
  ///
  /// Arabic Surah name (e.g. "الفاتحة", "البقرة").
  final String surahName;

  /// رقم الآية الأساسية أو آية البداية للدعاء.
  ///
  /// Primary or starting Ayah number within the Surah.
  final int ayahNumber;

  /// رقم آية النهاية في حال امتداد الدعاء لأكثر من آية.
  ///
  /// Ending Ayah number (for verse ranges, e.g. 7 for 5–7; equal to ayahNumber for single verses).
  final int ayahEndNumber;

  /// النص المعروض لرقم الآية أو نطاق الآيات.
  ///
  /// Display string for the Ayah number or range (e.g. "5–7", "126", "85–86").
  final String ayahDisplay;

  /// المفتاح المرجعي الثابت للآية أو نطاق الآيات.
  ///
  /// Stable Ayah reference key in format '$surahNumber:$ayahDisplay' (e.g. "1:5-7", "2:126").
  final String ayahKey;

  /// عنوان الدعاء أو محوره الموضوعي.
  ///
  /// Title or theme of the supplication (e.g. "الهداية والاستعانة", "طلب الأمن والرزق").
  final String title;

  /// النص القرآني الموثق للدعاء بالتشكيل الكامل.
  ///
  /// Verbatim authentic Quranic text with complete diacritics.
  final String duaText;

  /// رقم صفحة مصحف المدينة للانتقال المباشر.
  ///
  /// Medina Mushaf page number (1-604) for instant reading navigation.
  final int page;

  /// النص المطبّع مسبقاً بدون تشكيل لأغراض البحث السريع.
  ///
  /// Pre-normalized search text (without diacritics).
  final String rawText;

  /// التصنيف الموضوعي الأساسي للدعاء.
  ///
  /// Primary theme category from the defined categories.
  final String category;

  /// تنبيه أو ملاحظة سياقية اختيارية مرفقة بالدعاء.
  ///
  /// Optional contextual note or alert (e.g. for Al-Anfal 32, Al-Ra'd 16, etc.).
  final String? alert;

  /// يحدد ما إذا كان المدخل دعاءً مباشراً أم ذكراً واستعاذة.
  ///
  /// True if this entry is a direct supplication; false if Isti'adha, Dhikr, or contextual verse.
  final bool isDirectDua;

  /// الترتيب التسلسلي للدعاء داخل السورة الحالية.
  ///
  /// Sequential order within the current Surah.
  final int orderInSurah;

  /// قائمة الآيات الفردية المكونة لهذا الدعاء.
  ///
  /// List of individual verses making up this supplication.
  final List<QuranDuaVerse> verses;

  /// ينشئ كائن دعاء قرآني موثق.
  QuranDua({
    required this.id,
    required this.surahNumber,
    required this.surahName,
    required this.ayahNumber,
    int? ayahEndNumber,
    String? ayahDisplay,
    required this.ayahKey,
    this.title = '',
    required this.duaText,
    required this.page,
    required this.rawText,
    this.category = 'عام',
    this.alert,
    this.isDirectDua = true,
    this.orderInSurah = 1,
    List<QuranDuaVerse>? verses,
  }) : ayahEndNumber = ayahEndNumber ?? ayahNumber,
       ayahDisplay = ayahDisplay ?? '$ayahNumber',
       verses =
           verses ?? [QuranDuaVerse(ayahNumber: ayahNumber, text: duaText)];

  /// يعيد صحيحاً إذا كان الدعاء يمتد عبر أكثر من آية واحدة.
  ///
  /// True if this supplication spans more than one Ayah.
  bool get isMultiAyah => verses.length > 1;

  /// يعيد النص القرآني منسقاً مع فواصل أرقام الآيات للعرض أو النسخ.
  ///
  /// Formatted text with authentic Ayah end rosettes for display or copying.
  /// Single Ayah: returns verbatim [duaText].
  /// Multi Ayah: returns verses with ' ﴿رقم_الآية﴾' after each verse.
  String get formattedTextWithMarkers {
    if (!isMultiAyah) return duaText;
    return verses
        .map(
          (v) =>
              '${v.text} ﴿${ArabicSearchNormalizer.toArabicDigits(v.ayahNumber)}﴾',
        )
        .join(' ');
  }

  /// اسم بديل يعيد نص الدعاء القرآني للتوافق.
  ///
  /// Alias for backwards compatibility.
  String get text => duaText;
}
