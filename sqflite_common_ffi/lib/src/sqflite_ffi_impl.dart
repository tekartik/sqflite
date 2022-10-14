import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:sqflite_common/src/mixin/constant.dart'; // ignore: implementation_imports
import 'package:sqflite_common_ffi/src/constant.dart';
import 'package:sqflite_common_ffi/src/method_call.dart';
import 'package:sqflite_common_ffi/src/sqflite_ffi_exception.dart';
import 'package:sqlite3/common.dart' as common;
import 'package:synchronized/extension.dart';

import 'database_tracker.dart' if (dart.library.js) 'database_tracker_web.dart';
import 'import.dart';
import 'sqflite_ffi_impl_io.dart'
    if (dart.library.js) 'sqflite_ffi_impl_web.dart';

final _debug = false; // devWarning(true); // false
// final _useIsolate = true; // devWarning(true); // true the default!

/// Ffi handler.
abstract class SqfliteFfiHandler {
  /// Opens the database using an ffi implementation
  Future<common.CommonDatabase> openPlatform(Map argumentsMap);

  /// Delete the database file.
  Future<void> deleteDatabasePlatform(String path);

  /// Check if database file exists
  Future<bool> handleDatabaseExistsPlatform(String path);

  /// Default database path.
  String getDatabasesPathPlatform();

  /// Ffi specific options (for the web contains the sqlite3 wasm url)
  Future<void> handleOptionsPlatform(Map argumentMap);
}

String _prefix = '[sqflite]';

/// By id
var ffiDbs = <int, SqfliteFfiDatabase>{};

/// By path
var ffiSingleInstanceDbs = <String?, SqfliteFfiDatabase>{};

var _lastFfiId = 0;

/// Ffi log level.
int logLevel = sqfliteLogLevelNone;

/// Temp until exported from sqflite_common.
String _sqlArgumentsToString(String? sql, List<Object?>? arguments) {
  return '$sql${(arguments?.isNotEmpty ?? false) ? ' ${argumentsToString(arguments!)}' : ''}';
}

/// Ffi operation.
class SqfliteFfiOperation {
  /// Method.
  String? method;

  /// SQL command.
  String? sql;

  /// SQL arguments.
  List<Object?>? sqlArguments;

  @override
  String toString() => '$method ${_sqlArgumentsToString(sql, sqlArguments)}';
}

/// Ffi database
class SqfliteFfiDatabase {
  /// ffi database.
  SqfliteFfiDatabase(this.id, this._ffiDb,
      {required this.singleInstance,
      required this.path,
      required this.readOnly,
      required this.logLevel}) {
    ffiDbs[id] = this;
  }

  /// id.
  final int id;

  /// Whether it is single instance.
  final bool singleInstance;

  /// Path.
  final String? path;

  /// If read-only
  final bool readOnly;
  final common.CommonDatabase _ffiDb;

  /// Log level.
  final int logLevel;

  String get _prefix => '[sqflite-$id]';

  /// Debug map.
  Map<String, Object?> toDebugMap() {
    var map = <String, Object?>{
      'path': path,
      'id': id,
      'readOnly': readOnly,
      'singleInstance': singleInstance
    };
    return map;
  }

  /// Last insert id.
  int? getLastInsertId() {
    // Check the row count first, if 0 it means no insert
    // Fix issue #402
    if (getUpdatedRows() == 0) {
      return null;
    }
    var id = _ffiDb.lastInsertRowId;
    if (logLevel >= sqfliteLogLevelSql) {
      print('$_prefix Inserted $id');
    }
    return id;
  }

  @override
  String toString() => toDebugMap().toString();

  /// Close the database.
  void close() {
    logResult(result: 'Closing database $this');
    _ffiDb.dispose();
  }

  List<Object?> _ffiArguments(List? sqlArguments) {
    return sqlArguments?.cast<Object?>() ?? const <Object?>[];
  }

