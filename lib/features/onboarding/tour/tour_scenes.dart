/// مشاهد الجولة وشروحات الأقسام: قصص قصيرة مرسومة من عناصر التطبيق نفسها.
///
/// كل مشهد يُبنى من تقدّم قصته [t] (انظر [SceneStory])، على لوحة ثابتة المقاس
/// تتسع للشاشة، فتبقى المواضع محسوبة على أي هاتف. ونصوص الآيات من ملف المصحف.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/localization.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/ornaments.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/arabic_search_normalizer.dart';
import '../../../data/models/tadbeer_model.dart';
import '../../../data/quran/quran_repository.dart';
import '../../../data/storage/user_data_store.dart';
import 'scene_story.dart';

/// عرض اللوحة وارتفاعها المنطقيان؛ تُكبَّر أو تُصغَّر لتملأ مكانها.
const _w = 320.0;
const _h = 220.0;

/// لوحة المشهد: مقاس ثابت يتسع لمكانه، باتجاه من اليمين لليسار.
class _Canvas extends StatelessWidget {
  final List<Widget> children;

  const _Canvas({required this.children});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _w / _h,
      child: FittedBox(
        child: SizedBox(
          width: _w,
          height: _h,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Stack(clipBehavior: Clip.none, children: children),
          ),
        ),
      ),
    );
  }
}

/// ألوان المشهد من الثيم المختار.
class _Palette {
  final Color primary;
  final Color gold;
  final Color surface;
  final Color text;
  final Color muted;
  final bool dark;

  _Palette(BuildContext context)
    : primary = Theme.of(context).colorScheme.primary,
      gold = AppColors.accentGold(context),
      surface = AppColors.surface(context),
      text = AppColors.textPrimary(context),
      muted = AppColors.textSecondary(context),
      dark = Theme.of(context).brightness == Brightness.dark;
}

/// نص الآية من ملف المصحف، أو نص احتياطي إن لم يُحمَّل بعد.
String _ayahText(int surah, int ayah, String fallback) {
  try {
    return QuranRepository.instance.getAyah(surah, ayah)?.text ?? fallback;
  } on Object {
    return fallback;
  }
}

/// «السورة رقم» مختصراً.
String _ref(BuildContext context, int surah, int ayah) {
  try {
    final name = QuranRepository.instance.getSurah(surah).name;
    return '$name ${context.l10n.digits(ayah)}';
  } on Object {
    return context.l10n.digits(ayah);
  }
}

/// كلمات من [start] إلى ما قبل [end] من الآية، فيبقى رسمها كما في المصحف.
String _ayahWords(int surah, int ayah, int start, int end) {
  final words = _ayahText(surah, ayah, '').split(' ');
  return end > words.length ? '' : words.sublist(start, end).join(' ');
}

/// الآية التي تفتتح الجولة: غاية التطبيق بلفظ القرآن.
String tourOpeningAyah(String fallback) {
  final words = _ayahWords(38, 29, 0, 6);
  return words.isEmpty ? fallback : '﴿$words﴾';
}

TextStyle _quran(double size, Color color) => TextStyle(
  fontFamily: UserDataStore.instance.quranFontFamily,
  fontSize: size,
  height: 1.7,
  color: color,
);

TextStyle _ui(double size, Color color, {bool bold = false}) => TextStyle(
  fontFamily: AppTheme.appFontFamily,
  fontSize: size,
  height: 1.3,
  color: color,
  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
);

