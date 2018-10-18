import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite/src/batch.dart';
import 'package:sqflite/src/database.dart';

class SqfliteTransaction extends SqfliteDatabaseExecutor
    implements Transaction {
  SqfliteTransaction(this.database);

  final SqfliteDatabase database;

  @override
  SqfliteDatabase get db => database;

  bool successfull;

  @override
  SqfliteTransaction get txn => this;

  @override
  Future<List<dynamic>> applyBatch(Batch batch, {bool noResult}) {
    if (batch is SqfliteDatabaseBatch) {
      final SqfliteDatabaseBatch sqfliteDatabaseBatch = batch;
      if (sqfliteDatabaseBatch.database != database) {
        throw ArgumentError("database different in batch and transaction");
      }
    }
    final SqfliteBatch sqfliteBatch = batch;
    return database.txnApplyBatch(txn, sqfliteBatch, noResult: noResult);
  }

  @override
  Batch batch() => SqfliteTransactionBatch(this);
}
