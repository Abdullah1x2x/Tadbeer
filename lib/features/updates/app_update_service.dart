import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/localization.dart';
import '../../data/storage/user_data_store.dart';
import 'app_update_dialog.dart';
import 'app_update_model.dart';

/// حالات تنزيل التحديث في الخلفية.
enum UpdateDownloadStatus {
  idle,
  downloading,
  completed,
  error,
}

/// بيانات حالة التنزيل الشاملة المشتركة عبر التطبيق.
class UpdateDownloadState {
  final UpdateDownloadStatus status;
  final AppUpdateInfo? updateInfo;
  final DownloadProgress? progress;
  final File? targetFile;
  final String? errorMessage;

  const UpdateDownloadState({
    this.status = UpdateDownloadStatus.idle,
    this.updateInfo,
    this.progress,
    this.targetFile,
    this.errorMessage,
  });

  bool get isDownloading => status == UpdateDownloadStatus.downloading;
  bool get isCompleted => status == UpdateDownloadStatus.completed;
  bool get isError => status == UpdateDownloadStatus.error;
  bool get isIdle => status == UpdateDownloadStatus.idle;
}

/// خدمة التحقق من توفر تحديث جديد للتطبيق وتنزيله في الخلفية.
///
/// تعمل الخدمة بخصوصية مطلقة دون جمع أو إرسال أي معرفات أو بيانات جهاز.
class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  /// الإصدار الحالي المثبت من التطبيق.
  static const String currentVersion = '1.0.1';

  /// رقم البناء الحالي.
  static const int currentBuildNumber = 2;

  /// الرابط الأساسي لملف الإصدار في مستودع GitHub.
  static const String _primaryUrl =
      'https://raw.githubusercontent.com/Abdullah1x2x/Tadbeer/main/version.json';

  /// الرابط الاحتياطي لملف الإصدار على الموقع الرسمي.
  static const String _fallbackUrl =
      'https://tadbeerquran.netlify.app/version.json';

  /// رابط قناة تيليجرام الرسمية الافتراضي.
  static const String defaultTelegramUrl = 'https://t.me/tadbeerapp';

  /// رابط بوت التيليجرام لاستقبال الآراء والمقترحات.
  static const String feedbackBotUrl = 'https://t.me/TadbeerFeedbackBot';

  /// رابط صفحة الإصدارات الافتراضي.
  static const String defaultReleasesUrl =
      'https://github.com/Abdullah1x2x/Tadbeer/releases/latest';

  DateTime? _lastSilentCheck;

  /// حالة التنزيل المركزية المتوفرة لجميع شاشات وعناصر التطبيق.
  final ValueNotifier<UpdateDownloadState> downloadState =
      ValueNotifier(const UpdateDownloadState());

  /// يعكس ما إذا كانت نافذة التحديث معروضة الآن في الواجهة (لتجنب ازدواجية الشريط العائم).
  final ValueNotifier<bool> isDialogVisible = ValueNotifier(false);

  StreamSubscription<DownloadProgress>? _downloadSub;

  /// يجلب بيانات التحديث من المستودع عبر HTTP GET مجهول.
  ///
  /// يرمي استثناءً عند تعذر الوصول إلى جميع الروابط أو فشل قراءة الاستجابة.
  Future<AppUpdateInfo> fetchUpdateInfo({
    @visibleForTesting List<String>? urls,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 6);

    Object? lastError;
    try {
      // محاولة عبر الرابط الأساسي، ثم الاحتياطي إن تعذر.
      for (final url in urls ?? [_primaryUrl, _fallbackUrl]) {
        try {
          final uri = Uri.parse(url);
          final request = await client.getUrl(uri).timeout(
            const Duration(seconds: 6),
          );
          request.headers.set(
            HttpHeaders.userAgentHeader,
            'TadbeerApp/$currentVersion (Android; Offline-First)',
          );
          final response = await request.close().timeout(
            const Duration(seconds: 6),
          );

          if (response.statusCode == HttpStatus.ok) {
            final jsonStr = await response
                .transform(utf8.decoder)
                .join()
                .timeout(const Duration(seconds: 6));
            final data = json.decode(jsonStr) as Map<String, dynamic>;
            return AppUpdateInfo.fromJson(data);
          }
          await response.drain<void>();
          lastError = HttpException(
            'Update check failed with status ${response.statusCode}',
            uri: uri,
          );
        } catch (e) {
          lastError = e;
        }
      }
    } finally {
      client.close();
    }
    throw lastError ?? const SocketException('Failed to fetch update info');
  }

  /// يتحقق من التحديثات:
  /// - إذا كان التنزيل جارياً، يعيد فتح نافذة التحديث مباشرة.
  /// - إذا كان [showFeedback] صحيحاً (فحص يدوي): يُظهر حالة الفحص ونتيجته للمستخدم.
  /// - إذا كان خاطئاً (فحص تلقائي صامت): يفحص في الخلفية فقط إذا كان الخيار مفعلاً.
  Future<void> checkForUpdates(
    BuildContext context, {
    bool showFeedback = true,
    @visibleForTesting List<String>? urls,
  }) async {
    // إذا كان التحميل جارياً أو مكتملاً، نفتح نافذة التحديث فوراً
    if ((downloadState.value.isDownloading || downloadState.value.isCompleted) &&
        downloadState.value.updateInfo != null) {
      if (context.mounted) {
        await AppUpdateDialog.show(context, downloadState.value.updateInfo!);
      }
      return;
    }

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
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
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
                    context.l10n.checkingForUpdates,
                  ),
                ],
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    }

    final AppUpdateInfo update;
    try {
      update = await fetchUpdateInfo(urls: urls);
    } catch (_) {
      if (showFeedback && context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.updateCheckFailed,
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
      return;
    }

    if (!context.mounted) return;

    if (update.isNewerThan(currentBuildNumber, currentVersion)) {
      // التحقق مما إذا كان الملف محملاً مسبقاً
      await checkExistingDownloadedApk(update);
      if (!context.mounted) return;

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
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.usingLatestVersion(currentVersion),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  /// يتحقق مما إذا كانت حزمة التحديث قد حُمّلت مسبقاً وجاهزة للتثبيت.
  Future<void> checkExistingDownloadedApk(AppUpdateInfo update) async {
    try {
      final file = await getUpdateApkFile(update.buildNumber);
      if (await file.exists() && await file.length() > 1024 * 1024) {
        downloadState.value = UpdateDownloadState(
          status: UpdateDownloadStatus.completed,
          updateInfo: update,
          targetFile: file,
          progress: const DownloadProgress(
            receivedBytes: 100,
            totalBytes: 100,
          ),
        );
      }
    } catch (e) {
      // path_provider أو نظام الملفات: يبقى التحديث قابلاً للتنزيل من جديد.
      debugPrint('Checking the downloaded update failed: $e');
    }
  }

  /// يبدأ تنزيل ملف التحديث في الخلفية مع تحديث الحالة المركزية.
  Future<void> startDownload(AppUpdateInfo update) async {
    if (downloadState.value.isDownloading) return;
    // ملف APK لأندرويد وحده؛ غيره يفتح صفحة الإصدار.
    if (!Platform.isAndroid) {
      await openDownload(update.downloadUrl);
      return;
    }

    try {
      final file = await getUpdateApkFile(update.buildNumber);
      final abi = await _deviceAbi();

      downloadState.value = UpdateDownloadState(
        status: UpdateDownloadStatus.downloading,
        updateInfo: update,
        targetFile: file,
      );

      await _downloadSub?.cancel();
      _downloadSub = downloadApkFile(
        url: update.apkUrlFor(abi),
        targetFile: file,
      ).listen(
        (progress) {
          downloadState.value = UpdateDownloadState(
            status: UpdateDownloadStatus.downloading,
            updateInfo: update,
            progress: progress,
            targetFile: file,
          );
        },
        onError: (err) {
          downloadState.value = UpdateDownloadState(
            status: UpdateDownloadStatus.error,
            updateInfo: update,
            targetFile: file,
            errorMessage: err.toString(),
          );
        },
        onDone: () async {
          downloadState.value = UpdateDownloadState(
            status: UpdateDownloadStatus.completed,
            updateInfo: update,
            targetFile: file,
            progress: const DownloadProgress(
              receivedBytes: 100,
              totalBytes: 100,
            ),
          );
          // استدعاء مثبت النظام التلقائي في أندرويد
          await installApk(file.path);
        },
        cancelOnError: true,
      );
    } catch (e) {
      downloadState.value = UpdateDownloadState(
        status: UpdateDownloadStatus.error,
        updateInfo: update,
        errorMessage: e.toString(),
      );
    }
  }

  /// إلغاء التنزيل الحالي ومسح الملف المؤقت والحالة.
  void cancelDownload() {
    unawaited(_downloadSub?.cancel());
    _downloadSub = null;
    final file = downloadState.value.targetFile;
    if (file != null) {
      try {
        if (file.existsSync()) {
          file.deleteSync();
        }
        final part = File('${file.path}.part');
        if (part.existsSync()) {
          part.deleteSync();
        }
      } on FileSystemException catch (e) {
        debugPrint('Deleting the update download failed: $e');
      }
    }
    downloadState.value = const UpdateDownloadState(
      status: UpdateDownloadStatus.idle,
    );
  }

  /// تثبيت الحزمة المحملة حالياً عبر مثبت النظام.
  Future<bool> installCurrentDownloadedApk() async {
    final file = downloadState.value.targetFile;
    if (file == null || !await file.exists()) return false;
    return installApk(file.path);
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

  /// يفتح بوت التيليجرام الرسمي لاستقبال الآراء والمقترحات.
  Future<bool> openFeedbackBot([String? url]) async {
    final target = Uri.parse(url ?? feedbackBotUrl);
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

  static const MethodChannel _deviceChannel = MethodChannel('tadbeer/device');

  /// معمارية الجهاز (مثل `armeabi-v7a`)، أو null إن تعذّرت قراءتها.
  Future<String?> _deviceAbi() async {
    try {
      return await _deviceChannel.invokeMethod<String>('abi');
    } catch (e) {
      debugPrint('Reading the device ABI failed: $e');
      return null;
    }
  }

  /// يحصل على المسار المحلي لتخزين ملف الـ APK المحمّل.
  Future<File> getUpdateApkFile(int buildNumber) async {
    final tempDir = await getTemporaryDirectory();
    return File('${tempDir.path}/tadbeer_update_$buildNumber.apk');
  }

  /// يثبّت ملف الـ APK المخصص لأندرويد عبر استدعاء النظام الأصلي.
  Future<bool> installApk(String filePath) async {
    if (!Platform.isAndroid) return false;
    try {
      final res = await _deviceChannel.invokeMethod<bool>('installApk', {
        'filePath': filePath,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// ينزل ملف الـ APK في مجلد الكاش مع إرسال نسبة التقدم (0.0 إلى 1.0) وإجمالي البايتات.
  Stream<DownloadProgress> downloadApkFile({
    required String url,
    required File targetFile,
  }) async* {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);

    // يُكتب في ملف مؤقت ثم يُعاد تسميته، فلا يوجد الملف النهائي إلا كاملاً.
    final partFile = File('${targetFile.path}.part');
    IOSink? sink;
    try {
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      sink = partFile.openWrite();

      final request = await client.getUrl(Uri.parse(url));
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'TadbeerApp/$currentVersion (Android; Offline-First)',
      );
      final response = await request.close();

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Download failed with status ${response.statusCode}',
        );
      }

      final total = response.contentLength;
      var received = 0;

      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        yield DownloadProgress(
          receivedBytes: received,
          totalBytes: total > 0 ? total : 0,
        );
      }

      await sink.close();
      if (total > 0 && received != total) {
        throw HttpException('Download incomplete: $received of $total bytes');
      }
      await partFile.rename(targetFile.path);
    } finally {
      await sink?.close();
      client.close();
    }
  }
}

/// بيانات تقدم تنزيل ملف التحديث.
class DownloadProgress {
  final int receivedBytes;
  final int totalBytes;

  const DownloadProgress({
    required this.receivedBytes,
    required this.totalBytes,
  });

  double get progress =>
      totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;

  String get receivedMb => (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
  String get totalMb => (totalBytes / (1024 * 1024)).toStringAsFixed(1);
}
