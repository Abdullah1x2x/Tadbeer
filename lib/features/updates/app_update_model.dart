import 'dart:io';
import 'dart:math' as math;

/// نموذج معلومات التحديث المجلوب من ملف `version.json` في المستودع.
class AppUpdateInfo {
  final String latestVersion;
  final int buildNumber;
  final String releaseDate;
  final String title;
  final String changelog;
  final String telegramUrl;
  final String downloadUrl;
  final String apkUrl;
  final String linuxUrl;
  final String windowsUrl;
  /// بصمة SHA-256 لكل ملف APK، مفهرسة باسم المعمارية (arm64-v8a، armeabi-v7a).
  final Map<String, String> apkSha256s;
  final String linuxSha256;
  final String windowsSha256;
  final bool isMandatory;

  const AppUpdateInfo({
    required this.latestVersion,
    required this.buildNumber,
    required this.releaseDate,
    required this.title,
    required this.changelog,
    required this.telegramUrl,
    required this.downloadUrl,
    this.apkUrl = '',
    this.linuxUrl = '',
    this.windowsUrl = '',
    this.apkSha256s = const {},
    this.linuxSha256 = '',
    this.windowsSha256 = '',
    this.isMandatory = false,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    final platforms = json['platforms'];
    final linuxPlatform = platforms is Map ? platforms['linux'] : null;
    final linuxPlatformUrl =
        linuxPlatform is Map ? linuxPlatform['url'] as String? : null;
    final linuxPlatformSha =
        linuxPlatform is Map ? linuxPlatform['sha256'] as String? : null;

    return AppUpdateInfo(
      latestVersion: json['latest_version'] as String? ?? '1.0.0',
      buildNumber: json['build_number'] as int? ?? 1,
      releaseDate: json['release_date'] as String? ?? '',
      title: json['title'] as String? ?? 'تحديث جديد',
      changelog: json['changelog'] as String? ?? '',
      telegramUrl:
          json['telegram_url'] as String? ?? 'https://t.me/tadbeerapp',
      downloadUrl: json['download_url'] as String? ??
          'https://github.com/Abdullah1x2x/Tadbeer/releases/latest',
      apkUrl: json['apk_url'] as String? ?? '',
      linuxUrl: json['linux_url'] as String? ?? linuxPlatformUrl ?? '',
      windowsUrl: json['windows_url'] as String? ?? '',
      apkSha256s: {
        if (json['apk_sha256s'] case final Map hashes)
          for (final e in hashes.entries)
            if (e.value is String) '${e.key}': e.value as String,
      },
      linuxSha256: json['linux_sha256'] as String? ?? linuxPlatformSha ?? '',
      windowsSha256: json['windows_sha256'] as String? ?? '',
      isMandatory: json['is_mandatory'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'latest_version': latestVersion,
    'build_number': buildNumber,
    'release_date': releaseDate,
    'title': title,
    'changelog': changelog,
    'telegram_url': telegramUrl,
    'download_url': downloadUrl,
    'apk_url': apkUrl,
    'linux_url': linuxUrl,
    'windows_url': windowsUrl,
    if (apkSha256s.isNotEmpty) 'apk_sha256s': apkSha256s,
    if (linuxSha256.isNotEmpty) 'linux_sha256': linuxSha256,
    if (windowsSha256.isNotEmpty) 'windows_sha256': windowsSha256,
    'is_mandatory': isMandatory,
  };

  /// الرابط المباشر لملف الـ APK للتنزيل والتثبيت الفوري.
  String get directApkUrl {
    if (apkUrl.isNotEmpty) return apkUrl;
    if (downloadUrl.endsWith('.apk')) return downloadUrl;
    return 'https://github.com/Abdullah1x2x/Tadbeer/releases/latest/download/app-arm64-v8a-release.apk';
  }

  /// الرابط المباشر لحزمة لينكس المضغوطة (x64 tar.gz).
  String get directLinuxUrl {
    if (linuxUrl.isNotEmpty) return linuxUrl;
    if (downloadUrl.endsWith('.tar.gz') || downloadUrl.endsWith('.AppImage')) {
      return downloadUrl;
    }
    return 'https://github.com/Abdullah1x2x/Tadbeer/releases/latest/download/tadbeer-linux-x64.tar.gz';
  }

  /// الرابط المباشر لحزمة ويندوز المضغوطة (x64 zip).
  String get directWindowsUrl => windowsUrl.isNotEmpty
      ? windowsUrl
      : 'https://github.com/Abdullah1x2x/Tadbeer/releases/latest/download/tadbeer-windows-x64.zip';

  /// المعماريات التي يُبنى لها ملف APK في كل إصدار (v8 و v7).
  static const _builtAbis = {'arm64-v8a', 'armeabi-v7a'};

  /// رابط حزمة معمارية الجهاز [abi]؛ ملفات الإصدار تختلف في اسم المعمارية
  /// فقط. أي معمارية أخرى تُبقي رابط arm64.
  String apkUrlFor(String? abi) => _builtAbis.contains(abi)
      ? directApkUrl.replaceFirst('arm64-v8a', abi!)
      : directApkUrl;

  /// رابط حزمة التحديث المناسبة للمنصة الحالية (أندرويد أو لينكس أو ويندوز).
  String packageUrlFor({String? abi, bool? isLinux, bool? isWindows}) =>
      (isWindows ?? Platform.isWindows)
          ? directWindowsUrl
          : (isLinux ?? Platform.isLinux)
          ? directLinuxUrl
          : apkUrlFor(abi);

  /// بصمة SHA-256 الاختيارية للحزمة المناسبة للمنصة الحالية، أو نص فارغ.
  String expectedSha256For({String? abi, bool? isLinux, bool? isWindows}) =>
      (isWindows ?? Platform.isWindows)
          ? windowsSha256
          : (isLinux ?? Platform.isLinux)
          ? linuxSha256
          // نفس اختيار apkUrlFor: معمارية بلا ملف خاص تنزّل ملف arm64.
          : apkSha256s[_builtAbis.contains(abi) ? abi : 'arm64-v8a'] ?? '';

  /// يتحقق مما إذا كان هذا التحديث أحدث من الإصدار المثبت حالياً.
  bool isNewerThan(int currentBuildNumber, String currentVersion) {
    if (buildNumber > currentBuildNumber) return true;
    return _compareSemver(latestVersion, currentVersion) > 0;
  }

  static int _compareSemver(String v1, String v2) {
    final clean1 = v1.replaceAll(RegExp(r'[^0-9.]'), '');
    final clean2 = v2.replaceAll(RegExp(r'[^0-9.]'), '');
    final p1 = clean1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final p2 = clean2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final len = math.max(p1.length, p2.length);
    for (int i = 0; i < len; i++) {
      final a = i < p1.length ? p1[i] : 0;
      final b = i < p2.length ? p2[i] : 0;
      if (a > b) return 1;
      if (a < b) return -1;
    }
    return 0;
  }
}
