import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/theme.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/journey/mushaf_map_screen.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_map_test_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('pages take the strongest activity on them', () async {
    final store = UserDataStore.instance;
    await store.recordPageRead(3);
    await store.recordPageRead(2);
    // Al-Baqarah 2 is on page 2: saving it upgrades that page.
    await store.toggleBookmark(QuranRepository.instance.getAyah(2, 2)!);

    final levels = computePageActivity(store);
    expect(levels[0], PageActivity.none);
    expect(levels[1], PageActivity.marked);
    expect(levels[2], PageActivity.read);
  });

  testWidgets('renders the map and an empty reflection log', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const MushafMapScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.text('خريطة المصحف'), findsOneWidget);

    await tester.tap(find.text('سجل التدبر'));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد وقفات تدبر بعد'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
