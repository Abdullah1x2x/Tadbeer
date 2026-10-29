import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tadbeer/data/storage/user_database.dart';

void main() {
  late Directory tempDir;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tadbeer_migration_');
  });

  tearDown(() async {
    await UserDatabase.instance.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test(
    'upgrading a version 1 database adds app_state and keeps data',
    () async {
      final path = '${tempDir.path}/user.db';

      // A database as shipped before app_state existed.
      final v1 = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) async {
            await db.execute(
              'CREATE TABLE user_settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
            );
            await db.insert('user_settings', {
              'key': 'themeMode',
              'value': '"dark"',
            });
            await db.execute(
              'CREATE TABLE notes (id TEXT PRIMARY KEY, surah_number INTEGER, ayah_number INTEGER)',
            );
            await db.execute(
              'CREATE TABLE bookmarks (id TEXT PRIMARY KEY, surah_number INTEGER, ayah_number INTEGER)',
            );
            await db.execute(
              'CREATE TABLE highlights (id TEXT PRIMARY KEY, surah_number INTEGER, ayah_number INTEGER)',
            );
            await db.execute(
              'CREATE TABLE tadbeer_items (id TEXT PRIMARY KEY, surah_number INTEGER, ayah_number INTEGER)',
            );
          },
        ),
      );
      await v1.close();

      final db = UserDatabase.instance;
      await db.init(path);
      expect(db.isOpen, isTrue);

      await db.saveAppState('probe', {'ok': true});
      expect(await db.loadAppState('probe'), {'ok': true});

      final settings = await db.db.query('user_settings');
      expect(settings.single['key'], 'themeMode');
    },
  );
}
