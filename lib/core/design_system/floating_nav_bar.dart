import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';
import '../motion/app_motion.dart';

/// عنصر في شريط التنقل العائم.
class FloatingNavItem {
  final IconData icon;

  final IconData selectedIcon;

  final String label;

  const FloatingNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// شريط تنقل سفلي عائم: العنصر المحدد يتسع ليظهر اسمه، وكبسولة ذهبية تنزلق تحته.
/// لكل عنصر تلميح ووصف لقارئ الشاشة، فتبقى العناصر التي بلا اسم واضحة.
class FloatingNavBar extends StatelessWidget {
  final List<FloatingNavItem> items;

  final int selectedIndex;

  final ValueChanged<int> onSelected;

  const FloatingNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const double _height = 66;
  static const double _radius = 30;
  static const double _inset = 7;

  /// نسبة العرض التي يأخذها العنصر المحدد (الأيقونة والاسم).
  static const double _selectedShare = 0.36;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = AppColors.accentGold(context);
    final duration = AppMotion.duration(
      context,
      const Duration(milliseconds: 380),
    );
    // بلا ارتداد: يجب أن تبقى الكبسولة داخل الشريط حتى عند أول تبويب وآخره. الارتداد على الأيقونة بدلاً من ذلك.
    const curve = Curves.easeOutCubic;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Container(
          height: _height,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated(context),
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(
              color: gold.withValues(alpha: isDark ? 0.22 : 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : AppColors.lightPrimary)
                    .withValues(alpha: isDark ? 0.55 : 0.14),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final inner = constraints.maxWidth - _inset * 2;
              final wide = inner * _selectedShare;
              final narrow = (inner - wide) / (items.length - 1);
              final isRtl = Directionality.of(context) == TextDirection.rtl;

              // بداية العنصر المحدد في اتجاه القراءة، معكوسة إلى إزاحة من اليسار في RTL.
              final start = narrow * selectedIndex;
              final left = isRtl ? inner - start - wide : start;

              // طبقة مستقلة: تُرسم الكبسولة المتحركة دون إعادة رسم ظل الشريط الكبير كل إطار.
              return RepaintBoundary(
                child: Padding(
                  padding: const EdgeInsets.all(_inset),
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: duration,
                        curve: curve,
                        left: left,
                        top: 0,
                        bottom: 0,
                        width: wide,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(_radius),
                            boxShadow: [
                              BoxShadow(
                                color: gold.withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (var i = 0; i < items.length; i++)
                            AnimatedContainer(
                              duration: duration,
                              curve: curve,
                              width: i == selectedIndex ? wide : narrow,
                              child: _NavButton(
                                item: items[i],
                                selected: i == selectedIndex,
                                duration: duration,
                                onTap: () {
                                  if (i == selectedIndex) return;
                                  HapticFeedback.selectionClick();
                                  onSelected(i);
                                },
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// زر قسم: أيقونة، واسم يظهر عند التحديد فقط.
class _NavButton extends StatelessWidget {
  final FloatingNavItem item;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // الكحلي الداكن أوضح على الكبسولة الذهبية في الوضعين.
    final onGold = AppColors.lightPrimaryDark;
    final idle = AppColors.textSecondary(context);
    final color = selected ? onGold : idle;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: Tooltip(
        message: item.label,
        child: InkResponse(
          onTap: onTap,
          radius: 32,
          highlightShape: BoxShape.circle,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // مفتاح يتغير بالتحديد، فتقفز الأيقونة كلما اختيرت.
                TweenAnimationBuilder<double>(
                  key: ValueKey(selected),
                  tween: Tween(begin: selected ? 0.7 : 1.0, end: 1.0),
                  duration: duration,
                  curve: Curves.elasticOut,
                  builder: (context, pop, child) => Transform.scale(
                    scale: pop * (selected ? 1.15 : 1.0),
                    child: child,
                  ),
                  child: Icon(
                    selected ? item.selectedIcon : item.icon,
                    size: 24,
                    color: color,
                  ),
                ),
                // Flexible يقص الاسم بينما العنصر ما زال يتسع.
                Flexible(
                  child: AnimatedSize(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    child: selected
                        ? Padding(
                            padding: const EdgeInsetsDirectional.only(start: 6),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: duration,
                              builder: (context, t, child) =>
                                  Opacity(opacity: t, child: child),
                              child: Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                style: TextStyle(
                                  fontFamily: AppTheme.appFontFamily,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: onGold,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
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
