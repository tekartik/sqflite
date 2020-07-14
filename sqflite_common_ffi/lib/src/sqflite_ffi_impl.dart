import 'dart:io';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:sqlite3/sqlite3.dart' as ffi;
import 'package:path/path.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/src/constant.dart';
import 'package:sqflite_common_ffi/src/method_call.dart';
import 'package:sqflite_common_ffi/src/sqflite_ffi_exception.dart';
import 'package:sqflite_common_ffi/src/sqflite_import.dart';
import 'package:synchronized/extension.dart';
import 'package:synchronized/synchronized.dart';

import 'import.dart';

final _debug = false; // devWarning(true); // false
// final _useIsolate = true; // devWarning(true); // true the default!

String _prefix = '[sqflite]';

/// By id
var ffiDbs = <int, SqfliteFfiDatabase>{};

/// By path
var ffiSingleInstanceDbs = <String, SqfliteFfiDatabase>{};

var _lastFfiId = 0;

/// Ffi log level.
int logLevel = sqfliteLogLevelNone;

/// Ffi operation.
class SqfliteFfiOperation {
  /// Method.
  String method;

  /// SQL command.
  String sql;

  /// SQL arguments.
  List sqlArguments;
}

/// Ffi database
class SqfliteFfiDatabase {
  /// ffi database.
  SqfliteFfiDatabase(this.id, this._ffiDb,
      {@required this.singleInstance,
      @required this.path,
      @required this.readOnly,
      @required this.logLevel}) {
    ffiDbs[id] = this;
  }

  /// id.
  final int id;

  /// Whether it is single instance.
  final bool singleInstance;

  /// Path.
  final String path;

  /// If read-only
  final bool readOnly;
  final ffi.Database _ffiDb;

  /// Log level.
  final int logLevel;

  String get _prefix => '[sqflite-$id]';

  /// Debug map.
  Map<String, dynamic> toDebugMap() {
    var map = <String, dynamic>{
      'path': path,
      'id': id,
      'readOnly': readOnly,
      'singleInstance': singleInstance
    };
    return map;
  }

  /// Last insert id.
  int getLastInsertId() {
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

  /// Handle execute.
  Future handleExecute({String sql, List sqlArguments}) async {
    logSql(sql: sql, sqlArguments: sqlArguments);
    //database.ffiDb.execute(sql);
    if (sqlArguments?.isNotEmpty ?? false) {
      var preparedStatement = _ffiDb.prepare(sql);
      try {
        preparedStatement.execute(sqlArguments);
        return null;
      } finally {
        preparedStatement.dispose();
      }
    } else {
      _ffiDb.execute(sql);
    }
  }

  /// Log the result if needed.
  void logResult({String result}) {
    if (result != null && (logLevel >= sqfliteLogLevelSql)) {
      print('$_prefix $result');
    }
  }

  /// Log the sql statement if needed.
  void logSql({String sql, List sqlArguments, String result}) {
    if (logLevel >= sqfliteLogLevelSql) {
      print(
          '$_prefix $sql${(sqlArguments?.isNotEmpty ?? false) ? ' $sqlArguments' : ''}');
      logResult(result: result);
    }
  }

  /// Query handling.
  Future handleQuery({String sql, List sqlArguments}) async {
    var preparedStatement = _ffiDb.prepare(sql);

    try {
      logSql(sql: sql, sqlArguments: sqlArguments);
      var result = preparedStatement.select(sqlArguments);
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

/// Ffi handler.
class SqfliteFfiHandler {
  /// Lock per instance.
  final multiInstanceLocks = <String, Lock>{};

  /// Main lock.
  final mainLock = Lock();
}

/// Bas handler.
final sqfliteFfiHandler = SqfliteFfiHandler();

class _MultiInstanceLocker {
  _MultiInstanceLocker(this.path);

  final String path;

  @override
  int get hashCode => path?.hashCode ?? 0;

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
    var path = getPath() ?? getDatabase()?.path;
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
        e.details ??= <String, dynamic>{
          if (e.database != null) 'database': e.database.toDebugMap(),
          if (e.sql != null) 'sql': e.sql,
          if (e.sqlArguments != null) 'arguments': e.sqlArguments
        };
      }
      return e;
    } else if (e is ffi.SqliteException) {
      return wrapAnyException(wrapSqlException(e));
    } else {
      return wrapAnyException(
          SqfliteFfiException(code: anyErrorCode, message: e?.toString()));
    }
  }

  /// Main handling.
  Future handleImpl() async {
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
      /*
      if (e is ffi.SqliteException) {
        var database = getDatabase();
        var sql = getSql();
        var sqlArguments = getSqlArguments();
        var wrapped = wrapSqlException(e, details: <String, dynamic>{
          'database': database.toDebugMap(),
          'sql': sql,
          'arguments': sqlArguments
        });
        // devPrint(wrapped);
        throw wrapped;
      }
      var database = getDatabase();
      var sql = getSql();
      var sqlArguments = getSqlArguments();
      if (_debug) {
        print('$e in ${database?.toDebugMap()}');
      }
      String code;
      String message;
      Map<String, dynamic> details;
      if (e is SqfliteFfiException) {
        // devPrint('throwing $e');
        code = e.code;
        message = e.message;
        details = e.details;
      } else {
        code = anyErrorCode;
        message = e.toString();
      }
      if (_debug) {
        print('handleError: $e');
        print('stackTrace : $st');
      }
      throw SqfliteFfiException(
          code: code,
          message: message,
          details: <String, dynamic>{
            if (database != null) 'database': database.toDebugMap(),
            if (sql != null) 'sql': sql,
            if (sqlArguments != null) 'arguments': sqlArguments,
            if (details != null) 'details': details,
          });

       */
    }
  }

