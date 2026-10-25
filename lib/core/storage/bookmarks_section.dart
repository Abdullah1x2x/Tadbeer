part of 'user_data_store.dart';

/// BOOKMARKS
mixin _BookmarksSection on _StoreState {
  // ==========================================
  // BOOKMARKS
  // ==========================================

  /// التحقق الفوري مما إذا كانت الآية محفوظة في الإشارات المرجعية.
  bool hasBookmark(int surahNumber, int ayahNumber) {
    return _bookmarkLookup.containsKey('$surahNumber:$ayahNumber');
  }

  /// التحقق مما إذا كانت الآية محفوظة في الفواصل المرجعية.
  bool isBookmarked(int surahNumber, int ayahNumber) =>
      hasBookmark(surahNumber, ayahNumber);

  /// حفظ إشارة مرجعية في الذاكرة وقاعدة البيانات.
  Future<void> putBookmark(BookmarkItem bookmark) async {
    final idx = _bookmarks.indexWhere((b) => b.id == bookmark.id);
    if (idx != -1) {
      _bookmarks[idx] = bookmark;
    } else {
      _bookmarks.insert(0, bookmark);
    }
    _bookmarkLookup[bookmark.ayahKey] = bookmark;
    notifyListeners();
    final userDb = UserDatabase.instance;
    if (userDb.isOpen) {
      await userDb.insertBookmark(bookmark);
    }
    await saveToDisk();
  }

  /// تبديل حالة حفظ الآية (إضافة إشارة مرجعية أو إزالتها إن كانت موجودة).
  Future<bool> toggleBookmark(Ayah ayah) async {
    final currentlyBookmarked = hasBookmark(ayah.surahNumber, ayah.ayahNumber);
    if (currentlyBookmarked) {
      final existing = _bookmarks.firstWhere(
        (b) =>
            b.surahNumber == ayah.surahNumber &&
            b.ayahNumber == ayah.ayahNumber,
      );
      await removeBookmark(existing.id);
      return false;
    } else {
      final item = BookmarkItem(
        id: const Uuid().v4(),
        ayahId: ayah.id,
        surahNumber: ayah.surahNumber,
        ayahNumber: ayah.ayahNumber,
        page: ayah.page,
        createdAt: DateTime.now(),
      );
      await putBookmark(item);
      return true;
    }
  }

  /// إزالة إشارة مرجعية بواسطة معرفها الفريد.
  Future<void> removeBookmark(String id) async {
    final idx = _bookmarks.indexWhere((b) => b.id == id);
    if (idx != -1) {
      final item = _bookmarks.removeAt(idx);
      _bookmarkLookup.remove(item.ayahKey);
      notifyListeners();
      final userDb = UserDatabase.instance;
      if (userDb.isOpen) {
        await userDb.deleteBookmark(id);
      }
      await saveToDisk();
    }
  }
}
