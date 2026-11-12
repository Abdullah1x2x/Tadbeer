/// رحلة القراءة: خطة الختمة وسجل الصفحات المقروءة يومياً.
///
/// سجل محلي لما قرأه القارئ: الصفحات المقروءة كل يوم (للورد والرسم الأسبوعي)،
/// وأيام النشاط (للسلسلة)، وخطة ختمة اختيارية.
library;

import 'dart:math' as math;

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
///
/// لا يتقدم إلا بقراءة الصفحة التي يشير إليها، فلا يبعثره تصفح صفحات أخرى،
/// وتبقى حلقة التقدم وزر "أكمل من صفحة" على نفس الصفحة.
class KhatmaPlan {
  /// تاريخ البدء (أول اليوم).
  final DateTime startDate;

  final int days;

  final int startPage;

  /// الصفحة التي يكمل منها القارئ، ولم تُقرأ بعد.
  final int currentPage;

  /// الصفحات المنجزة.
  final int advanced;

  /// آخر يوم تقدمت فيه الختمة أو رجعت (yyyy-MM-dd)، و[advanced] أول ذلك اليوم:
  /// ورد اليوم هو ما تقدمته الختمة منذئذ، فيتفق مع حلقة التقدم وموضع القراءة.
  final String? day;
  final int advancedAtDayStart;

  KhatmaPlan({
    required DateTime startDate,
    required int days,
    int startPage = 1,
    int? currentPage,
    int advanced = 0,
    String? day,
    this.advancedAtDayStart = 0,
  }) : days = days.clamp(1, 3650),
       startPage = startPage.clamp(1, mushafPageCount),
       startDate = DateTime(startDate.year, startDate.month, startDate.day),
       currentPage = (currentPage ?? startPage).clamp(1, mushafPageCount),
       advanced = advanced < 0 ? 0 : advanced,
       day = day ?? dayKey(startDate);

  /// صفحات الختمة: من صفحة البدء إلى آخر المصحف.
  int get totalPages => mushafPageCount - startPage + 1;

  /// الورد اليومي بالصفحات.
  int get pagesPerDay => (totalPages / days).ceil();

  /// نسبة الإنجاز من ٠ إلى ١.
  double get progress => (advanced / totalPages).clamp(0.0, 1.0);

  /// تكتمل الختمة بقراءة آخر صفحة في المصحف.
  bool get isComplete => advanced >= totalPages;

  /// رقم اليوم في الخطة (من ١)، محصوراً بين ١ وعدد الأيام.
  int dayNumber(DateTime now) {
    // بـ UTC، فلا ينقص يوم عند بدء التوقيت الصيفي.
    final today = DateTime.utc(now.year, now.month, now.day);
    final start = DateTime.utc(startDate.year, startDate.month, startDate.day);
    return (today.difference(start).inDays + 1).clamp(1, days);
  }

  /// الصفحات المفترض إنجازها قبل اليوم؛ ورد اليوم لا يُعدّ تأخراً حتى ينتهي
  /// اليوم.
  int expectedPagesBefore(DateTime now) =>
      (pagesPerDay * (dayNumber(now) - 1)).clamp(0, totalPages);

  /// صفحات تقدمتها الختمة في [now].
  int advancedOn(DateTime now) =>
      day == dayKey(now) ? math.max(0, advanced - advancedAtDayStart) : 0;

  /// يتقدم المؤشر في [now] إن كانت [page] هي صفحته الحالية.
  KhatmaPlan read(int page, DateTime now) => page != currentPage
      ? this
      : _copy(
          now,
          currentPage: nextMushafPage(page),
          advanced: page == mushafPageCount ? totalPages : advanced + 1,
        );

  /// ينقل الختمة يدوياً في [now] إلى [page]، ويُحسب ما قبلها منجزاً؛ والرجوع
  /// قبل صفحة البدء يجعلها البداية.
  KhatmaPlan moveTo(int page, DateTime now) {
    final start = page < startPage ? page : startPage;
    return _copy(
      now,
      currentPage: page,
      advanced: page - start,
      startPage: start,
    );
  }

