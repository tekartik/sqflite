import 'dart:async';

import 'package:meta/meta.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/batch.dart';
import 'package:sqflite_common/src/constant.dart';
import 'package:sqflite_common/src/database.dart';
import 'package:sqflite_common/src/database_mixin.dart';
import 'package:sqflite_common/src/env_utils.dart';
import 'package:sqflite_common/src/factory.dart';
import 'package:sqflite_common/src/factory_mixin.dart';
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

/// Logger event.
abstract class SqfliteLoggerEvent {
  /// Set on failure
  Object? get error;

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
  final Object? error;

  @override
  final Stopwatch? sw;

  _SqfliteLoggerEvent(this.sw, this.error);

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
abstract class SqfliteLoggerSqlEvent extends SqfliteLoggerDatabaseEvent {
  /// Invoke arguments.
  String get sql;

  /// Sql arguments.
  Object? get arguments;

  /// Optional result.
  Object? get result;
}

/// batch event
abstract class SqfliteLoggerBatchEvent extends SqfliteLoggerDatabaseEvent {
  /// batch operations.
  List<SqfliteLoggerBatchOperation> get operations;
}

/// Open db event
abstract class SqfliteLoggerBatchOperation {
  /// Invoke arguments.
  String get sql;

  /// Sql arguments.
  Object? get arguments;

  /// Optional result.
  Object? get result;

  /// Optional error.
  Object? get error;
}

class _SqfliteLoggerDatabaseEvent extends _SqfliteLoggerEvent
    implements SqfliteLoggerDatabaseEvent {
  @override
  final DatabaseExecutor client;

  Map<String, Object?> get _databasePrefixMap => {
        if (client.database is SqfliteDatabase)
          'db': (client.database as SqfliteDatabase).id,
        if (txnId != null) 'txn': txnId
      };

  late int? txnId;

  @override
  Map<String, Object?> toMap() => {..._databasePrefixMap, ...super.toMap()};

  _SqfliteLoggerDatabaseEvent(super.sw, this.client, super.error) {
    // save txn id right away to handle when not set yet.
    txnId = (client as SqfliteDatabaseExecutorMixin).txn?.transactionId;
  }
}

/// Sql command type.
enum SqliteLoggerSqlCommandType {
  /// such CREATE TABLE, DROP_INDEX, pragma
  execute,

  /// Insert statement,
  insert,

  /// Update statement.
  update,

  /// Delete statement.
  delete,

