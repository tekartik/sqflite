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
  Batch batch() => SqfliteTransactionBatch(this);
}
