import 'package:flutter/material.dart';

/// شعار التطبيق بإطاره وظله، بنفس الشكل في كل مكان وكل ثيم.
///
/// يحيط به خط رفيع بلون البرونز (ذهبي خافت في الوضع الداكن). وحين يقف وحده
/// ([elevated]) يأخذ ظلاً دافئاً وحلقة بلون الثيم.
class AppLogo extends StatelessWidget {
  /// عرض الشعار وارتفاعه.
  final double size;

  /// ظل ناعم لشعار يقف وحده؛ يُطفأ للشعار الصغير بجانب الاسم.
  final bool elevated;

  const AppLogo({super.key, required this.size, this.elevated = true});

  static const _asset = 'assets/icons/app_logo.png';

  /// لون البرونز في قوس الشعار.
  static const _bronze = Color(0xFF946C33);
  static const _shadow = Color(0xFF5E401C);
  static const _gold = Color(0xFFE3C06A);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ring = Theme.of(context).colorScheme.primary;
    final gap = (size * 0.045).clamp(3.0, 7.0);
    final ringWidth = (size * 0.025).clamp(1.5, 3.0);
    // بانحناء أيقونة التطبيق نفسه.
    final radius = BorderRadius.circular(size * 0.22);
    final shape = RoundedSuperellipseBorder(borderRadius: radius);
    final edge = RoundedSuperellipseBorder(
      borderRadius: radius,
      side: BorderSide(
        color: isDark
            ? _gold.withValues(alpha: 0.35)
            : _bronze.withValues(alpha: 0.45),
        width: (size / 90).clamp(0.6, 1.4),
        strokeAlign: BorderSide.strokeAlignInside,
      ),
    );
    final logo = DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: elevated
            ? [
                BoxShadow(
                  color: _shadow.withValues(alpha: isDark ? 0.4 : 0.22),
                  blurRadius: size * 0.18,
                  offset: Offset(0, size * 0.05),
                ),
              ]
            : null,
      ),
      // الحافة تُرسم فوق الصورة لتقع على طرفها.
      position: DecorationPosition.background,
      child: DecoratedBox(
        decoration: ShapeDecoration(shape: edge),
        position: DecorationPosition.foreground,
        child: ClipPath(
          clipper: ShapeBorderClipper(shape: shape),
          child: Image.asset(
            _asset,
            width: size,
            height: size,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
    return Semantics(
      image: true,
      label: 'تدبير',
      child: elevated
          // حلقة الثيم، تفصلها عن الشعار مسافة رفيعة.
          ? DecoratedBox(
              decoration: ShapeDecoration(
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(
                    size * 0.22 + gap + ringWidth,
                  ),
                  side: BorderSide(color: ring, width: ringWidth),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(gap + ringWidth),
                child: logo,
              ),
            )
          : logo,
    );
  }
}
