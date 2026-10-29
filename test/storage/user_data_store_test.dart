import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/data/storage/user_database.dart';
import 'package:tadbeer/data/models/note_model.dart';
import 'package:tadbeer/data/quran/quran_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late File testFile;
  late UserDataStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_store_test_');
    testFile = File('${tempDir.path}/test_user_data.json');
    store = UserDataStore.instance;
    await store.init(testFile);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('UserDataStore Unit Tests', () {
    test('Reading Position Save and Persistence', () async {
      await store.saveReadingPosition(
        page: 25,
        surahNumber: 2,
        ayahNumber: 142,
      );
      expect(store.readingPosition.page, equals(25));
      expect(store.readingPosition.surahNumber, equals(2));
      expect(store.readingPosition.ayahNumber, equals(142));

      // Verify file persistence
      expect(testFile.existsSync(), isTrue);
      final content = testFile.readAsStringSync();
      expect(content, contains('"page":25'));
    });

    test('Notes CRUD and Ayah Linkage', () async {
      // 1. Create Ayah Note
      await store.saveNote(
        id: 'note-ayah-1',
        type: NoteType.ayah,
        content: 'تدبر عظيم في سورة الفاتحة',
        ayahId: 1,
        surahNumber: 1,
        ayahNumber: 1,
        page: 1,
        ayahText: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
      );

      expect(store.notes.length, equals(1));
      expect(store.notes.first.isAyahNote, isTrue);
      expect(store.notes.first.surahNumber, equals(1));

      // 2. Create Free Note
      await store.saveNote(
        id: 'note-free-1',
        type: NoteType.free,
        title: 'خاطرة صباحية',
        content: 'عن أهمية القرآن في حياة المسلم',
      );

      expect(store.notes.length, equals(2));
      expect(store.notes.first.id, equals('note-free-1')); // newest first

      // 3. Update Note
      await store.saveNote(
        id: 'note-free-1',
        type: NoteType.free,
        title: 'خاطرة صباحية محدثة',
        content: 'محتوى جديد',
      );

      expect(store.notes.first.title, equals('خاطرة صباحية محدثة'));

      // 4. Delete Note
      await store.deleteNote('note-free-1');
      expect(store.notes.length, equals(1));
      expect(store.notes.first.id, equals('note-ayah-1'));

      // 5. Verify SQLite persistence
      final dbNotes = await UserDatabase.instance.loadNotes();
      expect(dbNotes.length, equals(1));
      expect(dbNotes.first.id, equals('note-ayah-1'));
    });

    test('Bookmarks Toggle and Removal', () async {
      const ayah = Ayah(
        id: 7,
        surahNumber: 1,
        ayahNumber: 7,
        text: 'صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ',
        rawText: 'صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ',
        page: 1,
        juz: 1,
        hizb: 1,
        quarter: 1,
      );

      expect(store.isBookmarked(1, 7), isFalse);

      // Add bookmark
      await store.toggleBookmark(ayah);
      expect(store.isBookmarked(1, 7), isTrue);
      expect(store.bookmarks.length, equals(1));

      // Toggle off bookmark
      await store.toggleBookmark(ayah);
      expect(store.isBookmarked(1, 7), isFalse);
      expect(store.bookmarks.isEmpty, isTrue);
    });

    test('Highlights Set, Update Color, and Removal', () async {
      const ayah = Ayah(
        id: 255,
        surahNumber: 2,
        ayahNumber: 255,
        text: 'ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ ٱلْحَىُّ ٱلْقَيُّومُ',
        rawText: 'ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ ٱلْحَىُّ ٱلْقَيُّومُ',
        page: 42,
        juz: 3,
        hizb: 5,
        quarter: 17,
      );

      // Add highlight (color 0)
      await store.setHighlight(ayah, 0);
      expect(store.getHighlight(2, 255)?.colorIndex, equals(0));

      // Change highlight color (color 2)
      await store.setHighlight(ayah, 2);
      expect(store.getHighlight(2, 255)?.colorIndex, equals(2));

      // Remove highlight
      await store.removeHighlight(2, 255);
      expect(store.getHighlight(2, 255), isNull);
    });

    test('Settings Update and Persistence', () async {
      final updated = store.settings.copyWith(
        themeMode: ThemeMode.dark,
        languageCode: 'en',
        hideTadbeerIntroPermanently: true,
        quranFontSize: 28.0,
      );

      await store.updateSettings(updated);
      expect(store.settings.themeMode, equals(ThemeMode.dark));
      expect(store.settings.languageCode, equals('en'));
      expect(store.settings.hideTadbeerIntroPermanently, isTrue);
      expect(store.settings.quranFontSize, equals(28.0));
    });
  });
}
