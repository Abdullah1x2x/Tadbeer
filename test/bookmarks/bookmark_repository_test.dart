import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/data/models/bookmark_model.dart';
import 'package:tadbeer/data/quran/quran_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late File testFile;
  late BookmarkRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'tadbeer_bookmark_repo_test_',
    );
    testFile = File('${tempDir.path}/test_user_data.json');
    await UserDataStore.instance.init(testFile);
    repository = BookmarkRepository();
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('BookmarkRepository Unit Tests', () {
    const testAyah = Ayah(
      id: 1,
      surahNumber: 1,
      ayahNumber: 1,
      text: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
      rawText: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
      page: 1,
      juz: 1,
      hizb: 1,
      quarter: 1,
    );

    test('Toggle bookmark on and off', () async {
      expect(repository.isBookmarked(1, 1), isFalse);

      final added = await repository.toggleBookmark(testAyah);
      expect(added, isTrue);
      expect(repository.isBookmarked(1, 1), isTrue);
      expect(repository.allBookmarks.length, equals(1));

      final removed = await repository.toggleBookmark(testAyah);
      expect(removed, isFalse);
      expect(repository.isBookmarked(1, 1), isFalse);
      expect(repository.allBookmarks.isEmpty, isTrue);
    });
  });
}