  KhatmaPlan _copy(
    DateTime now, {
    required int currentPage,
    required int advanced,
    int? startPage,
  }) {
    final today = dayKey(now);
    return KhatmaPlan(
      startDate: startDate,
      days: days,
      startPage: startPage ?? this.startPage,
      currentPage: currentPage,
      advanced: advanced,
      day: today,
      // أول تغيير في يوم جديد يبدأ ورده من حيث كانت الختمة.
      advancedAtDayStart: day == today ? advancedAtDayStart : this.advanced,
    );
  }

  Map<String, dynamic> toJson() => {
    'startDate': dayKey(startDate),
    'days': days,
    'startPage': startPage,
    'currentPage': currentPage,
    'advanced': advanced,
    'day': day,
    'advancedAtDayStart': advancedAtDayStart,
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
        // الحفظ الأقدم بلا يوم: يبدأ ورد اليوم من موضع الختمة الآن.
        day: json['day'] as String? ?? '',
        advancedAtDayStart: (json['advancedAtDayStart'] as num?)?.toInt() ?? 0,
      );
    }
    // صيغة قديمة: صفحات متفرقة وآخر صفحة مقروءة. نكمل بعد آخر صفحة، ونحفظ عدد
    // المنجز.
    final pages = (json['readPages'] as List? ?? const []).length;
    final last = (json['lastPage'] as num?)?.toInt();
    final clampedLast = last?.clamp(1, mushafPageCount);
    final current = clampedLast == null
        ? 1
        : (clampedLast >= mushafPageCount
              ? mushafPageCount
              : nextMushafPage(clampedLast));
    // الختمة قد تبدأ قرب آخر المصحف وتكمل من أوله، فالبداية تلتف كذلك.
    final startPage = clampedLast == null
        ? 1
        : (clampedLast - pages) % mushafPageCount + 1;
    return KhatmaPlan(
      startDate: startDate,
      days: days,
      startPage: startPage,
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

  /// ورد [day]: ما تقدمته الختمة فيه، أو الصفحات المقروءة إن لم تكن ختمة.
  int portionPagesOn(DateTime day) => plan?.advancedOn(day) ?? pagesOn(day);

  /// هل كان في [day] قراءة أو تدبر أو حفظ.
  bool isActiveOn(DateTime day) =>
      pagesOn(day) > 0 || activeDays.contains(dayKey(day));

  /// عدد الأيام المتتالية التي فيها نشاط حتى اليوم، أو حتى أمس إن لم يكن نشاط
  /// اليوم بعد، فلا تنقطع صباحاً.
  ///
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

  /// السلسلة قائمة لكن اليوم بلا نشاط بعد، فتنقطع عند منتصف الليل إن لم يقرأ
  /// القارئ أو يتدبر أو يحفظ.
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

  /// يسجّل [page] مقروءة في [now] ويقدّم الختمة إن كانت صفحتها، وإتمام الختمة
  /// يمسح الخطة.
  ReadingJourney recordPage(int page, DateTime now) {
    final key = dayKey(now);
    return _withPlan(
      plan?.read(page, now),
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

  /// يقرأ ما بقي من ورد اليوم دفعة واحدة: يتقدم المؤشر بالصفحات الباقية منه.
  ReadingJourney completePortion(DateTime now) {
    final p = plan;
    if (p == null) return this;
    var journey = this;
    var page = p.currentPage;
    final left = p.pagesPerDay - portionPagesOn(now);
    for (var i = 0; i < left && journey.plan != null; i++) {
      journey = journey.recordPage(page, now);
      page = nextMushafPage(page);
    }
    return journey;
  }

  ReadingJourney moveKhatmaTo(int page, DateTime now) => plan == null
      ? this
      : _copy(plan: plan!.moveTo(page.clamp(1, mushafPageCount), now));

  /// يبدأ خطة ختمة من [startPage]، أو يستبدل الحالية.
  ReadingJourney startPlan(int days, DateTime now, {int startPage = 1}) =>
      _copy(
        plan: KhatmaPlan(startDate: now, days: days, startPage: startPage),
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
