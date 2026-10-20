/// Arabic text normalizer and numeral formatting utilities for Tadbeer.
///
/// EDUCATIONAL NOTE:
/// IMPORTANT:
/// Quran text itself must NEVER be normalized or modified for display.
/// Normalization is ONLY used for search matching.
///
/// Arabic orthography often contains stylistic variations (such as Alef with hamza
/// above/below/wasla: أ, إ, آ, ٱ, or Taa Marbuta: ة vs Haa: ه).
/// Removing diacritics and collapsing orthographic variants in query matching
/// enables an intuitive, fast search experience while preserving 100% of the
/// verified Uthmani script in the Quran reader.
class ArabicSearchNormalizer {
  ArabicSearchNormalizer._();

  // Arabic Tashkeel (diacritics) and Quranic annotation Unicode characters
  static final RegExp _diacriticsRegex = RegExp(
    r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]',
  );

  static final RegExp _tatweelRegex = RegExp(r'\u0640');

  /// Normalizes Arabic text for flexible search without modifying original text.
  static String normalize(String text) {
    if (text.isEmpty) return text;

    var result = text;

    // 1. Remove diacritics and Quranic pause/sajdah/stop marks
    result = result.replaceAll(_diacriticsRegex, '');

    // 2. Remove Tatweel (Kashida)
    result = result.replaceAll(_tatweelRegex, '');

    // 3. Normalize all Alef forms (أ, إ, آ, ٱ, and Uthmani isolated hamza before Alef ءا) to bare Alef (ا)
    result = result.replaceAll('ءا', 'ا');
    result = result.replaceAll(RegExp(r'[أإآٱ]'), 'ا');

    // 4. Normalize Taa Marbuta (ة) to Haa (ه)
    result = result.replaceAll('ة', 'ه');

    // 5. Normalize Alef Maqsura (ى) to Yaa (ي)
    result = result.replaceAll('ى', 'ي');

    // 6. Normalize Hamza on Waw / Yaa
    result = result.replaceAll('ؤ', 'و');
    result = result.replaceAll('ئ', 'ي');

    // 7. Normalize canonical Quranic Uthmani / Modern orthography variations for search:
    // Waw-Alif mappings in Uthmani (e.g. صلوة -> صلاة, زكوة -> زكاة, حيوة -> حياة)
    result = result.replaceAll('صلوه', 'صلاه');
    result = result.replaceAll('زكوه', 'زكاه');
    result = result.replaceAll('حيوه', 'حياه');
    result = result.replaceAll('ربوا', 'ربا');

    // Canonical names and terms where Uthmani uses dagger alif and modern Arabic uses full alif:
    result = result.replaceAll('ابراهيم', 'ابرهيم');
    result = result.replaceAll('اسماعيل', 'اسمعيل');
    result = result.replaceAll('اسحاق', 'اسحق');
    result = result.replaceAll('هارون', 'هرون');
    result = result.replaceAll('سليمان', 'سليمن');
    result = result.replaceAll('السماوات', 'السموات');
    result = result.replaceAll('سماوات', 'سموات');
    result = result.replaceAll('العالمين', 'العلمين');
    result = result.replaceAll('عالمين', 'علمين');

    // 8. Trim and collapse whitespace
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();

    return result;
  }

  /// Converts any ASCII digits in a string into Arabic-Indic digits (e.g. "5–7" -> "٥–٧").
  static String convertDigits(String input) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final code = input.codeUnitAt(i);
      if (code >= 48 && code <= 57) {
        buffer.write(arabicDigits[code - 48]);
      } else {
        buffer.write(input[i]);
      }
    }
    return buffer.toString();
  }

  /// Converts an integer to Arabic-Indic digits with optional minimum digits padding
  /// (e.g. 5 with minDigits: 2 -> "٠٥").
  static String formatDigits(int number, {int minDigits = 1}) {
    final s = number.toString().padLeft(minDigits, '0');
    return convertDigits(s);
  }

  /// Converts an integer to Arabic-Indic digits (e.g. 1 -> ١).
  static String toArabicDigits(int number) => formatDigits(number);

  /// يحول الأرقام العربية-المشرقية (٠-٩) والأرقام الفارسية (۰-۹) إلى أرقام لاتينية قياسية (0-9).
  ///
  /// 🎓 [ملاحظة تعليمية - تجربة المستخدم للمدخلات الرقمية العربية]:
  /// في لوحات المفاتيح العربية، تُدخل الأرقام كرموز يونيكود خاصة (مثل `\u0660` حتى `\u0669` أو الفارسية `\u06F0` حتى `\u06FF`).
  /// دوال التحويل القياسية في لغات البرمجة مثل `int.tryParse()` تفشل فوراً وتعيد `null` مع هذه المحارف لأنها تتوقع أرقام ASCII فقط (0-9).
  /// هذه الدالة تضمن تجربة مستخدم خالية من العوائق عند إدخال أرقام الصفحات أو أرقام الآيات من أي لوحة مفاتيح.
  static String toEnglishDigits(String input) {
    if (input.isEmpty) return input;
    var result = input;
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(arabicDigits[i], '$i');
      result = result.replaceAll(persianDigits[i], '$i');
    }
    return result;
  }
}

