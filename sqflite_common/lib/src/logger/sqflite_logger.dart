import 'dart:async';

import 'package:meta/meta.dart';
import 'package:sqflite_common/sqflite_logger.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/batch.dart';
import 'package:sqflite_common/src/database.dart';
import 'package:sqflite_common/src/database_mixin.dart';
import 'package:sqflite_common/src/env_utils.dart';
import 'package:sqflite_common/src/factory.dart';
import 'package:sqflite_common/src/factory_mixin.dart';
import 'package:sqflite_common/src/sql_command.dart';
import 'package:sqflite_common/src/transaction.dart';

/// Log helper to avoid overflow
String logTruncateAny(Object? value) {
  return logTruncate(value?.toString() ?? '<null>');
}

/// Log helper to avoid overflow
String logTruncate(String text, {int len = 256}) {
  if (text.length > len) {
    text = text.substring(0, len);
  }
  return text;
}

/// Type of logging. For now, only all logs (no filtering) are supported.
enum SqfliteDatabaseFactoryLoggerType {
  /// All logs are returned. default. For the 3rd party debugging.
  all,

  /// Internal implementation invocation. For internal debugging.
  ///
  /// all events are SqfliteLoggerInvokeEvent
  invoke,
}

/// Logger event function.
typedef SqfliteLoggerEventFunction = void Function(SqfliteLoggerEvent event);

/// Every operation/event is a command
abstract class SqfliteLoggerCommand {
  /// Set on failure
  Object? get error;
}

/// Logger event.
abstract class SqfliteLoggerEvent implements SqfliteLoggerCommand {
  /// Stopwatch. for performance testing.
  Stopwatch? get sw;
}

/// View helper
@visibleForTesting
abstract class SqfliteLoggerEventView implements SqfliteLoggerEvent {
  /// Map view.
  Map<String, Object?> toMap();
}

class _SqfliteLoggerEvent
    implements SqfliteLoggerEvent, SqfliteLoggerEventView {
  @override
  late final Object? error;

  @override
  late final Stopwatch? sw;

  _SqfliteLoggerEvent(this.sw, this.error);

  /// Allow late init.
  _SqfliteLoggerEvent._();

  @override
  Map<String, Object?> toMap() => {
        if (sw != null) 'sw': '${sw!.elapsed}',
        if (error != null) 'error': error
      };

  @override
  String toString() => logTruncate(toMap().toString());
}

/// Generic method event.
abstract class SqfliteLoggerInvokeEvent extends SqfliteLoggerEvent {
  /// Invoke method.
  String get method;

  /// Invoke arguments.
  Object? get arguments;

  /// The result (result can be null if error is null but cannot be non null if error is null).
  Object? get result;
}

/// Open db event
abstract class SqfliteLoggerDatabaseOpenEvent extends SqfliteLoggerEvent {
  /// The options used.
  OpenDatabaseOptions? get options;

  /// Invoke arguments.
  String? get path;

  /// The resulting database on success
  Database? get db;
}

/// Open db event
abstract class SqfliteLoggerDatabaseCloseEvent extends SqfliteLoggerEvent {
  /// The closed database.
  Database? get db;
}

/// In database event.
abstract class SqfliteLoggerDatabaseEvent implements SqfliteLoggerEvent {
  /// The database client (transaction or database)
  DatabaseExecutor get client;
}

/// Open db event
abstract class SqfliteLoggerSqlEvent<T> extends SqfliteLoggerDatabaseEvent
    implements SqfliteLoggerSqlCommand<T> {}

/// Typed sql command
abstract class SqfliteLoggerSqlCommand<T> implements SqfliteLoggerCommand {
  /// The command type.
  SqliteSqlCommandType get type;

  /// Invoke arguments.
  String get sql;

  /// Sql arguments.
  Object? get arguments;

  /// Optional result.
  T? get result;
}

/// batch event
abstract class SqfliteLoggerBatchEvent extends SqfliteLoggerDatabaseEvent {
  /// batch operations.
  List<SqfliteLoggerBatchOperation> get operations;
}

