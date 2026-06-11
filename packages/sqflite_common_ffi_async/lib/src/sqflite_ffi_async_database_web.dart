import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_async/src/sqflite_ffi_async_database.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite_async;

import 'import.dart';

/// Ffi async database implementation.
class SqfliteDatabaseFfiAsyncWeb extends SqfliteDatabaseFfiAsyncBase {
  /// Ffi async database implementation.
  SqfliteDatabaseFfiAsyncWeb(super.openHelper, super.path);

  @override
  Future<int> openDatabase() async {
    sqlite_async.SqliteOptions sqliteOptions;
    var path = this.path;
    if (path == inMemoryDatabasePath) {
      path = this.path = join('/tmp', 'in_memory_$ffiAsyncId.db');
    }
    var webSqliteOptions = const sqlite_async.WebSqliteOptions(
      wasmUri: 'sqlite3.wasm',
      workerUri: 'db_worker.js',
    );
    if (options?.readOnly ?? false) {
      /*if (!await factoryFfi.databaseExists(path)) {
        throw SqfliteDatabaseException(
          'read-only Database not found: $path',
          null,
        );
      }*/
      sqliteOptions = sqlite_async.SqliteOptions(
        journalMode: null,
        journalSizeLimit: null,
        synchronous: null,
        webSqliteOptions: webSqliteOptions,
      );
    } else {
      /*
      var dir = Directory(dirname(path));
      try {
        if (!dir.existsSync()) {
          // Create the directory if needed
          await dir.create(recursive: true);
        }
      } catch (e) {
        // ignore: avoid_print
        print('error checking directory $dir: $e');
      }*/
      sqliteOptions = sqlite_async.SqliteOptions(
        webSqliteOptions: webSqliteOptions,
      );
    }

    ffiAsyncDatabase = sqlite_async.SqliteDatabase(
      path: path,
      options: sqliteOptions,
    );
    return ffiAsyncId;
  }
}
