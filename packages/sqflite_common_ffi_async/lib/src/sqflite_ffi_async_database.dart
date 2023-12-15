import 'dart:collection';
import 'dart:io';

import 'package:path/path.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_async/src/sqflite_ffi_async_factory.dart';
import 'package:sqflite_common_ffi_async/src/sqflite_ffi_async_transaction.dart';
import 'package:sqlite_async/sqlite3.dart' as sqlite3;
import 'package:sqlite_async/sqlite_async.dart' as sqlite_async;

import 'import.dart';

class SqfliteDatabaseAsync extends SqfliteDatabaseBase {
  static int _id = 0;
  late final asyncId = ++_id;
  late sqlite_async.SqliteDatabase _database;

  SqfliteDatabaseAsync(super.openHelper, super.path);

  @override
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action,
      {bool? exclusive}) async {
    return _wrapFfiAsyncCall(() async {
      if (openTransaction is SqfliteFfiAsyncTransaction) {
        var sqfliteTxn = openTransaction as SqfliteFfiAsyncTransaction;
        var result = await action(sqfliteTxn);
        return result;
      }
      return await _database.writeTransaction((wc) async {
        var txn = SqfliteFfiAsyncTransaction(this, wc);
        var result = await action(txn);
        return result;
      });
    });
  }

  @override
  Future<int> openDatabase() async {
    sqlite_async.SqliteOptions sqliteOptions;
    int maxReaders = sqlite_async.SqliteDatabase.defaultMaxReaders;
    var path = this.path;
    if (path == inMemoryDatabasePath) {
      var dir = await Directory.systemTemp.createTemp();
      path = this.path = join(dir.path, 'in_memory_$asyncId.db');
    }
    if (options?.readOnly ?? false) {
      if (!await factoryFfi.databaseExists(path)) {
        throw SqfliteDatabaseException(
            'read-only Database not found: $path', null);
      }
      sqliteOptions = sqlite_async.SqliteOptions(
          journalMode: null, journalSizeLimit: null, synchronous: null);
    } else {
      var dir = Directory(dirname(path));
      try {
        if (!dir.existsSync()) {
          // Create the directory if needed
          await dir.create(recursive: true);
        }
      } catch (e) {
        print('error checking directory $dir: $e');
      }
      sqliteOptions = sqlite_async.SqliteOptions.defaults();
    }
    final factory = sqlite_async.DefaultSqliteOpenFactory(
        path: path, sqliteOptions: sqliteOptions);

    _database = sqlite_async.SqliteDatabase.withFactory(factory,
        maxReaders: maxReaders);
    //_database = sqlite_async.SqliteDatabase(path: path);
    return asyncId;
  }

  Future<List<Map<String, Object?>>> _select(sqlite_async.SqliteReadContext wc,
      String sql, List<Object?>? arguments) async {
    var resultSet = await wc.getAll(sql, _fixArguments(arguments));
    return SqfliteResultSet(resultSet);
  }

  @override
  Future<List<Map<String, Object?>>> txnRawQuery(
      SqfliteTransaction? txn, String sql, List<Object?>? arguments) async {
    return _wrapFfiAsyncCall(() {
      return _select(_readContext(txn), sql, arguments);
    });
  }

  /// Execute a raw SELECT command by page.
  /// TODO not supported yet
  @override
  Future<SqfliteQueryCursor> txnRawQueryCursor(SqfliteTransaction? txn,
      String sql, List<Object?>? arguments, int pageSize) async {
    var results = await _select(_readContext(txn), sql, arguments);
    return SqfliteQueryCursor(this, txn, null, results);
  }

  List<Object?> _fixArguments(List<Object?>? arguments) {
    return arguments ?? const <Object?>[];
  }

  Future<T> _wrapFfiAsyncCall<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      throw ffiWrapAnyException(e);
    }
  }

  sqlite_async.SqliteWriteContext _writeContext(SqfliteTransaction? txn) {
    return (txn as SqfliteFfiAsyncTransaction?)?.writeContext ?? _database;
  }

  sqlite_async.SqliteReadContext _readContext(SqfliteTransaction? txn) =>
      _writeContext(txn);

  Future<T> _writeTransaction<T>(SqfliteTransaction? txn,
      Future<T> Function(sqlite_async.SqliteWriteContext writeContext) action) {
    if (txn == null) {
      return _wrapFfiAsyncCall(() async {
        return await _database.writeTransaction(action);
      });
    } else {
      return _wrapFfiAsyncCall(() async {
        return await action((txn as SqfliteFfiAsyncTransaction).writeContext);
      });
    }
  }

  @override
  Future<T> txnExecute<T>(
      SqfliteTransaction? txn, String sql, List<Object?>? arguments,
      {bool? beginTransaction}) {
    // devPrint('txnExecute $sql $arguments');
    return _writeTransaction<T>(txn, (wc) async {
      var result = await wc.execute(sql, _fixArguments(arguments));
      return result as T;
    });
  }

  //}

  Future<int> _insert(sqlite_async.SqliteWriteContext wc, String sql,
      List<Object?>? arguments) async {
    // Result is empty list
    await wc.execute(sql, _fixArguments(arguments));

    var result =
        await wc.get('SELECT last_insert_rowid() as rowid, changes() as count');
    // devPrint('insert $result');
    var count = result['count'] as int;
    if (count > 0) {
      return result['rowid'] as int;
    } else {
      return 0;
    }
  }

  @override
  Future<int> txnRawInsert(
      SqfliteTransaction? txn, String sql, List<Object?>? arguments) async {
    // devPrint('txnRawInsert $sql $arguments');
    return _writeTransaction<int>(txn, (wc) async {
      return _insert(wc, sql, arguments);
    });
  }

  @override
  Future<List<Object?>> txnApplyBatch(
      SqfliteTransaction? txn, SqfliteBatch batch,
      {bool? noResult, bool? continueOnError}) {
    return _writeTransaction(txn, (wc) async {
      var results = <Object?>[];

      void addResult(Object? result) {
        if (noResult != true) {
          results.add(result);
        }
      }

      for (var operation in batch.operations) {
        try {
          switch (operation.type) {
            case SqliteSqlCommandType.insert:
              addResult(await _insert(wc, operation.sql, operation.arguments));
              break;
            case SqliteSqlCommandType.update:
              addResult(await _updateOrDelete(
                  wc, operation.sql, operation.arguments));
              break;

            case SqliteSqlCommandType.delete:
              addResult(await _updateOrDelete(
                  wc, operation.sql, operation.arguments));
              break;
            case SqliteSqlCommandType.execute:
              await wc.execute(
                  operation.sql, _fixArguments(operation.arguments));
              addResult(null);
            case SqliteSqlCommandType.query:
              addResult(await _select(wc, operation.sql, operation.arguments));
              break;
          }
        } catch (e) {
          if (continueOnError ?? false) {
            continue;
          } else {
            rethrow;
          }
        }
      }
      return results;
    });
  }

  /// for Update sql query
  /// returns the update count
  @override
  Future<int> txnRawUpdate(
          SqfliteTransaction? txn, String sql, List<Object?>? arguments) =>
      _txnRawUpdateOrDelete(txn, sql, arguments);

  /// for Delete sql query
  /// returns the delete count
  @override
  Future<int> txnRawDelete(
          SqfliteTransaction? txn, String sql, List<Object?>? arguments) =>
      _txnRawUpdateOrDelete(txn, sql, arguments);

  Future<int> _txnRawUpdateOrDelete(
      SqfliteTransaction? txn, String sql, List<Object?>? arguments) {
    return _writeTransaction<int>(txn, (wc) async {
      // Result is empty list
      return await _updateOrDelete(wc, sql, arguments);
    });
  }

  Future<int> _updateOrDelete(sqlite_async.SqliteWriteContext wc, String sql,
      List<Object?>? arguments) async {
    // Result is empty list
    await wc.execute(sql, _fixArguments(arguments));

    var result = await wc.get('SELECT changes() as count');
    // devPrint('insert $result');
    return result['count'] as int;
  }

  @override
  Future<void> close() async {
    await super.close();
  }

  Future<void> _closeSqfliteAsyncDatabase() {
    return _database.close();
  }

  @override
  Future<void> closeDatabase() {
    return _closeSqfliteAsyncDatabase();
  }
}

class SqfliteResultSet extends ListBase<Map<String, Object?>> {
  final sqlite3.ResultSet resultSet;

  @override
  int get length => resultSet.length;

  SqfliteResultSet(this.resultSet);

  @override
  Map<String, Object?> operator [](int index) {
    return resultSet[index];
  }

  @override
  void operator []=(int index, Map<String, Object?> value) {
    throw UnsupportedError('Read-only');
  }

  @override
  set length(int newLength) {
    throw UnsupportedError('Read-only');
  }
}
