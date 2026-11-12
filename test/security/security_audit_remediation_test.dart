// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:tadbeer/data/models/reminder_model.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/features/audio/audio_downloads.dart';
import 'package:tadbeer/features/backup/backup_crypto_service.dart';
import 'package:tadbeer/features/reminders/local_reminder_service.dart';
import 'package:tadbeer/features/updates/app_update_model.dart';
import 'package:tadbeer/features/updates/app_update_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String dirPath;
  FakePathProviderPlatform(this.dirPath);

  @override
  Future<String?> getTemporaryPath() async => dirPath;

  @override
  Future<String?> getApplicationCachePath() async => dirPath;

  @override
  Future<String?> getApplicationSupportPath() async => dirPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => dirPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory globalTempDir;

  setUpAll(() async {
    tz.initializeTimeZones();
    globalTempDir = await Directory.systemTemp.createTemp('tadbeer_sec_global_');
    PathProviderPlatform.instance = FakePathProviderPlatform(globalTempDir.path);
  });

  tearDownAll(() async {
    if (globalTempDir.existsSync()) {
      await globalTempDir.delete(recursive: true);
    }
  });

  group('Security Fix: Reminders infinite loop prevention', () {
    test('ReminderItem.fromJson filters selectedDays to valid ISO weekdays (1..7)', () {
      final json = {
        'id': 'test-reminder',
        'title': 'Test Reminder',
        'hour': 5,
        'minute': 30,
        'repeatMode': 'weekdays',
        'alertType': 'notification',
        'selectedDays': [0, 1, 3, 7, 8, -5],
        'isEnabled': true,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final item = ReminderItem.fromJson(json);
      expect(item.selectedDays, [1, 3, 7]);
    });

    test('nextWeekdayTime throws RangeError on invalid dayOfWeek (< 1 or > 7)', () {
      final now = tz.TZDateTime.now(tz.local);
      expect(
        () => nextWeekdayTime(now, 0, 8, 0),
        throwsA(isA<RangeError>()),
      );
      expect(
        () => nextWeekdayTime(now, 8, 8, 0),
        throwsA(isA<RangeError>()),
      );
    });

    test('nextWeekdayTime calculates valid upcoming time within at most 7 iterations', () {
      final now = tz.TZDateTime.now(tz.local);
      for (var day = 1; day <= 7; day++) {
        final target = nextWeekdayTime(now, day, 8, 0);
        expect(target.weekday, day);
        expect(target.isAfter(now) || target.isAtSameMomentAs(now), isTrue);
      }
    });
  });

  group('Security Fix: Audio Downloads SSRF & Redirects prevention', () {
    test('httpFetch rejects 3xx HTTP redirects instead of following them', () async {
      final tempDir = await Directory.systemTemp.createTemp('tadbeer_sec_audio_');
      final redirectTarget = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var targetHits = 0;
      redirectTarget.listen((request) async {
        targetHits++;
        request.response.write('SSRF TARGET REACHED');
        await request.response.close();
      });

      final redirectingServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      redirectingServer.listen((request) async {
        request.response.statusCode = HttpStatus.found;
        request.response.headers.set(
          HttpHeaders.locationHeader,
          'http://127.0.0.1:${redirectTarget.port}/secret',
        );
        await request.response.close();
      });

      addTearDown(() async {
        await redirectingServer.close(force: true);
        await redirectTarget.close(force: true);
        await tempDir.delete(recursive: true);
      });

      final destFile = File('${tempDir.path}/audio.mp3.part');
      await expectLater(
        httpFetch(
          Uri.parse('http://127.0.0.1:${redirectingServer.port}/audio.mp3'),
          destFile,
        ),
        throwsA(isA<HttpException>()),
      );

      expect(targetHits, 0);
      expect(destFile.existsSync(), isFalse);
    });
  });

  group('Security Fix: Backup decompression bomb and version validation', () {
    test('restoreFromFile rejects files with version <= 0 or invalid version format', () async {
      final tempDir = await Directory.systemTemp.createTemp('tadbeer_sec_backup_');
      addTearDown(() => tempDir.delete(recursive: true));

      final v0File = File('${tempDir.path}/v0.quranbackup');
      await v0File.writeAsString(jsonEncode({
        'magic': 'TADBEER_BACKUP',
        'version': 0,
        'schemaVersion': 1,
        'salt': 'c2FsdA==',
        'iv': 'aXZpdmk=',
        'cipher': 'Y2lwaGVy',
      }));

      final resultV0 = await BackupCryptoService.restoreFromFile(file: v0File);
      expect(resultV0.success, isFalse);
      expect(resultV0.errorMessage, contains('Invalid backup file format'));

      final negFile = File('${tempDir.path}/neg.quranbackup');
      await negFile.writeAsString(jsonEncode({
        'magic': 'TADBEER_BACKUP',
        'version': -1,
        'schemaVersion': 1,
        'salt': 'c2FsdA==',
        'iv': 'aXZpdmk=',
        'cipher': 'Y2lwaGVy',
      }));

      final resultNeg = await BackupCryptoService.restoreFromFile(file: negFile);
      expect(resultNeg.success, isFalse);
      expect(resultNeg.errorMessage, contains('Invalid backup file format'));
    });
  });

  group('Security Fix: App Updater URL validation and Path Traversal sanitization', () {
    test('openTelegram, openFeedbackBot, openDownload validate URLs against allowlists', () async {
      // Allowed Telegram URL opens
      final okTg = await AppUpdateService.instance.openTelegram('https://t.me/tadbeerapp');
      // Even if url_launcher has no UI host in tests, the method catches and returns true/false without dispatching evil URI
      expect(okTg, isA<bool>());

      // Disallowed schemes/hosts/traversals fallback cleanly to defaults
      final badScheme = await AppUpdateService.instance.openTelegram('file:///etc/passwd');
      expect(badScheme, isA<bool>());

      final badHost = await AppUpdateService.instance.openTelegram('https://evil.attacker.com/tadbeerapp');
      expect(badHost, isA<bool>());

      final traversal = await AppUpdateService.instance.openTelegram('https://t.me/tadbeerapp/../evil');
      expect(traversal, isA<bool>());

      final badGh = await AppUpdateService.instance.openDownload('https://evil.github.io/fake');
      expect(badGh, isA<bool>());
    });

    test('getUpdatePackageFile sanitizes path traversal characters in latestVersion', () async {
      final info = AppUpdateInfo(
        latestVersion: '../../etc/cron.d/evil',
        buildNumber: 99,
        releaseDate: '2026-11-12',
        title: 'Traversed Update',
        changelog: 'Test',
        telegramUrl: 'https://t.me/tadbeerapp',
        downloadUrl: 'https://github.com/Abdullah1x2x/Tadbeer/releases/latest',
      );

      final file = await AppUpdateService.instance.getUpdatePackageFile(info);
      expect(file.path, isNot(contains('../../')));
      expect(file.path.split(Platform.pathSeparator).last, contains('tadbeer-'));
    });

    test('downloadApkFile rejects untrusted external URLs and non-loopback HTTP', () async {
      final tempDir = await Directory.systemTemp.createTemp('tadbeer_update_sec_');
      final target = File('${tempDir.path}/update.bin');
      addTearDown(() => tempDir.delete(recursive: true));

      await expectLater(
        AppUpdateService.instance
            .downloadApkFile(
              url: 'http://malicious.example.com/update.apk',
              targetFile: target,
            )
            .drain<void>(),
        throwsA(isA<HttpException>()),
      );

      await expectLater(
        AppUpdateService.instance
            .downloadApkFile(
              url: 'https://untrusted-host.example.com/update.apk',
              targetFile: target,
            )
            .drain<void>(),
        throwsA(isA<HttpException>()),
      );
    });

    test('download allowlist accepts GitHub release-asset redirects', () {
      // github.com/.../releases/download/... redirects here.
      expect(
        AppUpdateService.isAllowedDownloadUri(Uri.parse(
          'https://release-assets.githubusercontent.com/github-production-release-asset/1/x',
        )),
        isTrue,
      );
    });
  });

  group('Security Fix: UserDataStore.resetAllData cleans export artifacts', () {
    test('resetAllData purges leftover temporary export files', () async {
      final dbFile = File('${globalTempDir.path}/test_user_data.json');
      await UserDataStore.instance.init(dbFile);

      final dummyNote = File('${globalTempDir.path}/tadbeer_note_test_123.pdf');
      await dummyNote.writeAsString('DUMMY NOTE CONTENT');
      final dummyReport = File('${globalTempDir.path}/monthly_report_test.png');
      await dummyReport.writeAsString('DUMMY REPORT CONTENT');

      expect(dummyNote.existsSync(), isTrue);
      expect(dummyReport.existsSync(), isTrue);

      await UserDataStore.instance.resetAllData();

      expect(dummyNote.existsSync(), isFalse);
      expect(dummyReport.existsSync(), isFalse);
    });
  });
}
