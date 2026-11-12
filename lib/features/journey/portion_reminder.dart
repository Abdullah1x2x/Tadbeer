/// تذكير ورد الختمة اليومي بعدد الصفحات المتبقية.
///
/// نص الإشعار يثبت عند جدولته، فبدل إشعار واحد متكرر يُجدول إشعار لكل يوم من
/// الأيام القادمة يذكر صفحات يومه المتبقية، وتُعاد الجدولة كلما تغيّرت قراءة
/// اليوم أو الخطة.
library;

import 'dart:math' as math;

import '../reminders/local_reminder_service.dart';
import '../../data/storage/user_data_store.dart';
import '../../data/models/reading_journey.dart';

/// معرّف ثابت، فتُحدّث الختمة الجديدة نفس التذكير بدل إضافة آخر.
const portionReminderId = 'khatma_daily_portion';

/// كم يوماً من إشعارات الورد يُجدول مسبقاً؛ ولا تذكير بعدها حتى يُفتح التطبيق.
///
/// لا تذكير يومي عام بعدها: أندرويد يبدأ التكرار اليومي من أقرب موعد قادم لا
/// من تاريخه، فيصل مع إشعار اليوم مكرراً.
const portionReminderDays = 30;

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

/// إشعارات الورد من [now] فصاعداً، في [hour]:[minute] كل يوم.
///
/// إشعار اليوم يذكر ما بقي من ورده، ويُسقط إن قُرئ الورد أو فات وقته. والأيام
/// التالية تتوقع ورداً كاملاً حتى تنفد صفحات الختمة.
List<PortionNotice> portionNotices(
  ReadingJourney journey,
  DateTime now, {
  required int hour,
  required int minute,
  int days = portionReminderDays,
}) {
  final plan = journey.plan;
  if (plan == null || plan.isComplete) return const [];
  var remaining = plan.totalPages - plan.advanced;
  final notices = <PortionNotice>[];
  for (var d = 0; d < days && remaining > 0; d++) {
    final at = DateTime(now.year, now.month, now.day + d, hour, minute);
    if (!at.isAfter(now)) continue;
    final target = d == 0
        ? math.max(0, plan.pagesPerDay - journey.portionPagesOn(now))
        : plan.pagesPerDay;
    final pages = math.min(target, remaining);
    if (pages <= 0) continue;
    remaining -= pages;
    notices.add(PortionNotice(at, pages));
  }
  return notices;
}

/// يُبقي إشعارات الورد متوافقة مع رحلة القراءة.
class PortionReminderSync {
  PortionReminderSync._();

  static String? _lastKey;
  static bool _lastEnabled = false;
  static Future<void>? _syncing;
  static bool _resyncNeeded = false;

  /// يبدأ الاستماع للمخزن؛ يُستدعى مرة بعد جاهزيته.
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
      _lastEnabled = false;
      return;
    }
    final now = DateTime.now();
    final journey = store.journey;
    // تعديل التذكير يعيد جدولته بنفسه؛ هذا لتقدّم القراءة وبداية يوم جديد.
    final key = [
      reminder.isEnabled,
      reminder.hour,
      reminder.minute,
      dayKey(now),
      journey.portionPagesOn(now),
      journey.plan?.toJson().toString(),
    ].join('|');
    if (key == _lastKey) return;
    final first = _lastKey == null;
    final wasEnabled = _lastEnabled;
    _lastKey = key;
    _lastEnabled = reminder.isEnabled;
    // عند الإقلاع تكون كل التذكيرات قد جُدولت؛ وإن كان معطّلاً مسبقاً فلا عمل.
    if (first || (!reminder.isEnabled && !wasEnabled)) return;
    _resyncNeeded = true;
    _syncing ??= _drain();
  }

  static Future<void> _drain() async {
    try {
      while (_resyncNeeded) {
        _resyncNeeded = false;
        final reminder = UserDataStore.instance.reminders
            .where((r) => r.id == portionReminderId)
            .firstOrNull;
        if (reminder == null) continue;
        await LocalReminderService.instance.scheduleReminder(
          reminder,
          requestPermissionIfNeeded: false,
        );
      }
    } finally {
      _syncing = null;
    }
  }
}
