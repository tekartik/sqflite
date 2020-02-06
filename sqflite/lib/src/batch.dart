import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite/src/constant.dart';
import 'package:sqflite/src/database.dart';
import 'package:sqflite/src/sql_builder.dart';
import 'package:sqflite/src/transaction.dart';
import 'package:sqflite/src/utils.dart';

/// Batch implementation
abstract class SqfliteBatch implements Batch {
  /// List of operations
  final List<Map<String, dynamic>> operations = <Map<String, dynamic>>[];

  Map<String, dynamic> _getOperationMap(
      String method, String sql, List<dynamic> arguments) {
    return <String, dynamic>{
      paramMethod: method,
      paramSql: sql,
      paramSqlArguments: arguments
    };
  }

  void _add(String method, String sql, List<dynamic> arguments) {
    operations.add(_getOperationMap(method, sql, arguments));
  }

  void _addExecute(
      String method, String sql, List<dynamic> arguments, bool inTransaction) {
    final Map<String, dynamic> map = _getOperationMap(method, sql, arguments);
    if (inTransaction != null) {
      map[paramInTransaction] = inTransaction;
    }
    operations.add(map);
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
    // Check for begin/end transaction
    final bool inTransaction = getSqlInTransactionArgument(sql);
    _addExecute(methodExecute, sql, arguments, inTransaction);
  }
}

/// Batch on a given database
class SqfliteDatabaseBatch extends SqfliteBatch {
  /// Create a batch in a database
  SqfliteDatabaseBatch(this.database);

  /// Our database
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

/// Batch on a given transaction
class SqfliteTransactionBatch extends SqfliteBatch {
  /// Create a batch in a transaction
  SqfliteTransactionBatch(this.transaction);

  /// Our transaction
  final SqfliteTransaction transaction;

  @override
  Future<List<dynamic>> commit(
      {bool exclusive, bool noResult, bool continueOnError}) {
    if (exclusive != null) {
      throw ArgumentError.value(exclusive, 'exclusive',
          'must not be set when commiting a batch in a transaction');
    }
    return transaction.database.txnApplyBatch(transaction, this,
        noResult: noResult, continueOnError: continueOnError);
  }
}
