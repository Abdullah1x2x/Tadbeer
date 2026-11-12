import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

import '../../data/storage/user_data_store.dart';

/// سبب فشل الاستعادة، لتعرض الواجهة رسالته بلغة القارئ.
enum BackupError { wrongPassword, newerVersion, invalidFile, writeFailed }

/// نتيجة تصدير نسخة احتياطية أو استعادتها.
class BackupResult {
  final bool success;
  final String? filePath;

  /// تفاصيل الفشل بالإنجليزية للسجل، لا للعرض.
  final String? errorMessage;
  final BackupError? error;

  const BackupResult.success(this.filePath)
    : success = true,
      errorMessage = null,
      error = null;

  const BackupResult.failure(
    this.errorMessage, [
    this.error = BackupError.invalidFile,
  ]) : success = false,
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
  static const int defaultKdfIterations = 600000;

  /// أقصى تكرارات تُقبل من رأس الملف، كي لا يعلّق ملف خبيث الاستعادة لدقائق.
  static const int _maxKdfIterations = 5000000;

  /// أقصى حجم لملف النسخة الاحتياطية (32 ميجابايت).
  static const int _maxBackupFileBytes = 32 * 1024 * 1024;

  /// أقصى حجم للبيانات المفكوكة بعد ضغط gzip (64 ميجابايت).
  static const int _maxDecompressedBytes = 64 * 1024 * 1024;

