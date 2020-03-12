import 'dart:async';

import 'package:sqflite_common/sqlite_api.dart';

/// Bare minimum mock.
class DatabaseFactoryMock implements DatabaseFactory {
  @override
  Future<bool> databaseExists(String path) async {
    return false;
  }

  @override
  Future<void> deleteDatabase(String path) async {}

  @override
  Future<String> getDatabasesPath() async {
    return null;
  }

  @override
  Future<Database> openDatabase(String path, {OpenDatabaseOptions options}) {
    return null;
  }
}

/// Bare minimum mock.
final databaseFactoryMock = DatabaseFactoryMock();