  /// Handle execute.
  Future handleExecute({required String sql, List? sqlArguments}) async {
    logSql(sql: sql, sqlArguments: sqlArguments);
    //database.ffiDb.execute(sql);
    if (sqlArguments?.isNotEmpty ?? false) {
      // devPrint('execute $sql $sqlArguments');
      var preparedStatement = _ffiDb.prepare(sql);
      try {
        preparedStatement.execute(_ffiArguments(sqlArguments));
        return null;
      } finally {
        preparedStatement.dispose();
      }
    } else {
      // devPrint('execute no args $sql');
      _ffiDb.execute(sql);
    }
  }

  /// Log the result if needed.
  void logResult({String? result}) {
    if (result != null && (logLevel >= sqfliteLogLevelSql)) {
      print('$_prefix $result');
    }
  }

  /// Log the sql statement if needed.
  void logSql({required String sql, List? sqlArguments, String? result}) {
    if (logLevel >= sqfliteLogLevelSql) {
      print(
          '$_prefix $sql${(sqlArguments?.isNotEmpty ?? false) ? ' $sqlArguments' : ''}');
      logResult(result: result);
    }
  }

  /// Query handling.
  Future handleQuery({required String sql, List? sqlArguments}) async {
    var preparedStatement = _ffiDb.prepare(sql);

    try {
      logSql(sql: sql, sqlArguments: sqlArguments);

      var result = preparedStatement.select(_ffiArguments(sqlArguments));
      logResult(result: 'Found ${result.length} rows');
      return packResult(result);
    } finally {
      preparedStatement.dispose();
    }
  }

  /// Return the count of updated row.
  int getUpdatedRows() {
    var rowCount = _ffiDb.getUpdatedRows();
    if (logLevel >= sqfliteLogLevelSql) {
      print('$_prefix Modified $rowCount rows');
    }
    return rowCount;
  }
}

SqfliteFfiHandler? _sqfliteFfiHandler;

/// Base handler, might be overriden by web implementation
SqfliteFfiHandler get sqfliteFfiHandler =>
    _sqfliteFfiHandler ??= sqfliteFfiHandlerIo;
set sqfliteFfiHandler(SqfliteFfiHandler handler) =>
    _sqfliteFfiHandler = handler;

class _MultiInstanceLocker {
  _MultiInstanceLocker(this.path);

  final String path;

  @override
  int get hashCode => path.hashCode;

  @override
  bool operator ==(other) {
    if (other is _MultiInstanceLocker) {
      return other.path == path;
    }
    return false;
  }
}

/// Extension on MethodCall
extension SqfliteFfiMethodCallHandler on FfiMethodCall {
  /// Locked per instance unless in memory.
  Future<T> synchronized<T>(Future<T> Function() action) async {
    var path = (getPath() ?? getDatabase()?.path!)!;
    if (isInMemory(path)) {
      return await action();
    }
    return await (_MultiInstanceLocker(path).synchronized(action));
  }

  /// Wrap the exception, keeping sql/sqlArguments in error
  SqfliteFfiException wrapAnyException(dynamic e) {
    if (e is SqfliteFfiException) {
      e.database ??= getDatabase();
      e.sql ??= getSql();
      e.sqlArguments ??= getSqlArguments();
      if (e.database != null || e.sql != null || e.sqlArguments != null) {
        e.details ??= <String, Object?>{
          if (e.database != null) 'database': e.database!.toDebugMap(),
          if (e.sql != null) 'sql': e.sql,
          if (e.sqlArguments != null) 'arguments': e.sqlArguments
        };
      }
      return e;
    } else if (e is common.SqliteException) {
      return wrapAnyException(wrapSqlException(e));
    } else {
      return wrapAnyException(
          SqfliteFfiException(code: anyErrorCode, message: e.toString()));
    }
  }

  /// Wrap the exception, keeping sql/sqlArguments in error
  SqfliteFfiException wrapAnyExceptionNoIsolate(dynamic e) {
    if (e is SqfliteFfiException) {
      e.database ??= getDatabase();
      e.sql ??= getSql();
      e.sqlArguments ??= getSqlArguments();

      return e;
    } else if (e is common.SqliteException) {
      return wrapAnyException(wrapSqlException(e));
    } else {
      return wrapAnyExceptionNoIsolate(
          SqfliteFfiException(code: anyErrorCode, message: e.toString()));
    }
  }

