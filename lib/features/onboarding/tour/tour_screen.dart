import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/localization.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/ornaments.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/theme/theme.dart';
import '../../../data/storage/user_data_store.dart';
import 'scene_story.dart';
import 'tour_scenes.dart';

/// جولة أول تشغيل: خمس صفحات، في كل صفحة ميزة ومشهدها المتحرّك.
///
/// تُفتح بعد اختيار المظهر، فتأتي بألوانه وخطه. ومن الإعدادات تُفتح ثانية، فإذا
/// انتهت عادت إلى حيث فُتحت ([next] فارغ).
class TourScreen extends StatefulWidget {
  /// ما يُفتح بعد الجولة؛ أو null لتُغلق وتعود.
  final WidgetBuilder? next;

  const TourScreen({super.key, this.next});

  static const _key = 'tour';

  /// هل رأى القارئ الجولة.
  static bool get seen =>
      UserDataStore.instance.featureState(_key)['seen'] == true;

  @override
  State<TourScreen> createState() => _TourScreenState();
}

class _TourScreenState extends State<TourScreen>
    with SingleTickerProviderStateMixin {
  final _pages = PageController();
  int _index = 0;

  /// لمعة زر البدء في الصفحة الأخيرة.
  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  List<_TourPage> _content(AppStrings l10n) => [
    _TourPage(
      (t) => MushafScene(t: t),
      l10n.tour1Title,
      l10n.tour1Body,
      duration: const Duration(milliseconds: 5600),
    ),
    _TourPage(
      (t) => ReflectScene(t: t),
      l10n.tour2Title,
      l10n.tour2Body,
      duration: const Duration(milliseconds: 6000),
    ),
    _TourPage((t) => ListenScene(t: t), l10n.tour3Title, l10n.tour3Body),
    _TourPage((t) => JourneyScene(t: t), l10n.tour4Title, l10n.tour4Body),
    _TourPage((t) => PrivacyScene(t: t), l10n.tour5Title, l10n.tour5Body),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.shouldAnimate(context)) {
      if (!_shine.isAnimating) _shine.repeat();
    } else {
      _shine.stop();
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    _shine.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    final navigator = Navigator.of(context);
    await UserDataStore.instance.saveFeatureState(TourScreen._key, {
      'seen': true,
    });
    final next = widget.next;
    if (next == null) {
      navigator.pop();
      return;
    }
    navigator.pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, _, _) => next(context),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _next(int count) {
    HapticFeedback.selectionClick();
    if (_index >= count - 1) {
      _finish();
      return;
    }
    _pages.nextPage(
      duration: AppMotion.duration(context, const Duration(milliseconds: 420)),
      curve: AppMotion.emphasized,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = _content(l10n);
    final last = _index == pages.length - 1;
    final gold = AppColors.accentGold(context);
    final primary = Theme.of(context).colorScheme.primary;
    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        body: Stack(
          children: [
            // تنزاح الزخرفة قليلاً مع السحب، فيبدو للصفحات عمق.
            AnimatedBuilder(
              animation: _pages,
              builder: (context, child) {
                final page = _pages.hasClients && _pages.page != null
                    ? _pages.page!
                    : _index.toDouble();
                return Transform.translate(
                  offset: Offset(page * 18, 0),
                  child: child,
                );
              },
              child: const PatternBackground(
                reach: 0.8,
                child: SizedBox.expand(),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: AnimatedOpacity(
                        opacity: last ? 0 : 1,
                        duration: AppMotion.normal,
                        child: TextButton(
                          onPressed: last ? null : _finish,
                          child: Text(l10n.tourSkip),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pages,
                      itemCount: pages.length,
                      onPageChanged: (i) {
                        HapticFeedback.selectionClick();
                        setState(() => _index = i);
                      },
                      itemBuilder: (context, i) =>
                          _TourPageView(page: pages[i], active: i == _index),
                    ),
                  ),
                  _Dots(count: pages.length, index: _index, color: gold),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: AnimatedBuilder(
                        animation: _shine,
                        builder: (context, child) => DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: last
                                ? LinearGradient(
                                    begin: Alignment(
                                      -1.6 + 3.2 * _shine.value,
                                      0,
                                    ),
                                    end: Alignment(
                                      -0.6 + 3.2 * _shine.value,
                                      0,
                                    ),
                                    colors: [primary, gold, primary],
                                    stops: const [0.2, 0.5, 0.8],
                                  )
                                : null,
                            color: last ? null : primary,
                            boxShadow: [
                              BoxShadow(
                                color: (last ? gold : primary).withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: child,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => _next(pages.length),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    last ? l10n.tourStart : l10n.tourNext,
                                    style: const TextStyle(
                                      fontFamily: AppTheme.appFontFamily,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    last
                                        ? AppIcons.sparkleFill
                                        : AppIcons.arrowRight,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// صفحة في الجولة: مشهدها، وعنوانها، وسطر يشرحها.
class _TourPage {
  final Widget Function(double t) scene;
  final String title;
  final String body;
  final Duration duration;

  const _TourPage(
    this.scene,
    this.title,
    this.body, {
    this.duration = const Duration(milliseconds: 4800),
  });
}

class _TourPageView extends StatelessWidget {
  final _TourPage page;
  final bool active;

  const _TourPageView({required this.page, required this.active});

  @override
  Widget build(BuildContext context) {
    final animate = AppMotion.shouldAnimate(context);
    // يدخل العنوان ثم الشرح كلما صارت الصفحة ظاهرة.
    Widget entering(int order, Widget child) => TweenAnimationBuilder<double>(
      key: ValueKey('$active$order'),
      tween: Tween(begin: active && animate ? 0 : 1, end: 1),
      duration: Duration(milliseconds: 420 + 100 * order),
      curve: Curves.easeOutCubic,
      builder: (context, p, child) => riseIn(p, child!, distance: 20),
      child: child,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: entering(
                  0,
                  SceneStory(
                    playing: active,
                    duration: page.duration,
                    builder: (context, t) => page.scene(t),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          entering(
            1,
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
          const SizedBox(height: 8),
          entering(
            2,
            Text(
              page.body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.appFontFamily,
                fontSize: 15,
                height: 1.6,
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// نقاط الصفحات: الحالية أطول وبلون ذهبي.
class _Dots extends StatelessWidget {
  final int count;
  final int index;
  final Color color;

  const _Dots({required this.count, required this.index, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: AppMotion.duration(context, AppMotion.slow),
            curve: AppMotion.emphasized,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == index ? 26 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index ? color : color.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
