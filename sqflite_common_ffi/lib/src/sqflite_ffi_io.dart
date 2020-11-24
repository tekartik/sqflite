import 'dart:io';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/src/database_factory_ffi.dart';
import 'package:sqflite_common_ffi/src/windows/setup.dart';

/// The database factory to use for ffi.
///
/// Check support documentation.
///
/// Currently supports Win/Mac/Linux.
DatabaseFactory get databaseFactoryFfi => databaseFactoryFfiImpl;

DatabaseFactory createDatabaseFactoryFfi({void Function() ffiInit}) => createDatabaseFactoryFfiImpl(ffiInit: ffiInit);

/// Optional. Initialize ffi loader.
///
/// Call in main until you find a loader for your needs.
void sqfliteFfiInit() {
  if (Platform.isWindows) {
    windowsInit();
  }
}
