part of 'user_data_store.dart';

/// مفتاح رحلة القراءة في جدول `app_state`.
const _journeyKey = 'reading_journey';

/// ما يطلبه المخزن من مجدول التذكيرات حين تتغير التذكيرات.
/// المجدول جزء من ميزة التذكيرات ويربطه bootstrap، فلا تستورد طبقة البيانات أي ميزة. وإن لم يُربط (كما في الاختبارات) لا يُجدول شيء.
abstract interface class ReminderScheduler {
  /// يستبدل كل التذكيرات المجدولة بـ[reminders].
  Future<void> syncAllReminders(List<ReminderItem> reminders);

  /// يلغي كل التذكيرات المجدولة.
  Future<void> cancelAll();
}

/// الحالة المشتركة بين أقسام المخزن.
/// كل قسم من [UserDataStore] في ملف خاص به كـ mixin على هذا الكلاس، فتُعرّف البيانات وطريقة حفظها هنا مرة واحدة.
abstract class _StoreState extends ChangeNotifier {
  bool _isInitialized = false;

  /// يجدول التذكيرات على الجهاز؛ يُضبط مرة عند الإقلاع.
  ReminderScheduler? reminderScheduler;

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

  ReadingPosition get readingPosition => _readingPosition;

  ReadingJourney _journey = const ReadingJourney();

  /// رحلة القراءة: خطة الختمة وسجل الصفحات اليومية.
  ReadingJourney get journey => _journey;

  /// حالة صغيرة لميزات أخرى (المسارات، الحفظ…)، بمفتاح لكل ميزة؛ تُحفظ في `app_state` وتدخل في النسخ الاحتياطية.
  final Map<String, Map<String, dynamic>> _featureState = {};

  /// حالة الميزة [key]، فارغة إن لم تُحفظ بعد.
  Map<String, dynamic> featureState(String key) =>
      Map<String, dynamic>.from(_featureState[key] ?? const {});

  /// يحفظ حالة الميزة [key] ويُعلم المستمعين.
  Future<void> saveFeatureState(String key, Map<String, dynamic> value) async {
    _featureState[key] = value;
    notifyListeners();
    await UserDatabase.instance.saveAppState(key, value);
    await saveToDisk();
  }

  List<NoteItem> get notes => List.unmodifiable(_notes);

  List<BookmarkItem> get bookmarks => List.unmodifiable(_bookmarks);

  List<HighlightItem> get highlights => List.unmodifiable(_highlights);

  List<ReminderItem> get reminders => List.unmodifiable(_reminders);

  List<AyahLinkItem> get ayahLinks => List.unmodifiable(_ayahLinks);

  List<TadbeerItem> get tadbeerItems => List.unmodifiable(_tadbeerItems);

  UserSettings get settings => _settings;

  // فهارس في الذاكرة ليُسأل عن الآيات فوراً أثناء رسم الصفحات.
  final Map<String, BookmarkItem> _bookmarkLookup = {};
  final Map<String, HighlightItem> _highlightLookup = {};
  final Map<String, TadbeerItem> _tadbeerLookup = {};

  File? _dataFile;

  /// يحفظ الحالة في ملف JSON احتياطي.
  Future<void> saveToDisk();

  // تنفّذها أقسام أخرى، وتُعلن هنا ليستخدمها كل قسم دون أن يعتمد على غيره.

  /// يحفظ موضع القراءة (قسم موضع القراءة).
  Future<void> saveReadingPosition({
    required int page,
    required int surahNumber,
    required int ayahNumber,
  });

  /// خواطر آية محددة (قسم الملاحظات).
  List<NoteItem> findNotesForAyah(int surahNumber, int ayahNumber);

  /// يسجّل يوم نشاط في السلسلة (قسم رحلة القراءة).
  Future<void> markActiveDay({DateTime? now});

  /// ينقل الختمة إلى موضع القراءة الجديد (قسم رحلة القراءة).
  Future<void> followReadingPosition(int page);
}