/// Sql batch operation.
abstract class SqfliteLoggerBatchOperation<T>
    implements SqfliteLoggerSqlCommand<T> {}

mixin _SqfliteLoggerSqlCommandMixin<T> implements SqfliteLoggerSqlCommand<T> {
  @override
  late final SqliteSqlCommandType type;

  /// Invoke arguments.
  @override
  late final String sql;

  /// Sql arguments.
  @override
  late final Object? arguments;

  /// Optional result.
  @override
  late final T? result;

  String get _typeAsText => type.toString().split('.').last;
}

class _SqfliteLoggerDatabaseEvent extends _SqfliteLoggerEvent
    implements SqfliteLoggerDatabaseEvent {
  late final DatabaseExecutor _client;

  @override
  DatabaseExecutor get client => _client;

  set client(DatabaseExecutor client) {
    _client = client;
    // save txn id right away to handle when not set yet.
    txnId = (client as SqfliteDatabaseExecutorMixin).txn?.transactionId;
  }

  Map<String, Object?> get _databasePrefixMap => {
        if (client.database is SqfliteDatabase)
          'db': (client.database as SqfliteDatabase).id,
        if (txnId != null) 'txn': txnId
      };

  late int? txnId;

  @override
  Map<String, Object?> toMap() => {..._databasePrefixMap, ...super.toMap()};

  _SqfliteLoggerDatabaseEvent(super.sw, DatabaseExecutor client, super.error) {
    this.client = client;
  }

  /// Allow late init.
  _SqfliteLoggerDatabaseEvent._() : super._();
}

/// Event or batch operation execute command return a count.
abstract class SqfliteLoggerSqlCommandExecute
    extends SqfliteLoggerSqlCommand<void> {}

/// Event or batch operation insert command return a record id.
abstract class SqfliteLoggerSqlCommandInsert
    extends SqfliteLoggerSqlCommand<int> {}

/// Event or batch operation update command return a count.
abstract class SqfliteLoggerSqlCommandUpdate
    extends SqfliteLoggerSqlCommand<int> {}

/// Event or batch operation delete command return a count.
abstract class SqfliteLoggerSqlCommandDelete
    extends SqfliteLoggerSqlCommand<int> {}

/// Event or batch operation query command.
abstract class SqfliteLoggerSqlCommandQuery
    extends SqfliteLoggerSqlCommand<List<Map<String, Object?>>> {}

class _SqfliteLoggerSqlEventInsert extends _SqfliteLoggerSqlEvent<int>
    implements SqfliteLoggerSqlCommandInsert {}

class _SqfliteLoggerSqlEventExecute extends _SqfliteLoggerSqlEvent<void>
    implements SqfliteLoggerSqlCommandExecute {}

class _SqfliteLoggerSqlEventUpdate extends _SqfliteLoggerSqlEvent<int>
    implements SqfliteLoggerSqlCommandUpdate {}

class _SqfliteLoggerSqlEventDelete extends _SqfliteLoggerSqlEvent<int>
    implements SqfliteLoggerSqlCommandDelete {}

class _SqfliteLoggerSqlEventQuery
    extends _SqfliteLoggerSqlEvent<List<Map<String, Object?>>>
    implements SqfliteLoggerSqlCommandQuery {}

