import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/features/updates/app_update_service.dart';

void main() {
  setUp(() {
    HttpOverrides.global = null;
  });

  test('AppUpdateService fetches live version.json and parses version metadata',
      () async {
    final updateInfo = await AppUpdateService.instance.fetchUpdateInfo();

    expect(updateInfo.latestVersion, isNotEmpty);
    expect(updateInfo.buildNumber, greaterThanOrEqualTo(1));
    expect(updateInfo.title, isNotEmpty);
    expect(updateInfo.changelog, isNotEmpty);
  });

  group('fetchUpdateInfo', () {
    test('falls back to secondary URL when primary fails', () async {
      final deadServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final deadPort = deadServer.port;
      await deadServer.close(force: true);

      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        request.response
          ..statusCode = HttpStatus.ok
          ..write(
            jsonEncode({
              'latest_version': '1.0.0',
              'build_number': 1,
              'release_date': '2026-11-11',
              'title': 'تحديث',
              'changelog': 'تحسينات',
            }),
          );
        await request.response.close();
      });

      final info = await AppUpdateService.instance.fetchUpdateInfo(
        urls: [
          'http://127.0.0.1:$deadPort/version.json',
          'http://127.0.0.1:${server.port}/version.json',
        ],
      );

      expect(info.latestVersion, '1.0.0');
      expect(info.buildNumber, 1);
    });

    test('throws when all update URLs fail or return non-200 status', () async {
      final deadServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final deadPort = deadServer.port;
      await deadServer.close(force: true);

      final errorServer =
          await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => errorServer.close(force: true));
      errorServer.listen((request) async {
        request.response.statusCode = HttpStatus.serviceUnavailable;
        await request.response.close();
      });

      await expectLater(
        AppUpdateService.instance.fetchUpdateInfo(
          urls: [
            'http://127.0.0.1:$deadPort/version.json',
            'http://127.0.0.1:${errorServer.port}/version.json',
          ],
        ),
        throwsA(isA<HttpException>()),
      );

      await expectLater(
        AppUpdateService.instance.fetchUpdateInfo(
          urls: ['http://127.0.0.1:$deadPort/version.json'],
        ),
        throwsA(isA<SocketException>()),
      );
    });
  });

  group('checkForUpdates', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('tadbeer_update_ui_');
      await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
      AppUpdateService.instance.downloadState.value =
          const UpdateDownloadState();
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<BuildContext> pumpHost(WidgetTester tester) async {
      late BuildContext captured;
      await tester.pumpWidget(
        AppLocalizationScope(
          currentLanguage: AppLanguage.arabic,
          strings: AppStrings(AppLanguage.arabic),
          onLanguageChanged: (_) {},
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  captured = context;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );
      return captured;
    }

    testWidgets('shows offline error SnackBar when unreachable', (
      tester,
    ) async {
      final deadServer = await tester.runAsync(
        () => HttpServer.bind(InternetAddress.loopbackIPv4, 0),
      );
      final deadPort = deadServer!.port;
      await tester.runAsync(() => deadServer.close(force: true));

      final context = await pumpHost(tester);
      final strings = AppStrings(AppLanguage.arabic);

      await tester.runAsync(
        () => AppUpdateService.instance.checkForUpdates(
          context,
          showFeedback: true,
          urls: ['http://127.0.0.1:$deadPort/version.json'],
        ),
      );
      await tester.pump();

      expect(find.text(strings.updateCheckFailed), findsOneWidget);
      expect(
        find.text(strings.usingLatestVersion(AppUpdateService.currentVersion)),
        findsNothing,
      );
    });

    testWidgets('shows latest version SnackBar when remote matches current', (
      tester,
    ) async {
      final server = await tester.runAsync(() async {
        final s = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        s.listen((request) async {
          request.response
            ..statusCode = HttpStatus.ok
            ..write(
              jsonEncode({
                'latest_version': AppUpdateService.currentVersion,
                'build_number': AppUpdateService.currentBuildNumber,
              }),
            );
          await request.response.close();
        });
        return s;
      });
      addTearDown(() => tester.runAsync(() => server!.close(force: true)));

      final context = await pumpHost(tester);
      final strings = AppStrings(AppLanguage.arabic);

      await tester.runAsync(
        () => AppUpdateService.instance.checkForUpdates(
          context,
          showFeedback: true,
          urls: ['http://127.0.0.1:${server!.port}/version.json'],
        ),
      );
      await tester.pump();

      expect(
        find.text(strings.usingLatestVersion(AppUpdateService.currentVersion)),
        findsOneWidget,
      );
      expect(find.text(strings.updateCheckFailed), findsNothing);
    });

    testWidgets('silent check stays silent when offline', (tester) async {
      final deadServer = await tester.runAsync(
        () => HttpServer.bind(InternetAddress.loopbackIPv4, 0),
      );
      final deadPort = deadServer!.port;
      await tester.runAsync(() => deadServer.close(force: true));

      final context = await pumpHost(tester);

      await tester.runAsync(
        () => AppUpdateService.instance.checkForUpdates(
          context,
          showFeedback: false,
          urls: ['http://127.0.0.1:$deadPort/version.json'],
        ),
      );
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('downloadApkFile', () {
    late HttpServer server;
    late Directory dir;
    late File target;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      dir = await Directory.systemTemp.createTemp('tadbeer_update_test');
      target = File('${dir.path}/update.apk');
    });

    tearDown(() async {
      await server.close(force: true);
      await dir.delete(recursive: true);
    });

    Stream<DownloadProgress> download() =>
        AppUpdateService.instance.downloadApkFile(
          url: 'http://127.0.0.1:${server.port}/update.apk',
          targetFile: target,
        );

    test('a complete download leaves only the final file', () async {
      server.listen((request) async {
        request.response.add(List.filled(4096, 7));
        await request.response.close();
      });

      await download().drain<void>();

      expect(await target.length(), 4096);
      expect(File('${target.path}.part').existsSync(), isFalse);
    });

    test('an interrupted download never creates the final file', () async {
      server.listen((request) async {
        request.response.contentLength = 4096;
        final socket = await request.response.detachSocket();
        socket.add(List.filled(1024, 7));
        await socket.flush();
        socket.destroy();
      });

      await expectLater(download().drain<void>(), throwsA(anything));

      expect(target.existsSync(), isFalse);
    });
  });
}
