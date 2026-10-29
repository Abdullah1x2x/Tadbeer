part of 'user_data_store.dart';

/// قسم موضع القراءة.
mixin _ReadingPositionSection on _StoreState {
  /// يحفظ [position] موضعاً للقراءة.
  Future<void> setReadingPosition(ReadingPosition position) async {
    _readingPosition = position;
    notifyListeners();
    final userDb = UserDatabase.instance;
    if (userDb.isOpen) {
      await userDb.saveReadingPosition(position);
    }
    await saveToDisk();
  }

  /// يحفظ موضع القراءة من الصفحة والسورة والآية.
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
    // الختمة تتبع موضع القارئ.
    await followReadingPosition(page);
  }
}
