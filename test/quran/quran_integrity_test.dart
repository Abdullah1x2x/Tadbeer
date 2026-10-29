import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/data/quran/quran_models.dart';

void main() {
  late Map<String, dynamic> quranJson;
  late List<Surah> surahs;
  late List<QuranPage> pages;

  setUpAll(() {
    final file = File('assets/quran/quran_data.json');
    expect(file.existsSync(), isTrue, reason: 'Quran JSON dataset must exist');
    final content = file.readAsStringSync();
    quranJson = jsonDecode(content) as Map<String, dynamic>;

    final rawSurahs = (quranJson['surahs'] as List)
        .cast<Map<String, dynamic>>();
    surahs = rawSurahs.map((s) => Surah.fromJson(s)).toList();

    final rawPages = (quranJson['pages'] as List).cast<Map<String, dynamic>>();
    pages = rawPages.map((p) => QuranPage.fromJson(p)).toList();
  });

  group('Quran Data Integrity Tests', () {
    test('Verified Surahs Count and Boundaries', () {
      expect(
        surahs.length,
        equals(114),
        reason: 'Must contain exactly 114 surahs',
      );
      expect(surahs.first.number, equals(1));
      expect(surahs.first.name, equals('الفاتحة'));
      expect(surahs.first.ayahCount, equals(7));

      expect(surahs[1].number, equals(2));
      expect(surahs[1].name, equals('البقرة'));
      expect(surahs[1].ayahCount, equals(286));

      expect(surahs.last.number, equals(114));
      expect(surahs.last.name, equals('الناس'));
      expect(surahs.last.ayahCount, equals(6));
    });

    test('Verified 604 Pages Mushaf Mapping', () {
      expect(
        pages.length,
        equals(604),
        reason: 'Must contain exactly 604 pages',
      );

      // Page 1 is Al-Fatiha
      expect(pages[0].pageNumber, equals(1));
      expect(pages[0].surahNumbers, contains(1));
      expect(pages[0].ayahs.first.surahNumber, equals(1));
      expect(pages[0].ayahs.first.ayahNumber, equals(1));

      // Page 2 is Al-Baqarah 1-5
      expect(pages[1].pageNumber, equals(2));
      expect(pages[1].surahNumbers, contains(2));
      expect(pages[1].ayahs.first.surahNumber, equals(2));
      expect(pages[1].ayahs.first.ayahNumber, equals(1));

      // Page 604 ends at Surah 114 Ayah 6
      expect(pages[603].pageNumber, equals(604));
      expect(pages[603].ayahs.last.surahNumber, equals(114));
      expect(pages[603].ayahs.last.ayahNumber, equals(6));
    });

    test('Total Ayahs Count and Stable ID Consistency', () {
      int totalAyahs = 0;
      final seenIds = <int>{};
      final seenKeys = <String>{};

      for (final page in pages) {
        for (final ayah in page.ayahs) {
          totalAyahs++;
          expect(
            seenIds.contains(ayah.id),
            isFalse,
            reason: 'Duplicate ayah id: ${ayah.id}',
          );
          expect(
            seenKeys.contains(ayah.key),
            isFalse,
            reason: 'Duplicate ayah key: ${ayah.key}',
          );
          seenIds.add(ayah.id);
          seenKeys.add(ayah.key);

          // Verify id continuity
          expect(ayah.id, equals(totalAyahs));
          expect(ayah.page, equals(page.pageNumber));
          expect(ayah.juz, inInclusiveRange(1, 30));
          expect(ayah.hizb, inInclusiveRange(1, 60));
          expect(ayah.quarter, inInclusiveRange(1, 240));
        }
      }

      expect(
        totalAyahs,
        equals(6236),
        reason: 'Must contain exactly 6236 ayahs',
      );
    });

    test('Sajdah Count and Specific Sajdah Ayahs', () {
      final sajdaAyahs = <Ayah>[];
      for (final page in pages) {
        for (final ayah in page.ayahs) {
          if (ayah.isSajdah) {
            sajdaAyahs.add(ayah);
          }
        }
      }

      expect(
        sajdaAyahs.length,
        equals(15),
        reason: 'Must contain exactly 15 sajdah markers',
      );

      // Check first sajdah: Al-Araf (7:206)
      expect(
        sajdaAyahs.any((a) => a.surahNumber == 7 && a.ayahNumber == 206),
        isTrue,
      );
      // Check Sajdah surah (32:15)
      expect(
        sajdaAyahs.any((a) => a.surahNumber == 32 && a.ayahNumber == 15),
        isTrue,
      );
      // Check Al-Alaq (96:19)
      expect(
        sajdaAyahs.any((a) => a.surahNumber == 96 && a.ayahNumber == 19),
        isTrue,
      );
    });

    test('Juz 30 Boundary Verification', () {
      final juz30Pages = pages.where((p) => p.juzNumber == 30).toList();
      expect(juz30Pages.isNotEmpty, isTrue);
      expect(juz30Pages.first.pageNumber, equals(582));
      expect(juz30Pages.last.pageNumber, equals(604));
    });

    test('Specific Quran Text Integrity Checks', () {
      // Ayat al-Kursi (2:255)
      final baqarahPage = pages.firstWhere(
        (p) => p.ayahs.any((a) => a.surahNumber == 2 && a.ayahNumber == 255),
      );
      final ayatKursi = baqarahPage.ayahs.firstWhere(
        (a) => a.surahNumber == 2 && a.ayahNumber == 255,
      );
      expect(
        ayatKursi.text,
        contains('ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ ٱلْحَىُّ ٱلْقَيُّومُ'),
      );

      // Surah Al-Ikhlas (112:1)
      final ikhlasPage = pages.firstWhere(
        (p) => p.ayahs.any((a) => a.surahNumber == 112 && a.ayahNumber == 1),
      );
      final ikhlas1 = ikhlasPage.ayahs.firstWhere(
        (a) => a.surahNumber == 112 && a.ayahNumber == 1,
      );
      expect(ikhlas1.text, equals('قُلْ هُوَ ٱللَّهُ أَحَدٌ'));

      // Surah Muhammad (47:24) Tadabbur verse
      final muhammadPage = pages.firstWhere(
        (p) => p.ayahs.any((a) => a.surahNumber == 47 && a.ayahNumber == 24),
      );
      final tadabburVerse = muhammadPage.ayahs.firstWhere(
        (a) => a.surahNumber == 47 && a.ayahNumber == 24,
      );
      expect(
        tadabburVerse.text,
        contains('أَفَلَا يَتَدَبَّرُونَ ٱلْقُرْءَانَ'),
      );
    });
  });
}
