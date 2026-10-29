import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

import '../../data/storage/user_data_store.dart';

/// نتيجة تصدير نسخة احتياطية أو استعادتها.
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

/// النسخ الاحتياطية المشفرة (.quranbackup)، على الجهاز فقط دون أي خادم.
///
/// المفتاح يُشتق من كلمة المرور بـ PBKDF2-HMAC-SHA256 وملح عشوائي، بطيئاً عمداً
/// ليصعب تخمينها. البيانات تُضغط بـ gzip، وتُشفّر بـ AES-256-CBC، ثم توقّع بـ
/// HMAC-SHA256 على كل حقول الرأس والنص المشفّر (encrypt-then-MAC)؛ فكلمة مرور
/// خاطئة أو بايت واحد معدّل يُفشل التحقق ولا يُستورد شيء. ودون كلمة مرور يكون
/// الملف مموّهاً لا محمياً، ويسجّل الرأس ذلك في `passwordProtected`.
///
/// الاستعادة تستبدل الأقسام الموجودة في النسخة فقط، وإن كانت النسخة غير صالحة
/// تبقى البيانات الحالية كما هي.
class BackupCryptoService {
  BackupCryptoService._();

  static const String magicHeader = 'TADBEER_BACKUP';

  /// v1: مفتاح SHA-256(كلمة المرور + الملح)، وAES-CBC، وبصمة النص الأصلي في
  /// الرأس؛ يبقى للاستعادة فقط.
  ///
  /// v2: اشتقاق PBKDF2-HMAC-SHA256، وAES-256-CBC مع HMAC-SHA256؛ ولا بصمة للنص
  /// الأصلي في الرأس.
  static const int formatVersion = 2;

  /// تكرارات PBKDF2؛ تُحفظ في الملف ليمكن رفعها مستقبلاً.
  static const int defaultKdfIterations = 100000;

  /// أقصى تكرارات تُقبل من رأس الملف، كي لا يعلّق ملف خبيث الاستعادة لدقائق.
  static const int _maxKdfIterations = 5000000;

  /// بايتات عشوائية آمنة للملح ومتجه التهيئة.
  static Uint8List _generateRandomBytes(int length) {
    final rand = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = rand.nextInt(256);
    }
    return bytes;
  }

  /// PBKDF2-HMAC-SHA256 (RFC 8018)؛ يعيد [length] بايت.
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

  /// يشتق مفتاح التشفير ومفتاح التوقيع (32 بايت لكل منهما) في خيط منفصل، فلا
  /// تتجمد الواجهة.
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

  /// توقيع HMAC على كل حقول الملف المهمة (encrypt-then-MAC).
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

  /// مقارنة بزمن ثابت، فلا يُسرّب التوقيت شيئاً.
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

  /// مفتاح v1 القديم: SHA-256 لكلمة المرور والملح؛ للاستعادة فقط.
  static enc.Key _deriveKeyV1(String password, Uint8List salt) {
    final input = utf8.encode(password) + salt;
    final digest = sha256.convert(input);
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  /// يصدّر نسخة احتياطية مضغوطة ومشفّرة وموقّعة.
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
    bool journey = true,
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
        journey: journey,
      );

      final rawPayloadBytes = utf8.encode(jsonEncode(snapshot));

      // ١. الضغط.
      final compressedBytes = gzip.encode(rawPayloadBytes);

      // ٢. اشتقاق المفتاح بملح عشوائي.
      final salt = _generateRandomBytes(16);
      final ivBytes = _generateRandomBytes(16);
      const iterations = defaultKdfIterations;
      final keys = await _deriveKeysV2(password, salt, iterations);
      final iv = enc.IV(ivBytes);

      // ٣. التشفير ثم التوقيع.
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

      // ٤. تجميع الملف، دون بصمة للنص الأصلي.
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

  /// يتحقق من ملف .quranbackup ثم يستعيده.
  ///
  /// إن كان الملف غير صالح لا يُمس شيء؛ وعند النجاح تُستبدل الأقسام الموجودة
  /// فيه.
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

      // ١. التحقق من توقيع نوع الملف.
      if (package['magic'] != magicHeader) {
        return const BackupResult.failure('Invalid backup file format');
      }

      // ٢. التحقق من توافق إصدار البيانات.
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

      // ٣. اشتقاق المفتاح (والتحقق من التوقيع في v2) ثم فك التشفير.
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
          // كلمة مرور خاطئة أو ملف معدّل أو تالف: لا يُفك شيء.
          return const BackupResult.failure(
            'Incorrect password or corrupt file',
          );
        }
        key = enc.Key(keys.encKey);
      } else {
        // نسخ v1 القديمة.
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

      // ٤. فك الضغط.
      List<int> decompressedBytes;
      try {
        decompressedBytes = gzip.decode(decryptedCompressed);
      } catch (e) {
        return const BackupResult.failure(
          'Incorrect password or corrupt backup data (decompression failed)',
        );
      }

      // ٥. التحقق من البصمة (v1 فقط؛ التوقيع يغطي v2).
      if (fileVersion < 2) {
        final actualChecksum = sha256.convert(decompressedBytes).toString();
        if (actualChecksum != expectedChecksum) {
          return const BackupResult.failure(
            'Checksum mismatch: backup file data is corrupted',
          );
        }
      }

      // ٦. قراءة JSON والتحقق من بنيته.
      final payloadJson =
          jsonDecode(utf8.decode(decompressedBytes)) as Map<String, dynamic>;
      if (payloadJson['app'] != 'Tadbeer') {
        return const BackupResult.failure('Invalid app identifier in backup');
      }

      // ٧. الاستبدال الذرّي.
      await UserDataStore.instance.replaceAllUserData(payloadJson);

      return BackupResult.success(file.path);
    } catch (e) {
      return BackupResult.failure('Failed to restore backup: $e');
    }
  }
}
