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

/// نوع المشكلة التي حدثت في قاعدة بيانات المستخدم.
enum UserDatabaseIssueKind {
  /// فشل قراءة جدول كامل.
  readFailed,

  /// فشل حفظ أو حذف بيانات.
  writeFailed,

  /// وُجدت صفوف تالفة وتم تخطيها أثناء التحميل (دون حذفها).
  corruptRowsSkipped,
}

/// وصف مشكلة في قاعدة البيانات لعرضها للمستخدم.
class UserDatabaseIssue {
  final UserDatabaseIssueKind kind;
  final String operation;
  final String error;
  final DateTime at;

  const UserDatabaseIssue({
    required this.kind,
    required this.operation,
    required this.error,
    required this.at,
  });
}

/// إدارة قاعدة بيانات SQLite لبيانات المستخدم (الملاحظات، الفواصل، روابط الآيات).
/// نصوص المصحف والكتب ثابتة ومخزنة كأصول للقراءة فقط لحمايتها وتسهيل النسخ الاحتياطي.
class UserDatabase {
  static final UserDatabase instance = UserDatabase._internal();
  UserDatabase._internal();

  static const String databaseFileName = 'tadbeer_user_data.db';
  static const int databaseVersion = 2;

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

  /// آخر مشكلة حدثت أثناء القراءة أو الكتابة، لتُعرض للمستخدم بدل ابتلاعها بصمت.
  ///
  /// Write failures and skipped corrupt rows are published here so the UI can
  /// tell the user instead of silently pretending everything was saved.
  final ValueNotifier<UserDatabaseIssue?> lastIssue =
      ValueNotifier<UserDatabaseIssue?>(null);

  void _reportIssue(
    UserDatabaseIssueKind kind,
    String operation,
    Object error,
  ) {
    debugPrint('UserDatabase.$operation [${kind.name}]: $error');
    lastIssue.value = UserDatabaseIssue(
      kind: kind,
      operation: operation,
      error: error.toString(),
      at: DateTime.now(),
    );
  }

  /// يفك ترميز صفوف الجدول صفاً صفاً، فيتخطى الصف التالف وحده بدلاً من
  /// إرجاع قائمة فارغة كاملة (وهو ما كان يُظهر كل البيانات كأنها حُذفت).
  /// الصفوف التالفة لا تُحذف من قاعدة البيانات.
  List<T> _decodeRows<T>(
    List<Map<String, Object?>> rows,
    T Function(Map<String, dynamic>) fromJson,
    String label,
  ) {
    final result = <T>[];
    final skippedIds = <Object?>[];
    for (final r in rows) {
      try {
        final data = jsonDecode(r['data'] as String) as Map<String, dynamic>;
        result.add(fromJson(data));
      } catch (e) {
        skippedIds.add(r['id']);
        debugPrint('UserDatabase: skipped corrupt $label row ${r['id']}: $e');
      }
    }
    if (skippedIds.isNotEmpty) {
      _reportIssue(
        UserDatabaseIssueKind.corruptRowsSkipped,
        'load$label',
        '${skippedIds.length} corrupt row(s) skipped: $skippedIds',
      );
    }
    return result;
  }

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
      await _createAppStateTable(db);
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

    // 9. Generic per-feature state (reading journey, ...)
    await _createAppStateTable(db);

    // 10. Composite Indexes for O(log N) Ayah Queries
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

