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
}
