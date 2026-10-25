import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../features/ayah_links/ayah_link_model.dart';
import '../../features/bookmarks/bookmark_model.dart';
import '../../features/highlights/highlight_model.dart';
import '../../features/notes/note_model.dart';
import '../../features/quran/data/quran_models.dart';
import '../../features/tadbeer/tadbeer_model.dart';
import '../../features/reminders/reminder_model.dart';

import 'package:sqflite/sqflite.dart';

import 'user_database.dart';
import '../services/local_reminder_service.dart';
import '../../features/settings/user_settings_model.dart';

/// المنسق المركزي لإدارة وتخزين بيانات المستخدم محلياً في تطبيق تدبّر.
///
/// ملاحظة معمارية:
/// - نعتمد مبدأ Offline-First الكامل: لا ترسل أي بيانات لخادم خارجي إطلاقاً.
/// - نستخدم خرائط بحث في الذاكرة (In-memory HashMaps مثل `_bookmarkLookup` و `_highlightLookup`)
///   لتكون استعلامات حالة الآيات O(1) وفورية تماماً أثناء رسم صفحات المصحف دون استعلام SQLite في كل إطار.
/// - يتم حفظ التغييرات ذرياً (Atomic writes) لضمان عدم تلف البيانات عند إغلاق التطبيق فجأة.
class UserDataStore extends ChangeNotifier {
  static final UserDataStore instance = UserDataStore._internal();
  UserDataStore._internal();

  /// Current schema version for user data and backups.
  static const int currentSchemaVersion = 1;
  static const String fileName = 'tadbeer_user_data.json';

  bool _isInitialized = false;

  /// ما إذا كان مخزن بيانات المستخدم قد تمت تهيئته.
  bool get isInitialized => _isInitialized;

  ReadingPosition _readingPosition = ReadingPosition.defaultPosition();
  final List<NoteItem> _notes = [];
  final List<BookmarkItem> _bookmarks = [];
  final List<HighlightItem> _highlights = [];
  final List<ReminderItem> _reminders = [];
  final List<AyahLinkItem> _ayahLinks = [];
  final List<TadbeerItem> _tadbeerItems = [];
  UserSettings _settings = const UserSettings();
  final ValueNotifier<UserSettings> settingsNotifier =
      ValueNotifier<UserSettings>(const UserSettings());

  /// آخر موضع قراءة محفوظ للمستخدم.
  ReadingPosition get readingPosition => _readingPosition;

  /// قائمة جميع الملاحظات والخواطر غير القابلة للتعديل المباشر.
  List<NoteItem> get notes => List.unmodifiable(_notes);

  /// قائمة جميع الإشارات المرجعية (الآيات المحفوظة).
  List<BookmarkItem> get bookmarks => List.unmodifiable(_bookmarks);

  /// قائمة جميع تظليلات الآيات.
  List<HighlightItem> get highlights => List.unmodifiable(_highlights);

  /// قائمة جميع التنبيهات والمنبهات المجدولة.
  List<ReminderItem> get reminders => List.unmodifiable(_reminders);

  /// قائمة جميع روابط وخرائط الآيات.
  List<AyahLinkItem> get ayahLinks => List.unmodifiable(_ayahLinks);

  /// قائمة جميع إجابات وقفات التدبر المحفوظة.
  List<TadbeerItem> get tadbeerItems => List.unmodifiable(_tadbeerItems);

  /// إعدادات المستخدم الحالية.
  UserSettings get settings => _settings;

  // In-memory lookups for O(1) page rendering performance
  final Map<String, BookmarkItem> _bookmarkLookup = {};
  final Map<String, HighlightItem> _highlightLookup = {};
  final Map<String, TadbeerItem> _tadbeerLookup = {};

  File? _dataFile;

