part of 'user_data_store.dart';

/// READING POSITION
mixin _ReadingPositionSection on _StoreState {
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
  @override
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
}
