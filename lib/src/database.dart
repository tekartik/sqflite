import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite/src/batch.dart';
import 'package:sqflite/src/constant.dart';
import 'package:sqflite/src/exception.dart';
import 'package:sqflite/src/sqflite_impl.dart';
import 'package:sqflite/src/sql_builder.dart';
import 'package:sqflite/src/transaction.dart';
import 'package:sqflite/src/utils.dart';
import 'package:synchronized/synchronized.dart';

abstract class SqfliteDatabaseExecutor {
  SqfliteTransaction get txn;

  SqfliteDatabase get db;

  /// for sql without return values
  Future execute(String sql, [List arguments]) =>
      db.txnExecute(txn, sql, arguments);

  /// for INSERT sql query
  /// returns the last inserted record id
  Future<int> rawInsert(String sql, [List arguments]) =>
      db.txnRawInsert(txn, sql, arguments);

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

  /// for SELECT sql query
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List arguments]) =>
      db.txnRawQuery(txn, sql, arguments);

  /// for UPDATE sql query
  /// return the number of changes made
  Future<int> rawUpdate(String sql, [List arguments]) =>
      db.txnRawUpdate(txn, sql, arguments);

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

  ///
  /// Get the database inner version
  ///
  Future<int> getVersion() async {
    List<Map<String, dynamic>> rows = await rawQuery("PRAGMA user_version;");
    return Sqflite.firstIntValue(rows);
  }

  ///
  /// Set the database inner version
  /// Used internally for open helpers and automatic versioning
  ///
  Future setVersion(int version) async {
    await execute("PRAGMA user_version = $version;");
  }
}

class SqfliteDatabase extends SqfliteDatabaseExecutor implements Database {
  SqfliteDatabase(this._path, this.id) {
    // For now keep a lock for all access
    if (supportsConcurrency) {
      _writeLock = new SynchronizedLock();
    } else {
      _writeLock = _lock;
    }
  }

  var _lock = new SynchronizedLock();
  var _writeLock;

  SynchronizedLock get transactionLock => _lock;

  @override
  SqfliteDatabase get db => this;

  String get path => _path;
  String _path;

  // only set during inTransaction to allow recursivity in transactions
  int transactionRefCount = 0;

  // only set during inTransaction to allow recursivity
  //int transactionRefCount = 0;

  // Not null during opening
  // default transaction used during opening
  SqfliteTransaction openTransaction;
  SqfliteTransaction get txn => openTransaction;

  // non-reentrant lock
  var _rawLock = new Lock();

  // Its internal id
  int id;

  Map<String, dynamic> get baseDatabaseMethodArguments {
    var map = <String, dynamic>{
      paramId: id,
    };
    return map;
  }

  @override
  Batch batch() {
    return new SqfliteBatch(this);
  }

  @override
  Future devInvokeMethod(String method, [arguments]) {
    return invokeMethod(
        method,
        (arguments ?? <String, dynamic>{})
          ..addAll(baseDatabaseMethodArguments));
  }

  @override
  Future devInvokeSqlMethod(String method, String sql, [List arguments]) {
    return devInvokeMethod(
        method, <String, dynamic>{paramSql: sql, paramSqlArguments: arguments});
  }

  /// synchronized call to the database
  /// not re-entrant
  Future<T> txnSynchronized<T>(Transaction txn, Future<T> action()) async {
    // If in a transaction, execute right away
    if ((txn ?? openTransaction) != null) {
      return await action();
    } else {
      T result = await _rawLock.synchronized(action);
      return result;
    }
  }

  /// synchronized call to the database
  /// not re-entrant
  Future<T> txnWriteSynchronized<T>(Transaction txn, Future<T> action()) =>
      txnSynchronized(txn, action);

  /// for sql without return values
  Future txnExecute(SqfliteTransaction txn, String sql, List arguments) {
    return txnWriteSynchronized(txn, () {
      return wrapDatabaseException(() {
        return invokeMethod(
            methodExecute,
            <String, dynamic>{paramSql: sql, paramSqlArguments: arguments}
              ..addAll(baseDatabaseMethodArguments));
      });
    });
  }

  /// for INSERT sql query
  /// returns the last inserted record id
  Future<int> txnRawInsert(SqfliteTransaction txn, String sql, List arguments) {
    return txnWriteSynchronized(txn, () {
      return wrapDatabaseException(() {
        return invokeMethod<int>(
            methodInsert,
            <String, dynamic>{paramSql: sql, paramSqlArguments: arguments}
              ..addAll(baseDatabaseMethodArguments));
      });
    });
  }

