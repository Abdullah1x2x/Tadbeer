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
  });
}
