import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../core/utils/arabic_root_search_helper.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../../word_meanings/data/custom_word_meanings.dart';
import 'quran_models.dart';

/// Repository providing verified, authentic Uthmani Quran data for Tadbeer.
///
/// EDUCATIONAL NOTE:
/// Quran Data Architecture & Integrity:
/// 1. Data Source: Bundled Tanzil Uthmani text (`assets/quran/quran_data.json`).
///    - 114 Surahs (Surah names, revelation type, ayah counts, page ranges)
///    - 6,236 Ayahs (global stable 1-based sequential ID, surah number, ayah number, page, juz, hizb, quarter, sajdah)
///    - 604 standard Madani Mushaf pages
/// 2. Immutability: Quranic text is immutable and strictly read-only.
/// مستودع بيانات القرآن الكريم وتخطيط المصحف (المرجع الأساسي غير القابل للتعديل).
///
/// ملاحظة معمارية:
/// - هذا المستودع يُحمّل النص العثماني الموثق من مشروع تنزيل (Tanzil) موزّعاً على 604 صفحات.
/// - تم إنشاء كاش نصوص تم تطبيعها مسبقاً (`_normalizedAyahTexts`) للبحث السريع في أجزاء من الثانية.
/// - الكائنات المعادة محمية بقوائم غير قابلة للتعديل (Unmodifiable Lists) لصيانة قدسية النص القرآني.
class QuranRepository {
  /// النسخة المشتركة الوحيدة (Singleton) من مستودع بيانات القرآن الكريم.
  static final QuranRepository instance = QuranRepository._internal();

  /// منشئ داخلي خاص لتطبيق نمط النسخة الوحيدة.
  QuranRepository._internal();

  bool _isLoaded = false;

  /// يحدد ما إذا تم تحميل بيانات القرآن الكريم ومعاني الكلمات في الذاكرة.
  bool get isLoaded => _isLoaded;

  final List<Surah> _surahs = [];
  final List<QuranPage> _pages = [];
  final List<Ayah> _allAyahs = [];
  final Map<String, Ayah> _ayahsByKey = {};
  final List<String> _normalizedAyahTexts = [];
  final List<QuranWordMeaning> _wordMeanings = [];
  final Map<int, List<QuranWordMeaning>> _wordMeaningsByPage = {};
  final Map<int, List<QuranWordMeaning>> _wordMeaningsBySurah = {};
  final List<String> _normalizedWordOnly = [];
  final List<String> _normalizedMeaningOnly = [];

  /// قائمة سور القرآن الكريم (١١٤ سورة) غير قابلة للتعديل.
  List<Surah> get surahs => List.unmodifiable(_surahs);

  /// قائمة صفحات المصحف المدني (٦٠٤ صفحات) غير قابلة للتعديل.
  List<QuranPage> get pages => List.unmodifiable(_pages);

  /// قائمة جميع آيات القرآن الكريم (٦٢٣٦ آية) غير قابلة للتعديل.
  List<Ayah> get allAyahs => List.unmodifiable(_allAyahs);

  /// قائمة جميع معاني الكلمات القرآنية الغريبة المعتمدة غير قابلة للتعديل.
  List<QuranWordMeaning> get allWordMeanings => List.unmodifiable(_wordMeanings);