  /// Main handling.
  Future<dynamic> handleImpl() async {
    // devPrint('$this');
    try {
      if (_debug) {
        print('handle $this');
      }
      dynamic result = await rawHandle();

      if (_debug) {
        print('result: $result');
      }

      // devPrint('result: $result');
      return result;
    } catch (e, st) {
      // devPrint('st $st');
      if (_debug) {
        print('error: $e');
        print('st $st');
      }

      var ffiException = wrapAnyException(e);
      throw ffiException;
    }
  }

  /// Handle a method call
  Future<dynamic> rawHandle() async {
    // devPrint('Handle method $method options $arguments');
    switch (method) {
      case 'openDatabase':
        return await handleOpenDatabase();
      case 'closeDatabase':
        return await handleCloseDatabase();

      case 'query':
        return await handleQuery();
      case 'execute':
        return await handleExecute();
      case 'insert':
        return await handleInsert();
      case 'update':
        return await handleUpdate();
      case 'batch':
        return await handleBatch();

      case 'getDatabasesPath':
        return await handleGetDatabasesPath();
      case 'deleteDatabase':
        return await handleDeleteDatabase();
      case 'databaseExists':
        return await handleDatabaseExists();
      case 'options':
        return await handleOptions();
      case 'debugMode':
        return await handleDebugMode();
      default:
        throw ArgumentError('Invalid method $method $this');
    }
  }

  /// Default database path.
  String getDatabasesPath() {
    return sqfliteFfiHandler.getDatabasesPathPlatform();
  }

  /// Read arguments as a map;
  Map get argumentsMap => arguments as Map;

  /// Handle open database.
  Future<Map> handleOpenDatabase() async {
    // devPrint('handleOpenDatabase $argumentsMap');
    var path = argumentsMap['path'] as String;

    Map wrapDbId(int id) {
      return <String, Object?>{'id': id};
    }

    var singleInstance = (argumentsMap['singleInstance'] as bool?) ?? false;
    var readOnly = (argumentsMap['readOnly'] as bool?) ?? false;
    if (singleInstance) {
      var database = ffiSingleInstanceDbs[path];
      if (database != null) {
        if (logLevel >= sqfliteLogLevelVerbose) {
          database.logResult(
              result: 'Reopening existing single database $database');
        }
        return wrapDbId(database.id);
      }
    }

    common.CommonDatabase ffiDb;
    try {
      ffiDb = await sqfliteFfiHandler.openPlatform(argumentsMap);
    } on common.SqliteException catch (e) {
      throw wrapSqlException(e, code: 'open_failed');
    }

    var id = ++_lastFfiId;
    var database = SqfliteFfiDatabase(id, ffiDb,
        singleInstance: singleInstance,
        path: path,
        readOnly: readOnly,
        logLevel: logLevel);
    database.logResult(result: 'Opening database $database');
    if (singleInstance) {
      ffiSingleInstanceDbs[path] = database;
    }
    return wrapDbId(id);
  }

  /// Handle close database.
  Future handleCloseDatabase() async {
    var database = getDatabaseOrThrow();
    if (database.singleInstance) {
      ffiSingleInstanceDbs.remove(database.path);

      // Handle hot-restart for single instance
      // The dart code is killed but the native code remains
      // Remove the database from our cache
      tracker.markClosed(database._ffiDb);
    }
    database.close();
  }

  /// Find the database or throw.arguments
  ///
  /// Never null.
  SqfliteFfiDatabase getDatabaseOrThrow() {
    var database = getDatabase();
    if (database == null) {
      throw StateError('Database ${getDatabaseId()} not found');
    }
    return database;
  }

  /// Find the database.
  SqfliteFfiDatabase? getDatabase() {
    var id = getDatabaseId();
    if (id != null) {
      var database = ffiDbs[id];
      return database;
    }
    return null;
  }