class _SqfliteLoggerSqlEvent<T> extends _SqfliteLoggerDatabaseEvent
    with _SqfliteLoggerSqlCommandMixin<T>
    implements SqfliteLoggerSqlEvent<T> {
  _SqfliteLoggerSqlEvent() : super._();

  static _SqfliteLoggerSqlEvent fromDynamic(
      Stopwatch sw,
      DatabaseExecutor client,
      SqliteSqlCommandType type,
      String sql,
      List<Object?>? arguments,
      Object? result,
      Object? error) {
    _SqfliteLoggerSqlEvent event;
    switch (type) {
      case SqliteSqlCommandType.execute:
        event = _SqfliteLoggerSqlEventExecute();
        break;
      case SqliteSqlCommandType.insert:
        event = _SqfliteLoggerSqlEventInsert();
        break;
      case SqliteSqlCommandType.update:
        event = _SqfliteLoggerSqlEventUpdate();
        break;
      case SqliteSqlCommandType.delete:
        event = _SqfliteLoggerSqlEventDelete();
        break;
      case SqliteSqlCommandType.query:
        event = _SqfliteLoggerSqlEventQuery();
        break;
    }

    event.type = type;
    event.sql = sql;
    event.arguments = arguments;
    event.result = result;
    event.error = error;
    event.sw = sw;
    event.client = client;
    return event;
  }

  @override
  Map<String, Object?> toMap() => {
        ..._databasePrefixMap,
        'sql': sql,
        if (arguments != null) 'arguments': arguments,
        if (result != null) 'result': result,
        ...super.toMap()
      };

  @override
  String toString() => '$_typeAsText(${super.toString()})';
}

/// Open db event
class _SqfliteLoggerBatchEvent extends _SqfliteLoggerDatabaseEvent
    implements SqfliteLoggerBatchEvent {
  @override
  final List<SqfliteLoggerBatchOperation> operations;

  _SqfliteLoggerBatchEvent(
      super.sw, super.client, this.operations, super.error);

  @override
  Map<String, Object?> toMap() => {
        ..._databasePrefixMap,
        'operations': operations
            .map((e) => (e as _SqfliteLoggerBatchOperation).toMap())
            .toList(),
        ...super.toMap()
      };
}

class _SqfliteLoggerBatchInsertOperation
    extends _SqfliteLoggerBatchOperation<int>
    implements SqfliteLoggerSqlCommandInsert {}

class _SqfliteLoggerBatchUpdateOperation
    extends _SqfliteLoggerBatchOperation<int>
    implements SqfliteLoggerSqlCommandUpdate {}

class _SqfliteLoggerBatchDeleteOperation
    extends _SqfliteLoggerBatchOperation<int>
    implements SqfliteLoggerSqlCommandDelete {}

class _SqfliteLoggerBatchExecuteOperation
    extends _SqfliteLoggerBatchOperation<void>
    implements SqfliteLoggerSqlCommandExecute {}

class _SqfliteLoggerBatchQueryOperation
    extends _SqfliteLoggerBatchOperation<List<Map<String, Object?>>>
    implements SqfliteLoggerSqlCommandQuery {}

/// Batch sql operation
abstract class _SqfliteLoggerBatchOperation<T>
    with _SqfliteLoggerSqlCommandMixin<T>
    implements SqfliteLoggerBatchOperation<T> {
  @override
  late final Object? error;

  /*
  _SqfliteLoggerBatchOperation(
      String sql, List<Object>? arguments, T? result, Object? error) {
    this.sql = sql;
    this.arguments = arguments;
    this.result = result;
    this.error = error;
  }
  */
  static _SqfliteLoggerBatchOperation fromDynamic(SqliteSqlCommandType type,
      String sql, List<Object?>? arguments, Object? result, Object? error) {
    _SqfliteLoggerBatchOperation operation;
    switch (type) {
      case SqliteSqlCommandType.execute:
        operation = _SqfliteLoggerBatchExecuteOperation();
        break;
      case SqliteSqlCommandType.insert:
        operation = _SqfliteLoggerBatchInsertOperation();
        break;

      case SqliteSqlCommandType.update:
        operation = _SqfliteLoggerBatchUpdateOperation();
        break;
      case SqliteSqlCommandType.delete:
        operation = _SqfliteLoggerBatchDeleteOperation();
        break;
      case SqliteSqlCommandType.query:
        operation = _SqfliteLoggerBatchQueryOperation();
        break;
    }
    operation.type = type;
    operation.sql = sql;
    operation.arguments = arguments;
    operation.result = result;
    operation.error = error;
    return operation;
  }

  Map<String, Object?> toMap() {
    var map = <String, Object?>{
      'sql': sql,
      if (arguments != null) 'arguments': arguments,
      if (result != null) 'result': result,
      if (error != null) 'error': error
    };
    return map;
  }

  @override
  String toString() => '$_typeAsText(${logTruncate(toMap().toString())})';
}

