import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/features/quran/qcf/qcf_ayah_text.dart';
import 'package:tadbeer/data/quran/quran_models.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/features/daily/ayah_of_day_card.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_ayah_of_day_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  bool inPool(int surah, int ayah) => AyahOfTheDay.pool.any(
    (a) => a.surahNumber == surah && a.ayahNumber == ayah,
  );

  test('the pool spans the whole Mushaf, leaving out only the longest', () {
    final repo = QuranRepository.instance;
    final pool = AyahOfTheDay.pool;
    expect(pool.map((a) => a.surahNumber).toSet(), hasLength(114));
    expect(pool.length, greaterThan(repo.allAyahs.length * 0.95));
    expect(inPool(2, 255), isTrue);
    expect(inPool(103, 1), isTrue);
    expect(inPool(108, 1), isTrue);
    // The debt ayah is too long for the card and the widget.
    expect(inPool(2, 282), isFalse);
  });

  test('each day has twelve different ayahs, led by a chosen one', () {
    for (var d = 0; d < 60; d++) {
      final day = DateTime(2026, 1, 1).add(Duration(days: d));
      final set = AyahOfTheDay.forDayAll(day);
      expect(set, hasLength(AyahOfTheDay.perDay));
      expect(set.map((a) => a.id).toSet(), hasLength(AyahOfTheDay.perDay));
      expect(AyahOfTheDay.curated.map((a) => a.id), contains(set.first.id));
      expect(AyahOfTheDay.forDay(day).id, set.first.id);
    }
  });

  Future<void> pumpCard(WidgetTester tester, {bool reduceMotion = false}) {
    return tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: const Scaffold(
            body: SingleChildScrollView(child: AyahOfTheDayCard()),
          ),
        ),
      ),
    );
  }

  /// The ayah on the card, written in the flowing font or, with the
  /// Madinah Mushaf, in its glyphs.
  String shownText(WidgetTester tester) {
    final today = AyahOfTheDay.forDayAll(DateTime.now());
    bool shown(Ayah a) {
      final glyphs = QcfGlyphs.of(a);
      return find.textContaining(a.text).evaluate().isNotEmpty ||
          (glyphs != null && find.text(glyphs.text).evaluate().isNotEmpty);
    }

    return today.firstWhere(shown).text;
  }

  testWidgets('the card moves to the next ayah by itself', (tester) async {
    await pumpCard(tester);
    final today = AyahOfTheDay.forDayAll(DateTime.now());
    expect(shownText(tester), today[0].text);
    await tester.pump(const Duration(seconds: 8));
    await tester.pumpAndSettle();
    expect(shownText(tester), today[1].text);
  });

  testWidgets('the card keeps one height as the ayahs change', (tester) async {
    await pumpCard(tester);
    final heights = <double>{};
    for (var i = 0; i < AyahOfTheDay.perDay; i++) {
      heights.add(tester.getSize(find.byType(AyahOfTheDayCard)).height);
      await tester.pump(const Duration(seconds: 8));
      await tester.pumpAndSettle();
    }
    expect(heights, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the card holds still under an open sheet', (tester) async {
    await pumpCard(tester);
    final today = AyahOfTheDay.forDayAll(DateTime.now());
    unawaited(
      showModalBottomSheet<void>(
        context: tester.element(find.byType(AyahOfTheDayCard)),
        builder: (_) => const SizedBox(height: 100),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 20));
    await tester.pumpAndSettle();
    expect(shownText(tester), today[0].text);
  });

  testWidgets('the card stays still with reduced motion', (tester) async {
    await pumpCard(tester, reduceMotion: true);
    final today = AyahOfTheDay.forDayAll(DateTime.now());
    await tester.pump(const Duration(seconds: 20));
    await tester.pumpAndSettle();
    expect(shownText(tester), today[0].text);
  });
}