  Future<List<Map<String, dynamic>>> txnRawQuery(
      SqfliteTransaction txn, String sql, List arguments) {
    return txnSynchronized(txn, () {
      return wrapDatabaseException(() async {
        var result = await invokeMethod(
            methodQuery,
            <String, dynamic>{paramSql: sql, paramSqlArguments: arguments}
              ..addAll(baseDatabaseMethodArguments));
        return queryResultToList(result);
      });
    });
  }

  /// for INSERT sql query
  /// returns the last inserted record id
  Future<int> txnRawUpdate(SqfliteTransaction txn, String sql, List arguments) {
    return txnWriteSynchronized(txn, () {
      return wrapDatabaseException(() {
        return invokeMethod<int>(
            methodUpdate,
            <String, dynamic>{paramSql: sql, paramSqlArguments: arguments}
              ..addAll(baseDatabaseMethodArguments));
      });
    });
  }

  Future<SqfliteTransaction> beginTransaction({bool exclusive}) async {
    SqfliteTransaction txn = new SqfliteTransaction(this);
    if (exclusive == true) {
      await execute("BEGIN EXCLUSIVE;");
    } else {
      await execute("BEGIN IMMEDIATE;");
    }
    return txn;
  }

  Future endTransaction(SqfliteTransaction txn) async {
    if (txn.successfull == true) {
      await execute("COMMIT;");
    } else {
      await execute("ROLLBACK;");
    }
  }

  @override
  Future<T> transaction<T>(Future<T> action(Transaction), {bool exclusive}) {
    return txnWriteSynchronized<T>(null, () async {
      SqfliteTransaction txn;
      bool successfull;
      if (transactionRefCount++ == 0) {
        txn = await beginTransaction(exclusive: exclusive);
      }
      T result;
      try {
        result = await action(txn);
        successfull = true;
      } finally {
        if (--transactionRefCount == 0) {
          txn.successfull = successfull;
          await endTransaction(txn);
        }
      }
      return result;
    });
  }

  ///
  /// synchronized all write calls to the database
  /// ensure that no other calls outside the inner action will
  /// write the database
  ///
  Future<T> writeSynchronized<T>(Future<T> action()) async {
    T result = await _writeLock.synchronized(action);
    return result;
  }

  ///
  /// Simple soon to be deprecated (used Zone) transaction mechanism
  ///
  Future<T> inTransaction<T>(Future<T> action(), {bool exclusive}) {
    return writeSynchronized<T>(() async {
      SqfliteTransaction transaction;
      bool successfull;
      if (transactionRefCount++ == 0) {
        transaction = await beginTransaction(exclusive: exclusive);
      }
      T result;
      try {
        result = await action();
        successfull = true;
      } finally {
        if (--transactionRefCount == 0) {
          transaction.successfull = successfull;
          await endTransaction(transaction);
        }
      }
      return result;
    });
  }

  ///
  /// synchronized call to the database
  /// ensure that no other calls outside the inner action will
  /// access the database
  /// Use [Zone] so should be deprecated soon
  ///
  Future<T> synchronized<T>(Future<T> action()) async {
    if (supportsConcurrency) {
      return await action();
    } else {
      T result = await _lock.synchronized(action);
      return result;
    }
  }

  /// Close the database. Cannot be access anymore
  Future close() => _closeDatabase(id);

  @override
  String toString() {
    return "${id} $path";
  }
}

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
          Database _db, int oldVersion, int newVersion) async {
        SqfliteDatabase db = _db as SqfliteDatabase;
        // This is tricky as we are in a middel of opening a database
        // need to close what is being done and retart
        await db.execute("ROLLBACK;");
        await db.close();
        await deleteDatabase(db.path);

        // get a new database id after open
        db.id = databaseId = await _openDatabase(path);

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
          await db.beginTransaction(exclusive: true);
          rethrow;
        }

        // no end transaction it will be done later before calling then onOpen
        await db.beginTransaction(exclusive: true);
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
      await database.inTransaction(() async {
        int oldVersion = await database.getVersion();
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

Future<int> _openDatabase(String path) {
  return wrapDatabaseException<int>(() {
    return invokeMethod<int>(
        methodOpenDatabase, <String, dynamic>{paramPath: path});
  });
}

Future _closeDatabase(int databaseId) {
  return wrapDatabaseException(() {
    return invokeMethod(
        methodCloseDatabase, <String, dynamic>{paramId: databaseId});
  });
}
