part of 'user_data_store.dart';

/// HIGHLIGHTS
mixin _HighlightsSection on _StoreState {
  // ==========================================
  // HIGHLIGHTS
  // ==========================================

  /// البحث الفوري عن تظليل الآية المحددة إن وُجد.
  HighlightItem? findHighlight(int surahNumber, int ayahNumber) {
    return _highlightLookup['$surahNumber:$ayahNumber'];
  }

  /// استرجاع تظليل الآية المحددة.
  HighlightItem? getHighlight(int surahNumber, int ayahNumber) =>
      findHighlight(surahNumber, ayahNumber);

  /// حفظ تظليل آية أو تحديث لونه في الذاكرة وقاعدة البيانات.
  Future<void> putHighlight(HighlightItem highlight) async {
    final key = highlight.ayahKey;
    final existing = _highlightLookup[key];
    if (existing != null) {
      final idx = _highlights.indexWhere((h) => h.id == existing.id);
      if (idx != -1) {
        _highlights[idx] = highlight;
      }
    } else {
      _highlights.insert(0, highlight);
    }
    _highlightLookup[key] = highlight;
    notifyListeners();
    final userDb = UserDatabase.instance;
    if (userDb.isOpen) {
      await userDb.insertOrUpdateHighlight(highlight);
    }
    await saveToDisk();
  }

  /// تعيين لون التظليل لآية محددة وحفظه.
  Future<void> setHighlight(Ayah ayah, int colorIndex) async {
    final existing = findHighlight(ayah.surahNumber, ayah.ayahNumber);
    final item = HighlightItem(
      id: existing?.id ?? const Uuid().v4(),
      ayahId: ayah.id,
      surahNumber: ayah.surahNumber,
      ayahNumber: ayah.ayahNumber,
      page: ayah.page,
      colorIndex: colorIndex,
      createdAt: DateTime.now(),
    );
    await putHighlight(item);
  }

  /// إزالة التظليل عن الآية المحددة.
  Future<void> removeHighlight(int surahNumber, int ayahNumber) async {
    final key = '$surahNumber:$ayahNumber';
    final existing = _highlightLookup.remove(key);
    if (existing != null) {
      _highlights.removeWhere((h) => h.id == existing.id);
      notifyListeners();
      final userDb = UserDatabase.instance;
      if (userDb.isOpen) {
        await userDb.deleteHighlight(existing.id);
      }
      await saveToDisk();
    }
  }
}