class _SqfliteLoggerDatabaseOpenEvent extends _SqfliteLoggerEvent
    implements SqfliteLoggerDatabaseOpenEvent {
  @override
  final SqfliteDatabase? db;

  @override
  final OpenDatabaseOptions? options;

  @override
  final String path;

  @override
  Map<String, Object?> toMap() => {
        'path': path,
        if (options != null) 'options': options!.toMap(),
        if (db?.id != null) 'id': db!.id,
        ...super.toMap()
      };

  _SqfliteLoggerDatabaseOpenEvent(
      super.sw, this.path, this.options, this.db, super.error);

  @override
  String toString() => 'openDatabase(${super.toString()})';
}

class _SqfliteLoggerDatabaseCloseEvent extends _SqfliteLoggerDatabaseEvent
    implements SqfliteLoggerDatabaseCloseEvent {
  @override
  Map<String, Object?> toMap() => {..._databasePrefixMap, ...super.toMap()};

  _SqfliteLoggerDatabaseCloseEvent(super.sw, super.db, super.error);

  @override
  String toString() => 'closeDatabase(${super.toString()})';

  @override
  Database get db => client.database;
}

class _SqfliteLoggerInvokeEvent extends _SqfliteLoggerEvent
    implements SqfliteLoggerInvokeEvent {
  @override
  final Object? result;

  @override
  final Object? arguments;

  @override
  final String method;

  @override
  Map<String, Object?> toMap() => {
        'method': method,
        if (arguments != null) 'arguments': arguments,
        if (result != null) 'result': result,
        ...super.toMap()
      };

  _SqfliteLoggerInvokeEvent(
      super.sw, this.method, this.arguments, this.result, super.error);
}

class _EventInfo<T> {
  Object? error;
  StackTrace? stackTrace;
  T? result;
  final sw = Stopwatch()..start();

  T throwOrResult() {
    if (error != null) {
      if (isDebug && (stackTrace != null)) {
        print(stackTrace);
      }
      throw error!;
    }
    return result as T;
  }
}

/// Default logger. print!
void _logDefault(SqfliteLoggerEvent event) {
  print(event);
}

/// Default type, all!
var _typeDefault = SqfliteDatabaseFactoryLoggerType.all;

/// Sqflite logger option.
///
/// [type] default to [SqfliteDatabaseFactoryLoggerType.all]
/// [log] default to print.
class SqfliteLoggerOptions {
  /// True if write should be logged
  late final void Function(SqfliteLoggerEvent event) log;

  /// The logger type (filtering)
  late final SqfliteDatabaseFactoryLoggerType type;

  /// Sqflite logger option.
  SqfliteLoggerOptions(
      {SqfliteLoggerEventFunction? log,
      SqfliteDatabaseFactoryLoggerType? type}) {
    this.log = log ?? _logDefault;
    this.type = type ?? _typeDefault;
  }
}

/// Special wrapper that allows easily wrapping each API calls.
abstract class SqfliteDatabaseFactoryLogger implements SqfliteDatabaseFactory {
  /// Wrap each call in a logger.
  factory SqfliteDatabaseFactoryLogger(DatabaseFactory factory,
      {SqfliteLoggerOptions? options}) {
    var delegate = factory;
    if (factory is SqfliteDatabaseFactoryLogger) {
      delegate = (factory as _SqfliteDatabaseFactoryLogger)._delegate;
    }
    return _SqfliteDatabaseFactoryLogger(
        delegate as SqfliteDatabaseFactory, options ?? SqfliteLoggerOptions());
  }
}

mixin _SqfliteDatabaseExecutorLoggerMixin implements SqfliteDatabaseExecutor {
  SqfliteDatabaseExecutor _executor(SqfliteTransaction? txn) =>
      txn ?? this.txn ?? this;
}

