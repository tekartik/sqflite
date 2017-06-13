import 'dart:async';

import 'package:flutter/services.dart';
import 'dart:io';
import 'package:sqflite/src/exception.dart';
import 'package:sqflite/src/sql_builder.dart';
import 'src/utils.dart';
import 'package:synchronized/synchronized.dart';
export 'src/exception.dart' show DatabaseException;

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
const String _methodGetPlatformVersion = "getPlatformVersion";

const String _channelName = 'com.tekartik.sqflite';

class Sqflite {
  static const MethodChannel _channel = const MethodChannel(_channelName);

  static Future<String> get platformVersion =>
      _channel.invokeMethod(_methodGetPlatformVersion);

  static Future setDebugModeOn([bool on = true]) async {
    await Sqflite._channel.invokeMethod(_methodSetDebugModeOn, on);
  }

  static firstIntValue(List<Map> list) {
    if (list != null && list.length > 0) {
      return parseInt(list.first.values?.first);
    }
    return null;
  }
}

class _Transaction {
  bool successfull;
}

///
/// Basic Database support
/// to send raw sql commands
///
class Database {
  String get path => _path;
  String _path;
  int _id;
  Database._(this._path, this._id);

  // only set during inTransaction to allow recursivity
  int _transactionRefCount = 0;

  var _lock = new SynchronizedLock();

  SynchronizedLock get transactionLock => _lock;

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
    return synchronized(_lock, () {
      return wrapDatabaseException(() {
        return Sqflite._channel.invokeMethod(_methodExecute, <String, dynamic>{
          _paramId: _id,
          _paramSql: sql,
          _paramSqlArguments: arguments
        });
      });
    });
  }

  /// for INSERT sql query
  /// returns the last inserted record id
  Future<int> rawInsert(String sql, [List arguments]) async {
    return synchronized(_lock, () {
      return wrapDatabaseException(() {
        return Sqflite._channel.invokeMethod(_methodInsert, <String, dynamic>{
          _paramId: _id,
          _paramSql: sql,
          _paramSqlArguments: arguments
        });
      });
    });
  }

  /// Convenience method for inserting a row into the database.
  /// Parameters:
  /// @table the table to insert the row into
  /// @nullColumnHack optional; may be null. SQL doesn't allow inserting a completely empty row without naming at least one column name. If your provided values is empty, no column names are known and an empty row can't be inserted. If not set to null, the nullColumnHack parameter provides the name of nullable column name to explicitly insert a NULL into in the case where your values is empty.
  /// @values this map contains the initial column values for the row. The keys should be the column names and the values the column values
  Future<int> insert(String table, Map<String, dynamic> values,
      {String nullColumnHack, ConflictAlgorithm conflictAlgorithm}) {
    SqlBuilder builder = new SqlBuilder.insert(table, values,
        nullColumnHack: nullColumnHack, conflictAlgorithm: conflictAlgorithm);
    return rawInsert(builder.sql, builder.arguments);
  }

  /// Helper to query a table
  ///
  /// @param distinct true if you want each row to be unique, false otherwise.
  /// @param table The table names to compile the query against.
  /// @param columns A list of which columns to return. Passing null will
  ///            return all columns, which is discouraged to prevent reading
  ///            data from storage that isn't going to be used.
  /// @param where A filter declaring which rows to return, formatted as an SQL
  ///            WHERE clause (excluding the WHERE itself). Passing null will
  ///            return all rows for the given URL.
  /// @param groupBy A filter declaring how to group rows, formatted as an SQL
  ///            GROUP BY clause (excluding the GROUP BY itself). Passing null
  ///            will cause the rows to not be grouped.
  /// @param having A filter declare which row groups to include in the cursor,
  ///            if row grouping is being used, formatted as an SQL HAVING
  ///            clause (excluding the HAVING itself). Passing null will cause
  ///            all row groups to be included, and is required when row
  ///            grouping is not being used.
  /// @param orderBy How to order the rows, formatted as an SQL ORDER BY clause
  ///            (excluding the ORDER BY itself). Passing null will use the
  ///            default sort order, which may be unordered.
  /// @param limit Limits the number of rows returned by the query,
  /// @param offset starting index,

  /// @return the items found
  Future<List<Map<String, dynamic>>> query(String table,
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
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
        whereArgs: whereArgs);
    return rawQuery(builder.sql, builder.arguments);
  }

  /// for UPDATE sql query
  /// return the number of changes made
  Future<int> rawUpdate(String sql, [List arguments]) async {
    return synchronized(_lock, () {
      return wrapDatabaseException(() {
        return Sqflite._channel.invokeMethod(_methodUpdate, <String, dynamic>{
          _paramId: _id,
          _paramSql: sql,
          _paramSqlArguments: arguments
        });
      });
    });
  }

  /// Convenience method for updating rows in the database.
  ///
  /// update into table [table] with the [values], a map from column names
  /// to new column values. null is a valid value that will be translated to NULL.
  /// [where] is the optional WHERE clause to apply when updating.
  ///            Passing null will update all rows.
  /// You may include ?s in the where clause, which
  ///            will be replaced by the values from [whereArgs]
  /// optional [conflictAlgorithm] for update conflict resolver
  /// return the number of rows affected
  Future<int> update(String table, Map<String, dynamic> values,
      {String where, List whereArgs, ConflictAlgorithm conflictAlgorithm}) {
    SqlBuilder builder = new SqlBuilder.update(table, values,
        where: where,
        whereArgs: whereArgs,
        conflictAlgorithm: conflictAlgorithm);
    return rawUpdate(builder.sql, builder.arguments);
  }

  /// for DELETE sql query
  /// return the number of changes made
  Future<int> rawDelete(String sql, [List arguments]) =>
      rawUpdate(sql, arguments);

  /// Convenience method for deleting rows in the database.
  ///
  /// delete from [table]
  /// [where] is the optional WHERE clause to apply when updating.
  ///            Passing null will update all rows.
  /// You may include ?s in the where clause, which
  ///            will be replaced by the values from [whereArgs]
  /// optional [conflictAlgorithm] for update conflict resolver
  /// return the number of rows affected if a whereClause is passed in, 0
  ///         otherwise. To remove all rows and get a count pass "1" as the
  ///         whereClause.
  Future<int> delete(String table, {String where, List whereArgs}) {
    SqlBuilder builder =
        new SqlBuilder.delete(table, where: where, whereArgs: whereArgs);
    return rawDelete(builder.sql, builder.arguments);
  }

  /// for SELECT sql query
  Future<List<Map<String, dynamic>>> rawQuery(String sql,
      [List arguments]) async {
    return await synchronized(_lock, () async {
      return await wrapDatabaseException(() async {
        return await Sqflite._channel.invokeMethod(
            _methodQuery, <String, dynamic>{
          _paramId: _id,
          _paramSql: sql,
          _paramSqlArguments: arguments
        });
      });
    });
  }

  Map<String, dynamic> _first(List<Map<String, dynamic>> list) {
    if (list != null && list.length > 0) {
      return list.first;
    }
    return null;
  }

  Future<_Transaction> _beginTransaction({bool exclusive}) async {
    _Transaction transaction = new _Transaction();
    if (exclusive == true) {
      await execute("BEGIN EXCLUSIVE;");
    } else {
      await execute("BEGIN IMMEDIATE;");
    }
    return transaction;
  }

  Future _endTransaction(_Transaction transaction) async {
    if (transaction.successfull == true) {
      await execute("COMMIT;");
    } else {
      await execute("ROLLBACK;");
    }
  }

  ///
  /// Simple transaction mechanism
  Future inTransaction(action(), {bool exclusive}) async {
    return synchronized(_lock, () async {
      _Transaction transaction;
      bool successfull;
      if (_transactionRefCount++ == 0) {
        transaction = await _beginTransaction(exclusive: exclusive);
      }
      try {
        await action();
        successfull = true;
      } finally {
        if (--_transactionRefCount == 0) {
          transaction.successfull = successfull;
          await _endTransaction(transaction);
        }
      }
    });
  }

  Future<int> getVersion() async {
    return parseInt(
        _first(await rawQuery("PRAGMA user_version;"))?.values?.first);
  }

  Future setVersion(int version) async {
    await execute("PRAGMA user_version = $version;");
  }
}

