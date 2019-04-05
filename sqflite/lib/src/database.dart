import 'dart:async';

import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite/src/batch.dart';
import 'package:sqflite/src/factory.dart';
import 'package:sqflite/src/transaction.dart';

abstract class SqfliteDatabaseExecutor implements DatabaseExecutor {
  SqfliteTransaction get txn;

  SqfliteDatabase get db;
}

class SqfliteDatabaseOpenHelper {
  SqfliteDatabaseOpenHelper(this.factory, this.path, this.options);

  final SqfliteDatabaseFactory factory;
  final OpenDatabaseOptions options;
  final String path;
  SqfliteDatabase sqfliteDatabase;

  SqfliteDatabase newDatabase(String path) => factory.newDatabase(this, path);

  bool get isOpen => sqfliteDatabase != null;

  // Future<SqfliteDatabase> get databaseReady => _completer.future;

  // open or return the one opened
  Future<SqfliteDatabase> openDatabase() async {
    if (!isOpen) {
      final SqfliteDatabase database = newDatabase(path);
      await database.doOpen(options);
      sqfliteDatabase = database;
    }
    return sqfliteDatabase;
  }

  Future<void> closeDatabase(SqfliteDatabase sqfliteDatabase) async {
    if (isOpen) {
      if (!isOpen) {
        return;
      } else {
        await sqfliteDatabase.doClose();
        this.sqfliteDatabase = null;
      }
    }
  }
}

abstract class SqfliteDatabase extends SqfliteDatabaseExecutor
    implements Database {
  Future<SqfliteDatabase> doOpen(OpenDatabaseOptions options);

  Future<void> doClose();

  // Its internal id
  int id;
  OpenDatabaseOptions options;

  Future<SqfliteTransaction> beginTransaction({bool exclusive});

  Future<void> endTransaction(SqfliteTransaction txn);

  Future<List<dynamic>> txnApplyBatch(
      SqfliteTransaction txn, SqfliteBatch batch,
      {bool noResult, bool continueOnError});

  Future<T> txnExecute<T>(SqfliteTransaction txn, String sql,
      [List<dynamic> arguments]);

  Future<int> txnRawInsert(
      SqfliteTransaction txn, String sql, List<dynamic> arguments);

  Future<List<Map<String, dynamic>>> txnRawQuery(
      SqfliteTransaction txn, String sql, List<dynamic> arguments);

  Future<int> txnRawUpdate(
      SqfliteTransaction txn, String sql, List<dynamic> arguments);

  void checkNotClosed();
}
