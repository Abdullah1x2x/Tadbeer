import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../core/design_system/app_icons.dart';
import '../../core/theme/theme.dart';
import '../../data/storage/user_data_store.dart';
import 'app_update_model.dart';
import 'app_update_service.dart';

/// نافذة تنبيه للمستخدم عند توفر تحديث جديد لتطبيق «تدبير».
class AppUpdateDialog extends StatelessWidget {
  final AppUpdateInfo update;

  const AppUpdateDialog({super.key, required this.update});

  static Future<void> show(BuildContext context, AppUpdateInfo update) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppUpdateDialog(update: update),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final gold = AppColors.accentGold(context);

    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.comsilkLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightBorder,
          ),
        ),
        child: SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.82,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // مقبض السحب
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // رأس النافذة مع شارة التحديث
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: gold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: gold.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(AppIcons.sparkleFill, color: gold, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            update.title.isNotEmpty
                                ? update.title
                                : (l10n.isArabic
                                    ? 'يتوفر تحديث جديد'
                                    : 'New Update Available'),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'v${update.latestVersion}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: primary,
                                  ),
                                ),
                              ),
                              if (update.releaseDate.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(
                                  update.releaseDate,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary(context),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // سجل التغييرات والتحسينات
                Text(
                  l10n.isArabic
                      ? 'ما الجديد في هذا الإصدار:'
                      : "What's new in this release:",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBackground
                          : AppColors.comsilk,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        update.changelog.isNotEmpty
                            ? update.changelog
                            : (l10n.isArabic
                                ? 'تحسينات عامة في الأداء والواجهة.'
                                : 'General performance and UI improvements.'),
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.6,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightPrimaryDark,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // أزرار التحميل
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    AppUpdateService.instance.openTelegram(update.telegramUrl);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF229ED9), // لون تيليجرام الرسمي
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(AppIcons.arrowSquareOut, size: 20),
                  label: Text(
                    l10n.isArabic
                        ? 'تحميل عبر قناة تيليجرام الرسمية'
                        : 'Download via Official Telegram',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          AppUpdateService.instance.openDownload(
                            update.downloadUrl,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(AppIcons.cloudArrowDown, size: 18),
                        label: Text(
                          l10n.isArabic
                              ? 'تحميل من GitHub'
                              : 'Download via GitHub',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        if (!update.isMandatory) {
                          await UserDataStore.instance.dismissUpdateVersion(
                            update.latestVersion,
                          );
                        }
                      },
                      child: Text(
                        l10n.isArabic ? 'لاحقاً' : 'Later',
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
