import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/localization.dart';
import '../../reminders/local_reminder_service.dart';
import '../../../data/storage/user_data_store.dart';
import '../../../data/models/reminder_model.dart';
import 'adhkar_repository.dart';
import '../../../core/design_system/app_icons.dart';

/// تذكيرات أذكار الصباح والمساء: تنبيه يومي يفتح الأذكار مباشرة.
class AdhkarReminders {
  AdhkarReminders._();

  /// معرّف ثابت، وحمولة الإشعار هي المعرّف نفسه، فيفتح النقر الأذكار المطابقة
  /// (انظر bootstrap.dart).
  static String idFor(AdhkarCategory c) =>
      c == AdhkarCategory.morning ? 'adhkar_morning' : 'adhkar_evening';

  /// تنبيه الفئة الحالي، إن وُجد.
  static ReminderItem? reminderFor(AdhkarCategory c) {
    for (final r in UserDataStore.instance.reminders) {
      if (r.id == idFor(c)) return r;
    }
    return null;
  }

  /// يفعّل تنبيهاً يومياً للفئة في [time].
  static Future<void> enable(
    AdhkarCategory c,
    TimeOfDay time,
    String title,
  ) async {
    final reminder = ReminderItem(
      id: idFor(c),
      title: title,
      hour: time.hour,
      minute: time.minute,
      repeatMode: ReminderRepeatMode.daily,
      alertType: ReminderAlertType.notification,
      createdAt: DateTime.now(),
    );
    await UserDataStore.instance.putReminder(reminder);
    await LocalReminderService.instance.scheduleReminder(reminder);
  }

  static Future<void> disable(AdhkarCategory c) async {
    final existing = reminderFor(c);
    if (existing == null) return;
    await LocalReminderService.instance.cancelReminder(existing);
    await UserDataStore.instance.removeReminder(existing.id);
  }

  /// لوحة ضبط تذكيرات الأذكار.
  static Future<void> showSettingsSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _AdhkarRemindersSheet(),
    );
  }
}

class _AdhkarRemindersSheet extends StatelessWidget {
  const _AdhkarRemindersSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: UserDataStore.instance,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.adhkarReminders,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              for (final c in const [
                AdhkarCategory.morning,
                AdhkarCategory.evening,
              ])
                _ReminderRow(
                  category: c,
                  title: c == AdhkarCategory.morning
                      ? l10n.morningAdhkarReminder
                      : l10n.eveningAdhkarReminder,
                  defaultTime: c == AdhkarCategory.morning
                      ? const TimeOfDay(hour: 6, minute: 0)
                      : const TimeOfDay(hour: 17, minute: 30),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final AdhkarCategory category;
  final String title;
  final TimeOfDay defaultTime;

  const _ReminderRow({
    required this.category,
    required this.title,
    required this.defaultTime,
  });

  @override
  Widget build(BuildContext context) {
    final reminder = AdhkarReminders.reminderFor(category);
    final time = reminder == null
        ? null
        : TimeOfDay(hour: reminder.hour, minute: reminder.minute);

    Future<void> changeTime() async {
      final picked = await showTimePicker(
        context: context,
        initialTime: time ?? defaultTime,
      );
      if (picked != null) {
        await AdhkarReminders.enable(category, picked, title);
      }
    }

    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(
        category == AdhkarCategory.morning
            ? AppIcons.sunFill
            : AppIcons.moonStars,
      ),
      title: Text(title),
      subtitle: time == null
          ? null
          : InkWell(
              onTap: changeTime,
              child: Text(
                time.format(context),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
      value: reminder != null,
      onChanged: (on) async {
        HapticFeedback.selectionClick();
        if (on) {
          // يبدأ فوراً بالوقت المعتاد، ويغيّره القارئ بالضغط عليه.
          await AdhkarReminders.enable(category, defaultTime, title);
        } else {
          await AdhkarReminders.disable(category);
        }
      },
    );
  }
}
