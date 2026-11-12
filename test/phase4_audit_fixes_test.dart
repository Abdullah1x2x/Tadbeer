import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/features/updates/app_update_dialog.dart';
import 'package:tadbeer/features/updates/app_update_model.dart';
import 'package:tadbeer/features/updates/app_update_service.dart';
import 'package:tadbeer/features/widgets/home_widget_sync.dart';

void main() {
  setUp(() {
    HttpOverrides.global = null;
  });

  group('Phase 4 Audit Fixes', () {
    tearDown(() {
      AppUpdateService.instance.cancelDownload();
    });

    testWidgets(
      'mandatory update dialog hides dismiss action and blocks PopScope',
      (tester) async {
        AppUpdateService.instance.downloadState.value =
            const UpdateDownloadState();

        const mandatoryUpdate = AppUpdateInfo(
          latestVersion: '2.0.0',
          buildNumber: 2,
          releaseDate: '2026-11-12',
          title: 'تحديث إجباري',
          changelog: '• إصلاح أمني',
          telegramUrl: 'https://t.me/tadbeerapp',
          downloadUrl:
              'https://github.com/Abdullah1x2x/Tadbeer/releases/tag/v2.0.0',
          linuxUrl:
              'https://github.com/Abdullah1x2x/Tadbeer/releases/download/v2.0.0/tadbeer-linux-x64.tar.gz',
          isMandatory: true,
        );

        await tester.pumpWidget(
          AppLocalizationScope(
            currentLanguage: AppLanguage.arabic,
            strings: AppStrings(AppLanguage.arabic),
            onLanguageChanged: (_) {},
            child: const MaterialApp(
              home: Scaffold(
                body: AppUpdateDialog(update: mandatoryUpdate),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final popScope = tester.widget<PopScope>(find.byType(PopScope));
        expect(popScope.canPop, isFalse);
        expect(
          find.text(AppStrings(AppLanguage.arabic).permissionsLater),
          findsNothing,
        );
      },
    );

    test('downloadApkFile succeeds when sha256 matches', () async {
      final bytes = List<int>.generate(256, (i) => i % 251);
      final expectedHash = sha256.convert(bytes).toString();

      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        request.response.contentLength = bytes.length;
        request.response.add(bytes);
        await request.response.close();
      });

      final dir = await Directory.systemTemp.createTemp('tadbeer_sha_ok_');
      addTearDown(() => dir.delete(recursive: true));
      final target = File('${dir.path}/tadbeer-linux-x64.tar.gz');

      await AppUpdateService.instance
          .downloadApkFile(
            url: 'http://127.0.0.1:${server.port}/tadbeer-linux-x64.tar.gz',
            targetFile: target,
            expectedSha256: expectedHash,
          )
          .drain<void>();

      expect(await target.exists(), isTrue);
      expect(await target.readAsBytes(), bytes);
      expect(File('${target.path}.part').existsSync(), isFalse);
    });

    test('HomeWidgetSync updates cleanly across non-widget hosts', () async {
      final dir = await Directory.systemTemp.createTemp('tadbeer_widget_p4_');
      addTearDown(() => dir.delete(recursive: true));
      await UserDataStore.instance.init(File('${dir.path}/data.json'));
      await QuranRepository.instance.init();
      await expectLater(HomeWidgetSync.update(), completes);
    });
  });
}
