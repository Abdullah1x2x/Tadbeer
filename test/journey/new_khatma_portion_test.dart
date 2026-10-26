import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/features/journey/reading_journey.dart';

void main() {
  final morning = DateTime(2026, 10, 26, 8);
  final evening = DateTime(2026, 10, 26, 20);

  ReadingJourney readPages(ReadingJourney j, Iterable<int> pages, DateTime at) {
    for (final p in pages) {
      j = j.recordPage(p, at);
    }
    return j;
  }

  test('a new khatma starts today with an empty portion', () {
    var journey = readPages(const ReadingJourney(), [300, 301, 302], morning);
    journey = journey.startPlan(30, evening);
    expect(journey.pagesOn(evening), 3);
    expect(journey.portionPagesOn(evening), 0);

    journey = journey.recordPage(1, evening);
    expect(journey.portionPagesOn(evening), 1);
  });

  test('the next day counts every page again', () {
    var journey = readPages(const ReadingJourney(), [300, 301], morning);
    journey = journey.startPlan(30, evening);
    final tomorrow = DateTime(2026, 10, 27, 9);
    journey = readPages(journey, [1, 2], tomorrow);
    expect(journey.portionPagesOn(tomorrow), 2);
  });

  test('the pages read before the start survive saving', () {
    var journey = readPages(const ReadingJourney(), [300, 301], morning);
    journey = journey.startPlan(30, evening);
    final restored = ReadingJourney.fromJson(journey.toJson());
    expect(restored.plan!.pagesBeforeStart, 2);
    expect(restored.portionPagesOn(evening), 0);
  });
}
