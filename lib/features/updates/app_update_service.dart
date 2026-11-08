import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/localization.dart';
import '../../data/storage/user_data_store.dart';
import 'app_update_dialog.dart';
import 'app_update_model.dart';

/// خدمة التحقق من توفر تحديث جديد للتطبيق عبر ملف `version.json` في المستودع.
///
/// تعمل الخدمة بخصوصية مطلقة دون جمع أو إرسال أي معرفات أو بيانات جهاز.
class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  /// الإصدار الحالي المثبت من التطبيق.
  static const String currentVersion = '1.0.0';

  /// رقم البناء الحالي.
  static const int currentBuildNumber = 1;

  /// الرابط الأساسي لملف الإصدار في مستودع GitHub.
  static const String _primaryUrl =
      'https://raw.githubusercontent.com/Abdullah1x2x/Tadbeer/main/version.json';

  /// الرابط الاحتياطي لملف الإصدار على الموقع الرسمي.
  static const String _fallbackUrl =
      'https://tadbeerquran.netlify.app/version.json';

  /// رابط قناة تيليجرام الرسمية الافتراضي.
  static const String defaultTelegramUrl = 'https://t.me/tadbeerapp';

  /// رابط صفحة الإصدارات الافتراضي.
  static const String defaultReleasesUrl =
      'https://github.com/Abdullah1x2x/Tadbeer/releases/latest';

  DateTime? _lastSilentCheck;

  /// يجلب بيانات التحديث من المستودع عبر HTTP GET مجهول.
  Future<AppUpdateInfo?> fetchUpdateInfo() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 6);

    try {
      // محاولة عبر الرابط الأساسي، ثم الاحتياطي إن تعذر.
      for (final url in [_primaryUrl, _fallbackUrl]) {
        try {
          final request = await client.getUrl(Uri.parse(url));
          request.headers.set(
            HttpHeaders.userAgentHeader,
            'TadbeerApp/$currentVersion (Android; Offline-First)',
          );
          final response = await request.close().timeout(
            const Duration(seconds: 6),
          );

          if (response.statusCode == HttpStatus.ok) {
            final jsonStr = await response.transform(utf8.decoder).join();
            final data = json.decode(jsonStr) as Map<String, dynamic>;
            return AppUpdateInfo.fromJson(data);
          }
        } catch (_) {
          continue;
        }
      }
    } finally {
      client.close();
    }
    return null;
  }

  /// يتحقق من التحديثات:
  /// - إذا كان [showFeedback] صحيحاً (فحص يدوي): يُظهر حالة الفحص ونتيجته للمستخدم.
  /// - إذا كان خاطئاً (فحص تلقائي صامت): يفحص في الخلفية فقط إذا كان الخيار مفعلاً.
  Future<void> checkForUpdates(
    BuildContext context, {
    bool showFeedback = true,
  }) async {
    if (!showFeedback) {
      final settings = UserDataStore.instance.settings;
      if (!settings.autoCheckUpdates) return;

      // منع تكرار الفحص الصامت أكثر من مرة كل 12 ساعة في نفس الجلسة.
      final now = DateTime.now();
      if (_lastSilentCheck != null &&
          now.difference(_lastSilentCheck!).inHours < 12) {
        return;
      }
      _lastSilentCheck = now;
    }

    if (showFeedback) {
      await HapticFeedback.lightImpact();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  context.l10n.isArabic
                      ? 'جارٍ التحقق من وجود تحديثات...'
                      : 'Checking for updates...',
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    try {
      final update = await fetchUpdateInfo();

      if (!context.mounted) return;

      if (update != null &&
          update.isNewerThan(currentBuildNumber, currentVersion)) {
        // التحقق مما إذا كان المستخدم قد تجاهل هذا الإصدار من قبل في الفحص الصامت.
        final settings = UserDataStore.instance.settings;
        if (!showFeedback &&
            !update.isMandatory &&
            settings.dismissedUpdateVersion == update.latestVersion) {
          return;
        }

        // إظهار نافذة التحديث
        await AppUpdateDialog.show(context, update);
      } else if (showFeedback) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.isArabic
                  ? 'أنت تستخدم أحدث إصدار من تطبيق تدبير (v$currentVersion)'
                  : 'You are using the latest version of Tadbeer (v$currentVersion)',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (showFeedback && context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.isArabic
                  ? 'تعذر التحقق من التحديثات، يرجى التأكد من اتصالك بالإنترنت.'
                  : 'Failed to check for updates. Please check your internet connection.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// يفتح قناة تيليجرام الرسمية لتنزيل التحديث.
  Future<bool> openTelegram([String? url]) async {
    final target = Uri.parse(url ?? defaultTelegramUrl);
    try {
      return await launchUrl(target, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// يفتح رابط التنزيل المباشر أو المستودع.
  Future<bool> openDownload([String? url]) async {
    final target = Uri.parse(url ?? defaultReleasesUrl);
    try {
      return await launchUrl(target, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