  /// Query statement (SELECTà
  query,
}

class _SqfliteLoggerSqlEvent extends _SqfliteLoggerDatabaseEvent
    implements SqfliteLoggerSqlEvent {
  final SqliteLoggerSqlCommandType type;
  @override
  final String sql;

  String get _typeAsText => type.toString().split('.').last;
  @override
  final Object? arguments;

  @override
  final Object? result;

  _SqfliteLoggerSqlEvent(super.sw, super.client, this.type, this.sql,
      this.arguments, this.result, super.error);

  @override
  Map<String, Object?> toMap() => {
        ..._databasePrefixMap,
        'sql': sql,
        if (arguments != null) 'arguments': arguments,
        if (result != null) 'result': result,
        ...super.toMap()
      };

  @override
  String toString() => '$_typeAsText${super.toString()})';
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

/// Open db event
class _SqfliteLoggerBatchOperation implements SqfliteLoggerBatchOperation {
  @override
  final String sql;

  @override
  final Object? arguments;

  @override
  final Object? result;

  @override
  final Object? error;

  _SqfliteLoggerBatchOperation(
      this.sql, this.arguments, this.result, this.error);

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
  String toString() => logTruncate(toMap().toString());
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

mixin _SqfliteDatabaseWithDelegateMixin implements SqfliteDatabaseMixin {
  @override
  String get path => delegate.path;

  SqfliteDatabaseMixin get delegate;

  @override
  int? get id => delegate.id;

  @override
  set id(int? id) => delegate.id = id;

  @override
  bool get inTransaction => delegate.inTransaction;

  @override
  set inTransaction(bool inTransaction) =>
      delegate.inTransaction = inTransaction;

  @override
  OpenDatabaseOptions? get options => delegate.options;

  /*
  @override
  SqfliteDatabaseOpenHelper? get openHelper => delegate.openHelper;

  set openHelper(SqfliteDatabaseOpenHelper? openHelper) =>
      delegate.openHelper = openHelper;*/
  @override
  SqfliteTransaction? get txn => openTransaction;

  @override
  SqfliteTransaction? get openTransaction => delegate.openTransaction;

  @override
  set openTransaction(SqfliteTransaction? openTransaction) =>
      delegate.openTransaction = openTransaction;
}

mixin _SqfliteDatabaseExecutorLoggerMixin implements SqfliteDatabaseExecutor {
  SqfliteDatabaseExecutor get _delegate;

  SqfliteDatabaseMixin get _delegateDatabaseMixin =>
      _delegate.database as SqfliteDatabaseMixin;

  SqfliteDatabaseExecutor _executor(SqfliteTransaction? txn) =>
      txn ?? this.txn ?? this;

  SqfliteTransaction? _delegateTransactionOrNull(SqfliteTransaction? txn) =>
      (txn as _SqfliteTransactionLogger?)?._delegate;
}

class _SqfliteDatabaseLogger
    with
        SqfliteDatabaseMixin,
        SqfliteDatabaseExecutorMixin,
        _SqfliteDatabaseExecutorLoggerMixin,
        _SqfliteDatabaseWithDelegateMixin
    implements SqfliteDatabase {
  final _SqfliteDatabaseFactoryLogger _factory;
  @override
  final SqfliteDatabaseMixin _delegate;

  @override
  SqfliteDatabaseMixin get delegate => _delegate;

  @override
  _SqfliteDatabaseFactoryLogger get factory => _factory;

  _SqfliteDatabaseLogger(this._factory, this._delegate);

  @override
  SqfliteTransaction? get openTransaction => _delegate.openTransaction == null
      ? null
      : _SqfliteTransactionLogger(this, _delegate.openTransaction!);

  @override
  set openTransaction(SqfliteTransaction? openTransaction) =>
      _delegate.openTransaction = _delegateTransactionOrNull(openTransaction);

  SqfliteLoggerOptions get _options => _factory._options;

  @override
  Future<void> close() async {
    var info = await _wrap<void>(() => _delegate.close());
    _options.log(_SqfliteLoggerDatabaseCloseEvent(info.sw, this, info.error));
    info.throwOrResult();
  }

  /// New transaction.
  @override
  SqfliteTransaction newTransaction() {
    final txn = _SqfliteTransactionLogger(this, super.newTransaction());
    return txn;
  }

  /// Commit a batch.
  @override
  Future<List<Object?>> txnApplyBatch(
      SqfliteTransaction? txn, SqfliteBatch batch,
      {bool? noResult, bool? continueOnError}) async {
    var info = await _wrap<List<Object?>>(() => _delegate.txnApplyBatch(
        txn, batch,
        noResult: noResult, continueOnError: continueOnError));

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
        logOperations.add(_SqfliteLoggerBatchOperation(
            operation[paramSql] as String,
            operation[paramSqlArguments],
            result,
            error));
      }
    }
    _options.log(_SqfliteLoggerBatchEvent(
        info.sw, _executor(txn), logOperations, info.error));
    return info.throwOrResult();
  }

  /// Execute a raw SQL SELECT query
  ///
  /// Returns a list of rows that were found
  @override
  Future<List<Map<String, Object?>>> txnRawQuery(
      SqfliteTransaction? txn, String sql, List<Object?>? arguments) {
    return _txnWrapSql(txn, SqliteLoggerSqlCommandType.query, sql, arguments,
        () async {
      return _delegateDatabaseMixin.txnRawQuery(
          _delegateTransactionOrNull(txn), sql, arguments);
    });
  }

  @override
  Future<int> txnRawDelete(
      SqfliteTransaction? txn, String sql, List<Object?>? arguments) {
    return _txnWrapSql(txn, SqliteLoggerSqlCommandType.delete, sql, arguments,
        () async {
      return _delegateDatabaseMixin.txnRawDelete(
          _delegateTransactionOrNull(txn), sql, arguments);
    });
  }

  @override
  Future<int> txnRawUpdate(
      SqfliteTransaction? txn, String sql, List<Object?>? arguments) {
    return _txnWrapSql(txn, SqliteLoggerSqlCommandType.update, sql, arguments,
        () async {
      return _delegateDatabaseMixin.txnRawUpdate(
          _delegateTransactionOrNull(txn), sql, arguments);
    });
  }

  /// for INSERT sql query
  /// returns the last inserted record id
  ///
  /// 0 returned instead of null
  @override
  Future<int> txnRawInsert(
      SqfliteTransaction? txn, String sql, List<Object?>? arguments) {
    return _txnWrapSql(txn, SqliteLoggerSqlCommandType.insert, sql, arguments,
        () async {
      return _delegateDatabaseMixin.txnRawInsert(
          _delegateTransactionOrNull(txn), sql, arguments);
    });
  }

  /// Execute a command.
  @override
  Future<T> txnExecute<T>(
      SqfliteTransaction? txn, String sql, List<Object?>? arguments,
      {bool? beginTransaction}) {
    return _txnWrapSql(
        txn,
        SqliteLoggerSqlCommandType.execute,
        sql,
        arguments,
        () => _delegateDatabaseMixin.txnExecute(
            _delegateTransactionOrNull(txn), sql, arguments,
            beginTransaction: beginTransaction));
  }

  Future<T> _txnWrapSql<T>(
      SqfliteTransaction? txn,
      SqliteLoggerSqlCommandType type,
      String sql,
      List<Object?>? arguments,
      Future<T> Function() action) async {
    if (_options.type != SqfliteDatabaseFactoryLoggerType.all) {
      return await action();
    } else {
      var info = await _wrap<T>(action);
      _options.log(_SqfliteLoggerSqlEvent(info.sw, _executor(txn), type, sql,
          arguments, info.result, info.error));
      return info.throwOrResult();
    }
  }

  Future<_EventInfo<T>> _wrap<T>(FutureOr<T> Function() action) =>
      _factory._wrap(action);

  @override
  Future<SqfliteDatabase> doOpen(OpenDatabaseOptions options) =>
      _delegate.doOpen(options);
}

class _SqfliteTransactionLogger
    with SqfliteDatabaseExecutorMixin, _SqfliteDatabaseExecutorLoggerMixin
    implements SqfliteTransaction {
  @override
  final _SqfliteDatabaseLogger db;
  @override
  final SqfliteTransaction _delegate;

  _SqfliteTransactionLogger(this.db, this._delegate);

  @override
  bool? get successful => _delegate.successful;

  @override
  set successful(bool? successful) => _delegate.successful = successful;

  @override
  int? get transactionId => _delegate.transactionId;

  @override
  set transactionId(int? transactionId) =>
      _delegate.transactionId = transactionId;

  @override
  SqfliteDatabaseMixin get database => db;

  @override
  SqfliteTransaction get txn => this;

  @override
  Batch batch() => SqfliteTransactionBatch(this);
}

class _SqfliteDatabaseFactoryLogger
    with SqfliteDatabaseFactoryMixin
    implements SqfliteDatabaseFactoryLogger {
  final SqfliteDatabaseFactory _delegate;
  final SqfliteLoggerOptions _options;

  _SqfliteDatabaseFactoryLogger(this._delegate, this._options);

  @override
  SqfliteDatabaseMixin newDatabase(
      SqfliteDatabaseOpenHelper openHelper, String path) {
    var delegate = _delegate.newDatabase(openHelper, path);
    return _SqfliteDatabaseLogger(this, delegate as SqfliteDatabaseMixin);
  }

  @override
  Future<Database> openDatabase(String path,
      {OpenDatabaseOptions? options}) async {
    Future<SqfliteDatabase> doOpenDatabase() async {
      return (await super.openDatabase(path, options: options))
          as SqfliteDatabase;
    }

    if (_options.type != SqfliteDatabaseFactoryLoggerType.all) {
      return await doOpenDatabase();
    } else {
      var info = await _wrap<SqfliteDatabase>(doOpenDatabase);
      _options.log(_SqfliteLoggerDatabaseOpenEvent(
          info.sw, path, options, info.result, info.error));
      return _SqfliteDatabaseLogger(
          this,
          (info.throwOrResult() as _SqfliteDatabaseExecutorLoggerMixin)
              ._delegateDatabaseMixin);
    }
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
      _delegate.wrapDatabaseException(action);
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
