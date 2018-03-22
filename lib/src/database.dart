import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite/src/batch.dart';
import 'package:sqflite/src/constant.dart';
import 'package:sqflite/src/exception.dart';
import 'package:sqflite/src/sqflite_impl.dart';
import 'package:sqflite/src/sqflite_impl.dart' as impl;
import 'package:sqflite/src/sql_builder.dart';
import 'package:sqflite/src/transaction.dart';
import 'package:sqflite/src/utils.dart';
import 'package:synchronized/synchronized.dart';

abstract class SqfliteDatabaseExecutor implements DatabaseExecutor {
  SqfliteTransaction get txn;

  SqfliteDatabase get db;

  /// for sql without return values
  @override
  Future execute(String sql, [List arguments]) =>
      db.txnExecute(txn, sql, arguments);

  /// for INSERT sql query
  /// returns the last inserted record id
  @override
  Future<int> rawInsert(String sql, [List arguments]) =>
      db.txnRawInsert(txn, sql, arguments);

  /// INSERT helper
  @override
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
  ///
  /// @return the items found
  ///
  @override
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
  @override
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List arguments]) =>
      db.txnRawQuery(txn, sql, arguments);

  /// for UPDATE sql query
  /// return the number of changes made
  @override
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
  @override
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
  @override
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
  @override
  Future<int> delete(String table, {String where, List whereArgs}) {
    SqlBuilder builder =
        new SqlBuilder.delete(table, where: where, whereArgs: whereArgs);
    return rawDelete(builder.sql, builder.arguments);
  }
}

class SqfliteDatabase extends SqfliteDatabaseExecutor implements Database {
  bool readOnly;
  SqfliteDatabase(this._path);

  // will be removed once writeSynchronized and synchronized are removed

  SynchronizedLock get synchronizedLock =>
      rawSynchronizedlock ??= new SynchronizedLock();
  SynchronizedLock get writeSynchronizedLock => rawWriteSynchronizedLock ??=
      (supportsConcurrency ? new SynchronizedLock() : synchronizedLock);
  SynchronizedLock rawSynchronizedlock;
  SynchronizedLock rawWriteSynchronizedLock;

  SynchronizedLock get transactionLock => rawSynchronizedlock;

  @override
  SqfliteDatabase get db => this;

