import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/core/utils/arabic_search_normalizer.dart';
import 'package:tadbeer/features/duas/data/quran_duas_repository.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File dataFile;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_duas_test_');
    dataFile = File('${tempDir.path}/test_user_data.json');
    await UserDataStore.instance.init(dataFile);
    await QuranRepository.instance.init();
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Quranic Duas Data Integrity Tests (أدعية من القرآن)', () {
    test('Verified Duas Count and Complete Inventory (88 Entries)', () {
      final repo = QuranDuasRepository.instance;
      repo.resetCache();
      final duas = repo.getDuas();

      expect(
        duas.length,
        equals(88),
        reason: 'Catalog must contain exactly 88 verified direct Quranic supplications',
      );
    });

    test('Strict Order Verification and Surah Mapping', () {
      final repo = QuranDuasRepository.instance;
      final duas = repo.getDuas();

      // IDs must be sequential 1 to 88
      for (int i = 0; i < duas.length; i++) {
        expect(duas[i].id, equals(i + 1));
      }

      // First dua is Al-Fatihah (5-7) and last is An-Nas (1-6)
      expect(duas.first.surahNumber, equals(1));
      expect(duas.first.ayahDisplay, equals('5–7'));
      expect(duas.last.surahNumber, equals(114));
      expect(duas.last.ayahDisplay, equals('1–6'));
    });

    test('Zero Duplicate IDs Check', () {
      final repo = QuranDuasRepository.instance;
      final duas = repo.getDuas();
      final ids = duas.map((d) => d.id).toList();
      final uniqueIds = ids.toSet();

      expect(
        ids.length,
        equals(uniqueIds.length),
        reason: 'There must be zero duplicate IDs in Duas catalog',
      );
    });

    test('All 12 Canonical Categories Are Populated', () {
      final repo = QuranDuasRepository.instance;
      final duas = repo.getDuas();

      expect(
        QuranDuasRepository.categories.length,
        equals(13),
      ); // 'الكل' + 12 categories
      expect(
        QuranDuasRepository.categories.contains(
          'آيات سياقية ليست دعاءً مباشرًا',
        ),
        isFalse,
      );

      final foundCategories = duas.map((d) => d.category).toSet();
      for (final cat in QuranDuasRepository.categories) {
        if (cat == 'الكل') continue;
        expect(
          foundCategories.contains(cat),
          isTrue,
          reason: 'Category "$cat" must have at least one entry',
        );
      }
    });

    test('Exclusion of Contextual Verses and Verification of Direct Duas Only', () {
      final repo = QuranDuasRepository.instance;
      final duas = repo.getDuas();

      // All 88 entries must be direct supplications without alerts
      for (final dua in duas) {
        expect(
          dua.isDirectDua,
          isTrue,
          reason:
              'Dua #${dua.id} (${dua.surahName} ${dua.ayahDisplay}) must be direct',
        );
        expect(
          dua.alert,
          isNull,
          reason: 'Dua #${dua.id} should not have alert',
        );
        expect(dua.category, isNot(equals('آيات سياقية ليست دعاءً مباشرًا')));
      }

      // Explicitly verify known previously-included contextual verses are completely removed:
      // 1. Al-An'am (6:71, 6:162, 6:163)
      expect(
        duas.any((d) => d.surahNumber == 6),
        isFalse,
        reason: 'Surah 6 has no direct duas',
      );
      // 2. Al-Anfal (8:32)
      expect(
        duas.any((d) => d.surahNumber == 8 && d.ayahNumber == 32),
        isFalse,
      );
      // 3. At-Tawbah (9:51, 9:129)
      expect(
        duas.any((d) => d.surahNumber == 9),
        isFalse,
        reason: 'Surah 9 has no direct duas',
      );
      // 4. Ar-Ra'd (13:16)
      expect(
        duas.any((d) => d.surahNumber == 13 && d.ayahNumber == 16),
        isFalse,
      );
      // 5. An-Nahl (16:98)
      expect(duas.any((d) => d.surahNumber == 16), isFalse);
      // 6. Al-Isra (17:81)
      expect(
        duas.any((d) => d.surahNumber == 17 && d.ayahNumber == 81),
        isFalse,
      );
      // 7. Ta-Ha (20:45)
      expect(
        duas.any((d) => d.surahNumber == 20 && d.ayahNumber == 45),
        isFalse,
      );
      // 8. Ash-Shu'ara (26:88–89)
      expect(
        duas.any((d) => d.surahNumber == 26 && d.ayahNumber == 88),
        isFalse,
      );
      // 9. Luqman (31:17)
      expect(duas.any((d) => d.surahNumber == 31), isFalse);
      // 10. Al-Ahzab (33:33)
      expect(duas.any((d) => d.surahNumber == 33), isFalse);
      // 11. Ya-Sin (36:22)
      expect(duas.any((d) => d.surahNumber == 36), isFalse);
      // 12. Fussilat (41:36)
      expect(duas.any((d) => d.surahNumber == 41), isFalse);
      // 13. Muhammad (47:19)
      expect(duas.any((d) => d.surahNumber == 47), isFalse);
      // 14. At-Tur (52:28)
      expect(duas.any((d) => d.surahNumber == 52), isFalse);
      // 15. Al-Munafiqun (63:10)
      expect(duas.any((d) => d.surahNumber == 63), isFalse);
      // 16. Al-Muzzammil (73:9)
      expect(duas.any((d) => d.surahNumber == 73), isFalse);
    });

    test('All Duas Map to Valid Mushaf Pages in QuranRepository', () {
      final quranRepo = QuranRepository.instance;
      final duas = QuranDuasRepository.instance.getDuas();

      for (final dua in duas) {
        expect(dua.page, greaterThanOrEqualTo(1));
        expect(dua.page, lessThanOrEqualTo(604));

        final originalAyah = quranRepo.getAyah(dua.surahNumber, dua.ayahNumber);
        expect(
          originalAyah,
          isNotNull,
          reason: 'Ayah ${dua.ayahKey} must exist in QuranRepository',
        );
        expect(dua.page, equals(originalAyah!.page));
        expect(dua.duaText.isNotEmpty, isTrue);
        expect(dua.title.isNotEmpty, isTrue);
      }
    });

    test('Search and Category Filtering Functionality', () {
      final repo = QuranDuasRepository.instance;

      // 1. Search by dua text
      final rabbanaResults = repo.search('ربنا اتنا');
      expect(rabbanaResults.isNotEmpty, isTrue);
      expect(
        rabbanaResults.any((d) => d.surahNumber == 2 && d.ayahNumber == 201),
        isTrue,
        reason: 'Should find 2:201 (ربنا آتنا في الدنيا حسنة...)',
      );

      // 2. Search by Prophet Yunus dua
      final yunusResults = repo.search('لا اله الا انت');
      expect(yunusResults.isNotEmpty, isTrue);
      expect(
        yunusResults.any((d) => d.surahNumber == 21 && d.ayahNumber == 87),
        isTrue,
        reason: 'Should find 21:87 (لا إله إلا أنت سبحانك...)',
      );

      // 3. Search by Surah Name
      final baqarahResults = repo.search('البقرة');
      expect(
        baqarahResults.length,
        equals(8),
        reason: 'Surah Al-Baqarah contains 8 items in the new catalog',
      );

      // 4. Search by Ayah Number
      final ayah250Results = repo.search('250');
      expect(
        ayah250Results.any((d) => d.surahNumber == 2 && d.ayahNumber == 250),
        isTrue,
      );

      // 5. Search by Title
      final titleResults = repo.search('طلب الأمن');
      expect(titleResults.isNotEmpty, isTrue);
      expect(
        titleResults.any((d) => d.surahNumber == 2 && d.ayahNumber == 126),
        isTrue,
      );

      // 6. Category Filtering
      final forgivenessResults = repo.search(
        '',
        categoryFilter: 'المغفرة والتوبة',
      );
      expect(forgivenessResults.length, equals(20));
      expect(
        forgivenessResults.every((d) => d.category == 'المغفرة والتوبة'),
        isTrue,
      );

      // 7. Combined Search and Category
      final combined = repo.search('نوح', categoryFilter: 'المغفرة والتوبة');
      expect(combined.isNotEmpty, isTrue);

      // 8. Empty Search returns all 88
      expect(repo.search('').length, equals(88));
      expect(repo.search('   ').length, equals(88));

      // 9. Non-existent query returns empty
      expect(repo.search('كلمة غير موجودة بتاتا').isEmpty, isTrue);
    });

    test('Multi-Ayah Entries Breakdown and Number Sequencing Test', () {
      final repo = QuranDuasRepository.instance;
      final duas = repo.getDuas();

      final multiAyahDuas = duas.where((d) => d.isMultiAyah).toList();

      // Exactly 9 multi-ayah entries
      expect(
        multiAyahDuas.length,
        equals(9),
        reason: 'Exactly 9 entries in the catalog span multiple verses',
      );

      // Verify each multi-ayah entry
      for (final dua in multiAyahDuas) {
        final expectedCount = dua.ayahEndNumber - dua.ayahNumber + 1;
        expect(
          dua.verses.length,
          equals(expectedCount),
          reason:
              'Dua #${dua.id} (${dua.surahName} ${dua.ayahDisplay}) must have $expectedCount verses',
        );

        // Verify strictly sequential authentic Ayah numbers
        for (int i = 0; i < dua.verses.length; i++) {
          final expectedAyahNum = dua.ayahNumber + i;
          expect(
            dua.verses[i].ayahNumber,
            equals(expectedAyahNum),
            reason:
                'Verse at index $i must match authentic Ayah number $expectedAyahNum',
          );
          expect(
            dua.verses[i].text.isNotEmpty,
            isTrue,
            reason: 'Verse text must not be empty',
          );
          // Confirm diacritics are preserved (contains fathah, dammah, or kasrah)
          expect(
            dua.verses[i].text.contains(RegExp(r'[\u064B-\u0652]')),
            isTrue,
            reason: 'Verse text must preserve full diacritics',
          );
        }

        // Verify formatted text contains the authentic Ayah markers
        final formatted = dua.formattedTextWithMarkers;
        for (final v in dua.verses) {
          expect(
            formatted.contains(
              '﴿${ArabicSearchNormalizer.toArabicDigits(v.ayahNumber)}﴾',
            ),
            isTrue,
            reason:
                'Formatted text must include rosette marker for Ayah ${v.ayahNumber}',
          );
        }
      }
    });

    test('Single-Ayah Entries Invariant Verification', () {
      final repo = QuranDuasRepository.instance;
      final duas = repo.getDuas();

      final singleAyahDuas = duas.where((d) => !d.isMultiAyah).toList();
      expect(singleAyahDuas.length, equals(79));

      for (final dua in singleAyahDuas) {
        expect(dua.verses.length, equals(1));
        expect(dua.verses.first.ayahNumber, equals(dua.ayahNumber));
        expect(dua.verses.first.text, equals(dua.duaText));
        expect(dua.formattedTextWithMarkers, equals(dua.duaText));
      }
    });

    test('Search Finds Intermediate Verses in Multi-Ayah Entries', () {
      final repo = QuranDuasRepository.instance;

      // 1. Search intermediate Ayah 6 in Al-Fatihah (5-7)
      final fatihah6 = repo.search('6');
      expect(
        fatihah6.any((d) => d.surahNumber == 1 && d.ayahDisplay == '5–7'),
        isTrue,
      );

      final fatihah6Arabic = repo.search('٦');
      expect(
        fatihah6Arabic.any((d) => d.surahNumber == 1 && d.ayahDisplay == '5–7'),
        isTrue,
      );

      // 2. Search intermediate Ayah 192 and 193 in Aal-Imran (191-194)
      final imran192 = repo.search('192');
      expect(
        imran192.any((d) => d.surahNumber == 3 && d.ayahDisplay == '191–194'),
        isTrue,
      );

      final imran193 = repo.search('193');
      expect(
        imran193.any((d) => d.surahNumber == 3 && d.ayahDisplay == '191–194'),
        isTrue,
      );

      // 3. Search intermediate Ayah 27 in Ta-Ha (25-28)
      final taha27 = repo.search('27');
      expect(
        taha27.any((d) => d.surahNumber == 20 && d.ayahDisplay == '25–28'),
        isTrue,
      );

      // 4. Text Search inside intermediate verses
      final yusufSearch = repo.search('يَفْقَهُوا قَوْلِي');
      expect(
        yusufSearch.any((d) => d.surahNumber == 20 && d.ayahDisplay == '25–28'),
        isTrue,
      );

      final nasSearch = repo.search('مَلِكِ النَّاسِ');
      expect(
        nasSearch.any((d) => d.surahNumber == 114 && d.ayahDisplay == '1–6'),
        isTrue,
      );
    });
  });
}
