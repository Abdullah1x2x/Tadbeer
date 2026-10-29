import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../core/theme/theme.dart';
import '../../data/storage/user_data_store.dart';
import '../../core/motion/app_motion.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../ayah_links/data/curated_pathways.dart';
import '../duas/data/quran_duas_repository.dart';
import '../focus/focus_mode_screen.dart';
import '../../data/quran/quran_models.dart';
import '../../data/quran/quran_repository.dart';
import '../quran/qcf/qcf_ayah_text.dart';
import '../../data/models/user_settings_model.dart';
import '../share/ayah_share_sheet.dart';
import '../../data/models/tadbeer_model.dart';
import '../tadbeer/tadbeer_pause_sheet.dart';
import '../tadbeer/tadbeer_questions.dart';
import '../../core/design_system/app_icons.dart';

/// آيات للتدبّر: القائمة المشتركة بين بطاقة الرئيسية والودجت.
///
/// هي الآيات التي تُقرأ وحدها: أدعية القرآن وآيات المسارات أولاً، ثم كل آية
/// بطول مريح لا تبدأ وسط فكرة ("فـ"، "ثم"، "إلا"…)، ولا داخل حوار قصة ("قال"…)،
/// ولا في أحكام مفصّلة. لكل يوم مجموعته، وهي نفسها لكل القرّاء.
class AyahOfTheDay {
  AyahOfTheDay._();

  /// عدد آيات بطاقة الرئيسية في اليوم، تتتابع واحدة بعد أخرى.
  static const perDay = 12;

  static List<Ayah>? _pool;
  static List<Ayah>? _curated;

  /// كل آية يمكن عرضها، بترتيب المصحف.
  static List<Ayah> get pool => _pool ??= _buildPool();

  /// الآيات المنتقاة (أدعية القرآن وآيات المسارات)؛ كل يوم يبدأ بإحداها.
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

  /// كلمات إن بدأت بها الآية فهي تكمل ما قبلها أو حوار قصة.
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

  /// كلمات الأحكام المفصّلة (النكاح والطلاق والميراث والطهارة).
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

  /// هل تُقرأ [ayah] ويُتدبّر فيها وحدها.
  static bool readsAlone(Ayah ayah) {
    var text = ArabicSearchNormalizer.normalize(ayah.rawText).trim();
    // أول آية في السورة تحمل البسملة في نصها.
    if (text.startsWith(_basmala)) {
      text = text.substring(_basmala.length).trim();
    }
    // الحروف فقط دون تشكيل: من سطر إلى فقرة قصيرة.
    final letters = text.replaceAll(' ', '').length;
    if (letters < 25 || letters > 170) return false;
    final words = text.split(RegExp(r'\s+'));
    final first = words.first;
    // "فـ" تكمل ما قبلها (فقال، فلما…)، أما "في" فحرف جر.
    if (first.startsWith('ف') && first != 'في') return false;
    if (_openers.contains(first)) return false;
    return !_rulings.any(text.contains);
  }

  static int _dayIndex(DateTime day) => DateTime.utc(
    day.year,
    day.month,
    day.day,
  ).difference(DateTime.utc(2020)).inDays;

  /// آيات [day] بالترتيب الذي تعرضه بطاقة الرئيسية.
  static List<Ayah> forDayAll(DateTime day) {
    final p = pool;
    final c = curated;
    final index = _dayIndex(day);
    final first = c[(index * 7919) % c.length];
    final base = index * perDay;
    // خطوة أولية كبيرة توزّعها على المصحف.
    final rest = [
      for (var i = 0; i < perDay; i++) p[((base + i) * 7919) % p.length],
    ].where((a) => a.id != first.id).take(perDay - 1);
    return [first, ...rest];
  }

  /// أول آية في [day].
  static Ayah forDay(DateTime day) => forDayAll(day).first;

  /// سؤال التدبر مع الآية رقم [index] في [day].
  static String questionFor(DateTime day, int index) {
    final ayah = forDayAll(day)[index];
    return TadbeerQuestions.forAyah(ayah)[questionIndex(day, index)];
  }

  /// أي الأسئلة الأربعة تطرحه البطاقة، ليفتح التدبر عليه.
  static int questionIndex(DateTime day, int index) =>
      (_dayIndex(day) + index) % TadbeerItem.questions.length;
}

/// بطاقة «آية للتدبّر» في الرئيسية: آيات اليوم تتتابع تلقائياً.
///
/// تتتابع كل [_interval] ما دامت البطاقة ظاهرة؛ السحب ينقل باليد، والإصبع على
/// البطاقة يوقفها. وتثبت مع "تقليل الحركة" أو قارئ الشاشة، وتنتقل إلى آيات
/// اليوم الجديد بعد منتصف الليل.
class AyahOfTheDayCard extends StatefulWidget {
  const AyahOfTheDayCard({super.key});

  /// ارتفاع ما عدا الآية والسؤال: الحشوة وسطر العنوان والفراغات والإجراءات
  /// والنقاط.
  static const _chrome = 16 + 10 + 24 + 12 + 8 + 40 + 13.0;

