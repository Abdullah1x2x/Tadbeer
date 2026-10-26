import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/core/storage/user_data_store.dart';
import 'package:tadbeer/features/notes/note_model.dart';
import 'package:tadbeer/features/tadbeer/tadbeer_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late File dataFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_test_');
    dataFile = File('${tempDir.path}/test_user_data.json');
    await UserDataStore.instance.init(dataFile);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('TadbeerItem Model Tests', () {
    test('Has four general questions, each with its answer key', () {
      expect(TadbeerItem.questions, [
        'أيّ كلمة أو عبارة توقّفت عندها؟',
        'ماذا تقول لك هذه الآية؟',
        'ماذا حرّكت فيك؟',
        'ما الذي ستفعله بها اليوم؟',
      ]);
      expect(TadbeerItem.questionKeys, [1, 2, 5, 3]);
    });

    test('An answer to the retired question joins what the ayah says', () {
      final now = DateTime(2026);
      Map<String, dynamic> saved(Map<String, String> answers) => {
        'id': 'x',
        'surahNumber': 3,
        'ayahNumber': 102,
        'answers': answers,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };
      final both = TadbeerItem.fromJson(
        saved({'1': 'أ', '2': 'فهم', '3': 'عمل', '4': 'صلة'}),
      );
      expect(both.answers, {1: 'أ', 2: 'فهم\nصلة', 3: 'عمل'});
      final onlyOld = TadbeerItem.fromJson(saved({'4': 'صلة'}));
      expect(onlyOld.answers, {2: 'صلة'});
    });

    test('combinedSummary joins only non-empty answers in question order', () {
      final item = TadbeerItem(
        id: 'tadbeer-1',
        surahNumber: 2,
        ayahNumber: 153,
        answers: {
          1: 'عظمة الصبر والصلاة في مواجهة المحن',
          2: '   ', // whitespace only - should be excluded
          3: 'المحافظة على الصلاة في أوقاتها والاستعانة بها',
        },
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(
        item.combinedSummary,
        equals(
          'عظمة الصبر والصلاة في مواجهة المحن\nالمحافظة على الصلاة في أوقاتها والاستعانة بها',
        ),
      );
    });

    test(
      'toJson and fromJson preserve all fields and integer question keys',
      () {
        final now = DateTime.now();
        final original = TadbeerItem(
          id: 'test-uuid',
          surahNumber: 3,
          ayahNumber: 102,
          ayahId: 395,
          answers: {
            1: 'تقوى الله حق تقاته',
            4: 'صلتها بما قبلها من التحذير من أهل الكتاب',
          },
          createdAt: now,
          updatedAt: now,
        );

        final json = original.toJson();
        final restored = TadbeerItem.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.surahNumber, equals(3));
        expect(restored.ayahNumber, equals(102));
        expect(restored.ayahId, equals(395));
        expect(restored.ayahKey, equals('3:102'));
        expect(restored.answers[1], equals('تقوى الله حق تقاته'));
        // The retired fourth question now sits with what the ayah says.
        expect(
          restored.answers[2],
          equals('صلتها بما قبلها من التحذير من أهل الكتاب'),
        );
        expect(restored.answers.containsKey(4), isFalse);
      },
    );
  });

  group('UserDataStore Tadbeer Pause (وقفة تدبر) Persistence Tests', () {
    test(
      'Saving mid-way stores only non-empty answers and ignores blanks',
      () async {
        await UserDataStore.instance.saveTadbeer(
          surahNumber: 2,
          ayahNumber: 255,
          ayahId: 262,
          answers: {
            1: 'آية الكرسي هي أعظم آية',
            2: '',
            3: '  ',
            4: 'كمال القيومية والعلم المحيط',
          },
        );

        final item = UserDataStore.instance.getTadbeer(2, 255);
        expect(item, isNotNull);
        expect(item!.surahNumber, equals(2));
        expect(item.ayahNumber, equals(255));
        expect(item.ayahId, equals(262));
        expect(item.answers.length, equals(2));
        expect(item.answers[1], equals('آية الكرسي هي أعظم آية'));
        expect(item.answers[4], equals('كمال القيومية والعلم المحيط'));
        expect(item.answers.containsKey(2), isFalse);
        expect(item.answers.containsKey(3), isFalse);
      },
    );

    test(
      'Never saves empty responses if user skips or submits empty answers',
      () async {
        await UserDataStore.instance.saveTadbeer(
          surahNumber: 1,
          ayahNumber: 1,
          answers: {1: '', 2: '   ', 3: '', 4: '\n'},
        );

        final item = UserDataStore.instance.getTadbeer(1, 1);
        expect(item, isNull);
      },
    );

    test('Retrieving by stable ayah ID returns populated answers across app re-visits', () async {
      await UserDataStore.instance.saveTadbeer(
        surahNumber: 18,
        ayahNumber: 10,
        answers: {
          1: 'دعاء الفتية بالرحمة والرشد',
          2: 'الالتجاء إلى الله عند اشتداد الفتن',
        },
      );

      // Re-read from disk by creating a new UserDataStore instance
      await UserDataStore.instance.init(dataFile);

      final retrieved = UserDataStore.instance.getTadbeer(18, 10);
      expect(retrieved, isNotNull);
      expect(retrieved!.answers[1], equals('دعاء الفتية بالرحمة والرشد'));
      expect(
        retrieved.answers[2],
        equals('الالتجاء إلى الله عند اشتداد الفتن'),
      );
    });

    test(
      'Clearing all answers for an existing record deletes it completely',
      () async {
        await UserDataStore.instance.saveTadbeer(
          surahNumber: 36,
          ayahNumber: 58,
          answers: {1: 'سلام قولاً من رب رحيم'},
        );
        expect(UserDataStore.instance.getTadbeer(36, 58), isNotNull);

        // Save again with only blank answers
        await UserDataStore.instance.saveTadbeer(
          surahNumber: 36,
          ayahNumber: 58,
          answers: {1: '   '},
        );

        expect(UserDataStore.instance.getTadbeer(36, 58), isNull);
      },
    );

    test('deleteTadbeer explicitly removes the pause record', () async {
      await UserDataStore.instance.saveTadbeer(
        surahNumber: 112,
        ayahNumber: 1,
        answers: {1: 'التوحيد الخالص لله وحده'},
      );
      expect(UserDataStore.instance.getTadbeer(112, 1), isNotNull);

      await UserDataStore.instance.deleteTadbeer(112, 1);
      expect(UserDataStore.instance.getTadbeer(112, 1), isNull);
    });

    test(
      'getReflectionForAyah resolves Note first, then Tadbeer combined summary',
      () async {
        // 1. Initially neither exists
        expect(UserDataStore.instance.getReflectionForAyah(55, 13), isNull);

        // 2. Add Tadbeer pause
        await UserDataStore.instance.saveTadbeer(
          surahNumber: 55,
          ayahNumber: 13,
          answers: {1: 'فبأي آلاء ربكما تكذبان', 3: 'شكر النعم وعدم إنكارها'},
        );

        expect(
          UserDataStore.instance.getReflectionForAyah(55, 13),
          equals('فبأي آلاء ربكما تكذبان\nشكر النعم وعدم إنكارها'),
        );

        // 3. Add explicit Ayah Note; Note takes priority
        final note = NoteItem(
          id: 'note-55-13',
          title: 'وقفة شكر',
          content: 'ملاحظة خاصة على آلاء الله ونعمه',
          type: NoteType.ayah,
          surahNumber: 55,
          ayahNumber: 13,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await UserDataStore.instance.putNote(note);

        expect(
          UserDataStore.instance.getReflectionForAyah(55, 13),
          equals('ملاحظة خاصة على آلاء الله ونعمه'),
        );
      },
    );

    test(
      'Snapshot export includes Tadbeer and restore replaces completely',
      () async {
        await UserDataStore.instance.saveTadbeer(
          surahNumber: 67,
          ayahNumber: 2,
          answers: {1: 'الذي خلق الموت والحياة ليبلوكم أيكم أحسن عملاً'},
        );

        final snapshot = UserDataStore.instance.exportSnapshot();
        expect(
          snapshot.containsKey('tadbeer') || snapshot.containsKey('tadabbur'),
          isTrue,
        );
        final list = (snapshot['tadbeer'] ?? snapshot['tadabbur']) as List;
        expect(list.length, equals(1));
        expect((list.first as Map)['ayahNumber'], equals(2));

        // Reset data
        await UserDataStore.instance.resetAllData();
        expect(UserDataStore.instance.getTadbeer(67, 2), isNull);

        // Restore snapshot
        await UserDataStore.instance.replaceAllUserData(snapshot);
        expect(UserDataStore.instance.getTadbeer(67, 2), isNotNull);
        expect(
          UserDataStore.instance.getTadbeer(67, 2)!.answers[1],
          equals('الذي خلق الموت والحياة ليبلوكم أيكم أحسن عملاً'),
        );
      },
    );
  });
}
