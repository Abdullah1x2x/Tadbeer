/// رحلة القراءة: خطة الختمة وسجل الصفحات المقروءة يومياً.
///
/// Offline record of what the user read: the pages read on each day (for
/// streaks and the weekly chart) and an optional khatma plan with the set of
/// pages read since it started (for progress and the daily portion).
library;

/// عدد صفحات مصحف المدينة.
const int mushafPageCount = 604;

/// يحوّل التاريخ إلى مفتاح يومي ثابت (yyyy-MM-dd) بالتوقيت المحلي.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// خطة ختمة: البدء في تاريخ معيّن والانتهاء خلال عدد من الأيام.
class KhatmaPlan {
  /// تاريخ بدء الختمة (بداية اليوم).
  final DateTime startDate;

  /// عدد أيام الختمة.
  final int days;

  /// الصفحات المقروءة منذ بدء الختمة.
  final Set<int> readPages;

  /// ينشئ خطة ختمة.
  KhatmaPlan({
    required DateTime startDate,
    required this.days,
    Set<int>? readPages,
  }) : startDate = DateTime(startDate.year, startDate.month, startDate.day),
       readPages = readPages ?? <int>{};

  /// الورد اليومي بالصفحات.
  int get pagesPerDay => (mushafPageCount / days).ceil();

  /// نسبة الإنجاز من ٠ إلى ١.
  double get progress => readPages.length / mushafPageCount;

  /// هل اكتملت الختمة.
  bool get isComplete => readPages.length >= mushafPageCount;

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

  /// أول صفحة لم تُقرأ بعد في الختمة (ليكمل منها القارئ).
  int get nextUnreadPage {
    for (var p = 1; p <= mushafPageCount; p++) {
      if (!readPages.contains(p)) return p;
    }
    return mushafPageCount;
  }

  /// Copy with an extra page marked as read.
  KhatmaPlan withPage(int page) => KhatmaPlan(
    startDate: startDate,
    days: days,
    readPages: {...readPages, page},
  );

  Map<String, dynamic> toJson() => {
    'startDate': dayKey(startDate),
    'days': days,
    'readPages': (readPages.toList()..sort()),
  };

  factory KhatmaPlan.fromJson(Map<String, dynamic> json) => KhatmaPlan(
    startDate: DateTime.parse(json['startDate'] as String),
    days: (json['days'] as num).toInt(),
    readPages: {
      for (final p in (json['readPages'] as List? ?? const []))
        (p as num).toInt(),
    },
  );
}

/// سجل رحلة القراءة كاملاً.
class ReadingJourney {
  /// خطة الختمة الحالية إن وُجدت.
  final KhatmaPlan? plan;

  /// الصفحات المقروءة في كل يوم (مفتاح yyyy-MM-dd).
  final Map<String, Set<int>> dailyPages;

  /// عدد الختمات المكتملة.
  final int completedKhatmas;

  /// ينشئ سجل رحلة القراءة.
  const ReadingJourney({
    this.plan,
    this.dailyPages = const {},
    this.completedKhatmas = 0,
  });

  /// صفحات يوم محدد.
  int pagesOn(DateTime day) => dailyPages[dayKey(day)]?.length ?? 0;

  /// عدد الأيام المتتالية التي قُرئ فيها شيء، حتى اليوم (أو حتى أمس إن
  /// لم يُقرأ شيء اليوم بعد، كي لا تنقطع السلسلة صباحاً).
  int streak(DateTime now) {
    var day = DateTime(now.year, now.month, now.day);
    if (pagesOn(day) == 0) day = day.subtract(const Duration(days: 1));
    var count = 0;
    while (pagesOn(day) > 0) {
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

  /// Records [page] as read on [now]. When it completes the khatma, the plan
  /// is cleared and the completed count goes up.
  ReadingJourney recordPage(int page, DateTime now) {
    final key = dayKey(now);
    final today = {...?dailyPages[key], page};
    var newPlan = plan?.withPage(page);
    var completed = completedKhatmas;
    if (newPlan != null && newPlan.isComplete) {
      completed++;
      newPlan = null;
    }
    return ReadingJourney(
      plan: newPlan,
      dailyPages: {...dailyPages, key: today},
      completedKhatmas: completed,
    );
  }

  /// Starts (or replaces) the khatma plan.
  ReadingJourney startPlan(int days, DateTime now) => ReadingJourney(
    plan: KhatmaPlan(startDate: now, days: days),
    dailyPages: dailyPages,
    completedKhatmas: completedKhatmas,
  );

  /// Cancels the current plan, keeping the reading history.
  ReadingJourney cancelPlan() => ReadingJourney(
    dailyPages: dailyPages,
    completedKhatmas: completedKhatmas,
  );

  Map<String, dynamic> toJson() => {
    if (plan != null) 'plan': plan!.toJson(),
    'dailyPages': {
      for (final e in dailyPages.entries) e.key: (e.value.toList()..sort()),
    },
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
    completedKhatmas: (json['completedKhatmas'] as num?)?.toInt() ?? 0,
  );
}
