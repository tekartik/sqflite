import 'dart:async';
import 'dart:io';

import 'package:sqflite/src/constant.dart';
import 'package:sqflite/src/database.dart' as impl;
import 'package:sqflite/src/sqflite_impl.dart';
import 'package:sqflite/src/sql_builder.dart';

import 'src/utils.dart';

export 'sql.dart' show ConflictAlgorithm;
export 'src/exception.dart' show DatabaseException;

class SqfliteOptions {
  // true =<0.7.0
  bool queryAsMapList;

  Map toMap() {
    return {'queryAsMapList': queryAsMapList};
  }

  fromMap(Map map) {
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
    await invokeMethod(methodSetDebugModeOn, on);
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
    await invokeMethod(methodOptions, options.toMap());
  }

  // Testing only
  @deprecated
  static Future devInvokeMethod(String method, [dynamic arguments]) async {
    await invokeMethod(method, arguments);
  }

  /// helper to get the first int value in a query
  /// Useful for COUNT(*) queries
  static int firstIntValue(List<Map> list) {
    if (list != null && list.length > 0) {
      return parseInt(list.first?.values?.first);
    }
    return null;
  }
}

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
}

/// Database transaction
/// to use during a transaction
abstract class Transaction implements DatabaseExecutor {}

///
/// Database support
/// to send sql commands
///
abstract class Database implements DatabaseExecutor {
  /// The path of the database
  String get path;

  /// Close the database. Cannot be access anymore
  Future close();

  ///
  /// synchronized call to the database
  /// ensure that no other calls outside the inner action will
  /// access the database
  /// Use [Zone] so should be deprecated soon starting 0.9.0
  ///
  // @deprecated
  Future<T> synchronized<T>(Future<T> action());

  /// Calls in action must only be done using the transaction object
  /// using the database will trigger a dead-lock
  Future<T> transaction<T>(Future<T> action(Transaction txn), {bool exclusive});

  ///
  /// Simple soon to be deprecated soon starting 0.9.0
  /// (used Zone) transaction mechanism
  ///
  // @deprecated
  Future<T> inTransaction<T>(Future<T> action(), {bool exclusive});

  ///
  /// Get the database inner version
  ///
  Future<int> getVersion();

  ///
  /// Set the database inner version
  /// Used internally for open helpers and automatic versioning
  ///
  Future setVersion(int version);

  /// Creates a batch, used for performing multiple operation
  /// in a single atomic operation.
  Batch batch();

  /// testing only
  @deprecated
  Future devInvokeMethod(String method, [dynamic arguments]);

  /// testing only
  @deprecated
  Future devInvokeSqlMethod(String method, String sql, [List arguments]);
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
        OnDatabaseOpenFn onOpen}) =>
    impl.openDatabase(path,
        version: version,
        onConfigure: onConfigure,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
        onDowngrade: onDowngrade,
        onOpen: onOpen);

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
  // Will be deprecated for apply
  // @deprecated
  Future<List<dynamic>> commit({bool exclusive, bool noResult});

  /// Commits all of the operations in this batch as a single atomic unit
  /// The result is a list of the result of each operation in the same order
  /// if [noResult] is true, the result list is empty (i.e. the id inserted
  /// the count of item changed is not returned
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
