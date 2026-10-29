/// أدوات تطبيع النصوص العربية وتنسيق الأرقام لمحرك البحث في تطبيق تدبر.
///
/// ملاحظة معمارية هامة:
/// نصوص المصحف الشريف العثمانية الأصلية لا تُمس نهائياً وتبقى محفوظة بنسبة ١٠٠٪ للعرض والقراءة.
/// عمليات التطبيع هنا تُطبق حصرياً وفقط أثناء مطابقة البحث لتسهيل العثور على الآيات بمختلف طرق الكتابة.
class ArabicSearchNormalizer {
  ArabicSearchNormalizer._();

  // علامات التشكيل وحركات الوقف والرموز المصحفية في اليونيكود
  static final RegExp _diacriticsRegex = RegExp(
    r'[\u0610-\u061A\u064B-\u065F\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]',
  );

  static final RegExp _tatweelRegex = RegExp(r'\u0640');

  /// يطبع النص العربي للبحث المرن دون المساس بالنص الأصلي.
  static String normalize(String text) {
    if (text.isEmpty) return text;

    var result = text;

    // ١. معالجة الألف الخنجرية (\u0670) في الرسم العثماني ومطابقتها مع الرسم الإملائي القياسي:
    // تحويل الواو الملحقة بألف خنجرية (مثل: صلوٰة، حيوٰة، زكوٰة، ربوٰا، مشكوٰة) إلى ألف قائمة
    result = result.replaceAll('و\u0670', 'ا');

    // الألف المقصورة المتبوعة بألف خنجرية:
    // إذا كانت وسطية متصلة بضمير (مثل: هَدَىٰكُمْ، سَوَّىٰهُ)، تُحول لألف قائمة (هداكم، سواه)
    result = result.replaceAll(RegExp(r'ى\u0670(?=[\u0621-\u064A])'), 'ا');
    // إذا كانت في نهاية الكلمة (مثل: عَلَىٰ، إِلَىٰ، حَتَّىٰ، مُوسَىٰ)، تُبقى ألفاً مقصورة لتطبيعها لاحقاً
    result = result.replaceAll('ى\u0670', 'ى');

    // تحويل سائر الألفات الخنجرية المنفردة (مثل: كِتَٰب، ٱلصَّٰبِرِين، ٱلظَّٰلِمِين) إلى ألف قائمة
    result = result.replaceAll('\u0670', 'ا');

    // ٢. إزالة التشكيل وحركات الوقف والرموز المصحفية
    result = result.replaceAll(_diacriticsRegex, '');

    // ٣. إزالة التطويل (الكشيدة)
    result = result.replaceAll(_tatweelRegex, '');

    // ٤. توحيد مختلف صور الهمزة والألف (أ، إ، آ، ٱ، ءا) إلى ألف مجردة (ا)
    result = result.replaceAll('ءا', 'ا');
    result = result.replaceAll(RegExp(r'[أإآٱ]'), 'ا');

    // ٥. توحيد التاء المربوطة (ة) مع الهاء (ه)
    result = result.replaceAll('ة', 'ه');

    // ٦. توحيد الألف المقصورة (ى) مع الياء (ي)
    result = result.replaceAll('ى', 'ي');

    // ٧. توحيد الهمزة على الواو والياء (ؤ، ئ)
    result = result.replaceAll('ؤ', 'و');
    result = result.replaceAll('ئ', 'ي');

    // ٨. دمج تكرار الألف المتتالية (مثل ناتج ربوا -> رباا -> ربا)
    result = result.replaceAll(RegExp(r'ا+'), 'ا');

    // ٩. تسوية الفروق الإملائية والنطق الصوتي الشائع مع الرسم القياسي:
    // تسوية لفظ الرحمن (الرحمن / الرحمان)
    result = result.replaceAll('الرحمان', 'الرحمن');
    result = result.replaceAll('رحمان', 'رحمن');

    // تسوية أسماء الإشارة (هذا / هاذا، ذلك / ذالك، ...)
    result = result.replaceAll('هاذا', 'هذا');
    result = result.replaceAll('هاذه', 'هذه');
    result = result.replaceAll('هاولاء', 'هولاء');
    result = result.replaceAll('هاذان', 'هذان');
    result = result.replaceAll('هاذين', 'هذين');
    result = result.replaceAll('هاكذا', 'هكذا');
    result = result.replaceAll('ذالك', 'ذلك');

    // تسوية لكن (لكن / لاكن)
    result = result.replaceAll('لاكن', 'لكن');

    // تسوية فواتح السور الشائعة نطقا
    result = result.replaceAll('طاها', 'طه');

    // تسوية اسم النبي داود (داود / داوود)
    result = result.replaceAll('داوود', 'داود');

    // تسوية لفظ إله ومشتقاته (إلاه -> اله، الاه -> اله) مع حماية الكلمات التي تبدأ بـ الأهل أو الأهرام
    result = result.replaceAllMapped(
      RegExp(r'(^|\s|[وفبك])الاه($|\s|[انكهي])'),
      (m) => '${m[1]}اله${m[2]}',
    );

    // مطابقة احتياطية لرسوم الواو في العثماني (صلوه -> صلاه، زكوه -> زكاه، حيوة -> حياة)
    result = result.replaceAll('صلوه', 'صلاه');
    result = result.replaceAll('زكوه', 'زكاه');
    result = result.replaceAll('حيوه', 'حياه');
    result = result.replaceAll('ربوا', 'ربا');

    // تسوية الأسماء والمصطلحات القرآنية بين الرسم العثماني المقتضب والرسم الحديث التام
    result = result.replaceAll('ابرهيم', 'ابراهيم');
    result = result.replaceAll('ابراهم', 'ابراهيم');
    result = result.replaceAll('اسمعيل', 'اسماعيل');
    result = result.replaceAll('اسحق', 'اسحاق');
    result = result.replaceAll('هرون', 'هارون');
    result = result.replaceAll('سليمن', 'سليمان');
    result = result.replaceAll('السموات', 'السماوات');
    result = result.replaceAll('سموات', 'سماوات');
    result = result.replaceAll('العلمين', 'العالمين');
    result = result.replaceAll('علمين', 'عالمين');

    // ١٠. ضبط وإزالة المسافات الزائدة
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

  /// يحول الأرقام العربية-المشرقية (٠-٩) والفارسية (۰-۹) إلى أرقام لاتينية (0-9).
  /// يُستخدم لضمان قبول مدخلات الأرقام في البحث والانتقال للصفحات من مختلف لوحات المفاتيح.
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
