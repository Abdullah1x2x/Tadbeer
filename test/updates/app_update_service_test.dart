import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/features/updates/app_update_service.dart';

void main() {
  setUp(() {
    HttpOverrides.global = null;
  });
  test('AppUpdateService fetches live version.json from GitHub and detects v1.0.1',
      () async {
    final updateInfo = await AppUpdateService.instance.fetchUpdateInfo();

    expect(updateInfo, isNotNull);
    expect(updateInfo!.latestVersion, '1.0.1');
    expect(updateInfo.buildNumber, 2);
    expect(
      updateInfo.isNewerThan(
        AppUpdateService.currentBuildNumber,
        AppUpdateService.currentVersion,
      ),
      isTrue,
    );
  });
}
