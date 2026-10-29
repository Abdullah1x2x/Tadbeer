part of 'user_data_store.dart';

/// Key of the reading journey in the `app_state` table.
const _journeyKey = 'reading_journey';

/// In-memory state shared by the store's sections.
///
/// Each section of [UserDataStore] lives in its own file as a mixin on this
/// class, so the data and the save path are defined once here.
/// What the store asks of the reminder scheduler when its reminders change.
///
/// The scheduler belongs to the reminders feature; main wires it in, so the
/// data layer never imports a feature. Left unset (as in tests), the store
/// simply schedules nothing.
abstract interface class ReminderScheduler {
  /// Replaces every scheduled reminder with [reminders].
  Future<void> syncAllReminders(List<ReminderItem> reminders);

  /// Cancels every scheduled reminder.
  Future<void> cancelAll();
}

abstract class _StoreState extends ChangeNotifier {
  bool _isInitialized = false;

  /// Schedules the reminders on the device; set once at startup.
  ReminderScheduler? reminderScheduler;

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

  ReadingJourney _journey = const ReadingJourney();

  /// رحلة القراءة: خطة الختمة وسجل الصفحات اليومية.
  ReadingJourney get journey => _journey;

  /// Small JSON state of other features (guided paths, memorization...),
  /// keyed by feature, stored in `app_state` and included in backups.
  final Map<String, Map<String, dynamic>> _featureState = {};

  /// حالة ميزة محفوظة بمفتاحها (فارغة إن لم تُحفظ بعد).
  Map<String, dynamic> featureState(String key) =>
      Map<String, dynamic>.from(_featureState[key] ?? const {});

  /// يحفظ حالة ميزة ويبلغ المستمعين.
  Future<void> saveFeatureState(String key, Map<String, dynamic> value) async {
    _featureState[key] = value;
    notifyListeners();
    await UserDatabase.instance.saveAppState(key, value);
    await saveToDisk();
  }

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

  /// يحفظ الحالة الحالية في ملف JSON احتياطي.
  Future<void> saveToDisk();

  // Implemented by other sections, declared here so sections can use each
  // other without depending on one another.

  /// حفظ موضع القراءة (قسم موضع القراءة).
  Future<void> saveReadingPosition({
    required int page,
    required int surahNumber,
    required int ayahNumber,
  });

  /// ملاحظات آية محددة (قسم الملاحظات).
  List<NoteItem> findNotesForAyah(int surahNumber, int ayahNumber);

  /// تسجيل يوم نشاط للأيام المتتالية (قسم رحلة القراءة).
  Future<void> markActiveDay({DateTime? now});

  /// نقل الختمة إلى موضع القراءة الجديد (قسم رحلة القراءة).
  Future<void> followReadingPosition(int page);
}
