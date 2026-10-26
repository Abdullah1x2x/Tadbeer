/// رحلة القراءة: خطة الختمة وسجل الصفحات المقروءة يومياً.
///
/// Offline record of what the user read: the pages read on each day in
/// reading mode (for the daily portion and the weekly chart), the days with
/// any activity (reading, reflection or memorization, for the streak) and an
/// optional sequential khatma plan.
library;

/// عدد صفحات مصحف المدينة.
const int mushafPageCount = 604;

/// يحوّل التاريخ إلى مفتاح يومي ثابت (yyyy-MM-dd) بالتوقيت المحلي.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// الصفحة التالية في المصحف مع الالتفاف من ٦٠٤ إلى ١.
int nextMushafPage(int page) => page % mushafPageCount + 1;

/// خطة ختمة متسلسلة: مؤشر واحد «وصلت إلى صفحة» يتقدم صفحة صفحة.
///
/// The khatma moves forward only when the page it points at is read, so
/// browsing other pages never scatters its progress, and the progress ring
/// and the "continue from page" button always show the same page.
class KhatmaPlan {
  /// تاريخ بدء الختمة (بداية اليوم).
  final DateTime startDate;

  /// عدد أيام الختمة.
  final int days;

  /// الصفحة التي بدأت منها الختمة.
  final int startPage;

  /// الصفحة التي يكمل منها القارئ (لم تُقرأ بعد).
  final int currentPage;

  /// عدد الصفحات المنجزة في الختمة.
  final int advanced;

  /// Pages already read on the day the khatma started, before it started;
  /// they do not count toward that day's portion.
  final int pagesBeforeStart;

  /// ينشئ خطة ختمة.
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

  /// هل اكتملت الختمة.
  bool get isComplete => advanced >= mushafPageCount;

  /// رقم اليوم الحالي في الخطة (يبدأ من ١)، محصوراً بين ١ وعدد الأيام.
  int dayNumber(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return (today.difference(startDate).inDays + 1).clamp(1, days);
  }

  /// الأيام المتبقية بما فيها اليوم.
  int daysLeft(DateTime now) => days - dayNumber(now) + 1;

  /// الصفحات التي كان يجب إنجازها قبل اليوم الحالي؛ ورد اليوم نفسه لا
  /// يُحسب تأخراً حتى ينتهي اليوم.
  int expectedPagesBefore(DateTime now) =>
      (pagesPerDay * (dayNumber(now) - 1)).clamp(0, mushafPageCount);

  /// يتقدم المؤشر إذا كانت [page] هي صفحته الحالية.
  KhatmaPlan read(int page) => page != currentPage
      ? this
      : _copy(currentPage: nextMushafPage(page), advanced: advanced + 1);

  /// يضبط موضع الختمة يدوياً على [page]، ويُحسب ما بين البداية وبينها منجزاً.
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
    // Earlier format: a set of scattered pages plus the last page read.
    // Continue after the last page, keeping the number of pages done.
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
  /// خطة الختمة الحالية إن وُجدت.
  final KhatmaPlan? plan;

  /// الصفحات المقروءة في كل يوم (مفتاح yyyy-MM-dd).
  final Map<String, Set<int>> dailyPages;

  /// أيام فيها تدبر أو حفظ (تُحسب في الأيام المتتالية مع أيام القراءة).
  final Set<String> activeDays;

  /// عدد الختمات المكتملة.
  final int completedKhatmas;

  /// ينشئ سجل رحلة القراءة.
  const ReadingJourney({
    this.plan,
    this.dailyPages = const {},
    this.activeDays = const {},
    this.completedKhatmas = 0,
  });

  /// صفحات يوم محدد.
  int pagesOn(DateTime day) => dailyPages[dayKey(day)]?.length ?? 0;

  /// صفحات ورد اليوم: ما قُرئ في [day] للختمة الحالية. On the day a khatma
  /// starts, pages read before it do not fill its first portion.
  int portionPagesOn(DateTime day) {
    final read = pagesOn(day);
    final p = plan;
    if (p == null || !_sameDay(p.startDate, day)) return read;
    return (read - p.pagesBeforeStart).clamp(0, read);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// هل كان للمستخدم نشاط (قراءة أو تدبر أو حفظ) في يوم محدد.
  bool isActiveOn(DateTime day) =>
      pagesOn(day) > 0 || activeDays.contains(dayKey(day));

  /// عدد الأيام المتتالية التي فيها نشاط، حتى اليوم (أو حتى أمس إن لم يكن
  /// هناك نشاط اليوم بعد، كي لا تنقطع السلسلة صباحاً).
  int streak(DateTime now) {
    var day = DateTime(now.year, now.month, now.day);
    if (!isActiveOn(day)) day = day.subtract(const Duration(days: 1));
    var count = 0;
    while (isActiveOn(day)) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  /// صفحات آخر سبعة أيام، من الأقدم إلى اليوم.
  List<int> lastSevenDays(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return [
      for (var i = 6; i >= 0; i--) pagesOn(today.subtract(Duration(days: i))),
    ];
  }

  /// إجمالي الصفحات المقروءة عبر كل الأيام.
  int get totalPages =>
      dailyPages.values.fold(0, (sum, pages) => sum + pages.length);

  /// Records [page] as read on [now] and advances the khatma when it is the
  /// page the plan points at. Completing the khatma clears the plan.
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

  /// يقرأ ورد اليوم دفعة واحدة: يتقدم المؤشر بعدد صفحات الورد.
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

  /// يضبط موضع الختمة يدوياً.
  ReadingJourney moveKhatmaTo(int page) => plan == null
      ? this
      : _copy(plan: plan!.moveTo(page.clamp(1, mushafPageCount)));

  /// Starts (or replaces) the khatma plan from [startPage].
  ReadingJourney startPlan(int days, DateTime now, {int startPage = 1}) =>
      _copy(
        plan: KhatmaPlan(
          startDate: now,
          days: days,
          startPage: startPage,
          pagesBeforeStart: pagesOn(now),
        ),
      );

  /// Cancels the current plan, keeping the reading history.
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
