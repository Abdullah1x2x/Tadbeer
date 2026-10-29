import 'package:flutter/material.dart';

import '../../../core/motion/app_motion.dart';

/// قصة متحرّكة قصيرة تُعاد ما دامت ظاهرة.
///
/// تبني [builder] المشهد من تقدّم القصة [t] (من 0 إلى 1)، ويثبت آخر ربع منها
/// لتُقرأ نتيجتها قبل أن تبدأ من جديد. مع «تقليل الحركة» تُعرض النهاية ثابتة،
/// فيبقى المعنى بلا حركة. ولمس المشهد يعيده من أوله.
class SceneStory extends StatefulWidget {
  /// مدة القصة كاملة، ومنها وقفة النهاية.
  final Duration duration;

  /// هل الصفحة ظاهرة الآن؛ غير الظاهرة تقف عند أولها.
  final bool playing;

  final Widget Function(BuildContext context, double t) builder;

  const SceneStory({
    super.key,
    required this.builder,
    this.duration = const Duration(milliseconds: 4800),
    this.playing = true,
  });

  /// الجزء الذي تتحرّك فيه القصة؛ وما بعده وقفة على النهاية.
  static const _motionShare = 0.78;

  @override
  State<SceneStory> createState() => _SceneStoryState();
}

class _SceneStoryState extends State<SceneStory>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  bool _animate = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animate = AppMotion.shouldAnimate(context);
    _sync();
  }

  @override
  void didUpdateWidget(SceneStory old) {
    super.didUpdateWidget(old);
    if (old.playing != widget.playing) _sync();
  }

  void _sync() {
    if (!_animate) {
      _controller.value = 1;
      return;
    }
    if (widget.playing) {
      _controller.repeat();
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  void _restart() {
    if (!_animate) return;
    _controller
      ..value = 0
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _restart,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => widget.builder(
          context,
          (_controller.value / SceneStory._motionShare).clamp(0.0, 1.0),
        ),
      ),
    );
  }
}

/// تقدّم مقطع من القصة بين [start] و[end] (كلاهما من 0 إلى 1)، بمنحنى [curve].
double phase(
  double t,
  double start,
  double end, [
  Curve curve = Curves.easeOutCubic,
]) {
  if (t <= start) return 0;
  if (t >= end) return 1;
  return curve.transform((t - start) / (end - start));
}

/// يظهر [child] ويرتفع قليلاً مع تقدّم [p] من 0 إلى 1.
Widget riseIn(double p, Widget child, {double distance = 14}) {
  return Opacity(
    opacity: p,
    child: Transform.translate(
      offset: Offset(0, (1 - p) * distance),
      child: child,
    ),
  );
}

/// يكبر [child] من الصفر مع [p]، بارتداد خفيف في آخره.
Widget popIn(double p, Widget child) {
  final scale = Curves.easeOutBack.transform(p.clamp(0.0, 1.0));
  return Opacity(
    opacity: p.clamp(0.0, 1.0),
    child: Transform.scale(scale: scale, child: child),
  );
}