  /// Get the id from the arguments.
  int? getDatabaseId() {
    if (arguments is Map) {
      return argumentsMap['id'] as int?;
    }
    return null;
  }

  /// Get the sql command.
  String? getSql() {
    var sql = argumentsMap['sql'] as String?;
    return sql;
  }

  /// Check if path in memory.
  bool isInMemory(String path) {
    return path == inMemoryDatabasePath;
  }

  /// Return the path argument if any
  String? getPath() {
    var arguments = this.arguments;
    if (arguments is Map) {
      var path = argumentsMap['path'] as String?;
      if ((path != null) && !isInMemory(path) && isRelative(path)) {
        path = join(getDatabasesPath(), path);
      }
      return path;
    }
    return null;
  }

  /// Check the arguments
  List<Object?>? getSqlArguments() {
    var arguments = this.arguments;
    if (arguments != null) {
      var sqlArguments = argumentsMap['arguments'] as List?;
      if (sqlArguments != null) {
        // Check the argument, make it stricter
        for (var argument in sqlArguments) {
          if (argument == null) {
          } else if (argument is num) {
          } else if (argument is String) {
          } else if (argument is Uint8List) {
          } else {
            throw ArgumentError(
                'Invalid sql argument type \'${argument.runtimeType}\': $argument');
          }
        }
      }
      return sqlArguments?.cast<Object?>();
    }
    return null;
  }

  /// Get the no result argument.
  bool getNoResult() {
    var noResult = argumentsMap['noResult'] as bool?;
    return noResult ?? false;
  }

  /// To ignore errors for batch.
  ///
  // 'continueOnError': true
  bool getContinueOnError() {
    var continueOnError = argumentsMap['continueOnError'] as bool?;
    return continueOnError ?? false;
  }

  /// Get the list of operations.
  List<SqfliteFfiOperation> getOperations() {
    var operations = <SqfliteFfiOperation>[];
    (argumentsMap['operations'] as List)
        .cast<Map>()
        .forEach((operationArgument) {
      operations.add(SqfliteFfiOperation()
        ..sql = operationArgument['sql'] as String?
        ..sqlArguments =
            (operationArgument['arguments'] as List?)?.cast<Object?>()
        ..method = operationArgument['method'] as String);
    });
    return operations;
  }

  /// Handle query.
  Future handleQuery() async {
    var database = getDatabaseOrThrow();
    var sql = getSql()!;
    var sqlArguments = getSqlArguments();
    return database.handleQuery(sqlArguments: sqlArguments, sql: sql);
  }

  /// Wrap SQL exception.
  SqfliteFfiException wrapSqlException(common.SqliteException e,
      {String? code, Map<String, Object?>? details}) {
    return SqfliteFfiException(
        // Hardcoded
        code: sqliteErrorCode,
        message: code == null ? '$e' : '$code: $e',
        details: details,
        resultCode: e.extendedResultCode);
  }

  /// Handle execute.
  Future handleExecute() async {
    var database = getDatabaseOrThrow();
    var sql = getSql()!;
    var sqlArguments = getSqlArguments();

    return database.handleExecute(sql: sql, sqlArguments: sqlArguments);
  }

  /// Handle options.
  Future handleOptions() async {
    if (arguments is Map) {
      if (argumentsMap.containsKey('logLevel')) {
        logLevel = (argumentsMap['logLevel'] as int?) ?? sqfliteLogLevelNone;
      }
      await sqfliteFfiHandler.handleOptionsPlatform(argumentsMap);
    }
    return null;
  }

  /// Handle debug mode.
  Future handleDebugMode() async {
    if (arguments == true) {
      logLevel = sqfliteLogLevelVerbose;
    }
    return null;
  }

  /// Handle insert.
  Future<int?> handleInsert() async {
    var database = getDatabaseOrThrow();
    if (database.readOnly) {
      throw SqfliteFfiException(
          code: sqliteErrorCode, message: 'Database readonly');
    }

    await handleExecute();

    // null means no insert
    var id = database.getLastInsertId();
    if (logLevel >= sqfliteLogLevelSql) {
      print('$_prefix Inserted id $id');
    }
    return id;
  }

