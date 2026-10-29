/// رحلة القراءة: خطة الختمة وسجل الصفحات المقروءة يومياً.
///
/// سجل محلي لما قرأه القارئ: الصفحات المقروءة كل يوم (للورد والرسم الأسبوعي)، وأيام النشاط (للسلسلة)، وخطة ختمة اختيارية.
library;

/// عدد صفحات مصحف المدينة.
const int mushafPageCount = 604;

/// مفتاح ثابت لليوم (yyyy-MM-dd) بالتوقيت المحلي.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// الصفحة التالية، مع الالتفاف من ٦٠٤ إلى ١.
int nextMushafPage(int page) => page % mushafPageCount + 1;

/// ختمة متسلسلة بمؤشر واحد «وصلت إلى صفحة» يتقدم صفحة صفحة.
/// لا يتقدم إلا بقراءة الصفحة التي يشير إليها، فلا يبعثره تصفح صفحات أخرى، وتبقى حلقة التقدم وزر "أكمل من صفحة" على نفس الصفحة.
class KhatmaPlan {
  /// تاريخ البدء (أول اليوم).
  final DateTime startDate;

  final int days;

  final int startPage;

  /// الصفحة التي يكمل منها القارئ، ولم تُقرأ بعد.
  final int currentPage;

  /// الصفحات المنجزة.
  final int advanced;

  /// صفحات قُرئت يوم البدء قبل بدء الختمة؛ لا تُحسب من ورد ذلك اليوم.
  final int pagesBeforeStart;

  KhatmaPlan({
    required DateTime startDate,
    required this.days,
    this.startPage = 1,
    int? currentPage,
    this.advanced = 0,
    this.pagesBeforeStart = 0,
  }) : startDate = DateTime(startDate.year, startDate.month, startDate.day),
       currentPage = currentPage ?? startPage;

  /// الورد اليومي بالصفحات.
  int get pagesPerDay => (mushafPageCount / days).ceil();

  /// نسبة الإنجاز من ٠ إلى ١.
  double get progress => advanced / mushafPageCount;

  bool get isComplete => advanced >= mushafPageCount;

  /// رقم اليوم في الخطة (من ١)، محصوراً بين ١ وعدد الأيام.
  int dayNumber(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return (today.difference(startDate).inDays + 1).clamp(1, days);
  }

  /// الأيام المتبقية، ومنها اليوم.
  int daysLeft(DateTime now) => days - dayNumber(now) + 1;

  /// الصفحات المفترض إنجازها قبل اليوم؛ ورد اليوم لا يُعدّ تأخراً حتى ينتهي اليوم.
  int expectedPagesBefore(DateTime now) =>
      (pagesPerDay * (dayNumber(now) - 1)).clamp(0, mushafPageCount);

  /// يتقدم المؤشر إن كانت [page] هي صفحته الحالية.
  KhatmaPlan read(int page) => page != currentPage
      ? this
      : _copy(currentPage: nextMushafPage(page), advanced: advanced + 1);

  /// ينقل الختمة يدوياً إلى [page]، ويُحسب ما قبلها منجزاً.
  KhatmaPlan moveTo(int page) => _copy(
    currentPage: page,
    advanced: (page - startPage + mushafPageCount) % mushafPageCount,
  );

  KhatmaPlan _copy({required int currentPage, required int advanced}) =>
      KhatmaPlan(
        startDate: startDate,
        days: days,
        startPage: startPage,
        currentPage: currentPage,
        advanced: advanced,
        pagesBeforeStart: pagesBeforeStart,
      );

  Map<String, dynamic> toJson() => {
    'startDate': dayKey(startDate),
    'days': days,
    'startPage': startPage,
    'currentPage': currentPage,
    'advanced': advanced,
    if (pagesBeforeStart > 0) 'pagesBeforeStart': pagesBeforeStart,
  };

  factory KhatmaPlan.fromJson(Map<String, dynamic> json) {
    final startDate = DateTime.parse(json['startDate'] as String);
    final days = (json['days'] as num).toInt();
    if (json['currentPage'] != null) {
      return KhatmaPlan(
        startDate: startDate,
        days: days,
        startPage: (json['startPage'] as num?)?.toInt() ?? 1,
        currentPage: (json['currentPage'] as num).toInt(),
        advanced: (json['advanced'] as num?)?.toInt() ?? 0,
        pagesBeforeStart: (json['pagesBeforeStart'] as num?)?.toInt() ?? 0,
      );
    }
    // صيغة قديمة: صفحات متفرقة وآخر صفحة مقروءة. نكمل بعد آخر صفحة، ونحفظ عدد المنجز.
    final pages = (json['readPages'] as List? ?? const []).length;
    final last = (json['lastPage'] as num?)?.toInt();
    final current = last == null ? 1 : nextMushafPage(last);
    return KhatmaPlan(
      startDate: startDate,
      days: days,
      startPage:
          ((current - 1 - pages) % mushafPageCount + mushafPageCount) %
              mushafPageCount +
          1,
      currentPage: current,
      advanced: pages,
    );
  }
}

/// سجل رحلة القراءة كاملاً.
class ReadingJourney {
  final KhatmaPlan? plan;

  /// الصفحات المقروءة في كل يوم، بمفتاح [dayKey].
  final Map<String, Set<int>> dailyPages;

  /// أيام فيها تدبر أو حفظ؛ تُحسب في السلسلة مع أيام القراءة.
  final Set<String> activeDays;

  final int completedKhatmas;

  const ReadingJourney({
    this.plan,
    this.dailyPages = const {},
    this.activeDays = const {},
    this.completedKhatmas = 0,
  });

