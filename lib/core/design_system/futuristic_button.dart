import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';
import '../motion/app_motion.dart';
import 'app_tokens.dart';

/// زر التطبيق: ممتلئ للإجراء الأساسي، أو مفرّغ للثانوي، مع حالة تحميل.
class FuturisticButton extends StatelessWidget {
  final String label;

  final VoidCallback? onPressed;

  /// أيقونة اختيارية قبل النص.
  final IconData? icon;

  /// لون الزر بدل اللون الأساسي للثيم.
  final Color? color;

  /// مفرّغ بإطار بدل الممتلئ.
  final bool isSecondary;

  /// يعرض مؤشر تحميل ويعطّل النقر.
  final bool isLoading;

  final EdgeInsetsGeometry? padding;

  const FuturisticButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.isSecondary = false,
    this.isLoading = false,
    this.padding,
  });

  /// زر ثانوي مفرّغ.
  const FuturisticButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.isLoading = false,
    this.padding,
  }) : isSecondary = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        color ?? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary);

    final bg = isSecondary
        ? (isDark
              ? AppColors.darkSurface.withValues(alpha: 0.8)
              : AppColors.lightSurface.withValues(alpha: 0.8))
        : primaryColor;

    final fg = isSecondary
        ? (isDark ? AppColors.darkTextPrimary : primaryColor)
        : Colors.white;

    final border = isSecondary
        ? Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: AppTokens.borderRegular,
          )
        : Border.all(
            color: primaryColor.withValues(alpha: isDark ? 0.8 : 0.6),
            width: AppTokens.borderRegular,
          );

    return ScaleOnPress(
      pressedScale: 0.96,
      enabled: onPressed != null && !isLoading,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading || onPressed == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onPressed!();
                },
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          splashColor: (isSecondary ? primaryColor : Colors.white).withValues(
            alpha: 0.15,
          ),
          hoverColor: primaryColor.withValues(alpha: 0.08),
          focusColor: primaryColor.withValues(alpha: 0.12),
          child: Ink(
            padding:
                padding ??
                const EdgeInsets.symmetric(
                  horizontal: AppTokens.spaceLg,
                  vertical: AppTokens.spaceSm,
                ),
            decoration: BoxDecoration(
              color: bg,
              gradient: !isSecondary && color == null
                  ? AppColors.heroGradient(isDark)
                  : null,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: border,
              boxShadow: !isSecondary
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(
                          alpha: isDark ? 0.30 : 0.28,
                        ),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(fg),
                    ),
                  ),
                  const SizedBox(width: AppTokens.spaceSm),
                ] else if (icon != null) ...[
                  Icon(icon, size: 18, color: fg),
                  const SizedBox(width: AppTokens.spaceXs),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: fg,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// زر أيقونة مربع مستدير للشريط العلوي والأدوات السريعة، مع تلميح.
class FuturisticIconButton extends StatelessWidget {
  final IconData icon;

  /// التلميح، وهو أيضاً اسم الزر لقارئ الشاشة.
  final String tooltip;

  final VoidCallback onTap;

  /// ضلع الزر.
  final double size;

  final double iconSize;

  final Color? iconColor;

  final Color? backgroundColor;

  /// يعطّل الزر ويخفّته حين يكون false.
  final bool isEnabled;

  const FuturisticIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 42,
    this.iconSize = 20,
    this.iconColor,
    this.backgroundColor,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightPrimary;
    final primary = (iconColor ?? defaultPrimary).withValues(
      alpha: isEnabled ? 1.0 : 0.35,
    );
    final bg =
        (backgroundColor ??
                (isDark ? AppColors.darkSurface : AppColors.lightSurface))
            .withValues(alpha: isEnabled ? 1.0 : 0.6);

    return ScaleOnPress(
      pressedScale: 0.93,
      enabled: isEnabled,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled
                ? () {
                    HapticFeedback.selectionClick();
                    onTap();
                  }
                : null,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            splashColor: primary.withValues(alpha: 0.14),
            hoverColor: primary.withValues(alpha: 0.08),
            focusColor: primary.withValues(alpha: 0.12),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                border: Border.all(
                  color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                      .withValues(alpha: isEnabled ? 1.0 : 0.4),
                  width: AppTokens.borderRegular,
                ),
                boxShadow: isDark && isEnabled
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : (isEnabled
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null),
              ),
              child: Center(
                child: Icon(icon, size: iconSize, color: primary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
