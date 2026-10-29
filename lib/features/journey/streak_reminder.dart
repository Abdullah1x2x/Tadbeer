/// تنبيه قبل انقطاع سلسلة الأيام المتتالية.
///
/// نص الإشعار يثبت عند جدولته، فهذا زوج من الإشعارات: الليلة إن لم يكن في اليوم نشاط بعد، والغد بعد أن يُحتسب اليوم. كل إشعار يذكر السلسلة التي يحفظها، ويُعاد جدولته كلما تغيّر نشاط اليوم أو التذكير.
library;

import '../reminders/local_reminder_service.dart';
import '../../data/storage/user_data_store.dart';
import '../../data/models/reading_journey.dart';

/// معرّف تذكير السلسلة الثابت بين التذكيرات المحفوظة.
const streakReminderId = 'streak_guard';

/// ساعة التذكير الافتراضية، متأخرة ليكون نداءً أخيراً.
const streakReminderDefaultHour = 21;

/// إشعار السلسلة ليوم واحد.
class StreakNotice {
  final DateTime at;

  /// أيام السلسلة التي يدعو الإشعار القارئ إلى حفظها.
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

/// إشعارات السلسلة من [now] فصاعداً، في [hour]:[minute].
/// إشعار الليلة يبقى ما دام اليوم بلا نشاط وهناك سلسلة تضيع. فإذا احتُسب اليوم حرس إشعار الغد السلسلة التي تشمله. ولا شيء بعد ذلك، إذ تكون السلسلة قد انقطعت.
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

/// يُبقي إشعارات السلسلة متوافقة مع رحلة القراءة.
class StreakReminderSync {
  StreakReminderSync._();

  static String? _lastKey;

  /// يبدأ الاستماع للمخزن؛ يُستدعى مرة بعد جاهزيته.
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
    // عند الإقلاع تكون كل التذكيرات قد جُدولت.
    if (first) return;
    LocalReminderService.instance.scheduleReminder(
      reminder,
      requestPermissionIfNeeded: false,
    );
  }
}
