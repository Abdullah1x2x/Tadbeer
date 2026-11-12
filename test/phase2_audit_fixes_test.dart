import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/core/design_system/app_icons.dart';
import 'package:tadbeer/data/models/ayah_link_model.dart';
import 'package:tadbeer/data/models/highlight_model.dart';
import 'package:tadbeer/data/models/note_model.dart';
import 'package:tadbeer/data/models/tadbeer_model.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/features/ayah_links/data/ayah_link_repository.dart';
import 'package:tadbeer/features/daily/ayah_of_day_card.dart';
import 'package:tadbeer/features/duas/data/quran_duas_repository.dart';
import 'package:tadbeer/features/journey/weekly_goals.dart';
import 'package:tadbeer/features/tadbeer/tadbeer_questions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_phase2_test_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await QuranRepository.instance.init();
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Phase 2 audit fixes regression tests', () {
    testWidgets('WeeklyGoalsCard treats goal <= 0 as 0% and not completed', (
      tester,
    ) async {
      await tester.runAsync(
        () => const WeeklyGoals(pages: 0, reflections: 0).save(),
      );
      await tester.pumpWidget(
        AppLocalizationScope(
          currentLanguage: AppLanguage.arabic,
          strings: AppStrings(AppLanguage.arabic),
          onLanguageChanged: (_) {},
          child: MaterialApp(
            home: Scaffold(body: WeeklyGoalsCard(now: DateTime(2026, 4, 15))),
          ),
        ),
      );

      final bars = tester
          .widgetList<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          )
          .toList();
      expect(bars, hasLength(2));
      expect(bars[0].value, 0.0);
      expect(bars[1].value, 0.0);
      expect(find.byIcon(AppIcons.checkCircleFill), findsNothing);
    });

    test('HighlightsSection.putHighlight cleans superseded ID in store', () async {
      final store = UserDataStore.instance;
      final first = HighlightItem(
        id: 'hl-old',
        ayahId: 1,
        surahNumber: 1,
        ayahNumber: 1,
        page: 1,
        colorIndex: 0,
        createdAt: DateTime(2026, 1, 1),
      );
      await store.putHighlight(first);
      expect(store.highlights.map((h) => h.id), ['hl-old']);

      final replacement = HighlightItem(
        id: 'hl-new',
        ayahId: 1,
        surahNumber: 1,
        ayahNumber: 1,
        page: 1,
        colorIndex: 2,
        createdAt: DateTime(2026, 1, 2),
      );
      await store.putHighlight(replacement);

      expect(store.highlights, hasLength(1));
      expect(store.highlights.single.id, 'hl-new');
      expect(store.getHighlight(1, 1)?.id, 'hl-new');
    });

    test('Tadbeer and AyahOfTheDay questions localize to English and Arabic', () {
      expect(TadbeerItem.questionsFor(isArabic: true), TadbeerItem.questions);
      expect(
        TadbeerItem.questionsFor(isArabic: false),
        TadbeerItem.questionsEn,
      );

      final qEn = AyahOfTheDay.questionFor(
        DateTime(2026, 4, 15),
        0,
        isArabic: false,
      );
      expect(qEn, isNotEmpty);
      expect(RegExp(r'[A-Za-z]').hasMatch(qEn), isTrue);

      final ayah = QuranRepository.instance.getAyah(1, 1)!;
      final ayahQuestionsEn = TadbeerQuestions.forAyah(ayah, isArabic: false);
      expect(ayahQuestionsEn, hasLength(4));
      expect(ayahQuestionsEn.every((q) => RegExp(r'[A-Za-z]').hasMatch(q)), isTrue);
    });

    test('copyWith null-clearing & NotesSection.saveNote clearTitle work', () async {
      final now = DateTime(2026, 4, 15);
      final verse = AyahLinkVerse(
        ayahId: 1,
        surahNumber: 1,
        ayahNumber: 1,
        toAyahNumber: 3,
        page: 1,
        note: 'existing note',
        addedAt: now,
      );
      final clearedVerse = verse.copyWith(note: null, toAyahNumber: null);
      expect(clearedVerse.note, isNull);
      expect(clearedVerse.toAyahNumber, isNull);

      final noteNode = AyahLinkNote(
        id: 'n1',
        title: 'Title',
        content: 'Body',
        createdAt: now,
        updatedAt: now,
      );
      expect(noteNode.copyWith(title: null).title, isNull);

      final link = AyahLinkItem(
        id: 'l1',
        title: 'Link',
        description: 'Desc',
        panX: 10,
        panY: 20,
        zoomScale: 1.5,
        createdAt: now,
        updatedAt: now,
      );
      final clearedLink = link.copyWith(
        description: null,
        panX: null,
        panY: null,
        zoomScale: null,
      );
      expect(clearedLink.description, isNull);
      expect(clearedLink.panX, isNull);
      expect(clearedLink.panY, isNull);
      expect(clearedLink.zoomScale, isNull);

      final noteItem = NoteItem(
        id: 'note-1',
        type: NoteType.free,
        title: 'My Title',
        content: 'Content',
        createdAt: now,
        updatedAt: now,
      );
      expect(noteItem.copyWith(title: null).title, isNull);

      final store = UserDataStore.instance;
      final saved = await store.saveNote(
        type: NoteType.free,
        title: 'Keep Me',
        content: 'Initial',
      );
      final preserved = await store.saveNote(
        id: saved.id,
        type: NoteType.free,
        content: 'Updated only content',
      );
      expect(preserved.title, 'Keep Me');

      final cleared = await store.saveNote(
        id: saved.id,
        type: NoteType.free,
        clearTitle: true,
        content: 'Cleared title',
      );
      expect(cleared.title, isNull);
    });

    test('Diacritics-only queries return empty results cleanly', () async {
      final linkRepo = AyahLinkRepository();
      await linkRepo.createLink(title: 'الصبر');

      expect(linkRepo.searchLinks('َُِ'), isEmpty);
      expect(QuranDuasRepository.instance.search('َُِ'), isEmpty);
    });
  });
}