  /// فك ضغط تدريجي مع سقف أقصى للبايتات لمنع استنزاف الذاكرة.
  static List<int> _boundedGzipDecode(List<int> compressed) {
    final builder = BytesBuilder(copy: false);
    var total = 0;
    final chunkSink = ByteConversionSink.withCallback((bytes) {
      total += bytes.length;
      if (total > _maxDecompressedBytes) {
        throw const FormatException('Decompressed backup exceeds maximum allowed size');
      }
      builder.add(bytes);
    });
    final gzipSink = gzip.decoder.startChunkedConversion(chunkSink);
    const chunkSize = 64 * 1024;
    for (var offset = 0; offset < compressed.length; offset += chunkSize) {
      final end = (offset + chunkSize < compressed.length)
          ? offset + chunkSize
          : compressed.length;
      gzipSink.add(compressed.sublist(offset, end));
    }
    gzipSink.close();
    return builder.takeBytes();
  }

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
        tadbeer: tadbeer,
        journey: journey,
      );
      final schemaVersion = UserDataStore.currentSchemaVersion;
      final outPath = await Isolate.run(
        () => _encodeAndWriteBackup(
          snapshot: snapshot,
          password: password,
          schemaVersion: schemaVersion,
          targetPath: targetPath,
        ),
      );
      return BackupResult.success(outPath);
    } catch (e) {
      return BackupResult.failure(e.toString());
    }
  }

  static Future<String> _encodeAndWriteBackup({
    required Map<String, dynamic> snapshot,
    required String password,
    required int schemaVersion,
    required String targetPath,
  }) async {
    final rawPayloadBytes = utf8.encode(jsonEncode(snapshot));
    final compressedBytes = gzip.encode(rawPayloadBytes);

    final salt = _generateRandomBytes(16);
    final ivBytes = _generateRandomBytes(16);
    const iterations = defaultKdfIterations;
    final material = _pbkdf2(
      utf8.encode(password),
      salt,
      iterations,
      64,
    );
    final encKey = Uint8List.sublistView(material, 0, 32);
    final macKey = Uint8List.sublistView(material, 32, 64);
    final iv = enc.IV(ivBytes);

    final encrypter = enc.Encrypter(
      enc.AES(enc.Key(encKey), mode: enc.AESMode.cbc),
    );
    final encrypted = encrypter.encryptBytes(compressedBytes, iv: iv);

    final saltB64 = base64.encode(salt);
    final ivB64 = iv.base64;
    final cipherB64 = encrypted.base64;
    final mac = _computeMac(
      macKey,
      version: formatVersion,
      schemaVersion: schemaVersion,
      iterations: iterations,
      saltB64: saltB64,
      ivB64: ivB64,
      cipherB64: cipherB64,
    );

    final package = {
      'magic': magicHeader,
      'version': formatVersion,
      'schemaVersion': schemaVersion,
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
    return file.path;
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
      if (await file.length() > _maxBackupFileBytes) {
        return const BackupResult.failure('Backup file exceeds maximum allowed size');
      }

      final filePath = file.path;
      const maxSchema = UserDataStore.currentSchemaVersion;
      final decoded = await Isolate.run(
        () => _readAndDecodeBackup(
          filePath: filePath,
          password: password,
          maxSchemaVersion: maxSchema,
        ),
      );
      if (decoded.failure != null) {
        return decoded.failure!;
      }

      // ٧. الاستبدال الذرّي.
      try {
        await UserDataStore.instance.replaceAllUserData(decoded.payload!);
      } on StateError catch (e) {
        return BackupResult.failure(
          'Failed to write restored data: $e',
          BackupError.writeFailed,
        );
      }

      return BackupResult.success(file.path);
    } catch (e) {
      return BackupResult.failure('Failed to restore backup: $e');
    }
  }

  static Future<({Map<String, dynamic>? payload, BackupResult? failure})>
  _readAndDecodeBackup({
    required String filePath,
    required String password,
    required int maxSchemaVersion,
  }) async {
    try {
      final file = File(filePath);
      if (await file.length() > _maxBackupFileBytes) {
        return (
          payload: null,
          failure: const BackupResult.failure('Backup file exceeds maximum allowed size'),
        );
      }
      final content = await file.readAsString();
      final decodedPkg = jsonDecode(content);
      if (decodedPkg is! Map<String, dynamic>) {
        return (
          payload: null,
          failure: const BackupResult.failure('Invalid backup file format'),
        );
      }
      final package = decodedPkg;

      // ١. التحقق من توقيع نوع الملف.
      if (package['magic'] != magicHeader) {
        return (
          payload: null,
          failure: const BackupResult.failure('Invalid backup file format'),
        );
      }

      // ٢. التحقق من توافق إصدار البيانات.
      final rawSchema = package['schemaVersion'];
      if (rawSchema != null && (rawSchema is! num || rawSchema.toInt() < 1)) {
        return (
          payload: null,
          failure: const BackupResult.failure('Invalid backup file format'),
        );
      }
      final schemaVersion = (rawSchema as num?)?.toInt() ?? 0;
      if (schemaVersion > maxSchemaVersion) {
        return (
          payload: null,
          failure: const BackupResult.failure(
            'Backup file was created with a newer version of Tadbeer',
            BackupError.newerVersion,
          ),
        );
      }

      final rawVersion = package['version'];
      if (rawVersion is! num) {
        return (
          payload: null,
          failure: const BackupResult.failure('Invalid backup file format'),
        );
      }
      final fileVersion = rawVersion.toInt();
      if (fileVersion < 1) {
        return (
          payload: null,
          failure: const BackupResult.failure('Invalid backup file format'),
        );
      }
      if (fileVersion > formatVersion) {
        return (
          payload: null,
          failure: const BackupResult.failure(
            'Backup file was created with a newer version of Tadbeer',
            BackupError.newerVersion,
          ),
        );
      }

      final saltB64 = package['salt'];
      final ivB64 = package['iv'];
      final cipherB64 = package['cipher'];
      if (saltB64 is! String || ivB64 is! String || cipherB64 is! String) {
        return (
          payload: null,
          failure: const BackupResult.failure('Invalid backup file format'),
        );
      }
      final salt = Uint8List.fromList(base64.decode(saltB64));
      final iv = enc.IV.fromBase64(ivB64);
      final cipher = enc.Encrypted.fromBase64(cipherB64);

      // ٣. اشتقاق المفتاح (والتحقق من التوقيع في v2) ثم فك التشفير.
      final enc.Key key;
      String? expectedChecksum;
      if (fileVersion >= 2) {
        final rawIterations = package['kdfIterations'];
        if (rawIterations is! num) {
          return (
            payload: null,
            failure: const BackupResult.failure('Invalid backup file format'),
          );
        }
        final iterations = rawIterations.toInt();
        if (iterations < 1 || iterations > _maxKdfIterations) {
          return (
            payload: null,
            failure: const BackupResult.failure('Invalid backup file format'),
          );
        }
        final material = _pbkdf2(utf8.encode(password), salt, iterations, 64);
        final encKey = Uint8List.sublistView(material, 0, 32);
        final macKey = Uint8List.sublistView(material, 32, 64);
        final expectedMac = _computeMac(
          macKey,
          version: fileVersion,
          schemaVersion: schemaVersion,
          iterations: iterations,
          saltB64: saltB64,
          ivB64: ivB64,
          cipherB64: cipherB64,
        );
        final rawMac = package['mac'];
        final actualMac = rawMac is String ? rawMac : '';
        if (!_constantTimeEquals(expectedMac, actualMac)) {
          return (
            payload: null,
            failure: const BackupResult.failure(
              'Incorrect password or corrupt file',
              BackupError.wrongPassword,
            ),
          );
        }
        key = enc.Key(encKey);
      } else {
        key = _deriveKeyV1(password, salt);
        final rawChecksum = package['checksum'];
        expectedChecksum = rawChecksum is String ? rawChecksum : null;
      }
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      List<int> decryptedCompressed;
      try {
        decryptedCompressed = encrypter.decryptBytes(cipher, iv: iv);
      } catch (e) {
        return (
          payload: null,
          failure: const BackupResult.failure(
            'Incorrect password or corrupt file',
            BackupError.wrongPassword,
          ),
        );
      }

      // ٤. فك الضغط.
      List<int> decompressedBytes;
      try {
        decompressedBytes = _boundedGzipDecode(decryptedCompressed);
      } catch (e) {
        return (
          payload: null,
          failure: const BackupResult.failure(
            'Incorrect password or corrupt backup data (decompression failed)',
            BackupError.wrongPassword,
          ),
        );
      }

      // ٥. التحقق من البصمة (v1 فقط؛ التوقيع يغطي v2).
      if (fileVersion < 2) {
        final actualChecksum = sha256.convert(decompressedBytes).toString();
        if (actualChecksum != expectedChecksum) {
          return (
            payload: null,
            failure: const BackupResult.failure(
              'Incorrect password or corrupt file',
              BackupError.wrongPassword,
            ),
          );
        }
      }

      // ٦. قراءة JSON والتحقق من بنيته.
      final payloadDecoded = jsonDecode(utf8.decode(decompressedBytes));
      if (payloadDecoded is! Map<String, dynamic> ||
          payloadDecoded['app'] != 'Tadbeer') {
        return (
          payload: null,
          failure: const BackupResult.failure(
            'Invalid app identifier in backup',
          ),
        );
      }

      return (payload: payloadDecoded, failure: null);
    } catch (e) {
      return (
        payload: null,
        failure: BackupResult.failure('Failed to restore backup: $e'),
      );
    }
  }
}