  /// Handle a method call
  Future<dynamic> rawHandle() async {
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
    return absolute(join('.dart_tool', 'sqflite_common_ffi', 'databases'));
  }

  /// Handle open database.
  Future handleOpenDatabase() async {
    //dePrint(arguments);
    var path = arguments['path'] as String;

    //devPrint('opening $path');
    var singleInstance = (arguments['singleInstance'] as bool) ?? false;
    var readOnly = (arguments['readOnly'] as bool) ?? false;
    if (singleInstance) {
      var database = ffiSingleInstanceDbs[path];
      if (database != null) {
        if (logLevel >= sqfliteLogLevelVerbose) {
          database.logResult(
              result: 'Reopening existing single database $database');
        }
        return database;
      }
    }
    ffi.Database ffiDb;
    try {
      if (path == inMemoryDatabasePath) {
        ffiDb = ffi.sqlite3.openInMemory();
      } else {
        if (readOnly) {
          // ignore: avoid_slow_async_io
          if (!(await File(path).exists())) {
            throw StateError('file $path not found');
          }
        } else {
          // ignore: avoid_slow_async_io
          if (!(await File(path).exists())) {
            // Make sure its parent exists
            try {
              await Directory(dirname(path)).create(recursive: true);
            } catch (_) {}
          }
        }
        final mode =
            readOnly ? ffi.OpenMode.readOnly : ffi.OpenMode.readWriteCreate;
        ffiDb = ffi.sqlite3.open(path, mode: mode);
      }
    } on ffi.SqliteException catch (e) {
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
    //devPrint('opened: $database');

    return <String, dynamic>{'id': id};
  }

  /// Handle close database.
  Future handleCloseDatabase() async {
    var database = getDatabaseOrThrow();
    if (database.singleInstance ?? false) {
      ffiSingleInstanceDbs.remove(database.path);
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
  SqfliteFfiDatabase getDatabase() {
    var id = getDatabaseId();
    var database = ffiDbs[id];
    return database;
  }

  /// Get the id from the arguments.
  int getDatabaseId() {
    if (arguments is Map) {
      return arguments['id'] as int;
    }
    return null;
  }

  /// Get the sql command.
  String getSql() {
    var sql = arguments['sql'] as String;
    return sql;
  }

  /// Check if path in memory.
  bool isInMemory(String path) {
    return path == inMemoryDatabasePath;
  }

  /// Return the path argument if any
  String getPath() {
    var arguments = this.arguments;
    if (arguments is Map) {
      var path = arguments['path'] as String;
      if ((path != null) && !isInMemory(path) && isRelative(path)) {
        path = join(getDatabasesPath(), path);
      }
      return path;
    }
    return null;
  }

  /// Check the arguments
  List getSqlArguments() {
    var arguments = this.arguments;
    if (arguments != null) {
      var sqlArguments = arguments['arguments'] as List;
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
      return sqlArguments;
    }
    return null;
  }

  /// Get the no result argument.
  bool getNoResult() {
    var noResult = arguments['noResult'] as bool;
    return noResult ?? false;
  }

  /// To ignore errors for batch.
  ///
  // 'continueOnError': true
  bool getContinueOnError() {
    var continueOnError = arguments['continueOnError'] as bool;
    return continueOnError ?? false;
  }

  /// Get the list of operations.
  List<SqfliteFfiOperation> getOperations() {
    var operations = <SqfliteFfiOperation>[];
    arguments['operations'].cast<Map>().forEach((operationArgument) {
      operations.add(SqfliteFfiOperation()
        ..sql = operationArgument['sql'] as String
        ..sqlArguments = operationArgument['arguments'] as List
        ..method = operationArgument['method'] as String);
    });
    return operations;
  }

  /// Handle query.
  Future handleQuery() async {
    var database = getDatabaseOrThrow();
    var sql = getSql();
    var sqlArguments = getSqlArguments();
    return database.handleQuery(sqlArguments: sqlArguments, sql: sql);
  }

  /// Wrap SQL exception.
  SqfliteFfiException wrapSqlException(ffi.SqliteException e,
      {String code, Map<String, dynamic> details}) {
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
    var sql = getSql();
    var sqlArguments = getSqlArguments();
    return database.handleExecute(sql: sql, sqlArguments: sqlArguments);
  }

  /// Handle options.
  Future handleOptions() async {
    if (arguments is Map) {
      logLevel = (arguments['logLevel'] as int) ?? sqfliteLogLevelNone;
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
  Future handleInsert() async {
    var database = getDatabaseOrThrow();
    if (database.readOnly ?? false) {
      throw SqfliteFfiException(
          code: sqliteErrorCode, message: 'Database readonly');
    }

    await handleExecute();

    var id = database.getLastInsertId();
    if (logLevel >= sqfliteLogLevelSql) {
      print('$_prefix Inserted id $id');
    }
    return id;
  }

  /// Handle udpate.
  Future handleUpdate() async {
    var database = getDatabaseOrThrow();
    if (database.readOnly ?? false) {
      throw SqfliteFfiException(
          code: sqliteErrorCode, message: 'Database readonly');
    }

    await handleExecute();

    var rowCount = database.getUpdatedRows();

    return rowCount;
  }

  /// Handle batch.
  Future handleBatch() async {
    //devPrint(arguments);
    var database = getDatabaseOrThrow();
    var operations = getOperations();
    List<Map<String, dynamic>> results;
    var noResult = getNoResult();
    var continueOnError = getContinueOnError();
    if (!noResult) {
      results = <Map<String, dynamic>>[];
    }
    for (var operation in operations) {
      Map<String, dynamic> getErrorMap(SqfliteFfiException e) {
        return <String, dynamic>{
          'error': <String, dynamic>{
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
          results.add(<String, dynamic>{'result': result});
        }
      }

      void addError(dynamic e) {
        SqfliteFfiException wrap(dynamic e) {
          return wrapAnyException(e)
            ..sql = operation.sql
            ..sqlArguments = operation.sqlArguments;
        }

        if (continueOnError) {
          if (!noResult) {
            results.add(getErrorMap(wrap(e)));
          }
        } else {
          throw wrapAnyException(e)
            ..sql = operation.sql
            ..sqlArguments = operation.sqlArguments;
        }
      }

      switch (operation.method) {
        case 'insert':
          {
            try {
              await database.handleExecute(
                  sql: operation.sql, sqlArguments: operation.sqlArguments);
              if (!noResult) {
                addResult(database.getLastInsertId());
              }
            } catch (e) {
              addError(e);
            }

            break;
          }
        case 'execute':
          {
            try {
              await database.handleExecute(
                  sql: operation.sql, sqlArguments: operation.sqlArguments);
              addResult(null);
            } catch (e) {
              addError(e);
            }

            break;
          }
        case 'query':
          {
            try {
              var result = await database.handleQuery(
                  sql: operation.sql, sqlArguments: operation.sqlArguments);
              addResult(result);
            } catch (e) {
              addError(e);
            }

            break;
          }
        case 'update':
          {
            try {
              await database.handleExecute(
                  sql: operation.sql, sqlArguments: operation.sqlArguments);
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
  Future handleDeleteDatabase() async {
    var path = getPath();

    var singleInstanceDatabase = ffiSingleInstanceDbs[path];
    if (singleInstanceDatabase != null) {
      singleInstanceDatabase.close();
      ffiSingleInstanceDbs.remove(path);
    }

    // Ignore failure
    try {
      await File(path).delete();
    } catch (_) {}
  }
}

/// Pack the result in the expected sqflite format.
Map<String, dynamic> packResult(ffi.ResultSet result) {
  var columns = result.columnNames;
  var rows = result.rows;
  // This is what sqflite expected
  return <String, dynamic>{'columns': columns, 'rows': rows};
}
