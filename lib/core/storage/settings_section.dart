part of 'user_data_store.dart';

/// SETTINGS
mixin _SettingsSection on _StoreState {
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

  /// حجم خط المصحف المحفوظ من الإصدارات السابقة؛ المصحف اليوم يحدد حجمه
  /// تلقائياً من الشاشة، ويبقى هذا لتوافق النسخ الاحتياطية.
  double get quranFontSize => _settings.quranFontSize;

  /// اسم عائلة خط المصحف المعتمدة حالياً في الإعدادات.
  String get quranFontFamily => _settings.quranFontFamilyName;

  /// حفظ اسم القارئ وإعادة جدولة التذكيرات لتناديه به.
  Future<void> setUserName(String name) async {
    final clean = name.trim();
    if (clean == _settings.userName) return;
    await updateSettings(_settings.copyWith(userName: clean));
    // Scheduled notifications keep the text they were given; redo them.
    await LocalReminderService.instance.syncAllReminders(_reminders);
  }

  /// تغيير طريقة عرض المصحف وحفظها.
  Future<void> setMushafStyle(MushafStyle style) async {
    await updateSettings(_settings.copyWith(mushafStyle: style));
  }

  /// تغيير نوع خط المصحف وحفظه في الإعدادات.
  Future<void> setQuranFontFamily(QuranFontFamilyOption fontFamily) async {
    await updateSettings(_settings.copyWith(quranFontFamily: fontFamily));
  }
}
