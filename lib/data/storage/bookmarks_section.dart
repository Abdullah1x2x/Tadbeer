part of 'user_data_store.dart';

/// قسم الفواصل.
mixin _BookmarksSection on _StoreState {
  /// هل الآية محفوظة في الفواصل؛ فوري من الفهرس.
  bool isBookmarked(int surahNumber, int ayahNumber) {
    return _bookmarkLookup.containsKey('$surahNumber:$ayahNumber');
  }

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

  /// يضيف الفاصل أو يحذفه، ويعيد true إن صارت الآية محفوظة.
  Future<bool> toggleBookmark(Ayah ayah) async {
    final currentlyBookmarked = isBookmarked(ayah.surahNumber, ayah.ayahNumber);
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