class _SqfliteDatabaseLogger extends SqfliteDatabaseBase
    with _SqfliteDatabaseExecutorLoggerMixin
    implements SqfliteDatabase {
  late final _SqfliteDatabaseFactoryLogger _factory;

  SqfliteLoggerOptions get _options => _factory._options;

  @override
  _SqfliteDatabaseFactoryLogger get factory => _factory;

  _SqfliteDatabaseLogger(SqfliteDatabaseOpenHelper openHelper, String path,
      {OpenDatabaseOptions? options})
      : super(openHelper, path, options: options) {
    _factory = openHelper.factory as _SqfliteDatabaseFactoryLogger;
  }

  void _log(SqfliteLoggerEvent event) => _options.log(event);

  bool get _needLogAll => _options.type == SqfliteDatabaseFactoryLoggerType.all;

  @override
  Future<int> openDatabase() async {
    Future<int> doOpenDatabase() async {
      return (await super.openDatabase());
    }

    if (!_needLogAll) {
      return await doOpenDatabase();
    } else {
      var info = await _wrap<int>(doOpenDatabase);
      _options.log(_SqfliteLoggerDatabaseOpenEvent(
          info.sw, path, options, this, info.error));
      return info.throwOrResult();
    }
  }

  @override
  Future<void> close() async {
    Future<void> doClose() {
      return super.close();
    }

    if (_needLogAll) {
      var info = await _wrap<void>(doClose);
      _log(_SqfliteLoggerDatabaseCloseEvent(info.sw, this, info.error));
      info.throwOrResult();
    } else {
      await doClose();
    }
  }

  /*
  /// New transaction.
  @override
  SqfliteTransaction newTransaction() {
    final txn = _SqfliteTransactionLogger(this, super.newTransaction());
    return txn;
  }*/

  /// Commit a batch.
  @override
  Future<List<Object?>> txnApplyBatch(
      SqfliteTransaction? txn, SqfliteBatch batch,
      {bool? noResult, bool? continueOnError}) async {
    Future<List<Object?>> doApplyBatch() {
      return super.txnApplyBatch(txn, batch,
          noResult: noResult, continueOnError: continueOnError);
    }

    if (_needLogAll) {
      var info = await _wrap(doApplyBatch);

      var logOperations = <_SqfliteLoggerBatchOperation>[];
      if (info.error == null) {
        var operations = batch.operations;

        for (var i = 0; i < operations.length; i++) {
          var operation = operations[i];
          Object? result;
          Object? error;
          if (noResult != true) {
            var resultOrError = info.result![i];
            if (resultOrError is DatabaseException) {
              error = resultOrError;
            } else {
              result = resultOrError;
            }
          }
          logOperations.add(_SqfliteLoggerBatchOperation.fromDynamic(
              operation.type,
              operation.sql,
              operation.arguments,
              result,
              error));
        }
      }
      _options.log(_SqfliteLoggerBatchEvent(
          info.sw, _executor(txn), logOperations, info.error));
      return info.throwOrResult();
    } else {
      return await doApplyBatch();
    }
  }

  /// Execute a raw SQL SELECT query
  ///
  /// Returns a list of rows that were found
  @override
  Future<List<Map<String, Object?>>> txnRawQuery(
      SqfliteTransaction? txn, String sql, List<Object?>? arguments) {
    return _txnWrapSql(txn, SqliteSqlCommandType.query, sql, arguments,
        () async {
      return super.txnRawQuery(txn, sql, arguments);
    });
  }

  @override
  Future<int> txnRawDelete(
      SqfliteTransaction? txn, String sql, List<Object?>? arguments) {
    return _txnWrapSql(txn, SqliteSqlCommandType.delete, sql, arguments,
        () async {
      return super.txnRawDelete(txn, sql, arguments);
    });
  }

  @override
  Future<int> txnRawUpdate(
      SqfliteTransaction? txn, String sql, List<Object?>? arguments) {
    return _txnWrapSql(txn, SqliteSqlCommandType.update, sql, arguments,
        () async {
      return super.txnRawUpdate(txn, sql, arguments);
    });
  }

  /// for INSERT sql query
  /// returns the last inserted record id
  ///
  /// 0 returned instead of null
  @override
  Future<int> txnRawInsert(
      SqfliteTransaction? txn, String sql, List<Object?>? arguments) {
    return _txnWrapSql(txn, SqliteSqlCommandType.insert, sql, arguments,
        () async {
      return super.txnRawInsert(txn, sql, arguments);
    });
  }

  /// Execute a command.
  @override
  Future<T> txnExecute<T>(
      SqfliteTransaction? txn, String sql, List<Object?>? arguments,
      {bool? beginTransaction}) {
    return _txnWrapSql(
        txn,
        SqliteSqlCommandType.execute,
        sql,
        arguments,
        () => super.txnExecute(txn, sql, arguments,
            beginTransaction: beginTransaction));
  }

  Future<T> _txnWrapSql<T>(SqfliteTransaction? txn, SqliteSqlCommandType type,
      String sql, List<Object?>? arguments, Future<T> Function() action) async {
    if (!_needLogAll) {
      return await action();
    } else {
      var info = await _wrap<T>(action);
      _options.log(_SqfliteLoggerSqlEvent.fromDynamic(info.sw, _executor(txn),
          type, sql, arguments, info.result, info.error));
      return info.throwOrResult();
    }
  }

  Future<_EventInfo<T>> _wrap<T>(FutureOr<T> Function() action) =>
      _factory._wrap(action);
}

