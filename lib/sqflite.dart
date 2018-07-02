import 'dart:async';
//import 'dart:io';

import 'package:sqflite/src/constant.dart';
import 'package:sqflite/src/database.dart' as impl;
import 'package:sqflite/src/database_factory.dart' as impl;
import 'package:sqflite/src/sqflite_impl.dart';
import 'package:sqflite/src/sqflite_impl.dart' as impl;
import 'package:sqflite/src/sql_builder.dart';
import 'package:sqflite/src/database_factory.dart' show databaseFactory;

import 'src/utils.dart';

export 'sql.dart' show ConflictAlgorithm;
export 'src/exception.dart' show DatabaseException;
export 'src/database_factory.dart' show DatabaseFactory, databaseFactory;
export 'src/constant.dart' show inMemoryDatabasePath;

///
/// internal options
///
class SqfliteOptions {
  // true =<0.7.0
  bool queryAsMapList;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'queryAsMapList': queryAsMapList};
  }

  void fromMap(Map<String, dynamic> map) {
    queryAsMapList = map['queryAsMapList'] as bool;
  }
}

///
/// sqflite plugin
///
class Sqflite {
  //static MethodChannel get _channel => channel;
  static bool _debugModeOn = false;

  static Future<String> get platformVersion =>
      invokeMethod<String>(methodGetPlatformVersion);

  /// turn on debug mode if you want to see the SQL query
  /// executed natively
  static Future setDebugModeOn([bool on = true]) async {
    await invokeMethod<dynamic>(methodSetDebugModeOn, on);
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

  // Testing only
  @deprecated
  static Future devSetOptions(SqfliteOptions options) async {
    await invokeMethod<dynamic>(methodOptions, options.toMap());
  }

  // Testing only
  @deprecated
  static Future devInvokeMethod(String method, [dynamic arguments]) async {
    await invokeMethod<dynamic>(method, arguments);
  }

  /// helper to get the first int value in a query
  /// Useful for COUNT(*) queries
  static int firstIntValue(List<Map> list) {
    if (list != null && list.length > 0) {
      return parseInt(list.first?.values?.first);
    }
    return null;
  }

  /// Sqlite has a dead lock warning feature that will print some text
  /// after 10s, you can override the default behavior
  static void setLockWarningInfo({Duration duration, void callback()}) {
    impl.setLockWarningInfo(duration: duration, callback: callback);
  }
}

///
/// Common API for [Database] and [Transaction] to execute SQL commands
///
abstract class DatabaseExecutor {
  /// for sql without return values
  Future execute(String sql, [List arguments]);

  /// for INSERT sql query
  /// returns the last inserted record id
  Future<int> rawInsert(String sql, [List arguments]);

  // INSERT helper
  Future<int> insert(String table, Map<String, dynamic> values,
      {String nullColumnHack, ConflictAlgorithm conflictAlgorithm});

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
      int offset});

  /// for SELECT sql query
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List arguments]);

  /// for UPDATE sql query
  /// return the number of changes made
  Future<int> rawUpdate(String sql, [List arguments]);

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
      {String where, List whereArgs, ConflictAlgorithm conflictAlgorithm});

  /// for DELETE sql query
  /// return the number of changes made
  Future<int> rawDelete(String sql, [List arguments]);

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
  Future<int> delete(String table, {String where, List whereArgs});

  /// Execute all batch operation
  /// The result is a list of the result of each operation in the same order
  /// if [noResult] is true, the result list is empty (i.e. the id inserted
  /// the count of item changed is not returned
  ///
  /// If called on a database a transaction is created
  @Deprecated("User batch.commit() instead")
  Future<List<dynamic>> applyBatch(Batch batch, {bool noResult});

  /// Creates a batch, used for performing multiple operation
  /// in a single atomic operation.
  ///
  /// a batch can be commited using [Batch.commit]
  ///
  /// If the batch was created in a transaction, it will be commited
  /// when the transaction is done
  Batch batch();
}

/// Database transaction
/// to use during a transaction
abstract class Transaction implements DatabaseExecutor {}

///
/// Database to send sql commands, created during [openDatabase]
///
abstract class Database implements DatabaseExecutor {
  /// The path of the database
  String get path;

  /// Close the database. Cannot be access anymore
  Future close();

  /// Calls in action must only be done using the transaction object
  /// using the database will trigger a dead-lock
  Future<T> transaction<T>(Future<T> action(Transaction txn), {bool exclusive});

  ///
  /// Get the database inner version
  ///
  Future<int> getVersion();

  ///
  /// Set the database inner version
  /// Used internally for open helpers and automatic versioning
  ///
  Future setVersion(int version);

  /// testing only
  @deprecated
  Future<T> devInvokeMethod<T>(String method, [dynamic arguments]);

