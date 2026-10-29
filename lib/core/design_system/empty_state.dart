import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'app_icons.dart';

/// حالة فارغة موحّدة: أيقونة، وعنوان، وسطر يشرح كيف تبدأ، وزر إجراء اختياري.
class EmptyState extends StatelessWidget {
  final IconData icon;

  final String title;

  /// سطر يشرح كيف يُضاف أول عنصر.
  final String? hint;

  final String? actionLabel;

  final IconData? actionIcon;

  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.hint,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = AppColors.accentGold(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gold.withValues(alpha: isDark ? 0.14 : 0.12),
              ),
              child: Icon(icon, size: 44, color: gold),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.appFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: 8),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.appFontFamily,
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: Icon(actionIcon ?? AppIcons.arrowLeft, size: 20),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