  /// يهيئ المستودع عبر تحميل بيانات القرآن الكريم ومعاني الكلمات وبناء فهارس البحث السريع.
  Future<void> init() async {
    if (_isLoaded) return;

    final jsonString = await rootBundle.loadString(
      'assets/quran/quran_data.json',
    );
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    final rawSurahs = (data['surahs'] as List).cast<Map<String, dynamic>>();
    _surahs.clear();
    for (final s in rawSurahs) {
      _surahs.add(Surah.fromJson(s));
    }

    final rawPages = (data['pages'] as List).cast<Map<String, dynamic>>();
    _pages.clear();
    _allAyahs.clear();
    _ayahsByKey.clear();
    _normalizedAyahTexts.clear();

    for (final p in rawPages) {
      final page = QuranPage.fromJson(p);
      _pages.add(page);
      for (final ayah in page.ayahs) {
        _allAyahs.add(ayah);
        _ayahsByKey[ayah.key] = ayah;
        _normalizedAyahTexts.add(ArabicSearchNormalizer.normalize(ayah.text));
      }
    }

    // Load authentic Quranic word meanings (السراج في بيان غريب القرآن)
    try {
      final meaningsString = await rootBundle.loadString(
        'assets/quran/word_meanings.json',
      );
      final rawMeanings = jsonDecode(meaningsString) as List<dynamic>;
      _wordMeanings.clear();
      _wordMeaningsByPage.clear();
      _wordMeaningsBySurah.clear();
      _normalizedWordOnly.clear();
      _normalizedMeaningOnly.clear();

      for (final item in rawMeanings) {
        final map = item as Map<String, dynamic>;
        final surahNum = (map['surah'] ?? map['surah_number']) as int? ?? 1;
        final ayahNum = (map['ayah'] ?? map['ayah_number']) as int? ?? 1;
        final ayah = _ayahsByKey['$surahNum:$ayahNum'];
        final pageNum = ayah?.page ?? 1;

        final wordMeaning = QuranWordMeaning.fromJson(map, page: pageNum);
        _wordMeanings.add(wordMeaning);
        _wordMeaningsByPage.putIfAbsent(pageNum, () => []).add(wordMeaning);
        _wordMeaningsBySurah.putIfAbsent(surahNum, () => []).add(wordMeaning);
        final normWord = ArabicSearchNormalizer.normalize(wordMeaning.word);
        final normMeaning = ArabicSearchNormalizer.normalize(wordMeaning.meaning);
        _normalizedWordOnly.add(normWord);
        _normalizedMeaningOnly.add(normMeaning);
      }
    } catch (_) {
      // Graceful fallback if asset loading is not mocked in isolated unit tests
    }

    // دمج مفردات غريب القرآن المضافة برمجياً من قبل المطور
    for (final customItem in customWordMeanings) {
      final ayah = _ayahsByKey['${customItem.surah}:${customItem.ayah}'];
      final pageNum = ayah?.page ?? 1;
      final wordMeaning = customItem.toQuranWordMeaning(pageNum);
      _wordMeanings.add(wordMeaning);
      _wordMeaningsByPage.putIfAbsent(pageNum, () => []).add(wordMeaning);
      _wordMeaningsBySurah.putIfAbsent(customItem.surah, () => []).add(wordMeaning);
      final normWord = ArabicSearchNormalizer.normalize(wordMeaning.word);
      final normMeaning = ArabicSearchNormalizer.normalize(wordMeaning.meaning);
      _normalizedWordOnly.add(normWord);
      _normalizedMeaningOnly.add(normMeaning);
    }

    _isLoaded = true;
  }

  /// يعيد بيانات صفحة المصحف الموافقة لرقم الصفحة (١ إلى ٦٠٤).
  QuranPage getPage(int pageNumber) {
    assert(_isLoaded, 'QuranRepository must be initialized before use');
    if (pageNumber < 1 || pageNumber > 604) {
      pageNumber = pageNumber.clamp(1, 604);
    }
    return _pages[pageNumber - 1];
  }

  /// يعيد بيانات السورة الموافقة لرقم السورة (١ إلى ١١٤).
  Surah getSurah(int surahNumber) {
    assert(_isLoaded, 'QuranRepository must be initialized before use');
    if (surahNumber < 1 || surahNumber > 114) {
      surahNumber = surahNumber.clamp(1, 114);
    }
    return _surahs[surahNumber - 1];
  }

  /// يعيد الآية المحددة برقم السورة ورقم الآية، أو قيمة فارغة إن لم توجد.
  Ayah? getAyah(int surahNumber, int ayahNumber) {
    assert(_isLoaded, 'QuranRepository must be initialized before use');
    return _ayahsByKey['$surahNumber:$ayahNumber'];
  }

