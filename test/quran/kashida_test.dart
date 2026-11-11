import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/features/quran/qcf/kashida.dart';

void main() {
  test('a kashida goes between joined letters, nearest the end', () {
    // كتب: after the kaf and after the ta.
    expect(kashidaSpots('كتب'), [2, 1]);
    expect(stretchWords(['كتب'], 1), ['كت$tatweelب']);
  });

  test('no kashida where it would break the word', () {
    expect(kashidaSpots('ٱللَّهِ'), isEmpty, reason: 'the name of Allah');
    // Digital Khatt puts the shadda before the fatha.
    expect(
      kashidaSpots('ٱلل\u0651\u064eهِ'),
      isEmpty,
      reason: 'the name of Allah, shadda first',
    );
    expect(kashidaSpots('شَيْءٍ'), [2], reason: 'never before a lone hamza');
    expect(kashidaSpots('لا'), isEmpty, reason: 'the lam-alef ligature');
    expect(kashidaSpots('دار'), isEmpty, reason: 'letters that do not join');
    // حتىٰ: the dagger alef on the last letter would come loose.
    expect(kashidaSpots('حَتَّىٰٓ'), [2]);
  });

  test('kashidas spread over the longest words, a few per word', () {
    int count(List<String> words) =>
        words.fold(0, (n, w) => n + tatweel.allMatches(w).length);
    List<int> each(List<String> words) => [
      for (final w in words) tatweel.allMatches(w).length,
    ];
    // Round by round, the longer word first.
    expect(each(stretchWords(['قال', 'يستكبرون', 'لا'], 3)), [1, 2, 0]);
    // At most [perWord] each: what is left over stays for the spacing.
    expect(count(stretchWords(['قال', 'يستكبرون'], 9, perWord: 3)), 6);
    expect(stretchWords(['لا'], 5), ['لا'], reason: 'nowhere to put one');
  });
}
