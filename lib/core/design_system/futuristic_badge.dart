import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'app_tokens.dart';

/// شارة رقمية مستقبلية متألقة لعرض الحالات والوسوم والعدادات.
///
/// Futuristic Digital Badge / Pill for displaying status, tags, and reading milestones.
/// Features high-contrast border styling, luminous ambient tint, and optional dot pulse.
class FuturisticBadge extends StatelessWidget {
  /// نص الشارة
  final String label;

  /// اللون المميز للشارة (تدرج الوهج والنص)
  final Color? color;

  /// أيقونة اختيارية تسبق النص
  final IconData? icon;

  /// إظهار نقطة ضوئية رقمية تشير إلى الحالة الحية
  final bool showDot;

  /// مقاس مضغوط للشاشات الصغيرة
  final bool isCompact;

  /// حجم خط مخصص إن وجد
  final double? fontSize;

  /// ينشئ شارة رقمية مستقبلية.
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
