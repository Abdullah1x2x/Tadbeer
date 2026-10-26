part of 'user_data_store.dart';

/// READING JOURNEY (الختمة والإحصاءات)
mixin _JourneySection on _StoreState {
  // ==========================================
  // READING JOURNEY (الختمة والإحصاءات)
  // ==========================================

  /// يسجل قراءة صفحة اليوم ويحدّث تقدم الختمة.
  Future<void> recordPageRead(int page, {DateTime? now}) async {
    if (page < 1 || page > mushafPageCount) return;
    final at = now ?? DateTime.now();
    final already = _journey.dailyPages[dayKey(at)]?.contains(page) ?? false;
    final advancesPlan = _journey.plan?.currentPage == page;
    if (already && !advancesPlan) return;
    await _saveJourney(_journey.recordPage(page, at));
  }

  /// يبدأ ختمة جديدة خلال [days] يوماً من [startPage]، ويجعلها موضع القراءة
  /// كي يفتح المصحف والرئيسية على الصفحة نفسها.
  Future<void> startKhatma(int days, {int startPage = 1}) async {
    await _saveJourney(
      _journey.startPlan(days, DateTime.now(), startPage: startPage),
    );
    await _moveReadingPositionTo(startPage);
  }

  /// يضبط موضع الختمة يدوياً (ويجعله موضع القراءة).
  Future<void> moveKhatmaTo(int page) async {
    await _saveJourney(_journey.moveKhatmaTo(page));
    await _moveReadingPositionTo(page);
  }

  /// يسجّل ورد اليوم كاملاً دفعة واحدة.
  Future<void> completeTodayPortion() async {
    await _saveJourney(_journey.completePortion(DateTime.now()));
    final plan = _journey.plan;
    if (plan != null) await _moveReadingPositionTo(plan.currentPage);
  }

  /// الختمة تتبع موضع القراءة: صفحتها هي الصفحة التي يقف عندها القارئ،
  /// والمنجز ما قبلها منذ بدايتها، كالعلامة في المصحف الورقي.
  @override
  Future<void> followReadingPosition(int page) async {
    final plan = _journey.plan;
    if (plan == null || plan.currentPage == page) return;
    await _saveJourney(_journey.moveKhatmaTo(page));
  }

  /// يسجّل يوماً فيه نشاط تدبر أو حفظ (للأيام المتتالية).
  @override
  Future<void> markActiveDay({DateTime? now}) async {
    final next = _journey.markActive(now ?? DateTime.now());
    if (!identical(next, _journey)) await _saveJourney(next);
  }

  Future<void> _moveReadingPositionTo(int page) async {
    final ayahs = QuranRepository.instance.getPage(page).ayahs;
    if (ayahs.isEmpty) return;
    await saveReadingPosition(
      page: page,
      surahNumber: ayahs.first.surahNumber,
      ayahNumber: ayahs.first.ayahNumber,
    );
  }

  /// يلغي الختمة الحالية مع الإبقاء على سجل القراءة.
  Future<void> cancelKhatma() => _saveJourney(_journey.cancelPlan());

  Future<void> _saveJourney(ReadingJourney journey) async {
    _journey = journey;
    notifyListeners();
    await UserDatabase.instance.saveAppState(_journeyKey, journey.toJson());
    await saveToDisk();
  }
}
