import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/core/theme/theme.dart';
import 'package:tadbeer/core/design_system/app_icons.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/features/quran/screens/quran_page_view.dart';
import 'package:tadbeer/data/models/user_settings_model.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_page_rebuild_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
    await UserDataStore.instance.setMushafStyle(MushafStyle.text);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('a page shows a bookmark added to one of its ayahs', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: QuranPageView(pageNumber: 3)),
      ),
    );
    await tester.pump();
    expect(find.byIcon(AppIcons.bookmarkSimpleFill), findsNothing);

    // Saving the reading position touches nothing the page shows.
    await tester.runAsync(
      () => UserDataStore.instance.saveReadingPosition(
        page: 3,
        surahNumber: 2,
        ayahNumber: 6,
      ),
    );
    await tester.pump();
    expect(find.byIcon(AppIcons.bookmarkSimpleFill), findsNothing);

    await tester.runAsync(
      () => UserDataStore.instance.toggleBookmark(
        QuranRepository.instance.getAyah(2, 7)!,
      ),
    );
    await tester.pump();
    expect(find.byIcon(AppIcons.bookmarkSimpleFill), findsOneWidget);
  });
}
