import 'package:flutter/material.dart';

/// شعار التطبيق بإطاره وظله، بالشكل نفسه في كل مكان وكل ثيم.
///
/// The logo's own sand and bronze decide its frame, never the theme: a
/// hairline of the arch's bronze (a faint gold in dark mode) on the same
/// squircle as the launcher icon, and a soft warm shadow when [elevated].
class AppLogo extends StatelessWidget {
  /// Width and height of the logo.
  final double size;

  /// Casts a soft shadow, for a logo standing on its own; off for a small
  /// mark beside a name.
  final bool elevated;

  /// ينشئ شعار التطبيق.
  const AppLogo({super.key, required this.size, this.elevated = true});

  static const _asset = 'assets/icons/app_logo.png';

  /// The arch's bronze in the logo.
  static const _bronze = Color(0xFF946C33);
  static const _shadow = Color(0xFF5E401C);
  static const _gold = Color(0xFFE3C06A);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // As rounded as the launcher icon, with its smooth corners.
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
    return Semantics(
      image: true,
      label: 'تدبير',
      child: DecoratedBox(
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
        // The edge is drawn over the picture, so it sits on its rim.
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
      ),
    );
  }
}
