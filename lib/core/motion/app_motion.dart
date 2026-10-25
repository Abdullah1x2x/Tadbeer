import 'package:flutter/material.dart';

/// نظام موحد لمحددات الحركة والانتقالات وتجربة التفاعل في تطبيق تَدْبِير.
///
/// Centralized motion design system for Tadbeer (تَدْبِير).
/// Provides standardized durations, easing curves, reduce-motion accessibility
/// helpers, smooth dialog transitions, and interactive micro-animation wrappers.
class AppMotion {
  AppMotion._();

  // ---------------------------------------------------------------------------
  // ⏱️ MOTION TOKENS: DURATIONS
  // ---------------------------------------------------------------------------

  /// مدة حركة فائقة السرعة (120ms) للاستجابات الدقيقة مثل نقر الأزرار واللمس.
  static const Duration fast = Duration(milliseconds: 120);

  /// مدة حركة قياسية معتدلة (200ms) لانتقالات التبويبات وظهور اللوحات وتلاشي الأشرطة.
  static const Duration normal = Duration(milliseconds: 200);

  /// مدة حركة متمهلة ومستقرة (350ms) لانتقالات الصفحات وتحريك المنظور والشبكة.
  static const Duration slow = Duration(milliseconds: 350);

  // ---------------------------------------------------------------------------
  // 📐 MOTION TOKENS: EASING CURVES
  // ---------------------------------------------------------------------------

  /// منحنى تسارع أساسي متزن وناعم لخروج العناصر وتفاعلات اللمس.
  static const Curve emphasized = Curves.easeOutCubic;

  /// منحنى تسارع ناعم للتحولات الداخلية وتبديل التبويبات والحالات.
  static const Curve standard = Curves.easeInOutCubic;

  // ---------------------------------------------------------------------------
  // ♿ ACCESSIBILITY: REDUCE MOTION
  // ---------------------------------------------------------------------------

  /// يتحقق مما إذا كانت الحركات مسموحاً بها بحسب إعدادات إمكانية الوصول في نظام المستخدم.
  ///
  /// يرجع `false` عندما يفعل المستخدم خيار "تقليل الحركة" (Reduce Motion) في النظام،
  /// مما يوجب جعل الحركات فورية لتجنب الصداع الحركي أو الإجهاد البصري.
  static bool shouldAnimate(BuildContext context) {
    return !MediaQuery.disableAnimationsOf(context);
  }

  /// إرجاع المدة المناسبة: المدة القياسية إذا كانت الحركة مفعلة، أو `Duration.zero` إذا كان تقليل الحركة مفعلاً.
  static Duration duration(BuildContext context, Duration standardDuration) {
    return shouldAnimate(context) ? standardDuration : Duration.zero;
  }

  // ---------------------------------------------------------------------------
  // 🪟 SMOOTH DIALOG TRANSITIONS
  // ---------------------------------------------------------------------------

  /// يعرض نافذة حوار منبثقة بانتقال ناعم متزن يجمع بين التلاشي والتكبير الخفيف.
  ///
  /// مستوحى من انتقال نافذة إجراءات الآية المتقنة ([AyahActionSheet]).
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

/// ودجت خفيفة تضفي استجابة ضغط مرنة وملموسة (`Scale on Press`) على الأزرار والبطاقات.
///
/// EDUCATIONAL NOTE:
/// تستخدم [Listener] لرصد إيماءات المؤشر دون حجزها أو تعطيل حركات السحب والتمرير
/// أو استجابة [InkWell] الأساسية داخل البطاقة.
class ScaleOnPress extends StatefulWidget {
  /// المحتوى التفاعلي المغلف.
  final Widget child;

  /// مقدار التصغير عند الضغط (افتراضياً 0.985 لإحساس لمسي هادئ ورصين).
  final double pressedScale;

  /// مدة الانتقال بين حالتي الضغط والارتداد.
  final Duration duration;

  /// هل التفاعل مفعل حالياً.
  final bool enabled;

  /// ينشئ ودجت استجابة الضغط المرنة.
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
        // Press in quickly, then spring back with a slight overshoot.
        duration: _isPressed ? widget.duration : AppMotion.normal,
        curve: _isPressed ? AppMotion.emphasized : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}
