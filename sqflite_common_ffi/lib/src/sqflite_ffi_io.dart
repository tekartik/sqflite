import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi/src/windows/setup.dart';

import 'database_factory_ffi_io.dart';

/// The sqflite database factory using ffi (`package:sqlite3`).
///
/// Works on Windows, Linux and macOS (Flutter and Dart VM), also on Android
/// and iOS. SQLite is bundled with the application by `package:sqlite3` build
/// hooks (run with `dart run`, `dart test`, `flutter run`...). Database calls
/// run in a background isolate.
///
/// Call [sqfliteFfiInit] first. Use the factory directly:
///
/// ```dart
/// sqfliteFfiInit();
/// var db = await databaseFactoryFfi.openDatabase(
///   inMemoryDatabasePath,
///   options: OpenDatabaseOptions(
///     version: 1,
///     onCreate: (db, version) =>
///         db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)'),
///   ),
/// );
/// ```
///
/// or set it as the global factory used by `openDatabase()` (existing sqflite
/// code, unit tests), once, before opening any database:
///
/// ```dart
/// sqfliteFfiInit();
/// databaseFactory = databaseFactoryFfi;
/// ```
///
/// `getDatabasesPath()` returns `.dart_tool/sqflite_common_ffi/databases` in
/// the current directory: use absolute paths in an application.
///
/// Not supported on the web, use `databaseFactoryFfiWeb` from the
/// `sqflite_common_ffi_web` package.
DatabaseFactory get databaseFactoryFfi => databaseFactoryFfiImpl;

/// The database factory to use for ffi without isolate
///
/// SQLite runs in the calling isolate. Use it in Flutter widget tests
/// (`testWidgets`) or from a background isolate you already own; in the main
/// isolate of an application, a long query blocks the UI.
///
/// Currently supports Win/Mac/Linux.
DatabaseFactory get databaseFactoryFfiNoIsolate =>
    databaseFactoryFfiNoIsolateImpl;

/// Initialize ffi loader, call it once before using [databaseFactoryFfi].
///
/// Call in main (or in `setUpAll` in tests) until you find a loader for your
/// needs.
///
/// Currently this only performs windows specific operations (loading SQLite
/// in the main isolate), it does nothing on other platforms and on the web so
/// it is safe to call everywhere. Implementation is provided for reference
/// only.
void sqfliteFfiInit() {
  if (Platform.isWindows) {
    windowsInit();
  }
}

/// Creates an FFI database factory.
/// Optionally the [ffiInit] function can be provided to run some code before
/// SQLite is used (in the sqflite isolate, or in the calling isolate when
/// [noIsolate] is true). This function should
/// be either a top level function or a static function.
/// Prefer the use of the [databaseFactoryFfi] getter if you don't need this functionality.
///
/// With `package:sqlite3` 3.x (`sqflite_common_ffi` 2.4.0 and later), the
/// SQLite library is not chosen in [ffiInit] but with build hooks options in
/// the application `pubspec.yaml`, for example to use the system library:
///
/// ```yaml
/// hooks:
///   user_defines:
///     sqlite3:
///       source: system
/// ```
///
/// (`package:sqlite3/open.dart` used in [ffiInit] with `sqlite3` v2 no longer
/// exists.)
///
/// ```dart
/// void ffiInit() {
///   // Called before SQLite is used.
/// }
///
/// Future<void> main() async {
///   final dbFactory = createDatabaseFactoryFfi(ffiInit: ffiInit);
///   final db = await dbFactory.openDatabase(inMemoryDatabasePath);
///   // ...
/// }
/// ```
///
/// If [isolatePortServer] is provided (not supported on the web), it is used
/// to share the sqflite isolate between isolates, typically using Flutter
/// `IsolateNameServer` (see the `sqflite_ffi` package).
DatabaseFactory createDatabaseFactoryFfi({
  SqfliteFfiInit? ffiInit,
  bool noIsolate = false,
  SqfliteFfiIsolatePortServer? isolatePortServer,
}) {
  return createDatabaseFactoryFfiImpl(
    ffiInit: ffiInit,
    noIsolate: noIsolate,
    isolatePortServer: isolatePortServer,
  );
}
