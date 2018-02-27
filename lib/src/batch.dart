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

  @override
  Future<List<dynamic>> commit({bool exclusive, bool noResult}) {
    return database.inTransaction<List>(() {
      return wrapDatabaseException<List>(() async {
        var arguments = <String, dynamic>{paramOperations: operations}
          ..addAll(database.baseDatabaseMethodArguments);
        if (noResult == true) {
          arguments[paramNoResult] = noResult;
        }
        List results = await channel.invokeMethod(methodBatch, arguments);

        // dart1 support
        if (results is List<dynamic>) {
          return results;
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
}
