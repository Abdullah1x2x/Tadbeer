import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/data/models/note_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late File testFile;
  late NoteRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_note_repo_test_');
    testFile = File('${tempDir.path}/test_user_data.json');
    await UserDataStore.instance.init(testFile);
    await UserDataStore.instance.resetAllData();
    repository = NoteRepository();
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('NoteRepository Unit Tests', () {
    test('Create and retrieve Ayah Note with stable linkage', () async {
      final note = await repository.saveNote(
        type: NoteType.ayah,
        content: 'تأمل في دلالات الرحمة',
        ayahId: 1,
        surahNumber: 1,
        ayahNumber: 1,
        page: 1,
        ayahText: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
      );

      expect(note.id, isNotEmpty);
      expect(note.isAyahNote, isTrue);
      expect(repository.allNotes.length, equals(1));

      final ayahNotes = repository.getNotesForAyah(1, 1);
      expect(ayahNotes.length, equals(1));
      expect(ayahNotes.first.content, equals('تأمل في دلالات الرحمة'));
    });

    test('Create, update and delete Free Note', () async {
      final note = await repository.saveNote(
        type: NoteType.free,
        title: 'خاطرة إيمانية',
        content: 'تدبر اليوم',
      );

      expect(note.isAyahNote, isFalse);
      expect(note.title, equals('خاطرة إيمانية'));

      // Update
      final updated = await repository.saveNote(
        id: note.id,
        type: NoteType.free,
        title: 'خاطرة إيمانية معدلة',
        content: 'محتوى جديد',
      );

      expect(updated.title, equals('خاطرة إيمانية معدلة'));
      expect(updated.content, equals('محتوى جديد'));

      // Delete
      await repository.deleteNote(note.id);
      expect(repository.allNotes.isEmpty, isTrue);
    });
  });
}
