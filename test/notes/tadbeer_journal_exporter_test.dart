import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/features/notes/tadbeer_journal_exporter.dart';
import 'package:tadbeer/data/models/note_model.dart';
import 'package:tadbeer/data/quran/quran_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File dataFile;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_journal_test_');
    dataFile = File('${tempDir.path}/test_user_data.json');
    await UserDataStore.instance.init(dataFile);
    await QuranRepository.instance.init();
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('TadbeerJournalExporter Unit Tests', () {
    test(
      'buildSummary aggregates notes and tadbeer pauses correctly',
      () async {
        final store = UserDataStore.instance;

        // Add a note
        final testNote = NoteItem(
          id: 'test_note_1',
          type: NoteType.ayah,
          surahNumber: 1,
          ayahNumber: 1,
          ayahText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          content: 'تأمل في البسملة واستفتاح كل أمر بالرحمة',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await store.putNote(testNote);

        // Add a tadbeer pause item
        await store.saveTadbeer(
          surahNumber: 1,
          ayahNumber: 1,
          answers: {
            1: 'البدء باسم الله دلالة على الاستعانة التامة به',
            2: 'الرحمة تسبق كل عمل مبارك',
          },
        );

        final summary = TadbeerJournalExporter.buildSummary(
          period: JournalPeriod.last7Days,
        );

        expect(summary.isEmpty, isFalse);
        expect(summary.totalReflections, greaterThanOrEqualTo(2));
        expect(summary.surahNames, contains('الفاتحة'));
        expect(summary.notes, anyElement((n) => n.id == 'test_note_1'));
        expect(summary.tadbeerItems, anyElement((t) => t.ayahKey == '1:1'));
      },
    );

    test('generateMarkdown formats statistics and reflections properly', () {
      final summary = TadbeerJournalExporter.buildSummary(
        period: JournalPeriod.last7Days,
      );

      final markdown = TadbeerJournalExporter.generateMarkdown(summary);

      expect(
        markdown,
        contains('# 📖 دفتر تدبّر — سجل الخواطر والتأملات القرآنية'),
      );
      expect(markdown, contains('ملخص الإحصاءات التدبرية'));
      expect(markdown, contains('سورة الفاتحة'));
      expect(markdown, contains('تأمل في البسملة'));
      expect(
        markdown,
        contains('البدء باسم الله دلالة على الاستعانة التامة به'),
      );
    });

    test(
      'generatePdf generates a valid PDF file with embedded Amiri fonts',
      () async {
        final summary = TadbeerJournalExporter.buildSummary(
          period: JournalPeriod.last7Days,
        );

        final pdfFile = await TadbeerJournalExporter.generatePdf(
          summary,
          outputDir: tempDir,
        );

        expect(pdfFile.existsSync(), isTrue);
        expect(pdfFile.lengthSync(), greaterThan(1000));
        expect(pdfFile.path, endsWith('.pdf'));

        // Clean up generated pdf file
        if (pdfFile.existsSync()) {
          pdfFile.deleteSync();
        }
      },
    );
  });
}
