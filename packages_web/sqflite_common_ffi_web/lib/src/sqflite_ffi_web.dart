import 'package:sqflite_common/sqlite_api.dart';

import 'database_factory_web.dart';

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
/// Web only.
DatabaseFactory get databaseFactoryFfiWeb => databaseFactoryFfiWebImpl;

/// The database factory to use for ffi web without web worker.
///
/// Only `sqlite3.wasm` is needed (no `sqflite_sw.js`).
///
/// Run in the main ui thread so long query could potentially hang. Not safe
/// when several tabs use the same database.
DatabaseFactory get databaseFactoryFfiWebNoWebWorker =>
    databaseFactoryFfiWebNoWebWorkerImpl;

/// Testing only.
DatabaseFactory get databaseFactoryFfiWebBasicWebWorker =>
    databaseFactoryFfiWebBasicWorkerImpl;
