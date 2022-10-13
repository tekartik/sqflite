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

/// The database factory to use for ffi without isolate
///
/// Check support documentation.
///
/// Currently supports Win/Mac/Linux.
DatabaseFactory get databaseFactoryFfiNoIsolate =>
    databaseFactoryFfiNoIsolateImpl;

/// Optional. Initialize ffi loader.
///
/// Call in main until you find a loader for your needs.
///
/// Currently this only performs windows specific operations. Implementation
/// is provided for reference only.
void sqfliteFfiInit() {
  if (Platform.isWindows) {
    windowsInit();
  }
}
