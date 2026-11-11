import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await QuranRepository.instance.init();
  });

  List<String> find(String query) => [
    for (final a in QuranRepository.instance.searchAyahs(query, limit: 500))
      '${a.surahNumber}:${a.ayahNumber}',
  ];

  // First, so the index comes from the background build and not a search.
  test('the index built in the background serves the search', () async {
    await QuranRepository.instance.warmSearchIndex();
    expect(find('أولئك'), contains('2:5'));
    expect(find('الصلاة'), contains('2:3'));
  });

  test('the common hamza spelling finds the Mushaf words', () {
    expect(find('يستهزئون'), contains('6:5'));
    expect(find('السيئات'), contains('4:18'));
    expect(find('بني إسرائيل'), contains('2:40'));
    expect(find('مسؤولا'), contains('17:34'));
    expect(find('أولئك'), contains('2:5'));
  });

  test('without the hamza a word is not found inside another', () {
    // رؤوف and the Mushaf's رءوف give the same ayahs, not every «معروف».
    expect(find('رؤوف'), find('رءوف'));
  });
}
