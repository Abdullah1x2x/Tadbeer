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
    this.isMandatory = false,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
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
    'is_mandatory': isMandatory,
  };

  /// الرابط المباشر لملف الـ APK للتنزيل والتثبيت الفوري.
  String get directApkUrl {
    if (apkUrl.isNotEmpty) return apkUrl;
    if (downloadUrl.endsWith('.apk')) return downloadUrl;
    return 'https://github.com/Abdullah1x2x/Tadbeer/releases/latest/download/app-arm64-v8a-release.apk';
  }

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
