import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/core/utils/arabic_search_normalizer.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/features/duas/data/adhkar_repository.dart';

void main() {
  test('each Quranic dhikr names the ayahs its text quotes', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await QuranRepository.instance.init();
    final repo = QuranRepository.instance;
    // Letters only: the dhikr is written in common spelling, the Mushaf not.
    String letters(String s) =>
        ArabicSearchNormalizer.withoutHamza(s)
            .replaceAll(RegExp('[^ء-ي]'), '')
            .replaceAll('ا', '');
    final items = [
      for (final c in AdhkarCategory.values)
        ...AdhkarRepository.instance.getAdhkar(c),
    ].where((i) => i.quran.isNotEmpty);
    expect(items, isNotEmpty);
    for (final item in items) {
      final quoted = [
        for (final (s, from, to) in item.quran)
          for (var a = from; a <= to; a++) repo.getAyah(s, a)!.text,
      ].join(' ');
      expect(letters(item.text), letters(quoted), reason: item.id);
    }
  });
}
