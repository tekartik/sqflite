import 'package:sqflite/src/factory.dart';
import 'package:sqflite/src/factory_impl.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Change the default factory used.
///
/// Test only.
///
@deprecated
void setMockDatabaseFactory(DatabaseFactory factory) {
  sqlfliteDatabaseFactory = factory as SqfliteDatabaseFactory;
}