  /// Key/value JSON store for feature state that has no table of its own.
  static Future<void> _createAppStateTable(DatabaseExecutor db) =>
      db.execute('''
        CREATE TABLE IF NOT EXISTS app_state (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');

  // ==================== APP STATE ====================

  /// تحميل حالة ميزة محفوظة كـ JSON بمفتاحها.
  Future<Map<String, dynamic>?> loadAppState(String key) async {
    if (!isOpen) return null;
    try {
      final rows = await db.query(
        'app_state',
        where: 'key = ?',
        whereArgs: [key],
      );
      if (rows.isEmpty) return null;
      return jsonDecode(rows.first['value'] as String) as Map<String, dynamic>;
    } catch (e) {
      _reportIssue(UserDatabaseIssueKind.readFailed, 'loadAppState', e);
      return null;
    }
  }

  /// تحميل كل حالات الميزات المحفوظة.
  Future<Map<String, Map<String, dynamic>>> loadAllAppState() async {
    if (!isOpen) return {};
    try {
      final rows = await db.query('app_state');
      return {
        for (final r in rows)
          r['key'] as String:
              jsonDecode(r['value'] as String) as Map<String, dynamic>,
      };
    } catch (e) {
      _reportIssue(UserDatabaseIssueKind.readFailed, 'loadAllAppState', e);
      return {};
    }
  }

  /// حفظ حالة ميزة كـ JSON بمفتاحها.
  Future<void> saveAppState(String key, Map<String, dynamic> value) async {
    if (!isOpen) return;
    try {
      await db.insert('app_state', {
        'key': key,
        'value': jsonEncode(value),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      _reportIssue(UserDatabaseIssueKind.writeFailed, 'saveAppState', e);
    }
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
      _reportIssue(UserDatabaseIssueKind.readFailed, 'loadReadingPosition', e);
      return null;
    }
  }

  /// حفظ أو تحديث آخر موضع قراءة للمستخدم في قاعدة البيانات.
  Future<void> saveReadingPosition(ReadingPosition position) async {
    if (!isOpen) return;
    try {
      await db.insert(
        'reading_position',
        _readingPositionRow(position),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      _reportIssue(UserDatabaseIssueKind.writeFailed, 'saveReadingPosition', e);
    }
  }

  // ==================== NOTES ====================

  /// استرجاع جميع ملاحظات وتأملات المستخدم مرتبة من الأحدث إلى الأقدم.
  Future<List<NoteItem>> loadNotes() async {
    if (!isOpen) return [];
    try {
      final rows = await db.query('notes', orderBy: 'updated_at DESC');
      return _decodeRows(rows, NoteItem.fromJson, 'NoteItem');
    } catch (e) {
      _reportIssue(UserDatabaseIssueKind.readFailed, 'loadNotes', e);
      return [];
    }
  }

  /// إدراج ملاحظة جديدة أو تحديث ملاحظة موجودة في جدول الملاحظات.
  Future<void> insertOrUpdateNote(NoteItem note) async {
    if (!isOpen) return;
    try {
      await db.insert(
        'notes',
        _noteRow(note),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      _reportIssue(UserDatabaseIssueKind.writeFailed, 'insertOrUpdateNote', e);
    }
  }

  /// حذف ملاحظة من قاعدة البيانات باستخدام معرفها الفريد.
  Future<void> deleteNote(String id) async {
    if (!isOpen) return;
    try {
      await db.delete('notes', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      _reportIssue(UserDatabaseIssueKind.writeFailed, 'deleteNote', e);
    }
  }

  // ==================== BOOKMARKS ====================

  /// تحميل جميع الآيات المحفوظة (الإشارات المرجعية) مرتبة تنازلياً حسب تاريخ الإضافة.
  Future<List<BookmarkItem>> loadBookmarks() async {
    if (!isOpen) return [];
    try {
      final rows = await db.query('bookmarks', orderBy: 'created_at DESC');
      return _decodeRows(rows, BookmarkItem.fromJson, 'BookmarkItem');
    } catch (e) {
      _reportIssue(UserDatabaseIssueKind.readFailed, 'loadBookmarks', e);
      return [];
    }
  }

  /// إدراج أو تحديث إشارة مرجعية لآية في قاعدة البيانات.
  Future<void> insertBookmark(BookmarkItem bookmark) async {
    if (!isOpen) return;
    try {
      await db.insert(
        'bookmarks',
        _bookmarkRow(bookmark),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      _reportIssue(UserDatabaseIssueKind.writeFailed, 'insertBookmark', e);
    }
  }

  /// حذف إشارة مرجعية من قاعدة البيانات بواسطة معرفها.
  Future<void> deleteBookmark(String id) async {
    if (!isOpen) return;
    try {
      await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      _reportIssue(UserDatabaseIssueKind.writeFailed, 'deleteBookmark', e);
    }
  }

  // ==================== HIGHLIGHTS ====================

  /// تحميل جميع تظليلات الآيات المحفوظة من قاعدة البيانات.
  Future<List<HighlightItem>> loadHighlights() async {
    if (!isOpen) return [];
    try {
      final rows = await db.query('highlights', orderBy: 'created_at DESC');
      return _decodeRows(rows, HighlightItem.fromJson, 'HighlightItem');
    } catch (e) {
      _reportIssue(UserDatabaseIssueKind.readFailed, 'loadHighlights', e);
      return [];
    }
  }

  /// إدراج أو تحديث تظليل لآية في جدول التظليلات.
  Future<void> insertOrUpdateHighlight(HighlightItem highlight) async {
    if (!isOpen) return;
    try {
      await db.insert(
        'highlights',
        _highlightRow(highlight),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      _reportIssue(
        UserDatabaseIssueKind.writeFailed,
        'insertOrUpdateHighlight',
        e,
      );
    }
  }

  /// حذف تظليل آية من قاعدة البيانات بواسطة معرفه.
  Future<void> deleteHighlight(String id) async {
    if (!isOpen) return;
    try {
      await db.delete('highlights', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      _reportIssue(UserDatabaseIssueKind.writeFailed, 'deleteHighlight', e);
    }
  }

  // ==================== REMINDERS ====================

  /// تحميل جميع تنبيهات ومنبهات الورد القرآني من قاعدة البيانات.
  Future<List<ReminderItem>> loadReminders() async {
    if (!isOpen) return [];
    try {
      final rows = await db.query('reminders', orderBy: 'created_at ASC');
      return _decodeRows(rows, ReminderItem.fromJson, 'ReminderItem');
    } catch (e) {
      _reportIssue(UserDatabaseIssueKind.readFailed, 'loadReminders', e);
      return [];
    }
  }

  /// إدراج أو تحديث تنبيه في جدول التنبيهات.
  Future<void> insertOrUpdateReminder(ReminderItem reminder) async {
    if (!isOpen) return;
    try {
      await db.insert(
        'reminders',
        _reminderRow(reminder),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      _reportIssue(
        UserDatabaseIssueKind.writeFailed,
        'insertOrUpdateReminder',
        e,
      );
    }
  }

  /// حذف تنبيه من قاعدة البيانات بواسطة معرفه.
  Future<void> deleteReminder(String id) async {
    if (!isOpen) return;
    try {
      await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      _reportIssue(UserDatabaseIssueKind.writeFailed, 'deleteReminder', e);
    }
  }

  // ==================== AYAH LINKS ====================

  /// تحميل جميع خرائط وروابط الآيات المحفوظة مرتبة من الأحدث إلى الأقدم.
  Future<List<AyahLinkItem>> loadAyahLinks() async {
    if (!isOpen) return [];
    try {
      final rows = await db.query('ayah_links', orderBy: 'updated_at DESC');
      return _decodeRows(rows, AyahLinkItem.fromJson, 'AyahLinkItem');
    } catch (e) {
      _reportIssue(UserDatabaseIssueKind.readFailed, 'loadAyahLinks', e);
      return [];
    }
  }

  /// إدراج أو تحديث رابط آيات في قاعدة البيانات.
  Future<void> insertOrUpdateAyahLink(AyahLinkItem link) async {
    if (!isOpen) return;
    try {
      await db.insert(
        'ayah_links',
        _ayahLinkRow(link),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      _reportIssue(
        UserDatabaseIssueKind.writeFailed,
        'insertOrUpdateAyahLink',
        e,
      );
    }
  }

  /// حذف رابط آيات من قاعدة البيانات بواسطة معرفه.
  Future<void> deleteAyahLink(String id) async {
    if (!isOpen) return;
    try {
      await db.delete('ayah_links', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      _reportIssue(UserDatabaseIssueKind.writeFailed, 'deleteAyahLink', e);
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
      return _decodeRows(rows, TadbeerItem.fromJson, 'TadbeerItem');
    } catch (e) {
      _reportIssue(UserDatabaseIssueKind.readFailed, 'loadTadbeerItems', e);
      return [];
    }
  }

  /// إدراج أو تحديث إجابات وقفة تدبر لآية محددة في قاعدة البيانات.
  Future<void> insertOrUpdateTadbeer(TadbeerItem item) async {
    if (!isOpen) return;
    try {
      final values = _tadbeerRow(item);
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
      _reportIssue(
        UserDatabaseIssueKind.writeFailed,
        'insertOrUpdateTadbeer',
        e,
      );
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
      _reportIssue(UserDatabaseIssueKind.writeFailed, 'deleteTadbeer', e);
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
      _reportIssue(UserDatabaseIssueKind.readFailed, 'loadSettings', e);
      return null;
    }
  }

  /// حفظ إعدادات المستخدم في جدول الإعدادات.
  Future<void> saveSettings(UserSettings settings) async {
    if (!isOpen) return;
    try {
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final row in _settingsRows(settings)) {
          batch.insert(
            'user_settings',
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
    } catch (e) {
      _reportIssue(UserDatabaseIssueKind.writeFailed, 'saveSettings', e);
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
      await db.delete('app_state');
      try {
        await db.delete('tadabbur_items');
      } catch (_) {}
      await db.delete('user_settings');
    } catch (e) {
      _reportIssue(UserDatabaseIssueKind.writeFailed, 'clearAllUserData', e);
    }
  }

  /// يستبدل كل بيانات المستخدم في معاملة واحدة (Transaction).
  ///
  /// Used by backup restore and JSON migration: either EVERYTHING is written,
  /// or (on any failure) the transaction is rolled back and the previous
  /// database content stays intact. Returns `false` on failure.
  Future<bool> replaceAllUserData({
    required ReadingPosition readingPosition,
    required List<NoteItem> notes,
    required List<BookmarkItem> bookmarks,
    required List<HighlightItem> highlights,
    required List<ReminderItem> reminders,
    required List<AyahLinkItem> ayahLinks,
    required List<TadbeerItem> tadbeerItems,
    required UserSettings settings,
  }) async {
    if (!isOpen) return false;
    try {
      await db.transaction((txn) async {
        // The legacy mirror table may be missing on some old installs.
        final legacy = await txn.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='tadabbur_items'",
        );
        final hasLegacyTable = legacy.isNotEmpty;

        for (final table in [
          'reading_position',
          'notes',
          'bookmarks',
          'highlights',
          'reminders',
          'ayah_links',
          'tadbeer_items',
          if (hasLegacyTable) 'tadabbur_items',
          'user_settings',
        ]) {
          await txn.delete(table);
        }

        final batch = txn.batch();
        const replace = ConflictAlgorithm.replace;
        batch.insert(
          'reading_position',
          _readingPositionRow(readingPosition),
          conflictAlgorithm: replace,
        );
        for (final n in notes) {
          batch.insert('notes', _noteRow(n), conflictAlgorithm: replace);
        }
        for (final b in bookmarks) {
          batch.insert(
            'bookmarks',
            _bookmarkRow(b),
            conflictAlgorithm: replace,
          );
        }
        for (final h in highlights) {
          batch.insert(
            'highlights',
            _highlightRow(h),
            conflictAlgorithm: replace,
          );
        }
        for (final r in reminders) {
          batch.insert(
            'reminders',
            _reminderRow(r),
            conflictAlgorithm: replace,
          );
        }
        for (final l in ayahLinks) {
          batch.insert(
            'ayah_links',
            _ayahLinkRow(l),
            conflictAlgorithm: replace,
          );
        }
        for (final t in tadbeerItems) {
          final row = _tadbeerRow(t);
          batch.insert('tadbeer_items', row, conflictAlgorithm: replace);
          if (hasLegacyTable) {
            batch.insert('tadabbur_items', row, conflictAlgorithm: replace);
          }
        }
        for (final row in _settingsRows(settings)) {
          batch.insert('user_settings', row, conflictAlgorithm: replace);
        }
        await batch.commit(noResult: true);
      });
      return true;
    } catch (e) {
      _reportIssue(UserDatabaseIssueKind.writeFailed, 'replaceAllUserData', e);
      return false;
    }
  }

  // ==================== ROW BUILDERS ====================

  static Map<String, Object?> _readingPositionRow(ReadingPosition p) => {
    'id': 1,
    'page': p.page,
    'surah_number': p.surahNumber,
    'ayah_number': p.ayahNumber,
    'data': jsonEncode(p.toJson()),
    'updated_at': p.updatedAt.toIso8601String(),
  };

  static Map<String, Object?> _noteRow(NoteItem note) => {
    'id': note.id,
    'type': note.type.name,
    'surah_number': note.surahNumber,
    'ayah_number': note.ayahNumber,
    'data': jsonEncode(note.toJson()),
    'created_at': note.createdAt.toIso8601String(),
    'updated_at': note.updatedAt.toIso8601String(),
  };

  static Map<String, Object?> _bookmarkRow(BookmarkItem b) => {
    'id': b.id,
    'surah_number': b.surahNumber,
    'ayah_number': b.ayahNumber,
    'data': jsonEncode(b.toJson()),
    'created_at': b.createdAt.toIso8601String(),
  };

  static Map<String, Object?> _highlightRow(HighlightItem h) => {
    'id': h.id,
    'surah_number': h.surahNumber,
    'ayah_number': h.ayahNumber,
    'color_index': h.colorIndex,
    'data': jsonEncode(h.toJson()),
    'created_at': h.createdAt.toIso8601String(),
  };

  static Map<String, Object?> _reminderRow(ReminderItem r) => {
    'id': r.id,
    'is_enabled': r.isEnabled ? 1 : 0,
    'data': jsonEncode(r.toJson()),
    'created_at': r.createdAt.toIso8601String(),
  };

  static Map<String, Object?> _ayahLinkRow(AyahLinkItem l) => {
    'id': l.id,
    'data': jsonEncode(l.toJson()),
    'created_at': l.createdAt.toIso8601String(),
    'updated_at': l.updatedAt.toIso8601String(),
  };

  static Map<String, Object?> _tadbeerRow(TadbeerItem t) => {
    'id': t.id,
    'surah_number': t.surahNumber,
    'ayah_number': t.ayahNumber,
    'data': jsonEncode(t.toJson()),
    'updated_at': t.updatedAt.toIso8601String(),
  };

  static List<Map<String, Object?>> _settingsRows(UserSettings settings) => [
    for (final entry in settings.toJson().entries)
      {'key': entry.key, 'value': jsonEncode(entry.value)},
  ];

  /// إغلاق اتصال قاعدة البيانات بأمان.
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}
