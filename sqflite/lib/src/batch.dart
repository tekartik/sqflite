import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite/src/constant.dart';
import 'package:sqflite/src/database.dart';
import 'package:sqflite/src/sql_builder.dart';
import 'package:sqflite/src/transaction.dart';

abstract class SqfliteBatch implements Batch {
  final List<Map<String, dynamic>> operations = <Map<String, dynamic>>[];

  void _add(String method, String sql, List<dynamic> arguments) {
    operations.add(<String, dynamic>{
      paramMethod: method,
      paramSql: sql,
      paramSqlArguments: arguments
    });
  }

  @override
  void rawInsert(String sql, [List<dynamic> arguments]) {
    _add(methodInsert, sql, arguments);
  }

  @override
  void insert(String table, Map<String, dynamic> values,
      {String nullColumnHack, ConflictAlgorithm conflictAlgorithm}) {
    final SqlBuilder builder = SqlBuilder.insert(table, values,
        nullColumnHack: nullColumnHack, conflictAlgorithm: conflictAlgorithm);
    return rawInsert(builder.sql, builder.arguments);
  }

  @override
  void rawQuery(String sql, [List<dynamic> arguments]) {
    _add(methodQuery, sql, arguments);
  }

  @override
  void query(String table,
      {bool distinct,
      List<String> columns,
      String where,
      List<dynamic> whereArgs,
      String groupBy,
      String having,
      String orderBy,
      int limit,
      int offset}) {
    final SqlBuilder builder = SqlBuilder.query(table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset);
    return rawQuery(builder.sql, builder.arguments);
  }

  @override
  void rawUpdate(String sql, [List<dynamic> arguments]) {
    _add(methodUpdate, sql, arguments);
  }

  @override
  void update(String table, Map<String, dynamic> values,
      {String where,
      List<dynamic> whereArgs,
      ConflictAlgorithm conflictAlgorithm}) {
    final SqlBuilder builder = SqlBuilder.update(table, values,
        where: where,
        whereArgs: whereArgs,
        conflictAlgorithm: conflictAlgorithm);
    return rawUpdate(builder.sql, builder.arguments);
  }

  @override
  void delete(String table, {String where, List<dynamic> whereArgs}) {
    final SqlBuilder builder =
        SqlBuilder.delete(table, where: where, whereArgs: whereArgs);
    return rawDelete(builder.sql, builder.arguments);
  }

  @override
  void rawDelete(String sql, [List<dynamic> arguments]) {
    rawUpdate(sql, arguments);
  }

  @override
  void execute(String sql, [List<dynamic> arguments]) {
    _add(methodExecute, sql, arguments);
  }
}

class SqfliteDatabaseBatch extends SqfliteBatch {
  SqfliteDatabaseBatch(this.database);

  final SqfliteDatabase database;

  @override
  Future<List<dynamic>> commit(
      {bool exclusive, bool noResult, bool continueOnError}) {
    database.checkNotClosed();
    return database.transaction<List<dynamic>>((Transaction txn) {
      final SqfliteTransaction sqfliteTransaction = txn as SqfliteTransaction;
      return database.txnApplyBatch(sqfliteTransaction, this,
          noResult: noResult, continueOnError: continueOnError);
    }, exclusive: exclusive);
  }
}

class SqfliteTransactionBatch extends SqfliteBatch {
  SqfliteTransactionBatch(this.transaction);

  final SqfliteTransaction transaction;

  @override
  Future<List<dynamic>> commit(
      {bool exclusive, bool noResult, bool continueOnError}) {
    if (exclusive != null) {
      throw ArgumentError.value(exclusive, "exclusive",
          "must not be set when commiting a batch in a transaction");
    }
    return transaction.database.txnApplyBatch(transaction, this,
        noResult: noResult, continueOnError: continueOnError);
  }
}