typedef Future OnDatabaseVersionChangeFn(
    Database db, int oldVersion, int newVersion);
typedef Future OnDatabaseCreateFn(Database db, int newVersion);
typedef Future OnDatabaseOpenFn(Database db);

// Downgrading will always fail
Future onDatabaseVersionChangeError(
    Database db, int oldVersion, int newVersion) async {
  try {
    await db.close();
  } catch (_) {}
  ;
  throw new ArgumentError(
      "can't change version from $oldVersion to $newVersion");
}

Future __onDatabaseDowngradeDelete(
    Database db, int oldVersion, int newVersion) async {
  // Implementation is hidden implemented in openDatabase._onDatabaseDowngradeDelete
}
// Downgrading will delete the database and open it again
final OnDatabaseVersionChangeFn onDatabaseDowngradeDelete =
    __onDatabaseDowngradeDelete;

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
  int databaseId = await wrapDatabaseException(() { return Sqflite._channel
      .invokeMethod(_methodOpenDatabase, <String, dynamic>{_paramPath: path}); });

  // Special on downgrade elete database
  if (onDowngrade == onDatabaseDowngradeDelete) {
    // Downgrading will delete the database and open it again
    Future _onDatabaseDowngradeDelete(
        Database db, int oldVersion, int newVersion) async {
      // This is tricky as we are in a middel of opening a database
      // need to close what is being done and retart
      await db.execute("ROLLBACK;");
      await db.close();
      await deleteDatabase(db.path);

      // get a new database id after open
      db._id = await Sqflite._channel.invokeMethod(
          _methodOpenDatabase, <String, dynamic>{_paramPath: path});

      // no end transaction it will be done
      await db._beginTransaction(exclusive: true);
      if (onCreate != null) {
        await onCreate(db, version);
      }
    }

    onDowngrade = _onDatabaseDowngradeDelete;
  }

  Database database = new Database._(path, databaseId);
  if (version != null) {
    if (version == 0) {
      throw new ArgumentError("version cannot be set to 0 in openDatabase");
    }
    // init
    await database.inTransaction(() async {
      //print("opening...");
      int oldVersion = await database.getVersion();
      //print("got version");
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
