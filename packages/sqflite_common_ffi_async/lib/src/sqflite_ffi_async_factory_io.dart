import 'dart:typed_data';

// ignore: implementation_imports
import 'package:sqflite_common/src/database_file_system_io.dart';
// ignore: implementation_imports
import 'package:sqflite_common/src/path_utils.dart' show isInMemoryDatabasePath;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_async/src/sqflite_ffi_async_database.dart';
import 'package:sqflite_common_ffi_async/src/sqflite_ffi_async_database_io.dart';
import 'package:sqflite_common_ffi_async/src/sqflite_ffi_async_factory.dart';

import 'import.dart';

/// Same file operations as sqflite_common_ffi (the parent directory is
/// created on write).
final _databaseFileSystem = DatabaseFileSystemIo();

/// The Ffi database factory, to use when needed.
var factoryFfi = databaseFactoryFfi; //.debugQuickLoggerWrapper();

/// The Ffi database factory.
var databaseFactoryFfiAsyncIoImpl = SqfliteDatabaseFactoryFfiAsyncIo(
  tag: 'ffi_async',
);

/// The Ffi database factory for tests.
var databaseFactoryFfiAsyncIoTestImpl = SqfliteDatabaseFactoryFfiAsyncIo(
  tag: 'ffi_async_test',
);

/// The Ffi async database factory.
class SqfliteDatabaseFactoryFfiAsyncIo
    with SqfliteDatabaseFactoryMixin, SqfliteDatabaseFactoryFfiAsyncMixin {
  /// The Ffi async database factory.
  SqfliteDatabaseFactoryFfiAsyncIo({String? tag}) {
    this.tag = tag;
  }
  @override
  Future<String> getDatabasesPath() async {
    return (await ffiAsyncGetDatabasesPathOrNull()) ??
        (await factoryFfi.getDatabasesPath());
  }

  @override
  SqfliteDatabase newDatabase(
    SqfliteDatabaseOpenHelper openHelper,
    String path,
  ) {
    return SqfliteDatabaseFfiAsyncIo(openHelper, path);
  }

  /// Invoke delete database.
  @override
  Future<void> invokeDeleteDatabase(String path) async {
    var databaseOpenHelper = databaseOpenHelpers[path];
    if (databaseOpenHelper != null) {
      removeDatabaseOpenHelper(path);
      //await databaseOpenHelper.closeDatabase(sqfliteDatabase)
    }
    await factoryFfi.deleteDatabase(path);
  }

  /// The open single instance database at [path] (already fixed), if any.
  SqfliteDatabaseFfiAsyncBase? _openDatabase(String path) {
    var database = databaseOpenHelpers[path]?.sqfliteDatabase;
    if (database is SqfliteDatabaseFfiAsyncBase && database.isOpen) {
      return database;
    }
    return null;
  }

  /// Closes the open database first: sqlite_async shares its connection pool
  /// by path, a database opened again after the delete would get the
  /// connections on the deleted file (and lose what is written next). As with
  /// sqflite_common_ffi, the deleted database cannot be used anymore.
  @override
  Future<void> deleteDatabase(String path) async {
    await _openDatabase(await fixPath(path))?.close();
    await super.deleteDatabase(path);
  }

  @override
  Future<Uint8List> readDatabaseBytes(String path) async {
    path = await fixPath(path);
    // WAL mode: the last changes of an open database are in the -wal file.
    await _openDatabase(path)?.checkpoint();
    return await _databaseFileSystem.readDatabaseBytes(path);
  }

  @override
  Future<void> writeDatabaseBytes(String path, Uint8List bytes) async {
    path = await fixPath(path);
    await _databaseFileSystem.writeDatabaseBytes(path, bytes);
  }

  @override
  Future<bool> databaseExists(String path) async {
    path = await fixPath(path);
    return _databaseFileSystem.databaseExists(path);
  }

  @override
  Future<Database> openDatabase(
    String path, {
    OpenDatabaseOptions? options,
  }) async {
    // Read-only not supported in ffi_async
    if (options?.readOnly ?? false) {
      return await factoryFfi.openDatabase(path, options: options);
    }
    // Use ffi for in memory (since it is mainly for tests...), `:memory:`
    // and `file::memory:`.
    if (isInMemoryDatabasePath(path)) {
      return await factoryFfi.openDatabase(path, options: options);
    }
    var database = await super.openDatabase(path, options: options);

    /// We allow concurrent transaction starting from now.
    // ignore: invalid_use_of_visible_for_testing_member
    database.internalsDoNotUseSynchronized = true;
    return database;
  }
}
