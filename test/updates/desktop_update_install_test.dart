import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/features/updates/app_update_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_desktop_update_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// يبني أرشيفاً بشكل حزمة الإصدار: مجلد `tadbeer/` فيه الملف التنفيذي و`lib` و`data`.
  Future<File> buildArchive(
    String marker, {
    bool withData = true,
    bool withLink = false,
    bool windows = false,
  }) async {
    final src = Directory('${tempDir.path}/src_$marker/tadbeer')
      ..createSync(recursive: true);
    File('${src.path}/tadbeer${windows ? '.exe' : ''}')
        .writeAsStringSync(marker);
    if (!windows) Directory('${src.path}/lib').createSync();
    if (withData) Directory('${src.path}/data').createSync();
    if (withLink) Link('${src.path}/lib/escape').createSync('/etc');
    final archive = File('${tempDir.path}/$marker.tar.gz');
    final result = await Process.run('tar', [
      '-czf',
      archive.path,
      '-C',
      src.parent.path,
      'tadbeer',
    ]);
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
      AppUpdateService.isSafeUpdateArchiveListing([
        'tadbeer/',
        'tadbeer/tadbeer',
        'tadbeer/lib/libapp.so',
      ]),
      isTrue,
    );
    expect(AppUpdateService.isSafeUpdateArchiveListing([]), isFalse);
    expect(
      AppUpdateService.isSafeUpdateArchiveListing(['tadbeer/../evil']),
      isFalse,
    );
    expect(
      AppUpdateService.isSafeUpdateArchiveListing(['/etc/passwd']),
      isFalse,
    );
    expect(
      AppUpdateService.isSafeUpdateArchiveListing(['other/tadbeer']),
      isFalse,
    );
    expect(
      AppUpdateService.isSafeUpdateArchiveListing(['C:/Windows/evil.dll']),
      isFalse,
    );
    expect(
      AppUpdateService.isSafeUpdateArchiveListing(['tadbeer\\..\\evil']),
      isFalse,
    );
  });

  test('stages a valid archive next to the app without touching it', () async {
    final app = installedApp('old');
    final archive = await buildArchive('new');

    expect(
      await AppUpdateService.instance.stageDesktopUpdate(archive, app),
      isTrue,
    );
    expect(File('${app.path}/tadbeer').readAsStringSync(), 'old');
    expect(File('${app.path}.update/tadbeer').readAsStringSync(), 'new');
    expect(Directory('${app.path}.unpack').existsSync(), isFalse);
  }, skip: !Platform.isLinux);

  test('a Windows bundle needs tadbeer.exe, not the Linux layout', () async {
    final app = installedApp('old');
    final service = AppUpdateService.instance;
    final windowsArchive = await buildArchive('win', windows: true);
    final linuxArchive = await buildArchive('lin');

    expect(
      await service.stageDesktopUpdate(linuxArchive, app, isWindows: true),
      isFalse,
    );
    expect(
      await service.stageDesktopUpdate(windowsArchive, app, isWindows: true),
      isTrue,
    );
    expect(File('${app.path}.update/tadbeer.exe').readAsStringSync(), 'win');
  }, skip: !Platform.isLinux);

  test('rejects archives with symlinks or a missing data folder', () async {
    final app = installedApp('old');
    for (final archive in [
      await buildArchive('link', withLink: true),
      await buildArchive('nodata', withData: false),
    ]) {
      expect(
        await AppUpdateService.instance.stageDesktopUpdate(archive, app),
        isFalse,
      );
    }
    expect(Directory('${app.path}.update').existsSync(), isFalse);
    expect(Directory('${app.path}.unpack').existsSync(), isFalse);
  }, skip: !Platform.isLinux);

  test('swap script replaces the app folder once the app has exited', () async {
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
  }, skip: !Platform.isLinux);
}
