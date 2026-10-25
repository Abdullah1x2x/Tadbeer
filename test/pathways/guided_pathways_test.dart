import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/theme.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/ayah_links/curated_pathways.dart';
import 'package:tadbeer/features/pathways/guided_pathways_screen.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_paths_test_');
    await UserDataStore.instance.init(
      File('${tempDir.path}/data.json'),
      '${tempDir.path}/user.db',
    );
    await QuranRepository.instance.init();
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('progress is saved and restored from a backup', () async {
    final store = UserDataStore.instance;
    await GuidedPathwayProgress.completeDay('names_of_allah', 0);
    await GuidedPathwayProgress.completeDay('names_of_allah', 1);
    final backup = store.exportSnapshot();

    await store.resetAllData();
    expect(GuidedPathwayProgress.completedDays('names_of_allah'), isEmpty);

    await store.replaceAllUserData(backup);
    expect(GuidedPathwayProgress.completedDays('names_of_allah'), {0, 1});
  });

  testWidgets('completing today unlocks the next day', (tester) async {
    final pathway = CuratedPathwaysRegistry.pathways.first;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: PathwayJourneyScreen(pathway: pathway),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('أتممت اليوم'), findsOneWidget);
    await tester.runAsync(
      () => GuidedPathwayProgress.completeDay(pathway.id, 0),
    );
    await tester.pumpAndSettle();

    expect(GuidedPathwayProgress.completedDays(pathway.id), {0});
    // Day 2 is now the open card.
    expect(find.text('أتممت اليوم'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