/// بطاقة المشهد: سطح التطبيق بإطار ذهبي خفيف.
Widget _card(_Palette c, {required Widget child, EdgeInsets? padding}) {
  return Container(
    padding: padding ?? const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: c.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: c.gold.withValues(alpha: 0.4)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: c.dark ? 0.35 : 0.08),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

/// إصبع يلمس الشاشة: دائرة شفافة تنكمش عند الضغط.
Widget _finger(_Palette c, Offset at, double press, {double opacity = 1}) {
  final size = 34.0 * (1 - 0.22 * press);
  return Positioned(
    left: at.dx - size / 2,
    top: at.dy - size / 2,
    child: IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.55),
            border: Border.all(color: c.gold, width: 2),
            boxShadow: [
              BoxShadow(
                color: c.gold.withValues(alpha: 0.5 * press),
                blurRadius: 16,
                spreadRadius: 4 * press,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// نقطة على خط مستقيم بين [a] و[b] عند [p].
Offset _lerp(Offset a, Offset b, double p) => Offset.lerp(a, b, p)!;

/// علامة رقم الآية: دائرة ذهبية برقمها.
Widget _ayahMarker(_Palette c, int n, {double size = 26}) {
  return Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: c.gold, width: 1.6),
    ),
    child: Text(
      ArabicSearchNormalizer.toArabicDigits(n),
      style: _ui(size * 0.42, c.gold, bold: true),
    ),
  );
}

// ─────────────────────────────── المصحف ───────────────────────────────

/// ضغطة مطوّلة على آية تفتح القائمة الدائرية؛ ثم يختار القارئ منها.
///
/// مع [pickCenter] يضغط وسط القائمة («وقفة تدبر»)، وإلا اختار الحفظ فطارت
/// أيقونته إلى رقم الآية.
class MushafScene extends StatelessWidget {
  final double t;
  final bool pickCenter;

  const MushafScene({super.key, required this.t, this.pickCenter = false});

  static const _centre = Offset(160, 128);
  static const _ring = 62.0;
  static const _marker = Offset(46, 52);

  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final l10n = context.l10n;
    final approach = phase(t, 0.0, 0.16);
    final press = phase(t, 0.16, 0.24) * (1 - phase(t, 0.26, 0.3));
    final open = phase(t, 0.28, 0.48);
    final toPetal = phase(t, 0.5, 0.6);
    final pick = phase(t, 0.6, 0.65) * (1 - phase(t, 0.67, 0.7));
    final close = phase(t, 0.68, 0.76);
    final fly = phase(t, 0.74, 0.88, Curves.easeInOutCubic);
    final pulse = math.sin(phase(t, 0.88, 0.97) * math.pi);

    final petals = <(IconData, String)>[
      (AppIcons.notePencil, l10n.addNote),
      (AppIcons.headphones, l10n.listen),
      (AppIcons.brain, l10n.addToMemorization),
      (AppIcons.bookmarkSimple, l10n.markAyah),
      (AppIcons.graph, l10n.ayahLinks),
    ];
    Offset petalAt(int i) {
      final a = -math.pi / 2 + i * 2 * math.pi / petals.length;
      return _centre + Offset(_ring * math.cos(a), _ring * math.sin(a));
    }

    const brain = 2;
    final target = pickCenter ? _centre : petalAt(brain);
    final fingerStart = const Offset(280, 210);
    final fingerAt = t < 0.5
        ? _lerp(fingerStart, const Offset(200, 52), approach)
        : _lerp(const Offset(200, 52), target, toPetal);
    final fingerOpacity = 1 - close;
    final ringOpacity = open * (1 - close);
    final highlight = phase(t, 0.2, 0.3) * (1 - fly * 0.6);

    return _Canvas(
      children: [
        Positioned(
          left: 8,
          right: 8,
          top: 18,
          child: _card(
            c,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: c.gold.withValues(alpha: 0.22 * highlight),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _ayahText(1, 2, 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ'),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: _quran(22, c.text),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _ayahMarker(c, 2),
              ],
            ),
          ),
        ),
        // علامة الحفظ تستقر فوق رقم الآية.
        if (!pickCenter && fly > 0)
          Positioned(
            left: _lerp(petalAt(brain), _marker, fly).dx - 10,
            top: _lerp(petalAt(brain), _marker, fly).dy - 10 - 12 * fly,
            child: Transform.scale(
              scale: 1 + 0.35 * pulse,
              child: Icon(AppIcons.brainFill, size: 20, color: c.gold),
            ),
          ),
        if (ringOpacity > 0)
          Positioned.fill(
            child: Opacity(
              opacity: ringOpacity,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: _centre.dx - _ring - 26,
                    top: _centre.dy - _ring - 26,
                    child: Transform.scale(
                      scale: 0.6 + 0.4 * open,
                      child: Container(
                        width: (_ring + 26) * 2,
                        height: (_ring + 26) * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.primary.withValues(alpha: 0.92),
                          border: Border.all(color: c.gold, width: 1.4),
                        ),
                      ),
                    ),
                  ),
                  for (var i = 0; i < petals.length; i++)
                    _petal(
                      c,
                      petalAt(i),
                      petals[i].$1,
                      phase(open, i * 0.12, 0.5 + i * 0.12),
                      picked: !pickCenter && i == brain ? pick : 0,
                    ),
                  Positioned(
                    left: _centre.dx - 30,
                    top: _centre.dy - 30,
                    child: Transform.scale(
                      scale: 1 - 0.12 * (pickCenter ? pick : 0),
                      child: Container(
                        width: 60,
                        height: 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.surface,
                          border: Border.all(color: c.gold, width: 2),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              AppIcons.flowerLotusFill,
                              size: 18,
                              color: c.primary,
                            ),
                            Text(
                              l10n.tadbeerPause,
                              style: _ui(7.5, c.text, bold: true),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        _finger(c, fingerAt, math.max(press, pick), opacity: fingerOpacity),
      ],
    );
  }

  Widget _petal(
    _Palette c,
    Offset at,
    IconData icon,
    double p, {
    double picked = 0,
  }) {
    return Positioned(
      left: at.dx - 17,
      top: at.dy - 17,
      child: popIn(
        p,
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(
              Colors.white.withValues(alpha: 0.14),
              c.gold,
              picked,
            ),
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(icon, size: 17, color: Colors.white),
        ),
      ),
    );
  }
}

// ─────────────────────────────── التدبّر ───────────────────────────────

/// بطاقة الوقفة: تُكتب أسئلتها الأربعة سطراً بعد سطر.
///
/// مع [answer] تمتلئ إجابة السؤال الثاني ويُضغط الحفظ، وإلا تنكمش البطاقة إلى
/// عقدة تجتمع حولها آيتان في شبكة.
class ReflectScene extends StatelessWidget {
  final double t;
  final bool answer;

  const ReflectScene({super.key, required this.t, this.answer = false});

  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final l10n = context.l10n;
    const questions = TadbeerItem.questions;
    final typing = answer ? phase(t, 0.0, 0.42) : phase(t, 0.0, 0.55);
    final shrink = answer ? 0.0 : phase(t, 0.74, 0.8);
    final answerType = answer ? phase(t, 0.45, 0.72) : 0.0;
    final savePress = answer ? math.sin(phase(t, 0.78, 0.86) * math.pi) : 0.0;
    final saved = answer ? phase(t, 0.86, 0.94) : 0.0;

    final card = _card(
      c,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(AppIcons.flowerLotusFill, size: 16, color: c.gold),
              const SizedBox(width: 6),
              Text(l10n.tadbeerPause, style: _ui(12, c.text, bold: true)),
            ],
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < questions.length; i++) ...[
            _typed(
              questions[i],
              phase(typing, i * 0.25, (i + 1) * 0.25),
              _ui(10.5, c.text),
            ),
            if (answer && i == 1)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 10, top: 2),
                child: _typed(
                  l10n.tourSampleAnswer,
                  answerType,
                  _ui(10, c.primary, bold: true),
                ),
              ),
            const SizedBox(height: 3),
          ],
          if (answer)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Transform.scale(
                scale: 1 - 0.1 * savePress,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Color.lerp(c.primary, c.gold, saved),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (saved > 0)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 4),
                          child: popIn(
                            saved,
                            const Icon(
                              AppIcons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      Text(l10n.save, style: _ui(10, Colors.white, bold: true)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return _Canvas(
      children: [
        Positioned(
          left: 34,
          right: 34,
          top: 6,
          child: Opacity(
            opacity: 1 - shrink,
            child: Transform.scale(scale: 1 - 0.7 * shrink, child: card),
          ),
        ),
        if (!answer && shrink > 0)
          Positioned.fill(
            child: LinkNetwork(
              t: phase(t, 0.76, 1),
              centreLabel: l10n.tourSampleLink,
            ),
          ),
        if (answer)
          _finger(
            c,
            _lerp(
              const Offset(260, 210),
              const Offset(64, 196),
              phase(t, 0.7, 0.78),
            ),
            savePress,
            opacity: phase(t, 0.68, 0.72) * (1 - phase(t, 0.9, 0.95)),
          ),
      ],
    );
  }
}

/// نص يُكتب من اليمين بقدر [p].
Widget _typed(String text, double p, TextStyle style) {
  return ClipRect(
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: p.clamp(0.0, 1.0),
      child: Text(text, style: style, maxLines: 1, softWrap: false),
    ),
  );
}

