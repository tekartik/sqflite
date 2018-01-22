import 'dart:async';

import 'package:flutter/services.dart';
import 'package:sqflite/src/constant.dart';
import 'package:sqflite/src/database.dart';
import 'dart:io';
import 'package:sqflite/src/exception.dart';
import 'package:sqflite/src/sql_builder.dart';
import 'package:sqflite/src/sqflite_impl.dart';
import 'src/utils.dart';
import 'package:synchronized/synchronized.dart';
export 'src/exception.dart' show DatabaseException;

///
/// sqflite plugin
///
class Sqflite {
  static MethodChannel get _channel => channel;
  static bool _debugModeOn = false;
  static bool _supportsConcurrency = supportsConcurrency;
  static Future<String> get platformVersion =>
      _channel.invokeMethod(methodGetPlatformVersion);

  /// turn on debug mode if you want to see the SQL query
  /// executed natively
  static Future setDebugModeOn([bool on = true]) async {
    await Sqflite._channel.invokeMethod(methodSetDebugModeOn, on);
  }

  static Future<bool> getDebugModeOn() async {
    return _debugModeOn;
  }

  // To use in code when you want to remove it later
  @deprecated
  static Future devSetDebugModeOn([bool on = true]) {
    _debugModeOn = on;
    return setDebugModeOn(on);
  }

  /// helper to get the first int value in a query
  /// Useful for COUNT(*) queries
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
/// Database support
/// to send raw sql commands
///
abstract class Database {
  /// The path of the database
  String get path;

  int get _id => (this as SqfliteDatabase).id;

  Database() {
    // For now keep a lock for all access
    if (Sqflite._supportsConcurrency) {
      _writeLock = new SynchronizedLock();
    } else {
      _writeLock = _lock;
    }
  }

  // only set during inTransaction to allow recursivity
  int _transactionRefCount = 0;

  var _lock = new SynchronizedLock();
  var _writeLock;

  SynchronizedLock get transactionLock => _lock;

  @override
  String toString() {
    return "${_id} $path";
  }

  /// Close the database. Cannot be access anymore
  Future close() => _closeDatabase(_id);

  /// for sql without return values
  Future execute(String sql, [List arguments]) {
    return writeSynchronized(() {
      return wrapDatabaseException(() {
        return Sqflite._channel.invokeMethod(
            methodExecute,
            <String, dynamic>{paramSql: sql, paramSqlArguments: arguments}
              ..addAll(_baseDatabaseMethodArguments));
      });
    });
  }

