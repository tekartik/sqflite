import 'dart:async';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:sqflite_common/src/mixin/constant.dart'; // ignore: implementation_imports
import 'package:sqflite_common_ffi/src/constant.dart';
import 'package:sqflite_common_ffi/src/sqflite_ffi_exception.dart';
import 'package:sqflite_common_ffi/src/sqflite_ffi_handler.dart';
import 'package:sqlite3/common.dart' as common;
import 'package:synchronized/synchronized.dart';

import 'database_tracker.dart' if (dart.library.js) 'database_tracker_web.dart';
import 'import.dart';
import 'sqflite_ffi_impl_io.dart'
    if (dart.library.js) 'sqflite_ffi_impl_web.dart';

export 'sqflite_ffi_handler.dart'
    show SqfliteFfiHandler; // compatibility, was defined here before

final _debug = false; // devWarning(true); // false

final _globalHandlerLock = Lock();

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

class _SqfliteFfiCursorInfo {
  final int id;
  final common.CommonPreparedStatement statement;
  final int pageSize;
  final common.IteratingCursor cursor;

  /// mutable
  var atEnd = false;

  _SqfliteFfiCursorInfo(this.id, this.statement, this.pageSize, this.cursor);
}

/// Queued handler when a transaction is in progress
class _QueuedHandler {
  final Future Function() handler;
  final _completer = Completer<void>();

  _QueuedHandler(this.handler);

  Future get future => _completer.future;

  Future<void> run() async {
    try {
      var result = await handler();
      _completer.complete(result);
    } catch (e) {
      _completer.completeError(e);
    }
  }

  void cancel() {
    _completer.completeError(StateError('Database has been closed'));
  }
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

  var _lastTransactionId = 0;
  int? _currentTransactionId;

  /// Delayed operations not in the current transaction.
  final _noTransactionHandlerQueue = <_QueuedHandler>[];

  final _handlerLock = Lock();

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

