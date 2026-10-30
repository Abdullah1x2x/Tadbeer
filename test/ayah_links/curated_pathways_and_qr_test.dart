import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/data/models/ayah_link_model.dart';
import 'package:tadbeer/features/ayah_links/data/ayah_link_repository.dart';
import 'package:tadbeer/features/ayah_links/data/curated_pathways.dart';
import 'package:tadbeer/features/ayah_links/widgets/ayah_link_qr_dialog.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File dataFile;
  late AyahLinkRepository repo;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'tadbeer_pathways_qr_test_',
    );
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

  group('CuratedPathwaysRegistry & AyahLinkQrDialog Tests', () {
    test(
      'Curated pathways registry provides 7 thematic pathways of real ayahs',
      () {
        final pathways = CuratedPathwaysRegistry.pathways;
        expect(pathways.length, equals(7));
        expect(pathways.map((p) => p.id).toSet(), hasLength(7));
        expect(
          pathways.map((p) => p.id),
          containsAll(['doors_of_provision', 'allah_is_near', 'gratitude']),
        );

        for (final p in pathways) {
          expect(p.id, isNotEmpty);
          expect(p.title, isNotEmpty);
          expect(p.description, isNotEmpty);
          expect(p.category, isNotEmpty);
          expect(p.verses.length, greaterThanOrEqualTo(3));
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

    test('AyahLinkQrDialog link encoding and decoding roundtrip', () {
      final link = AyahLinkItem(
        id: 'test_qr_link_1',
        title: 'رابط تدبري لاختبار QR',
        description:
            'وصف الرابط التدبري للتحقق من التشفير وفك التشفير دون إنترنت',
        verses: [
          AyahLinkVerse(
            ayahId: 255,
            surahNumber: 2,
            ayahNumber: 255,
            page: 42,
            note: 'آية الكرسي',
            addedAt: DateTime.now(),
          ),
          AyahLinkVerse(
            ayahId: 5148,
            surahNumber: 59,
            ayahNumber: 23,
            page: 548,
            note: 'الملك القدوس',
            addedAt: DateTime.now(),
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final encoded = AyahLinkQrDialog.encodeLink(link);
      expect(encoded, isNotEmpty);
      expect(encoded, startsWith('tadbeer://link?data='));

      final decoded = AyahLinkQrDialog.decodeLink(encoded);
      expect(decoded, isNotNull);
      expect(decoded!['t'], equals(link.title));
      expect(decoded['d'], equals(link.description));

      final ayahs = (decoded['ay'] as List).cast<Map<String, dynamic>>();
      expect(ayahs.length, equals(2));
      expect(ayahs[0]['s'], equals(2));
      expect(ayahs[0]['a'], equals(255));
      expect(ayahs[0]['n'], equals('آية الكرسي'));
      expect(ayahs[1]['s'], equals(59));
      expect(ayahs[1]['a'], equals(23));
    });

    test('AyahLinkQrDialog decodeLink gracefully rejects invalid payloads', () {
      expect(AyahLinkQrDialog.decodeLink(''), isNull);
      expect(AyahLinkQrDialog.decodeLink('https://example.com'), isNull);
      expect(
        AyahLinkQrDialog.decodeLink('tadbeer://link?data=invalid_base64!!!'),
        isNull,
      );
      expect(
        AyahLinkQrDialog.decodeLink('tadbeer://link?data=YWJj'),
        isNull,
      ); // not JSON
    });
  });
}
