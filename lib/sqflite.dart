import 'dart:async';

import 'package:flutter/services.dart';
import 'dart:io';
import 'src/utils.dart';
import 'package:synchronized/synchronized.dart';

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

  static Future setDebugModeOn() async {
    await Sqflite._channel.invokeMethod(_methodSetDebugModeOn);
  }

  static firstIntValue(List<Map> list) {
    if (list != null && list.length > 0) {
      return parseInt(list.first.values?.first);
    }
    return null;
  }
}

class Transaction {
  bool successfull;
}

class Database {
  String get path => _path;
  String _path;
  int _id;
  Database._(this._path, this._id);
  var lock = new SynchronizedLock();

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
    return synchronized(lock, () async {
      await Sqflite._channel.invokeMethod(_methodExecute, <String, dynamic>{
        _paramId: _id,
        _paramSql: sql,
        _paramSqlArguments: arguments
      });
    });
  }

  /// for INSERT sql query
  /// returns the last inserted record id
  Future<int> insert(String sql, [List arguments]) async {
    return synchronized(lock, () async {
      return await Sqflite._channel.invokeMethod(
          _methodInsert, <String, dynamic>{
        _paramId: _id,
        _paramSql: sql,
        _paramSqlArguments: arguments
      });
    });
  }

  /// for UPDATE sql query
  /// return the number of changes made
  Future<int> update(String sql, [List arguments]) async {
    return synchronized(lock, () async {
      return await Sqflite._channel.invokeMethod(
          _methodUpdate, <String, dynamic>{
        _paramId: _id,
        _paramSql: sql,
        _paramSqlArguments: arguments
      });
    });
  }

  /// for DELETE sql query
  /// return the number of changes made
  Future<int> delete(String sql, [List arguments]) => update(sql, arguments);

  /// for SELECT sql query
  Future<List<Map<String, dynamic>>> query(String sql, [List arguments]) async {
    return synchronized(lock, () async {
      return await Sqflite._channel.invokeMethod(
          _methodQuery, <String, dynamic>{
        _paramId: _id,
        _paramSql: sql,
        _paramSqlArguments: arguments
      });
    });
  }

  Map<String, dynamic> _first(List<Map<String, dynamic>> list) {
    if (list != null && list.length > 0) {
      return list.first;
    }
    return null;
  }

  Future<Transaction> beginTransaction({bool exclusive}) async {
    Transaction transaction = new Transaction();
    if (exclusive == true) {
      await execute("BEGIN EXCLUSIVE;");
    } else {
      await execute("BEGIN IMMEDIATE;");
    }
    return transaction;
  }

  Future endTransaction(Transaction transaction) async {
    if (transaction.successfull == true) {
      await execute("COMMIT;");
    } else {
      await execute("ROLLBACK;");
    }
  }

  ///
  /// Simple transaction mechanism
  Future inTransaction(action(), {bool exclusive}) async {
    return synchronized(lock, () async {
      Transaction transaction = await beginTransaction(exclusive: exclusive);
      try {
        await action();
        transaction.successfull = true;
      } finally {
        await endTransaction(transaction);
      }
    });
  }

  Future<int> getVersion() async {
    return parseInt(_first(await query("PRAGMA user_version;"))?.values?.first);
  }

  Future setVersion(int version) async {
    await execute("PRAGMA user_version = $version;");
  }
}

class DatabaseException implements Exception {
  String msg;
  DatabaseException(this.msg);
}

typedef Future OnDatabaseVersionChangeFn(
    Database db, int oldVersion, int newVersion);
typedef Future OnDatabaseCreateFn(Database db, int newVersion);
typedef Future OnDatabaseOpenFn(Database db);

Future onDatabaseVersionChangeError(
    Database db, int oldVersion, int newVersion) async {
  throw new ArgumentError(
      "can't change version from $oldVersion to $newVersion");
}

///
/// Open the database at a given path
/// setting a version is optional
/// onCreate, onUpgrade, onDowngrade are called in a transaction
///
Future<Database> openDatabase(String path,
    {int version,
    OnDatabaseCreateFn onCreate,
    OnDatabaseVersionChangeFn onUpgrade,
    OnDatabaseVersionChangeFn onDowngrade,
    OnDatabaseOpenFn onOpen}) async {
  int databaseId = await Sqflite._channel
      .invokeMethod(_methodOpenDatabase, <String, dynamic>{_paramPath: path});

  Database database = new Database._(path, databaseId);
  if (version != null) {
    if (version == 0) {
      throw new ArgumentError("version cannot be set to 0 in openDatabase");
    }
    // init
    await database.inTransaction(() async {
      print("opening...");
      int oldVersion = await database.getVersion();
      print("got version");
      if (oldVersion == null || oldVersion == 0) {
        if (onCreate != null) {
          await onCreate(database, version);
        } else if (onUpgrade != null) {
          await onUpgrade(database, 0, version);
        }
      } else if (version > oldVersion) {
        if (onUpgrade != null) {
          await onUpgrade(database, oldVersion, version);
        }
      } else if (version < oldVersion) {
        if (onDowngrade != null) {
          await onDowngrade(database, oldVersion, version);
        }
      }
      await database.setVersion(version);
    }, exclusive: true);

    if (onOpen != null) {
      await onOpen(database);
    }
  } else {
    if (onCreate != null) {
      throw new ArgumentError(
          "onCreate must be null if no version is specified");
    }
    if (onUpgrade != null) {
      throw new ArgumentError(
          "onUpgrade must be null if no version is specified");
    }
    if (onDowngrade != null) {
      throw new ArgumentError(
          "onDowngrade must be null if no version is specified");
    }
  }
  return database;
}

Future deleteDatabase(String path) async {
  try {
    await new File(path).delete(recursive: true);
  } catch (e) {
    print(e);
  }
}
