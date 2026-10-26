import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/storage/user_data_store.dart';
import '../../core/motion/app_motion.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../ayah_links/curated_pathways.dart';
import '../duas/quran_duas_repository.dart';
import '../focus/focus_mode_screen.dart';
import '../quran/data/quran_models.dart';
import '../quran/data/quran_repository.dart';
import '../share/ayah_share_sheet.dart';
import '../tadbeer/tadbeer_model.dart';
import '../tadbeer/tadbeer_pause_sheet.dart';
import '../tadbeer/tadbeer_questions.dart';
import '../../core/design_system/app_icons.dart';

/// آيات للتدبّر: القائمة المشتركة بين بطاقة الرئيسية والودجت.
///
/// The ayahs are those that read well on their own: the Quranic duas and
/// the pathway verses first, then every ayah of a comfortable length that
/// does not open mid-thought ("فـ", "ثم", "إلا"…), inside a story's
/// dialogue ("قال"…), or with detailed rulings. Each day has its own set,
/// the same for every reader.
class AyahOfTheDay {
  AyahOfTheDay._();

  /// Ayahs shown on the Home card each day, one after another.
  static const perDay = 12;

  static List<Ayah>? _pool;
  static List<Ayah>? _curated;

  /// Every ayah that may be shown, in Mushaf order.
  static List<Ayah> get pool => _pool ??= _buildPool();

  /// The hand-picked ayahs (Quranic duas and pathway verses); each day
  /// opens with one of them.
  static List<Ayah> get curated => _curated ??= _buildCurated();

  static List<Ayah> _buildPool() {
    final picked = {for (final a in curated) a.id: a};
    for (final a in QuranRepository.instance.allAyahs) {
      if (readsAlone(a)) picked[a.id] = a;
    }
    return picked.values.toList()..sort((x, y) => x.id.compareTo(y.id));
  }

  static List<Ayah> _buildCurated() {
    final repo = QuranRepository.instance;
    final picked = <int, Ayah>{};
    void add(int surah, int ayah) {
      final a = repo.getAyah(surah, ayah);
      if (a != null) picked[a.id] = a;
    }

    for (final dua in QuranDuasRepository.instance.getDuas(
      quranRepository: repo,
    )) {
      add(dua.surahNumber, dua.ayahNumber);
    }
    for (final pathway in CuratedPathwaysRegistry.pathways) {
      for (final v in pathway.verses) {
        add(v.surah, v.ayah);
      }
    }
    return picked.values.toList()..sort((x, y) => x.id.compareTo(y.id));
  }

  /// Words that, opening an ayah, carry on the one before it or a
  /// story's dialogue.
  static final Set<String> _openers = {
    for (final w in const [
      'ثم',
      'إلا',
      'أو',
      'بل',
      'حتى',
      'إذ',
      'لكن',
      'ذلك',
      'أولئك',
      'كذلك',
      'قال',
      'قالوا',
      'قالت',
      'قيل',
      'قلنا',
      'وقال',
      'وقالوا',
      'وقالت',
      'وإذ',
      'وكذلك',
      'لهم',
      'ومنهم',
      'منهم',
    ])
      ArabicSearchNormalizer.normalize(w),
  };

  static final String _basmala = ArabicSearchNormalizer.normalize(
    'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
  );

  /// Words of detailed rulings (marriage, divorce, inheritance, purity).
  static final List<String> _rulings = [
    for (final w in const [
      'تنكحوا',
      'نكح',
      'طلقتم',
      'المطلقات',
      'الطلاق',
      'السدس',
      'الثلث',
      'الربع',
      'الثمن',
      'المحيض',
      'الحيض',
      'نسائكم',
      'أرحامهن',
    ])
      ArabicSearchNormalizer.normalize(w),
  ];

  /// Whether [ayah] can be read and reflected on by itself.
  static bool readsAlone(Ayah ayah) {
    var text = ArabicSearchNormalizer.normalize(ayah.rawText).trim();
    // A surah's first ayah carries the basmala in its text.
    if (text.startsWith(_basmala)) {
      text = text.substring(_basmala.length).trim();
    }
    // Letters only (no diacritics): from a line to a short paragraph.
    final letters = text.replaceAll(' ', '').length;
    if (letters < 25 || letters > 170) return false;
    final words = text.split(RegExp(r'\s+'));
    final first = words.first;
    // "فـ" carries on (فقال، فلما…), but "في" is a preposition.
    if (first.startsWith('ف') && first != 'في') return false;
    if (_openers.contains(first)) return false;
    return !_rulings.any(text.contains);
  }

