import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tadbeer/data/storage/user_database.dart';
import 'package:tadbeer/data/models/user_settings_model.dart';
import 'package:tadbeer/data/models/ayah_link_model.dart';
import 'package:tadbeer/data/models/bookmark_model.dart';
import 'package:tadbeer/data/models/highlight_model.dart';
import 'package:tadbeer/data/models/note_model.dart';
import 'package:tadbeer/data/models/tadbeer_model.dart';
import 'package:tadbeer/data/quran/quran_models.dart';
import 'package:tadbeer/data/models/reminder_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late UserDatabase db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_sqlite_test_');
    db = UserDatabase.instance;
    await db.close();
    await db.init('${tempDir.path}/test_tadbeer.db');
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('UserDatabase SQLite Storage Tests', () {
    test('Reading Position Save and Load', () async {
      final pos = ReadingPosition(
        page: 45,
        surahNumber: 2,
        ayahNumber: 255,
        updatedAt: DateTime(2026, 10, 6),
      );
      await db.saveReadingPosition(pos);

      final loaded = await db.loadReadingPosition();
      expect(loaded, isNotNull);
      expect(loaded!.page, equals(45));
      expect(loaded.surahNumber, equals(2));
      expect(loaded.ayahNumber, equals(255));
    });

    test('Notes CRUD operations', () async {
      final note = NoteItem(
        id: 'note-sqlite-1',
        type: NoteType.ayah,
        content: 'تأمل في سورة الكهف',
        ayahId: 2141,
        surahNumber: 18,
        ayahNumber: 1,
        page: 293,
        ayahText:
            'الْحَمْدُ لِلَّهِ الَّذِي أَنزَلَ عَلَىٰ عَبْدِهِ الْكِتَابَ',
        title: 'افتتاحية الكهف',
        createdAt: DateTime(2026, 10, 6, 10),
        updatedAt: DateTime(2026, 10, 6, 10),
      );

      await db.insertOrUpdateNote(note);

      var notes = await db.loadNotes();
      expect(notes.length, equals(1));
      expect(notes.first.id, equals('note-sqlite-1'));
      expect(notes.first.title, equals('افتتاحية الكهف'));
      expect(notes.first.content, contains('تأمل'));

      // Delete note
      await db.deleteNote('note-sqlite-1');
      notes = await db.loadNotes();
      expect(notes.isEmpty, isTrue);
    });

    test('Bookmarks CRUD operations', () async {
      final bookmark = BookmarkItem(
        id: 'bm-1',
        ayahId: 100,
        surahNumber: 2,
        ayahNumber: 93,
        page: 14,
        createdAt: DateTime(2026, 10, 6),
      );
      await db.insertBookmark(bookmark);

      var bookmarks = await db.loadBookmarks();
      expect(bookmarks.length, equals(1));
      expect(bookmarks.first.ayahId, equals(100));

      await db.deleteBookmark('bm-1');
      bookmarks = await db.loadBookmarks();
      expect(bookmarks.isEmpty, isTrue);
    });

    test('Highlights CRUD operations', () async {
      final hl = HighlightItem(
        id: 'hl-1',
        ayahId: 255,
        surahNumber: 2,
        ayahNumber: 255,
        page: 42,
        colorIndex: 2,
        createdAt: DateTime(2026, 10, 6),
      );
      await db.insertOrUpdateHighlight(hl);

      var highlights = await db.loadHighlights();
      expect(highlights.length, equals(1));
      expect(highlights.first.colorIndex, equals(2));

      await db.deleteHighlight('hl-1');
      highlights = await db.loadHighlights();
      expect(highlights.isEmpty, isTrue);
    });

    test('Reminders CRUD operations', () async {
      final reminder = ReminderItem(
        id: 'rem-1',
        title: 'ورد الصباح',
        hour: 6,
        minute: 30,
        repeatMode: ReminderRepeatMode.daily,
        selectedDays: const [1, 2, 3, 4, 5, 6, 7],
        isEnabled: true,
        createdAt: DateTime(2026, 10, 6),
      );
      await db.insertOrUpdateReminder(reminder);

      var reminders = await db.loadReminders();
      expect(reminders.length, equals(1));
      expect(reminders.first.title, equals('ورد الصباح'));
      expect(reminders.first.selectedDays.length, equals(7));

      await db.deleteReminder('rem-1');
      reminders = await db.loadReminders();
      expect(reminders.isEmpty, isTrue);
    });

    test('Ayah Links CRUD operations', () async {
      final link = AyahLinkItem(
        id: 'link-1',
        title: 'آيات الاستغفار',
        description: 'روابط موضوعية لطلب المغفرة',
        verses: [
          AyahLinkVerse(
            ayahId: 135,
            surahNumber: 3,
            ayahNumber: 135,
            page: 67,
            addedAt: DateTime(2026, 10, 6),
          ),
          AyahLinkVerse(
            ayahId: 5400,
            surahNumber: 71,
            ayahNumber: 10,
            page: 570,
            addedAt: DateTime(2026, 10, 6),
          ),
        ],
        createdAt: DateTime(2026, 10, 6),
        updatedAt: DateTime(2026, 10, 6),
      );
      await db.insertOrUpdateAyahLink(link);

      var links = await db.loadAyahLinks();
      expect(links.length, equals(1));
      expect(links.first.verses.length, equals(2));

      await db.deleteAyahLink('link-1');
      links = await db.loadAyahLinks();
      expect(links.isEmpty, isTrue);
    });

    test('Tadbeer Answers CRUD operations', () async {
      final tadbeer = TadbeerItem(
        id: '1:1',
        surahNumber: 1,
        ayahNumber: 1,
        ayahId: 1,
        answers: const {
          1: 'بداية بالرحمة والإحسان',
          2: 'استشعار معيّة الله في كل عمل',
        },
        createdAt: DateTime(2026, 10, 6),
        updatedAt: DateTime(2026, 10, 6),
      );
      await db.insertOrUpdateTadbeer(tadbeer);

      var items = await db.loadTadbeerItems();
      expect(items.length, equals(1));
      expect(items.first.answers[1], equals('بداية بالرحمة والإحسان'));

      await db.deleteTadbeer('1:1');
      items = await db.loadTadbeerItems();
      expect(items.isEmpty, isTrue);
    });

    test('UserSettings Save and Load', () async {
      const settings = UserSettings(
        themeMode: ThemeMode.dark,
        languageCode: 'ar',
        hideTadbeerIntroPermanently: true,
      );
      await db.saveSettings(settings);

      final loaded = await db.loadSettings();
      expect(loaded, isNotNull);
      expect(loaded!.themeMode, equals(ThemeMode.dark));
      expect(loaded.hideTadabburIntroPermanently, isTrue);
    });

    test('Clear All User Data', () async {
      await db.saveReadingPosition(
        ReadingPosition(
          page: 1,
          surahNumber: 1,
          ayahNumber: 1,
          updatedAt: DateTime.now(),
        ),
      );
      await db.insertBookmark(
        BookmarkItem(
          id: 'bm-clear',
          ayahId: 1,
          surahNumber: 1,
          ayahNumber: 1,
          page: 1,
          createdAt: DateTime.now(),
        ),
      );

      await db.clearAllUserData();
      final pos = await db.loadReadingPosition();
      final bms = await db.loadBookmarks();
      expect(pos, isNull);
      expect(bms.isEmpty, isTrue);
    });

    test(
      'A corrupt row is skipped instead of hiding the whole table',
      () async {
        final now = DateTime(2026, 10, 1);
        await db.insertOrUpdateNote(
          NoteItem(
            id: 'good-note',
            type: NoteType.free,
            content: 'سليمة',
            createdAt: now,
            updatedAt: now,
          ),
        );
        // Simulate a damaged row written by a crash / disk issue.
        await db.db.insert('notes', {
          'id': 'broken-note',
          'type': 'free',
          'data': '{not valid json',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });

        db.lastIssue.value = null;
        final notes = await db.loadNotes();
        expect(notes.map((n) => n.id), equals(['good-note']));
        expect(
          db.lastIssue.value?.kind,
          equals(UserDatabaseIssueKind.corruptRowsSkipped),
        );

        // The damaged row is kept on disk (never silently deleted).
        final raw = await db.db.query('notes');
        expect(raw.length, equals(2));
      },
    );

    test('replaceAllUserData swaps all tables in one transaction', () async {
      final now = DateTime(2026, 10, 1);
      await db.insertBookmark(
        BookmarkItem(
          id: 'old-bm',
          ayahId: 1,
          surahNumber: 1,
          ayahNumber: 1,
          page: 1,
          createdAt: now,
        ),
      );

      final ok = await db.replaceAllUserData(
        readingPosition: ReadingPosition(
          page: 3,
          surahNumber: 2,
          ayahNumber: 10,
          updatedAt: now,
        ),
        notes: [
          NoteItem(
            id: 'new-note',
            type: NoteType.free,
            content: 'جديدة',
            createdAt: now,
            updatedAt: now,
          ),
        ],
        bookmarks: const [],
        highlights: const [],
        reminders: const [],
        ayahLinks: const [],
        tadbeerItems: const [],
        settings: const UserSettings(),
      );

      expect(ok, isTrue);
      expect((await db.loadBookmarks()).isEmpty, isTrue);
      expect((await db.loadNotes()).single.id, equals('new-note'));
      expect((await db.loadReadingPosition())!.page, equals(3));
    });
  });
}
