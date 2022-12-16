import 'dart:async';

import 'package:sqflite_common/sqlite_api.dart';

/// Bare minimum mock.
class DatabaseFactoryMock implements DatabaseFactory {
  @override
  Future<bool> databaseExists(String path) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteDatabase(String path) async {
    throw UnimplementedError();
  }

  @override
  Future<String> getDatabasesPath() async {
    throw UnimplementedError();
  }

  @override
  Future<Database> openDatabase(String path, {OpenDatabaseOptions? options, String? password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> setDatabasesPath(String path) {
    throw UnimplementedError();
  }

  @override
  Future<bool> encryptDatabase(String path, String password) {
    // TODO: implement encryptDatabase
    throw UnimplementedError();
  }
}

/// Bare minimum mock.
final databaseFactoryMock = DatabaseFactoryMock();
