import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/highlights/highlight_model.dart';
import 'package:tadbeer/features/quran/data/quran_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late File testFile;
  late HighlightRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'tadbeer_highlight_repo_test_',
    );
    testFile = File('${tempDir.path}/test_user_data.json');
    await UserDataStore.instance.init(testFile);
    repository = HighlightRepository();
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('HighlightRepository Unit Tests', () {
    const testAyah = Ayah(
      id: 255,
      surahNumber: 2,
      ayahNumber: 255,
      text: 'ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ ٱلْحَىُّ ٱلْقَيُّومُ',
      rawText: 'ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ ٱلْحَىُّ ٱلْقَيُّومُ',
      page: 42,
      juz: 3,
      hizb: 5,
      quarter: 17,
    );

    test('Set, retrieve, and remove highlight', () async {
      expect(repository.getHighlight(2, 255), isNull);

      await repository.setHighlight(testAyah, 1);
      final hl = repository.getHighlight(2, 255);
      expect(hl, isNotNull);
      expect(hl!.colorIndex, equals(1));

      // Update color
      await repository.setHighlight(testAyah, 3);
      expect(repository.getHighlight(2, 255)?.colorIndex, equals(3));

      // Remove
      await repository.removeHighlight(2, 255);
      expect(repository.getHighlight(2, 255), isNull);
    });
  });
}
