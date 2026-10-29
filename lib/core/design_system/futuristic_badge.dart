import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'app_tokens.dart';

/// شارة صغيرة للحالات والوسوم والعدادات، بإطار ولون خلفية خافت ونقطة اختيارية.
class FuturisticBadge extends StatelessWidget {
  final String label;

  /// لون الإطار والنص والخلفية الخافتة.
  final Color? color;

  /// أيقونة اختيارية قبل النص.
  final IconData? icon;

  /// نقطة تشير إلى حالة حية.
  final bool showDot;

  /// مقاس مضغوط للشاشات الصغيرة.
  final bool isCompact;

  /// حجم خط مخصّص بدل الافتراضي.
  final double? fontSize;

  const FuturisticBadge({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.showDot = false,
    this.isCompact = false,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent =
        color ??
        (isDark ? AppColors.darkAccentGold : AppColors.lightAccentGold);

    final padH = isCompact ? AppTokens.spaceXs : AppTokens.spaceSm;
    final padV = isCompact ? 3.0 : 4.5;
    final textSz = fontSize ?? (isCompact ? 10.0 : 11.5);
    final iconSz = isCompact ? 12.0 : 14.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.40 : 0.35),
          width: AppTokens.borderRegular,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.15),
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent,
                boxShadow: AppTokens.pulseGlow(color: accent),
              ),
            ),
            const SizedBox(width: AppTokens.spaceXs),
          ],
          if (icon != null) ...[
            Icon(icon, size: iconSz, color: accent),
            const SizedBox(width: AppTokens.spaceXxs),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: textSz,
              fontWeight: FontWeight.w700,
              color: accent,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
