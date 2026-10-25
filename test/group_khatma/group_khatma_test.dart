import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/app/theme.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/group_khatma/group_khatma.dart';
import 'package:tadbeer/features/group_khatma/group_khatma_screen.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';

void main() {
  group('GroupKhatma', () {
    test('splits the 30 juz evenly and in order', () {
      final k = GroupKhatma.create('عائلة', ['أ', 'ب', 'ج', 'د']);
      expect(k.juzOf(0), [1, 2, 3, 4, 5, 6, 7, 8]);
      expect(k.juzOf(1), [9, 10, 11, 12, 13, 14, 15, 16]);
      expect(k.juzOf(2).length, 7);
      expect(k.juzOf(3), [24, 25, 26, 27, 28, 29, 30]);
    });

    test('round-trips through the share code', () {
      final k = GroupKhatma.create('ختمة رمضان', ['محمد', 'فاطمة']);
      final joined = GroupKhatma.fromCode(k.shareCode)!;
      expect(joined.title, 'ختمة رمضان');
      expect(joined.names, ['محمد', 'فاطمة']);
      expect(joined.juzOf(1), k.juzOf(1));
    });

    test('rejects broken codes', () {
      expect(GroupKhatma.fromCode('not a code'), isNull);
      expect(GroupKhatma.fromCode(''), isNull);
    });
  });

  group('GroupKhatmaScreen', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('tadbeer_group_test_');
      await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
      await QuranRepository.instance.init();
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    testWidgets('join with a code, pick a name, mark a juz done', (
      tester,
    ) async {
      final code = GroupKhatma.create('ختمة', ['محمد', 'فاطمة']).shareCode;
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        AppLocalizationScope(
          currentLanguage: AppLanguage.arabic,
          strings: const AppStrings(AppLanguage.arabic),
          onLanguageChanged: (_) {},
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const GroupKhatmaScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, code);
      await tester.runAsync(() async {
        await tester.tap(find.text('انضم'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(find.text('اختر اسمك'), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.text('فاطمة'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(find.text('الجزء ١٦'), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.byType(Checkbox).first);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(GroupKhatmaStore.current()!.done, {16});
      expect(tester.takeException(), isNull);
    });
  });
}