  @override
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
  final rawLock = new Lock();

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
    return new SqfliteDatabaseBatch(this);
  }

  Future<T> invokeMethod<T>(String method, [dynamic arguments]) =>
      impl.invokeMethod(method, arguments);

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
  /// Ugly compatibility step to not support older synchronized
  /// mechanism
  Future<T> txnSynchronized<T>(
      Transaction txn, Future<T> action(Transaction txn)) async {
    // If in a transaction, execute right away
    if (txn != null) {
      return await action(txn);
    } else {
      T result;
      bool useOldSynchronized = false;
      // We use the old synchronized lock as soon as it is used
      // We might have pending queries that would return
      if (rawSynchronizedlock == null) {
        result = await rawLock.synchronized(() {
          if (rawSynchronizedlock != null) {
            useOldSynchronized = true;
          } else {
            return action(txn);
          }
        });
      } else {
        useOldSynchronized = true;
      }

      if (useOldSynchronized) {
        result = await rawSynchronizedlock.synchronized(() => action(txn));
      }
      return result;
    }
  }

  /// synchronized call to the database
  /// not re-entrant
  Future<T> txnWriteSynchronized<T>(
          Transaction txn, Future<T> action(Transaction txn)) =>
      txnSynchronized(txn, action);

  /// for sql without return values
  Future txnExecute(SqfliteTransaction txn, String sql, [List arguments]) {
    return txnWriteSynchronized(txn, (_) {
      return invokeExecute(sql, arguments);
    });
  }

  Future invokeExecute(String sql, List arguments) {
    return wrapDatabaseException(() {
      return invokeMethod(
          methodExecute,
          <String, dynamic>{paramSql: sql, paramSqlArguments: arguments}
            ..addAll(baseDatabaseMethodArguments));
    });
  }

  /// for INSERT sql query
  /// returns the last inserted record id
  Future<int> txnRawInsert(SqfliteTransaction txn, String sql, List arguments) {
    return txnWriteSynchronized(txn, (_) {
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
    return txnSynchronized(txn, (_) {
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
    return txnWriteSynchronized(txn, (_) {
      return wrapDatabaseException(() {
        return invokeMethod<int>(
            methodUpdate,
            <String, dynamic>{paramSql: sql, paramSqlArguments: arguments}
              ..addAll(baseDatabaseMethodArguments));
      });
    });
  }

  Future<List<dynamic>> txnApplyBatch(
      SqfliteTransaction txn, SqfliteBatch batch,
      {bool noResult}) {
    return txnWriteSynchronized(txn, (_) {
      return wrapDatabaseException<List>(() async {
        var arguments = <String, dynamic>{paramOperations: batch.operations}
          ..addAll(baseDatabaseMethodArguments);
        if (noResult == true) {
          arguments[paramNoResult] = noResult;
        }
        List results = await invokeMethod(methodBatch, arguments);

        // Typically when noResult is true
        if (results == null) {
          return null;
        }
        // dart2 - wrap if we need to support more results than just int
        return new BatchResults.from(results);
      });
    });
  }

  @override
  Future<List<dynamic>> applyBatch(Batch batch,
      {bool exclusive, bool noResult}) {
    return transaction((txn) {
      return txnApplyBatch(txn as SqfliteTransaction, batch as SqfliteBatch,
          noResult: noResult);
    }, exclusive: exclusive);
  }

  Future<SqfliteTransaction> beginTransaction({bool exclusive}) async {
    SqfliteTransaction txn = new SqfliteTransaction(this);
    // never create transaction in read-only mode
    if (readOnly != true) {
      if (exclusive == true) {
        await txnExecute(txn, "BEGIN EXCLUSIVE");
      } else {
        await txnExecute(txn, "BEGIN IMMEDIATE");
      }
    }
    return txn;
  }

  Future endTransaction(SqfliteTransaction txn) async {
    // never commit transaction in read-only mode
    if (readOnly != true) {
      if (txn.successfull == true) {
        await txnExecute(txn, "COMMIT");
      } else {
        await txnExecute(txn, "ROLLBACK");
      }
    }
  }

  Future<T> _runTransaction<T>(
      Transaction txn, Future<T> action(Transaction txn),
      {bool exclusive}) async {
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
        (txn as SqfliteTransaction).successfull = successfull;
        await endTransaction((txn as SqfliteTransaction));
      }
    }
    return result;
  }

  @override
  Future<T> transaction<T>(Future<T> action(Transaction txn),
      {bool exclusive}) {
    return txnWriteSynchronized<T>(txn, (txn) async {
      return _runTransaction(txn, action, exclusive: exclusive);
    });
  }

  ///
  /// synchronized all write calls to the database
  /// ensure that no other calls outside the inner action will
  /// write the database
  /// This should be removed once synchronized is removed
  ///
  Future<T> writeSynchronized<T>(Future<T> action()) {
    // this is true once synchronized or inTransaction has been used once
    // All remaining calls will be done in a zone
    //return writeSynchronizedLock.synchronized(action);

    // that should be the necessary step, to check if issue arises
    // especially on first call
    // but anyway this code will disappear
    return writeSynchronizedLock.synchronized(action);
  }

  ///
  /// Simple soon to be deprecated (used Zone) transaction mechanism
  ///
  Future<T> inTransaction<T>(Future<T> action(), {bool exclusive}) {
    return writeSynchronized<T>(() async {
      return _runTransaction(null, (_) => action(), exclusive: exclusive);
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
      T result = await synchronizedLock.synchronized(action);
      return result;
    }
  }

  ///
  /// Get the database inner version
  ///
  @override
  Future<int> getVersion() async {
    List<Map<String, dynamic>> rows = await rawQuery("PRAGMA user_version;");
    return Sqflite.firstIntValue(rows);
  }

  ///
  /// Set the database inner version
  /// Used internally for open helpers and automatic versioning
  ///
  @override
  Future setVersion(int version) async {
    await execute("PRAGMA user_version = $version;");
  }

  /// Close the database. Cannot be access anymore
  Future close() => _closeDatabase(id);

  @override
  String toString() {
    return "${id} $path";
  }

  Future<int> _openDatabase() {
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

  Future<Database> openReadOnlyDatabase() async {
    id = await wrapDatabaseException<int>(() {
      return invokeMethod<int>(methodOpenDatabase,
          <String, dynamic>{paramPath: path, paramReadOnly: true});
    });
    readOnly = true;
    return this;
  }

  // To call during open
  Future<Database> open(
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
    int databaseId = await _openDatabase();

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
          db.id = databaseId = await _openDatabase();

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

      id = databaseId;
      readOnly = false;

      // create dummy open transaction
      openTransaction = new SqfliteTransaction(this);

      // first configure it
      if (onConfigure != null) {
        await onConfigure(this);
      }

      if (version != null) {
        await transaction((txn) async {
          // Set the current transaction as the open one
          // to allow direct database call during open
          openTransaction = txn as SqfliteTransaction;

          int oldVersion = await getVersion();
          if (oldVersion == null || oldVersion == 0) {
            if (onCreate != null) {
              await onCreate(this, version);
            } else if (onUpgrade != null) {
              await onUpgrade(this, 0, version);
            }
          } else if (version > oldVersion) {
            if (onUpgrade != null) {
              await onUpgrade(this, oldVersion, version);
            }
          } else if (version < oldVersion) {
            if (onDowngrade != null) {
              await onDowngrade(this, oldVersion, version);
            }
          }
          await setVersion(version);
        }, exclusive: true);
      }

      if (onOpen != null) {
        await onOpen(this);
      }

      return this;
    } catch (e) {
      await _closeDatabase(databaseId);
      rethrow;
    } finally {
      // clean up open transaction
      openTransaction = null;
    }
  }
}

Future<Database> openDatabase(String path,
    {int version,
    OnDatabaseConfigureFn onConfigure,
    OnDatabaseCreateFn onCreate,
    OnDatabaseVersionChangeFn onUpgrade,
    OnDatabaseVersionChangeFn onDowngrade,
    OnDatabaseOpenFn onOpen}) {
  SqfliteDatabase database = new SqfliteDatabase(path);
  return database.open(
      version: version,
      onConfigure: onConfigure,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
      onDowngrade: onDowngrade,
      onOpen: onOpen);
}

Future<Database> openReadOnlyDatabase(String path) {
  SqfliteDatabase database = new SqfliteDatabase(path);
  return database.openReadOnlyDatabase();
}
