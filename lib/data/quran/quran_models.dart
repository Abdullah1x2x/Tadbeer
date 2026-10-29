/// يمثل بيانات سورة من سور القرآن الكريم (١١٤ سورة).
class Surah {
  final int number;
  final String name;
  final String transliteration;
  final String translation;
  final String type;
  final int ayahCount;
  final int order;
  final int rukus;
  final int pageStart;
  final int pageEnd;

  /// ينشئ كائناً يمثل بيانات السورة القرآنية.
  const Surah({
    required this.number,
    required this.name,
    required this.transliteration,
    required this.translation,
    required this.type,
    required this.ayahCount,
    required this.order,
    required this.rukus,
    required this.pageStart,
    required this.pageEnd,
  });

  /// يحدد ما إذا كانت السورة مكية.
  bool get isMeccan => type == 'Meccan';

  /// ينشئ كائن سورة من خريطة بيانات JSON.
  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'] as int,
      name: json['name'] as String,
      transliteration: json['transliteration'] as String,
      translation: json['translation'] as String,
      type: json['type'] as String,
      ayahCount: json['ayahCount'] as int,
      order: json['order'] as int,
      rukus: json['rukus'] as int,
      pageStart: json['pageStart'] as int,
      pageEnd: json['pageEnd'] as int,
    );
  }

  /// يحول بيانات السورة إلى خريطة JSON.
  Map<String, dynamic> toJson() => {
    'number': number,
    'name': name,
    'transliteration': transliteration,
    'translation': translation,
    'type': type,
    'ayahCount': ayahCount,
    'order': order,
    'rukus': rukus,
    'pageStart': pageStart,
    'pageEnd': pageEnd,
  };
}

/// يمثل آية قرآنية بالرسم العثماني مع بيانات موقعها في المصحف الشريف.
class Ayah {
  final int id;
  final int surahNumber;
  final int ayahNumber;
  final String text;
  final String rawText;
  final int page;
  final int juz;
  final int hizb;
  final int quarter;
  final bool isSajdah;
  final String? sajdaType;

  /// ينشئ كائناً يمثل الآية القرآنية ومعلوماتها الوصفية.
  const Ayah({
    required this.id,
    required this.surahNumber,
    required this.ayahNumber,
    required this.text,
    required this.rawText,
    required this.page,
    required this.juz,
    required this.hizb,
    required this.quarter,
    this.isSajdah = false,
    this.sajdaType,
  });

  /// المفتاح الفريد للآية بصيغة (رقم السورة:رقم الآية).
  String get key => '$surahNumber:$ayahNumber';

  /// ينشئ كائن آية من خريطة بيانات JSON.
  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      id: json['id'] as int,
      surahNumber: json['surahNumber'] as int,
      ayahNumber: json['ayahNumber'] as int,
      text: json['text'] as String,
      rawText: json['rawText'] as String? ?? json['text'] as String,
      page: json['page'] as int,
      juz: json['juz'] as int,
      hizb: json['hizb'] as int,
      quarter: json['quarter'] as int,
      isSajdah: json['isSajdah'] as bool? ?? false,
      sajdaType: json['sajdaType'] as String?,
    );
  }

  /// يحول بيانات الآية إلى خريطة JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
    'text': text,
    'rawText': rawText,
    'page': page,
    'juz': juz,
    'hizb': hizb,
    'quarter': quarter,
    'isSajdah': isSajdah,
    if (sajdaType != null) 'sajdaType': sajdaType,
  };
}

/// يمثل صفحة واحدة من صفحات المصحف المدني (١ إلى ٦٠٤) وما تحتويه من آيات.
class QuranPage {
  final int pageNumber;
  final int juzNumber;
  final int hizbNumber;
  final List<int> surahNumbers;
  final List<Ayah> ayahs;

  /// ينشئ كائناً يمثل صفحة من المصحف الشريف.
  const QuranPage({
    required this.pageNumber,
    required this.juzNumber,
    required this.hizbNumber,
    required this.surahNumbers,
    required this.ayahs,
  });

