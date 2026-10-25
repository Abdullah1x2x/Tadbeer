part of 'user_data_store.dart';

/// AYAH LINKS (روابط الآيات)
mixin _AyahLinksSection on _StoreState {
  // ==========================================
  // AYAH LINKS (روابط الآيات)
  // ==========================================

  /// استرجاع رابط آيات محدد بواسطة معرفه الفريد.
  AyahLinkItem? getAyahLink(String id) {
    return _ayahLinks.where((l) => l.id == id).firstOrNull;
  }

  /// استرجاع جميع روابط الآيات التي تتضمن الآية المحددة.
  List<AyahLinkItem> getLinksForAyah(int surahNumber, int ayahNumber) {
    return _ayahLinks
        .where((l) => l.containsAyah(surahNumber, ayahNumber))
        .toList();
  }

  /// حفظ رابط آيات جديد أو تحديث رابط موجود.
  Future<void> saveAyahLink(AyahLinkItem link) async {
    final idx = _ayahLinks.indexWhere((l) => l.id == link.id);
    if (idx != -1) {
      _ayahLinks[idx] = link;
    } else {
      _ayahLinks.insert(0, link);
    }
    notifyListeners();
    final userDb = UserDatabase.instance;
    if (userDb.isOpen) {
      await userDb.insertOrUpdateAyahLink(link);
    }
    await saveToDisk();
  }

  /// حذف رابط آيات بواسطة معرفه الفريد.
  Future<void> deleteAyahLink(String id) async {
    _ayahLinks.removeWhere((l) => l.id == id);
    notifyListeners();
    final userDb = UserDatabase.instance;
    if (userDb.isOpen) {
      await userDb.deleteAyahLink(id);
    }
    await saveToDisk();
  }

  /// إضافة آية جديدة إلى رابط آيات قائم.
  Future<void> addVerseToLink(String linkId, AyahLinkVerse verse) async {
    final idx = _ayahLinks.indexWhere((l) => l.id == linkId);
    if (idx != -1) {
      final existing = _ayahLinks[idx];
      if (!existing.containsAyah(verse.surahNumber, verse.ayahNumber)) {
        final updatedVerses = [...existing.verses, verse];
        final updated = existing.copyWith(
          verses: updatedVerses,
          updatedAt: DateTime.now(),
        );
        _ayahLinks[idx] = updated;
        notifyListeners();
        final userDb = UserDatabase.instance;
        if (userDb.isOpen) {
          await userDb.insertOrUpdateAyahLink(updated);
        }
        await saveToDisk();
      }
    }
  }

  /// إزالة آية محددة من رابط آيات مع حذف إحداثياتها في المخطط الشبكي.
  Future<void> removeVerseFromLink(
    String linkId,
    int surahNumber,
    int ayahNumber,
  ) async {
    final idx = _ayahLinks.indexWhere((l) => l.id == linkId);
    if (idx != -1) {
      final existing = _ayahLinks[idx];
      final key = '$surahNumber:$ayahNumber';
      final updatedVerses = existing.verses
          .where((v) => v.ayahKey != key)
          .toList();
      final updatedPositions = Map<String, LinkNodePosition>.from(
        existing.positions,
      )..remove(key);
      final updated = existing.copyWith(
        verses: updatedVerses,
        positions: updatedPositions,
        updatedAt: DateTime.now(),
      );
      _ayahLinks[idx] = updated;
      notifyListeners();
      final userDb = UserDatabase.instance;
      if (userDb.isOpen) {
        await userDb.insertOrUpdateAyahLink(updated);
      }
      await saveToDisk();
    }
  }

  /// تحديث الملاحظة التدبرية الخاصة بآية داخل رابط آيات محدد.
  Future<void> updateVerseNote(
    String linkId,
    int surahNumber,
    int ayahNumber,
    String? note,
  ) async {
    final idx = _ayahLinks.indexWhere((l) => l.id == linkId);
    if (idx != -1) {
      final existing = _ayahLinks[idx];
      final key = '$surahNumber:$ayahNumber';
      final updatedVerses = existing.verses.map((v) {
        if (v.ayahKey == key) {
          return v.copyWith(note: note);
        }
        return v;
      }).toList();
      final updated = existing.copyWith(
        verses: updatedVerses,
        updatedAt: DateTime.now(),
      );
      _ayahLinks[idx] = updated;
      notifyListeners();
      final userDb = UserDatabase.instance;
      if (userDb.isOpen) {
        await userDb.insertOrUpdateAyahLink(updated);
      }
      await saveToDisk();
    }
  }

  /// تحديث إحداثيات عقد الآيات في العرض الشبكي لرابط الآيات.
  Future<void> updateLinkPositions(
    String linkId,
    Map<String, LinkNodePosition> positions,
    bool isManual,
  ) async {
    final idx = _ayahLinks.indexWhere((l) => l.id == linkId);
    if (idx != -1) {
      final existing = _ayahLinks[idx];
      final updated = existing.copyWith(
        positions: positions,
        isManualLayout: isManual,
        updatedAt: DateTime.now(),
      );
      _ayahLinks[idx] = updated;
      notifyListeners();
      final userDb = UserDatabase.instance;
      if (userDb.isOpen) {
        await userDb.insertOrUpdateAyahLink(updated);
      }
      await saveToDisk();
    }
  }

  /// حفظ حالة العرض والتقريب والإزاحة لشاشة رابط الآيات.
  Future<void> updateLinkViewState(
    String linkId, {
    String? viewMode,
    double? panX,
    double? panY,
    double? zoomScale,
  }) async {
    final idx = _ayahLinks.indexWhere((l) => l.id == linkId);
    if (idx != -1) {
      final existing = _ayahLinks[idx];
      final updated = existing.copyWith(
        lastViewMode: viewMode ?? existing.lastViewMode,
        panX: panX ?? existing.panX,
        panY: panY ?? existing.panY,
        zoomScale: zoomScale ?? existing.zoomScale,
        updatedAt: DateTime.now(),
      );
      _ayahLinks[idx] = updated;
      notifyListeners();
      final userDb = UserDatabase.instance;
      if (userDb.isOpen) {
        await userDb.insertOrUpdateAyahLink(updated);
      }
      await saveToDisk();
    }
  }
}