  // Saved cursors
  final _cursors = <int, _SqfliteFfiCursorInfo>{};
  var _lastCursorId = 0;

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
  int? _getLastInsertId() {
    // Check the row count first, if 0 it means no insert
    // Fix issue #402
    if (_getUpdatedRows() == 0) {
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
    _cancelQueuedHandlers();
    logResult(result: 'Closing database $this');
    _ffiDb.dispose();
  }

  List<Object?> _ffiArguments(List? sqlArguments) {
    return sqlArguments?.cast<Object?>() ?? const <Object?>[];
  }

  /// Handle execute.
  ///
  /// For transaction, return the created
  Future<void> handleExecute({required String sql, List? sqlArguments}) {
    return _handlerLock.synchronized(
        () => _handleExecute(sql: sql, sqlArguments: sqlArguments));
  }

  Future<void> _handleExecute({required String sql, List? sqlArguments}) async {
    logSql(sql: sql, sqlArguments: sqlArguments);
    if (sqlArguments?.isNotEmpty ?? false) {
      // devPrint('execute $sql $sqlArguments');
      var preparedStatement = _ffiDb.prepare(sql);
      try {
        preparedStatement.execute(_ffiArguments(sqlArguments));
        return;
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

  final _queuedHandlerLock = Lock();

  /// Run queued handlers
  Future<void> _runQueuedHandlers() async {
    if (_noTransactionHandlerQueue.isNotEmpty) {
      await _queuedHandlerLock.synchronized(() async {
        while (true) {
          if (_noTransactionHandlerQueue.isNotEmpty) {
            var queuedHandler = _noTransactionHandlerQueue.first;
            if (_currentTransactionId != null) {
              break;
            }
            await queuedHandler.run();
            _noTransactionHandlerQueue.removeAt(0);
          } else {
            break;
          }
        }
      });
    }
  }

  /// Run queued handlers
  Future<void> _cancelQueuedHandlers() async {
    if (_noTransactionHandlerQueue.isNotEmpty) {
      await _queuedHandlerLock.synchronized(() async {
        for (var queuedHandler in _noTransactionHandlerQueue) {
          queuedHandler.cancel();
        }
      });
    }
  }

  /// If a transaction is in progress and we are not in it, queue for later
  Future handleTransactionId(
      int? transactionId, Future Function() handler) async {
    if (_currentTransactionId == null) {
      // ignore transactionId, could be null or -1 or something else if closed...
      return await handler();
    } else if (transactionId == _currentTransactionId ||
        transactionId == paramTransactionIdValueForce) {
      try {
        return await handler();
      } finally {
        // If we are no longer in a transaction, run queued action asynchronously
        if (_currentTransactionId == null) {
          unawaited(_runQueuedHandlers());
        }
      }
    } else {
      // Queue for later
      var queuedHandler = _QueuedHandler(handler);
      _noTransactionHandlerQueue.add(queuedHandler);
      return queuedHandler.future;
    }
  }

  void _handleReadOnly() {
    if (readOnly) {
      throw SqfliteFfiException(
          code: sqliteErrorCode, message: 'Database readonly');
    }
  }

  /// Handle insert.
  Future<int?> handleInsert({required String sql, List? sqlArguments}) {
    return _handlerLock.synchronized(
        () => _handleInsert(sql: sql, sqlArguments: sqlArguments));
  }

  Future<int?> _handleInsert({required String sql, List? sqlArguments}) async {
    _handleReadOnly();

    await _handleExecute(sql: sql, sqlArguments: sqlArguments);

    // null means no insert
    var id = _getLastInsertId();
    if (logLevel >= sqfliteLogLevelSql) {
      print('$_prefix Inserted id $id');
    }
    return id;
  }

  /// Handle update or delete
  Future<int> handleUpdate({required String sql, List? sqlArguments}) {
    return _handlerLock.synchronized(
        () => _handleUpdate(sql: sql, sqlArguments: sqlArguments));
  }

  Future<int> _handleUpdate({required String sql, List? sqlArguments}) async {
    _handleReadOnly();
    await _handleExecute(sql: sql, sqlArguments: sqlArguments);

    var rowCount = _getUpdatedRows();

    return rowCount;
  }

  /// Query handling.
  Future handleQuery({required String sql, List? sqlArguments, int? pageSize}) {
    return _handlerLock.synchronized(() {
      if (pageSize == null) {
        return _handleQuery(sqlArguments: sqlArguments, sql: sql);
      } else {
        return _handleQueryByPage(
            sqlArguments: sqlArguments, sql: sql, pageSize: pageSize);
      }
    });
  }

  /// Query handling.
  Future _handleQuery({required String sql, List? sqlArguments}) async {
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

  Map _resultFromCursor(_SqfliteFfiCursorInfo cursorInfo) {
    var cursorId = cursorInfo.id;
    try {
      var cursor = cursorInfo.cursor;
      var columns = cursor.columnNames;
      var rows = <List<Object?>>[];

      while (true) {
        if (cursor.moveNext()) {
          var row = cursor.current;
          rows.add(row.values);
        } else {
          cursorInfo.atEnd = true;
          break;
        }
        if (rows.length >= cursorInfo.pageSize) {
          break;
        }
      }
      var pack = packColumnsRowsResult(columns, rows);
      if (!cursorInfo.atEnd) {
        pack[paramCursorId] = cursorInfo.id;
      }
      return pack;
    } catch (_) {
      _closeCursor(cursorId);
      rethrow;
    } finally {
      if (cursorInfo.atEnd) {
        _closeCursor(cursorId);
      }
    }
  }

  /// Query handling.
  Future<Object?> _handleQueryByPage(
      {required String sql, List? sqlArguments, required int pageSize}) async {
    var preparedStatement = _ffiDb.prepare(sql);

    logSql(sql: sql, sqlArguments: sqlArguments);

    var cursor = preparedStatement.selectCursor(_ffiArguments(sqlArguments));

    var cursorId = ++_lastCursorId;
    var cursorInfo =
        _SqfliteFfiCursorInfo(cursorId, preparedStatement, pageSize, cursor);

    _cursors[cursorId] = cursorInfo;
    return _resultFromCursor(cursorInfo);
  }

  /// Query handling.
  Future handleQueryCursorNext({required int cursorId, bool? cancel}) {
    return _handlerLock.synchronized(() {
      return _handleQueryCursorNext(cursorId: cursorId, cancel: cancel);
    });
  }

  Future<Object?> _handleQueryCursorNext(
      {required int cursorId, bool? cancel}) async {
    if (logLevel >= sqfliteLogLevelVerbose) {
      logResult(
          result:
              'queryCursorNext $cursorId${cancel == true ? ' (cancel)' : ''}');
    }
    var cursorInfo = _cursors[cursorId];

    // Cancel?
    if (cancel == true) {
      _closeCursor(cursorId);
      return null;
    }

    if (cursorInfo == null) {
      throw StateError('Cursor $cursorId not found');
    }
    return _resultFromCursor(cursorInfo);
  }

  void _closeCursor(int cursorId) {
    // devPrint('Closing cursor $cursorId in ${_cursors.keys}');
    var info = _cursors.remove(cursorId);
    if (info != null) {
      if (logLevel >= sqfliteLogLevelVerbose) {
        logResult(result: 'Closing cursor $cursorId');
      }
      info.statement.dispose();
    }
  }

  /// Return the count of updated row.
  int _getUpdatedRows() {
    var rowCount = _ffiDb.getUpdatedRows();
    if (logLevel >= sqfliteLogLevelSql) {
      print('$_prefix Modified $rowCount rows');
    }
    return rowCount;
  }

  /// Handle batch.
  Future handleBatch(
      {required List<SqfliteFfiOperation> operations,
      required bool noResult,
      required bool continueOnError}) {
    return _handlerLock.synchronized(() => _handleBatch(
        operations: operations,
        noResult: noResult,
        continueOnError: continueOnError));
  }

  Future _handleBatch(
      {required List<SqfliteFfiOperation> operations,
      required bool noResult,
      required bool continueOnError}) async {
    List<Map<String, Object?>>? results;
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
          return _ffiWrapAnyException(e,
              database: this,
              sql: operation.sql,
              sqlArguments: operation.sqlArguments);
        }

        if (continueOnError) {
          if (!noResult) {
            results!.add(getErrorMap(wrap(e)));
          }
        } else {
          throw wrap(e);
        }
      }

      switch (operation.method) {
        case methodInsert:
          {
            try {
              await _handleExecute(
                  sql: operation.sql!, sqlArguments: operation.sqlArguments);
              if (!noResult) {
                addResult(_getLastInsertId());
              }
            } catch (e, st) {
              addError(e, st);
            }

            break;
          }
        case methodExecute:
          {
            try {
              await _handleExecute(
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
              var result = await _handleQuery(
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
              await _handleExecute(
                  sql: operation.sql!, sqlArguments: operation.sqlArguments);
              if (!noResult) {
                addResult(_getUpdatedRows());
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
}

SqfliteFfiHandler? _sqfliteFfiHandler;

/// Base handler, might be overriden by web implementation
SqfliteFfiHandler get sqfliteFfiHandler =>
    _sqfliteFfiHandler ??= sqfliteFfiHandlerIo;

set sqfliteFfiHandler(SqfliteFfiHandler handler) =>
    _sqfliteFfiHandler = handler;

/// Wrap SQL exception.
SqfliteFfiException _ffiWrapSqliteException(common.SqliteException e,
    {String? code, Map<String, Object?>? details}) {
  return SqfliteFfiException(
      // Hardcoded
      code: sqliteErrorCode,
      message: code == null ? '$e' : '$code: $e',
      details: details,
      resultCode: e.extendedResultCode);
}

SqfliteFfiException _ffiWrapAnyException(dynamic e,
    {required SqfliteFfiDatabase? database,
    required String? sql,
    required List<Object?>? sqlArguments}) {
  if (e is SqfliteFfiException) {
    e.database ??= database;
    e.sql ??= sql;
    e.sqlArguments ??= sqlArguments;
    if (e.database != null || e.sql != null || e.sqlArguments != null) {
      e.details ??= <String, Object?>{
        if (e.database != null) 'database': e.database!.toDebugMap(),
        if (e.sql != null) 'sql': e.sql,
        if (e.sqlArguments != null) 'arguments': e.sqlArguments
      };
    }
    return e;
  } else if (e is common.SqliteException) {
    return _ffiWrapAnyException(_ffiWrapSqliteException(e),
        database: database, sql: sql, sqlArguments: sqlArguments);
  } else {
    return _ffiWrapAnyException(
        SqfliteFfiException(code: anyErrorCode, message: e.toString()),
        database: database,
        sql: sql,
        sqlArguments: sqlArguments);
  }
}

/// Extension on MethodCall
extension SqfliteFfiMethodCallHandler on FfiMethodCall {
  /// Wrap the exception, keeping sql/sqlArguments in error
  SqfliteFfiException wrapAnyException(dynamic e) => _ffiWrapAnyException(e,
      database: getDatabase(), sql: getSql(), sqlArguments: getSqlArguments());

  /// Wrap the exception, keeping sql/sqlArguments in error
  SqfliteFfiException wrapAnyExceptionNoIsolate(dynamic e) =>
      wrapAnyException(e);

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

  Future _wrapSqlHandler(Future Function(SqfliteFfiDatabase database) handler) {
    var database = getDatabaseOrThrow();

    var transactionId = argumentsMap[paramTransactionId] as int?;
    return database.handleTransactionId(transactionId, () => handler(database));
  }

  Future _wrapGlobalHandler(Future Function() handler) {
    return _globalHandlerLock.synchronized(() => handler());
  }

  /// Handle a method call.
  /// Transaction id should only be handle when running in an isolate
  /// or web worker
  Future<dynamic> rawHandle() async {
    // devPrint('Handle method $method options $arguments');
    switch (method) {
      case methodOpenDatabase:
        return await _wrapGlobalHandler(handleOpenDatabase);
      case methodCloseDatabase:
        return await _wrapGlobalHandler(handleCloseDatabase);

      case methodQuery:
        return await _wrapSqlHandler(handleQuery);
      case methodQueryCursorNext:
        return await _wrapSqlHandler(handleQueryCursorNext);
      case methodExecute:
        return await _wrapSqlHandler(handleExecute);
      case methodInsert:
        return await _wrapSqlHandler(handleInsert);
      case methodUpdate:
        return await _wrapSqlHandler(handleUpdate);
      case methodBatch:
        return await _wrapSqlHandler(handleBatch);

      case methodGetDatabasesPath:
        return await _wrapGlobalHandler(handleGetDatabasesPath);
      case methodDeleteDatabase:
        return await _wrapGlobalHandler(handleDeleteDatabase);
      case methodDatabaseExists:
        return await _wrapGlobalHandler(handleDatabaseExists);
      case methodOptions:
        return await _wrapGlobalHandler(handleOptions);
      case methodWriteDatabaseBytes:
        return await _wrapGlobalHandler(handleWriteDatabaseBytes);
      case methodReadDatabaseBytes:
        return await _wrapGlobalHandler(handleReadDatabaseBytes);
      // compat
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
      return argumentsMap[paramId] as int?;
    }
    return null;
  }

  T? _getParam<T>(String key) {
    if (arguments is Map) {
      return argumentsMap[key] as T?;
    }
    return null;
  }

  /// Get the optional transaction id
  int? getTransactionId() => _getParam<int>(paramTransactionId);

  /// true if the map contains it but its value is null
  bool hasNullTransactionId() {
    if (arguments is Map) {
      return argumentsMap.containsKey(paramTransactionId) &&
          argumentsMap[paramTransactionId] == null;
    }
    return false;
  }

  /// null if no transaction change, true if begin, false if commit
  bool? getInTransactionChange() => _getParam<bool>(paramInTransaction);

  /// Get the sql command.
  String? getSql() => _getParam<String>(paramSql);

  /// Check if path in memory.
  bool isInMemory(String path) {
    return path == inMemoryDatabasePath;
  }

  /// Return the path argument if any
  String? getPath() {
    var path = _getParam<String>(paramPath);
    if ((path != null) && !isInMemory(path) && isRelative(path)) {
      path = join(getDatabasesPath(), path);
    }
    return path;
  }

  /// Get the `bytes` argument as Uint8List.
  Uint8List? getBytes() {
    var bytes = _getParam<Uint8List>(paramBytes);
    return bytes;
  }

  /// Check the arguments
  List<Object?>? getSqlArguments() {
    var sqlArguments = _getParam<List>(paramSqlArguments);
    if (sqlArguments != null) {
      // Check the argument, make it stricter
      for (var argument in sqlArguments) {
        if (argument == null) {
        } else if (argument is num) {
        } else if (argument is String) {
        } else if (argument is Uint8List) {
          // Support needed for the web and web only
        } else if (argument is BigInt) {
        } else {
          throw ArgumentError(
              'Invalid sql argument type \'${argument.runtimeType}\': $argument');
        }
      }
    }
    return sqlArguments?.cast<Object?>();
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
        ..sql = operationArgument[paramSql] as String?
        ..sqlArguments =
            (operationArgument[paramSqlArguments] as List?)?.cast<Object?>()
        ..method = operationArgument[paramMethod] as String);
    });
    return operations;
  }

  /// Handle query.
  Future handleQuery(SqfliteFfiDatabase database) async {
    var sql = getSql()!;
    var sqlArguments = getSqlArguments();
    var pageSize = argumentsMap[paramCursorPageSize] as int?;

    return database.handleQuery(
        sqlArguments: sqlArguments, sql: sql, pageSize: pageSize);
  }

  /// Handle query.
  Future handleQueryCursorNext(SqfliteFfiDatabase database) async {
    var database = getDatabaseOrThrow();
    var cursorId = argumentsMap[paramCursorId] as int;
    var cancel = argumentsMap[paramCursorCancel] as bool?;
    return database.handleQueryCursorNext(cursorId: cursorId, cancel: cancel);
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
  Future<Object?> _handleExecute(SqfliteFfiDatabase database) async {
    var database = getDatabaseOrThrow();
    var sql = getSql()!;
    var sqlArguments = getSqlArguments();

    await database.handleExecute(sql: sql, sqlArguments: sqlArguments);

    return null;
  }

  /// Handle execute.
  Future<Object?> handleExecute(SqfliteFfiDatabase database) async {
    var inTransactionChange = getInTransactionChange();
    // Transaction v2
    var enteringTransaction =
        inTransactionChange == true && hasNullTransactionId();
    if (enteringTransaction) {
      database._currentTransactionId = ++database._lastTransactionId;
    }
    try {
      await _handleExecute(database);
    } catch (e) {
      // Revert if needed
      if (enteringTransaction) {
        database._currentTransactionId = null;
      }
      rethrow;
    }

    if (enteringTransaction) {
      return <String, Object?>{
        paramTransactionId: database._currentTransactionId
      };
    } else if (inTransactionChange == false) {
      // We are leaving our current transaction
      database._currentTransactionId = null;
    }
    return null;
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

  /// Handle debug mode. compat.
  Future handleDebugMode() async {
    if (arguments == true) {
      logLevel = sqfliteLogLevelVerbose;
    }
    return null;
  }

  /// Handle insert.
  Future<int?> handleInsert(SqfliteFfiDatabase database) async {
    var sql = getSql()!;
    var sqlArguments = getSqlArguments();
    return database.handleInsert(sql: sql, sqlArguments: sqlArguments);
  }

  /// Handle update or delete
  Future<int> handleUpdate(SqfliteFfiDatabase database) async {
    var sql = getSql()!;
    var sqlArguments = getSqlArguments();
    return database.handleUpdate(sql: sql, sqlArguments: sqlArguments);
  }

  /// Handle batch.
  Future handleBatch(SqfliteFfiDatabase database) {
    var operations = getOperations();
    var noResult = getNoResult();
    var continueOnError = getContinueOnError();
    return database.handleBatch(
        operations: operations,
        noResult: noResult,
        continueOnError: continueOnError);
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

  /// Handle `readDatabaseBytes`.
  Future<Map> handleReadDatabaseBytes() async {
    var path = getPath();
    var bytes = await sqfliteFfiHandler.readDatabaseBytesPlatform(path!);
    return <String, Object?>{paramBytes: bytes};
  }

  /// Handle `writeDatabaseBytes`.
  Future<void> handleWriteDatabaseBytes() async {
    var path = getPath();
    var bytes = getBytes();
    return sqfliteFfiHandler.writeDatabaseBytesPlatform(path!, bytes!);
  }
}

/// Pack the result in the expected sqflite format.
Map<String, Object?> packResult(common.ResultSet result) {
  var columns = result.columnNames;
  var rows = result.rows;

  /// This is what sqflite expects as query response
  return packColumnsRowsResult(columns, rows);
}

/// Pack the result in the expected sqflite format.
Map<String, Object?> packColumnsRowsResult(
    List<String?> columns, List<List<Object?>> rows) {
  /// This is what sqflite expects as query response
  return <String, Object?>{'columns': columns, 'rows': rows};
}
