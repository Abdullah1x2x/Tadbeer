import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
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
  static const String currentVersion = '1.0.0';

  /// رقم البناء الحالي.
  static const int currentBuildNumber = 1;

  /// مدة الانتظار بين محاولات الفحص التلقائي الناجحة في نفس الجلسة.
  static const Duration silentCheckCooldown = Duration(hours: 2);

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
  bool _isChecking = false;
  bool _isStartingDownload = false;
  int _downloadGeneration = 0;
  HttpClient? _activeDownloadClient;

  static String get _userAgent =>
      'TadbeerApp/$currentVersion (${Platform.operatingSystem}; Offline-First)';

  @visibleForTesting
  void resetSilentCheckForTesting() {
    _lastSilentCheck = null;
    _isChecking = false;
  }

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
          request.headers.set(HttpHeaders.userAgentHeader, _userAgent);
          request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
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
    @visibleForTesting DateTime? currentTime,
  }) async {
    // إذا كان التحميل جارياً أو مكتملاً، نفتح نافذة التحديث فوراً عند الطلب اليدوي.
    if ((downloadState.value.isDownloading || downloadState.value.isCompleted) &&
        downloadState.value.updateInfo != null) {
      if (showFeedback && context.mounted) {
        await AppUpdateDialog.show(context, downloadState.value.updateInfo!);
      }
      return;
    }

    if (_isChecking) return;

    final now = currentTime ?? DateTime.now();
    if (!showFeedback) {
      if (isDialogVisible.value) return;
      final settings = UserDataStore.instance.settings;
      if (!settings.autoCheckUpdates) return;

      // منع تكرار الفحص الصامت الناجح أكثر من مرة كل ساعتين في نفس الجلسة.
      if (_lastSilentCheck != null &&
          now.difference(_lastSilentCheck!) < silentCheckCooldown) {
        return;
      }
    }

    _isChecking = true;
    try {
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

      // يُسجَّل وقت الفحص الصامت بعد نجاح الجلب فقط، كي لا يُحجب التكرار عند فشل الشبكة.
      if (!showFeedback) {
        _lastSilentCheck = now;
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
    } finally {
      _isChecking = false;
    }
  }

  /// يتحقق مما إذا كانت حزمة التحديث قد حُمّلت مسبقاً وجاهزة للتثبيت.
  Future<void> checkExistingDownloadedApk(AppUpdateInfo update) async {
    if (!Platform.isAndroid && !Platform.isLinux) return;
    try {
      final file = await getUpdatePackageFile(update);
      if (await file.exists()) {
        final len = await file.length();
        if (len > 1024 * 1024) {
          final abi = Platform.isAndroid ? await _deviceAbi() : null;
          final expectedHash =
              update.expectedSha256For(abi: abi).trim().toLowerCase();
          if (expectedHash.isNotEmpty) {
            final actual = await _fileSha256(file);
            if (actual != expectedHash) {
              await file.delete();
              return;
            }
          }
          downloadState.value = UpdateDownloadState(
            status: UpdateDownloadStatus.completed,
            updateInfo: update,
            targetFile: file,
            progress: DownloadProgress(
              receivedBytes: len,
              totalBytes: len,
            ),
          );
        }
      }
    } catch (e) {
      // path_provider أو نظام الملفات: يبقى التحديث قابلاً للتنزيل من جديد.
      debugPrint('Checking the downloaded update failed: $e');
    }
  }

  /// يبدأ تنزيل ملف التحديث في الخلفية مع تحديث الحالة المركزية.
  Future<void> startDownload(AppUpdateInfo update) async {
    if (_isStartingDownload || downloadState.value.isDownloading) return;
    // أندرويد ينزّل APK ولينكس ينزّل حزمة tar.gz؛ بقية المنصات تفتح صفحة الإصدار.
    if (!Platform.isAndroid && !Platform.isLinux) {
      await openDownload(update.downloadUrl);
      return;
    }

    _isStartingDownload = true;
    final generation = ++_downloadGeneration;
    // نُثبت حالة التنزيل فوراً قبل أي await لمنع النقر المزدوج.
    downloadState.value = UpdateDownloadState(
      status: UpdateDownloadStatus.downloading,
      updateInfo: update,
    );

    try {
      final file = await getUpdatePackageFile(update);
      final abi = Platform.isAndroid ? await _deviceAbi() : null;
      if (generation != _downloadGeneration) return;

      downloadState.value = UpdateDownloadState(
        status: UpdateDownloadStatus.downloading,
        updateInfo: update,
        targetFile: file,
      );

      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15);
      _activeDownloadClient?.close(force: true);
      _activeDownloadClient = client;

      await _downloadSub?.cancel();
      DownloadProgress? lastProgress;
      _downloadSub = _downloadFileWithClient(
        client: client,
        ownsClient: true,
        url: update.packageUrlFor(abi: abi),
        targetFile: file,
        expectedSha256: update.expectedSha256For(abi: abi),
      ).listen(
        (progress) {
          if (generation != _downloadGeneration) return;
          lastProgress = progress;
          downloadState.value = UpdateDownloadState(
            status: UpdateDownloadStatus.downloading,
            updateInfo: update,
            progress: progress,
            targetFile: file,
          );
        },
        onError: (err) {
          if (identical(_activeDownloadClient, client)) {
            _activeDownloadClient = null;
          }
          if (generation != _downloadGeneration) return;
          downloadState.value = UpdateDownloadState(
            status: UpdateDownloadStatus.error,
            updateInfo: update,
            targetFile: file,
            errorMessage: err.toString(),
          );
        },
        onDone: () async {
          if (identical(_activeDownloadClient, client)) {
            _activeDownloadClient = null;
          }
          if (generation != _downloadGeneration) return;
          var finalProgress = lastProgress;
          if (finalProgress == null || finalProgress.totalBytes <= 0) {
            final len = await file.exists() ? await file.length() : 0;
            finalProgress = DownloadProgress(
              receivedBytes: len,
              totalBytes: len,
            );
          }
          if (generation != _downloadGeneration) return;
          downloadState.value = UpdateDownloadState(
            status: UpdateDownloadStatus.completed,
            updateInfo: update,
            targetFile: file,
            progress: finalProgress,
          );
          await installCurrentDownloadedApk();
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (generation == _downloadGeneration) {
        downloadState.value = UpdateDownloadState(
          status: UpdateDownloadStatus.error,
          updateInfo: update,
          errorMessage: e.toString(),
        );
      }
    } finally {
      _isStartingDownload = false;
    }
  }

  /// إلغاء التنزيل الحالي ومسح الملف المؤقت والحالة.
  void cancelDownload() {
    ++_downloadGeneration;
    _isStartingDownload = false;
    _activeDownloadClient?.close(force: true);
    _activeDownloadClient = null;
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

  /// تثبيت الحزمة المحملة حالياً (APK في أندرويد، أو فتح مجلد الحزمة في لينكس).
  Future<bool> installCurrentDownloadedApk() async {
    final file = downloadState.value.targetFile;
    if (file == null || !await file.exists()) return false;
    if (Platform.isAndroid) {
      return installApk(file.path);
    }
    if (Platform.isLinux) {
      return openLinuxPackageFolder(file);
    }
    return false;
  }

  /// يفتح مجلد الحزمة المحمّلة على لينكس عبر مدير الملفات الافتراضي.
  Future<bool> openLinuxPackageFolder(File packageFile) async {
    if (!Platform.isLinux) return false;
    try {
      final result = await Process.run(
        'xdg-open',
        [packageFile.parent.path],
      ).timeout(const Duration(seconds: 5));
      if (result.exitCode == 0) return true;
    } catch (e) {
      debugPrint('xdg-open failed for update folder: $e');
    }
    try {
      return await launchUrl(
        Uri.directory(packageFile.parent.path),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }

  /// يفتح قناة تيليجرام الرسمية لتنزيل التحديث.
  static Uri _validatedExternalUri(
    String? rawUrl,
    String fallbackUrl, {
    required Set<String> allowedHosts,
    required String requiredPathPrefix,
  }) {
    final trimmed = rawUrl?.trim();
    final parsed = trimmed == null ? null : Uri.tryParse(trimmed);
    if (parsed == null ||
        parsed.scheme != 'https' ||
        parsed.userInfo.isNotEmpty ||
        parsed.hasPort ||
        !allowedHosts.contains(parsed.host.toLowerCase())) {
      return Uri.parse(fallbackUrl);
    }
    final afterScheme = trimmed!.substring(parsed.scheme.length + 3);
    final authorityAndPath = afterScheme.split('?').first.split('#').first;
    final slashIndex = authorityAndPath.indexOf('/');
    final rawPath =
        slashIndex == -1 ? '' : authorityAndPath.substring(slashIndex);
    final lowerRawPath = rawPath.toLowerCase();
    final hasTraversalOrEncoding =
        rawPath.split('/').any((s) => s == '.' || s == '..') ||
        lowerRawPath.contains('%2e') ||
        lowerRawPath.contains('%2f') ||
        lowerRawPath.contains('%5c') ||
        lowerRawPath.contains('%25') ||
        lowerRawPath.contains(r'\');
    final normalized = parsed.normalizePath();
    final path = normalized.path;
    final pathOk =
        path == requiredPathPrefix || path.startsWith('$requiredPathPrefix/');
    if (!hasTraversalOrEncoding && pathOk) {
      return normalized;
    }
    return Uri.parse(fallbackUrl);
  }

  /// يفتح قناة تيليجرام الرسمية لتنزيل التحديث.
  Future<bool> openTelegram([String? url]) async {
    final target = _validatedExternalUri(
      url,
      defaultTelegramUrl,
      allowedHosts: const {'t.me', 'telegram.me'},
      requiredPathPrefix: '/tadbeerapp',
    );
    try {
      return await launchUrl(target, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// يفتح بوت التيليجرام الرسمي لاستقبال الآراء والمقترحات.
  Future<bool> openFeedbackBot([String? url]) async {
    final target = _validatedExternalUri(
      url,
      feedbackBotUrl,
      allowedHosts: const {'t.me', 'telegram.me'},
      requiredPathPrefix: '/TadbeerFeedbackBot',
    );
    try {
      return await launchUrl(target, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// يفتح رابط التنزيل المباشر أو المستودع.
  Future<bool> openDownload([String? url]) async {
    final target = _validatedExternalUri(
      url,
      defaultReleasesUrl,
      allowedHosts: const {'github.com'},
      requiredPathPrefix: '/Abdullah1x2x/Tadbeer',
    );
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
    final safeBuild = buildNumber > 0 ? buildNumber : 1;
    return File('${tempDir.path}/tadbeer_update_$safeBuild.apk');
  }

  /// يحصل على المسار المحلي المناسب لحزمة التحديث حسب المنصة الحالية.
  Future<File> getUpdatePackageFile(AppUpdateInfo update) async {
    if (Platform.isLinux) {
      Directory? dir;
      try {
        dir = await getDownloadsDirectory();
      } catch (_) {
        dir = null;
      }
      dir ??= await getTemporaryDirectory();
      final canonicalDir = dir.resolveSymbolicLinksSync();
      final rawVersion = update.latestVersion.trim();
      final safeVersion =
          RegExp(r'^\d+(\.\d+)*(-[0-9A-Za-z.-]+)?$').hasMatch(rawVersion) &&
                  !rawVersion.contains('..')
              ? rawVersion
              : 'update';
      return File('$canonicalDir/tadbeer-linux-x64-v$safeVersion.tar.gz');
    }
    return getUpdateApkFile(update.buildNumber);
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

  /// ينزل حزمة التحديث مع التحقق من حالة الاستجابة واكتمال الطول وبصمة SHA-256 الاختيارية.
  Stream<DownloadProgress> downloadApkFile({
    required String url,
    required File targetFile,
    String expectedSha256 = '',
  }) {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    return _downloadFileWithClient(
      client: client,
      ownsClient: true,
      url: url,
      targetFile: targetFile,
      expectedSha256: expectedSha256,
    );
  }

  static const _allowedDownloadHosts = {
    'github.com',
    'objects.githubusercontent.com',
    // روابط ملفات الإصدار في GitHub تُحوَّل اليوم إلى هذا الموقع.
    'release-assets.githubusercontent.com',
    'raw.githubusercontent.com',
    'tadbeerquran.netlify.app',
    '127.0.0.1',
    'localhost',
  };

  @visibleForTesting
  static bool isAllowedDownloadUri(Uri uri) {
    if (uri.scheme == 'https' &&
        _allowedDownloadHosts.contains(uri.host.toLowerCase())) {
      return true;
    }
    if (uri.scheme == 'http' &&
        (uri.host == '127.0.0.1' || uri.host == 'localhost')) {
      return true;
    }
    return false;
  }

  Stream<DownloadProgress> _downloadFileWithClient({
    required HttpClient client,
    required bool ownsClient,
    required String url,
    required File targetFile,
    String expectedSha256 = '',
  }) async* {
    // يُكتب في ملف مؤقت ثم يُعاد تسميته، فلا يوجد الملف النهائي إلا كاملاً وموثّقاً.
    final partFile = File('${targetFile.path}.part');
    IOSink? sink;
    var sinkClosed = false;
    var completed = false;
    try {
      var currentUri = Uri.parse(url);
      if (!isAllowedDownloadUri(currentUri)) {
        throw HttpException('Untrusted download URL: $currentUri');
      }
      HttpClientResponse response;
      for (var hop = 0;; hop++) {
        if (!isAllowedDownloadUri(currentUri)) {
          throw HttpException('Untrusted download redirect target: $currentUri');
        }
        final request = await client
            .getUrl(currentUri)
            .timeout(const Duration(seconds: 20));
        request.followRedirects = false;
        request.headers.set(HttpHeaders.userAgentHeader, _userAgent);
        response =
            await request.close().timeout(const Duration(seconds: 20));
        if (!response.isRedirect &&
            response.statusCode != HttpStatus.movedPermanently &&
            response.statusCode != HttpStatus.found &&
            response.statusCode != HttpStatus.seeOther &&
            response.statusCode != HttpStatus.temporaryRedirect &&
            response.statusCode != HttpStatus.permanentRedirect) {
          break;
        }
        final loc = response.headers.value(HttpHeaders.locationHeader);
        await response.drain<void>();
        if (loc == null || hop >= 5) {
          throw const HttpException('Invalid or excessive update redirects');
        }
        currentUri = currentUri.resolve(loc);
      }

      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw HttpException(
          'Download failed with status ${response.statusCode}',
        );
      }

      if (!await targetFile.parent.exists()) {
        await targetFile.parent.create(recursive: true);
      }
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      if (await partFile.exists()) {
        await partFile.delete();
      }

      sink = partFile.openWrite();
      final total = response.contentLength;
      var received = 0;

      final normalizedExpected = expectedSha256.trim().toLowerCase();
      _DigestSink? digestSink;
      ByteConversionSink? hashSink;
      if (normalizedExpected.isNotEmpty) {
        digestSink = _DigestSink();
        hashSink = sha256.startChunkedConversion(digestSink);
      }

      await for (final chunk in response.timeout(const Duration(seconds: 30))) {
        sink.add(chunk);
        hashSink?.add(chunk);
        received += chunk.length;
        yield DownloadProgress(
          receivedBytes: received,
          totalBytes: total > 0 ? total : 0,
        );
      }

      await sink.close();
      sinkClosed = true;
      hashSink?.close();

      if (total > 0 && received != total) {
        throw HttpException('Download incomplete: $received of $total bytes');
      }
      if (digestSink != null) {
        final actualHex = digestSink.value.toString().toLowerCase();
        if (actualHex != normalizedExpected) {
          throw HttpException('Checksum mismatch: expected $normalizedExpected');
        }
      }
      await partFile.rename(targetFile.path);
      completed = true;
    } finally {
      if (sink != null && !sinkClosed) {
        try {
          await sink.close();
        } catch (_) {}
      }
      if (!completed && partFile.existsSync()) {
        try {
          partFile.deleteSync();
        } catch (_) {}
      }
      if (ownsClient) {
        client.close();
      }
    }
  }

  Future<String> _fileSha256(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString().toLowerCase();
  }
}

class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
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
