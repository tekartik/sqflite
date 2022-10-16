import 'dart:io';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi/src/windows/setup.dart';

import 'database_factory_ffi_io.dart';

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

/// Creates an FFI database factory.
/// Optionally the FFIInit function can be provided if you want to override
/// some behavior with the sqlite3 dynamic library opening. This function should
/// be either a top level function or a static function.
/// Prefer the use of the [databaseFactoryFfi] getter if you don't need this functionality.
///
/// Example for overriding the sqlite library in Windows by providing a custom path.
///
/// ```dart
/// import 'package:sqlite3/open.dart';
///
/// void ffiInit() {
///   open.overrideFor(
///     OperatingSystem.windows,
///     () => DynamicLibrary.open('path/to/bundled/sqlite.dll'),
///   );
/// }
///
/// Future<void> main() async {
///   final dbFactory = createDatabaseFactoryFfi(ffiInit: ffiInit);
///   final db = await dbFactory.openDatabase(inMemoryDatabasePath);
///   ...
/// }
/// ```
DatabaseFactory createDatabaseFactoryFfi(
    {SqfliteFfiInit? ffiInit, bool noIsolate = false}) {
  return createDatabaseFactoryFfiImpl(ffiInit: ffiInit, noIsolate: noIsolate);
}
