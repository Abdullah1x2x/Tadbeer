import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/core/services/local_reminder_service.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/reminders/reminder_model.dart';
import 'package:tadbeer/features/reminders/reminders_screen.dart';
import 'package:tadbeer/core/design_system/app_icons.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return AppLocalizationScope(
      currentLanguage: AppLanguage.arabic,
      strings: const AppStrings(AppLanguage.arabic),
      onLanguageChanged: (_) {},
      child: MaterialApp(
        home: Directionality(textDirection: TextDirection.rtl, child: child),
      ),
    );
  }

  setUp(() async {
    await UserDataStore.instance.resetAllData();
  });

  group('Reminders & Notification System Tests', () {
    test('One-time reminder is detected as fired once its moment passed', () {
      final base = ReminderItem(
        id: 'once-1',
        title: 'مرة واحدة',
        hour: 6,
        minute: 0,
        repeatMode: ReminderRepeatMode.once,
        createdAt: DateTime(2026, 1, 1),
      );
      final now = DateTime(2026, 5, 10, 12);

      // Never scheduled yet -> not fired.
      expect(base.hasOnceReminderFired(now), isFalse);

      final scheduledPast = base.copyWith(
        scheduledFor: DateTime(2026, 5, 10, 6),
      );
      expect(scheduledPast.hasOnceReminderFired(now), isTrue);

      final scheduledFuture = base.copyWith(
        scheduledFor: DateTime(2026, 5, 11, 6),
      );
      expect(scheduledFuture.hasOnceReminderFired(now), isFalse);

      // scheduledFor survives JSON round-trip.
      final restored = ReminderItem.fromJson(scheduledPast.toJson());
      expect(restored.scheduledFor, DateTime(2026, 5, 10, 6));

      // Disabling keeps the target; re-enabling or editing the time clears it
      // so a fresh date gets scheduled.
      expect(
        scheduledPast.copyWith(isEnabled: false).scheduledFor,
        isNotNull,
      );
      expect(scheduledPast.copyWith(isEnabled: true).scheduledFor, isNull);
      expect(scheduledPast.copyWith(hour: 7).scheduledFor, isNull);

      // Repeating reminders never count as "fired".
      final daily = scheduledPast.copyWith(
        repeatMode: ReminderRepeatMode.daily,
        scheduledFor: DateTime(2026, 5, 10, 6),
      );
      expect(daily.hasOnceReminderFired(now), isFalse);
    });

    test(
      'ReminderItem serializes and deserializes all repeat modes and alert types',
      () {
        final item = ReminderItem(
          id: 'rem-1',
          title: 'ورد الفجر',
          hour: 5,
          minute: 30,
          repeatMode: ReminderRepeatMode.weekdays,
          alertType: ReminderAlertType.alarm,
          selectedDays: const [1, 4, 5],
          isEnabled: true,
          createdAt: DateTime(2026, 1, 1),
        );

        final json = item.toJson();
        final restored = ReminderItem.fromJson(json);

        expect(restored.id, 'rem-1');
        expect(restored.title, 'ورد الفجر');
        expect(restored.hour, 5);
        expect(restored.minute, 30);
        expect(restored.repeatMode, ReminderRepeatMode.weekdays);
        expect(restored.alertType, ReminderAlertType.alarm);
        expect(restored.selectedDays, [1, 4, 5]);
        expect(restored.isEnabled, isTrue);
        expect(restored.formattedTime, '٠٥:٣٠ ص');
        expect(ReminderItem.formatTime12Hour(0, 0), '١٢:٠٠ ص');
        expect(ReminderItem.formatTime12Hour(12, 0), '١٢:٠٠ م');
        expect(ReminderItem.formatTime12Hour(13, 5), '٠١:٠٥ م');
      },
    );

    testWidgets(
      'RemindersScreen supports choosing between Notification and Alarm modes',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(const RemindersScreen()));
        await tester.pumpAndSettle();

        // Initially empty state is shown
        expect(find.text('لا توجد تنبيهات قراءة مضافة'), findsOneWidget);

        // Tap Test Notification menu in AppBar and choose standard notification
        final testBtn = find.byIcon(AppIcons.bellRinging);
        expect(testBtn, findsOneWidget);
        await tester.tap(testBtn);
        await tester.pumpAndSettle();
        expect(find.text('تجربة إشعار الآن'), findsOneWidget);
        expect(find.text('تجربة منبه الآن'), findsOneWidget);

        await tester.tap(find.text('تجربة إشعار الآن'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('تم إرسال إشعار تجريبي الآن'),
          findsOneWidget,
        );

        // Tap Add Reminder FAB
        await tester.tap(find.byIcon(AppIcons.alarm));
        await tester.pumpAndSettle();

        // Verify both alert type options exist in dialog
        expect(find.text('إشعار'), findsOneWidget);
        expect(find.text('منبه'), findsOneWidget);

        // Select Alarm mode (منبه)
        await tester.tap(find.text('منبه'));
        await tester.pumpAndSettle();

        // Enter reminder title and save
        final titleField = find.byType(TextField).last;
        await tester.enterText(titleField, 'ورد السحر');
        await tester.tap(find.text('حفظ'));
        await tester.pumpAndSettle();

        // Verify reminder is stored as Alarm and rendered with منبه badge
        expect(UserDataStore.instance.reminders.length, 1);
        expect(
          UserDataStore.instance.reminders.first.alertType,
          ReminderAlertType.alarm,
        );
        expect(find.text('ورد السحر'), findsOneWidget);
        expect(find.textContaining('منبه •'), findsOneWidget);

        // Toggle switch off
        final switchFinder = find.byType(Switch);
        expect(switchFinder, findsOneWidget);
        await tester.tap(switchFinder);
        await tester.pumpAndSettle();
        expect(UserDataStore.instance.reminders.first.isEnabled, isFalse);

        // Sync all reminders without throwing
        await LocalReminderService.instance.syncAllReminders(
          UserDataStore.instance.reminders,
        );
      },
    );
  });
}
