import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

import '../storage/user_data_store.dart';

/// Represents the outcome of a backup export or restore operation.
class BackupResult {
  final bool success;
  final String? filePath;
  final String? errorMessage;

  const BackupResult.success(this.filePath)
    : success = true,
      errorMessage = null;

  const BackupResult.failure(this.errorMessage)
    : success = false,
      filePath = null;
}

/// Service handling encrypted, compressed, and authenticated backups (.quranbackup).
///
/// EDUCATIONAL NOTE:
/// 1. Backups are entirely offline and user-managed (no cloud, no server).
/// 2. The key is derived from the password with PBKDF2-HMAC-SHA256 and a
///    random salt (slow on purpose, so guessing passwords is expensive).
/// 3. Data is gzip-compressed, encrypted with AES-256-CBC, then authenticated
///    with HMAC-SHA256 over every header field and the ciphertext
///    (encrypt-then-MAC). A wrong password or a single changed byte fails the
///    MAC check and NOTHING is imported.
/// 4. Without a password the file is only obfuscated, not protected: anyone
///    with Tadbeer can open it. The header records this as `passwordProtected`.
///
/// IMPORTANT INVARIANT:
/// Restore replaces the sections contained in the backup. Sections that were
/// not exported are left untouched. If the backup is invalid, current user
/// data remains 100% untouched.
class BackupCryptoService {
  BackupCryptoService._();

  static const String magicHeader = 'TADBEER_BACKUP';

  /// v1: SHA-256(password + salt) key, AES-CBC, plaintext checksum in header.
  ///     Kept for RESTORE ONLY so older backups still open.
  /// v2: PBKDF2-HMAC-SHA256 key derivation, AES-256-CBC + HMAC-SHA256
  ///     (encrypt-then-MAC). No plaintext data hash is exposed in the header.
  static const int formatVersion = 2;

  /// عدد تكرارات PBKDF2 (يُحفظ داخل الملف ليمكن رفعه مستقبلاً).
  static const int defaultKdfIterations = 100000;

  /// Upper bound accepted from a file header, to avoid hostile files
  /// making restore hang for minutes.
  static const int _maxKdfIterations = 5000000;

