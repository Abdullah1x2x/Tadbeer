import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/features/ayah_links/data/ayah_link_repository.dart';
import 'package:tadbeer/features/ayah_links/data/curated_pathways.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File dataFile;
  late AyahLinkRepository repo;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_pathways_test_');
    dataFile = File('${tempDir.path}/test_user_data.json');
    await UserDataStore.instance.init(dataFile);
    await QuranRepository.instance.init();
    repo = AyahLinkRepository();
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('CuratedPathwaysRegistry Tests', () {
    test(
      'Curated pathways registry provides 15 thematic pathways of real ayahs',
      () {
        final pathways = CuratedPathwaysRegistry.pathways;
        expect(pathways.length, equals(15));
        expect(pathways.map((p) => p.id).toSet(), hasLength(15));
        expect(
          pathways.map((p) => p.id),
          containsAll(['doors_of_provision', 'allah_is_near', 'gratitude']),
        );

        for (final p in pathways) {
          expect(p.id, isNotEmpty);
          expect(p.title, isNotEmpty);
          expect(p.description, isNotEmpty);
          expect(p.category, isNotEmpty);
          expect(p.verses.length, greaterThanOrEqualTo(7));
          for (final v in p.verses) {
            expect(
              QuranRepository.instance.getAyah(v.surah, v.ayah),
              isNotNull,
              reason: '${p.id}: ${v.surah}:${v.ayah}',
            );
            expect(v.note, isNotEmpty);
          }
        }
      },
    );

    test(
      'importPathway imports curated pathway into AyahLinkRepository',
      () async {
        final pathway = CuratedPathwaysRegistry.pathways.first;
        final imported = await CuratedPathwaysRegistry.importPathway(
          pathway,
          repo: repo,
        );

        expect(imported.title, equals(pathway.title));
        expect(imported.verses.length, equals(pathway.verses.length));

        final retrieved = repo.getLink(imported.id);
        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals(imported.id));
        expect(retrieved.verses.length, equals(pathway.verses.length));
      },
    );
  });
}
