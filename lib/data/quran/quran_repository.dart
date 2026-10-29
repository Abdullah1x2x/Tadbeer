import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/utils/arabic_root_search_helper.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import 'custom_word_meanings.dart';
import 'quran_models.dart';

/// نص القرآن وبيانات المصحف، للقراءة فقط.
/// النص العثماني من مشروع تنزيل (`assets/quran/quran_data.json`): ١١٤ سورة، و٦٢٣٦ آية برقم ثابت لكل آية، و٦٠٤ صفحات. القوائم المعادة غير قابلة للتعديل، ويُحفظ نص كل آية مطبّعاً مسبقاً ليكون البحث فورياً.
class QuranRepository {
  static final QuranRepository instance = QuranRepository._internal();

  QuranRepository._internal();

  bool _isLoaded = false;

  /// هل حُمّلت بيانات القرآن ومعاني الكلمات.
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

  List<Surah> get surahs => List.unmodifiable(_surahs);

  List<QuranPage> get pages => List.unmodifiable(_pages);

  List<Ayah> get allAyahs => List.unmodifiable(_allAyahs);

  /// معاني الكلمات الغريبة.
  List<QuranWordMeaning> get allWordMeanings =>
      List.unmodifiable(_wordMeanings);

  /// يحمّل بيانات القرآن ومعاني الكلمات ويبني فهارس البحث؛ يُستدعى مرة عند الإقلاع.
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

