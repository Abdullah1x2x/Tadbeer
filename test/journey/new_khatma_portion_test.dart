import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/data/models/reading_journey.dart';

/// Today's portion is how far the khatma moved today, so the bar on the
/// journey page agrees with the khatma ring and the reading position.
void main() {
  final morning = DateTime(2026, 10, 26, 8);
  final evening = DateTime(2026, 10, 26, 20);
  final tomorrow = DateTime(2026, 10, 27, 9);

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

  test('the next day starts a new portion from where the khatma is', () {
    var journey = const ReadingJourney().startPlan(30, morning);
    journey = readPages(journey, [1, 2, 3], morning);
    expect(journey.portionPagesOn(tomorrow), 0);
    journey = readPages(journey, [4, 5], tomorrow);
    expect(journey.portionPagesOn(tomorrow), 2);
  });

  test('moving the khatma with the reading position fills the portion', () {
    var journey = const ReadingJourney().startPlan(30, morning);
    // Pages turned too fast to count, then the reader stays on page 6.
    journey = journey.moveKhatmaTo(6, morning);
    expect(journey.plan!.advanced, 5);
    expect(journey.portionPagesOn(morning), 5);
  });

  test('re-reading earlier pages does not fill the portion', () {
    var journey = const ReadingJourney().startPlan(30, morning);
    journey = readPages(journey, [100, 101, 102], morning);
    expect(journey.pagesOn(morning), 3);
    expect(journey.portionPagesOn(morning), 0);
  });

  test('the portion survives saving, and an older save starts afresh', () {
    var journey = const ReadingJourney().startPlan(30, morning);
    journey = readPages(journey, [1, 2], morning);
    final restored = ReadingJourney.fromJson(journey.toJson());
    expect(restored.portionPagesOn(evening), 2);

    final old = journey.toJson();
    (old['plan'] as Map).remove('day');
    expect(ReadingJourney.fromJson(old).portionPagesOn(evening), 0);
  });
}
