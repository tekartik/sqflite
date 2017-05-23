import 'dart:async';

import 'package:flutter/services.dart';

final String _paramPath = "path";
final String _paramId = "id";
final String _paramSql = "sql";
final String _paramTable = "table";
final String _paramValues = "values";
final String _paramSqlArguments = "arguments";

final String _methodCloseDatabase = "closeDatabase";
final String _methodExecute = "execute";
final String _methodInsert = "insert";
final String _methodUpdate = "update";

class Sqflite {
  static const MethodChannel _channel =
      const MethodChannel('com.tekartik.sqflite');

  static Future<String> get platformVersion =>
      _channel.invokeMethod('getPlatformVersion');
}

class Database {
  String _path;
  int _id;
  Database._(this._path, this._id);

  @override
  String toString() {
    return "$_id $_path";
  }

  Future close() async {
    await Sqflite._channel
        .invokeMethod(_methodCloseDatabase, <String, dynamic>{_paramId: _id});
  }

  /// for query without return values
  Future execute(String sql, [List arguments]) async {
    await Sqflite._channel.invokeMethod(_methodExecute, <String, dynamic>{
      _paramId: _id,
      _paramSql: sql,
      _paramSqlArguments: arguments
    });
  }

  /// for INSERT sql query
  /// returns the last inserted record id
  Future<int> insert(String sql, [List arguments]) async {
    return await Sqflite._channel.invokeMethod(_methodInsert, <String, dynamic>{
      _paramId: _id,
      _paramSql: sql,
      _paramSqlArguments: arguments
    });
  }

  /// for UPDATE/DELETE sql query
  /// return the number of changes made
  Future<int> update(String sql, [List arguments]) async {
    return await Sqflite._channel.invokeMethod(_methodUpdate, <String, dynamic>{
      _paramId: _id,
      _paramSql: sql,
      _paramSqlArguments: arguments
    });
  }

  /*
  Future<int> insertSmart(String table, Map<String, dynamic> values) async {
    return await Sqflite._channel.invokeMethod(_methodInsert, <String, dynamic>{
      _paramId: _id,
      _paramTable: table,
      _paramValues: values
    });
  }
  */
}

class DatabaseException implements Exception {
  String msg;
  DatabaseException(this.msg);
}

Future<Database> openDatabase(String path, {int version}) async {
  int databaseId = await Sqflite._channel.invokeMethod(
      "openDatabase", <String, dynamic>{"path": path, "version": version ?? 1});

  return new Database._(path, databaseId);
}
