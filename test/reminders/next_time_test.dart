import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/features/reminders/local_reminder_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  late tz.Location zone;

  setUpAll(() {
    tz.initializeTimeZones();
    zone = tz.getLocation('America/New_York');
  });

  test('a time later today stays today', () {
    final next = nextDailyTime(tz.TZDateTime(zone, 2027, 5, 1, 7), 8, 0);
    expect(next, tz.TZDateTime(zone, 2027, 5, 1, 8));
  });

  test('a passed time moves to tomorrow', () {
    final next = nextDailyTime(tz.TZDateTime(zone, 2027, 5, 1, 9), 8, 0);
    expect(next, tz.TZDateTime(zone, 2027, 5, 2, 8));
  });

  test('tomorrow keeps its clock time across the spring change', () {
    final next = nextDailyTime(tz.TZDateTime(zone, 2027, 3, 13, 9), 8, 0);
    expect(next.hour, 8);
    expect(next.day, 14);
  });

  test('a weekday finds the next matching day', () {
    // May 1 2027 is a Saturday.
    final next = nextWeekdayTime(
      tz.TZDateTime(zone, 2027, 5, 1, 9),
      DateTime.monday,
      8,
      0,
    );
    expect(next, tz.TZDateTime(zone, 2027, 5, 3, 8));
  });
}
