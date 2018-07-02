import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite/src/batch.dart';
import 'package:sqflite/src/database.dart';

class SqfliteTransaction extends SqfliteDatabaseExecutor
    implements Transaction {
  final SqfliteDatabase database;

  SqfliteTransaction(this.database);

  @override
  SqfliteDatabase get db => database;

  bool successfull;

  @override
  SqfliteTransaction get txn => this;

  @override
  Future<List> applyBatch(Batch batch, {bool noResult}) {
    if (batch is SqfliteDatabaseBatch) {
      SqfliteDatabaseBatch sqfliteDatabaseBatch = batch;
      if (sqfliteDatabaseBatch.database != database) {
        throw new ArgumentError("database different in batch and transaction");
      }
    }

    return database.txnApplyBatch(txn, batch as SqfliteBatch,
        noResult: noResult);
  }

  @override
  Batch batch() => new SqfliteTransactionBatch(this);
}
