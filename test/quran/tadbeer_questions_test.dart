import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/quran/data/quran_repository.dart';
import 'package:tadbeer/features/tadbeer/tadbeer_model.dart';
import 'package:tadbeer/features/tadbeer/tadbeer_questions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_questions_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  AyahKind kind(int surah, int ayah) =>
      TadbeerQuestions.kindOf(QuranRepository.instance.getAyah(surah, ayah)!);

  test('ayahs get a simple kind', () {
    expect(kind(2, 201), AyahKind.dua);
    expect(kind(20, 25), AyahKind.dua);
    expect(kind(3, 8), AyahKind.dua);
    expect(kind(2, 25), AyahKind.promise);
    expect(kind(12, 23), AyahKind.story);
    expect(kind(2, 255), AyahKind.general);
    expect(kind(103, 1), AyahKind.general);
  });

  test('a kind swaps one question and keeps the rest', () {
    final repo = QuranRepository.instance;
    final general = TadbeerItem.questions;
    final dua = TadbeerQuestions.forAyah(repo.getAyah(2, 201));
    final story = TadbeerQuestions.forAyah(repo.getAyah(12, 23));
    final promise = TadbeerQuestions.forAyah(repo.getAyah(2, 25));
    expect(TadbeerQuestions.forAyah(repo.getAyah(2, 255)), general);
    expect(dua[1], 'ما الذي تحتاجه أنت من هذا الدعاء؟');
    expect(story[1], 'ما الذي يشبه حالك في هذا الموقف؟');
    expect(promise[2], 'أين أنت من هذه الآية؟');
    for (final q in [dua, story, promise]) {
      expect(q, hasLength(4));
      var differ = 0;
      for (var i = 0; i < 4; i++) {
        if (q[i] != general[i]) differ++;
      }
      expect(differ, 1);
    }
  });

  test('how many ayahs fall in each kind', () {
    final counts = <AyahKind, int>{};
    for (var s = 1; s <= 114; s++) {
      final surah = QuranRepository.instance.getSurah(s);
      for (var a = 1; a <= surah.ayahCount; a++) {
        final k = kind(s, a);
        counts[k] = (counts[k] ?? 0) + 1;
      }
    }
    // ignore: avoid_print
    print(counts);
    expect(counts[AyahKind.general]! > 3000, isTrue);
  });
}
