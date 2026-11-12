import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../core/design_system/app_icons.dart';
import '../../core/theme/theme.dart';
import '../../data/storage/user_data_store.dart';
import 'app_update_model.dart';
import 'app_update_service.dart';

/// نافذة تنبيه وتنزيل التحديثات لتطبيق «تدبير».
class AppUpdateDialog extends StatelessWidget {
  final AppUpdateInfo update;

  const AppUpdateDialog({super.key, required this.update});

  static Future<void> show(BuildContext context, AppUpdateInfo update) async {
    AppUpdateService.instance.isDialogVisible.value = true;
    try {
      return await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        isDismissible: !update.isMandatory,
        enableDrag: !update.isMandatory,
        backgroundColor: Colors.transparent,
        builder: (_) => AppUpdateDialog(update: update),
      );
    } finally {
      AppUpdateService.instance.isDialogVisible.value = false;
    }
  }

  Future<void> _installOrWarn(BuildContext context) async {
    final ok = await AppUpdateService.instance
        .installCurrentDownloadedApk(restart: true);
    if (!ok && context.mounted) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(context.l10n.downloadFailed),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'GitHub',
              onPressed: () =>
                  AppUpdateService.instance.openDownload(update.downloadUrl),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final gold = AppColors.accentGold(context);

    return PopScope(
      canPop: !update.isMandatory,
      child: Directionality(
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
                maxHeight: MediaQuery.sizeOf(context).height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!update.isMandatory)
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
                                : l10n.newUpdateAvailable,
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
                  l10n.whatsNewInRelease,
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
                            : l10n.generalPerformanceAndUiImprovements,
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
                const SizedBox(height: 16),

                  // قسم أزرار التحميل متصل بالحالة المركزية
                  ValueListenableBuilder<UpdateDownloadState>(
                    valueListenable: AppUpdateService.instance.downloadState,
                    builder: (context, downloadState, _) {
                      return _buildActionSection(
                        context,
                        isDark,
                        primary,
                        downloadState,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionSection(
    BuildContext context,
    bool isDark,
    Color primary,
    UpdateDownloadState downloadState,
  ) {
    final l10n = context.l10n;

    // حالة جارٍ التنزيل في الخلفية
    if (downloadState.isDownloading) {
      final totalBytes = downloadState.progress?.totalBytes ?? 0;
      final percent = (downloadState.progress != null && totalBytes > 0)
          ? (downloadState.progress!.progress * 100).toInt()
          : 0;
      final progressVal =
          totalBytes > 0 ? downloadState.progress?.progress : null;

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primary.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: progressVal,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          l10n.downloadingAndPreparingInstall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progressVal,
                minHeight: 8,
                backgroundColor: primary.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(primary),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  downloadState.progress != null
                      ? (totalBytes > 0
                          ? '${downloadState.progress!.receivedMb} MB / ${downloadState.progress!.totalMb} MB'
                          : '${downloadState.progress!.receivedMb} MB')
                      : '...',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    AppUpdateService.instance.cancelDownload();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    l10n.cancelUpdateDownload,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // حالة اكتمال التنزيل وجاهزية التثبيت
    if (downloadState.isCompleted && downloadState.targetFile != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(AppIcons.checkCircleFill, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.downloadCompleteTapInstall,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _installOrWarn(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(AppIcons.checkCircle, size: 20),
            label: Text(
              l10n.installUpdateNow,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    AppUpdateService.instance.startDownload(update);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    l10n.reDownload,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              if (!update.isMandatory) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    l10n.permissionsLater,
                    style: TextStyle(color: AppColors.textSecondary(context)),
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    }

    // حالة حدوث خطأ أثناء التنزيل
    if (downloadState.isError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  AppIcons.warningCircle,
                  color: Theme.of(context).colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.autoDownloadFailed,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              AppUpdateService.instance.startDownload(update);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(AppIcons.arrowCounterClockwise, size: 18),
            label: Text(
              l10n.retryDownload,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    AppUpdateService.instance.openTelegram(
                      update.telegramUrl,
                    );
                  },
                  child: Text(
                    l10n.telegramLabel,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l10n.close,
                  style: TextStyle(color: AppColors.textSecondary(context)),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // الحالة الافتراضية (Idle)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // الزر الأساسي: تحميل وتثبيت التحديث مباشرة داخل التطبيق
        ElevatedButton.icon(
          onPressed: () {
            AppUpdateService.instance.startDownload(update);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          icon: const Icon(AppIcons.cloudArrowDown, size: 20),
          label: Text(
            l10n.downloadInstallUpdate,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // الخيار البديل: تيليجرام
        ElevatedButton.icon(
          onPressed: () {
            if (!update.isMandatory) Navigator.pop(context);
            AppUpdateService.instance.openTelegram(update.telegramUrl);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF229ED9),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(AppIcons.arrowSquareOut, size: 18),
          label: Text(
            l10n.downloadViaOfficialTelegram,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (!update.isMandatory) ...[
          const SizedBox(height: 8),

          // زر لاحقاً
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await UserDataStore.instance.dismissUpdateVersion(
                update.latestVersion,
              );
            },
            child: Text(
              l10n.permissionsLater,
              style: TextStyle(
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
