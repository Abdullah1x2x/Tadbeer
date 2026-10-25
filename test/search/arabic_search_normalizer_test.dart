import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/core/utils/arabic_search_normalizer.dart';

void main() {
  group('ArabicSearchNormalizer Unit Tests', () {
    test('Diacritics and Tashkeel Removal', () {
      const textWithTashkeel = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
      final normalized = ArabicSearchNormalizer.normalize(textWithTashkeel);
      expect(normalized, equals('بسم الله الرحمن الرحيم'));
    });

    test('Alef Variations Normalization to Bare Alef', () {
      expect(ArabicSearchNormalizer.normalize('إِيمَان'), equals('ايمان'));
      expect(ArabicSearchNormalizer.normalize('أَنْعَمْتَ'), equals('انعمت'));
      expect(ArabicSearchNormalizer.normalize('آيَات'), equals('ايات'));
      expect(ArabicSearchNormalizer.normalize('ٱلْحَمْدُ'), equals('الحمد'));
    });

    test('Taa Marbuta and Alef Maqsura Normalization', () {
      expect(ArabicSearchNormalizer.normalize('سُورَة'), equals('سوره'));
      expect(ArabicSearchNormalizer.normalize('هُدَىٰ'), equals('هدي'));
    });

    test('Tatweel / Kashida Removal', () {
      expect(
        ArabicSearchNormalizer.normalize('الـــرَّحْـــمَـــٰن'),
        equals('الرحمن'),
      );
    });

    test('Arabic-Indic Digits Conversion and Padding', () {
      expect(ArabicSearchNormalizer.toArabicDigits(1), equals('١'));
      expect(ArabicSearchNormalizer.toArabicDigits(114), equals('١١٤'));
      expect(ArabicSearchNormalizer.toArabicDigits(6236), equals('٦٢٣٦'));
      expect(
        ArabicSearchNormalizer.formatDigits(5, minDigits: 2),
        equals('٠٥'),
      );
      expect(
        ArabicSearchNormalizer.formatDigits(45, minDigits: 2),
        equals('٤٥'),
      );
    });

    test('Arabic-Indic and Persian Digits Conversion to English ASCII', () {
      expect(ArabicSearchNormalizer.toEnglishDigits('١'), equals('1'));
      expect(ArabicSearchNormalizer.toEnglishDigits('١١٤'), equals('114'));
      expect(ArabicSearchNormalizer.toEnglishDigits('٦٢٣٦'), equals('6236'));
      expect(ArabicSearchNormalizer.toEnglishDigits('۱۲۳'), equals('123'));
      expect(ArabicSearchNormalizer.toEnglishDigits('صفحة ١٥٠'), equals('صفحة 150'));
    });

    test('Real Quran Verse Search Matching (Ayat Al-Kursi)', () {
      final file = File('assets/quran/quran_data.json');
      final content = file.readAsStringSync();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final rawPages = (data['pages'] as List).cast<Map<String, dynamic>>();

      final allAyahs = <Map<String, dynamic>>[];
      for (final p in rawPages) {
        for (final a in (p['ayahs'] as List)) {
          allAyahs.add(a as Map<String, dynamic>);
        }
      }

      // Search for "الله لا اله الا هو الحي القيوم" without diacritics
      const query = 'الله لا اله الا هو الحي القيوم';
      final normalizedQuery = ArabicSearchNormalizer.normalize(query);

      final matches = allAyahs.where((a) {
        final normText = ArabicSearchNormalizer.normalize(a['text'] as String);
        return normText.contains(normalizedQuery);
      }).toList();

      expect(matches.isNotEmpty, isTrue);
      final match = matches.first;
      expect(match['surahNumber'], equals(2));
      expect(match['ayahNumber'], equals(255));
    });

    test('Dagger Alif and Phonetic Variations Normalization Equivalence', () {
      // Rahman
      expect(
        ArabicSearchNormalizer.normalize('الرَّحْمَٰن'),
        equals(ArabicSearchNormalizer.normalize('الرحمن')),
      );
      expect(
        ArabicSearchNormalizer.normalize('الرحمان'),
        equals(ArabicSearchNormalizer.normalize('الرحمن')),
      );

      // Dhalika
      expect(
        ArabicSearchNormalizer.normalize('ذَٰلِكَ'),
        equals(ArabicSearchNormalizer.normalize('ذلك')),
      );
      expect(
        ArabicSearchNormalizer.normalize('ذالك'),
        equals(ArabicSearchNormalizer.normalize('ذلك')),
      );
      expect(
        ArabicSearchNormalizer.normalize('ذالك الكتاب'),
        equals(ArabicSearchNormalizer.normalize('ذلك الكتاب')),
      );

      // Hadha
      expect(
        ArabicSearchNormalizer.normalize('هَٰذَا'),
        equals(ArabicSearchNormalizer.normalize('هذا')),
      );
      expect(
        ArabicSearchNormalizer.normalize('هاذا'),
        equals(ArabicSearchNormalizer.normalize('هذا')),
      );

      // Ilah / Alah
      expect(
        ArabicSearchNormalizer.normalize('إِلَٰه'),
        equals(ArabicSearchNormalizer.normalize('إله')),
      );
      expect(
        ArabicSearchNormalizer.normalize('إلاه'),
        equals(ArabicSearchNormalizer.normalize('إله')),
      );
      expect(
        ArabicSearchNormalizer.normalize('لا إلاه إلا الله'),
        equals(ArabicSearchNormalizer.normalize('لا إله إلا الله')),
      );

      // Lakin
      expect(
        ArabicSearchNormalizer.normalize('لَٰكِن'),
        equals(ArabicSearchNormalizer.normalize('لكن')),
      );
      expect(
        ArabicSearchNormalizer.normalize('لاكن'),
        equals(ArabicSearchNormalizer.normalize('لكن')),
      );

      // Taha & Dawud
      expect(
        ArabicSearchNormalizer.normalize('طاها'),
        equals(ArabicSearchNormalizer.normalize('طه')),
      );
      expect(
        ArabicSearchNormalizer.normalize('داوود'),
        equals(ArabicSearchNormalizer.normalize('داود')),
      );

      // Integrity check: Words starting with Al-Ahl / Al-Ahram must NOT be damaged
      expect(ArabicSearchNormalizer.normalize('الأهل'), equals('الاهل'));
      expect(ArabicSearchNormalizer.normalize('الأهرام'), equals('الاهرام'));

      // Uthmani Waw + Dagger Alif (Salah, Zakah, Hayah, Riba)
      expect(ArabicSearchNormalizer.normalize('ٱلصَّلَوٰة'), equals('الصلاه'));
      expect(ArabicSearchNormalizer.normalize('ٱلزَّكَوٰة'), equals('الزكاه'));
      expect(ArabicSearchNormalizer.normalize('ٱلْحَيَوٰة'), equals('الحياه'));
      expect(ArabicSearchNormalizer.normalize('ٱلرِّبَوٰا۟'), equals('الربا'));

      // Uthmani Medial Alef Maqsura + Dagger Alif
      expect(ArabicSearchNormalizer.normalize('أَلْهَىٰكُمُ'), equals('الهاكم'));
      expect(ArabicSearchNormalizer.normalize('هَدَىٰهُمْ'), equals('هداهم'));
      expect(ArabicSearchNormalizer.normalize('سَوَّىٰهُ'), equals('سواه'));

      // Uthmani Medial Dagger Alif words restored for search
      expect(ArabicSearchNormalizer.normalize('كِتَٰب'), equals('كتاب'));
      expect(ArabicSearchNormalizer.normalize('ٱلْكِتَٰبُ'), equals('الكتاب'));
      expect(ArabicSearchNormalizer.normalize('ٱلصَّٰبِرِينَ'), equals('الصابرين'));
      expect(ArabicSearchNormalizer.normalize('ٱلظَّٰلِمِينَ'), equals('الظالمين'));
      expect(ArabicSearchNormalizer.normalize('ٱلصَّٰلِحِينَ'), equals('الصالحين'));
    });

    test('Real Quran Search Matching with Dagger Alif and Phonetic Input', () {
      final file = File('assets/quran/quran_data.json');
      final content = file.readAsStringSync();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final rawPages = (data['pages'] as List).cast<Map<String, dynamic>>();

      final allAyahs = <Map<String, dynamic>>[];
      for (final p in rawPages) {
        for (final a in (p['ayahs'] as List)) {
          allAyahs.add(a as Map<String, dynamic>);
        }
      }

      List<Map<String, dynamic>> searchAyahs(String query) {
        final nq = ArabicSearchNormalizer.normalize(query);
        return allAyahs.where((a) {
          final nt = ArabicSearchNormalizer.normalize(a['text'] as String);
          return nt.contains(nq);
        }).toList();
      }

      // 1. "الرحمان" matches Surah Al-Fatiha
      final rahmanMatches = searchAyahs('الرحمان');
      expect(rahmanMatches.isNotEmpty, isTrue);
      expect(rahmanMatches.any((a) => a['surahNumber'] == 1 && a['ayahNumber'] == 1), isTrue);
      expect(rahmanMatches.any((a) => a['surahNumber'] == 1 && a['ayahNumber'] == 3), isTrue);

      // 2. "ذالك الكتاب" matches Surah Al-Baqarah:2
      final dhalikaMatches = searchAyahs('ذالك الكتاب');
      expect(dhalikaMatches.isNotEmpty, isTrue);
      expect(dhalikaMatches.first['surahNumber'], equals(2));
      expect(dhalikaMatches.first['ayahNumber'], equals(2));

      // 3. "لا إلاه إلا هو" matches Al-Baqarah:255, and "لا إلاه إلا الله" matches Muhammad:19
      final ilahHuwaMatches = searchAyahs('لا إلاه إلا هو');
      expect(ilahHuwaMatches.isNotEmpty, isTrue);
      expect(ilahHuwaMatches.any((a) => a['surahNumber'] == 2 && a['ayahNumber'] == 255), isTrue);

      final ilahAllahMatches = searchAyahs('لا إلاه إلا الله');
      expect(ilahAllahMatches.isNotEmpty, isTrue);
      expect(ilahAllahMatches.any((a) => a['surahNumber'] == 47 && a['ayahNumber'] == 19), isTrue);

      // 4. "الصابرين" matches Al-Baqarah:153
      final sabirMatches = searchAyahs('الصابرين');
      expect(sabirMatches.isNotEmpty, isTrue);
      expect(sabirMatches.any((a) => a['surahNumber'] == 2 && a['ayahNumber'] == 153), isTrue);

      // 5. "داوود" matches Al-Baqarah:251
      final dawudMatches = searchAyahs('داوود');
      expect(dawudMatches.isNotEmpty, isTrue);
      expect(dawudMatches.any((a) => a['surahNumber'] == 2 && a['ayahNumber'] == 251), isTrue);

      // 6. "الهاكم التكاثر" matches Surah At-Takathur:1
      final takathurMatches = searchAyahs('الهاكم التكاثر');
      expect(takathurMatches.isNotEmpty, isTrue);
      expect(takathurMatches.first['surahNumber'], equals(102));
      expect(takathurMatches.first['ayahNumber'], equals(1));
    });
  });
}