/// وقفاتي: وقفة جديدة تنزلق إلى أول القائمة وعليها زهرة التدبّر.
class ReflectionsListScene extends StatelessWidget {
  final double t;

  const ReflectionsListScene({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final l10n = context.l10n;
    final slide = phase(t, 0.1, 0.45, Curves.easeOutBack);
    final glow = math.sin(phase(t, 0.5, 0.8) * math.pi);
    Widget row(int surah, int ayah, String text, {double opacity = 1}) {
      return Opacity(
        opacity: opacity,
        child: _card(
          c,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(AppIcons.flowerLotusFill, size: 18, color: c.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _ref(context, surah, ayah),
                      style: _ui(11, c.text, bold: true),
                    ),
                    Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _ui(9.5, c.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _Canvas(
      children: [
        Positioned(
          left: 30,
          right: 30,
          top: 8,
          child: Row(
            children: [
              Icon(AppIcons.flowerLotus, size: 16, color: c.primary),
              const SizedBox(width: 6),
              Text(l10n.myReflections, style: _ui(13, c.text, bold: true)),
            ],
          ),
        ),
        Positioned(
          left: 30,
          right: 30,
          top: 40 + 56 * slide,
          child: row(94, 5, l10n.tourSampleAnswer2, opacity: 0.55),
        ),
        Positioned(
          left: 30,
          right: 30,
          top: 96 + 56 * slide,
          child: row(
            13,
            28,
            l10n.tourSampleAnswer3,
            opacity: 0.4 * (1 - slide),
          ),
        ),
        Positioned(
          left: 30,
          right: 30,
          top: 40,
          child: Opacity(
            opacity: slide.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, -24 * (1 - slide)),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: c.gold.withValues(alpha: 0.45 * glow),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: row(2, 153, l10n.tourSampleAnswer),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────── الروابط ───────────────────────────────

/// شبكة روابط عن أبواب الرزق: ثلاث آيات تنضم إلى الموضوع، ولكل منها ملاحظة.
///
/// الطلاق ٢-٣ (التقوى)، ونوح ١٠-١١ (الاستغفار)، وإبراهيم ٧ (الشكر)؛ فتصل فكرة
/// الربط: آيات من سور متفرقة تهدف إلى معنى واحد ويدعم بعضها بعضاً.
class LinkNetwork extends StatelessWidget {
  final double t;
  final String centreLabel;
  final IconData centreIcon;

  /// كم آية تنضم؛ وأولها يظهر أولاً.
  final int verses;

  /// هل تظهر ملاحظة كل آية تحتها.
  final bool notes;

  const LinkNetwork({
    super.key,
    required this.t,
    required this.centreLabel,
    this.centreIcon = AppIcons.graphFill,
    this.verses = 3,
    this.notes = false,
  });

  static const _centre = Offset(160, 104);
  static const _spots = [Offset(72, 40), Offset(248, 40), Offset(160, 184)];

  static String _verse(int i, AppStrings l10n) {
    final text = switch (i) {
      0 =>
        '${_ayahWords(65, 2, 26, 32)} ۝ '
            '${_ayahWords(65, 3, 0, 5)}',
      1 =>
        '${_ayahWords(71, 10, 1, 3)} ۝ '
            '${_ayahWords(71, 11, 0, 4)}',
      _ => _ayahWords(14, 7, 3, 6),
    };
    return text.trim() == '۝' ? '' : text;
  }

  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final l10n = context.l10n;
    final noteTexts = [
      l10n.tourLinkNote1,
      l10n.tourLinkNote2,
      l10n.tourLinkNote3,
    ];
    final n = verses.clamp(1, _spots.length);
    final join = [
      for (var i = 0; i < n; i++)
        phase(t, i * 0.22, 0.24 + i * 0.22, Curves.easeOutBack),
    ];
    final noteIn = [
      for (var i = 0; i < n; i++) phase(t, 0.1 + i * 0.22, 0.3 + i * 0.22),
    ];
    final lines = [
      for (var i = 0; i < n; i++) phase(t, 0.16 + i * 0.22, 0.36 + i * 0.22),
    ];
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _ThreadsPainter(
              centre: _centre,
              spots: _spots.take(n).toList(),
              progress: lines,
              color: c.gold,
            ),
          ),
        ),
        for (var i = 0; i < n; i++)
          Positioned(
            left: _spots[i].dx - _nodeWidth(i) / 2,
            top: i == 2 ? _spots[i].dy - 22 : 2,
            child: popIn(
              join[i],
              Container(
                width: _nodeWidth(i),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.gold.withValues(alpha: 0.7)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: c.dark ? 0.3 : 0.06,
                      ),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _verse(i, l10n),
                      textAlign: TextAlign.center,
                      style: _quran(10, c.text).copyWith(height: 1.55),
                    ),
                    if (notes)
                      Opacity(
                        opacity: noteIn[i],
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            noteTexts[i],
                            textAlign: TextAlign.center,
                            style: _ui(8.5, c.primary, bold: true),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          left: _centre.dx - 34,
          top: _centre.dy - 34,
          child: Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.primary,
              border: Border.all(color: c.gold, width: 2),
              boxShadow: [
                BoxShadow(
                  color: c.gold.withValues(alpha: 0.35),
                  blurRadius: 14,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(centreIcon, size: 18, color: c.gold),
                Text(
                  centreLabel,
                  maxLines: 1,
                  style: _ui(10, Colors.white, bold: true),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

double _nodeWidth(int i) => i == 2 ? 150 : 136;

class _ThreadsPainter extends CustomPainter {
  final Offset centre;
  final List<Offset> spots;
  final List<double> progress;
  final Color color;

  _ThreadsPainter({
    required this.centre,
    required this.spots,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < spots.length; i++) {
      final p = progress[i];
      if (p <= 0) continue;
      canvas.drawLine(centre, Offset.lerp(centre, spots[i], p)!, paint);
    }
  }

  @override
  bool shouldRepaint(_ThreadsPainter old) =>
      old.progress != progress || old.color != color;
}

/// إنشاء رابط: يُكتب عنوانه ويُضغط «إنشاء» فتولد عقدته.
class CreateLinkScene extends StatelessWidget {
  final double t;

  const CreateLinkScene({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final l10n = context.l10n;
    final type = phase(t, 0.1, 0.4);
    final press = math.sin(phase(t, 0.48, 0.56) * math.pi);
    final morph = phase(t, 0.58, 0.75);
    return _Canvas(
      children: [
        Positioned(
          left: 50,
          right: 50,
          top: 24,
          child: Opacity(
            opacity: 1 - morph,
            child: Transform.scale(
              scale: 1 - 0.5 * morph,
              child: _card(
                c,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.tourCreateLink,
                      style: _ui(12, c.text, bold: true),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: c.gold.withValues(alpha: 0.6),
                        ),
                      ),
                      child: _typed(
                        l10n.tourSampleLink,
                        type,
                        _ui(12, c.text, bold: true),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Transform.scale(
                        scale: 1 - 0.1 * press,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: c.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            l10n.create,
                            style: _ui(10.5, Colors.white, bold: true),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (morph > 0)
          Positioned.fill(
            child: Opacity(
              opacity: morph,
              child: LinkNetwork(
                t: 0,
                verses: 1,
                centreLabel: l10n.tourSampleLink,
              ),
            ),
          ),
        _finger(
          c,
          _lerp(
            const Offset(250, 200),
            const Offset(84, 124),
            phase(t, 0.4, 0.48),
          ),
          press,
          opacity: phase(t, 0.38, 0.42) * (1 - phase(t, 0.6, 0.66)),
        ),
      ],
    );
  }
}

/// تنضم ثلاث آيات عن الصبر إلى الرابط، ولكل منها ملاحظة، وتُرسم خيوطها.
class AddVersesScene extends StatelessWidget {
  final double t;

  const AddVersesScene({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    return _Canvas(
      children: [
        Positioned.fill(
          child: LinkNetwork(
            t: t,
            notes: true,
            centreLabel: context.l10n.tourSampleLink,
          ),
        ),
      ],
    );
  }
}

/// الشبكة تكتمل آية بعد آية، ولكل آية ملاحظتها.
class WholeNetworkScene extends StatelessWidget {
  final double t;

  const WholeNetworkScene({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    return _Canvas(
      children: [
        Positioned.fill(
          child: LinkNetwork(
            t: t,
            notes: true,
            centreLabel: context.l10n.tourSampleLink,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────── المسارات ───────────────────────────────

/// مسار من سبعة أيام: يُضاء يومه الأول ثم الذي بعده.
class PathwayDaysScene extends StatelessWidget {
  final double t;

  /// كم يوماً أُنجز في آخر المشهد.
  final int done;

  const PathwayDaysScene({super.key, required this.t, this.done = 1});

  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final l10n = context.l10n;
    final appear = phase(t, 0.0, 0.25);
    final advance = phase(t, 0.35, 0.7);
    const days = 7;
    return _Canvas(
      children: [
        Positioned(
          left: 18,
          right: 18,
          top: 30,
          child: riseIn(
            appear,
            _card(
              c,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(AppIcons.path, size: 18, color: c.gold),
                      const SizedBox(width: 6),
                      Text(
                        l10n.tourSamplePathway,
                        style: _ui(13, c.text, bold: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.tourSamplePathwayHint, style: _ui(10, c.muted)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (var d = 0; d < days; d++) ...[
                        if (d > 0)
                          Expanded(
                            child: Container(
                              height: 2,
                              color: d <= done - 1 + advance
                                  ? c.gold
                                  : c.muted.withValues(alpha: 0.25),
                            ),
                          ),
                        _day(c, d, done, advance),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _day(_Palette c, int d, int done, double advance) {
    final isDone = d < done - 1 || (d == done - 1 && advance > 0.5);
    final isNext = d == done - 1 + (advance > 0.5 ? 1 : 0);
    final glow = isNext ? math.sin(advance * math.pi) : 0.0;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone ? c.gold : (isNext ? c.primary : c.surface),
        border: Border.all(
          color: isDone || isNext ? c.gold : c.muted.withValues(alpha: 0.4),
          width: 1.6,
        ),
        boxShadow: [
          if (isNext)
            BoxShadow(
              color: c.gold.withValues(alpha: 0.5 * (0.4 + glow)),
              blurRadius: 12,
              spreadRadius: 1,
            ),
        ],
      ),
      child: isDone
          ? const Icon(AppIcons.check, size: 14, color: Colors.white)
          : Text(
              ArabicSearchNormalizer.toArabicDigits(d + 1),
              style: _ui(10, isNext ? Colors.white : c.muted, bold: true),
            ),
    );
  }
}

/// آية اليوم، ثم يطفو سؤالها تحتها.
class TodayAyahScene extends StatelessWidget {
  final double t;

  const TodayAyahScene({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final l10n = context.l10n;
    final ayah = phase(t, 0.0, 0.3);
    final question = phase(t, 0.35, 0.6);
    return _Canvas(
      children: [
        Positioned(
          left: 16,
          right: 16,
          top: 14,
          child: riseIn(
            ayah,
            _card(
              c,
              child: Column(
                children: [
                  Text(l10n.tourDayOne, style: _ui(10, c.gold, bold: true)),
                  const SizedBox(height: 4),
                  Text(
                    _ayahText(
                      2,
                      153,
                      'يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوا۟ ٱسْتَعِينُوا۟ بِٱلصَّبْرِ وَٱلصَّلَوٰةِ',
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: _quran(15, c.text),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 40,
          right: 40,
          bottom: 8,
          child: riseIn(
            question,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.lightbulbFill, size: 16, color: c.gold),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.tourSampleQuestion,
                      style: _ui(10.5, Colors.white, bold: true),
                    ),
                  ),
                ],
              ),
            ),
            distance: 24,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────── الاستماع ───────────────────────────────

/// تلاوة سورة الإخلاص: الضوء ينتقل من آية لأخرى، ثم يُختار «آية واحدة».
class ListenScene extends StatelessWidget {
  final double t;

  const ListenScene({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final l10n = context.l10n;
    final current = t < 0.2 ? 0 : (t < 0.4 ? 1 : 2);
    final toggled = t >= 0.5;
    final finished = t >= 0.74;
    final press = math.sin(phase(t, 0.44, 0.52) * math.pi);
    const fallback = [
      'قُلْ هُوَ ٱللَّهُ أَحَدٌ',
      'ٱللَّهُ ٱلصَّمَدُ',
      'لَمْ يَلِدْ وَلَمْ يُولَدْ',
    ];
    return _Canvas(
      children: [
        Positioned(
          left: 30,
          right: 30,
          top: 4,
          child: Column(
            children: [
              for (var i = 0; i < 3; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: c.gold.withValues(
                      alpha: i == current && !finished ? 0.24 : 0,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _ayahText(112, i + 1, fallback[i]),
                          maxLines: 1,
                          style: _quran(18, c.text),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _ayahMarker(c, i + 1, size: 20),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          left: 6,
          right: 6,
          bottom: 4,
          child: _card(
            c,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Icon(AppIcons.skipBackFill, size: 16, color: c.text),
                const SizedBox(width: 6),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: c.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    finished ? AppIcons.playFill : AppIcons.pauseFill,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(AppIcons.skipForwardFill, size: 16, color: c.text),
                const SizedBox(width: 4),
                Transform.scale(
                  scale: 1 + 0.25 * press,
                  child: Icon(
                    toggled ? AppIcons.repeatOnce : AppIcons.repeat,
                    size: 18,
                    color: toggled ? c.gold : c.text,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _ref(context, 112, current + 1),
                        maxLines: 1,
                        style: _ui(10, c.text, bold: true),
                      ),
                      Text(
                        finished ? l10n.ayahFinished : l10n.tourSampleReciter,
                        maxLines: 1,
                        style: _ui(9, finished ? c.gold : c.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _finger(
          c,
          _lerp(
            const Offset(250, 120),
            const Offset(205, 194),
            phase(t, 0.36, 0.44),
          ),
          press,
          opacity: phase(t, 0.34, 0.38) * (1 - phase(t, 0.56, 0.62)),
        ),
      ],
    );
  }
}

// ─────────────────────────────── الرحلة ───────────────────────────────

/// الختمة تتقدّم، والسلسلة تزيد يوماً، والسبحة تكمل ثلاثاً وثلاثين، والودجت
/// يظهر على شاشة الهاتف.
class JourneyScene extends StatelessWidget {
  final double t;

  const JourneyScene({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final l10n = context.l10n;
    final ring = phase(t, 0.0, 0.35);
    final flip = phase(t, 0.32, 0.46);
    final beads = phase(t, 0.42, 0.66);
    final count = 30 + (3 * beads).round();
    final sparkle = phase(t, 0.64, 0.74, Curves.easeOutBack);
    final phone = phase(t, 0.66, 0.84);
    return _Canvas(
      children: [
        // حلقة الختمة.
        Positioned(
          right: 18,
          top: 20,
          child: Column(
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: CustomPaint(
                  painter: _RingPainter(0.4 * ring, c.gold, c.muted),
                  child: Center(
                    child: Text(
                      '${l10n.digits((40 * ring).round())}٪',
                      style: _ui(16, c.text, bold: true),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(l10n.tourKhatma, style: _ui(10, c.muted)),
            ],
          ),
        ),
        // السلسلة.
        Positioned(
          right: 128,
          top: 30,
          child: Column(
            children: [
              Icon(
                AppIcons.fire,
                size: 30 + 6 * math.sin(flip * math.pi),
                color: const Color(0xFFE0782E),
              ),
              SizedBox(
                height: 24,
                width: 36,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: 1 - flip,
                      child: Transform.translate(
                        offset: Offset(0, -12 * flip),
                        child: Text(
                          l10n.digits(6),
                          style: _ui(18, c.text, bold: true),
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: flip,
                      child: Transform.translate(
                        offset: Offset(0, 12 * (1 - flip)),
                        child: Text(
                          l10n.digits(7),
                          style: _ui(18, c.text, bold: true),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(l10n.tourStreak, style: _ui(10, c.muted)),
            ],
          ),
        ),
        // السبحة.
        Positioned(
          right: 26,
          top: 130,
          child: SizedBox(
            width: 76,
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: beads * math.pi * 0.6,
                  child: CustomPaint(
                    size: const Size(76, 76),
                    painter: _BeadsPainter(c.primary, c.gold),
                  ),
                ),
                Text(l10n.digits(count), style: _ui(15, c.text, bold: true)),
                Positioned(
                  top: 0,
                  right: 0,
                  child: popIn(
                    sparkle,
                    Icon(AppIcons.sparkleFill, size: 18, color: c.gold),
                  ),
                ),
              ],
            ),
          ),
        ),
        // الهاتف والودجت.
        Positioned(
          left: 22 - 60 * (1 - phone),
          top: 24,
          child: Opacity(
            opacity: phone,
            child: Container(
              width: 112,
              height: 182,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: c.dark
                    ? const Color(0xFF0E1622)
                    : const Color(0xFF1B2535),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: c.gold.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: c.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          l10n.widgetAyahTitle,
                          style: _ui(7, c.gold, bold: true),
                        ),
                        Text(
                          _ayahText(
                            13,
                            28,
                            'أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ',
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: _quran(9, Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (var i = 0; i < 4; i++)
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color track;

  _RingPainter(this.value, this.color, this.track);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    paint.color = track.withValues(alpha: 0.18);
    canvas.drawArc(rect.deflate(5), 0, 2 * math.pi, false, paint);
    paint.color = color;
    canvas.drawArc(
      rect.deflate(5),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color;
}

class _BeadsPainter extends CustomPainter {
  final Color bead;
  final Color accent;

  _BeadsPainter(this.bead, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 6;
    for (var i = 0; i < 16; i++) {
      final a = i * 2 * math.pi / 16;
      canvas.drawCircle(
        c + Offset(r * math.cos(a), r * math.sin(a)),
        4.2,
        Paint()..color = i == 0 ? accent : bead.withValues(alpha: 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(_BeadsPainter old) => old.bead != bead;
}

// ─────────────────────────────── الرفيق ───────────────────────────────

/// أقسام التطبيق تجتمع حول نجمة ذهبية: كل ما يحتاجه القارئ في مكان واحد.
class CompanionScene extends StatelessWidget {
  final double t;

  const CompanionScene({super.key, required this.t});

  static const _centre = Offset(160, 110);
  static const _icons = [
    AppIcons.bookOpenTextFill,
    AppIcons.flowerLotusFill,
    AppIcons.graphFill,
    AppIcons.handHeartFill,
    AppIcons.sparkleFill,
    AppIcons.books,
  ];

  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final star = phase(t, 0.5, 0.7, Curves.easeOutBack);
    final pulse = math.sin(phase(t, 0.7, 0.95) * math.pi);
    return _Canvas(
      children: [
        for (var i = 0; i < _icons.length; i++)
          () {
            final p = phase(t, i * 0.07, 0.3 + i * 0.07, Curves.easeOutCubic);
            final angle = -math.pi / 2 + i * math.pi / 3;
            // تأتي من بعيد ثم تستقر في مدار حول النجمة.
            final radius = 150 - 66 * p;
            final at =
                _centre +
                Offset(
                  radius * math.cos(angle) * 1.25,
                  radius * math.sin(angle),
                );
            return Positioned(
              left: at.dx - 21,
              top: at.dy - 21,
              child: Opacity(
                opacity: p.clamp(0.0, 1.0),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: c.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.gold.withValues(alpha: 0.7)),
                  ),
                  child: Icon(_icons[i], size: 21, color: c.primary),
                ),
              ),
            );
          }(),
        Positioned(
          left: _centre.dx - 40,
          top: _centre.dy - 40,
          child: popIn(
            star,
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: c.gold.withValues(alpha: 0.3 + 0.4 * pulse),
                    blurRadius: 16 + 14 * pulse,
                    spreadRadius: 2 * pulse,
                  ),
                ],
              ),
              child: CustomPaint(painter: _StarPainter(c.gold)),
            ),
          ),
        ),
      ],
    );
  }
}

class _StarPainter extends CustomPainter {
  final Color color;

  _StarPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      eightPointStar(size.center(Offset.zero), size.width / 2),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.color != color;
}

// ─────────────────────────────── عام ───────────────────────────────

/// أيقونة القسم في هالة ذهبية، تدور حولها نجوم صغيرة.
class IconScene extends StatelessWidget {
  final double t;
  final IconData icon;

  const IconScene({super.key, required this.t, required this.icon});

  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final appear = phase(t, 0.0, 0.3, Curves.easeOutBack);
    final orbit = t * 2 * math.pi;
    return _Canvas(
      children: [
        for (var i = 0; i < 6; i++)
          () {
            final a = orbit + i * math.pi / 3;
            final r = 74.0 + 6 * math.sin(orbit * 2 + i);
            return Positioned(
              left: 160 + r * math.cos(a) - 5,
              top: 110 + r * math.sin(a) * 0.8 - 5,
              child: Opacity(
                opacity: 0.35 + 0.4 * appear.clamp(0.0, 1.0),
                child: Icon(AppIcons.sparkleFill, size: 10, color: c.gold),
              ),
            );
          }(),
        Positioned(
          left: 160 - 46,
          top: 110 - 46,
          child: popIn(
            appear,
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.primary,
                border: Border.all(color: c.gold, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: c.gold.withValues(alpha: 0.4),
                    blurRadius: 22,
                  ),
                ],
              ),
              child: Icon(icon, size: 44, color: c.gold),
            ),
          ),
        ),
      ],
    );
  }
}