  static int _dayIndex(DateTime day) => DateTime.utc(
    day.year,
    day.month,
    day.day,
  ).difference(DateTime.utc(2020)).inDays;

  /// The ayahs of [day], in the order the Home card shows them.
  static List<Ayah> forDayAll(DateTime day) {
    final p = pool;
    final c = curated;
    final index = _dayIndex(day);
    final first = c[(index * 7919) % c.length];
    final base = index * perDay;
    // A large prime stride spreads them across the Mushaf.
    final rest = [
      for (var i = 0; i < perDay; i++) p[((base + i) * 7919) % p.length],
    ].where((a) => a.id != first.id).take(perDay - 1);
    return [first, ...rest];
  }

  /// The first ayah of [day].
  static Ayah forDay(DateTime day) => forDayAll(day).first;

  /// The reflection question shown with the [index]th ayah of [day].
  static String questionFor(DateTime day, int index) {
    final ayah = forDayAll(day)[index];
    return TadbeerQuestions.forAyah(ayah)[questionIndex(day, index)];
  }

  /// Which of the ayah's four questions the card asks, so the reflection
  /// opens on it.
  static int questionIndex(DateTime day, int index) =>
      (_dayIndex(day) + index) % TadbeerItem.questions.length;

  /// سؤال التدبر لهذا اليوم.
  static String questionForDay(DateTime day) => questionFor(day, 0);
}

/// بطاقة «آية للتدبّر» في الرئيسية: آيات اليوم تتتابع تلقائياً.
///
/// The day's ayahs follow one another every [_interval] while the card is
/// on screen; a swipe moves by hand, and a finger on the card holds it.
/// The sequence stays still with reduced motion or a screen reader, and
/// moves to the new day's ayahs after midnight.
class AyahOfTheDayCard extends StatefulWidget {
  /// ينشئ بطاقة آيات التدبّر.
  const AyahOfTheDayCard({super.key});

  @override
  State<AyahOfTheDayCard> createState() => _AyahOfTheDayCardState();
}

class _AyahOfTheDayCardState extends State<AyahOfTheDayCard> {
  static const _interval = Duration(seconds: 8);

  late DateTime _day;
  late List<Ayah> _ayahs;
  int _index = 0;
  Timer? _timer;
  bool _held = false;

