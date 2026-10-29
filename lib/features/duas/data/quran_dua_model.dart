import 'package:flutter/foundation.dart';

import '../../../core/utils/arabic_search_normalizer.dart';

/// آية من آيات دعاء قرآني.
@immutable
class QuranDuaVerse {
  /// رقم الآية في سورتها (من 1).
  final int ayahNumber;

  /// نص الآية مشكولاً.
  final String text;

  const QuranDuaVerse({required this.ayahNumber, required this.text});
}

/// دعاء من القرآن بنصه الموثق، مع سورته وتصنيفه؛ للقراءة فقط.
///
/// يميّز الدعاء المباشر من الاستعاذة والذكر والآيات السياقية، ويحفظ آيات الدعاء
/// متعدد الآيات بأرقامها.
@immutable
class QuranDua {
  /// رقم تسلسلي (1..88).
  final int id;

  /// رقم السورة (1..114).
  final int surahNumber;

  final String surahName;

  /// الآية الأولى للدعاء.
  final int ayahNumber;

  /// الآية الأخيرة، وتساوي [ayahNumber] للدعاء من آية واحدة.
  final int ayahEndNumber;

  /// رقم الآية أو نطاقها للعرض ("5–7"، "126").
  final String ayahDisplay;

  /// مفتاح ثابت بصيغة 'سورة:آيات' ("1:5-7"، "2:126").
  final String ayahKey;

  /// عنوان الدعاء أو محوره ("الهداية والاستعانة"…).
  final String title;

  /// النص القرآني الموثق مشكولاً.
  final String duaText;

  /// صفحة مصحف المدينة (1..604).
  final int page;

  /// النص مطبّعاً دون تشكيل، للبحث.
  final String rawText;

  /// المحور الموضوعي.
  final String category;

  /// تنبيه سياقي اختياري (كما في الأنفال 32، والرعد 16).
  final String? alert;

  /// دعاء مباشر، لا استعاذة أو ذكر أو آية سياقية.
  final bool isDirectDua;

  /// ترتيبه بين أدعية سورته.
  final int orderInSurah;

  /// آيات الدعاء.
  final List<QuranDuaVerse> verses;

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

  /// هل يمتد على أكثر من آية.
  bool get isMultiAyah => verses.length > 1;

  /// النص للعرض أو النسخ: النص كما هو لآية واحدة، أو كل آية متبوعة برقمها '
  /// ﴿رقم﴾'.
  String get formattedTextWithMarkers {
    if (!isMultiAyah) return duaText;
    return verses
        .map(
          (v) =>
              '${v.text} ﴿${ArabicSearchNormalizer.toArabicDigits(v.ayahNumber)}﴾',
        )
        .join(' ');
  }
}
