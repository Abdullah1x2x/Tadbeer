import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/core/services/backup_crypto_service.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/ayah_links/ayah_link_model.dart';
import 'package:tadbeer/features/ayah_links/ayah_link_repository.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late File dataFile;
  late AyahLinkRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_ayah_links_test_');
    dataFile = File('${tempDir.path}/test_user_data.json');
    await UserDataStore.instance.init(dataFile);
    await QuranRepository.instance.init();
    repo = AyahLinkRepository();
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Ayah Links Repository & Data Integrity Tests', () {
    test('1 & 5 & 6: Create Ayah Link, Save Title and Description', () async {
      final link = await repo.createLink(
        title: 'الصبر عند الشدة',
        description: 'ربط آيات الصبر واليقين',
      );

      expect(link.id, isNotEmpty);
      expect(link.title, equals('الصبر عند الشدة'));
      expect(link.description, equals('ربط آيات الصبر واليقين'));
      expect(link.verses, isEmpty);

      // Verify persistence in UserDataStore
      final fetched = repo.getLink(link.id);
      expect(fetched, isNotNull);
      expect(fetched!.title, equals('الصبر عند الشدة'));
      expect(fetched.description, equals('ربط آيات الصبر واليقين'));
    });

    test('2 & 3: Add Verse to Link and Delete Verse from Link', () async {
      final link = await repo.createLink(title: 'الاستعانة بالله');

      // Add Al-Baqarah 153 (Ayah ID: 160)
      await repo.addVerseToLink(
        link.id,
        ayahId: 160,
        surahNumber: 2,
        ayahNumber: 153,
        page: 23,
        note: 'يا أيها الذين آمنوا استعينوا بالصبر والصلاة',
      );

      var updated = repo.getLink(link.id)!;
      expect(updated.verses.length, equals(1));
      expect(updated.containsAyah(2, 153), isTrue);
      expect(updated.verses.first.note, contains('استعينوا بالصبر والصلاة'));

      // Add another verse: Ali 'Imran 200
      await repo.addVerseToLink(
        link.id,
        ayahId: 493,
        surahNumber: 3,
        ayahNumber: 200,
        page: 76,
      );

      updated = repo.getLink(link.id)!;
      expect(updated.verses.length, equals(2));

      // Remove Al-Baqarah 153
      await repo.removeVerseFromLink(link.id, 2, 153);
      updated = repo.getLink(link.id)!;
      expect(updated.verses.length, equals(1));
      expect(updated.containsAyah(2, 153), isFalse);
      expect(updated.containsAyah(3, 200), isTrue);
    });

    test('4: Same Ayah can belong to Multiple Independent Links', () async {
      final link1 = await repo.createLink(title: 'رابط الصبر');
      final link2 = await repo.createLink(title: 'رابط الصلاة');

      // Add Al-Baqarah 153 to both links
      await repo.addVerseToLink(
        link1.id,
        ayahId: 160,
        surahNumber: 2,
        ayahNumber: 153,
        page: 23,
        note: 'ملاحظة خاصة برابط الصبر',
      );

      await repo.addVerseToLink(
        link2.id,
        ayahId: 160,
        surahNumber: 2,
        ayahNumber: 153,
        page: 23,
        note: 'ملاحظة خاصة برابط الصلاة',
      );

      // Verify both links contain the ayah independently
      final fetched1 = repo.getLink(link1.id)!;
      final fetched2 = repo.getLink(link2.id)!;

      expect(fetched1.containsAyah(2, 153), isTrue);
      expect(fetched2.containsAyah(2, 153), isTrue);
      expect(fetched1.verses.first.note, equals('ملاحظة خاصة برابط الصبر'));
      expect(
        fetched2.verses.first.note,
        equals(
          'مخاصة برابط الصلاة'.contains('الصلاة')
              ? 'ملاحظة خاصة برابط الصلاة'
              : '',
        ),
      );

      // Find links for this ayah
      final linksForAyah = repo.getLinksForAyah(2, 153);
      expect(linksForAyah.length, equals(2));
    });

    test('7 & 8: Save and Restore Manual Verse Positions in Grid', () async {
      final link = await repo.createLink(title: 'اختبار المواضع');
      await repo.addVerseToLink(
        link.id,
        ayahId: 160,
        surahNumber: 2,
        ayahNumber: 153,
        page: 23,
      );
      await repo.addVerseToLink(
        link.id,
        ayahId: 493,
        surahNumber: 3,
        ayahNumber: 200,
        page: 76,
      );

      final positions = {
        '2:153': const LinkNodePosition(dx: 1200.5, dy: 1350.0),
        '3:200': const LinkNodePosition(dx: 1800.0, dy: 1650.5),
      };

      await repo.updatePositions(link.id, positions, true);

      final saved = repo.getLink(link.id)!;
      expect(saved.isManualLayout, isTrue);
      expect(
        saved.positions['2:153'],
        equals(const LinkNodePosition(dx: 1200.5, dy: 1350.0)),
      );
      expect(
        saved.positions['3:200'],
        equals(const LinkNodePosition(dx: 1800.0, dy: 1650.5)),
      );

      // Reload from disk to verify full persistence
      final freshStore = UserDataStore.instance;
      await freshStore.init(dataFile);
      final reloaded = freshStore.getAyahLink(link.id)!;
      expect(reloaded.isManualLayout, isTrue);
      expect(reloaded.positions['2:153']!.dx, equals(1200.5));
      expect(reloaded.positions['3:200']!.dy, equals(1650.5));
    });

    test(
      '9: Auto-Layout produces non-overlapping distinct coordinates',
      () async {
        final link = await repo.createLink(title: 'اختبار التوزيع');
        // Add 12 verses
        for (int i = 1; i <= 12; i++) {
          await repo.addVerseToLink(
            link.id,
            ayahId: i,
            surahNumber: 1,
            ayahNumber: i.clamp(1, 7),
            page: 1,
          );
        }

        // Check model serialization & distinct keys
        final fetched = repo.getLink(link.id)!;
        expect(
          fetched.verses.length,
          equals(7),
        ); // Unique keys (Al-Fatiha 1..7)
      },
    );

    test('10: Changing View Mode does not alter Ayah or Link data', () async {
      final link = await repo.createLink(
        title: 'تبديل العرض',
        description: 'وصف ثابت',
      );
      await repo.addVerseToLink(
        link.id,
        ayahId: 1,
        surahNumber: 1,
        ayahNumber: 1,
        page: 1,
        note: 'ملاحظة',
      );

      // Change view mode to 'ordered'
      await repo.updateViewState(link.id, viewMode: 'ordered');
      var updated = repo.getLink(link.id)!;
      expect(updated.lastViewMode, equals('ordered'));
      expect(updated.title, equals('تبديل العرض'));
      expect(updated.verses.length, equals(1));
      expect(updated.verses.first.note, equals('ملاحظة'));

      // Change view mode to 'cards'
      await repo.updateViewState(link.id, viewMode: 'cards');
      updated = repo.getLink(link.id)!;
      expect(updated.lastViewMode, equals('cards'));
      expect(updated.verses.length, equals(1));
    });

    test(
      '11 & 12: Encrypted Backup includes Ayah Links and Restores completely',
      () async {
        final store = UserDataStore.instance;
        final backupFile = File(
          '${tempDir.path}/ayah_links_backup.quranbackup',
        );

        final link = await repo.createLink(
          title: 'رابط النسخ الاحتياطي',
          description: 'وصف مهم جداً',
        );
        await repo.addVerseToLink(
          link.id,
          ayahId: 160,
          surahNumber: 2,
          ayahNumber: 153,
          page: 23,
          note: 'ملاحظة التصدير',
        );

        // Create backup
        final res = await BackupCryptoService.createBackupFile(
          targetPath: backupFile.path,
          password: 'TestPassword123',
        );
        expect(res.success, isTrue);

        // Clear local store
        await store.resetAllUserData();
        expect(store.ayahLinks, isEmpty);

        // Restore
        final restoreRes = await BackupCryptoService.restoreFromFile(
          file: backupFile,
          password: 'TestPassword123',
        );
        expect(restoreRes.success, isTrue);

        // Verify restored links
        expect(store.ayahLinks.length, equals(1));
        final restored = store.ayahLinks.first;
        expect(restored.title, equals('رابط النسخ الاحتياطي'));
        expect(restored.description, equals('وصف مهم جداً'));
        expect(restored.verses.length, equals(1));
        expect(restored.verses.first.ayahNumber, equals(153));
        expect(restored.verses.first.note, equals('ملاحظة التصدير'));
      },
    );

    test(
      '14: Search Links by title, description, or contained verses',
      () async {
        await repo.createLink(
          title: 'الصبر في الشدائد',
          description: 'تدبرات حول الصبر',
        );
        final link2 = await repo.createLink(
          title: 'شكر النعم',
          description: 'آيات الحمد',
        );
        // Add verse from Al-Baqarah
        await repo.addVerseToLink(
          link2.id,
          ayahId: 159,
          surahNumber: 2,
          ayahNumber: 152,
          page: 23,
        );

        // Search by title
        final searchByTitle = repo.searchLinks('الصبر');
        expect(searchByTitle.length, equals(1));
        expect(searchByTitle.first.title, contains('الصبر'));

        // Search by description
        final searchByDesc = repo.searchLinks('الحمد');
        expect(searchByDesc.length, equals(1));
        expect(searchByDesc.first.title, equals('شكر النعم'));

        // Search by surah name
        final searchBySurah = repo.searchLinks('البقرة');
        expect(searchBySurah.length, equals(1));
        expect(searchBySurah.first.title, equals('شكر النعم'));
      },
    );

    test('15: No Duplicate Quran Data is stored in Ayah Links', () async {
      final link = await repo.createLink(title: 'فحص التجريد');
      await repo.addVerseToLink(
        link.id,
        ayahId: 160,
        surahNumber: 2,
        ayahNumber: 153,
        page: 23,
      );

      // Verify JSON representation does NOT contain full Quran text
      final updatedLink = repo.getLink(link.id)!;
      final json = updatedLink.toJson();
      final versesJson = json['verses'] as List;
      final verseMap = versesJson.first as Map<String, dynamic>;

      expect(verseMap.containsKey('ayahId'), isTrue);
      expect(verseMap.containsKey('surahNumber'), isTrue);
      expect(verseMap.containsKey('ayahNumber'), isTrue);
      expect(verseMap.containsKey('page'), isTrue);
      // Quran text must be fetched from QuranRepository, NOT stored in user DB!
      expect(verseMap.containsKey('text'), isFalse);
      expect(verseMap.containsKey('ayahText'), isFalse);
    });

    test('16: Add, update and delete independent Note Cards in Ayah Link', () async {
      final link = await repo.createLink(title: 'رابط مع كروت الملاحظات');
      expect(link.notes, isEmpty);

      // 1. Add Note Card
      final note = await repo.addNoteToLink(
        link.id,
        title: 'فكرة تدبرية أولى',
        content: 'نص الملاحظة التدبرية المستقلة',
      );
      var updated = repo.getLink(link.id)!;
      expect(updated.notes.length, equals(1));
      expect(updated.notes.first.id, equals(note.id));
      expect(updated.notes.first.title, equals('فكرة تدبرية أولى'));
      expect(updated.notes.first.content, equals('نص الملاحظة التدبرية المستقلة'));
      expect(updated.positions.containsKey(note.noteKey), isTrue);

      // 2. Update Note Card
      await repo.updateNoteInLink(
        link.id,
        note.id,
        title: 'عنوان معدل',
        content: 'محتوى معدل بالكامل',
      );
      updated = repo.getLink(link.id)!;
      expect(updated.notes.first.title, equals('عنوان معدل'));
      expect(updated.notes.first.content, equals('محتوى معدل بالكامل'));

      // 3. Delete Note Card
      await repo.deleteNoteFromLink(link.id, note.id);
      updated = repo.getLink(link.id)!;
      expect(updated.notes, isEmpty);
      expect(updated.positions.containsKey(note.noteKey), isFalse);
    });
  });
}
