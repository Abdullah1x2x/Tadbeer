import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/ayah_link_model.dart';
import '../models/bookmark_model.dart';
import '../models/highlight_model.dart';
import '../models/reading_journey.dart';
import '../models/note_model.dart';
import '../quran/quran_models.dart';
import '../quran/quran_repository.dart';
import '../models/tadbeer_model.dart';
import '../models/reminder_model.dart';

import 'package:sqflite/sqflite.dart';

import 'user_database.dart';
import '../models/user_settings_model.dart';

part 'store_state.dart';
part 'reading_position_section.dart';
part 'notes_section.dart';
part 'bookmarks_section.dart';
part 'highlights_section.dart';
part 'reminders_section.dart';
part 'settings_section.dart';
part 'ayah_links_section.dart';
part 'journey_section.dart';
part 'tadbeer_section.dart';

/// المنسق المركزي لإدارة وتخزين بيانات المستخدم محلياً في تطبيق تدبّر.
///
/// ملاحظة معمارية:
/// - نعتمد مبدأ Offline-First الكامل: لا ترسل أي بيانات لخادم خارجي إطلاقاً.
/// - نستخدم خرائط بحث في الذاكرة (In-memory HashMaps مثل `_bookmarkLookup` و `_highlightLookup`)
///   لتكون استعلامات حالة الآيات O(1) وفورية تماماً أثناء رسم صفحات المصحف دون استعلام SQLite في كل إطار.
/// - يتم حفظ التغييرات ذرياً (Atomic writes) لضمان عدم تلف البيانات عند إغلاق التطبيق فجأة.
class UserDataStore extends _StoreState
    with
        _ReadingPositionSection,
        _NotesSection,
        _BookmarksSection,
        _HighlightsSection,
        _RemindersSection,
        _SettingsSection,
        _AyahLinksSection,
        _JourneySection,
        _TadbeerSection {
  static final UserDataStore instance = UserDataStore._internal();
  UserDataStore._internal();

  /// Current schema version for user data and backups.
  static const int currentSchemaVersion = 1;
  static const String fileName = 'tadbeer_user_data.json';

  /// Initializes the local storage engine.
  /// Accepts an optional [testFile] for deterministic, isolated unit tests.
  Future<void> init([File? testFile, String? testDbPath]) async {
    if (_isInitialized && testFile == null) return;

    final userDb = UserDatabase.instance;
    if (testFile != null) {
      _dataFile = testFile;
      _readingPosition = ReadingPosition.defaultPosition();
      _journey = const ReadingJourney();
      _featureState.clear();
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

      final appState = await userDb.loadAllAppState();
      final savedJourney = appState.remove(_journeyKey);
      if (savedJourney != null) {
        _journey = ReadingJourney.fromJson(savedJourney);
      }
      _featureState
        ..clear()
        ..addAll(appState);

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
          .map((t) => TadbeerItem.fromJson(Map<String, dynamic>.from(t as Map)))
          .toList();
    }

    Map<String, Map<String, dynamic>>? newFeatureState;
    if (data['featureState'] is Map) {
      newFeatureState = {
        for (final e in (data['featureState'] as Map).entries)
          e.key as String: Map<String, dynamic>.from(e.value as Map),
      };
    }

    ReadingJourney? newJourney;
    if (data['readingJourney'] is Map) {
      newJourney = ReadingJourney.fromJson(
        Map<String, dynamic>.from(data['readingJourney'] as Map),
      );
    }

    UserSettings? newSettings;
    if (data['settings'] is Map) {
      newSettings = UserSettings.fromJson(
        Map<String, dynamic>.from(data['settings'] as Map),
      );
    }

    // ---- Everything parsed successfully: apply present sections only ----
    if (newPosition != null) _readingPosition = newPosition;
    if (newJourney != null) _journey = newJourney;
    if (newFeatureState != null) {
      _featureState
        ..clear()
        ..addAll(newFeatureState);
    }

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
    await userDb.saveAppState(_journeyKey, _journey.toJson());
    for (final e in _featureState.entries) {
      await userDb.saveAppState(e.key, e.value);
    }
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
  @override
  Future<void> saveToDisk() async {
    if (_dataFile == null) return;

    try {
      final data = {
        'schemaVersion': currentSchemaVersion,
        'exportedAt': DateTime.now().toIso8601String(),
        'readingPosition': _readingPosition.toJson(),
        'readingJourney': _journey.toJson(),
        'featureState': _featureState,
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
  // DATA INTEGRITY & RESET
  // ==========================================

  /// إعادة ضبط ومسح جميع بيانات المستخدم وإلغاء جميع المنبهات المجدولة.
  Future<void> resetAllData() async {
    _readingPosition = ReadingPosition.defaultPosition();
    _journey = const ReadingJourney();
    _featureState.clear();
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
    await reminderScheduler?.cancelAll();
    final userDb = UserDatabase.instance;
    if (userDb.isOpen) {
      await userDb.clearAllUserData();
    }
    await saveToDisk();
  }

  /// مسح جميع بيانات المستخدم وإعادتها للوضع الافتراضي.
  Future<void> resetAllUserData() => resetAllData();

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
    bool journey = true,
  }) {
    final includeTadbeer = tadabbur ?? tadbeer;
    return {
      'app': 'Tadbeer',
      'schemaVersion': currentSchemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'readingPosition': _readingPosition.toJson(),
      if (journey) ...{
        'readingJourney': _journey.toJson(),
        // A copy, so the snapshot stays intact if the live state changes.
        'featureState': {
          for (final e in _featureState.entries)
            e.key: Map<String, dynamic>.from(e.value),
        },
      },
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
    await reminderScheduler?.cancelAll();
    await reminderScheduler?.syncAllReminders(_reminders);
  }
}
