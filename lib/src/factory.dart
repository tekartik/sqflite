import 'dart:async';

import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite/src/database.dart';
import 'package:synchronized/synchronized.dart';

abstract class SqfliteDatabaseFactory implements DatabaseFactory {
  Future<T> invokeMethod<T>(String method, [dynamic arguments]);

  Future<T> wrapDatabaseException<T>(Future<T> action());
  // To override
  // This also should wrap exception
  //Future<T> safeInvokeMethod<T>(String method, [dynamic arguments]);

  // open lock mechanism
  final Lock lock = Lock();

  SqfliteDatabase newDatabase(
      SqfliteDatabaseOpenHelper openHelper, String path);

  // internal close
  void doCloseDatabase(SqfliteDatabase database);

  void removeDatabaseOpenHelper(String path);

  @override
  Future<Database> openDatabase(String path, {OpenDatabaseOptions options});

  @override
  Future<void> deleteDatabase(String path);

  @override
  Future<bool> databaseExists(String path);

  Future<void> createParentDirectory(String path);
}
