import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/app/localization.dart';
import 'package:tadbeer/core/design_system/app_icons.dart';
import 'package:tadbeer/data/models/note_model.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/data/storage/user_database.dart';
import 'package:tadbeer/features/notes/note_editor_screen.dart';
import 'package:tadbeer/features/notes/note_pdf_exporter.dart';
import 'package:tadbeer/features/notes/notes_screen.dart';
import 'package:tadbeer/features/notes/tadbeer_journal_exporter.dart';

Widget _wrapApp(
  Widget child, {
  AppLanguage language = AppLanguage.arabic,
}) {
  return AppLocalizationScope(
    currentLanguage: language,
    strings: AppStrings(language),
    onLanguageChanged: (_) {},
    child: MaterialApp(home: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('phase1_notes_test_');
    await UserDataStore.instance.init(File('${tempDir.path}/data.json'));
    await UserDataStore.instance.resetAllData();
    await QuranRepository.instance.init();
  });

  tearDown(() async {
    await UserDatabase.instance.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('NoteEditorScreen tracks title changes live and applies BiDi direction', (
    tester,
  ) async {
    final l10nEn = AppStrings(AppLanguage.english);
    final existing = NoteItem(
      id: 'n-1',
      type: NoteType.free,
      title: 'Title',
      content: 'Initial note content',
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );

    await tester.pumpWidget(
      _wrapApp(
        NoteEditorScreen(existingNote: existing),
        language: AppLanguage.english,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.saved), findsOneWidget);
    final titleFieldFinder = find.byType(TextField).first;
    expect(
      tester.widget<TextField>(titleFieldFinder).textDirection,
      TextDirection.ltr,
    );

    await tester.enterText(titleFieldFinder, 'عنوان عربي جديد');
    await tester.pump();

    expect(find.text(l10nEn.unsaved), findsOneWidget);
    expect(
      tester.widget<TextField>(titleFieldFinder).textDirection,
      TextDirection.rtl,
    );

    final navState = tester.state<NavigatorState>(find.byType(Navigator));
    await navState.maybePop();
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.unsavedChanges), findsOneWidget);
    await tester.tap(find.text(l10nEn.discard));
    await tester.pumpAndSettle();
  });

  testWidgets('NotesScreen exposes Edit action in popup menu for ayah notes', (
    tester,
  ) async {
    final l10nAr = AppStrings(AppLanguage.arabic);
    await tester.runAsync(
      () => UserDataStore.instance.saveNote(
        type: NoteType.ayah,
        title: 'عنوان على الآية',
        content: 'محتوى التدبر',
        surahNumber: 1,
        ayahNumber: 1,
        page: 1,
        ayahText: 'بِسْمِ ٱللَّهِ',
      ),
    );

    await tester.pumpWidget(
      _wrapApp(const NotesScreen(), language: AppLanguage.arabic),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('عنوان على الآية'), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.dotsThreeVertical).first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(l10nAr.edit), findsOneWidget);
  });

  test('NoteRepository.duplicateNote supports localized copyLabel', () async {
    final original = NoteItem(
      id: 'orig-1',
      type: NoteType.free,
      title: 'Reflection',
      content: 'Body',
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );
    final copy = await UserDataStore.instance.duplicateNote(
      original,
      copyLabel: AppStrings(AppLanguage.english).copyLabel,
    );
    expect(copy.title, 'Reflection (copy)');
  });

  test('NotePdfExporter paginates long notes cleanly and uses unique filenames', () async {
    final longBody = List.generate(
      140,
      (i) => 'السطر رقم $i: تدبر وملاحظة طويلة لاختبار تعدد الصفحات في ملف PDF.',
    ).join('\n');
    final note = NoteItem(
      id: 'preview/unsafe:id',
      type: NoteType.ayah,
      title: 'فائدة حول الفاتحة',
      content: longBody,
      surahNumber: 1,
      ayahNumber: 2,
      page: 1,
      ayahText: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ',
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );

    final file1 = await NotePdfExporter.generateNotePdf(
      note,
      outputDir: tempDir,
      l10n: AppStrings(AppLanguage.arabic),
      language: AppLanguage.arabic,
    );
    final file2 = await NotePdfExporter.generateNotePdf(
      note,
      outputDir: tempDir,
      l10n: AppStrings(AppLanguage.english),
      language: AppLanguage.english,
    );

    expect(file1.existsSync(), isTrue);
    expect(file2.existsSync(), isTrue);
    expect(file1.path, isNot(file2.path));
    final bytes1 = file1.readAsBytesSync();
    expect(String.fromCharCodes(bytes1.take(4)), '%PDF');
  });

  test('TadbeerJournalExporter safely handles ayah notes missing or invalid surah metadata', () async {
    final store = UserDataStore.instance;
    await store.putNote(
      NoteItem(
        id: 'corrupt-1',
        type: NoteType.ayah,
        title: 'خاطرة بلا مرجع كامل',
        content: 'محتوى آمن',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    await store.putNote(
      NoteItem(
        id: 'corrupt-2',
        type: NoteType.ayah,
        content: 'سورة خارج النطاق',
        surahNumber: 999,
        ayahNumber: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final summary = TadbeerJournalExporter.buildSummary(
      period: JournalPeriod.allTime,
    );
    final markdown = TadbeerJournalExporter.generateMarkdown(summary);
    final pdf = await TadbeerJournalExporter.generatePdf(
      summary,
      outputDir: tempDir,
    );

    expect(summary.notes.length, 2);
    expect(markdown, contains('خاطرة بلا مرجع كامل'));
    expect(pdf.existsSync(), isTrue);
  });
}
