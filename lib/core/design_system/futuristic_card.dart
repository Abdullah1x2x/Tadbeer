import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../motion/app_motion.dart';
import 'app_tokens.dart';

/// بطاقة رقمية مستقبلية متقدمة لتطبيق تَدْبِير.
///
/// Futuristic Card component with precision borders, dual-layer glow,
/// refined surface gradients, and integrated tactile interaction.
class FuturisticCard extends StatefulWidget {
  /// محتوى البطاقة الداخلي
  final Widget child;

  /// إجراء النقر عند الضغط على البطاقة
  final VoidCallback? onTap;

  /// إجراء اختياري عند الضغط المطول
  final VoidCallback? onLongPress;

  /// اللون المميز لحواف البطاقة والوهج المحيطي
  final Color? accentColor;

  /// لون خلفية اختياري مخصص
  final Color? backgroundColor;

  /// نصف قطر انحناء الزوايا
  final double? borderRadius;

  /// حشوة داخلية للبطاقة
  final EdgeInsetsGeometry? padding;

  /// مقياس الضغط اللمسي (الافتراضي 0.985)
  final double pressedScale;

  /// هل البطاقة محددة حالياً
  final bool isSelected;

  /// هل يظهر وهج الحافة العلوية المميز
  final bool showTopAccentGlow;

  /// ينشئ بطاقة مستقبلية تفاعلية.
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

    // Background calculation
    final defaultBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final baseBg = widget.backgroundColor ?? defaultBg;

    // Border color logic based on hover / focus / selected states
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

    // Shadow & ambient glow
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
              // Subtle top-edge neon illumination line if requested
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

              // Main child content
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
                        widget.padding ?? const EdgeInsets.all(AppTokens.spaceMd),
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
