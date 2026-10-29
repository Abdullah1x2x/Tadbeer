import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization.dart';
import '../../core/theme/theme.dart';
import '../../core/motion/app_motion.dart';
import '../../data/storage/user_data_store.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../../data/quran/quran_models.dart';
import '../../data/quran/quran_repository.dart';
import '../tadbeer/tadbeer_pause_sheet.dart';
import '../../core/design_system/app_icons.dart';

/// وضع التأمل: آية واحدة في كل مرة على خلفية هادئة متحركة.
///
/// Full-screen, distraction-free reading. Swipe to move between verses, open
/// the reflection questions for the current verse, or follow a breathing
/// circle before reading.
class FocusModeScreen extends StatefulWidget {
  /// الآية التي يبدأ منها التأمل.
  final Ayah startAyah;

  /// ينشئ شاشة وضع التأمل.
  const FocusModeScreen({super.key, required this.startAyah});

  /// يفتح وضع التأمل بانتقال تلاشٍ هادئ.
  static Future<void> open(BuildContext context, Ayah ayah) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, _, _) => FocusModeScreen(startAyah: ayah),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen>
    with TickerProviderStateMixin {
  late final List<Ayah> _ayahs = QuranRepository.instance.allAyahs;
  late final PageController _pages;
  late int _index;

  /// Slow loop driving the drifting background and stars.
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );

  /// 8 s breathing cycle (4 s in, 4 s out); runs only while shown.
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );
  bool _breathing = false;

  @override
  void initState() {
    super.initState();
    final start = _ayahs.indexWhere(
      (a) =>
          a.surahNumber == widget.startAyah.surahNumber &&
          a.ayahNumber == widget.startAyah.ayahNumber,
    );
    _index = start < 0 ? 0 : start;
    _pages = PageController(initialPage: _index);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the system "reduce motion" setting for the ambient sky.
    if (AppMotion.shouldAnimate(context)) {
      if (!_ambient.isAnimating) _ambient.repeat();
    } else {
      _ambient.stop();
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _ambient.dispose();
    _breath.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _toggleBreathing() {
    HapticFeedback.selectionClick();
    setState(() => _breathing = !_breathing);
    if (_breathing) {
      _breath.repeat();
    } else {
      _breath.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const gold = Color(0xFFE8C878);
    // The night sky takes the colours of the chosen theme.
    final deepest = Color.lerp(AppColors.darkBackground, Colors.black, 0.4)!;
    final sky = [
      AppColors.heroGradient(true).colors.first,
      AppColors.darkBackground,
      deepest,
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: deepest,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Drifting night gradient with slowly twinkling stars.
            AnimatedBuilder(
              animation: _ambient,
              builder: (context, _) => CustomPaint(
                painter: _NightSkyPainter(t: _ambient.value, sky: sky),
              ),
            ),
            PageView.builder(
              controller: _pages,
              itemCount: _ayahs.length,
              onPageChanged: (i) {
                HapticFeedback.selectionClick();
                // Moving on from the last verse of a Mushaf page counts that
                // page as read, as in the Mushaf.
                if (i == _index + 1 && _ayahs[i].page != _ayahs[_index].page) {
                  UserDataStore.instance.recordPageRead(_ayahs[_index].page);
                }
                setState(() => _index = i);
              },
              itemBuilder: (context, i) =>
                  _AyahPanel(ayah: _ayahs[i], active: i == _index),
            ),
            if (_breathing)
              IgnorePointer(
                child: Center(child: _BreathingCircle(animation: _breath)),
              ),
            // Top bar: close and breathing toggle.
            Align(
              alignment: Alignment.topCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: l10n.close,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(AppIcons.x),
                        color: Colors.white70,
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: l10n.breathe,
                        onPressed: _toggleBreathing,
                        icon: Icon(
                          _breathing ? AppIcons.wind : AppIcons.flowerLotus,
                        ),
                        color: _breathing ? gold : Colors.white70,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom actions.
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFD9B566),
                          foregroundColor: const Color(0xFF0B1220),
                        ),
                        onPressed: () =>
                            TadbeerPauseSheet.show(context, _ayahs[_index]),
                        icon: const Icon(AppIcons.flowerLotusFill),
                        label: Text(l10n.tadbeerPause),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.swipeForNextAyah,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// آية واحدة تظهر بتلاشٍ وتكبير هادئ عند وصولها.
class _AyahPanel extends StatelessWidget {
  final Ayah ayah;
  final bool active;

  const _AyahPanel({required this.ayah, required this.active});

  @override
  Widget build(BuildContext context) {
    final surah = QuranRepository.instance.getSurah(ayah.surahNumber);
    final font = UserDataStore.instance.quranFontFamily;
    const gold = Color(0xFFD9B566);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 700),
      opacity: active ? 1 : 0.25,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        scale: active ? 1 : 0.94,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 90, 28, 150),
          child: Column(
            children: [
              Text(
                'سُورَةُ ${surah.name}',
                style: const TextStyle(
                  fontFamily: AppTheme.appFontFamily,
                  color: gold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 60,
                height: 1,
                color: gold.withValues(alpha: 0.5),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: ayah.text),
                          TextSpan(
                            text:
                                ' ﴿${ArabicSearchNormalizer.toArabicDigits(ayah.ayahNumber)}﴾',
                            style: const TextStyle(color: gold),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 30,
                        height: 2.1,
                        color: const Color(0xFFF2EEE4),
                        shadows: const [
                          Shadow(color: Color(0x66000000), blurRadius: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// دائرة تنفس تتسع ٤ ثوانٍ وتنقبض ٤ ثوانٍ.
class _BreathingCircle extends StatelessWidget {
  final Animation<double> animation;

  const _BreathingCircle({required this.animation});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const gold = Color(0xFFE8C878);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final inhale = t < 0.5;
        // Smooth in/out: 0 → 1 → 0 across the cycle.
        final phase = Curves.easeInOut.transform(inhale ? t * 2 : (1 - t) * 2);
        final size = 140 + 120 * phase;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    gold.withValues(alpha: 0.28),
                    gold.withValues(alpha: 0.02),
                  ],
                ),
                border: Border.all(color: gold.withValues(alpha: 0.45)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              inhale ? l10n.breatheIn : l10n.breatheOut,
              style: const TextStyle(color: gold, fontSize: 16),
            ),
          ],
        );
      },
    );
  }
}

/// سماء ليلية: تدرج كحلي ينجرف ببطء ونجوم تتلألأ.
class _NightSkyPainter extends CustomPainter {
  final double t;

  /// Sky colours from the centre of the glow outwards, from the app theme.
  final List<Color> sky;

  _NightSkyPainter({required this.t, required this.sky});

  static final List<Offset> _stars = List.generate(70, (i) {
    final r = math.Random(i * 7919);
    return Offset(r.nextDouble(), r.nextDouble());
  });

  @override
  void paint(Canvas canvas, Size size) {
    final angle = t * math.pi * 2;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(
            math.sin(angle) * 0.5,
            -0.3 + math.cos(angle) * 0.2,
          ),
          radius: 1.3,
          colors: sky,
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );

    final star = Paint();
    for (var i = 0; i < _stars.length; i++) {
      final twinkle = 0.25 + 0.75 * (0.5 + 0.5 * math.sin(angle * 3 + i));
      star.color = const Color(0xFFF2E3B8).withValues(alpha: 0.35 * twinkle);
      final p = Offset(
        _stars[i].dx * size.width,
        (_stars[i].dy * size.height + t * 30) % size.height,
      );
      canvas.drawCircle(p, i % 5 == 0 ? 1.4 : 0.8, star);
    }
  }

  @override
  bool shouldRepaint(covariant _NightSkyPainter old) =>
      old.t != t || !listEquals(old.sky, sky);
}
