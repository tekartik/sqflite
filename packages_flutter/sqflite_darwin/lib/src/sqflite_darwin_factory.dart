import 'package:sqflite_common/sqlite_api.dart';

import 'sqflite_import.dart';

final DatabaseFactory databaseFactorySqfliteDarwinPlugin =
    createDatabaseFactoryDarwinImpl();

/// Creates an FFI database factory
DatabaseFactory createDatabaseFactoryDarwinImpl({String? tag = 'darwin'}) {
  return buildDatabaseFactory(
      tag: tag,
      invokeMethod: (String method, [Object? arguments]) {
        throw UnimplementedError();
      });
}
