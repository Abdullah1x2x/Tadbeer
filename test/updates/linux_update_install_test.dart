import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/features/updates/app_update_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_linux_update_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// يبني أرشيفاً بشكل حزمة الإصدار: مجلد `tadbeer/` فيه الملف التنفيذي و`lib` و`data`.
  Future<File> buildArchive(
    String marker, {
    bool withData = true,
    bool withLink = false,
  }) async {
    final src = Directory('${tempDir.path}/src_$marker/tadbeer')
      ..createSync(recursive: true);
    File('${src.path}/tadbeer').writeAsStringSync(marker);
    Directory('${src.path}/lib').createSync();
    if (withData) Directory('${src.path}/data').createSync();
    if (withLink) Link('${src.path}/lib/escape').createSync('/etc');
    final archive = File('${tempDir.path}/$marker.tar.gz');
    final result = await Process.run(
      'tar',
      ['-czf', archive.path, '-C', src.parent.path, 'tadbeer'],
    );
    expect(result.exitCode, 0, reason: '${result.stderr}');
    return archive;
  }

  Directory installedApp(String marker) {
    final dir = Directory('${tempDir.path}/opt/tadbeer')
      ..createSync(recursive: true);
    File('${dir.path}/tadbeer').writeAsStringSync(marker);
    return dir;
  }

  test('archive listing must stay inside tadbeer/', () {
    expect(
      AppUpdateService.isSafeLinuxArchiveListing(
        ['tadbeer/', 'tadbeer/tadbeer', 'tadbeer/lib/libapp.so'],
      ),
      isTrue,
    );
    expect(AppUpdateService.isSafeLinuxArchiveListing([]), isFalse);
    expect(
      AppUpdateService.isSafeLinuxArchiveListing(['tadbeer/../evil']),
      isFalse,
    );
    expect(
      AppUpdateService.isSafeLinuxArchiveListing(['/etc/passwd']),
      isFalse,
    );
    expect(
      AppUpdateService.isSafeLinuxArchiveListing(['other/tadbeer']),
      isFalse,
    );
  });

  test(
    'stages a valid archive next to the app without touching it',
    () async {
      final app = installedApp('old');
      final archive = await buildArchive('new');

      expect(
        await AppUpdateService.instance.stageLinuxUpdate(archive, app),
        isTrue,
      );
      expect(File('${app.path}/tadbeer').readAsStringSync(), 'old');
      expect(File('${app.path}.update/tadbeer').readAsStringSync(), 'new');
      expect(Directory('${app.path}.unpack').existsSync(), isFalse);
    },
    skip: !Platform.isLinux,
  );

  test(
    'rejects archives with symlinks or a missing data folder',
    () async {
      final app = installedApp('old');
      for (final archive in [
        await buildArchive('link', withLink: true),
        await buildArchive('nodata', withData: false),
      ]) {
        expect(
          await AppUpdateService.instance.stageLinuxUpdate(archive, app),
          isFalse,
        );
      }
      expect(Directory('${app.path}.update').existsSync(), isFalse);
      expect(Directory('${app.path}.unpack').existsSync(), isFalse);
    },
    skip: !Platform.isLinux,
  );

  test(
    'swap script replaces the app folder once the app has exited',
    () async {
      final app = installedApp('old');
      final staged = Directory('${app.path}.update')..createSync();
      File('${staged.path}/tadbeer').writeAsStringSync('new');

      final exited = await Process.start('true', []);
      await exited.exitCode;
      final result = await Process.run('sh', [
        '-c',
        AppUpdateService.linuxSwapScript,
        'tadbeer-update',
        '${exited.pid}',
        app.path,
        staged.path,
        '${app.path}.relaunch',
      ]);

      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(File('${app.path}/tadbeer').readAsStringSync(), 'new');
      expect(staged.existsSync(), isFalse);
      expect(Directory('${app.path}.old').existsSync(), isFalse);
    },
    skip: !Platform.isLinux,
  );
}