  /// testing only
  @deprecated
  Future<T> devInvokeSqlMethod<T>(String method, String sql, [List arguments]);
}

typedef FutureOr OnDatabaseVersionChangeFn(
    Database db, int oldVersion, int newVersion);
typedef FutureOr OnDatabaseCreateFn(Database db, int version);
typedef FutureOr OnDatabaseOpenFn(Database db);
typedef FutureOr OnDatabaseConfigureFn(Database db);

/// to specify during [openDatabase] for [onDowngrade]
/// Downgrading will always fail
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

///
/// Options for opening the database
/// see [openDatabase] for details
///
abstract class OpenDatabaseOptions {
  factory OpenDatabaseOptions(
      {int version,
      OnDatabaseConfigureFn onConfigure,
      OnDatabaseCreateFn onCreate,
      OnDatabaseVersionChangeFn onUpgrade,
      OnDatabaseVersionChangeFn onDowngrade,
      OnDatabaseOpenFn onOpen,
      bool readOnly = false,
      bool singleInstance = true}) {
    return new impl.SqfliteOpenDatabaseOptions(
        version: version,
        onConfigure: onConfigure,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
        onDowngrade: onDowngrade,
        onOpen: onOpen,
        readOnly: readOnly,
        singleInstance: singleInstance);
  }

  int version;
  OnDatabaseConfigureFn onConfigure;
  OnDatabaseCreateFn onCreate;
  OnDatabaseVersionChangeFn onUpgrade;
  OnDatabaseVersionChangeFn onDowngrade;
  OnDatabaseOpenFn onOpen;
  bool readOnly;
  bool singleInstance;
}

///
/// Open the database at a given path
/// setting a version is optional
/// [onCreate],  [onUpgrade], [onDowngrade] are called in a transaction
///
/// [onConfigure] is called when the database connection is being configured,
/// to enable features such as write-ahead logging or foreign key support.
/// This method is called before [onCreate], [onUpgrade], [onDowngrade]
///
/// [onOpen] is called after [onCreate], [onUpgrade], [onDowngrade] are called
///
/// When [readOnly] is true all other parameters are ignored and the database
/// is opened as is
///
/// When [singleInstance] is true (the default), a single database instance is
/// returned for a given path and other options are ignore if you call
/// openDatabase again if the database is already opened
///
Future<Database> openDatabase(String path,
    {int version,
    OnDatabaseConfigureFn onConfigure,
    OnDatabaseCreateFn onCreate,
    OnDatabaseVersionChangeFn onUpgrade,
    OnDatabaseVersionChangeFn onDowngrade,
    OnDatabaseOpenFn onOpen,
    bool readOnly = false,
    bool singleInstance = true}) {
  var options = new OpenDatabaseOptions(
      version: version,
      onConfigure: onConfigure,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
      onDowngrade: onDowngrade,
      onOpen: onOpen,
      readOnly: readOnly,
      singleInstance: singleInstance);
  return databaseFactory.openDatabase(path, options: options);
}

///
/// Open the database at a given path in read only mode
///
Future<Database> openReadOnlyDatabase(String path) =>
    openDatabase(path, readOnly: true);

///
/// Get the default databases location
///
/// on Android, it is typically data/data/<package_name>/databases
/// on iOS, it is the Documents directory
///
Future<String> getDatabasesPath() => databaseFactory.getDatabasesPath();

///
/// delete the database at the given path
///
Future deleteDatabase(String path) => databaseFactory.deleteDatabase(path);

///
/// A batch is used to perform multiple operation as a single atomic unit.
/// A Batch object can be acquired by calling [Database.batch]. It provides
/// methods for adding operation. None of the operation will be
/// executed (or visible locally) until commit() is called.
///
abstract class Batch {
  /// Commits all of the operations in this batch as a single atomic unit
  /// The result is a list of the result of each operation in the same order
  /// if [noResult] is true, the result list is empty (i.e. the id inserted
  /// the count of item changed is not returned
  ///
  /// During [Database.onCreate], [Database.onUpgrade], [Database.onDowngrade]
  /// (we are already in a transaction) or if the batch was created in a
  /// transaction it will only be commited when
  /// the transaction is commited ([exclusive] is not used then)
  Future<List<dynamic>> commit({bool exclusive, bool noResult});

  /// See [Batch.commit], kept for compatibility...
  @Deprecated("Use Batch.commit instead")
  Future<List<dynamic>> apply({bool exclusive, bool noResult});

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

  /// See [Database.execute];
  void execute(String sql, [List arguments]);

  /// See [Database.query];
  void query(String table,
      {bool distinct,
      List<String> columns,
      String where,
      List whereArgs,
      String groupBy,
      String having,
      String orderBy,
      int limit,
      int offset});

  /// See [Database.query];
  void rawQuery(String sql, [List arguments]);
}
