part of 'user_data_store.dart';

/// REMINDERS
mixin _RemindersSection on _StoreState {
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
}
