import 'package:sqflite_common/sqlite_api.dart';

/// The sqflite database factory for the web, using `package:sqlite3`
/// compiled to WebAssembly.
///
/// SQLite runs in a shared worker (a basic web worker when shared workers
/// are not available) and the databases are stored in IndexedDB.
///
/// It requires 2 files in the web folder, created by
/// `dart run sqflite_common_ffi_web:setup`: `sqlite3.wasm` and
/// `sqflite_sw.js`.
///
/// A database path is only a name (for example `my_db.db`). Use the factory
/// directly or set it as the global factory used by `openDatabase()`, once,
/// before opening any database:
///
/// ```dart
/// if (kIsWeb) {
///   databaseFactory = databaseFactoryFfiWeb;
/// }
/// var db = await openDatabase('my_db.db');
/// ```
///
/// `singleInstance: false` is not supported for a persistent database.
///
/// Web only: throws [UnsupportedError] on io (Android, iOS, desktop, Dart
/// VM), use `sqflite` or `sqflite_common_ffi` there.
DatabaseFactory get databaseFactoryFfiWeb =>
    throw UnsupportedError(_webOnlyMessage('databaseFactoryFfiWeb'));

/// The database factory to use for ffi web without web worker.
///
/// Web only: throws [UnsupportedError] on io.
DatabaseFactory get databaseFactoryFfiWebNoWebWorker =>
    throw UnsupportedError(_webOnlyMessage('databaseFactoryFfiWebNoWebWorker'));

/// The database factory to use for ffi web with a basic web worker.
///
/// Testing only. Web only: throws [UnsupportedError] on io.
DatabaseFactory get databaseFactoryFfiWebBasicWebWorker =>
    throw UnsupportedError(
      _webOnlyMessage('databaseFactoryFfiWebBasicWebWorker'),
    );

String _webOnlyMessage(String name) =>
    '$name is only supported on the web, use the sqflite plugin '
    '(Android, iOS, macOS) or databaseFactoryFfi from sqflite_common_ffi '
    '(desktop, Dart VM) here';
