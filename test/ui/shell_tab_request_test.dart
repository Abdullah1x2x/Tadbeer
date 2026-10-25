import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/app.dart';
import 'package:tadbeer/app/main_shell.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';
import 'package:tadbeer/features/quran/screens/quran_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_shell_req_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
    await UserDataStore.instance.updateSettings(
      UserDataStore.instance.settings.copyWith(
        hideTadbeerIntroPermanently: true,
      ),
    );
  });

  tearDown(() {
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
}
