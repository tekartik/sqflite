import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite/src/constant.dart';
import 'package:sqflite/src/database.dart';
import 'package:sqflite/src/sqflite_impl.dart';
import 'package:sqflite/src/sql_builder.dart';
import 'package:sqflite/src/exception.dart';

class SqfliteBatch implements Batch {
  final SqfliteDatabase database;
  final List<Map<String, dynamic>> operations = [];

  SqfliteBatch(this.database);

  @override
  Future<List<dynamic>> commit({bool exclusive}) {
    return database.inTransaction(() {
      return wrapDatabaseException(() {
        return channel.invokeMethod(
            methodBatch,
            <String, dynamic>{paramOperations: operations}
              ..addAll(database.baseDatabaseMethodArguments));
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
}
