/// تذكير ورد الختمة اليومي بعدد الصفحات المتبقية.
///
/// A notification's text is fixed when it is scheduled, so instead of one
/// repeating notification the portion reminder is a run of one-off
/// notifications for the coming days. Each states the pages left on its day,
/// and the run is rescheduled whenever today's reading or the plan changes.
library;

import 'dart:math' as math;

import '../../core/services/local_reminder_service.dart';
import '../../core/storage/user_data_store.dart';
import 'reading_journey.dart';

/// Fixed id so a new khatma updates the same reminder instead of adding.
const portionReminderId = 'khatma_daily_portion';

/// How many days of portion notifications are scheduled ahead.
const portionReminderDays = 14;

/// إشعار ورد يوم واحد.
class PortionNotice {
  final DateTime at;
  final int pages;

  const PortionNotice(this.at, this.pages);

  @override
  bool operator ==(Object other) =>
      other is PortionNotice && other.at == at && other.pages == pages;

  @override
  int get hashCode => Object.hash(at, pages);

  @override
  String toString() => 'PortionNotice($at, $pages)';
}

/// The portion notifications from [now] on, at [hour]:[minute] each day.
///
/// Today's notice says what is left of today's portion and is dropped once
/// the portion is read or its time has passed. Later days expect a full
/// portion, until the pages left in the khatma run out.
List<PortionNotice> portionNotices(
  ReadingJourney journey,
  DateTime now, {
  required int hour,
  required int minute,
  int days = portionReminderDays,
}) {
  final plan = journey.plan;
  if (plan == null || plan.isComplete) return const [];
  var remaining = mushafPageCount - plan.advanced;
  final notices = <PortionNotice>[];
  for (var d = 0; d < days && remaining > 0; d++) {
    final target = d == 0
        ? math.max(0, plan.pagesPerDay - journey.pagesOn(now))
        : plan.pagesPerDay;
    final pages = math.min(target, remaining);
    remaining -= pages;
    final at = DateTime(now.year, now.month, now.day + d, hour, minute);
    if (pages > 0 && at.isAfter(now)) notices.add(PortionNotice(at, pages));
  }
  return notices;
}

/// Keeps the portion notifications in step with the reading journey.
class PortionReminderSync {
  PortionReminderSync._();

  static String? _lastKey;

  /// Starts listening to the store; call once after the store is ready.
  static void attach() {
    UserDataStore.instance.addListener(_onChange);
    _onChange();
  }

  static void _onChange() {
    final store = UserDataStore.instance;
    final reminder = store.reminders
        .where((r) => r.id == portionReminderId)
        .firstOrNull;
    if (reminder == null) {
      _lastKey = null;
      return;
    }
    final now = DateTime.now();
    final journey = store.journey;
    // Reminder edits reschedule on their own; this covers reading progress
    // and the start of a new day.
    final key = [
      reminder.isEnabled,
      reminder.hour,
      reminder.minute,
      dayKey(now),
      journey.pagesOn(now),
      journey.plan?.toJson().toString(),
    ].join('|');
    if (key == _lastKey) return;
    final first = _lastKey == null;
    _lastKey = key;
    // At start-up main() has already synced every reminder.
    if (first) return;
    LocalReminderService.instance.scheduleReminder(
      reminder,
      requestPermissionIfNeeded: false,
    );
  }
}