  /// Initializes the local storage engine.
  /// Accepts an optional [testFile] for deterministic, isolated unit tests.
  Future<void> init([File? testFile, String? testDbPath]) async {
    if (_isInitialized && testFile == null) return;

    final userDb = UserDatabase.instance;
    if (testFile != null) {
      _dataFile = testFile;
      _readingPosition = ReadingPosition.defaultPosition();
      _notes.clear();
      _bookmarks.clear();
      _bookmarkLookup.clear();
      _highlights.clear();
      _highlightLookup.clear();
      _reminders.clear();
      _ayahLinks.clear();
      _tadbeerItems.clear();
      _tadbeerLookup.clear();
      _settings = const UserSettings();
      settingsNotifier.value = _settings;

      final dbPath = testDbPath ?? inMemoryDatabasePath;
      await userDb.close();
      await userDb.init(dbPath);
    } else {
      final dir = await getApplicationDocumentsDirectory();
      _dataFile = File('${dir.path}/$fileName');
      await userDb.init();
    }

    if (userDb.isOpen) {
      final savedPos = await userDb.loadReadingPosition();
      if (savedPos != null) _readingPosition = savedPos;

      final dbNotes = await userDb.loadNotes();
      if (dbNotes.isNotEmpty) {
        _notes.clear();
        _notes.addAll(dbNotes);
      }

      final dbBookmarks = await userDb.loadBookmarks();
      if (dbBookmarks.isNotEmpty) {
        _bookmarks.clear();
        _bookmarkLookup.clear();
        for (final b in dbBookmarks) {
          _bookmarks.add(b);
          _bookmarkLookup[b.ayahKey] = b;
        }
      }

      final dbHighlights = await userDb.loadHighlights();
      if (dbHighlights.isNotEmpty) {
        _highlights.clear();
        _highlightLookup.clear();
        for (final h in dbHighlights) {
          _highlights.add(h);
          _highlightLookup[h.ayahKey] = h;
        }
      }

      final dbReminders = await userDb.loadReminders();
      if (dbReminders.isNotEmpty) {
        _reminders.clear();
        _reminders.addAll(dbReminders);
      }

      final dbLinks = await userDb.loadAyahLinks();
      if (dbLinks.isNotEmpty) {
        _ayahLinks.clear();
        _ayahLinks.addAll(dbLinks);
      }

      final dbTadbeer = await userDb.loadTadbeerItems();
      if (dbTadbeer.isNotEmpty) {
        _tadbeerItems.clear();
        _tadbeerLookup.clear();
        for (final t in dbTadbeer) {
          _tadbeerItems.add(t);
          _tadbeerLookup[t.ayahKey] = t;
        }
      }

      final dbSettings = await userDb.loadSettings();
      if (dbSettings != null) {
        _settings = dbSettings;
        settingsNotifier.value = dbSettings;
      }

      // Migrate from JSON file if SQLite was fresh but JSON file already exists
      if (_notes.isEmpty &&
          _bookmarks.isEmpty &&
          _highlights.isEmpty &&
          _dataFile != null &&
          await _dataFile!.exists()) {
        await _loadFromFile();
        await _persistAllToSQLite();
      }
    } else {
      await _loadFromFile();
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// قراءة بيانات المستخدم من ملف JSON المحلي عند الترحيل أو عدم توفر SQLite.
  Future<void> _loadFromFile() async {
    if (_dataFile == null || !await _dataFile!.exists()) {
      return;
    }

    try {
      final content = await _dataFile!.readAsString();
      if (content.trim().isEmpty) return;

      final data = jsonDecode(content) as Map<String, dynamic>;
      _applyData(data);
    } catch (e) {
      debugPrint('Error reading Tadbeer user data file: $e');
    }
  }

  /// تفريغ البيانات المستخرجة من خريطة JSON إلى القوائم والفهارس في الذاكرة.
  ///
  /// IMPORTANT: Only sections that are PRESENT in [data] are replaced.
  /// A partial backup (e.g. exported without notes) must never wipe the
  /// user's existing data for the sections it does not contain.
  ///
  /// Parsing happens into temporary collections first, so a malformed
  /// section throws before anything in memory is modified.
  void _applyData(Map<String, dynamic> data) {
    ReadingPosition? newPosition;
    if (data['readingPosition'] is Map) {
      newPosition = ReadingPosition.fromJson(
        Map<String, dynamic>.from(data['readingPosition'] as Map),
      );
    }

    List<NoteItem>? newNotes;
    if (data['notes'] is List) {
      final parsed = (data['notes'] as List)
          .map((n) => NoteItem.fromJson(Map<String, dynamic>.from(n as Map)))
          .toList();
      parsed.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      newNotes = parsed;
    }

    List<BookmarkItem>? newBookmarks;
    if (data['bookmarks'] is List) {
      newBookmarks = (data['bookmarks'] as List)
          .map(
            (b) => BookmarkItem.fromJson(Map<String, dynamic>.from(b as Map)),
          )
          .toList();
    }

    List<HighlightItem>? newHighlights;
    if (data['highlights'] is List) {
      newHighlights = (data['highlights'] as List)
          .map(
            (h) => HighlightItem.fromJson(Map<String, dynamic>.from(h as Map)),
          )
          .toList();
    }

    List<ReminderItem>? newReminders;
    if (data['reminders'] is List) {
      newReminders = (data['reminders'] as List)
          .map(
            (r) => ReminderItem.fromJson(Map<String, dynamic>.from(r as Map)),
          )
          .toList();
    }

    List<AyahLinkItem>? newLinks;
    if (data['ayahLinks'] is List) {
      final parsed = (data['ayahLinks'] as List)
          .map(
            (l) => AyahLinkItem.fromJson(Map<String, dynamic>.from(l as Map)),
          )
          .toList();
      parsed.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      newLinks = parsed;
    }

    List<TadbeerItem>? newTadbeer;
    final tadbeerData = data['tadbeer'] ?? data['tadabbur'];
    if (tadbeerData is List) {
      newTadbeer = tadbeerData
          .map(
            (t) => TadbeerItem.fromJson(Map<String, dynamic>.from(t as Map)),
          )
          .toList();
    }

    UserSettings? newSettings;
    if (data['settings'] is Map) {
      newSettings = UserSettings.fromJson(
        Map<String, dynamic>.from(data['settings'] as Map),
      );
    }

    // ---- Everything parsed successfully: apply present sections only ----
    if (newPosition != null) _readingPosition = newPosition;

    if (newNotes != null) {
      _notes
        ..clear()
        ..addAll(newNotes);
    }

    if (newBookmarks != null) {
      _bookmarks.clear();
      _bookmarkLookup.clear();
      for (final item in newBookmarks) {
        _bookmarks.add(item);
        _bookmarkLookup[item.ayahKey] = item;
      }
    }

    if (newHighlights != null) {
      _highlights.clear();
      _highlightLookup.clear();
      for (final item in newHighlights) {
        _highlights.add(item);
        _highlightLookup[item.ayahKey] = item;
      }
    }

    if (newReminders != null) {
      _reminders
        ..clear()
        ..addAll(newReminders);
    }

    if (newLinks != null) {
      _ayahLinks
        ..clear()
        ..addAll(newLinks);
    }

    if (newTadbeer != null) {
      _tadbeerItems.clear();
      _tadbeerLookup.clear();
      for (final item in newTadbeer) {
        _tadbeerItems.add(item);
        _tadbeerLookup[item.ayahKey] = item;
      }
    }

    if (newSettings != null) {
      _settings = newSettings;
      settingsNotifier.value = _settings;
    }
  }

  /// Persists all in-memory collections into the SQLite user database within
  /// a single atomic transaction (all-or-nothing). Returns `false` on failure.
  Future<bool> _persistAllToSQLite() async {
    final userDb = UserDatabase.instance;
    if (!userDb.isOpen) return false;
    return userDb.replaceAllUserData(
      readingPosition: _readingPosition,
      notes: _notes,
      bookmarks: _bookmarks,
      highlights: _highlights,
      reminders: _reminders,
      ayahLinks: _ayahLinks,
      tadbeerItems: _tadbeerItems,
      settings: _settings,
    );
  }

  /// Flushes current state to disk using an atomic JSON file pattern.
  Future<void> saveToDisk() async {
    if (_dataFile == null) return;

    try {
      final data = {
        'schemaVersion': currentSchemaVersion,
        'exportedAt': DateTime.now().toIso8601String(),
        'readingPosition': _readingPosition.toJson(),
        'notes': _notes.map((n) => n.toJson()).toList(),
        'bookmarks': _bookmarks.map((b) => b.toJson()).toList(),
        'highlights': _highlights.map((h) => h.toJson()).toList(),
        'reminders': _reminders.map((r) => r.toJson()).toList(),
        'ayahLinks': _ayahLinks.map((l) => l.toJson()).toList(),
        'tadbeer': _tadbeerItems.map((t) => t.toJson()).toList(),
        'tadabbur': _tadbeerItems.map((t) => t.toJson()).toList(),
        'settings': _settings.toJson(),
      };

      final jsonString = jsonEncode(data);

      final tempFile = File('${_dataFile!.path}.tmp');
      await tempFile.writeAsString(jsonString, flush: true);
      await tempFile.rename(_dataFile!.path);
    } catch (e) {
      debugPrint('UserDataStore.saveToDisk: $e');
    }
  }

  // ==========================================
  // READING POSITION
  // ==========================================

  /// تعيين كائن موضع القراءة الحالي وحفظه في قاعدة البيانات والقرص.
  Future<void> setReadingPosition(ReadingPosition position) async {
    _readingPosition = position;
    notifyListeners();
    final userDb = UserDatabase.instance;
    if (userDb.isOpen) {
      await userDb.saveReadingPosition(position);
    }
    await saveToDisk();
  }

  /// حفظ موضع القراءة الحالي باستخدام رقم الصفحة ورقم السورة ورقم الآية.
  Future<void> saveReadingPosition({
    required int page,
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final position = ReadingPosition(
      page: page,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      updatedAt: DateTime.now(),
    );
    await setReadingPosition(position);
  }

  // ==========================================
  // NOTES
  // ==========================================

  /// البحث عن جميع الملاحظات المرتبطة بآية محددة.
  List<NoteItem> findNotesForAyah(int surahNumber, int ayahNumber) {
    return _notes
        .where(
          (n) => n.surahNumber == surahNumber && n.ayahNumber == ayahNumber,
        )
        .toList();
  }

  /// استرجاع الملاحظات المرتبطة بآية محددة (مرادف لدالة البحث).
  List<NoteItem> getNotesForAyah(int surahNumber, int ayahNumber) {
    return findNotesForAyah(surahNumber, ayahNumber);
  }

  /// إضافة ملاحظة أو تحديثها في الذاكرة وقاعدة البيانات.
  Future<void> putNote(NoteItem note) async {
    final idx = _notes.indexWhere((n) => n.id == note.id);
    if (idx != -1) {
      _notes[idx] = note;
    } else {
      _notes.insert(0, note);
    }
    notifyListeners();
    final userDb = UserDatabase.instance;
    if (userDb.isOpen) {
      await userDb.insertOrUpdateNote(note);
    }
    await saveToDisk();
  }

  /// إنشاء ملاحظة جديدة أو تحديث ملاحظة قائمة وحفظها.
  Future<NoteItem> saveNote({
    String? id,
    required NoteType type,
    String? title,
    required String content,
    int? ayahId,
    int? surahNumber,
    int? ayahNumber,
    int? page,
    String? ayahText,
  }) async {
    final now = DateTime.now();

    if (id != null) {
      final existing = _notes.where((n) => n.id == id).firstOrNull;
      if (existing != null) {
        final updated = existing.copyWith(
          title: title,
          content: content,
          updatedAt: now,
        );
        await putNote(updated);
        return updated;
      }
    }

    final newNote = NoteItem(
      id: id ?? const Uuid().v4(),
      type: type,
      title: title,
      content: content,
      ayahId: ayahId,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      page: page,
      ayahText: ayahText,
      createdAt: now,
      updatedAt: now,
    );
    await putNote(newNote);
    return newNote;
  }

  /// إزالة ملاحظة من الذاكرة وقاعدة البيانات بواسطة معرفها.
  Future<void> removeNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
    final userDb = UserDatabase.instance;
    if (userDb.isOpen) {
      await userDb.deleteNote(id);
    }
    await saveToDisk();
  }

  /// حذف ملاحظة بواسطة معرفها.
  Future<void> deleteNote(String id) => removeNote(id);

  // ==========================================
  // BOOKMARKS
  // ==========================================

  /// التحقق الفوري مما إذا كانت الآية محفوظة في الإشارات المرجعية.
  bool hasBookmark(int surahNumber, int ayahNumber) {
    return _bookmarkLookup.containsKey('$surahNumber:$ayahNumber');
  }

  /// التحقق مما إذا كانت الآية محفوظة في الفواصل المرجعية.
  bool isBookmarked(int surahNumber, int ayahNumber) =>
      hasBookmark(surahNumber, ayahNumber);

  /// حفظ إشارة مرجعية في الذاكرة وقاعدة البيانات.
  Future<void> putBookmark(BookmarkItem bookmark) async {
    final idx = _bookmarks.indexWhere((b) => b.id == bookmark.id);
    if (idx != -1) {
      _bookmarks[idx] = bookmark;
    } else {
      _bookmarks.insert(0, bookmark);
    }
    _bookmarkLookup[bookmark.ayahKey] = bookmark;
    notifyListeners();
    final userDb = UserDatabase.instance;
    if (userDb.isOpen) {
      await userDb.insertBookmark(bookmark);
    }
    await saveToDisk();
  }

  /// تبديل حالة حفظ الآية (إضافة إشارة مرجعية أو إزالتها إن كانت موجودة).
  Future<bool> toggleBookmark(Ayah ayah) async {
    final currentlyBookmarked = hasBookmark(ayah.surahNumber, ayah.ayahNumber);
    if (currentlyBookmarked) {
      final existing = _bookmarks.firstWhere(
        (b) =>
            b.surahNumber == ayah.surahNumber &&
            b.ayahNumber == ayah.ayahNumber,
      );
      await removeBookmark(existing.id);
      return false;
    } else {
      final item = BookmarkItem(
        id: const Uuid().v4(),
        ayahId: ayah.id,
        surahNumber: ayah.surahNumber,
        ayahNumber: ayah.ayahNumber,
        page: ayah.page,
        createdAt: DateTime.now(),
      );
      await putBookmark(item);
      return true;
    }
  }

  /// إزالة إشارة مرجعية بواسطة معرفها الفريد.
  Future<void> removeBookmark(String id) async {
    final idx = _bookmarks.indexWhere((b) => b.id == id);
    if (idx != -1) {
      final item = _bookmarks.removeAt(idx);
      _bookmarkLookup.remove(item.ayahKey);
      notifyListeners();
      final userDb = UserDatabase.instance;
      if (userDb.isOpen) {
        await userDb.deleteBookmark(id);
      }
      await saveToDisk();
    }
  }

  // ==========================================
  // HIGHLIGHTS
  // ==========================================

  /// البحث الفوري عن تظليل الآية المحددة إن وُجد.
  HighlightItem? findHighlight(int surahNumber, int ayahNumber) {
    return _highlightLookup['$surahNumber:$ayahNumber'];
  }

  /// استرجاع تظليل الآية المحددة.
  HighlightItem? getHighlight(int surahNumber, int ayahNumber) =>
      findHighlight(surahNumber, ayahNumber);

  /// حفظ تظليل آية أو تحديث لونه في الذاكرة وقاعدة البيانات.
  Future<void> putHighlight(HighlightItem highlight) async {
    final key = highlight.ayahKey;
    final existing = _highlightLookup[key];
    if (existing != null) {
      final idx = _highlights.indexWhere((h) => h.id == existing.id);
      if (idx != -1) {
        _highlights[idx] = highlight;
      }
    } else {
      _highlights.insert(0, highlight);
    }
    _highlightLookup[key] = highlight;
    notifyListeners();
    final userDb = UserDatabase.instance;
    if (userDb.isOpen) {
      await userDb.insertOrUpdateHighlight(highlight);
    }
    await saveToDisk();
  }

  /// تعيين لون التظليل لآية محددة وحفظه.
  Future<void> setHighlight(Ayah ayah, int colorIndex) async {
    final existing = findHighlight(ayah.surahNumber, ayah.ayahNumber);
    final item = HighlightItem(
      id: existing?.id ?? const Uuid().v4(),
      ayahId: ayah.id,
      surahNumber: ayah.surahNumber,
      ayahNumber: ayah.ayahNumber,
      page: ayah.page,
      colorIndex: colorIndex,
      createdAt: DateTime.now(),
    );
    await putHighlight(item);
  }

  /// إزالة التظليل عن الآية المحددة.
  Future<void> removeHighlight(int surahNumber, int ayahNumber) async {
    final key = '$surahNumber:$ayahNumber';
    final existing = _highlightLookup.remove(key);
    if (existing != null) {
      _highlights.removeWhere((h) => h.id == existing.id);
      notifyListeners();
      final userDb = UserDatabase.instance;
      if (userDb.isOpen) {
        await userDb.deleteHighlight(existing.id);
      }
      await saveToDisk();
    }
  }

  // ==========================================
  // REMINDERS
  // ==========================================

  /// إضافة تنبيه جديد أو تحديث تنبيه موجود في الذاكرة وقاعدة البيانات.
  Future<void> putReminder(ReminderItem reminder) async {
    final idx = _reminders.indexWhere((r) => r.id == reminder.id);
    if (idx != -1) {
      _reminders[idx] = reminder;
    } else {
      _reminders.add(reminder);
    }
    notifyListeners();
    final userDb = UserDatabase.instance;
    if (userDb.isOpen) {
      await userDb.insertOrUpdateReminder(reminder);
    }
    await saveToDisk();
  }

  /// حذف تنبيه من الذاكرة وقاعدة البيانات بواسطة معرفه.
  Future<void> removeReminder(String id) async {
    _reminders.removeWhere((r) => r.id == id);
    notifyListeners();
    final userDb = UserDatabase.instance;
    if (userDb.isOpen) {
      await userDb.deleteReminder(id);
    }
    await saveToDisk();
  }

  // ==========================================
  // SETTINGS
  // ==========================================

  /// حفظ إعدادات المستخدم الجديدة وتحديث المستمعين وقاعدة البيانات.
  Future<void> putSettings(UserSettings newSettings) async {
    _settings = newSettings;
    settingsNotifier.value = newSettings;
    notifyListeners();
    final userDb = UserDatabase.instance;
    if (userDb.isOpen) {
      await userDb.saveSettings(newSettings);
    }
    await saveToDisk();
  }

  /// تحديث إعدادات المستخدم.
  Future<void> updateSettings(UserSettings newSettings) =>
      putSettings(newSettings);

  /// حجم خط المصحف المعتمد حالياً في الإعدادات.
  double get quranFontSize => _settings.quranFontSize;

  /// اسم عائلة خط المصحف المعتمدة حالياً في الإعدادات.
  String get quranFontFamily => _settings.quranFontFamilyName;

  /// تغيير حجم خط المصحف ضمن الحدود المسموحة وحفظه.
  Future<void> setQuranFontSize(double size) async {
    final clamped = size.clamp(
      UserSettings.minQuranFontSize,
      UserSettings.maxQuranFontSize,
    );
    await updateSettings(_settings.copyWith(quranFontSize: clamped));
  }

  /// تغيير نوع خط المصحف وحفظه في الإعدادات.
  Future<void> setQuranFontFamily(QuranFontFamilyOption fontFamily) async {
    await updateSettings(_settings.copyWith(quranFontFamily: fontFamily));
  }

  // ==========================================
  // AYAH LINKS (روابط الآيات)
  // ==========================================

  /// استرجاع رابط آيات محدد بواسطة معرفه الفريد.
  AyahLinkItem? getAyahLink(String id) {
    return _ayahLinks.where((l) => l.id == id).firstOrNull;
  }

  /// استرجاع جميع روابط الآيات التي تتضمن الآية المحددة.
  List<AyahLinkItem> getLinksForAyah(int surahNumber, int ayahNumber) {
    return _ayahLinks
        .where((l) => l.containsAyah(surahNumber, ayahNumber))
        .toList();
  }

  /// حفظ رابط آيات جديد أو تحديث رابط موجود.
  Future<void> saveAyahLink(AyahLinkItem link) async {
    final idx = _ayahLinks.indexWhere((l) => l.id == link.id);
    if (idx != -1) {
      _ayahLinks[idx] = link;
    } else {
      _ayahLinks.insert(0, link);
    }
    notifyListeners();
    final userDb = UserDatabase.instance;
    if (userDb.isOpen) {
      await userDb.insertOrUpdateAyahLink(link);
    }
    await saveToDisk();
  }

  /// حذف رابط آيات بواسطة معرفه الفريد.
  Future<void> deleteAyahLink(String id) async {
    _ayahLinks.removeWhere((l) => l.id == id);
    notifyListeners();
    final userDb = UserDatabase.instance;
    if (userDb.isOpen) {
      await userDb.deleteAyahLink(id);
    }
    await saveToDisk();
  }

  /// إضافة آية جديدة إلى رابط آيات قائم.
  Future<void> addVerseToLink(String linkId, AyahLinkVerse verse) async {
    final idx = _ayahLinks.indexWhere((l) => l.id == linkId);
    if (idx != -1) {
      final existing = _ayahLinks[idx];
      if (!existing.containsAyah(verse.surahNumber, verse.ayahNumber)) {
        final updatedVerses = [...existing.verses, verse];
        final updated = existing.copyWith(
          verses: updatedVerses,
          updatedAt: DateTime.now(),
        );
        _ayahLinks[idx] = updated;
        notifyListeners();
        final userDb = UserDatabase.instance;
        if (userDb.isOpen) {
          await userDb.insertOrUpdateAyahLink(updated);
        }
        await saveToDisk();
      }
    }
  }

  /// إزالة آية محددة من رابط آيات مع حذف إحداثياتها في المخطط الشبكي.
  Future<void> removeVerseFromLink(
    String linkId,
    int surahNumber,
    int ayahNumber,
  ) async {
    final idx = _ayahLinks.indexWhere((l) => l.id == linkId);
    if (idx != -1) {
      final existing = _ayahLinks[idx];
      final key = '$surahNumber:$ayahNumber';
      final updatedVerses = existing.verses
          .where((v) => v.ayahKey != key)
          .toList();
      final updatedPositions = Map<String, LinkNodePosition>.from(
        existing.positions,
      )..remove(key);
      final updated = existing.copyWith(
        verses: updatedVerses,
        positions: updatedPositions,
        updatedAt: DateTime.now(),
      );
      _ayahLinks[idx] = updated;
      notifyListeners();
      final userDb = UserDatabase.instance;
      if (userDb.isOpen) {
        await userDb.insertOrUpdateAyahLink(updated);
      }
      await saveToDisk();
    }
  }

  /// تحديث الملاحظة التدبرية الخاصة بآية داخل رابط آيات محدد.
  Future<void> updateVerseNote(
    String linkId,
    int surahNumber,
    int ayahNumber,
    String? note,
  ) async {
    final idx = _ayahLinks.indexWhere((l) => l.id == linkId);
    if (idx != -1) {
      final existing = _ayahLinks[idx];
      final key = '$surahNumber:$ayahNumber';
      final updatedVerses = existing.verses.map((v) {
        if (v.ayahKey == key) {
          return v.copyWith(note: note);
        }
        return v;
      }).toList();
      final updated = existing.copyWith(
        verses: updatedVerses,
        updatedAt: DateTime.now(),
      );
      _ayahLinks[idx] = updated;
      notifyListeners();
      final userDb = UserDatabase.instance;
      if (userDb.isOpen) {
        await userDb.insertOrUpdateAyahLink(updated);
      }
      await saveToDisk();
    }
  }

  /// تحديث إحداثيات عقد الآيات في العرض الشبكي لرابط الآيات.
  Future<void> updateLinkPositions(
    String linkId,
    Map<String, LinkNodePosition> positions,
    bool isManual,
  ) async {
    final idx = _ayahLinks.indexWhere((l) => l.id == linkId);
    if (idx != -1) {
      final existing = _ayahLinks[idx];
      final updated = existing.copyWith(
        positions: positions,
        isManualLayout: isManual,
        updatedAt: DateTime.now(),
      );
      _ayahLinks[idx] = updated;
      notifyListeners();
      final userDb = UserDatabase.instance;
      if (userDb.isOpen) {
        await userDb.insertOrUpdateAyahLink(updated);
      }
      await saveToDisk();
    }
  }

  /// حفظ حالة العرض والتقريب والإزاحة لشاشة رابط الآيات.
  Future<void> updateLinkViewState(
    String linkId, {
    String? viewMode,
    double? panX,
    double? panY,
    double? zoomScale,
  }) async {
    final idx = _ayahLinks.indexWhere((l) => l.id == linkId);
    if (idx != -1) {
      final existing = _ayahLinks[idx];
      final updated = existing.copyWith(
        lastViewMode: viewMode ?? existing.lastViewMode,
        panX: panX ?? existing.panX,
        panY: panY ?? existing.panY,
        zoomScale: zoomScale ?? existing.zoomScale,
        updatedAt: DateTime.now(),
      );
      _ayahLinks[idx] = updated;
      notifyListeners();
      final userDb = UserDatabase.instance;
      if (userDb.isOpen) {
        await userDb.insertOrUpdateAyahLink(updated);
      }
      await saveToDisk();
    }
  }

  // ==========================================
  // DATA INTEGRITY & RESET
  // ==========================================

  /// إعادة ضبط ومسح جميع بيانات المستخدم وإلغاء جميع المنبهات المجدولة.
  Future<void> resetAllData() async {
    _readingPosition = ReadingPosition.defaultPosition();
    _notes.clear();
    _bookmarks.clear();
    _bookmarkLookup.clear();
    _highlights.clear();
    _highlightLookup.clear();
    _reminders.clear();
    _ayahLinks.clear();
    _tadbeerItems.clear();
    _tadbeerLookup.clear();
    _settings = const UserSettings();
    settingsNotifier.value = _settings;
    notifyListeners();
    await LocalReminderService.instance.cancelAll();
    final userDb = UserDatabase.instance;
    if (userDb.isOpen) {
      await userDb.clearAllUserData();
    }
    await saveToDisk();
  }

  /// مسح جميع بيانات المستخدم وإعادتها للوضع الافتراضي.
  Future<void> resetAllUserData() => resetAllData();

  // ==========================================
  // TADBEER PAUSE (وقفة تدبر)
  // ==========================================

  /// استرجاع إجابات وقفة التدبر المحفوظة لآية محددة إن وُجدت.
  TadbeerItem? getTadbeer(int surahNumber, int ayahNumber) {
    return _tadbeerLookup['$surahNumber:$ayahNumber'];
  }

  /// Resolves the most relevant reflection note for an ayah across Notes & Tadbeer.
  String? getReflectionForAyah(int surahNumber, int ayahNumber) {
    final notes = findNotesForAyah(surahNumber, ayahNumber);
    if (notes.isNotEmpty && notes.first.content.trim().isNotEmpty) {
      return notes.first.content.trim();
    }
    final tadbeer = getTadbeer(surahNumber, ayahNumber);
    if (tadbeer != null && tadbeer.combinedSummary.isNotEmpty) {
      return tadbeer.combinedSummary;
    }
    return null;
  }

  /// حفظ إجابات أسئلة وقفة التدبر لآية محددة أو حذفها إن صارت فارغة.
  Future<void> saveTadbeer({
    required int surahNumber,
    required int ayahNumber,
    int? ayahId,
    required Map<int, String> answers,
  }) async {
    final cleanedAnswers = <int, String>{};
    answers.forEach((k, v) {
      final trimmed = v.trim();
      if (trimmed.isNotEmpty) {
        cleanedAnswers[k] = trimmed;
      }
    });

    final key = '$surahNumber:$ayahNumber';
    if (cleanedAnswers.isEmpty) {
      // Do not save empty responses; clean up if all were deleted
      final existing = _tadbeerLookup.remove(key);
      _tadbeerItems.removeWhere((t) => t.ayahKey == key);
      notifyListeners();
      final userDb = UserDatabase.instance;
      if (userDb.isOpen && existing != null) {
        await userDb.deleteTadbeer(existing.id);
      }
      await saveToDisk();
      return;
    }

    final now = DateTime.now();
    final existing = _tadbeerLookup[key];
    final item = TadbeerItem(
      id: existing?.id ?? const Uuid().v4(),
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      ayahId: ayahId ?? existing?.ayahId,
      answers: cleanedAnswers,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    final idx = _tadbeerItems.indexWhere((t) => t.ayahKey == key);
    if (idx != -1) {
      _tadbeerItems[idx] = item;
    } else {
      _tadbeerItems.add(item);
    }
    _tadbeerLookup[key] = item;

    notifyListeners();
    final userDb = UserDatabase.instance;
    if (userDb.isOpen) {
      await userDb.insertOrUpdateTadbeer(item);
    }
    await saveToDisk();
  }

  /// حذف إجابات وقفة التدبر المرتبطة بآية محددة.
  Future<void> deleteTadbeer(int surahNumber, int ayahNumber) async {
    final key = '$surahNumber:$ayahNumber';
    final existing = _tadbeerLookup.remove(key);
    _tadbeerItems.removeWhere((t) => t.ayahKey == key);
    notifyListeners();
    final userDb = UserDatabase.instance;
    if (userDb.isOpen && existing != null) {
      await userDb.deleteTadbeer(existing.id);
    }
    await saveToDisk();
  }

  // ==========================================
  // SNAPSHOT EXPORT / RESTORE
  // ==========================================

  /// تصدير لقطة كاملة أو مخصصة من بيانات المستخدم إلى خريطة JSON للنسخ الاحتياطي.
  Map<String, dynamic> exportSnapshot({
    bool notes = true,
    bool bookmarks = true,
    bool highlights = true,
    bool settings = true,
    bool reminders = true,
    bool ayahLinks = true,
    bool tadbeer = true,
    bool? tadabbur,
  }) {
    final includeTadbeer = tadabbur ?? tadbeer;
    return {
      'app': 'Tadbeer',
      'schemaVersion': currentSchemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'readingPosition': _readingPosition.toJson(),
      if (notes) 'notes': _notes.map((n) => n.toJson()).toList(),
      if (bookmarks) 'bookmarks': _bookmarks.map((b) => b.toJson()).toList(),
      if (highlights) 'highlights': _highlights.map((h) => h.toJson()).toList(),
      if (settings) 'settings': _settings.toJson(),
      if (reminders) 'reminders': _reminders.map((r) => r.toJson()).toList(),
      if (ayahLinks) 'ayahLinks': _ayahLinks.map((l) => l.toJson()).toList(),
      if (includeTadbeer) ...{
        'tadbeer': _tadbeerItems.map((t) => t.toJson()).toList(),
        'tadabbur': _tadbeerItems.map((t) => t.toJson()).toList(),
      },
    };
  }

  /// IMPORTANT:
  /// Restore replaces every section CONTAINED in [data] (never merges inside a
  /// section). Sections absent from [data] are left untouched.
  ///
  /// Throws [StateError] if the database could not be written; in that case
  /// the in-memory state is rolled back so nothing changes for the user.
  Future<void> replaceAllUserData(Map<String, dynamic> data) async {
    final previous = exportSnapshot();

    // Parses everything first: throws before modifying anything if invalid.
    _applyData(data);

    final userDb = UserDatabase.instance;
    if (userDb.isOpen) {
      final ok = await _persistAllToSQLite();
      if (!ok) {
        _applyData(previous); // roll back in-memory state
        notifyListeners();
        throw StateError('Could not write restored data to the database');
      }
    }

    notifyListeners();
    await saveToDisk();
    await LocalReminderService.instance.cancelAll();
    await LocalReminderService.instance.syncAllReminders(_reminders);
  }
}
