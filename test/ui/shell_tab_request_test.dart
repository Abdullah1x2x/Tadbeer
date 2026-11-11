import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/app.dart';
import 'package:tadbeer/app/main_shell.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/features/quran/screens/quran_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_shell_req_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    // A returning user: the first-launch theme picker is behind them.
    await UserDataStore.instance.updateSettings(
      UserDataStore.instance.settings.copyWith(themeChosen: true),
    );
    await QuranRepository.instance.init();
    await UserDataStore.instance.updateSettings(
      UserDataStore.instance.settings.copyWith(
        hideTadbeerIntroPermanently: true,
      ),
    );
  });

  tearDown(() {
    MainShell.silentUpdateCheckForTesting = null;
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('a reminder tap request opens the Mushaf tab', (tester) async {
    await tester.pumpWidget(const TadbeerApp());
    await tester.pumpAndSettle();
    expect(MainShell.isMounted, isTrue);
    expect(find.byType(QuranScreen), findsNothing);

    MainShell.requestedTab.value = ShellTab.quran;
    await tester.pumpAndSettle();

    expect(find.byType(QuranScreen), findsOneWidget);
    expect(MainShell.requestedTab.value, isNull);
  });

  testWidgets('checks for updates on launch and when app resumes', (
    tester,
  ) async {
    var checks = 0;
    MainShell.silentUpdateCheckForTesting = (_) async {
      checks++;
    };

    await tester.pumpWidget(const TadbeerApp());
    await tester.pumpAndSettle();
    expect(checks, 0);

    // 3-second startup timer after welcome finishes.
    await tester.pump(const Duration(seconds: 3));
    expect(checks, 1);

    // Returning from background schedules another check after 1 second.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 1));
    expect(checks, 2);
  });
}
