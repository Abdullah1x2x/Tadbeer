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
}
