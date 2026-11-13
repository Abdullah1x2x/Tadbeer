import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/features/updates/app_update_model.dart';

void main() {
  group('AppUpdateInfo', () {
    test('parses complete json correctly', () {
      final json = {
        'latest_version': '1.2.0',
        'build_number': 15,
        'release_date': '2026-11-10',
        'is_mandatory': true,
        'title': 'تحديث هام',
        'changelog': 'إصلاحات وتحسينات هامة',
        'download_url':
            'https://github.com/Abdullah1x2x/Tadbeer/releases/tag/v1.2.0',
        'telegram_url': 'https://t.me/tadbeerapp/42',
      };

      final info = AppUpdateInfo.fromJson(json);

      expect(info.latestVersion, '1.2.0');
      expect(info.buildNumber, 15);
      expect(info.releaseDate, '2026-11-10');
      expect(info.isMandatory, isTrue);
      expect(info.title, 'تحديث هام');
      expect(info.changelog, 'إصلاحات وتحسينات هامة');
      expect(
        info.downloadUrl,
        'https://github.com/Abdullah1x2x/Tadbeer/releases/tag/v1.2.0',
      );
      expect(info.telegramUrl, 'https://t.me/tadbeerapp/42');
    });

    test('parses linux_url, platforms.linux fallback, and sha256 hashes', () {
      final flat = AppUpdateInfo.fromJson({
        'latest_version': '1.2.0',
        'linux_url': 'https://example.org/tadbeer-linux-x64.tar.gz',
        'linux_sha256': 'abc123',
        'apk_sha256s': {'arm64-v8a': 'def456', 'armeabi-v7a': 'v7hash'},
      });
      expect(
        flat.directLinuxUrl,
        'https://example.org/tadbeer-linux-x64.tar.gz',
      );
      expect(flat.expectedSha256For(isLinux: true), 'abc123');
      expect(
        flat.expectedSha256For(abi: 'arm64-v8a', isLinux: false),
        'def456',
      );
      expect(
        flat.expectedSha256For(abi: 'armeabi-v7a', isLinux: false),
        'v7hash',
      );
      // Same fallback as apkUrlFor: an unbuilt ABI downloads the arm64 file.
      expect(flat.expectedSha256For(abi: 'x86_64', isLinux: false), 'def456');
      expect(flat.expectedSha256For(isLinux: false), 'def456');

      final nested = AppUpdateInfo.fromJson({
        'platforms': {
          'linux': {
            'url': 'https://example.org/nested.tar.gz',
            'sha256': 'nestedhash',
          },
        },
      });
      expect(nested.directLinuxUrl, 'https://example.org/nested.tar.gz');
      expect(nested.expectedSha256For(isLinux: true), 'nestedhash');
    });

    test('falls back to safe defaults when keys are missing or null', () {
      final info = AppUpdateInfo.fromJson({});

      expect(info.latestVersion, '1.0.0');
      expect(info.buildNumber, 1);
      expect(info.releaseDate, '');
      expect(info.isMandatory, isFalse);
      expect(info.title, 'تحديث جديد');
      expect(info.changelog, '');
      expect(info.downloadUrl, contains('github.com'));
      expect(info.telegramUrl, 'https://t.me/tadbeerapp');
      expect(
        info.directLinuxUrl,
        'https://github.com/Abdullah1x2x/Tadbeer/releases/download/v1.0.0/Tadbeer-1.0.0-linux-x64.tar.gz',
      );
      expect(
        info.directApkUrl,
        endsWith('/v1.0.0/Tadbeer-1.0.0-android-arm64.apk'),
      );
      expect(
        info.directWindowsUrl,
        endsWith('/v1.0.0/Tadbeer-1.0.0-windows-x64.zip'),
      );
    });

    group('isNewerThan', () {
      test('returns true when remote build number is greater', () {
        final update = AppUpdateInfo.fromJson({
          'latest_version': '1.0.0',
          'build_number': 5,
        });

        expect(update.isNewerThan(4, '1.0.0'), isTrue);
      });

      test('returns false when remote build number is smaller', () {
        final update = AppUpdateInfo.fromJson({
          'latest_version': '1.0.0',
          'build_number': 3,
        });

        expect(update.isNewerThan(4, '1.0.0'), isFalse);
      });

      test('compares semantic version when build numbers are equal', () {
        final updatePatch = AppUpdateInfo.fromJson({
          'latest_version': '1.0.1',
          'build_number': 10,
        });
        expect(updatePatch.isNewerThan(10, '1.0.0'), isTrue);

        final updateMinor = AppUpdateInfo.fromJson({
          'latest_version': '1.1.0',
          'build_number': 10,
        });
        expect(updateMinor.isNewerThan(10, '1.0.9'), isTrue);

        final updateMajor = AppUpdateInfo.fromJson({
          'latest_version': '2.0.0',
          'build_number': 10,
        });
        expect(updateMajor.isNewerThan(10, '1.9.9'), isTrue);

        final updateSame = AppUpdateInfo.fromJson({
          'latest_version': '1.0.0',
          'build_number': 10,
        });
        expect(updateSame.isNewerThan(10, '1.0.0'), isFalse);

        final updateOlder = AppUpdateInfo.fromJson({
          'latest_version': '0.9.9',
          'build_number': 10,
        });
        expect(updateOlder.isNewerThan(10, '1.0.0'), isFalse);
      });
    });
  });
}
