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

/// مخزن بيانات القارئ على الجهاز، ومصدرها الوحيد في التطبيق.
///
/// يحفظ في SQLite، ويبقي في الذاكرة فهارس للفواصل والتظليل فتُسأل أثناء رسم
/// المصحف دون استعلام كل إطار. الحفظ ذرّي، فلا تتلف البيانات إن أُغلق التطبيق
/// فجأة.
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

  /// إصدار بنية البيانات في التخزين والنسخ الاحتياطية.
  static const int currentSchemaVersion = 1;
  static const String fileName = 'tadbeer_user_data.json';

  /// يفتح التخزين ويحمّل البيانات؛ [testFile] و[testDbPath] لعزل الاختبارات.
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

      // ترحيل من ملف JSON القديم إن كانت قاعدة SQLite جديدة وفارغة.
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

  /// يقرأ البيانات من ملف JSON، عند الترحيل أو حين لا تتوفر SQLite.
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

  /// يضع بيانات [data] في الذاكرة.
  ///
  /// لا يستبدل إلا الأقسام الموجودة في [data]، فنسخة احتياطية جزئية لا تمسح ما
  /// ليس فيها. ويقرأ كل شيء أولاً، فقسم تالف يرمي خطأ قبل أن يتغير أي شيء.
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

    // قُرئ كل شيء بنجاح: نطبّق الأقسام الموجودة فقط.
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

  /// يكتب كل البيانات في SQLite في معاملة واحدة (كلها أو لا شيء)، ويعيد false
  /// عند الفشل.
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

  /// يكتب الحالة في ملف JSON بكتابة ذرّية.
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

  /// يمسح كل بيانات القارئ ويلغي التذكيرات المجدولة.
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

  /// لقطة من بيانات القارئ للنسخ الاحتياطي، كاملة أو لأقسام مختارة.
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
        // نسخة، فلا تتغير اللقطة إن تغيّرت الحالة الحية.
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

  /// يستعيد نسخة احتياطية: يستبدل كل قسم موجود في [data] كاملاً، ويترك الأقسام
  /// الغائبة.
  ///
  /// يرمي [StateError] إن فشلت الكتابة في قاعدة البيانات، وتعود الذاكرة كما
  /// كانت فلا يتغير شيء.
  Future<void> replaceAllUserData(Map<String, dynamic> data) async {
    final previous = exportSnapshot();

    // يقرأ كل شيء أولاً: يرمي خطأ قبل أي تعديل إن كانت البيانات غير صالحة.
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