  int pagesOn(DateTime day) => dailyPages[dayKey(day)]?.length ?? 0;

  /// صفحات ورد [day] للختمة الحالية؛ وفي يوم بدء الختمة لا تُحسب الصفحات المقروءة قبلها.
  int portionPagesOn(DateTime day) {
    final read = pagesOn(day);
    final p = plan;
    if (p == null || !_sameDay(p.startDate, day)) return read;
    return (read - p.pagesBeforeStart).clamp(0, read);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// هل كان في [day] قراءة أو تدبر أو حفظ.
  bool isActiveOn(DateTime day) =>
      pagesOn(day) > 0 || activeDays.contains(dayKey(day));

  /// عدد الأيام المتتالية التي فيها نشاط حتى اليوم، أو حتى أمس إن لم يكن نشاط اليوم بعد، فلا تنقطع صباحاً.
  /// يرجع بأيام التقويم لا بـ 24 ساعة، فلا يُسقط تغيير التوقيت الصيفي يوماً.
  int streak(DateTime now) {
    var day = DateTime(now.year, now.month, now.day);
    if (!isActiveOn(day)) day = DateTime(day.year, day.month, day.day - 1);
    var count = 0;
    while (isActiveOn(day)) {
      count++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return count;
  }

  /// السلسلة قائمة لكن اليوم بلا نشاط بعد، فتنقطع عند منتصف الليل إن لم يقرأ القارئ أو يتدبر أو يحفظ.
  bool streakAtRisk(DateTime now) => !isActiveOn(now) && streak(now) > 0;

  /// صفحات آخر سبعة أيام، من الأقدم إلى اليوم.
  List<int> lastSevenDays(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return [
      for (var i = 6; i >= 0; i--)
        pagesOn(DateTime(today.year, today.month, today.day - i)),
    ];
  }

  int get totalPages =>
      dailyPages.values.fold(0, (sum, pages) => sum + pages.length);

  /// يسجّل [page] مقروءة في [now] ويقدّم الختمة إن كانت صفحتها، وإتمام الختمة يمسح الخطة.
  ReadingJourney recordPage(int page, DateTime now) {
    final key = dayKey(now);
    return _withPlan(
      plan?.read(page),
      dailyPages: {
        ...dailyPages,
        key: {...?dailyPages[key], page},
      },
    );
  }

  /// يسجّل يوماً فيه تدبر أو حفظ.
  ReadingJourney markActive(DateTime now) {
    final key = dayKey(now);
    if (activeDays.contains(key)) return this;
    return _copy(activeDays: {...activeDays, key});
  }

  /// يقرأ ورد اليوم دفعة واحدة: يتقدم المؤشر بعدد صفحاته.
  ReadingJourney completePortion(DateTime now) {
    final p = plan;
    if (p == null) return this;
    var journey = this;
    var page = p.currentPage;
    for (var i = 0; i < p.pagesPerDay && journey.plan != null; i++) {
      journey = journey.recordPage(page, now);
      page = nextMushafPage(page);
    }
    return journey;
  }

  ReadingJourney moveKhatmaTo(int page) => plan == null
      ? this
      : _copy(plan: plan!.moveTo(page.clamp(1, mushafPageCount)));

  /// يبدأ خطة ختمة من [startPage]، أو يستبدل الحالية.
  ReadingJourney startPlan(int days, DateTime now, {int startPage = 1}) =>
      _copy(
        plan: KhatmaPlan(
          startDate: now,
          days: days,
          startPage: startPage,
          pagesBeforeStart: pagesOn(now),
        ),
      );

  /// يلغي الخطة، ويبقى سجل القراءة.
  ReadingJourney cancelPlan() => ReadingJourney(
    dailyPages: dailyPages,
    activeDays: activeDays,
    completedKhatmas: completedKhatmas,
  );

  ReadingJourney _withPlan(
    KhatmaPlan? newPlan, {
    required Map<String, Set<int>> dailyPages,
  }) {
    var completed = completedKhatmas;
    if (newPlan != null && newPlan.isComplete) {
      completed++;
      newPlan = null;
    }
    return ReadingJourney(
      plan: newPlan,
      dailyPages: dailyPages,
      activeDays: activeDays,
      completedKhatmas: completed,
    );
  }

  ReadingJourney _copy({KhatmaPlan? plan, Set<String>? activeDays}) =>
      ReadingJourney(
        plan: plan ?? this.plan,
        dailyPages: dailyPages,
        activeDays: activeDays ?? this.activeDays,
        completedKhatmas: completedKhatmas,
      );

  Map<String, dynamic> toJson() => {
    if (plan != null) 'plan': plan!.toJson(),
    'dailyPages': {
      for (final e in dailyPages.entries) e.key: (e.value.toList()..sort()),
    },
    'activeDays': (activeDays.toList()..sort()),
    'completedKhatmas': completedKhatmas,
  };

  factory ReadingJourney.fromJson(Map<String, dynamic> json) => ReadingJourney(
    plan: json['plan'] is Map
        ? KhatmaPlan.fromJson(Map<String, dynamic>.from(json['plan'] as Map))
        : null,
    dailyPages: {
      for (final e in (json['dailyPages'] as Map? ?? const {}).entries)
        e.key as String: {for (final p in e.value as List) (p as num).toInt()},
    },
    activeDays: {
      for (final d in (json['activeDays'] as List? ?? const [])) d as String,
    },
    completedKhatmas: (json['completedKhatmas'] as num?)?.toInt() ?? 0,
  );
}
