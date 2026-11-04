import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/features/quran/qcf/qcf_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the Digital Khatt layout holds the whole Mushaf', () async {
    final layout = QcfLayout.instance;
    await layout.init();
    expect(layout.page(1), hasLength(8));
    for (var p = 3; p <= 604; p++) {
      expect(layout.page(p), hasLength(15), reason: 'page $p');
    }
    final ends = [
      for (var p = 1; p <= 604; p++)
        for (final line in layout.page(p))
          for (final w in line.words)
            if (w.isEnd) w,
    ];
    expect(ends, hasLength(6236));
    final basmalas = [
      for (var p = 1; p <= 604; p++)
        for (final line in layout.page(p))
          if (line.kind == QcfLineKind.basmala) line,
    ];
    // Every surah but al-Fatihah (whose basmala is its first ayah) and
    // at-Tawbah; never counted as words of the surah's first ayah.
    expect(basmalas, hasLength(112));
  });

  test('its pages follow the modern Madinah print', () async {
    final layout = QcfLayout.instance;
    await layout.init();
    // Al-Jathiyah 25 ends on the sixth line of page 501, before «يوم».
    final sixth = layout.page(501)[5].words;
    expect(sixth.last.surah, 45);
    expect(sixth.last.ayah, 26);
    expect(layout.page(502)[6].kind, QcfLineKind.surahHeader);
    // A boundary ayah sits a page later than in the 1405 print.
    expect(layout.pageOf(5, 77), 120);
    expect(layout.pageOf(5, 78), 121);
  });
}