  @override
  void initState() {
    super.initState();
    _load(DateTime.now());
    _restart();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _load(DateTime now) {
    _day = DateTime(now.year, now.month, now.day);
    _ayahs = AyahOfTheDay.forDayAll(_day);
    _index = 0;
  }

  void _restart() {
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) => _tick());
  }

  /// Whether the sequence may move by itself right now.
  bool get _mayMove {
    if (!mounted || _held) return false;
    if (!TickerMode.valuesOf(context).enabled) return false;
    // Hold still under a sheet or page opened on top, such as a reflection.
    if (ModalRoute.isCurrentOf(context) == false) return false;
    if (MediaQuery.accessibleNavigationOf(context)) return false;
    return AppMotion.shouldAnimate(context);
  }

  void _tick() {
    if (!mounted) return;
    final now = DateTime.now();
    if (now.day != _day.day ||
        now.month != _day.month ||
        now.year != _day.year) {
      setState(() => _load(now));
      return;
    }
    if (_mayMove) setState(() => _index = (_index + 1) % _ayahs.length);
  }

  static String _verse(Ayah a) =>
      '${a.text} ﴿${ArabicSearchNormalizer.toArabicDigits(a.ayahNumber)}﴾';

  void _step(int by) {
    setState(() => _index = (_index + by) % _ayahs.length);
    _restart();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ayah = _ayahs[_index];
    final surah = QuranRepository.instance.getSurah(ayah.surahNumber);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final motion = AppMotion.shouldAnimate(context);
    const gold = Color(0xFFD9B566);
    final verseStyle = TextStyle(
      fontFamily: UserDataStore.instance.quranFontFamily,
      fontSize: 21,
      height: 2,
      color: const Color(0xFFF2EEE4),
    );
    const questionStyle = TextStyle(
      color: gold,
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
    );

    return Listener(
      // A finger on the card holds the sequence.
      onPointerDown: (_) => _held = true,
      onPointerUp: (_) => _held = false,
      onPointerCancel: (_) => _held = false,
      child: GestureDetector(
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v.abs() < 200) return;
          // Swiping toward the reading direction's end shows the next one.
          _step((v > 0) == rtl ? 1 : -1);
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient(isDark),
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.lightPrimary.withValues(
                  alpha: isDark ? 0.4 : 0.25,
                ),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              onTap: () => FocusModeScreen.open(context, ayah),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: motion ? 450 : 0),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.topCenter,
                    children: [...previous, ?current],
                  ),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, 0.04),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Column(
                    key: ValueKey(ayah.id),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(AppIcons.sunFill, color: gold, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            l10n.widgetAyahTitle,
                            style: const TextStyle(
                              color: gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Long surah names shrink instead of overflowing.
                          Expanded(
                            child: Text(
                              l10n.ayahReference(surah.name, ayah.ayahNumber),
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SteadyHeight(
                        texts: [for (final a in _ayahs) _verse(a)],
                        style: verseStyle,
                        maxLines: 5,
                        child: Text(
                          _verse(ayah),
                          textAlign: TextAlign.center,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: verseStyle,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Shows a check once this verse has been reflected on.
                      _SteadyHeight(
                        texts: [
                          for (var i = 0; i < _ayahs.length; i++)
                            AyahOfTheDay.questionFor(_day, i),
                        ],
                        style: questionStyle,
                        child: ListenableBuilder(
                          listenable: UserDataStore.instance,
                          builder: (context, _) {
                            final done =
                                UserDataStore.instance.getTadbeer(
                                  ayah.surahNumber,
                                  ayah.ayahNumber,
                                ) !=
                                null;
                            return done
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        AppIcons.checkCircleFill,
                                        color: gold,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        l10n.reflectedToday,
                                        style: questionStyle,
                                      ),
                                    ],
                                  )
                                : Text(
                                    AyahOfTheDay.questionFor(_day, _index),
                                    textAlign: TextAlign.center,
                                    style: questionStyle,
                                  );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Wraps on narrow phones instead of overflowing.
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          _Action(
                            icon: AppIcons.flowerLotusFill,
                            label: l10n.reflectOnIt,
                            onTap: () => TadbeerPauseSheet.show(
                              context,
                              ayah,
                              initialQuestion: AyahOfTheDay.questionIndex(
                                _day,
                                _index,
                              ),
                            ),
                          ),
                          _Action(
                            icon: AppIcons.export,
                            label: l10n.share,
                            onTap: () => AyahShareSheet.show(context, ayah),
                          ),
                          _Action(
                            icon: AppIcons.personSimpleTaiChi,
                            label: l10n.focusMode,
                            onTap: () => FocusModeScreen.open(context, ayah),
                          ),
                        ],
                      ),
                      _Dots(count: _ayahs.length, current: _index, color: gold),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gives [child] the height of the tallest of [texts], so the card keeps
/// one size while the day's ayahs follow one another.
class _SteadyHeight extends StatelessWidget {
  final List<String> texts;
  final TextStyle style;
  final int? maxLines;
  final Widget child;

  const _SteadyHeight({
    required this.texts,
    required this.style,
    required this.child,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final merged = DefaultTextStyle.of(context).style.merge(style);
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        var tallest = 0.0;
        for (final text in texts) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: merged),
            textAlign: TextAlign.center,
            textDirection: direction,
            textScaler: scaler,
            maxLines: maxLines,
            ellipsis: maxLines == null ? null : '…',
          )..layout(maxWidth: box.maxWidth);
          tallest = math.max(tallest, painter.height);
          painter.dispose();
        }
        return SizedBox(
          height: tallest,
          child: Center(child: child),
        );
      },
    );
  }
}

/// Where the shown ayah sits among the day's ayahs.
class _Dots extends StatelessWidget {
  final int count;
  final int current;
  final Color color;

  const _Dots({
    required this.count,
    required this.current,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              Container(
                width: i == current ? 14 : 5,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: i == current ? color : color.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Action({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(foregroundColor: Colors.white),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}
