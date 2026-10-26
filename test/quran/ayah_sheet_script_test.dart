import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/theme.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';
import 'package:tadbeer/features/quran/qcf/qcf_ayah_text.dart';
import 'package:tadbeer/features/quran/qcf/qcf_fonts.dart';
import 'package:tadbeer/features/quran/qcf/qcf_layout.dart';
import 'package:tadbeer/features/quran/widgets/ayah_action_sheet.dart';
import 'package:tadbeer/features/settings/user_settings_model.dart';

void main() {
  late Directory tempDir;

  // Loaded in real time: font loading does not finish under fake time.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await QcfLayout.instance.init();
    await QcfFonts.instance.ensurePage(50);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_ayah_sheet_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<void> pumpSheet(WidgetTester tester, int surah, int ayah) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: AyahActionSheet(
            ayah: QuranRepository.instance.getAyah(surah, ayah)!,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Font families the ayah box draws with.
  Set<String> familiesInBox(WidgetTester tester) {
    final rich = tester.widget<RichText>(
      find.descendant(
        of: find.byType(QcfAyahText),
        matching: find.byType(RichText),
      ),
    );
    final families = <String>{};
    rich.text.visitChildren((span) {
      if (span.style?.fontFamily case final family?) families.add(family);
      return true;
    });
    return families;
  }

  testWidgets('the ayah is shown in the Madinah script', (tester) async {
    await pumpSheet(tester, 3, 7);
    expect(familiesInBox(tester), {QcfFonts.familyFor(50)});
    expect(tester.takeException(), isNull);
  });

  testWidgets('the flowing text view keeps the reader\'s font', (tester) async {
    await tester.runAsync(
      () => UserDataStore.instance.setMushafStyle(MushafStyle.text),
    );
    await pumpSheet(tester, 3, 7);
    expect(find.byType(QcfAyahText), findsNothing);
    expect(find.textContaining('﴿'), findsOneWidget);
  });
}
