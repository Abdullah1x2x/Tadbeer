part of 'user_data_store.dart';

/// قسم روابط الآيات.
mixin _AyahLinksSection on _StoreState {
  AyahLinkItem? getAyahLink(String id) {
    return _ayahLinks.where((l) => l.id == id).firstOrNull;
  }

  /// الروابط التي تضم الآية.
  List<AyahLinkItem> getLinksForAyah(int surahNumber, int ayahNumber) {
    return _ayahLinks
        .where((l) => l.containsAyah(surahNumber, ayahNumber))
        .toList();
  }

  /// يحفظ رابطاً جديداً أو يعدّله.
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
  }

  Future<void> deleteAyahLink(String id) async {
    _ayahLinks.removeWhere((l) => l.id == id);
    notifyListeners();
    final userDb = UserDatabase.instance;
    if (userDb.isOpen) {
      await userDb.deleteAyahLink(id);
    }
  }

  /// يضيف آية (أو نطاق آيات) إلى رابط.
  Future<void> addVerseToLink(String linkId, AyahLinkVerse verse) async {
    final idx = _ayahLinks.indexWhere((l) => l.id == linkId);
    if (idx != -1) {
      final existing = _ayahLinks[idx];
      final isAlready = existing.verses.any((v) => v.ayahKey == verse.ayahKey);
      if (!isAlready) {
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
      }
    }
  }

  /// يضيف عدة آيات دفعة واحدة إلى رابط.
  Future<void> addVersesToLink(String linkId, List<AyahLinkVerse> verses) async {
    if (verses.isEmpty) return;
    final idx = _ayahLinks.indexWhere((l) => l.id == linkId);
    if (idx != -1) {
      final existing = _ayahLinks[idx];
      final newVerses = <AyahLinkVerse>[...existing.verses];
      for (final v in verses) {
        if (!newVerses.any((ev) => ev.ayahKey == v.ayahKey)) {
          newVerses.add(v);
        }
      }
      final updated = existing.copyWith(
        verses: newVerses,
        updatedAt: DateTime.now(),
      );
      _ayahLinks[idx] = updated;
      notifyListeners();
      final userDb = UserDatabase.instance;
      if (userDb.isOpen) {
        await userDb.insertOrUpdateAyahLink(updated);
      }
    }
  }

  /// يغيّر موضع بطاقة آية في القائمة المرتبة (تقديم أو تأخير).
  Future<void> reorderVerseInLink(
    String linkId,
    int oldIndex,
    int newIndex,
  ) async {
    final idx = _ayahLinks.indexWhere((l) => l.id == linkId);
    if (idx != -1) {
      final existing = _ayahLinks[idx];
      final verses = List<AyahLinkVerse>.from(existing.verses);
      if (oldIndex < 0 || oldIndex >= verses.length) return;
      if (newIndex < 0 || newIndex >= verses.length) return;
      final item = verses.removeAt(oldIndex);
      verses.insert(newIndex, item);
      final updated = existing.copyWith(
        verses: verses,
        updatedAt: DateTime.now(),
      );
      _ayahLinks[idx] = updated;
      notifyListeners();
      final userDb = UserDatabase.instance;
      if (userDb.isOpen) {
        await userDb.insertOrUpdateAyahLink(updated);
      }
    }
  }

  /// يغيّر ترتيب بطاقة خاطرة داخل الرابط.
  Future<void> reorderNoteInLink(
    String linkId,
    int oldIndex,
    int newIndex,
  ) async {
    final idx = _ayahLinks.indexWhere((l) => l.id == linkId);
    if (idx != -1) {
      final existing = _ayahLinks[idx];
      final notes = List<AyahLinkNote>.from(existing.notes);
      if (oldIndex < 0 || oldIndex >= notes.length) return;
      if (newIndex < 0 || newIndex >= notes.length) return;
      final item = notes.removeAt(oldIndex);
      notes.insert(newIndex, item);
      final updated = existing.copyWith(
        notes: notes,
        updatedAt: DateTime.now(),
      );
      _ayahLinks[idx] = updated;
      notifyListeners();
      final userDb = UserDatabase.instance;
      if (userDb.isOpen) {
        await userDb.insertOrUpdateAyahLink(updated);
      }
    }
  }

  /// يزيل آية من رابط، مع موضعها على الشبكة.
  Future<void> removeVerseFromLink(
    String linkId,
    int surahNumber,
    int ayahNumber, [
    int? toAyahNumber,
    String? verseId,
  ]) async {
    final idx = _ayahLinks.indexWhere((l) => l.id == linkId);
    if (idx != -1) {
      final existing = _ayahLinks[idx];
      final targetKey = (toAyahNumber != null && toAyahNumber > ayahNumber)
          ? '$surahNumber:$ayahNumber-$toAyahNumber'
          : '$surahNumber:$ayahNumber';
      final updatedVerses = existing.verses.where((v) {
        if (verseId != null) {
          return v.id != verseId;
        }
        return v.ayahKey != targetKey &&
            !(toAyahNumber == null &&
                v.surahNumber == surahNumber &&
                v.ayahNumber == ayahNumber);
      }).toList();
      final removeKey = verseId ?? targetKey;
      final updatedPositions = Map<String, LinkNodePosition>.from(
        existing.positions,
      )..remove(removeKey);
      final updated = existing.copyWith(
        verses: updatedVerses,
        positions: updatedPositions,
        relationships: existing.relationships
            .where((r) => r.fromAyahKey != removeKey && r.toAyahKey != removeKey)
            .toList(),
        updatedAt: DateTime.now(),
      );
      _ayahLinks[idx] = updated;
      notifyListeners();
      final userDb = UserDatabase.instance;
      if (userDb.isOpen) {
        await userDb.insertOrUpdateAyahLink(updated);
      }
    }
  }

  /// يعدّل خاطرة آية داخل رابط.
  Future<void> updateVerseNote(
    String linkId,
    int surahNumber,
    int ayahNumber,
    String? note, [
    String? verseId,
  ]) async {
    final idx = _ayahLinks.indexWhere((l) => l.id == linkId);
    if (idx != -1) {
      final existing = _ayahLinks[idx];
      final key = '$surahNumber:$ayahNumber';
      var found = false;
      final updatedVerses = existing.verses.map((v) {
        if (verseId != null) {
          if (v.id == verseId) {
            return v.copyWith(note: note);
          }
          return v;
        }
        if (!found && v.ayahKey == key) {
          found = true;
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
    }
  }

  /// يحفظ مواضع العقد على الشبكة.
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
    }
  }

  /// يحفظ لون بطاقة في الشبكة، و[color] الفارغ يعيدها للون الافتراضي.
  Future<void> updateLinkNodeColor(
    String linkId,
    String nodeKey,
    int? color,
  ) async {
    final idx = _ayahLinks.indexWhere((l) => l.id == linkId);
    if (idx != -1) {
      final existing = _ayahLinks[idx];
      final colors = Map<String, int>.of(existing.nodeColors);
      if (color == null) {
        colors.remove(nodeKey);
      } else {
        colors[nodeKey] = color;
      }
      final updated = existing.copyWith(
        nodeColors: colors,
        updatedAt: DateTime.now(),
      );
      _ayahLinks[idx] = updated;
      notifyListeners();
      final userDb = UserDatabase.instance;
      if (userDb.isOpen) {
        await userDb.insertOrUpdateAyahLink(updated);
      }
    }
  }

  /// يحفظ منظور الشبكة: طريقة العرض والتكبير والإزاحة.
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
    }
  }

  /// يكرّر بطاقة خاطرة داخل الرابط.
  Future<AyahLinkNote?> duplicateNoteInLink(
    String linkId,
    String noteId,
  ) async {
    final idx = _ayahLinks.indexWhere((l) => l.id == linkId);
    if (idx != -1) {
      final existing = _ayahLinks[idx];
      final targetNote =
          existing.notes.where((n) => n.id == noteId).firstOrNull;
      if (targetNote != null) {
        final now = DateTime.now();
        final duplicated = AyahLinkNote(
          id: const Uuid().v4(),
          title: targetNote.title != null ? '${targetNote.title} (نسخة)' : null,
          content: targetNote.content,
          createdAt: now,
          updatedAt: now,
        );
        final updatedNotes = [...existing.notes, duplicated];
        final updatedPositions =
            Map<String, LinkNodePosition>.from(existing.positions);
        final count = existing.verses.length + updatedNotes.length;
        final angle = (2 * math.pi * (count % 8)) / 8;
        final radius = 330.0 + ((count % 3) * 60.0);
        final dx = 1500.0 + (radius * math.cos(angle));
        final dy = 1500.0 + (radius * math.sin(angle));
        updatedPositions[duplicated.noteKey] = LinkNodePosition(dx: dx, dy: dy);
        final updated = existing.copyWith(
          notes: updatedNotes,
          positions: updatedPositions,
          updatedAt: now,
        );
        _ayahLinks[idx] = updated;
        notifyListeners();
        final userDb = UserDatabase.instance;
        if (userDb.isOpen) {
          await userDb.insertOrUpdateAyahLink(updated);
        }
        return duplicated;
      }
    }
    return null;
  }

  /// يكرّر كرت آية داخل الرابط مع إمكانية ربطه بخواطر أو خيوط إضافية.
  Future<AyahLinkVerse?> duplicateVerseInLink(
    String linkId,
    AyahLinkVerse verse,
  ) async {
    final idx = _ayahLinks.indexWhere((l) => l.id == linkId);
    if (idx != -1) {
      final existing = _ayahLinks[idx];
      final uniqueId =
          '${verse.surahNumber}:${verse.ayahNumber}_${const Uuid().v4().substring(0, 8)}';
      final duplicated = AyahLinkVerse(
        id: uniqueId,
        ayahId: verse.ayahId,
        surahNumber: verse.surahNumber,
        ayahNumber: verse.ayahNumber,
        toAyahNumber: verse.toAyahNumber,
        page: verse.page,
        note: verse.note != null ? '${verse.note} (نسخة)' : null,
        addedAt: DateTime.now(),
      );
      final updatedVerses = [...existing.verses, duplicated];
      final updatedPositions = Map<String, LinkNodePosition>.from(
        existing.positions,
      );
      final origPos =
          existing.positions[verse.nodeKey] ?? existing.positions[verse.ayahKey];
      if (origPos != null) {
        updatedPositions[duplicated.nodeKey] = LinkNodePosition(
          dx: origPos.dx + 50,
          dy: origPos.dy + 50,
        );
      } else {
        final count = updatedVerses.length + existing.notes.length;
        final angle = (2 * math.pi * count / math.max(1, count));
        const radius = 340.0;
        final dx = 1500.0 + (radius * math.cos(angle));
        final dy = 1500.0 + (radius * math.sin(angle));
        updatedPositions[duplicated.nodeKey] = LinkNodePosition(dx: dx, dy: dy);
      }
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
      return duplicated;
    }
    return null;
  }
}