  /// ينشئ كائن صفحة مصحف من خريطة بيانات JSON.
  factory QuranPage.fromJson(Map<String, dynamic> json) {
    return QuranPage(
      pageNumber: json['pageNumber'] as int,
      juzNumber: json['juzNumber'] as int,
      hizbNumber: json['hizbNumber'] as int,
      surahNumbers: (json['surahNumbers'] as List).cast<int>(),
      ayahs: (json['ayahs'] as List)
          .map((a) => Ayah.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// موضع القراءة الحالي للمستخدم في المصحف الشريف.
///
/// ملاحظة:
/// يتم تحديث هذا النموذج تلقائياً عند تقليب الصفحات في شاشة المصحف،
/// ويُحفظ محلياً في SQLite لاسترجاع آخر موضع وصل إليه القارئ عند إعادة فتح التطبيق.
class ReadingPosition {
  final int page;
  final int surahNumber;
  final int ayahNumber;
  final DateTime updatedAt;

  /// ينشئ كائناً يمثل موضع القراءة الحالي.
  const ReadingPosition({
    required this.page,
    required this.surahNumber,
    required this.ayahNumber,
    required this.updatedAt,
  });

  /// الموضع الافتراضي عند فتح التطبيق لأول مرة: الفاتحة (صفحة 1، آية 1).
  static ReadingPosition defaultPosition() => ReadingPosition(
    page: 1,
    surahNumber: 1,
    ayahNumber: 1,
    updatedAt: DateTime.now(),
  );

  /// يحول موضع القراءة إلى خريطة JSON للتخزين المحلي.
  Map<String, dynamic> toJson() => {
    'page': page,
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// ينشئ كائن موضع قراءة من خريطة بيانات JSON.
  factory ReadingPosition.fromJson(Map<String, dynamic> json) {
    return ReadingPosition(
      page: json['page'] as int? ?? 1,
      surahNumber: json['surahNumber'] as int? ?? 1,
      ayahNumber: json['ayahNumber'] as int? ?? 1,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}

/// نموذج معنى الكلمة القرآنية الغريبة المعتمدة في تَدْبِير.
class QuranWordMeaning {
  final int surah;
  final int ayah;
  final String word;
  final String meaning;
  final String originalMeaning;
  final int sourceId;
  final String sourceName;
  final String? sourceUrl;
  final int page;
  final String status;
  final bool isMultipleOpinions;
  final String? notes;

  /// ينشئ كائناً يمثل معنى كلمة قرآنية ومصدرها المعجمي.
  const QuranWordMeaning({
    required this.surah,
    required this.ayah,
    required this.word,
    required this.meaning,
    String? originalMeaning,
    required this.sourceId,
    this.sourceName = 'المعجم الوسيط، مجمع اللغة العربية بالقاهرة',
    this.sourceUrl,
    required this.page,
    this.status = 'approved',
    this.isMultipleOpinions = false,
    this.notes,
  }) : originalMeaning = originalMeaning ?? meaning;

  /// مفتاح الآية المرتبطة بالكلمة بصيغة (رقم السورة:رقم الآية).
  String get ayahKey => '$surah:$ayah';

  /// ينشئ كائن معنى كلمة قرآنية من خريطة بيانات JSON.
  factory QuranWordMeaning.fromJson(Map<String, dynamic> json, {int page = 1}) {
    final meaningText = json['meaning'] as String? ?? '';
    final origText =
        json['original_meaning'] as String? ??
        json['originalMeaning'] as String? ??
        meaningText;
    final srcName =
        json['source_name'] as String? ??
        json['sourceName'] as String? ??
        'المعجم الوسيط، مجمع اللغة العربية بالقاهرة';
    final srcUrl =
        json['source_url'] as String? ??
        json['sourceUrl'] as String? ??
        'https://www.arabicacademy.gov.eg/ar/';
    final multiOpinions =
        json['is_multiple_opinions'] as bool? ??
        json['isMultipleOpinions'] as bool? ??
        false;

    return QuranWordMeaning(
      surah: (json['surah'] ?? json['surah_number']) as int? ?? 1,
      ayah: (json['ayah'] ?? json['ayah_number']) as int? ?? 1,
      word: json['word'] as String? ?? '',
      meaning: meaningText,
      originalMeaning: origText,
      sourceId: json['source_id'] as int? ?? json['sourceId'] as int? ?? 1,
      sourceName: srcName,
      sourceUrl: srcUrl,
      page: json['page'] as int? ?? page,
      status: json['status'] as String? ?? 'approved',
      isMultipleOpinions: multiOpinions,
      notes: json['notes'] as String?,
    );
  }

  /// يحول بيانات معنى الكلمة القرآنية إلى خريطة JSON.
  Map<String, dynamic> toJson() => {
    'surah': surah,
    'ayah': ayah,
    'word': word,
    'meaning': meaning,
    'original_meaning': originalMeaning,
    'source_id': sourceId,
    'source_name': sourceName,
    if (sourceUrl != null) 'source_url': sourceUrl,
    'page': page,
    'status': status,
    'is_multiple_opinions': isMultipleOpinions,
    if (notes != null) 'notes': notes,
  };
}
