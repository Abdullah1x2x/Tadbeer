part of 'user_data_store.dart';

/// قسم الإعدادات.
mixin _SettingsSection on _StoreState {
  /// يحفظ [newSettings] ويُعلم المستمعين.
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

  /// الاسم القديم لـ[putSettings].
  Future<void> updateSettings(UserSettings newSettings) =>
      putSettings(newSettings);

  /// حجم خط المصحف من الإصدارات السابقة؛ المصحف اليوم يحدد حجمه من الشاشة، ويبقى هذا لتوافق النسخ الاحتياطية.
  double get quranFontSize => _settings.quranFontSize;

  String get quranFontFamily => _settings.quranFontFamilyName;

  /// يحفظ اسم القارئ، ويعيد جدولة التذكيرات لتناديه به.
  Future<void> setUserName(String name) async {
    final clean = name.trim();
    if (clean == _settings.userName) return;
    await updateSettings(_settings.copyWith(userName: clean));
    // الإشعارات المجدولة تحتفظ بنصها، فتُجدول من جديد.
    await reminderScheduler?.syncAllReminders(_reminders);
  }

  Future<void> setMushafStyle(MushafStyle style) async {
    await updateSettings(_settings.copyWith(mushafStyle: style));
  }

  Future<void> setQuranFontFamily(QuranFontFamilyOption fontFamily) async {
    await updateSettings(_settings.copyWith(quranFontFamily: fontFamily));
  }
}
