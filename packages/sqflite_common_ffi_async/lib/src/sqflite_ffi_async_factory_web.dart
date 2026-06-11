import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_async/src/sqflite_ffi_async_database_web.dart';

import 'import.dart';
import 'sqflite_ffi_async_factory.dart';

/// The Ffi database factory, to use when needed.
var factoryFfi = databaseFactoryFfi; //.debugQuickLoggerWrapper();

/// The Ffi database factory.
var databaseFactoryFfiAsyncWebImpl = SqfliteDatabaseFactoryFfiAsyncWeb(
  tag: 'ffi_async_web',
);

/// The Ffi database factory for tests.
var databaseFactoryFfiAsyncWebTestImpl = SqfliteDatabaseFactoryFfiAsyncWeb(
  tag: 'ffi_async_web_test',
);

/// The Ffi async database factory.
class SqfliteDatabaseFactoryFfiAsyncWeb
    with SqfliteDatabaseFactoryMixin, SqfliteDatabaseFactoryFfiAsyncMixin {
  /// The Ffi async database factory.
  SqfliteDatabaseFactoryFfiAsyncWeb({String? tag}) {
    this.tag = tag;
  }

  @override
  SqfliteDatabase newDatabase(
    SqfliteDatabaseOpenHelper openHelper,
    String path,
  ) {
    return SqfliteDatabaseFfiAsyncWeb(openHelper, path);
  }

  @override
  Future<Database> openDatabase(
    String path, {
    OpenDatabaseOptions? options,
  }) async {
    if (options?.readOnly ?? false) {
      throw UnsupportedError('read only not supported in ffi_async_web');
    }
    // Use ffi for in memory (since it is mainly for tests...)
    if (path == inMemoryDatabasePath) {
      throw UnsupportedError(
        '$inMemoryDatabasePath not supported in ffi_async_web',
      );
    }
    var database = await super.openDatabase(path, options: options);

    /// We allow concurrent transaction starting from now.
    // ignore: invalid_use_of_visible_for_testing_member
    database.internalsDoNotUseSynchronized = true;
    return database;
  }
}
