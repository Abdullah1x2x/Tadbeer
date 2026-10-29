/// تطبيع النص العربي للبحث فقط: النص العثماني نفسه لا يُمس، والتطبيع يُطبّق عند
/// المطابقة ليجد البحث الآية بأي طريقة كتابة.
class ArabicSearchNormalizer {
  ArabicSearchNormalizer._();

  // علامات التشكيل والوقف والرموز المصحفية في يونيكود.
  static final RegExp _diacriticsRegex = RegExp(
    r'[\u0610-\u061A\u064B-\u065F\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]',
  );

  static final RegExp _tatweelRegex = RegExp(r'\u0640');

  /// نسخة موحّدة من [text] للمطابقة، لا للعرض.
  static String normalize(String text) {
    if (text.isEmpty) return text;

    var result = text;

    // ١. الألف الخنجرية: الواو التي تحملها (صلوٰة، زكوٰة) تصير ألفاً قائمة
    // كالرسم الإملائي.
    result = result.replaceAll('و\u0670', 'ا');

    // الألف المقصورة قبل خنجرية في وسط الكلمة (هَدَىٰكُمْ) تصير ألفاً قائمة.
    result = result.replaceAll(RegExp(r'ى\u0670(?=[\u0621-\u064A])'), 'ا');
    // وفي آخر الكلمة (عَلَىٰ، مُوسَىٰ) تبقى مقصورة وتُطبّع لاحقاً.
    result = result.replaceAll('ى\u0670', 'ى');

    // باقي الخنجريات المنفردة (كِتَٰب، ٱلصَّٰبِرِين) تصير ألفاً قائمة.
    result = result.replaceAll('\u0670', 'ا');

    // ٢. إزالة التشكيل والوقف والرموز المصحفية.
    result = result.replaceAll(_diacriticsRegex, '');

    // ٣. إزالة التطويل.
    result = result.replaceAll(_tatweelRegex, '');

    // ٤. صور الهمزة والألف (أ، إ، آ، ٱ، ءا) تصير ألفاً.
    result = result.replaceAll('ءا', 'ا');
    result = result.replaceAll(RegExp(r'[أإآٱ]'), 'ا');

    // ٥. التاء المربوطة تصير هاءً.
    result = result.replaceAll('ة', 'ه');

    // ٦. الألف المقصورة تصير ياءً.
    result = result.replaceAll('ى', 'ي');

    // ٧. الهمزة على الواو والياء.
    result = result.replaceAll('ؤ', 'و');
    result = result.replaceAll('ئ', 'ي');

    // ٨. دمج الألفات المتتالية (ربوا ← رباا ← ربا).
    result = result.replaceAll(RegExp(r'ا+'), 'ا');

    // ٩. فروق إملائية شائعة مع الرسم القياسي: الرحمن / الرحمان.
    result = result.replaceAll('الرحمان', 'الرحمن');
    result = result.replaceAll('رحمان', 'رحمن');

    // أسماء الإشارة (هاذا ← هذا، ذالك ← ذلك).
    result = result.replaceAll('هاذا', 'هذا');
    result = result.replaceAll('هاذه', 'هذه');
    result = result.replaceAll('هاولاء', 'هولاء');
    result = result.replaceAll('هاذان', 'هذان');
    result = result.replaceAll('هاذين', 'هذين');
    result = result.replaceAll('هاكذا', 'هكذا');
    result = result.replaceAll('ذالك', 'ذلك');

    // لاكن ← لكن.
    result = result.replaceAll('لاكن', 'لكن');

    // فواتح السور كما تُنطق.
    result = result.replaceAll('طاها', 'طه');

    // داوود ← داود.
    result = result.replaceAll('داوود', 'داود');

    // إلاه ← اله، دون المساس بكلمات تبدأ بـ "الأهل" أو "الأهرام".
    result = result.replaceAllMapped(
      RegExp(r'(^|\s|[وفبك])الاه($|\s|[انكهي])'),
      (m) => '${m[1]}اله${m[2]}',
    );

    // رسوم الواو العثمانية (صلوه ← صلاه، حيوة ← حياة).
    result = result.replaceAll('صلوه', 'صلاه');
    result = result.replaceAll('زكوه', 'زكاه');
    result = result.replaceAll('حيوه', 'حياه');
    result = result.replaceAll('ربوا', 'ربا');

    // أسماء ومصطلحات بين الرسم العثماني المختصر والرسم الحديث.
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

    // ١٠. المسافات الزائدة.
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();

    return result;
  }

  /// يحوّل الأرقام اللاتينية في [input] إلى أرقام عربية هندية ("5–7" ← "٥–٧").
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

  /// [number] بالأرقام العربية الهندية، مع أصفار بادئة حتى [minDigits] (5 ←
  /// "٠٥").
  static String formatDigits(int number, {int minDigits = 1}) {
    final s = number.toString().padLeft(minDigits, '0');
    return convertDigits(s);
  }

  /// [number] بالأرقام العربية الهندية (1 ← ١).
  static String toArabicDigits(int number) => formatDigits(number);

  /// يحوّل الأرقام العربية الهندية والفارسية إلى لاتينية، ليُقبل الإدخال من أي
  /// لوحة مفاتيح.
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
