part of 'user_data_store.dart';

/// قسم الخواطر.
mixin _NotesSection on _StoreState {
  /// خواطر آية محددة.
  @override
  List<NoteItem> getNotesForAyah(int surahNumber, int ayahNumber) {
    return _notes
        .where(
          (n) => n.surahNumber == surahNumber && n.ayahNumber == ayahNumber,
        )
        .toList();
  }

  /// يضيف خاطرة أو يعدّلها.
  Future<void> putNote(NoteItem note) async {
    final idx = _notes.indexWhere((n) => n.id == note.id);
    if (idx != -1) {
      _notes[idx] = note;
    } else {
      _notes.insert(0, note);
    }
    notifyListeners();
    final userDb = UserDatabase.instance;
    if (userDb.isOpen) {
      await userDb.insertOrUpdateNote(note);
    }
    await saveToDisk();
  }

  /// ينشئ خاطرة، أو يعدّل الموجودة إن مُرّر معرّفها، ويحفظها.
  Future<NoteItem> saveNote({
    String? id,
    required NoteType type,
    String? title,
    required String content,
    int? ayahId,
    int? surahNumber,
    int? ayahNumber,
    int? page,
    String? ayahText,
  }) async {
    final now = DateTime.now();

    if (id != null) {
      final existing = _notes.where((n) => n.id == id).firstOrNull;
      if (existing != null) {
        final updated = existing.copyWith(
          title: title,
          content: content,
          updatedAt: now,
        );
        await putNote(updated);
        return updated;
      }
    }

    final newNote = NoteItem(
      id: id ?? const Uuid().v4(),
      type: type,
      title: title,
      content: content,
      ayahId: ayahId,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      page: page,
      ayahText: ayahText,
      createdAt: now,
      updatedAt: now,
    );
    await putNote(newNote);
    return newNote;
  }

  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
    final userDb = UserDatabase.instance;
    if (userDb.isOpen) {
      await userDb.deleteNote(id);
    }
    await saveToDisk();
  }
}