  /// أقل ارتفاع تحتاجه البطاقة بعرض [width] لتعرض كل آيات اليوم كاملة مع
  /// إجراءاتها؛ وقد يتنحى السؤال.
  static double minHeight(BuildContext context, double width) {
    final looks = _VerseLook.of(AyahOfTheDay.forDayAll(DateTime.now()));
    return _chrome +
        _tallest(context, [
          for (final l in looks)
            (l.text, l.at(_FittedVerse.minSize, _FittedVerse.tightHeight)),
        ], width - _AyahOfTheDayCardState._padH * 2);
  }

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

  /// هل خطوط مصحف المدينة لآيات اليوم قيد التحميل.
  bool _preparing = false;

  @override
  void initState() {
    super.initState();
    _load(DateTime.now());
    _restart();
  }

  /// يحمّل خطوط مصحف المدينة لآيات اليوم إن كان هو المختار؛ وحتى ذلك تظهر الآية
  /// بخط النص المتدفق.
  void _prepareGlyphs() {
    if (_preparing || !_VerseLook.madinah) return;
    if (_ayahs.every((a) => QcfGlyphs.of(a) != null)) return;
    _preparing = true;
    Future.wait(_ayahs.map(QcfGlyphs.prepare)).whenComplete(() {
      _preparing = false;
      if (mounted) setState(() {});
    });
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

  /// هل يجوز أن تتحرك السلسلة وحدها الآن.
  bool get _mayMove {
    if (!mounted || _held) return false;
    if (!TickerMode.valuesOf(context).enabled) return false;
    // تثبت تحت لوحة أو صفحة مفتوحة فوقها، كالتدبر.
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

  /// الحشوة الأفقية داخل البطاقة.
  static const _padH = 18.0;

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
    _prepareGlyphs();
    final looks = _VerseLook.of(_ayahs);
    const questionStyle = TextStyle(
      color: gold,
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
    );

    return Listener(
      // الإصبع على البطاقة يوقف السلسلة.
      onPointerDown: (_) => _held = true,
      onPointerUp: (_) => _held = false,
      onPointerCancel: (_) => _held = false,
      child: GestureDetector(
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v.abs() < 200) return;
          // السحب نحو نهاية اتجاه القراءة يعرض التالية.
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
                padding: const EdgeInsets.fromLTRB(_padH, 16, _padH, 10),
                // إن أُعطيت ارتفاعاً (صفحة بقدر الشاشة) تأخذ الآية ما بقي؛ وفي
                // البطاقة القصيرة يتنحى السؤال ثم الإجراءات لتبقى الآية ظاهرة.
                child: LayoutBuilder(
                  builder: (context, box) {
                    final bounded = box.maxHeight.isFinite;
                    // لا يظهر السؤال إلا إن بقيت الآية كاملة بجانبه.
                    var showQuestion = true;
                    if (bounded) {
                      final verse = _tallest(context, [
                        for (final l in looks)
                          (
                            l.text,
                            l.at(
                              _FittedVerse.minSize,
                              _FittedVerse.tightHeight,
                            ),
                          ),
                      ], box.maxWidth);
                      final question = _tallest(context, [
                        for (var i = 0; i < _ayahs.length; i++)
                          (
                            AyahOfTheDay.questionFor(_day, i),
                            DefaultTextStyle.of(context).style
                                .merge(questionStyle),
                          ),
                      ], box.maxWidth);
                      final free =
                          box.maxHeight -
                          (AyahOfTheDayCard._chrome - 26) -
                          verse;
                      showQuestion = free >= question + 6;
                    }
                    final showActions = !bounded || box.maxHeight >= 110;
                    return AnimatedSwitcher(
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
                              const Icon(
                                AppIcons.sunFill,
                                color: gold,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l10n.widgetAyahTitle,
                                style: const TextStyle(
                                  color: gold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // أسماء السور الطويلة تصغر بدل أن تفيض.
                              Expanded(
                                child: Text(
                                  l10n.ayahReference(
                                    surah.name,
                                    ayah.ayahNumber,
                                  ),
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
                          if (bounded)
                            Expanded(
                              child: _FittedVerse(
                                looks: looks,
                                shown: looks[_index],
                              ),
                            )
                          else
                            _SteadyHeight(
                              items: [
                                for (final l in looks) (l.text, l.at(21, 2)),
                              ],
                              child: Text(
                                looks[_index].text,
                                textAlign: TextAlign.center,
                                style: looks[_index].at(21, 2),
                              ),
                            ),
                          const SizedBox(height: 8),
                          // علامة تظهر بعد التدبر في هذه الآية.
                          if (showQuestion)
                            _SteadyHeight(
                              items: [
                                for (var i = 0; i < _ayahs.length; i++)
                                  (
                                    AyahOfTheDay.questionFor(_day, i),
                                    questionStyle,
                                  ),
                              ],
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                                          AyahOfTheDay.questionFor(
                                            _day,
                                            _index,
                                          ),
                                          textAlign: TextAlign.center,
                                          style: questionStyle,
                                        );
                                },
                              ),
                            ),
                          if (showQuestion) const SizedBox(height: 6),
                          // تلتف في الهواتف الضيقة بدل أن تفيض.
                          if (showActions)
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
                                  onTap: () =>
                                      AyahShareSheet.show(context, ayah),
                                ),
                                _Action(
                                  icon: AppIcons.personSimpleTaiChi,
                                  label: l10n.focusMode,
                                  onTap: () =>
                                      FocusModeScreen.open(context, ayah),
                                ),
                              ],
                            ),
                          _Dots(
                            count: _ayahs.length,
                            current: _index,
                            color: gold,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// يعطي [child] ارتفاع أطول عناصر [items]، فتبقى البطاقة بحجم واحد وآيات اليوم
/// تتتابع.
class _SteadyHeight extends StatelessWidget {
  final List<(String, TextStyle)> items;
  final Widget child;

  const _SteadyHeight({required this.items, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => SizedBox(
        height: _tallest(context, items, box.maxWidth),
        child: Center(child: child),
      ),
    );
  }
}

/// ارتفاع أطول [items]، كل نص بنمطه، مرصوفاً بعرض [width].
double _tallest(
  BuildContext context,
  List<(String, TextStyle)> items,
  double width,
) {
  final scaler = MediaQuery.textScalerOf(context);
  final direction = Directionality.of(context);
  final base = DefaultTextStyle.of(context).style;
  var h = 0.0;
  for (final (text, style) in items) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: base.merge(style)),
      textAlign: TextAlign.center,
      textDirection: direction,
      textScaler: scaler,
    )..layout(maxWidth: width);
    h = math.max(h, painter.height);
    painter.dispose();
  }
  return h;
}

/// كيف تُكتب الآية على البطاقة: بخطوط مصحف المدينة وعلامة آيتها حين يكون هو
/// المختار، أو بخط النص المتدفق ورقم الآية بين قوسين.
class _VerseLook {
  final String text;

  /// نمط الآية بحجم [size] وتباعد أسطر [height].
  final TextStyle Function(double size, double height) at;

  const _VerseLook(this.text, this.at);

  static const _color = Color(0xFFF2EEE4);

  /// هل اختار القارئ مصحف المدينة.
  static bool get madinah =>
      UserDataStore.instance.settings.mushafStyle == MushafStyle.madinah;

  /// أشكال [ayahs]: كلها بخطوط المدينة متى حُمّلت جميعاً، فلا تخلط البطاقة بين
  /// الخطين.
  static List<_VerseLook> of(List<Ayah> ayahs) {
    if (madinah) {
      final glyphs = [for (final a in ayahs) QcfGlyphs.of(a)];
      if (glyphs.every((g) => g != null)) {
        return [
          for (final g in glyphs)
            _VerseLook(
              g!.text,
              (size, height) =>
                  g.style(fontSize: size, height: height, color: _color),
            ),
        ];
      }
    }
    final font = UserDataStore.instance.quranFontFamily;
    return [
      for (final a in ayahs)
        _VerseLook(
          '${a.text} ﴿${ArabicSearchNormalizer.toArabicDigits(a.ayahNumber)}﴾',
          (size, height) => TextStyle(
            fontFamily: font,
            fontSize: size,
            height: height,
            color: _color,
          ),
        ),
    ];
  }
}

/// الآية بأكبر حجم (حتى [minSize]) تتسع عنده كل [looks] في ارتفاعها، فتبقى
/// البطاقة بحجم واحد. وعند أصغر حجم تتقارب الأسطر ([tightHeight]) قبل أن يُقص
/// سطر.
class _FittedVerse extends StatelessWidget {
  final List<_VerseLook> looks;
  final _VerseLook shown;

  const _FittedVerse({required this.looks, required this.shown});

  /// أكبر حجم للآية.
  static const maxSize = 21.0;

  /// أصغر حجم للآية.
  static const minSize = 15.0;

  /// تباعد الأسطر عند أصغر حجم، أقرب من 2 المعتاد.
  static const tightHeight = 1.7;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        bool fits(double size, double height) =>
            _tallest(context, [
              for (final l in looks) (l.text, l.at(size, height)),
            ], box.maxWidth) <=
            box.maxHeight;

        var size = maxSize;
        var height = 2.0;
        while (size > minSize && !fits(size, height)) {
          size -= 1;
        }
        if (!fits(size, height)) height = tightHeight;
        final style = shown.at(size, height);
        final lineHeight =
            scaler.scale(style.fontSize ?? size) * (style.height ?? 1);
        final lines = box.maxHeight.isFinite
            ? math.max(1, (box.maxHeight / lineHeight).floor())
            : null;
        return Center(
          child: Text(
            shown.text,
            textAlign: TextAlign.center,
            maxLines: lines,
            overflow: lines == null ? null : TextOverflow.ellipsis,
            style: style,
          ),
        );
      },
    );
  }
}

/// موضع الآية المعروضة بين آيات اليوم.
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
      // متقاربة، لتتسع الثلاثة في صف واحد على هاتف ضيق.
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        visualDensity: VisualDensity.compact,
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}
