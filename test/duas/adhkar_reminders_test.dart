import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/features/duas/data/adhkar_reminders.dart';
import 'package:tadbeer/features/duas/data/adhkar_repository.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_adhkar_rem_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('enabling twice keeps one reminder; disabling removes it', () async {
    await AdhkarReminders.enable(
      AdhkarCategory.morning,
      const TimeOfDay(hour: 6, minute: 0),
      'أذكار الصباح',
    );
    await AdhkarReminders.enable(
      AdhkarCategory.morning,
      const TimeOfDay(hour: 5, minute: 30),
      'أذكار الصباح',
    );

    final morning = AdhkarReminders.reminderFor(AdhkarCategory.morning);
    expect(morning?.hour, 5);
    expect(
      UserDataStore.instance.reminders.where((r) => r.id == 'adhkar_morning'),
      hasLength(1),
    );
    expect(AdhkarReminders.reminderFor(AdhkarCategory.evening), isNull);

    await AdhkarReminders.disable(AdhkarCategory.morning);
    expect(AdhkarReminders.reminderFor(AdhkarCategory.morning), isNull);
  });

  testWidgets('switching a reminder on starts at the default time', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      AppLocalizationScope(
        currentLanguage: AppLanguage.arabic,
        strings: const AppStrings(AppLanguage.arabic),
        onLanguageChanged: (_) {},
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (c) {
                context = c;
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
    AdhkarReminders.showSettingsSheet(context).ignore();
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    expect(find.byType(TimePickerDialog), findsNothing);
    final morning = AdhkarReminders.reminderFor(AdhkarCategory.morning);
    expect(morning?.hour, 6);
    expect(morning?.minute, 0);
    expect(AdhkarReminders.reminderFor(AdhkarCategory.evening), isNull);
  });
}
