import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common/utils/utils.dart' as sqflite_utils;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../features/ayah_links/ayah_link_model.dart';
import '../../features/bookmarks/bookmark_model.dart';
import '../../features/highlights/highlight_model.dart';
import '../../features/notes/note_model.dart';
import '../../features/tadbeer/tadbeer_model.dart';
import '../../features/quran/data/quran_models.dart';
import '../../features/reminders/reminder_model.dart';
import '../../features/settings/user_settings_model.dart';

/// إدارة قاعدة بيانات SQLite لبيانات المستخدم (الملاحظات، الفواصل، روابط الآيات).
/// نصوص المصحف والكتب ثابتة ومخزنة كأصول للقراءة فقط لحمايتها وتسهيل النسخ الاحتياطي.
class UserDatabase {
  static final UserDatabase instance = UserDatabase._internal();
  UserDatabase._internal();

  static const String databaseFileName = 'tadbeer_user_data.db';
  static const int databaseVersion = 1;

  Database? _database;

  /// إرجاع كائن قاعدة البيانات المفتوح حالياً أو رمي خطأ إذا لم تتم التهيئة.
  Database get db {
    if (_database == null) {
      throw StateError(
        'UserDatabase has not been initialized. Call init() first.',
      );
    }
    return _database!;
  }

  /// ما إذا كان اتصال قاعدة البيانات مفتوحاً وجاهزاً للاستخدام.
  bool get isOpen => _database != null && _database!.isOpen;

