import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/theme.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';
import 'package:tadbeer/features/share/ayah_share_sheet.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_share_test_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(body: Center(child: FittedBox(child: child))),
  );

  group('AyahCard', () {
    // Al-Baqarah 282 is the longest verse; it must still fit every format.
    for (final style in AyahCardStyle.values) {
      for (final height in [360.0, 640.0]) {
        testWidgets('fits the longest verse ($style, height $height)', (
          WidgetTester tester,
        ) async {
          final ayah = QuranRepository.instance.getAyah(2, 282)!;
          await tester.pumpWidget(
            host(
              AyahCard(ayah: ayah, style: style, width: 360, height: height),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.textContaining('سُورَةُ'), findsOneWidget);
          expect(find.text('تَدْبِير'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
