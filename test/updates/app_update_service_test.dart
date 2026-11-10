import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/features/updates/app_update_service.dart';

void main() {
  setUp(() {
    HttpOverrides.global = null;
  });
  test('AppUpdateService fetches live version.json and parses version metadata',
      () async {
    final updateInfo = await AppUpdateService.instance.fetchUpdateInfo();

    expect(updateInfo, isNotNull);
    expect(updateInfo!.latestVersion, isNotEmpty);
    expect(updateInfo.buildNumber, greaterThanOrEqualTo(1));
    expect(updateInfo.title, isNotEmpty);
    expect(updateInfo.changelog, isNotEmpty);
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