  /// Initializes the SQLite engine and opens the database.
  /// If [customPath] is provided (or in-memory path), it will be used.
  Future<void> init([String? customPath]) async {
    if (_database != null && _database!.isOpen) return;

    // Disable watchdog timer to prevent fake_async pending timer leaks during widget tests
    // ignore: deprecated_member_use
    sqflite_utils.lockWarningCallback = null;
    // ignore: deprecated_member_use
    sqflite_utils.lockWarningDuration = null;

    if (!kIsWeb &&
        (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final String path;
    if (customPath != null) {
      path = customPath;
    } else {
      final docDir = await getApplicationDocumentsDirectory();
      path = p.join(docDir.path, databaseFileName);
    }

    _database = await openDatabase(
      path,
      version: databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// ترقية مخطط قاعدة البيانات تدريجياً عند تحديث إصدار المخطط.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Progressive schema migrations
    if (oldVersion < 2) {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_ayah ON notes (surah_number, ayah_number)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_bookmarks_ayah ON bookmarks (surah_number, ayah_number)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_highlights_ayah ON highlights (surah_number, ayah_number)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_tadbeer_ayah ON tadbeer_items (surah_number, ayah_number)');
    }
  }

  /// Executes multiple database operations inside a single atomic SQLite transaction.
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    if (!isOpen) {
      throw StateError('Database is not open');
    }
    return await db.transaction(action);
  }

  /// إنشاء جميع جداول بيانات المستخدم والفهارس عند فتح قاعدة البيانات لأول مرة.
  Future<void> _onCreate(Database db, int version) async {
    // 1. Reading Position Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reading_position (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        page INTEGER NOT NULL,
        surah_number INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        data TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 2. Notes Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        surah_number INTEGER,
        ayah_number INTEGER,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 3. Bookmarks Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bookmarks (
        id TEXT PRIMARY KEY,
        surah_number INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 4. Highlights Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS highlights (
        id TEXT PRIMARY KEY,
        surah_number INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        color_index INTEGER NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 5. Reminders Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reminders (
        id TEXT PRIMARY KEY,
        is_enabled INTEGER NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 6. Verse Links (Ayah Links) Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ayah_links (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 7. Tadbeer Answers Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tadbeer_items (
        id TEXT PRIMARY KEY,
        surah_number INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        data TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tadabbur_items (
        id TEXT PRIMARY KEY,
        surah_number INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        data TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 8. User Settings Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // 9. Composite Indexes for O(log N) Ayah Queries
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_notes_ayah ON notes (surah_number, ayah_number)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_bookmarks_ayah ON bookmarks (surah_number, ayah_number)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_highlights_ayah ON highlights (surah_number, ayah_number)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tadbeer_ayah ON tadbeer_items (surah_number, ayah_number)',
    );
  }

  // ==================== READING POSITION ====================

  /// تحميل آخر موضع قراءة محفوظ للمستخدم من قاعدة البيانات.
  Future<ReadingPosition?> loadReadingPosition() async {
    if (!isOpen) return null;
    try {
      final rows = await db.query('reading_position', where: 'id = 1');
      if (rows.isEmpty) return null;
      final data =
          jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
      return ReadingPosition.fromJson(data);
    } catch (e) {
      debugPrint('UserDatabase.loadReadingPosition: $e');
      return null;
    }
  }

  /// حفظ أو تحديث آخر موضع قراءة للمستخدم في قاعدة البيانات.
  Future<void> saveReadingPosition(ReadingPosition position) async {
    if (!isOpen) return;
    try {
      await db.insert('reading_position', {
        'id': 1,
        'page': position.page,
        'surah_number': position.surahNumber,
        'ayah_number': position.ayahNumber,
        'data': jsonEncode(position.toJson()),
        'updated_at': position.updatedAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('UserDatabase.saveReadingPosition: $e');
    }
  }

  // ==================== NOTES ====================

  /// استرجاع جميع ملاحظات وتأملات المستخدم مرتبة من الأحدث إلى الأقدم.
  Future<List<NoteItem>> loadNotes() async {
    if (!isOpen) return [];
    try {
      final rows = await db.query('notes', orderBy: 'updated_at DESC');
      return rows.map((r) {
        final data = jsonDecode(r['data'] as String) as Map<String, dynamic>;
        return NoteItem.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('UserDatabase.loadNotes: $e');
      return [];
    }
  }

  /// إدراج ملاحظة جديدة أو تحديث ملاحظة موجودة في جدول الملاحظات.
  Future<void> insertOrUpdateNote(NoteItem note) async {
    if (!isOpen) return;
    try {
      await db.insert('notes', {
        'id': note.id,
        'type': note.type.name,
        'surah_number': note.surahNumber,
        'ayah_number': note.ayahNumber,
        'data': jsonEncode(note.toJson()),
        'created_at': note.createdAt.toIso8601String(),
        'updated_at': note.updatedAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('UserDatabase.insertOrUpdateNote: $e');
    }
  }

  /// حذف ملاحظة من قاعدة البيانات باستخدام معرفها الفريد.
  Future<void> deleteNote(String id) async {
    if (!isOpen) return;
    try {
      await db.delete('notes', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('UserDatabase.deleteNote: $e');
    }
  }

  // ==================== BOOKMARKS ====================

  /// تحميل جميع الآيات المحفوظة (الإشارات المرجعية) مرتبة تنازلياً حسب تاريخ الإضافة.
  Future<List<BookmarkItem>> loadBookmarks() async {
    if (!isOpen) return [];
    try {
      final rows = await db.query('bookmarks', orderBy: 'created_at DESC');
      return rows.map((r) {
        final data = jsonDecode(r['data'] as String) as Map<String, dynamic>;
        return BookmarkItem.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('UserDatabase.loadBookmarks: $e');
      return [];
    }
  }

  /// إدراج أو تحديث إشارة مرجعية لآية في قاعدة البيانات.
  Future<void> insertBookmark(BookmarkItem bookmark) async {
    if (!isOpen) return;
    try {
      await db.insert('bookmarks', {
        'id': bookmark.id,
        'surah_number': bookmark.surahNumber,
        'ayah_number': bookmark.ayahNumber,
        'data': jsonEncode(bookmark.toJson()),
        'created_at': bookmark.createdAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('UserDatabase.insertBookmark: $e');
    }
  }

  /// حذف إشارة مرجعية من قاعدة البيانات بواسطة معرفها.
  Future<void> deleteBookmark(String id) async {
    if (!isOpen) return;
    try {
      await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('UserDatabase.deleteBookmark: $e');
    }
  }

  // ==================== HIGHLIGHTS ====================

  /// تحميل جميع تظليلات الآيات المحفوظة من قاعدة البيانات.
  Future<List<HighlightItem>> loadHighlights() async {
    if (!isOpen) return [];
    try {
      final rows = await db.query('highlights', orderBy: 'created_at DESC');
      return rows.map((r) {
        final data = jsonDecode(r['data'] as String) as Map<String, dynamic>;
        return HighlightItem.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('UserDatabase.loadHighlights: $e');
      return [];
    }
  }

  /// إدراج أو تحديث تظليل لآية في جدول التظليلات.
  Future<void> insertOrUpdateHighlight(HighlightItem highlight) async {
    if (!isOpen) return;
    try {
      await db.insert('highlights', {
        'id': highlight.id,
        'surah_number': highlight.surahNumber,
        'ayah_number': highlight.ayahNumber,
        'color_index': highlight.colorIndex,
        'data': jsonEncode(highlight.toJson()),
        'created_at': highlight.createdAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('UserDatabase.insertOrUpdateHighlight: $e');
    }
  }

  /// حذف تظليل آية من قاعدة البيانات بواسطة معرفه.
  Future<void> deleteHighlight(String id) async {
    if (!isOpen) return;
    try {
      await db.delete('highlights', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('UserDatabase.deleteHighlight: $e');
    }
  }

  // ==================== REMINDERS ====================

  /// تحميل جميع تنبيهات ومنبهات الورد القرآني من قاعدة البيانات.
  Future<List<ReminderItem>> loadReminders() async {
    if (!isOpen) return [];
    try {
      final rows = await db.query('reminders', orderBy: 'created_at ASC');
      return rows.map((r) {
        final data = jsonDecode(r['data'] as String) as Map<String, dynamic>;
        return ReminderItem.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('UserDatabase.loadReminders: $e');
      return [];
    }
  }

  /// إدراج أو تحديث تنبيه في جدول التنبيهات.
  Future<void> insertOrUpdateReminder(ReminderItem reminder) async {
    if (!isOpen) return;
    try {
      await db.insert('reminders', {
        'id': reminder.id,
        'is_enabled': reminder.isEnabled ? 1 : 0,
        'data': jsonEncode(reminder.toJson()),
        'created_at': reminder.createdAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('UserDatabase.insertOrUpdateReminder: $e');
    }
  }

  /// حذف تنبيه من قاعدة البيانات بواسطة معرفه.
  Future<void> deleteReminder(String id) async {
    if (!isOpen) return;
    try {
      await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('UserDatabase.deleteReminder: $e');
    }
  }

  // ==================== AYAH LINKS ====================

  /// تحميل جميع خرائط وروابط الآيات المحفوظة مرتبة من الأحدث إلى الأقدم.
  Future<List<AyahLinkItem>> loadAyahLinks() async {
    if (!isOpen) return [];
    try {
      final rows = await db.query('ayah_links', orderBy: 'updated_at DESC');
      return rows.map((r) {
        final data = jsonDecode(r['data'] as String) as Map<String, dynamic>;
        return AyahLinkItem.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('UserDatabase.loadAyahLinks: $e');
      return [];
    }
  }

  /// إدراج أو تحديث رابط آيات في قاعدة البيانات.
  Future<void> insertOrUpdateAyahLink(AyahLinkItem link) async {
    if (!isOpen) return;
    try {
      await db.insert('ayah_links', {
        'id': link.id,
        'data': jsonEncode(link.toJson()),
        'created_at': link.createdAt.toIso8601String(),
        'updated_at': link.updatedAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('UserDatabase.insertOrUpdateAyahLink: $e');
    }
  }

  /// حذف رابط آيات من قاعدة البيانات بواسطة معرفه.
  Future<void> deleteAyahLink(String id) async {
    if (!isOpen) return;
    try {
      await db.delete('ayah_links', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('UserDatabase.deleteAyahLink: $e');
    }
  }

  // ==================== TADBEER ANSWERS ====================

  /// تحميل جميع إجابات وقفات التدبر المحفوظة مع دعم الجداول السابقة للتوافق.
  Future<List<TadbeerItem>> loadTadbeerItems() async {
    if (!isOpen) return [];
    try {
      var rows = await db.query('tadbeer_items', orderBy: 'updated_at DESC');
      if (rows.isEmpty) {
        final legacyRows = await db.query(
          'tadabbur_items',
          orderBy: 'updated_at DESC',
        );
        if (legacyRows.isNotEmpty) {
          rows = legacyRows;
        }
      }
      return rows.map((r) {
        final data = jsonDecode(r['data'] as String) as Map<String, dynamic>;
        return TadbeerItem.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('UserDatabase.loadTadbeerItems: $e');
      return [];
    }
  }

  /// إدراج أو تحديث إجابات وقفة تدبر لآية محددة في قاعدة البيانات.
  Future<void> insertOrUpdateTadbeer(TadbeerItem item) async {
    if (!isOpen) return;
    try {
      final values = {
        'id': item.id,
        'surah_number': item.surahNumber,
        'ayah_number': item.ayahNumber,
        'data': jsonEncode(item.toJson()),
        'updated_at': item.updatedAt.toIso8601String(),
      };
      await db.insert(
        'tadbeer_items',
        values,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      try {
        await db.insert(
          'tadabbur_items',
          values,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (_) {}
    } catch (e) {
      debugPrint('UserDatabase.insertOrUpdateTadbeer: $e');
    }
  }

  /// حذف إجابات وقفة تدبر من قاعدة البيانات بواسطة معرفها.
  Future<void> deleteTadbeer(String id) async {
    if (!isOpen) return;
    try {
      await db.delete('tadbeer_items', where: 'id = ?', whereArgs: [id]);
      try {
        await db.delete('tadabbur_items', where: 'id = ?', whereArgs: [id]);
      } catch (_) {}
    } catch (e) {
      debugPrint('UserDatabase.deleteTadbeer: $e');
    }
  }

  // ==================== USER SETTINGS ====================

  /// تحميل إعدادات المستخدم المفضلة (السمة، حجم ونوع الخط، اللغة) من قاعدة البيانات.
  Future<UserSettings?> loadSettings() async {
    if (!isOpen) return null;
    try {
      final rows = await db.query('user_settings');
      if (rows.isEmpty) return null;
      final map = <String, dynamic>{};
      for (final r in rows) {
        final key = r['key'] as String;
        final val = r['value'] as String;
        try {
          map[key] = jsonDecode(val);
        } catch (_) {
          map[key] = val;
        }
      }
      return UserSettings.fromJson(map);
    } catch (e) {
      debugPrint('UserDatabase.loadSettings: $e');
      return null;
    }
  }

  /// حفظ إعدادات المستخدم في جدول الإعدادات.
  Future<void> saveSettings(UserSettings settings) async {
    if (!isOpen) return;
    try {
      for (final entry in settings.toJson().entries) {
        await db.insert('user_settings', {
          'key': entry.key,
          'value': jsonEncode(entry.value),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e) {
      debugPrint('UserDatabase.saveSettings: $e');
    }
  }

  // ==================== FULL REPLACEMENT / RESTORE ====================

  /// مسح جميع بيانات المستخدم المخزنة في الجداول (عند إعادة الضبط أو استعادة نسخة احتياطية).
  Future<void> clearAllUserData() async {
    if (!isOpen) return;
    try {
      await db.delete('reading_position');
      await db.delete('notes');
      await db.delete('bookmarks');
      await db.delete('highlights');
      await db.delete('reminders');
      await db.delete('ayah_links');
      await db.delete('tadbeer_items');
      try {
        await db.delete('tadabbur_items');
      } catch (_) {}
      await db.delete('user_settings');
    } catch (e) {
      debugPrint('UserDatabase.clearAllUserData: $e');
    }
  }

  /// إغلاق اتصال قاعدة البيانات بأمان.
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}
