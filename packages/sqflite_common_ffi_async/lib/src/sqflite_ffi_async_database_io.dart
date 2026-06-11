import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi_async/src/sqflite_ffi_async_database.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite_async;

import 'import.dart';
//import 'dart:io';
import 'sqflite_ffi_async_factory_io.dart';

/// Ffi async database implementation.
class SqfliteDatabaseFfiAsyncIo extends SqfliteDatabaseFfiAsyncBase {
  /// Ffi async database implementation.
  SqfliteDatabaseFfiAsyncIo(super.openHelper, super.path);

  @override
  Future<int> openDatabase() async {
    sqlite_async.SqliteOptions sqliteOptions;
    var path = this.path;
    if (path == inMemoryDatabasePath) {
      var dir = await Directory.systemTemp.createTemp();
      path = this.path = join(dir.path, 'in_memory_$ffiAsyncId.db');
    }
    if (options?.readOnly ?? false) {
      if (!await factoryFfi.databaseExists(path)) {
        throw SqfliteDatabaseException(
          'read-only Database not found: $path',
          null,
        );
      }
      sqliteOptions = const sqlite_async.SqliteOptions(
        journalMode: null,
        journalSizeLimit: null,
        synchronous: null,
      );
    } else {
      var dir = Directory(dirname(path));
      try {
        if (!dir.existsSync()) {
          // Create the directory if needed
          await dir.create(recursive: true);
        }
      } catch (e) {
        // ignore: avoid_print
        print('error checking directory $dir: $e');
      }
      sqliteOptions = const sqlite_async.SqliteOptions();
    }

    ffiAsyncDatabase = sqlite_async.SqliteDatabase(
      path: path,
      options: sqliteOptions,
    );
    return ffiAsyncId;
  }
}
