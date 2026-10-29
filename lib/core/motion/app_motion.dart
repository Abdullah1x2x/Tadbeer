import 'package:flutter/material.dart';

/// قيم الحركة الموحّدة: المدد والمنحنيات، واحترام "تقليل الحركة"، وانتقال الحوارات.
class AppMotion {
  AppMotion._();

  // المدد

  /// للاستجابات الدقيقة كنقر الأزرار.
  static const Duration fast = Duration(milliseconds: 120);

  /// لتبديل التبويبات وظهور اللوحات.
  static const Duration normal = Duration(milliseconds: 200);

  /// لانتقالات الصفحات وحركة الشبكة.
  static const Duration slow = Duration(milliseconds: 350);

  // المنحنيات

  /// لخروج العناصر وتفاعلات اللمس.
  static const Curve emphasized = Curves.easeOutCubic;

  /// للتحولات الداخلية وتبديل الحالات.
  static const Curve standard = Curves.easeInOutCubic;

  // تقليل الحركة

  /// هل يُسمح بالحركة؛ false حين يفعّل المستخدم "تقليل الحركة" في النظام، فتصبح الحركات فورية.
  static bool shouldAnimate(BuildContext context) {
    return !MediaQuery.disableAnimationsOf(context);
  }

  /// [standardDuration]، أو صفر عند تقليل الحركة.
  static Duration duration(BuildContext context, Duration standardDuration) {
    return shouldAnimate(context) ? standardDuration : Duration.zero;
  }

  // انتقال الحوارات

  /// يعرض حواراً بانتقال يجمع التلاشي والتكبير الخفيف، كنافذة إجراءات الآية.
  static Future<T?> showSmoothDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color barrierColor = Colors.black54,
    Duration duration = const Duration(milliseconds: 180),
  }) {
    final effectiveDuration = shouldAnimate(context) ? duration : Duration.zero;

    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: barrierColor,
      transitionDuration: effectiveDuration,
      pageBuilder: (dialogCtx, _, _) => builder(dialogCtx),
      transitionBuilder: (dialogCtx, anim1, anim2, child) {
        if (!shouldAnimate(dialogCtx)) return child;
        final curved = CurvedAnimation(
          parent: anim1,
          curve: emphasized,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

/// يصغّر الزر أو البطاقة قليلاً عند الضغط ثم يرتد.
/// يستخدم [Listener] فيرصد اللمس دون أن يحجزه، فيبقى السحب والتمرير و[InkWell] الداخلي يعملون.
class ScaleOnPress extends StatefulWidget {
  final Widget child;

  /// مقدار التصغير عند الضغط.
  final double pressedScale;

  /// مدة الانتقال بين الضغط والارتداد.
  final Duration duration;

  final bool enabled;

  const ScaleOnPress({
    super.key,
    required this.child,
    this.pressedScale = 0.985,
    this.duration = AppMotion.fast,
    this.enabled = true,
  });

  @override
  State<ScaleOnPress> createState() => _ScaleOnPressState();
}

class _ScaleOnPressState extends State<ScaleOnPress> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed != value && mounted) {
      setState(() => _isPressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || !AppMotion.shouldAnimate(context)) {
      return widget.child;
    }

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _isPressed ? widget.pressedScale : 1.0,
        // ينضغط بسرعة، ثم يرتد مع تجاوز خفيف.
        duration: _isPressed ? widget.duration : AppMotion.normal,
        curve: _isPressed ? AppMotion.emphasized : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}
