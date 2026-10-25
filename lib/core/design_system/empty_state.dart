import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'app_icons.dart';

/// حالة فارغة موحدة تشرح للمستخدم كيف يبدأ، مع زر إجراء اختياري.
///
/// Shared empty state: a soft icon badge, a title, a one-line hint on how to
/// fill the screen, and an optional call-to-action button.
class EmptyState extends StatelessWidget {
  /// أيقونة الحالة الفارغة.
  final IconData icon;

  /// العنوان الرئيسي.
  final String title;

  /// شرح مختصر لكيفية إضافة أول عنصر.
  final String? hint;

  /// نص زر الإجراء.
  final String? actionLabel;

  /// أيقونة زر الإجراء.
  final IconData? actionIcon;

  /// ما يحدث عند الضغط على زر الإجراء.
  final VoidCallback? onAction;

  /// ينشئ حالة فارغة موحدة.
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
