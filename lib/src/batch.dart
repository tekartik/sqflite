import 'package:sqflite/sqflite.dart';
import 'package:sqflite/src/constant.dart';
import 'package:sqflite/src/database.dart';
import 'package:sqflite/src/sqflite_impl.dart';
import 'package:sqflite/src/sql_builder.dart';
import 'package:sqflite/src/exception.dart';
import 'package:sqflite/src/utils.dart';

class SqfliteBatch implements Batch {
  final SqfliteDatabase database;
  final List<Map<String, dynamic>> operations = [];

  SqfliteBatch(this.database);

  Future<List<dynamic>> commit({bool exclusive, bool noResult}) => apply(exclusive: exclusive, noResult: noResult);

  @override
  Future<List<dynamic>> apply({bool exclusive, bool noResult}) {
    return database.transaction<List>((txn) {
      return wrapDatabaseException<List>(() async {
        var arguments = <String, dynamic>{paramOperations: operations}
          ..addAll(database.baseDatabaseMethodArguments);
        if (noResult == true) {
          arguments[paramNoResult] = noResult;
        }
        List results = await database.invokeMethod(methodBatch, arguments);

        // Typically when noResult is true
        if (results == null) {
          return null;
        }
        // dart2 - wrap if we need to support more results than just int
        return new BatchResults.from(results);
      });
    }, exclusive: exclusive);
  }

  _add(String method, String sql, List arguments) {
    operations.add(
        {paramMethod: method, paramSql: sql, paramSqlArguments: arguments});
  }

  @override
  void rawInsert(String sql, [List arguments]) {
    _add(methodInsert, sql, arguments);
  }

  @override
  void insert(String table, Map<String, dynamic> values,
      {String nullColumnHack, ConflictAlgorithm conflictAlgorithm}) {
    SqlBuilder builder = new SqlBuilder.insert(table, values,
        nullColumnHack: nullColumnHack, conflictAlgorithm: conflictAlgorithm);
    return rawInsert(builder.sql, builder.arguments);
  }

  @override
  void rawQuery(String sql, [List arguments]) {
    _add(methodQuery, sql, arguments);
  }

  @override
  void query(String table,
      {bool distinct,
      List<String> columns,
      String where,
      List whereArgs,
      String groupBy,
      String having,
      String orderBy,
      int limit,
      int offset}) {
    SqlBuilder builder = new SqlBuilder.query(table,
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
  void rawUpdate(String sql, [List arguments]) {
    _add(methodUpdate, sql, arguments);
  }

  @override
  void update(String table, Map<String, dynamic> values,
      {String where, List whereArgs, ConflictAlgorithm conflictAlgorithm}) {
    SqlBuilder builder = new SqlBuilder.update(table, values,
        where: where,
        whereArgs: whereArgs,
        conflictAlgorithm: conflictAlgorithm);
    return rawUpdate(builder.sql, builder.arguments);
  }

  @override
  void delete(String table, {String where, List whereArgs}) {
    SqlBuilder builder =
        new SqlBuilder.delete(table, where: where, whereArgs: whereArgs);
    return rawDelete(builder.sql, builder.arguments);
  }

  @override
  void rawDelete(String sql, [List arguments]) {
    rawUpdate(sql, arguments);
  }

  @override
  void execute(String sql, [List arguments]) {
    _add(methodExecute, sql, arguments);
  }
}
