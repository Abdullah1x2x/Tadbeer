import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/localization.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/theme/theme.dart';
import '../../../data/storage/user_data_store.dart';
import 'section_guide.dart';

/// دليل الرئيسية بعد الجولة: يعتّم الشاشة ويضيء عناصرها الحقيقية واحداً بعد
/// آخر، ويُعاد من الإعدادات.
abstract final class HomeWalkthrough {
  static const _key = 'home_walkthrough';

  static final ayahCard = GlobalKey(debugLabel: 'walkAyah');
  static final quranCard = GlobalKey(debugLabel: 'walkQuran');
  static final searchBar = GlobalKey(debugLabel: 'walkSearch');
  static final homeTab = GlobalKey(debugLabel: 'walkHomeTab');
  static final moreTab = GlobalKey(debugLabel: 'walkMoreTab');

  static bool get seen =>
      UserDataStore.instance.featureState(_key)['seen'] == true;

  /// يعرض الدليل مرة واحدة، بعد إذن الأذونات وقبل أن يبدأ القارئ.
  static Future<void> showOnce(BuildContext context) async {
    if (!SectionGuide.autoShowAllowed || seen) return;
    await show(context);
  }

  /// يعرض الدليل الآن.
  static Future<void> show(BuildContext context) async {
    await UserDataStore.instance.saveFeatureState(_key, {'seen': true});
    if (!context.mounted) return;
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: AppMotion.duration(context, AppMotion.normal),
        pageBuilder: (_, _, _) => const _Walkthrough(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}

/// خطوة في الدليل: ما تضيئه (لا شيء لنصيحة عامة)، وعنوانها، وشرحها.
class _Step {
  final List<GlobalKey> targets;
  final String title;
  final String body;

  const _Step(this.targets, this.title, this.body);
}

class _Walkthrough extends StatefulWidget {
  const _Walkthrough();

  @override
  State<_Walkthrough> createState() => _WalkthroughState();
}

class _WalkthroughState extends State<_Walkthrough> {
  int _index = 0;

  List<_Step> _steps(AppStrings l10n) => [
    _Step([HomeWalkthrough.ayahCard], l10n.walkAyahTitle, l10n.walkAyahBody),
    _Step([HomeWalkthrough.quranCard], l10n.walkQuranTitle, l10n.walkQuranBody),
    _Step(
      [HomeWalkthrough.searchBar],
      l10n.walkSearchTitle,
      l10n.walkSearchBody,
    ),
    _Step(
      [HomeWalkthrough.homeTab, HomeWalkthrough.moreTab],
      l10n.walkTabsTitle,
      l10n.walkTabsBody,
    ),
    _Step([HomeWalkthrough.moreTab], l10n.walkMoreTitle, l10n.walkMoreBody),
    _Step(const [], l10n.walkTipTitle, l10n.walkTipBody),
  ];

  /// مكان [keys] على الشاشة، أو null إن لم يكن أيٌّ منها معروضاً.
  Rect? _rectOf(List<GlobalKey> keys) {
    Rect? rect;
    for (final key in keys) {
      final box = key.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) continue;
      final found = box.localToGlobal(Offset.zero) & box.size;
      rect = rect?.expandToInclude(found) ?? found;
    }
    return rect?.inflate(6);
  }

  Future<void> _next(List<_Step> steps) async {
    HapticFeedback.selectionClick();
    final next = _index + 1;
    if (next >= steps.length) {
      Navigator.pop(context);
      return;
    }
    // الشاشات القصيرة تُمرّر، فيُجلب العنصر إلى المشهد قبل إضاءته.
    final target = steps[next].targets.firstOrNull?.currentContext;
    if (target != null) {
      await Scrollable.ensureVisible(
        target,
        alignment: 0.5,
        duration: AppMotion.duration(context, AppMotion.normal),
      );
    }
    if (mounted) setState(() => _index = next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = _steps(l10n);
    final step = steps[_index];
    final rect = _rectOf(step.targets);
    final screen = MediaQuery.sizeOf(context);
    // الفقاعة في الجهة الأوسع من العنصر المضاء.
    final below = rect != null && rect.center.dy < screen.height / 2;
    final gold = AppColors.accentGold(context);
    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned.fill(
              child: TweenAnimationBuilder<Rect?>(
                tween: RectTween(end: rect ?? _emptyAt(screen)),
                duration: AppMotion.duration(context, AppMotion.slow),
                curve: AppMotion.emphasized,
                builder: (context, r, _) => CustomPaint(
                  painter: _SpotlightPainter(hole: r!, gold: gold),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              top: rect == null
                  ? screen.height * 0.34
                  : below
                  ? rect.bottom + 16
                  : null,
              bottom: rect != null && !below
                  ? screen.height - rect.top + 16
                  : null,
              child: _Bubble(
                step: step,
                index: _index,
                total: steps.length,
                onNext: () => _next(steps),
                onSkip: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// فتحة معدومة في وسط الشاشة، لنصيحة لا تضيء شيئاً.
  Rect _emptyAt(Size screen) =>
      Rect.fromCenter(center: screen.center(Offset.zero), width: 0, height: 0);
}

class _Bubble extends StatelessWidget {
  final _Step step;
  final int index;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _Bubble({
    required this.step,
    required this.index,
    required this.total,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gold = AppColors.accentGold(context);
    final last = index == total - 1;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: gold.withValues(alpha: 0.6)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.guideStep(index + 1, total),
                style: TextStyle(
                  fontFamily: AppTheme.appFontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: gold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step.title,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step.body,
                style: TextStyle(
                  fontFamily: AppTheme.appFontFamily,
                  fontSize: 14.5,
                  height: 1.6,
                  color: AppColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 6),
              // مع النص الكبير ينزل الزر تحت الآخر بدل أن يفيضا.
              OverflowBar(
                alignment: last
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.spaceBetween,
                children: [
                  if (!last)
                    TextButton(onPressed: onSkip, child: Text(l10n.tourSkip)),
                  FilledButton(
                    onPressed: onNext,
                    child: Text(last ? l10n.tourGotIt : l10n.tourNext),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// يعتّم الشاشة ويترك فتحة بإطار ذهبي حول العنصر.
class _SpotlightPainter extends CustomPainter {
  final Rect hole;
  final Color gold;

  _SpotlightPainter({required this.hole, required this.gold});

  @override
  void paint(Canvas canvas, Size size) {
    final rounded = RRect.fromRectAndRadius(hole, const Radius.circular(22));
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addRRect(rounded),
      Paint()..color = Colors.black.withValues(alpha: 0.72),
    );
    if (hole.isEmpty) return;
    canvas.drawRRect(
      rounded,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = gold,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.hole != hole || old.gold != gold;
}
