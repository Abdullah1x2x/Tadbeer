import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/data/models/reading_journey.dart';
import 'package:tadbeer/features/journey/weekly_goals.dart';
import 'package:tadbeer/features/memorization/memorization_model.dart';

/// Meaningful only in a zone with daylight saving; CI runs this file again with
/// TZ=America/New_York, where March 14 2027 has 23 hours and November 7 has 25.
void main() {
  test('a khatma day number survives the spring clock change', () {
    final plan = KhatmaPlan(startDate: DateTime(2027, 3, 12), days: 30);
    expect(plan.dayNumber(DateTime(2027, 3, 16, 9)), 5);
  });

  test('the week after a clock change starts on Saturday midnight', () {
    expect(WeeklyGoals.weekStart(DateTime(2027, 3, 16)), DateTime(2027, 3, 13));
  });

  test('a review date is not pulled back by the autumn clock change', () {
    final card = HifzCard(
      box: 1,
      due: DateTime(2027, 11, 5),
    ).grade(remembered: true, now: DateTime(2027, 11, 5));
    expect(dayKey(card.due), '2027-11-08');
  });
}
