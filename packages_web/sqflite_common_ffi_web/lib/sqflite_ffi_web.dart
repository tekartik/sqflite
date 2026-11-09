/// sqflite on the web: SQLite compiled to WebAssembly, databases stored in
/// IndexedDB.
///
/// Run `dart run sqflite_common_ffi_web:setup` once to create
/// `web/sqlite3.wasm` and `web/sqflite_sw.js`, then use
/// [databaseFactoryFfiWeb] (or set it as the global `databaseFactory` of
/// sqflite when `kIsWeb`):
///
/// ```dart
/// var db = await databaseFactoryFfiWeb.openDatabase('my_db.db');
/// ```
///
/// The `Database` API comes from `package:sqflite_common/sqlite_api.dart`
/// (or `package:sqflite/sqflite.dart`).
library;

export 'src/database_factory.dart' show createDatabaseFactoryFfiWeb;
export 'src/debug/debug.dart' show sqliteFfiWebDebugWebWorker;
export 'src/sqflite_ffi.dart'
    show
        databaseFactoryFfiWeb,
        databaseFactoryFfiWebNoWebWorker,
        databaseFactoryFfiWebBasicWebWorker;
export 'src/web/load_sqlite.dart'
    show
        SqfliteFfiWebContext,
        SqfliteFfiWebOptions,
        SqfliteFfiWebOptionsExt,
        sqfliteFfiWebLoadSqlite3Wasm,
        sqfliteFfiWebStartSharedWorker;
