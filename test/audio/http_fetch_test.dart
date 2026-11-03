import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/features/audio/audio_downloads.dart';

void main() {
  test('a server that stops sending fails the download', () async {
    final tempDir = await Directory.systemTemp.createTemp('tadbeer_fetch_');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response.write('start');
      await request.response.flush(); // then silence
    });
    addTearDown(() async {
      await server.close(force: true);
      await tempDir.delete(recursive: true);
    });

    await expectLater(
      httpFetch(
        Uri.parse('http://127.0.0.1:${server.port}/a.mp3'),
        File('${tempDir.path}/a.mp3.part'),
        stall: const Duration(milliseconds: 100),
      ),
      throwsA(isA<TimeoutException>()),
    );
  });
}