class _SqfliteDatabaseFactoryLogger
    with SqfliteDatabaseFactoryMixin
    implements SqfliteDatabaseFactoryLogger {
  final SqfliteDatabaseFactory _delegate;
  final SqfliteLoggerOptions _options;

  _SqfliteDatabaseFactoryLogger(this._delegate, this._options);

  /// The only method to override to create a custom object.
  @override
  SqfliteDatabaseMixin newDatabase(
      SqfliteDatabaseOpenHelper openHelper, String path) {
    return _SqfliteDatabaseLogger(openHelper, path);
  }

  Future<_EventInfo<T>> _wrap<T>(FutureOr<T> Function() action) async {
    var info = _EventInfo<T>();
    try {
      var result = await action();
      info.result = result;
    } catch (error, stackTrace) {
      info.error = error;
      if (isDebug) {
        info.stackTrace = stackTrace;
      }
    } finally {
      info.sw.stop();
    }
    return info;
  }

  /// The only method to override to use the delegate
  @override
  Future<T> invokeMethod<T>(String method, [Object? arguments]) async {
    Future<T> doInvokeMethod() {
      return _delegate.invokeMethod<T>(method, arguments);
    }

    if (_options.type == SqfliteDatabaseFactoryLoggerType.invoke) {
      var info = await _wrap(doInvokeMethod);
      _options.log(_SqfliteLoggerInvokeEvent(
          info.sw, method, arguments, info.result, info.error));
      return info.throwOrResult();
    } else {
      return await doInvokeMethod();
    }
  }
/*
  @override
  Future<void> closeDatabase(SqfliteDatabase database) =>
      _delegate.closeDatabase(database);

  @override
  Future<bool> databaseExists(String path) => _delegate.databaseExists(path);

  @override
  Future<void> deleteDatabase(String path) => _delegate.deleteDatabase(path);

  @override
  Future<String> getDatabasesPath() => _delegate.getDatabasesPath();

  @override
  void removeDatabaseOpenHelper(String path) =>
      _delegate.removeDatabaseOpenHelper(path);

  @override
  Future<void> setDatabasesPath(String? path) =>
      _delegate.setDatabasesPath(path!);

  @override
  Future<T> wrapDatabaseException<T>(Future<T> Function() action) =>
      _delegate.wrapDatabaseException(action);*/
}

/// internal extension.
@visibleForTesting
extension OpenDatabaseOptionsLogger on OpenDatabaseOptions {
  /// To map view
  Map<String, Object?> toMap() => <String, Object?>{
        'readOnly': readOnly,
        'singleInstance': singleInstance,
        if (version != null) 'version': version
      };
}
