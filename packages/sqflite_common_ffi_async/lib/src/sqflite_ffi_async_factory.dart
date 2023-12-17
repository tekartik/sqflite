import 'dart:io' as io;
import 'dart:typed_data';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'import.dart';
import 'sqflite_ffi_async_database.dart';

/// The Ffi database factory, to use when needed.
var factoryFfi = databaseFactoryFfi; //.debugQuickLoggerWrapper();

/// The Ffi database factory.
var databaseFactoryFfiAsyncImpl =
    SqfliteDatabaseFactoryFfiAsync(tag: 'ffi_async');

/// The Ffi database factory for tests.
var databaseFactoryFfiAsyncTestImpl =
    SqfliteDatabaseFactoryFfiAsync(tag: 'ffi_async_test');

/// The Ffi async database factory.
class SqfliteDatabaseFactoryFfiAsync with SqfliteDatabaseFactoryMixin {
  /// The Ffi async database factory.
  SqfliteDatabaseFactoryFfiAsync({String? tag}) {
    this.tag = tag;
  }

  @override
  Future<T> wrapDatabaseException<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      throw ffiWrapAnyException(e);
    }
  }

  @override
  Future<String> getDatabasesPath() {
    return factoryFfi.getDatabasesPath();
  }

  /*
  @override
  Future<void> deleteDatabase(String path) {
    return factoryFfi.deleteDatabase(path);
  }*/

  @override
  SqfliteDatabase newDatabase(
      SqfliteDatabaseOpenHelper openHelper, String path) {
    return SqfliteDatabaseFfiAsync(openHelper, path);
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

  @override
  Future<Uint8List> readDatabaseBytes(String path) async {
    path = await fixPath(path);
    var bytes = await io.File(path).readAsBytes();
    return bytes;
  }

  @override
  Future<void> writeDatabaseBytes(String path, Uint8List bytes) async {
    path = await fixPath(path);
    await io.File(path).writeAsBytes(bytes, flush: true);
  }

  @override
  Future<bool> databaseExists(String path) async {
    path = await fixPath(path);
    return io.File(path).existsSync();
  }

  @override
  Future<T> invokeMethod<T>(String method, [Object? arguments]) async {
    switch (method) {
      case methodOptions:
        return null as T;
    }
    throw UnimplementedError('Unimplemented method $method');
  }

  @override
  Future<Database> openDatabase(String path,
      {OpenDatabaseOptions? options}) async {
    // Read-only not supported in ffi_async
    if (options?.readOnly ?? false) {
      return await factoryFfi.openDatabase(path, options: options);
    }
    // Use ffi for in memory (since it is mainly for tests...)
    if (path == inMemoryDatabasePath) {
      return await factoryFfi.openDatabase(path, options: options);
    }
    var database = await super.openDatabase(path, options: options);

    /// We allow concurrent transaction starting from now.
    // ignore: invalid_use_of_visible_for_testing_member
    database.internalsDoNotUseSynchronized = true;
    return database;
  }
}
