import 'dart:async';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Tests run on the desktop, where the sqflite plugin is not available.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await testMain();
}
