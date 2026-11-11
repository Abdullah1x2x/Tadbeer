import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/features/updates/app_update_model.dart';
import 'package:tadbeer/features/updates/app_update_service.dart';

import '../../tool/release.dart';

void main() {
  group('the version is the same everywhere', () {
    final (version, build) = pubspecVersion(
      File('pubspec.yaml').readAsStringSync(),
    );

    test('the app knows the version it was built as', () {
      // A stale constant offers the update again after every update.
      expect(AppUpdateService.currentVersion, version);
      expect(AppUpdateService.currentBuildNumber, build);
    });

    test('both copies of version.json match each other and the build', () {
      final primary = File('version.json').readAsStringSync();
      expect(File('docs/version.json').readAsStringSync(), primary);
      final json = jsonDecode(primary) as Map<String, dynamic>;
      expect(json['latest_version'], version);
      expect(json['build_number'], build);
    });
  });

  group('apkUrlFor', () {
    final update = AppUpdateInfo.fromJson({
      'apk_url': 'https://example.org/v2/app-arm64-v8a-release.apk',
    });

    test('names the APK built for the device', () {
      expect(
        update.apkUrlFor('armeabi-v7a'),
        'https://example.org/v2/app-armeabi-v7a-release.apk',
      );
      expect(update.apkUrlFor('arm64-v8a'), update.directApkUrl);
    });

    test('keeps the arm64 link for an ABI no APK is built for', () {
      expect(update.apkUrlFor('x86_64'), update.directApkUrl);
      expect(update.apkUrlFor('x86'), update.directApkUrl);
      expect(update.apkUrlFor(null), update.directApkUrl);
    });
  });

  group('release tool', () {
    const changelog = '# سجل التغييرات\n\n'
        '$unreleasedHeading\n\n- إصلاح أول\n- إصلاح ثانٍ\n\n'
        '## 1.0.0 — 2026-11-10\n\n- قديم\n';

    test('closes the unreleased notes under the new version', () {
      final (cut, notes) = cutChangelog(changelog, '1.0.1', '2026-11-12');
      expect(notes, ['إصلاح أول', 'إصلاح ثانٍ']);
      expect(
        cut,
        contains('$unreleasedHeading\n\n## 1.0.1 — 2026-11-12\n\n- إصلاح أول'),
      );
      expect(cut, endsWith('## 1.0.0 — 2026-11-10\n\n- قديم\n'));
    });

    test('refuses a release with no notes', () {
      expect(
        () => cutChangelog('$unreleasedHeading\n\n## 1.0.0\n- قديم\n', '1.0.1', 'd'),
        throwsFormatException,
      );
      expect(() => cutChangelog('## 1.0.0\n', '1.0.1', 'd'), throwsFormatException);
    });

    test('writes the version into pubspec and the service', () {
      expect(
        pubspecVersion(setPubspecVersion('name: a\nversion: 1.0.0+1\n', '1.0.1', 2)),
        ('1.0.1', 2),
      );
      final service = setServiceVersion(
        File('lib/features/updates/app_update_service.dart').readAsStringSync(),
        '9.8.7',
        65,
      );
      expect(service, contains("currentVersion = '9.8.7'"));
      expect(service, contains('currentBuildNumber = 65'));
    });

    test('version.json lists the notes and the tagged APK', () {
      final json = versionJson('1.0.1', 2, '2026-11-12', ['أ', 'ب']);
      expect(json['changelog'], '• أ\n• ب');
      expect(
        AppUpdateInfo.fromJson(json).apkUrlFor('armeabi-v7a'),
        'https://github.com/Abdullah1x2x/Tadbeer/releases/download/v1.0.1/app-armeabi-v7a-release.apk',
      );
    });
  });
}