  /// توليد سلسلة بايتات عشوائية آمنة تشفيرياً لاستخدامها في التمليح (Salt) ومتجه التهيئة (IV).
  static Uint8List _generateRandomBytes(int length) {
    final rand = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = rand.nextInt(256);
    }
    return bytes;
  }

  /// PBKDF2-HMAC-SHA256 (RFC 8018) — returns [length] bytes.
  static Uint8List _pbkdf2(
    List<int> password,
    List<int> salt,
    int iterations,
    int length,
  ) {
    final hmac = Hmac(sha256, password);
    final out = BytesBuilder(copy: false);
    var block = 1;
    while (out.length < length) {
      final blockIndex = Uint8List(4)
        ..[0] = (block >> 24) & 0xff
        ..[1] = (block >> 16) & 0xff
        ..[2] = (block >> 8) & 0xff
        ..[3] = block & 0xff;
      var u = hmac.convert([...salt, ...blockIndex]).bytes;
      final t = Uint8List.fromList(u);
      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      out.add(t);
      block++;
    }
    return Uint8List.sublistView(out.takeBytes(), 0, length);
  }

  /// يشتق مفتاح تشفير (32 بايت) ومفتاح توقيع HMAC (32 بايت) في خيط منفصل
  /// حتى لا تتجمد الواجهة أثناء الحساب.
  static Future<({Uint8List encKey, Uint8List macKey})> _deriveKeysV2(
    String password,
    Uint8List salt,
    int iterations,
  ) async {
    final pw = utf8.encode(password);
    final saltCopy = Uint8List.fromList(salt);
    final material = await Isolate.run(
      () => _pbkdf2(pw, saltCopy, iterations, 64),
    );
    return (
      encKey: Uint8List.sublistView(material, 0, 32),
      macKey: Uint8List.sublistView(material, 32, 64),
    );
  }

  /// يحسب توقيع HMAC على كل حقول الملف الحساسة (encrypt-then-MAC).
  static String _computeMac(
    Uint8List macKey, {
    required int version,
    required int schemaVersion,
    required int iterations,
    required String saltB64,
    required String ivB64,
    required String cipherB64,
  }) {
    final message = utf8.encode(
      '$magicHeader|$version|$schemaVersion|$iterations|$saltB64|$ivB64|$cipherB64',
    );
    return base64.encode(Hmac(sha256, macKey).convert(message).bytes);
  }

  /// مقارنة بزمن ثابت لتجنب تسريب معلومات عبر التوقيت.
  static bool _constantTimeEquals(String a, String b) {
    final x = utf8.encode(a);
    final y = utf8.encode(b);
    if (x.length != y.length) return false;
    var diff = 0;
    for (var i = 0; i < x.length; i++) {
      diff |= x[i] ^ y[i];
    }
    return diff == 0;
  }

  /// (v1 legacy) اشتقاق مفتاح تشفير AES-256 من كلمة المرور والملح عبر SHA-256.
  /// يُستخدم فقط لاستعادة النسخ القديمة.
  static enc.Key _deriveKeyV1(String password, Uint8List salt) {
    // Key derivation using SHA-256(password + salt)
    final input = utf8.encode(password) + salt;
    final digest = sha256.convert(input);
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  /// Exports an encrypted, compressed, versioned, and checksummed backup file.
  static Future<BackupResult> createBackupFile({
    required String targetPath,
    String password = '',
    bool notes = true,
    bool bookmarks = true,
    bool highlights = true,
    bool settings = true,
    bool reminders = true,
    bool ayahLinks = true,
    bool tadbeer = true,
    bool? tadabbur,
  }) async {
    try {
      final snapshot = UserDataStore.instance.exportSnapshot(
        notes: notes,
        bookmarks: bookmarks,
        highlights: highlights,
        settings: settings,
        reminders: reminders,
        ayahLinks: ayahLinks,
        tadbeer: tadabbur ?? tadbeer,
      );

      final rawPayloadBytes = utf8.encode(jsonEncode(snapshot));

      // 1. Gzip compression (reduces backup file size significantly)
      final compressedBytes = gzip.encode(rawPayloadBytes);

      // 2. Key derivation (PBKDF2-HMAC-SHA256, random salt)
      final salt = _generateRandomBytes(16);
      final ivBytes = _generateRandomBytes(16);
      const iterations = defaultKdfIterations;
      final keys = await _deriveKeysV2(password, salt, iterations);
      final iv = enc.IV(ivBytes);

      // 3. Encryption (AES-256-CBC) then authentication (HMAC-SHA256)
      final encrypter = enc.Encrypter(
        enc.AES(enc.Key(keys.encKey), mode: enc.AESMode.cbc),
      );
      final encrypted = encrypter.encryptBytes(compressedBytes, iv: iv);

      final saltB64 = base64.encode(salt);
      final ivB64 = iv.base64;
      final cipherB64 = encrypted.base64;
      final mac = _computeMac(
        keys.macKey,
        version: formatVersion,
        schemaVersion: UserDataStore.currentSchemaVersion,
        iterations: iterations,
        saltB64: saltB64,
        ivB64: ivB64,
        cipherB64: cipherB64,
      );

      // 4. Assemble container package (no plaintext data hash exposed)
      final package = {
        'magic': magicHeader,
        'version': formatVersion,
        'schemaVersion': UserDataStore.currentSchemaVersion,
        'kdf': 'pbkdf2-hmac-sha256',
        'kdfIterations': iterations,
        'passwordProtected': password.isNotEmpty,
        'salt': saltB64,
        'iv': ivB64,
        'mac': mac,
        'createdAt': DateTime.now().toIso8601String(),
        'cipher': cipherB64,
      };

      final file = File(targetPath);
      await file.writeAsString(jsonEncode(package), flush: true);

      return BackupResult.success(file.path);
    } catch (e) {
      return BackupResult.failure(e.toString());
    }
  }

  /// Validates and restores user data from a .quranbackup file.
  ///
  /// IMPORTANT:
  /// If file is invalid or corrupt, NO data is touched.
  /// Upon success, current data is COMPLETELY REPLACED.
  static Future<BackupResult> restoreFromFile({
    required File file,
    String password = '',
  }) async {
    try {
      if (!await file.exists()) {
        return const BackupResult.failure('Backup file not found');
      }

      final content = await file.readAsString();
      final package = jsonDecode(content) as Map<String, dynamic>;

      // 1. Verify magic header
      if (package['magic'] != magicHeader) {
        return const BackupResult.failure('Invalid backup file format');
      }

      // 2. Verify schema version compatibility
      final schemaVersion = package['schemaVersion'] as int? ?? 0;
      if (schemaVersion > UserDataStore.currentSchemaVersion) {
        return const BackupResult.failure(
          'Backup file was created with a newer version of Tadbeer',
        );
      }

      final fileVersion = package['version'] as int? ?? 1;
      if (fileVersion > formatVersion) {
        return const BackupResult.failure(
          'Backup file was created with a newer version of Tadbeer',
        );
      }

      final saltB64 = package['salt'] as String;
      final ivB64 = package['iv'] as String;
      final cipherB64 = package['cipher'] as String;
      final salt = Uint8List.fromList(base64.decode(saltB64));
      final iv = enc.IV.fromBase64(ivB64);
      final cipher = enc.Encrypted.fromBase64(cipherB64);

      // 3. Derive key (and verify authenticity for v2) then decrypt
      final enc.Key key;
      String? expectedChecksum;
      if (fileVersion >= 2) {
        final iterations = package['kdfIterations'] as int? ?? 0;
        if (iterations < 1 || iterations > _maxKdfIterations) {
          return const BackupResult.failure('Invalid backup file format');
        }
        final keys = await _deriveKeysV2(password, salt, iterations);
        final expectedMac = _computeMac(
          keys.macKey,
          version: fileVersion,
          schemaVersion: schemaVersion,
          iterations: iterations,
          saltB64: saltB64,
          ivB64: ivB64,
          cipherB64: cipherB64,
        );
        final actualMac = package['mac'] as String? ?? '';
        if (!_constantTimeEquals(expectedMac, actualMac)) {
          // Wrong password or tampered/corrupt file: nothing is decrypted.
          return const BackupResult.failure(
            'Incorrect password or corrupt file',
          );
        }
        key = enc.Key(keys.encKey);
      } else {
        // Legacy v1 backups
        key = _deriveKeyV1(password, salt);
        expectedChecksum = package['checksum'] as String?;
      }
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      List<int> decryptedCompressed;
      try {
        decryptedCompressed = encrypter.decryptBytes(cipher, iv: iv);
      } catch (e) {
        return const BackupResult.failure('Incorrect password or corrupt file');
      }

      // 4. Decompress
      List<int> decompressedBytes;
      try {
        decompressedBytes = gzip.decode(decryptedCompressed);
      } catch (e) {
        return const BackupResult.failure(
          'Incorrect password or corrupt backup data (decompression failed)',
        );
      }

      // 5. Integrity Checksum Verification (v1 only; v2 is covered by the MAC)
      if (fileVersion < 2) {
        final actualChecksum = sha256.convert(decompressedBytes).toString();
        if (actualChecksum != expectedChecksum) {
          return const BackupResult.failure(
            'Checksum mismatch: backup file data is corrupted',
          );
        }
      }

      // 6. Parse and Validate JSON structure
      final payloadJson =
          jsonDecode(utf8.decode(decompressedBytes)) as Map<String, dynamic>;
      if (payloadJson['app'] != 'Tadbeer') {
        return const BackupResult.failure('Invalid app identifier in backup');
      }

      // 7. Atomic complete replacement
      await UserDataStore.instance.replaceAllUserData(payloadJson);

      return BackupResult.success(file.path);
    } catch (e) {
      return BackupResult.failure('Failed to restore backup: $e');
    }
  }
}
