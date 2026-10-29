import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/features/journey/portion_reminder.dart';
import 'package:tadbeer/data/models/reading_journey.dart';

void main() {
  final now = DateTime(2026, 10, 26, 10);

  ReadingJourney journey({int advanced = 0, int readToday = 0}) =>
      ReadingJourney(
        plan: KhatmaPlan(
          startDate: DateTime(2026, 10, 20),
          days: 30,
          currentPage: advanced + 1,
          advanced: advanced,
        ),
        dailyPages: {
          if (readToday > 0)
            dayKey(now): {for (var p = 1; p <= readToday; p++) p},
        },
      );

  List<PortionNotice> notices(ReadingJourney j, {int hour = 20}) =>
      portionNotices(j, now, hour: hour, minute: 0);

  test('nothing without a khatma', () {
    expect(notices(const ReadingJourney()), isEmpty);
  });

  test('today states what is left, later days a full portion', () {
    final list = notices(journey(readToday: 5));
    expect(list.first, PortionNotice(DateTime(2026, 10, 26, 20), 16));
    expect(list[1], PortionNotice(DateTime(2026, 10, 27, 20), 21));
    expect(list, hasLength(portionReminderDays));
  });

  test('skips today once the portion is read', () {
    final list = notices(journey(readToday: 21));
    expect(list.first.at, DateTime(2026, 10, 27, 20));
    expect(list.first.pages, 21);
  });

  test('skips today when its time has passed', () {
    final list = notices(journey(), hour: 8);
    expect(list.first.at, DateTime(2026, 10, 27, 8));
  });

  test('stops when the khatma runs out of pages', () {
    final list = notices(journey(advanced: 580));
    expect(list.map((n) => n.pages), [21, 3]);
  });
}