    // معاني الكلمات (السراج في بيان غريب القرآن).
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
        final normMeaning = ArabicSearchNormalizer.normalize(
          wordMeaning.meaning,
        );
        _normalizedWordOnly.add(normWord);
        _normalizedMeaningOnly.add(normMeaning);
      }
    } catch (_) {
      // في الاختبارات المعزولة قد لا تُتاح ملفات الأصول، فتُكمل البيانات بدونها.
    }

    // دمج المعاني التي أضافها المطور في [customWordMeanings].
    for (final customItem in customWordMeanings) {
      final ayah = _ayahsByKey['${customItem.surah}:${customItem.ayah}'];
      final pageNum = ayah?.page ?? 1;
      final wordMeaning = customItem.toQuranWordMeaning(pageNum);
      _wordMeanings.add(wordMeaning);
      _wordMeaningsByPage.putIfAbsent(pageNum, () => []).add(wordMeaning);
      _wordMeaningsBySurah
          .putIfAbsent(customItem.surah, () => [])
          .add(wordMeaning);
      final normWord = ArabicSearchNormalizer.normalize(wordMeaning.word);
      final normMeaning = ArabicSearchNormalizer.normalize(wordMeaning.meaning);
      _normalizedWordOnly.add(normWord);
      _normalizedMeaningOnly.add(normMeaning);
    }

    _isLoaded = true;
  }

  /// صفحة المصحف [pageNumber] (١..٦٠٤).
  QuranPage getPage(int pageNumber) {
    assert(_isLoaded, 'QuranRepository must be initialized before use');
    if (pageNumber < 1 || pageNumber > 604) {
      pageNumber = pageNumber.clamp(1, 604);
    }
    return _pages[pageNumber - 1];
  }

  /// السورة [surahNumber] (١..١١٤).
  Surah getSurah(int surahNumber) {
    assert(_isLoaded, 'QuranRepository must be initialized before use');
    if (surahNumber < 1 || surahNumber > 114) {
      surahNumber = surahNumber.clamp(1, 114);
    }
    return _surahs[surahNumber - 1];
  }

  /// الآية، أو null إن لم توجد.
  Ayah? getAyah(int surahNumber, int ayahNumber) {
    assert(_isLoaded, 'QuranRepository must be initialized before use');
    return _ayahsByKey['$surahNumber:$ayahNumber'];
  }

  /// بحث في كل الآيات دون إنترنت.
  /// يتعرّف على المراجع المباشرة ("البقرة 255"، "2:255"، "آية الكرسي")، ويدعم البحث بالجذر ("جذر:صبر"). المطابقة المتصلة أولاً، ثم الآيات التي فيها كل كلمات البحث ولو متفرقة. ولا يشترط "ال" التعريف.
  List<Ayah> searchAyahs(String query, {int limit = 50}) {
    if (!_isLoaded || query.trim().isEmpty) return const [];

    if (ArabicRootSearchHelper.isRootQuery(query)) {
      final root = ArabicRootSearchHelper.extractRoot(query);
      return searchAyahsByRoot(root, limit: limit);
    }

    final cleanQuery = ArabicSearchNormalizer.toEnglishDigits(query.trim());
    final directAyah = _tryParseDirectAyahReference(cleanQuery);

    final normalizedQuery = ArabicSearchNormalizer.normalize(query);
    if (normalizedQuery.isEmpty) {
      return directAyah != null ? [directAyah] : const [];
    }

    final results = <Ayah>[];
    final addedIds = <int>{};

    // مرجع مباشر (البقرة 255 أو الكرسي) يأتي أولاً.
    if (directAyah != null) {
      results.add(directAyah);
      addedIds.add(directAyah.id);
    }

    // أولاً: العبارة كاملة متصلة.
    for (int i = 0; i < _allAyahs.length; i++) {
      if (_normalizedAyahTexts[i].contains(normalizedQuery)) {
        if (addedIds.add(_allAyahs[i].id)) {
          results.add(_allAyahs[i]);
          if (results.length >= limit) return results;
        }
      }
    }

    // ثانياً: كل الكلمات في نفس الآية ولو متفرقة.
    final tokens = normalizedQuery
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    if (tokens.length > 1) {
      for (int i = 0; i < _allAyahs.length; i++) {
        final ayahNorm = _normalizedAyahTexts[i];

        bool allTokensMatch = true;
        for (final token in tokens) {
          if (ayahNorm.contains(token)) continue;

          // كلمة من ٤ أحرف فأكثر تبدأ بـ "ال" تُفحص أيضاً بدونها.
          if (token.startsWith('ال') && token.length >= 4) {
            final withoutAl = token.substring(2);
            if (ayahNorm.contains(withoutAl)) continue;
          }

          allTokensMatch = false;
          break;
        }

        if (allTokensMatch) {
          if (addedIds.add(_allAyahs[i].id)) {
            results.add(_allAyahs[i]);
            if (results.length >= limit) return results;
          }
        }
      }
    } else if (tokens.length == 1) {
      // كلمة واحدة تبدأ بـ "ال" ولم تطابق حرفياً.
      final single = tokens.first;
      if (single.startsWith('ال') && single.length >= 4) {
        final withoutAl = single.substring(2);
        for (int i = 0; i < _allAyahs.length; i++) {
          if (_normalizedAyahTexts[i].contains(withoutAl)) {
            if (addedIds.add(_allAyahs[i].id)) {
              results.add(_allAyahs[i]);
              if (results.length >= limit) return results;
            }
          }
        }
      }
    }

    return results;
  }

  /// الآية التي يشير إليها مرجع مباشر ("البقرة 255"، "2:255"، "سورة الكهف"، "آية الكرسي")، أو null.
  Ayah? _tryParseDirectAyahReference(String rawQuery) {
    if (!_isLoaded) return null;
    final englishQuery = ArabicSearchNormalizer.toEnglishDigits(
      rawQuery.trim(),
    );
    final norm = ArabicSearchNormalizer.normalize(rawQuery);

    // ١. آيات بأسماء مشهورة.
    if (norm == 'ايه الكرسي' || norm == 'الكرسي') {
      return getAyah(2, 255);
    }
    if (norm == 'ايه الدين' || norm == 'الدين') {
      return getAyah(2, 282);
    }

    // ٢. "سورة:آية" (2:255).
    final colonMatch = RegExp(r'^(\d{1,3})\s*[:\s]\s*(\d{1,3})$')
        .firstMatch(englishQuery);
    if (colonMatch != null) {
      final surahNum = int.tryParse(colonMatch.group(1)!);
      final ayahNum = int.tryParse(colonMatch.group(2)!);
      if (surahNum != null &&
          ayahNum != null &&
          surahNum >= 1 &&
          surahNum <= 114) {
        final surah = getSurah(surahNum);
        if (ayahNum >= 1 && ayahNum <= surah.ayahCount) {
          return getAyah(surahNum, ayahNum);
        }
      }
    }

    // ٣. اسم السورة ورقم الآية (البقرة 255).
    final surahAyahMatch = RegExp(r'^(?:سورة\s+)?([^\d:]+?)\s+(\d{1,3})$')
        .firstMatch(englishQuery);
    if (surahAyahMatch != null) {
      final surahNameRaw = surahAyahMatch.group(1)!.trim();
      final ayahNum = int.tryParse(surahAyahMatch.group(2)!);
      if (ayahNum != null) {
        final surah = _findSurahByName(surahNameRaw);
        if (surah != null && ayahNum >= 1 && ayahNum <= surah.ayahCount) {
          return getAyah(surah.number, ayahNum);
        }
      }
    }

    // ٤. اسم السورة وحده (سورة الكهف).
    final surahOnlyMatch = RegExp(r'^سورة\s+([^\d:]+)$')
        .firstMatch(englishQuery);
    if (surahOnlyMatch != null) {
      final surahNameRaw = surahOnlyMatch.group(1)!.trim();
      final surah = _findSurahByName(surahNameRaw);
      if (surah != null) {
        return getAyah(surah.number, 1);
      }
    }

    return null;
  }

  /// السورة بالاسم، مع "ال" أو بدونها.
  Surah? _findSurahByName(String nameQuery) {
    final normQuery = ArabicSearchNormalizer.normalize(nameQuery);
    final withoutAl = normQuery.startsWith('ال') && normQuery.length > 3
        ? normQuery.substring(2)
        : normQuery;

    for (final surah in _surahs) {
      final surahNorm = ArabicSearchNormalizer.normalize(surah.name);
      final surahWithoutAl = surahNorm.startsWith('ال') && surahNorm.length > 3
          ? surahNorm.substring(2)
          : surahNorm;

      if (surahNorm == normQuery ||
          surahWithoutAl == withoutAl ||
          surahNorm == withoutAl ||
          surahWithoutAl == normQuery) {
        return surah;
      }
    }
    return null;
  }

  /// الآيات التي فيها صيغة من صيغ الجذر [root].
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

  /// معاني الكلمات في صفحة [pageNumber].
  List<QuranWordMeaning> getWordMeaningsForPage(int pageNumber) {
    assert(_isLoaded, 'QuranRepository must be initialized before use');
    if (pageNumber < 1 || pageNumber > 604) {
      pageNumber = pageNumber.clamp(1, 604);
    }
    return _wordMeaningsByPage[pageNumber] ?? const [];
  }

  /// معاني الكلمات في سورة [surahNumber].
  List<QuranWordMeaning> getWordMeaningsForSurah(int surahNumber) {
    assert(_isLoaded, 'QuranRepository must be initialized before use');
    if (surahNumber < 1 || surahNumber > 114) {
      surahNumber = surahNumber.clamp(1, 114);
    }
    return _wordMeaningsBySurah[surahNumber] ?? const [];
  }

  /// بحث في معاني الكلمات، المطابقة التامة أولاً.
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
