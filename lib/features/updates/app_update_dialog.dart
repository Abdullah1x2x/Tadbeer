import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../core/design_system/app_icons.dart';
import '../../core/theme/theme.dart';
import '../../data/storage/user_data_store.dart';
import 'app_update_model.dart';
import 'app_update_service.dart';

/// نافذة تنبيه وتنزيل التحديثات لتطبيق «تدبير».
class AppUpdateDialog extends StatefulWidget {
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
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  bool _isDownloading = false;
  DownloadProgress? _downloadProgress;
  String? _errorMessage;
  File? _downloadedFile;
  StreamSubscription<DownloadProgress>? _downloadSub;

  @override
  void initState() {
    super.initState();
    _checkExistingFile();
  }

  @override
  void dispose() {
    unawaited(_downloadSub?.cancel());
    super.dispose();
  }

  Future<void> _checkExistingFile() async {
    try {
      final file = await AppUpdateService.instance.getUpdateApkFile(
        widget.update.buildNumber,
      );
      if (await file.exists() && await file.length() > 1024 * 1024) {
        if (mounted) {
          setState(() {
            _downloadedFile = file;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _errorMessage = null;
      _downloadProgress = null;
    });

    try {
      final file = await AppUpdateService.instance.getUpdateApkFile(
        widget.update.buildNumber,
      );

      await _downloadSub?.cancel();
      _downloadSub = AppUpdateService.instance
          .downloadApkFile(
            url: widget.update.directApkUrl,
            targetFile: file,
          )
          .listen(
            (progress) {
              if (!mounted) return;
              setState(() {
                _downloadProgress = progress;
              });
            },
            onError: (err) {
              if (!mounted) return;
              setState(() {
                _isDownloading = false;
                _errorMessage = err.toString();
              });
            },
            onDone: () async {
              if (!mounted) return;
              setState(() {
                _isDownloading = false;
                _downloadedFile = file;
              });
              // استدعاء مثبت النظام التلقائي في أندرويد
              await AppUpdateService.instance.installApk(file.path);
            },
            cancelOnError: true,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _cancelDownload() {
    unawaited(_downloadSub?.cancel());
    _downloadSub = null;
    setState(() {
      _isDownloading = false;
      _downloadProgress = null;
    });
  }

  Future<void> _installDownloadedApk() async {
    if (_downloadedFile == null) return;
    await AppUpdateService.instance.installApk(_downloadedFile!.path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final gold = AppColors.accentGold(context);

    return PopScope(
      canPop: !_isDownloading,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isDownloading) {
          _cancelDownload();
          Navigator.pop(context);
        }
      },
      child: Directionality(
        textDirection: context.currentLanguage.direction,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.comsilkLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.lightBorder,
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
                              widget.update.title.isNotEmpty
                                  ? widget.update.title
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
                                    'v${widget.update.latestVersion}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: primary,
                                    ),
                                  ),
                                ),
                                if (widget.update.releaseDate.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.update.releaseDate,
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
                          widget.update.changelog.isNotEmpty
                              ? widget.update.changelog
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
                  const SizedBox(height: 16),

                  // قسم التحكم وأزرار التحميل
                  _buildActionSection(context, isDark, primary),
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
  ) {
    final l10n = context.l10n;

    // حالة جارٍ التنزيل
    if (_isDownloading) {
      final percent = (_downloadProgress != null)
          ? (_downloadProgress!.progress * 100).toInt()
          : 0;
      final progressVal = _downloadProgress?.progress;

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
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
                    Text(
                      l10n.isArabic
                          ? 'جارٍ التحميل والتثبيت التلقائي...'
                          : 'Downloading and preparing install...',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
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
                  _downloadProgress != null
                      ? '${_downloadProgress!.receivedMb} MB / ${_downloadProgress!.totalMb} MB'
                      : '...',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                TextButton(
                  onPressed: _cancelDownload,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    l10n.isArabic ? 'إلغاء التحميل' : 'Cancel',
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
    if (_downloadedFile != null) {
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
                    l10n.isArabic
                        ? 'اكتمل التحميل! اضغط على التثبيت لتحديث التطبيق.'
                        : 'Download complete! Tap Install to update.',
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
            onPressed: _installDownloadedApk,
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
              l10n.isArabic ? 'تثبيت التحديث الآن' : 'Install Update Now',
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
                  onPressed: _startDownload,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    l10n.isArabic ? 'إعادة التنزيل' : 'Re-download',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l10n.isArabic ? 'لاحقاً' : 'Later',
                  style: TextStyle(color: AppColors.textSecondary(context)),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // حالة حدوث خطأ أثناء التنزيل
    if (_errorMessage != null) {
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
                    l10n.isArabic
                        ? 'تعذر إكمال التحميل التلقائي. يمكنك إعادة المحاولة أو التحميل عبر تيليجرام.'
                        : 'Auto-download failed. You can retry or download via Telegram.',
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
            onPressed: _startDownload,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(AppIcons.arrowCounterClockwise, size: 18),
            label: Text(
              l10n.isArabic ? 'إعادة المحاولة' : 'Retry Download',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    AppUpdateService.instance.openTelegram(
                      widget.update.telegramUrl,
                    );
                  },
                  child: Text(
                    l10n.isArabic ? 'تيليجرام' : 'Telegram',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l10n.isArabic ? 'إغلاق' : 'Close',
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
          onPressed: _startDownload,
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
            l10n.isArabic
                ? 'تحميل وتثبيت التحديث تلقائياً'
                : 'Download & Install Update',
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // الخيارات البديلة: تيليجرام و GitHub ومتصفح
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            AppUpdateService.instance.openTelegram(widget.update.telegramUrl);
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
            l10n.isArabic
                ? 'تحميل عبر قناة تيليجرام الرسمية'
                : 'Download via Official Telegram',
            style: const TextStyle(
              fontSize: 13.5,
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
                    widget.update.downloadUrl,
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(AppIcons.cloudArrowDown, size: 16),
                label: Text(
                  l10n.isArabic ? 'تحميل من GitHub' : 'Download via GitHub',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (!widget.update.isMandatory) {
                  await UserDataStore.instance.dismissUpdateVersion(
                    widget.update.latestVersion,
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
    );
  }
}
