part of 'user_data_store.dart';

/// TADBEER PAUSE (وقفة تدبر)
mixin _TadbeerSection on _StoreState {
  // ==========================================
  // TADBEER PAUSE (وقفة تدبر)
  // ==========================================

  /// استرجاع إجابات وقفة التدبر المحفوظة لآية محددة إن وُجدت.
  TadbeerItem? getTadbeer(int surahNumber, int ayahNumber) {
    return _tadbeerLookup['$surahNumber:$ayahNumber'];
  }

  /// Resolves the most relevant reflection note for an ayah across Notes & Tadbeer.
  String? getReflectionForAyah(int surahNumber, int ayahNumber) {
    final notes = findNotesForAyah(surahNumber, ayahNumber);
    if (notes.isNotEmpty && notes.first.content.trim().isNotEmpty) {
      return notes.first.content.trim();
    }
    final tadbeer = getTadbeer(surahNumber, ayahNumber);
    if (tadbeer != null && tadbeer.combinedSummary.isNotEmpty) {
      return tadbeer.combinedSummary;
    }
    return null;
  }

  /// حفظ إجابات أسئلة وقفة التدبر لآية محددة أو حذفها إن صارت فارغة.
  Future<void> saveTadbeer({
    required int surahNumber,
    required int ayahNumber,
    int? ayahId,
    required Map<int, String> answers,
  }) async {
    final cleanedAnswers = <int, String>{};
    answers.forEach((k, v) {
      final trimmed = v.trim();
      if (trimmed.isNotEmpty) {
        cleanedAnswers[k] = trimmed;
      }
    });

    final key = '$surahNumber:$ayahNumber';
    if (cleanedAnswers.isEmpty) {
      // Do not save empty responses; clean up if all were deleted
      final existing = _tadbeerLookup.remove(key);
      _tadbeerItems.removeWhere((t) => t.ayahKey == key);
      notifyListeners();
      final userDb = UserDatabase.instance;
      if (userDb.isOpen && existing != null) {
        await userDb.deleteTadbeer(existing.id);
      }
      await saveToDisk();
      return;
    }

    final now = DateTime.now();
    final existing = _tadbeerLookup[key];
    // A new or changed commitment is asked about afresh.
    final commitment = cleanedAnswers[TadbeerItem.commitmentKey];
    final sameCommitment =
        existing != null && existing.commitment == commitment;
    final item = TadbeerItem(
      id: existing?.id ?? const Uuid().v4(),
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      ayahId: ayahId ?? existing?.ayahId,
      answers: cleanedAnswers,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      commitmentAt: commitment == null
          ? null
          : (sameCommitment ? existing.commitmentAt : now),
      commitmentDone: sameCommitment && existing.commitmentDone,
      commitmentAsked: sameCommitment && existing.commitmentAsked,
    );

    final idx = _tadbeerItems.indexWhere((t) => t.ayahKey == key);
    if (idx != -1) {
      _tadbeerItems[idx] = item;
    } else {
      _tadbeerItems.add(item);
    }
    _tadbeerLookup[key] = item;

    notifyListeners();
    final userDb = UserDatabase.instance;
    if (userDb.isOpen) {
      await userDb.insertOrUpdateTadbeer(item);
    }
    await saveToDisk();
    // A reflection keeps the day streak going like reading does.
    await markActiveDay(now: now);
  }

  /// The commitment to ask about on Home: the latest one written before
  /// today and within the last week, not done and not asked about yet.
  TadbeerItem? pendingCommitment({DateTime? now}) {
    final at = now ?? DateTime.now();
    final today = DateTime(at.year, at.month, at.day);
    final weekAgo = today.subtract(const Duration(days: 7));
    TadbeerItem? latest;
    for (final t in _tadbeerItems) {
      final at = t.commitmentAt ?? t.updatedAt;
      if (t.commitment == null || t.commitmentDone || t.commitmentAsked) {
        continue;
      }
      if (!at.isBefore(today) || at.isBefore(weekAgo)) continue;
      if (latest == null ||
          at.isAfter(latest.commitmentAt ?? latest.updatedAt)) {
        latest = t;
      }
    }
    return latest;
  }

  /// يسجّل أن القارئ فعل ما التزم به عند الآية، أو يلغي ذلك.
  Future<void> setCommitmentDone(
    int surahNumber,
    int ayahNumber, {
    required bool done,
  }) => _updateCommitment(
    surahNumber,
    ayahNumber,
    (t) => t.copyWith(commitmentDone: done, commitmentAsked: true),
  );

  /// يسجّل أن القارئ أجاب «ليس بعد»، فلا تُعرض عليه البطاقة ثانية.
  Future<void> setCommitmentAsked(int surahNumber, int ayahNumber) =>
      _updateCommitment(
        surahNumber,
        ayahNumber,
        (t) => t.copyWith(commitmentAsked: true),
      );

  Future<void> _updateCommitment(
    int surahNumber,
    int ayahNumber,
    TadbeerItem Function(TadbeerItem) change,
  ) async {
    final key = '$surahNumber:$ayahNumber';
    final existing = _tadbeerLookup[key];
    if (existing == null) return;
    final item = change(existing);
    _tadbeerLookup[key] = item;
    final idx = _tadbeerItems.indexWhere((t) => t.ayahKey == key);
    if (idx != -1) _tadbeerItems[idx] = item;
    notifyListeners();
    final userDb = UserDatabase.instance;
    if (userDb.isOpen) await userDb.insertOrUpdateTadbeer(item);
    await saveToDisk();
  }

  /// حذف إجابات وقفة التدبر المرتبطة بآية محددة.
  Future<void> deleteTadbeer(int surahNumber, int ayahNumber) async {
    final key = '$surahNumber:$ayahNumber';
    final existing = _tadbeerLookup.remove(key);
    _tadbeerItems.removeWhere((t) => t.ayahKey == key);
    notifyListeners();
    final userDb = UserDatabase.instance;
    if (userDb.isOpen && existing != null) {
      await userDb.deleteTadbeer(existing.id);
    }
    await saveToDisk();
  }
}
