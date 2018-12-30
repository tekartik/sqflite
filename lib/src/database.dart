import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite/src/batch.dart';
import 'package:sqflite/src/constant.dart' hide lockWarningDuration;
import 'package:sqflite/src/database_factory.dart';
import 'package:sqflite/src/exception.dart';
import 'package:sqflite/src/sqflite_impl.dart';
import 'package:sqflite/src/sql_builder.dart';
import 'package:sqflite/src/transaction.dart';
import 'package:sqflite/src/utils.dart';
import 'package:synchronized/synchronized.dart';

abstract class SqfliteDatabaseExecutor implements DatabaseExecutor {
  SqfliteTransaction get txn;

  SqfliteDatabase get db;

  /// Execute an SQL query with no return value
  @override
  Future<void> execute(String sql, [List<dynamic> arguments]) =>
      db.txnExecute<dynamic>(txn, sql, arguments);

  /// Execute a raw SQL INSERT query
  ///
  /// Returns the last inserted record id
  @override
  Future<int> rawInsert(String sql, [List<dynamic> arguments]) =>
      db.txnRawInsert(txn, sql, arguments);

  /// Insert a row into a table, where the keys of [values] correspond to
  /// column names
  @override
  Future<int> insert(String table, Map<String, dynamic> values,
      {String nullColumnHack, ConflictAlgorithm conflictAlgorithm}) {
    final SqlBuilder builder = SqlBuilder.insert(table, values,
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
      List<dynamic> whereArgs,
      String groupBy,
      String having,
      String orderBy,
      int limit,
      int offset}) {
    final SqlBuilder builder = SqlBuilder.query(table,
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

  /// Execute a raw SQL SELECT query
  ///
  /// Returns a list of rows that were found
  @override
  Future<List<Map<String, dynamic>>> rawQuery(String sql,
          [List<dynamic> arguments]) =>
      db.txnRawQuery(txn, sql, arguments);

  /// Execute a raw SQL UPDATE query
  ///
  /// Returns the number of changes made
  @override
  Future<int> rawUpdate(String sql, [List<dynamic> arguments]) =>
      db.txnRawUpdate(txn, sql, arguments);

  /// Convenience method for updating rows in the database.
  ///
  /// Update [table] with [values], a map from column names to new column
  /// values. null is a valid value that will be translated to NULL.
  ///
  /// [where] is the optional WHERE clause to apply when updating.
  /// Passing null will update all rows.
  ///
  /// You may include ?s in the where clause, which will be replaced by the
  /// values from [whereArgs]
  ///
  /// [conflictAlgorithm] (optional) specifies algorithm to use in case of a
  /// conflict. See [ConflictResolver] docs for more details
  @override
  Future<int> update(String table, Map<String, dynamic> values,
      {String where,
      List<dynamic> whereArgs,
      ConflictAlgorithm conflictAlgorithm}) {
    final SqlBuilder builder = SqlBuilder.update(table, values,
        where: where,
        whereArgs: whereArgs,
        conflictAlgorithm: conflictAlgorithm);
    return rawUpdate(builder.sql, builder.arguments);
  }

  /// Executes a raw SQL DELETE query
  ///
  /// Returns the number of changes made
  @override
  Future<int> rawDelete(String sql, [List<dynamic> arguments]) =>
      rawUpdate(sql, arguments);

  /// Convenience method for deleting rows in the database.
  ///
  /// Delete from [table]
  ///
  /// [where] is the optional WHERE clause to apply when updating. Passing null
  /// will update all rows.
  ///
  /// You may include ?s in the where clause, which will be replaced by the
  /// values from [whereArgs]
  ///
  /// [conflictAlgorithm] (optional) specifies algorithm to use in case of a
  /// conflict. See [ConflictResolver] docs for more details
  ///
  /// Returns the number of rows affected if a whereClause is passed in, 0
  /// otherwise. To remove all rows and get a count pass "1" as the
  /// whereClause.
  @override
  Future<int> delete(String table, {String where, List<dynamic> whereArgs}) {
    final SqlBuilder builder =
        SqlBuilder.delete(table, where: where, whereArgs: whereArgs);
    return rawDelete(builder.sql, builder.arguments);
  }
}

class SqfliteDatabaseOpenHelper {
  SqfliteDatabaseOpenHelper(this.factory, this.path, this.options);

  final SqfliteDatabaseFactory factory;
  final OpenDatabaseOptions options;
  final Lock lock = Lock();
  final String path;
  SqfliteDatabase sqfliteDatabase;

  SqfliteDatabase newDatabase(String path) => factory.newDatabase(this, path);

  bool get isOpen => sqfliteDatabase != null;

  // Future<SqfliteDatabase> get databaseReady => _completer.future;

  // open or return the one opened
  Future<SqfliteDatabase> openDatabase() async {
    if (!isOpen) {
      return await lock.synchronized(() async {
        if (!isOpen) {
          final SqfliteDatabase database = newDatabase(path);
          await database.doOpen(options);
          sqfliteDatabase = database;
        }
        return sqfliteDatabase;
      });
    }
    return sqfliteDatabase;
  }

  Future<void> closeDatabase(SqfliteDatabase sqfliteDatabase) async {
    if (isOpen) {
      await lock.synchronized(() async {
        if (!isOpen) {
          return;
        } else {
          await sqfliteDatabase.doClose();
          factory.doCloseDatabase(sqfliteDatabase);
          this.sqfliteDatabase = null;
        }
      });
    }
  }
}

class SqfliteDatabase extends SqfliteDatabaseExecutor implements Database {
  SqfliteDatabase(this.openHelper, this._path, {this.options});

  // save the open helper for proper closing
  final SqfliteDatabaseOpenHelper openHelper;
  OpenDatabaseOptions options;

  SqfliteDatabaseFactory get factory => openHelper.factory;

  @override
  bool get readOnly => openHelper?.options?.readOnly == true;

  @override
  SqfliteDatabase get db => this;

  @override
  bool get isOpen => openHelper.isOpen;

  @override
  String get path => _path;
  String _path;

  // only set during inTransaction to allow transaction during open
  int transactionRefCount = 0;

  // Not null during opening
  // default transaction used during opening
  SqfliteTransaction openTransaction;

  @override
  SqfliteTransaction get txn => openTransaction;

  // non-reentrant lock
  final Lock rawLock = Lock();

  // Its internal id
  int id;

  Map<String, dynamic> get baseDatabaseMethodArguments {
    final Map<String, dynamic> map = <String, dynamic>{
      paramId: id,
    };
    return map;
  }

  @override
  Batch batch() {
    return SqfliteDatabaseBatch(this);
  }

  Future<T> invokeMethod<T>(String method, [dynamic arguments]) =>
      factory.invokeMethod(method, arguments);

  @override
  Future<T> devInvokeMethod<T>(String method, [dynamic arguments]) {
    return invokeMethod<T>(
        method,
        (arguments ?? <String, dynamic>{})
          ..addAll(baseDatabaseMethodArguments));
  }

  @override
  Future<T> devInvokeSqlMethod<T>(String method, String sql,
      [List<dynamic> arguments]) {
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
      // Simple timeout warning if we cannot get the lock after XX seconds
      final bool handleTimeoutWarning =
          (lockWarningDuration != null && lockWarningCallback != null);
      Completer<dynamic> timeoutCompleter;
      if (handleTimeoutWarning) {
        timeoutCompleter = Completer<dynamic>();
      }

      // Grab the lock
      final Future<T> operation = rawLock.synchronized(() {
        if (handleTimeoutWarning) {
          timeoutCompleter.complete();
        }
        return action(txn);
      });
      // Simply warn the developer as this could likely be a deadlock
      if (handleTimeoutWarning) {
        timeoutCompleter.future.timeout(lockWarningDuration, onTimeout: () {
          lockWarningCallback();
        });
      }
      return await operation;
    }
  }

  /// synchronized call to the database
  /// not re-entrant
  Future<T> txnWriteSynchronized<T>(
          Transaction txn, Future<T> action(Transaction txn)) =>
      txnSynchronized(txn, action);

  /// for sql without return values
  Future<T> txnExecute<T>(SqfliteTransaction txn, String sql,
      [List<dynamic> arguments]) {
    return txnWriteSynchronized<T>(txn, (_) {
      return invokeExecute<T>(sql, arguments);
    });
  }

  Future<T> invokeExecute<T>(String sql, List<dynamic> arguments) {
    return wrapDatabaseException(() {
      return invokeMethod(
          methodExecute,
          <String, dynamic>{paramSql: sql, paramSqlArguments: arguments}
            ..addAll(baseDatabaseMethodArguments));
    });
  }

  /// for INSERT sql query
  /// returns the last inserted record id
  Future<int> txnRawInsert(
      SqfliteTransaction txn, String sql, List<dynamic> arguments) {
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
      SqfliteTransaction txn, String sql, List<dynamic> arguments) {
    return txnSynchronized(txn, (_) {
      return wrapDatabaseException(() async {
        final dynamic result = await invokeMethod<dynamic>(
            methodQuery,
            <String, dynamic>{paramSql: sql, paramSqlArguments: arguments}
              ..addAll(baseDatabaseMethodArguments));
        return queryResultToList(result);
      });
    });
  }

  /// for INSERT sql query
  /// returns the last inserted record id
  Future<int> txnRawUpdate(
      SqfliteTransaction txn, String sql, List<dynamic> arguments) {
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
      {bool noResult, bool continueOnError}) {
    return txnWriteSynchronized(txn, (_) {
      return wrapDatabaseException<List<dynamic>>(() async {
        final Map<String, dynamic> arguments = <String, dynamic>{
          paramOperations: batch.operations
        }..addAll(baseDatabaseMethodArguments);
        if (noResult == true) {
          arguments[paramNoResult] = noResult;
        }
        if (continueOnError == true) {
          arguments[paramContinueOnError] = continueOnError;
        }
        final List<dynamic> results =
            await invokeMethod(methodBatch, arguments);

        // Typically when noResult is true
        if (results == null) {
          return null;
        }
        // dart2 - wrap if we need to support more results than just int
        return BatchResults.from(results);
      });
    });
  }

  @override
  Future<List<dynamic>> applyBatch(Batch batch,
      {bool exclusive, bool noResult}) {
    return transaction((Transaction txn) {
      final SqfliteTransaction sqfliteTransaction = txn;
      final SqfliteBatch sqfliteBatch = batch;
      return txnApplyBatch(sqfliteTransaction, sqfliteBatch,
          noResult: noResult);
    }, exclusive: exclusive);
  }

  Future<SqfliteTransaction> beginTransaction({bool exclusive}) async {
    final SqfliteTransaction txn = SqfliteTransaction(this);
    // never create transaction in read-only mode
    if (readOnly != true) {
      if (exclusive == true) {
        await txnExecute<dynamic>(txn, "BEGIN EXCLUSIVE");
      } else {
        await txnExecute<dynamic>(txn, "BEGIN IMMEDIATE");
      }
    }
    return txn;
  }

  Future<void> endTransaction(SqfliteTransaction txn) async {
    // never commit transaction in read-only mode
    if (readOnly != true) {
      if (txn.successfull == true) {
        await txnExecute<dynamic>(txn, "COMMIT");
      } else {
        await txnExecute<dynamic>(txn, "ROLLBACK");
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
        final SqfliteTransaction sqfliteTransaction = txn;
        sqfliteTransaction.successfull = successfull;
        await endTransaction(sqfliteTransaction);
      }
    }
    return result;
  }

  @override
  Future<T> transaction<T>(Future<T> action(Transaction txn),
      {bool exclusive}) {
    return txnWriteSynchronized<T>(txn, (Transaction txn) async {
      return _runTransaction(txn, action, exclusive: exclusive);
    });
  }

  ///
  /// Get the database inner version
  ///
  @override
  Future<int> getVersion() async {
    final List<Map<String, dynamic>> rows =
        await rawQuery("PRAGMA user_version;");
    return Sqflite.firstIntValue(rows);
  }

  ///
  /// Set the database inner version
  /// Used internally for open helpers and automatic versioning
  ///
  @override
  Future<void> setVersion(int version) async {
    await execute("PRAGMA user_version = $version;");
  }

  /// Close the database. Cannot be access anymore
  @override
  Future<void> close() => openHelper.closeDatabase(this);

  /// Close the database. Cannot be access anymore
  Future<void> doClose() => _closeDatabase(id);

  @override
  String toString() {
    return "$id $path";
  }

  Future<int> openDatabase() async {
    final Map<String, dynamic> params = <String, dynamic>{paramPath: path};
    if (readOnly == true) {
      params[paramReadOnly] = true;
    } else {
      // create the folder if needed (needed for iOS)
      await factory.createParentDirectory(path);
    }
    return await wrapDatabaseException<int>(() {
      return invokeMethod<int>(methodOpenDatabase, params);
    });
  }

  Future<void> _closeDatabase(int databaseId) {
    return wrapDatabaseException<dynamic>(() {
      return invokeMethod<dynamic>(
          methodCloseDatabase, <String, dynamic>{paramId: databaseId});
    });
  }

  // To call during open
  // not exported
  Future<SqfliteDatabase> doOpen(OpenDatabaseOptions options) async {
    if (options.version != null) {
      if (options.version == 0) {
        throw ArgumentError("version cannot be set to 0 in openDatabase");
      }
    } else {
      if (options.onCreate != null) {
        throw ArgumentError("onCreate must be null if no version is specified");
      }
      if (options.onUpgrade != null) {
        throw ArgumentError(
            "onUpgrade must be null if no version is specified");
      }
      if (options.onDowngrade != null) {
        throw ArgumentError(
            "onDowngrade must be null if no version is specified");
      }
    }
    int databaseId = await openDatabase();
    this.options = options;

    try {
      // Special on downgrade delete database
      if (options.onDowngrade == onDatabaseDowngradeDelete) {
        // Downgrading will delete the database and open it again
        Future<void> _onDatabaseDowngradeDelete(
            Database _db, int oldVersion, int newVersion) async {
          final SqfliteDatabase db = _db;
          // This is tricky as we are in the middle of opening a database
          // need to close what is being done and restart
          await db.execute("ROLLBACK;");
          await db.doClose();
          await deleteDatabase(db.path);

          // get a new database id after open
          db.id = databaseId = await openDatabase();

          try {
            // Since we deleted the database re-run the needed first steps:
            // onConfigure then onCreate
            if (options.onConfigure != null) {
              await options.onConfigure(db);
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
          if (options.onCreate != null) {
            await options.onCreate(db, options.version);
          }
        }

        options.onDowngrade = _onDatabaseDowngradeDelete;
      }

      id = databaseId;

      // create dummy open transaction
      openTransaction = SqfliteTransaction(this);

      // first configure it
      if (options.onConfigure != null) {
        await options.onConfigure(this);
      }

      if (options.version != null) {
        await transaction((Transaction txn) async {
          // Set the current transaction as the open one
          // to allow direct database call during open
          final SqfliteTransaction sqfliteTransaction = txn;
          openTransaction = sqfliteTransaction;

          final int oldVersion = await getVersion();
          if (oldVersion == null || oldVersion == 0) {
            if (options.onCreate != null) {
              await options.onCreate(this, options.version);
            } else if (options.onUpgrade != null) {
              await options.onUpgrade(this, 0, options.version);
            }
          } else if (options.version > oldVersion) {
            if (options.onUpgrade != null) {
              await options.onUpgrade(this, oldVersion, options.version);
            }
          } else if (options.version < oldVersion) {
            if (options.onDowngrade != null) {
              await options.onDowngrade(this, oldVersion, options.version);
            }
          }
          await setVersion(options.version);
        }, exclusive: true);
      }

      if (options.onOpen != null) {
        await options.onOpen(this);
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
