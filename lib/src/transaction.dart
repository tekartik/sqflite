import 'package:sqflite/sqflite.dart';
import 'package:sqflite/src/database.dart';

class SqfliteTransaction extends SqfliteDatabaseExecutor
    implements Transaction {
  final SqfliteDatabase database;

  @override
  SqfliteDatabase get db => database;

  bool successfull;

  SqfliteTransaction(this.database);

  @override
  SqfliteTransaction get txn => this;
}
