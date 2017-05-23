import 'dart:async';

import 'package:flutter/services.dart';

const String _paramPath = "path";
const String _paramVersion = "version";
const String _paramId = "id";
const String _paramSql = "sql";
const String _paramTable = "table";
const String _paramValues = "values";
const String _paramSqlArguments = "arguments";

const String _methodSetDebugModeOn = "debugMode";
const String _methodCloseDatabase = "closeDatabase";
const String _methodOpenDatabase = "openDatabase";
const String _methodExecute = "execute";
const String _methodInsert = "insert";
const String _methodUpdate = "update";
const String _methodQuery = "query";

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

  /// for sql without return values
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

  /// for SELECT sql query
  Future<List<Map>> query(String sql, [List arguments]) async {
    return await Sqflite._channel.invokeMethod(_methodQuery, <String, dynamic>{
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

typedef Future VersionChangeFn(Database db, int oldVersion, int newVersion);

Future<Database> openDatabase(String path, {int version, VersionChangeFn onUpgrade, VersionChangeFn onDowngrade}) async {
  int databaseId = await Sqflite._channel.invokeMethod(
      _methodOpenDatabase, <String, dynamic>{_paramPath: path, _paramVersion: version ?? 1});

  return new Database._(path, databaseId);
}

Future setDebugModeOn() async {
  await Sqflite._channel.invokeMethod(_methodSetDebugModeOn);
}
