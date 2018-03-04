import 'dart:async';
import 'dart:io';

import 'package:sqflite/src/constant.dart';
import 'package:sqflite/src/database.dart';
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

/// Database transaction
/// to use during a transaction
abstract class Transaction extends SqfliteDatabaseExecutor {}

///
/// Database support
/// to send sql commands
///
abstract class Database extends SqfliteDatabaseExecutor {
  /// The path of the database
  String get path;

  /// Close the database. Cannot be access anymore
  Future close();

  ///
  /// synchronized call to the database
  /// ensure that no other calls outside the inner action will
  /// access the database
  /// Use [Zone] so should be deprecated soon
  ///
  Future<T> synchronized<T>(Future<T> action());

  /// Calls in action must only be done using the transaction object
  /// using the database will trigger a dead-lock
  Future<T> transaction<T>(Future<T> action(Transaction), {bool exclusive});

  ///
  /// Simple soon to be deprecated (used Zone) transaction mechanism
  ///
  Future<T> inTransaction<T>(Future<T> action(), {bool exclusive});

  /// Creates a batch, used for performing multiple operation
  /// in a single atomic operation.
  Batch batch();

  @deprecated
  Future devInvokeMethod(String method, [dynamic arguments]);

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