  /// Instant offline Arabic search across all 6,236 ayahs using pre-normalized cache.
  /// Automatically detects root queries (e.g. `جذر:صبر` or `جذر صبر`) and executes morphological search.
  /// يبحث فورياً بدون إنترنت في جميع آيات القرآن الكريم مع دعم البحث النصي والبحث بالجذر اللغوي.
  List<Ayah> searchAyahs(String query, {int limit = 50}) {
    if (!_isLoaded || query.trim().isEmpty) return const [];

    if (ArabicRootSearchHelper.isRootQuery(query)) {
      final root = ArabicRootSearchHelper.extractRoot(query);
      return searchAyahsByRoot(root, limit: limit);
    }

    final normalizedQuery = ArabicSearchNormalizer.normalize(query);
    if (normalizedQuery.isEmpty) return const [];

    final results = <Ayah>[];
    for (int i = 0; i < _allAyahs.length; i++) {
      if (_normalizedAyahTexts[i].contains(normalizedQuery)) {
        results.add(_allAyahs[i]);
        if (results.length >= limit) break;
      }
    }
    return results;
  }

  /// Instant offline Arabic root and morphological search across all 6,236 ayahs.
  /// يبحث في آيات القرآن الكريم باستخدام الجذر الصرفي العربي ومشتقاته.
  List<Ayah> searchAyahsByRoot(String root, {int limit = 50}) {
    if (!_isLoaded || root.trim().isEmpty) return const [];
    final forms = ArabicRootSearchHelper.getRootForms(root);
    if (forms.isEmpty) return const [];

    final results = <Ayah>[];
    for (int i = 0; i < _allAyahs.length; i++) {
      final textNorm = _normalizedAyahTexts[i];
      for (final form in forms) {
        if (textNorm.contains(form)) {
          results.add(_allAyahs[i]);
          break;
        }
      }
      if (results.length >= limit) break;
    }
    return results;
  }

  /// الكلمات الغريبة المعتمدة في صفحة مصحف معينة (1 - 604).
  List<QuranWordMeaning> getWordMeaningsForPage(int pageNumber) {
    assert(_isLoaded, 'QuranRepository must be initialized before use');
    if (pageNumber < 1 || pageNumber > 604) {
      pageNumber = pageNumber.clamp(1, 604);
    }
    return _wordMeaningsByPage[pageNumber] ?? const [];
  }

  /// الكلمات الغريبة المعتمدة في سورة معينة (1 - 114).
  List<QuranWordMeaning> getWordMeaningsForSurah(int surahNumber) {
    assert(_isLoaded, 'QuranRepository must be initialized before use');
    if (surahNumber < 1 || surahNumber > 114) {
      surahNumber = surahNumber.clamp(1, 114);
    }
    return _wordMeaningsBySurah[surahNumber] ?? const [];
  }

  /// بحث لحظي في معاني الكلمات القرآنية المعتمدة ومفرداتها مع ترتيب الأولوية للمطابقة التامة والمباشرة.
  List<QuranWordMeaning> searchWordMeanings(String query, {int limit = 50}) {
    if (!_isLoaded) return const [];
    if (query.trim().isEmpty) {
      return _wordMeanings.take(limit).toList();
    }

    final normalizedQuery = ArabicSearchNormalizer.normalize(query);
    if (normalizedQuery.isEmpty) return _wordMeanings.take(limit).toList();

    final exactMatches = <QuranWordMeaning>[];
    final prefixMatches = <QuranWordMeaning>[];
    final wordContainsMatches = <QuranWordMeaning>[];
    final meaningMatches = <QuranWordMeaning>[];

    for (int i = 0; i < _wordMeanings.length; i++) {
      final item = _wordMeanings[i];
      final wordNorm = _normalizedWordOnly[i];
      final meaningNorm = _normalizedMeaningOnly[i];

      if (wordNorm == normalizedQuery) {
        exactMatches.add(item);
      } else if (wordNorm.startsWith(normalizedQuery)) {
        prefixMatches.add(item);
      } else if (wordNorm.contains(normalizedQuery)) {
        wordContainsMatches.add(item);
      } else if (meaningNorm.contains(normalizedQuery)) {
        meaningMatches.add(item);
      }
    }

    final combined = <QuranWordMeaning>[
      ...exactMatches,
      ...prefixMatches,
      ...wordContainsMatches,
      ...meaningMatches,
    ];

    if (combined.length > limit) {
      return combined.sublist(0, limit);
    }
    return combined;
  }
}
