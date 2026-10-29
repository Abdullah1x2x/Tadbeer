import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';
import '../motion/app_motion.dart';
import 'app_tokens.dart';

/// بطاقة التطبيق: سطح بتدرج خفيف وإطار وظل، تنكمش قليلاً عند الضغط.
class FuturisticCard extends StatefulWidget {
  final Widget child;

  final VoidCallback? onTap;

  final VoidCallback? onLongPress;

  /// لون الإطار والوهج المحيط بدل لون الثيم.
  final Color? accentColor;

  final Color? backgroundColor;

  final double? borderRadius;

  final EdgeInsetsGeometry? padding;

  /// مقدار الانكماش عند الضغط (1 بلا انكماش).
  final double pressedScale;

  /// يبرز الإطار ويضيء الحافة العلوية.
  final bool isSelected;

  /// خط مضيء على الحافة العلوية.
  final bool showTopAccentGlow;

  const FuturisticCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.accentColor,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.pressedScale = 0.97,
    this.isSelected = false,
    this.showTopAccentGlow = false,
  });

  @override
  State<FuturisticCard> createState() => _FuturisticCardState();
}

class _FuturisticCardState extends State<FuturisticCard> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultAccent = isDark
        ? AppColors.darkPrimary
        : AppColors.lightPrimary;
    final accent = widget.accentColor ?? defaultAccent;
    final radius = widget.borderRadius ?? AppTokens.radiusLg;

    final defaultBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final baseBg = widget.backgroundColor ?? defaultBg;

    Color borderColor;
    double borderWidth = AppTokens.borderRegular;

    if (widget.isSelected || _isFocused) {
      borderColor = accent;
      borderWidth = AppTokens.borderEmphasized;
    } else if (_isHovered) {
      borderColor = accent.withValues(alpha: isDark ? 0.65 : 0.50);
      borderWidth = AppTokens.borderRegular;
    } else {
      borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    }

    List<BoxShadow> shadows;
    if (_isHovered || widget.isSelected) {
      shadows = AppTokens.heroGlow(isDark: isDark, accentColor: accent);
    } else {
      shadows = AppTokens.cardShadow(
        isDark: isDark,
        glowColor: widget.showTopAccentGlow ? accent : null,
      );
    }

    Widget content = Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.emphasized,
        decoration: BoxDecoration(
          color: baseBg,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: shadows,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - borderWidth),
          child: Stack(
            children: [
              if (widget.showTopAccentGlow || widget.isSelected)
                Positioned(
                  top: 0,
                  left: 16,
                  right: 16,
                  height: 1.5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: 0.0),
                          accent.withValues(alpha: isDark ? 0.90 : 0.70),
                          accent.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),

              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap == null
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          widget.onTap!();
                        },
                  onLongPress: widget.onLongPress,
                  onHover: (hovered) => setState(() => _isHovered = hovered),
                  onFocusChange: (focused) =>
                      setState(() => _isFocused = focused),
                  borderRadius: BorderRadius.circular(radius - borderWidth),
                  splashColor: accent.withValues(alpha: 0.12),
                  hoverColor: accent.withValues(alpha: 0.05),
                  focusColor: accent.withValues(alpha: 0.08),
                  child: Padding(
                    padding:
                        widget.padding ??
                        const EdgeInsets.all(AppTokens.spaceMd),
                    child: widget.child,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.onTap != null) {
      return ScaleOnPress(pressedScale: widget.pressedScale, child: content);
    }

    return content;
  }
}