  /// for INSERT sql query
  /// returns the last inserted record id
  Future<int> rawInsert(String sql, [List arguments]) {
    return writeSynchronized(() {
      return wrapDatabaseException(() {
        return Sqflite._channel.invokeMethod(
            methodInsert,
            <String, dynamic>{paramSql: sql, paramSqlArguments: arguments}
              ..addAll(_baseDatabaseMethodArguments));
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
  Future<int> rawUpdate(String sql, [List arguments]) {
    return writeSynchronized(() {
      return wrapDatabaseException(() {
        return Sqflite._channel.invokeMethod(
            methodUpdate,
            <String, dynamic>{paramSql: sql, paramSqlArguments: arguments}
              ..addAll(_baseDatabaseMethodArguments));
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

  Map<String, dynamic> get _baseDatabaseMethodArguments =>
      (this as SqfliteDatabase).baseDatabaseMethodArguments;

  /// for SELECT sql query
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List arguments]) {
    return synchronized(() {
      return wrapDatabaseException(() async {
        return await Sqflite._channel.invokeMethod(
            methodQuery,
            <String, dynamic>{paramSql: sql, paramSqlArguments: arguments}
              ..addAll(_baseDatabaseMethodArguments));
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
  /// synchronized call to the database
  /// ensure that no other calls outside the inner action will
  /// access the database
  ///
  FutureOr synchronized(action()) {
    if (Sqflite._supportsConcurrency) {
      return action;
    } else {
      return _lock.synchronized(action);
    }
  }

  ///
  /// synchronized all write calls to the database
  /// ensure that no other calls outside the inner action will
  /// write the database
  ///
  Future writeSynchronized(action()) {
    return _writeLock.synchronized(action);
  }

  ///
  /// Simple transaction mechanism
  ///
  Future inTransaction(action(), {bool exclusive}) {
    return writeSynchronized(() async {
      _Transaction transaction;
      bool successfull;
      if (_transactionRefCount++ == 0) {
        transaction = await _beginTransaction(exclusive: exclusive);
      }
      var result;
      try {
        result = await action();
        successfull = true;
      } finally {
        if (--_transactionRefCount == 0) {
          transaction.successfull = successfull;
          await _endTransaction(transaction);
        }
      }
      return result;
    });
  }

  ///
  /// Get the database inner version
  ///
  Future<int> getVersion() async {
    return parseInt(
        _first(await rawQuery("PRAGMA user_version;"))?.values?.first);
  }

  ///
  /// Set the database inner version
  /// Used internally for open helpers and automatic versioning
  ///
  Future setVersion(int version) async {
    await execute("PRAGMA user_version = $version;");
  }

  /// Creates a batch, used for performing multiple operation
  /// in a single atomic operation.
  Batch batch();
}

typedef FutureOr OnDatabaseVersionChangeFn(
    Database db, int oldVersion, int newVersion);
typedef FutureOr OnDatabaseCreateFn(Database db, int newVersion);
typedef FutureOr OnDatabaseOpenFn(Database db);
typedef FutureOr OnDatabaseConfigureFn(Database db);

// Downgrading will always fail
Future onDatabaseVersionChangeError(
    Database db, int oldVersion, int newVersion) async {
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

Future _closeDatabase(int databaseId) {
  return wrapDatabaseException(() {
    return Sqflite._channel.invokeMethod(
        methodCloseDatabase, <String, dynamic>{paramId: databaseId});
  });
}

Future<int> _openDatabase(String path) {
  return wrapDatabaseException(() {
    return Sqflite._channel
        .invokeMethod(methodOpenDatabase, <String, dynamic>{paramPath: path});
  });
}

///
/// Open the database at a given path
/// setting a version is optional
/// [onConfigure], [onCreate],  [onUpgrade], [onDowngrade] are called in a transaction
///
/// [onConfigure] is alled when the database connection is being configured,
/// to enable features such as write-ahead logging or foreign key support.
/// This method is called before [onCreate], [onUpgrade], [onDowngrade]
/// [onOpen] are called. It should not modify the database except to configure
/// the database connection as required.
///
Future<Database> openDatabase(String path,
    {int version,
    OnDatabaseConfigureFn onConfigure,
    OnDatabaseCreateFn onCreate,
    OnDatabaseVersionChangeFn onUpgrade,
    OnDatabaseVersionChangeFn onDowngrade,
    OnDatabaseOpenFn onOpen}) async {
  if (version != null) {
    if (version == 0) {
      throw new ArgumentError("version cannot be set to 0 in openDatabase");
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
  int databaseId = await _openDatabase(path);

  try {
    // Special on downgrade delete database
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
        (db as SqfliteDatabase).id = databaseId = await _openDatabase(path);

        try {
          // Since we deleted the database re-run the needed first steps:
          // onConfigure then onCreate
          if (onConfigure != null) {
            await onConfigure(db);
          }
        } catch (e) {
          // This exception is sometimes hard te catch
          // during development
          print(e);

          // create a transaction just to make the current transaction happy
          await db._beginTransaction(exclusive: true);
          rethrow;
        }

        // no end transaction it will be done later before calling then onOpen
        await db._beginTransaction(exclusive: true);
        if (onCreate != null) {
          await onCreate(db, version);
        }
      }

      onDowngrade = _onDatabaseDowngradeDelete;
    }

    Database database = new SqfliteDatabase(path, databaseId);

    // first configure it
    if (onConfigure != null) {
      await onConfigure(database);
    }

    if (version != null) {
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
    }

    if (onOpen != null) {
      await onOpen(database);
    }

    return database;
  } catch (e) {
    await _closeDatabase(databaseId);
    rethrow;
  }
}

///
/// delete the database at the given path
///
Future deleteDatabase(String path) async {
  try {
    await new File(path).delete(recursive: true);
  } catch (e) {
    print(e);
  }
}

///
/// A batch is used to perform multiple operation as a single atomic unit.
/// A Batch object can be acquired by calling [Database.batch]. It provides
/// methods for adding operation. None of the operation will be
/// executed (or visible locally) until commit() is called.
///
abstract class Batch {
  // Commits all of the operations in this batch as a single atomic unit
  // The result is a list of the result of each operation in the same order
  // if [noResult] is true, the result list is empty (i.e. the id inserted
  // the count of item changed is not returned
  Future<List<dynamic>> commit({bool exclusive, bool noResult});

  /// See [Database.rawInsert]
  void rawInsert(String sql, [List arguments]);

  /// See [Database.insert]
  void insert(String table, Map<String, dynamic> values,
      {String nullColumnHack, ConflictAlgorithm conflictAlgorithm});

  /// See [Database.rawUpdate]
  void rawUpdate(String sql, [List arguments]);

  /// See [Database.update]
  void update(String table, Map<String, dynamic> values,
      {String where, List whereArgs, ConflictAlgorithm conflictAlgorithm});

  /// See [Database.rawDelete]
  void rawDelete(String sql, [List arguments]);

  /// See [Database.delete]
  void delete(String table, {String where, List whereArgs});
}
