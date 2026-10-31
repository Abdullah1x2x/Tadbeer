import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/features/duas/data/quran_duas_repository.dart';
import 'package:tadbeer/features/quran/qcf/qcf_ayah_text.dart';
import 'package:tadbeer/features/quran/qcf/qcf_layout.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = Directory.systemTemp.createTempSync('tadbeer_dua_font_');
    await UserDataStore.instance.init(File('${dir.path}/data.json'));
    await QuranRepository.instance.init();
    await QcfLayout.instance.init();
  });

  test('every Quranic dua verse matches words of the Madinah layout', () {
    final misses = <String>[];
    for (final dua in QuranDuasRepository.instance.getDuas()) {
      for (final verse in dua.verses) {
        final ayah = QuranRepository.instance.getAyah(
          dua.surahNumber,
          verse.ayahNumber,
        );
        if (ayah == null || QcfGlyphs.excerptCodes(ayah, verse.text) == null) {
          misses.add('${dua.surahNumber}:${verse.ayahNumber}');
        }
      }
    }
    expect(misses, isEmpty);
  });
}
