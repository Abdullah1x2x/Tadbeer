/// تنبيه قبل انقطاع سلسلة الأيام المتتالية.
///
/// A notification's text is fixed when it is scheduled, so like the
/// portion reminder this is a pair of one-off notifications: tonight's,
/// when today has no activity yet, and tomorrow's, once today counts. Each
/// names the streak it would save, and the pair is rescheduled whenever
/// today's activity or the reminder changes.
library;

import '../../core/services/local_reminder_service.dart';
import '../../core/storage/user_data_store.dart';
import 'reading_journey.dart';

/// Fixed id of the streak reminder among the saved reminders.
const streakReminderId = 'streak_guard';

/// Hour the streak reminder starts at, late enough to be a last call.
const streakReminderDefaultHour = 21;

/// إشعار سلسلة ليوم واحد.
class StreakNotice {
  final DateTime at;

  /// Days in the streak the notice asks the reader to keep.
  final int streak;

  const StreakNotice(this.at, this.streak);

  @override
  bool operator ==(Object other) =>
      other is StreakNotice && other.at == at && other.streak == streak;

  @override
  int get hashCode => Object.hash(at, streak);

  @override
  String toString() => 'StreakNotice($at, $streak)';
}

/// The streak notices from [now] on, at [hour]:[minute].
///
/// Tonight's notice stands only while today has no activity and there is a
/// streak to lose. Once today counts, tomorrow's notice guards the streak
/// that includes today. Nothing further ahead: by then the streak would
/// already have broken.
List<StreakNotice> streakNotices(
  ReadingJourney journey,
  DateTime now, {
  required int hour,
  required int minute,
}) {
  final today = DateTime(now.year, now.month, now.day, hour, minute);
  final streak = journey.streak(now);
  if (streak == 0) return const [];
  if (journey.isActiveOn(now)) {
    return [
      StreakNotice(
        DateTime(now.year, now.month, now.day + 1, hour, minute),
        streak,
      ),
    ];
  }
  return [if (today.isAfter(now)) StreakNotice(today, streak)];
}

/// Keeps the streak notifications in step with the reading journey.
class StreakReminderSync {
  StreakReminderSync._();

  static String? _lastKey;

  /// Starts listening to the store; call once after the store is ready.
  static void attach() {
    UserDataStore.instance.addListener(_onChange);
    _onChange();
  }

  static void _onChange() {
    final store = UserDataStore.instance;
    final reminder = store.reminders
        .where((r) => r.id == streakReminderId)
        .firstOrNull;
    if (reminder == null) {
      _lastKey = null;
      return;
    }
    final now = DateTime.now();
    final journey = store.journey;
    final key = [
      reminder.isEnabled,
      reminder.hour,
      reminder.minute,
      dayKey(now),
      journey.isActiveOn(now),
      journey.streak(now),
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
