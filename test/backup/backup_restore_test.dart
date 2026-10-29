import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/features/backup/backup_crypto_service.dart';
import 'package:tadbeer/data/storage/user_data_store.dart';
import 'package:tadbeer/data/models/bookmark_model.dart';
import 'package:tadbeer/data/models/note_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late File dataFile;
  late File backupFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_backup_test_');
    dataFile = File('${tempDir.path}/user_data.json');
    backupFile = File('${tempDir.path}/test.quranbackup');
    await UserDataStore.instance.init(dataFile);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Encrypted Backup & Restore Tests', () {
    test(
      'Export, Encrypt, and Successful Restore with Full Replacement',
      () async {
        final store = UserDataStore.instance;

        // Seed initial data
        await store.saveReadingPosition(
          page: 50,
          surahNumber: 2,
          ayahNumber: 286,
        );
        await store.saveNote(
          id: 'backup-note-1',
          type: NoteType.free,
          title: 'ملاحظة النسخ الاحتياطي',
          content: 'محتوى النسخ الاحتياطي السري',
        );
        await store.updateSettings(
          store.settings.copyWith(themeMode: ThemeMode.dark),
        );

        // 1. Create encrypted backup
        const password = 'SecretPassword123';
        final exportRes = await BackupCryptoService.createBackupFile(
          targetPath: backupFile.path,
          password: password,
        );
        expect(exportRes.success, isTrue);
        expect(backupFile.existsSync(), isTrue);

        // Verify backup is encrypted and contains required metadata
        final backupContent =
            jsonDecode(backupFile.readAsStringSync()) as Map<String, dynamic>;
        expect(backupContent['magic'], equals(BackupCryptoService.magicHeader));
        expect(backupContent['version'], equals(2));
        expect(backupContent['mac'], isNotNull);
        expect(backupContent['cipher'], isNotNull);
        expect(backupContent['passwordProtected'], isTrue);
        // v2 must not expose a hash of the plaintext data.
        expect(backupContent.containsKey('checksum'), isFalse);

        // 2. Modify local storage to different values (to test complete replacement)
        await store.saveReadingPosition(page: 1, surahNumber: 1, ayahNumber: 1);
        await store.saveNote(
          id: 'new-unrelated-note',
          type: NoteType.free,
          title: 'ملاحظة جديدة يجب أن تُستبدل بالكامل',
          content: 'محتوى جديد',
        );
        await store.updateSettings(
          store.settings.copyWith(themeMode: ThemeMode.light),
        );

        expect(store.notes.length, equals(2));
        expect(store.readingPosition.page, equals(1));
        expect(store.settings.themeMode, equals(ThemeMode.light));

        // 3. Restore from backup
        final restoreRes = await BackupCryptoService.restoreFromFile(
          file: backupFile,
          password: password,
        );
        expect(restoreRes.success, isTrue);

        // Verify that local data was COMPLETELY REPLACED (not merged!)
        expect(store.readingPosition.page, equals(50));
        expect(store.notes.length, equals(1));
        expect(store.notes.first.id, equals('backup-note-1'));
        expect(store.notes.first.title, equals('ملاحظة النسخ الاحتياطي'));
        expect(store.settings.themeMode, equals(ThemeMode.dark));
      },
    );

    test('Incorrect Password Rejects Restore and Imports Nothing', () async {
      final store = UserDataStore.instance;
      await store.saveReadingPosition(page: 10, surahNumber: 2, ayahNumber: 1);

      await BackupCryptoService.createBackupFile(
        targetPath: backupFile.path,
        password: 'CorrectPassword',
      );

      // Try restore with wrong password
      final restoreRes = await BackupCryptoService.restoreFromFile(
        file: backupFile,
        password: 'WrongPassword',
      );

      expect(restoreRes.success, isFalse);
      expect(restoreRes.errorMessage, contains('password'));
    });

    test('Corrupted Backup Rejects Restore and Imports Nothing', () async {
      await BackupCryptoService.createBackupFile(
        targetPath: backupFile.path,
        password: 'Password',
      );

      // Corrupt the cipher text in the backup file
      final json =
          jsonDecode(backupFile.readAsStringSync()) as Map<String, dynamic>;
      json['cipher'] = base64Encode(utf8.encode('corrupted data'));
      backupFile.writeAsStringSync(jsonEncode(json));

      final restoreRes = await BackupCryptoService.restoreFromFile(
        file: backupFile,
        password: 'Password',
      );

      expect(restoreRes.success, isFalse);
    });

    test(
      'Partial backup restore keeps sections that were not exported',
      () async {
        final store = UserDataStore.instance;
        await store.saveNote(
          id: 'keep-me',
          type: NoteType.free,
          title: 'ملاحظة يجب أن تبقى',
          content: 'لا تُحذف عند استعادة نسخة بلا ملاحظات',
        );
        await store.putBookmark(
          BookmarkItem(
            id: 'bm-in-backup',
            ayahId: 1,
            surahNumber: 1,
            ayahNumber: 1,
            page: 1,
            createdAt: DateTime(2026, 1, 1),
          ),
        );

        // Export WITHOUT notes.
        final exportRes = await BackupCryptoService.createBackupFile(
          targetPath: backupFile.path,
          password: 'pw',
          notes: false,
        );
        expect(exportRes.success, isTrue);

        final restoreRes = await BackupCryptoService.restoreFromFile(
          file: backupFile,
          password: 'pw',
        );
        expect(restoreRes.success, isTrue);

        // Notes were not in the backup -> must still be there.
        expect(store.notes.map((n) => n.id), contains('keep-me'));
        expect(store.bookmarks.map((b) => b.id), contains('bm-in-backup'));
      },
    );

    test('Tampered v2 backup is rejected by the MAC check', () async {
      await BackupCryptoService.createBackupFile(
        targetPath: backupFile.path,
        password: 'pw',
      );
      final json =
          jsonDecode(backupFile.readAsStringSync()) as Map<String, dynamic>;
      json['schemaVersion'] = 0; // header tampering must also be detected
      backupFile.writeAsStringSync(jsonEncode(json));

      final restoreRes = await BackupCryptoService.restoreFromFile(
        file: backupFile,
        password: 'pw',
      );
      expect(restoreRes.success, isFalse);
    });

    test('Legacy v1 backups can still be restored', () async {
      final store = UserDataStore.instance;
      const password = 'old-password';
      final payload = utf8.encode(
        jsonEncode({
          'app': 'Tadbeer',
          'schemaVersion': 1,
          'notes': [
            NoteItem(
              id: 'legacy-note',
              type: NoteType.free,
              content: 'من نسخة قديمة',
              createdAt: DateTime(2025, 1, 1),
              updatedAt: DateTime(2025, 1, 1),
            ).toJson(),
          ],
        }),
      );
      final salt = Uint8List.fromList(List<int>.generate(16, (i) => i));
      final ivBytes = Uint8List.fromList(
        List<int>.generate(16, (i) => 100 + i),
      );
      final key = enc.Key(
        Uint8List.fromList(sha256.convert(utf8.encode(password) + salt).bytes),
      );
      final cipher = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc))
          .encryptBytes(gzip.encode(payload), iv: enc.IV(ivBytes));
      backupFile.writeAsStringSync(
        jsonEncode({
          'magic': BackupCryptoService.magicHeader,
          'version': 1,
          'schemaVersion': 1,
          'salt': base64.encode(salt),
          'iv': base64.encode(ivBytes),
          'checksum': sha256.convert(payload).toString(),
          'createdAt': DateTime(2025, 1, 1).toIso8601String(),
          'cipher': cipher.base64,
        }),
      );

      final restoreRes = await BackupCryptoService.restoreFromFile(
        file: backupFile,
        password: password,
      );
      expect(restoreRes.success, isTrue);
      expect(store.notes.map((n) => n.id), contains('legacy-note'));
    });
  });
}
