import 'package:flutter/cupertino.dart';
import 'package:sqflite/src/factory.dart';
import 'package:sqflite/src/factory_impl.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Change the default factory used.
///
/// Test only.
///
@visibleForTesting
void setMockDatabaseFactory(DatabaseFactory factory) {
  // ignore: deprecated_member_use_from_same_package
  sqlfliteDatabaseFactory = factory as SqfliteDatabaseFactory;
}