  /// Handle udpate.
  Future<int> handleUpdate() async {
    var database = getDatabaseOrThrow();
    if (database.readOnly) {
      throw SqfliteFfiException(
          code: sqliteErrorCode, message: 'Database readonly');
    }

    await handleExecute();

    var rowCount = database.getUpdatedRows();

    return rowCount;
  }

  /// Handle batch.
  Future handleBatch() async {
    var database = getDatabaseOrThrow();
    var operations = getOperations();
    List<Map<String, Object?>>? results;
    var noResult = getNoResult();
    var continueOnError = getContinueOnError();
    if (!noResult) {
      results = <Map<String, Object?>>[];
    }
    for (var operation in operations) {
      // devPrint('operation $operation');
      Map<String, Object?> getErrorMap(SqfliteFfiException e) {
        return <String, Object?>{
          'error': <String, Object?>{
            'message': '$e',
            if (e.sql != null || e.sqlArguments != null)
              'data': {
                'sql': e.sql,
                if (e.sqlArguments != null) 'arguments': e.sqlArguments
              }
          }
        };
      }

      void addResult(dynamic result) {
        if (!noResult) {
          results!.add(<String, Object?>{'result': result});
        }
      }

      void addError(dynamic e, [dynamic st]) {
        if (_debug && st != null) {
          print('stack: $st');
        }
        SqfliteFfiException wrap(dynamic e) {
          return wrapAnyException(e)
            ..sql = operation.sql
            ..sqlArguments = operation.sqlArguments;
        }

        if (continueOnError) {
          if (!noResult) {
            results!.add(getErrorMap(wrap(e)));
          }
        } else {
          throw wrapAnyException(e)
            ..sql = operation.sql
            ..sqlArguments = operation.sqlArguments;
        }
      }

      switch (operation.method) {
        case methodInsert:
          {
            try {
              await database.handleExecute(
                  sql: operation.sql!, sqlArguments: operation.sqlArguments);
              if (!noResult) {
                addResult(database.getLastInsertId());
              }
            } catch (e, st) {
              addError(e, st);
            }

            break;
          }
        case methodExecute:
          {
            try {
              await database.handleExecute(
                  sql: operation.sql!, sqlArguments: operation.sqlArguments);
              addResult(null);
            } catch (e) {
              addError(e);
            }

            break;
          }
        case methodQuery:
          {
            try {
              var result = await database.handleQuery(
                  sql: operation.sql!, sqlArguments: operation.sqlArguments);
              addResult(result);
            } catch (e) {
              addError(e);
            }

            break;
          }
        case methodUpdate:
          {
            try {
              await database.handleExecute(
                  sql: operation.sql!, sqlArguments: operation.sqlArguments);
              if (!noResult) {
                addResult(database.getUpdatedRows());
              }
            } catch (e) {
              addError(e);
            }
            break;
          }
        default:
          throw 'batch operation ${operation.method} not supported';
      }
    }
    return results;
  }

  /// Get the databases path.
  Future handleGetDatabasesPath() async {
    return getDatabasesPath();
  }

  /// Handle delete database.
  Future<void> handleDeleteDatabase() async {
    var path = getPath();

    var singleInstanceDatabase = ffiSingleInstanceDbs[path];
    if (singleInstanceDatabase != null) {
      singleInstanceDatabase.close();
      ffiSingleInstanceDbs.remove(path);
    }

    // Ignore failure
    try {
      await sqfliteFfiHandler.deleteDatabasePlatform(path!);
    } catch (_) {}
  }

  /// Handle `databaseExists`.
  Future<bool> handleDatabaseExists() async {
    var path = getPath();
    return sqfliteFfiHandler.handleDatabaseExistsPlatform(path!);
  }
}

/// Pack the result in the expected sqflite format.
Map<String, Object?> packResult(common.ResultSet result) {
  var columns = result.columnNames;
  var rows = result.rows;

  /// This is what sqflite expects as query response
  return <String, Object?>{'columns': columns, 'rows': rows};
}
