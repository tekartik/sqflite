import 'package:sqflite_common/sqflite_logger.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_test/src/sqflite_import.dart';
import 'package:test/test.dart';

import 'sqflite_logger_test.dart';

var _events = <SqfliteLoggerEvent>[];
var _factory = SqfliteDatabaseFactoryLogger(
  createDatabaseFactoryFfi(noIsolate: true),
  options: SqfliteLoggerOptions(
    type: SqfliteDatabaseFactoryLoggerType.all,
    log: (e) {
      print(e);
      _events.add(e);
    },
  ),
);
var _invokeFactory = SqfliteDatabaseFactoryLogger(
  createDatabaseFactoryFfi(noIsolate: false),
  options: SqfliteLoggerOptions(
    type: SqfliteDatabaseFactoryLoggerType.invoke,
    log: (e) {
      print(e);
      _events.add(e);
    },
  ),
);
Future<void> main() async {
  /// Initialize ffi loader
  sqfliteFfiInit();
  // Add _no_isolate suffix to the path
  var dbsPath = await _factory.getDatabasesPath();
  await _factory.setDatabasesPath('${dbsPath}_all_logger_various_no_isolate');

  group('delete/exists', () {
    test('delete', () async {
      _events.clear();
      // await _invokeFactory.deleteDatabase(inMemoryDatabasePath);
      await _invokeFactory.invokeMethod<void>(
        'deleteDatabase',
        <String, Object?>{'path': ':memory:'},
      ); // deleteDatabase(inMemoryDatabasePath);

      expect(_events.toMapListNoSw(), [
        {
          'method': 'deleteDatabase',
          'arguments': {'path': ':memory:'},
        },
      ]);
      var event = _events.first as SqfliteLoggerInvokeEvent;
      expect(event.sw!.isRunning, isFalse);
      expect(event.method, 'deleteDatabase');

      _events.clear();
      await _factory.deleteDatabase(inMemoryDatabasePath);
      var deleteEvent = _events.first as SqfliteLoggerDatabaseDeleteEvent;
      expect(deleteEvent.sw!.isRunning, isFalse);
      expect(deleteEvent.path, inMemoryDatabasePath);
      expect(_events.toMapListNoSw(), [
        {'path': ':memory:'},
      ]);
    });
    test('exists', () async {
      _events.clear();
      await _invokeFactory.databaseExists(inMemoryDatabasePath);
      expect(_events.toMapListNoSw(), [
        {
          'method': 'databaseExists',
          'arguments': {'path': ':memory:'},
          'result': false,
        },
      ]);
      _events.clear();
      await _factory.databaseExists(inMemoryDatabasePath);
      expect(_events.toMapListNoSw(), isEmpty);
    });
  });
  group('various_test_value', () {
    late Database db;
    late int? dbId;
    setUp(() async {
      _events.clear();
      db = await _factory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          singleInstance: true,
          version: 1,
          onCreate: (db, version) async {
            await db.execute(
              'CREATE TABLE Test (_id INTEGER PRIMARY KEY, value INTEGER)',
            );
          },
        ),
      );
      dbId = db.databaseId;
    });
    tearDown(() async {
      await db.close();
    });

    test('open/close', () async {
      expect(_events.toMapListNoSw(), [
        {
          'path': ':memory:',
          'options': {'readOnly': false, 'singleInstance': true, 'version': 1},
          'id': dbId,
        },
        {
          'db': dbId,
          'sql': 'PRAGMA user_version',
          'result': [
            {'user_version': 0},
          ],
        },
        {
          'db': dbId,
          'sql': 'BEGIN EXCLUSIVE',
          'result': {'transactionId': 1},
        },
        {
          'db': dbId,
          'txn': 1,
          'sql': 'PRAGMA user_version',
          'result': [
            {'user_version': 0},
          ],
        },
        {
          'db': dbId,
          'txn': 1,
          'sql': 'CREATE TABLE Test (_id INTEGER PRIMARY KEY, value INTEGER)',
        },
        {'db': dbId, 'txn': 1, 'sql': 'PRAGMA user_version = 1'},
        {'db': dbId, 'txn': 1, 'sql': 'COMMIT'},
      ]);
      var event = _events[0];
      expect(event, isA<SqfliteLoggerDatabaseOpenEvent>());
      var openEvent = event as SqfliteLoggerDatabaseOpenEvent;
      expect(openEvent.options?.version, 1);
      expect(openEvent.path, inMemoryDatabasePath);
      expect(openEvent.db, db);
      expect(openEvent.databaseId, isNotNull);
      _events.clear();

      await db.close();
      expect(_events.toMapListNoSw(), [
        {'db': 1},
      ]);
      event = _events[0];
      expect(event, isA<SqfliteLoggerDatabaseCloseEvent>());
      var closeEvent = event as SqfliteLoggerDatabaseCloseEvent;
      expect(openEvent.databaseId, isNotNull);
      expect(closeEvent.db, db);
    });

    test('insert/update/query/delete/execute', () async {
      _events.clear();

      // insert
      var key1 = await db.insert('Test', {'value': 1});

      expect(_events.toMapListNoSw(), [
        {
          'db': dbId,
          'sql': 'INSERT INTO Test (value) VALUES (?)',
          'arguments': [1],
          'result': 1,
        },
      ]);
      var event = _events[0];
      expect(event, isA<SqfliteLoggerSqlCommandInsert>());
      expect(event, isA<SqfliteLoggerSqlEvent>());
      var sqlEvent = event as SqfliteLoggerSqlEvent;
      expect(sqlEvent.type, SqliteSqlCommandType.insert);

      _events.clear();
      await db.update(
        'Test',
        {'value': 2},
        where: '_id = ?',
        whereArgs: [key1],
      );
      expect(_events.toMapListNoSw(), [
        {
          'db': dbId,
          'sql': 'UPDATE Test SET value = ? WHERE _id = ?',
          'arguments': [2, 1],
          'result': 1,
        },
      ]);
      event = _events[0];
      expect(event, isA<SqfliteLoggerSqlCommandUpdate>());
      expect(event, isA<SqfliteLoggerSqlEvent>());
      sqlEvent = event as SqfliteLoggerSqlEvent;
      expect(sqlEvent.type, SqliteSqlCommandType.update);
      expect(sqlEvent.databaseId, dbId);

      // Query
      _events.clear();
      await db.query('Test');
      expect(_events.toMapListNoSw(), [
        {
          'db': dbId,
          'sql': 'SELECT * FROM Test',
          'result': [
            {'_id': 1, 'value': 2},
          ],
        },
      ]);

      event = _events[0];
      expect(event, isA<SqfliteLoggerSqlCommandQuery>());
      expect(event, isA<SqfliteLoggerSqlEvent>());
      sqlEvent = event as SqfliteLoggerSqlEvent;
      expect(sqlEvent.type, SqliteSqlCommandType.query);

      // Delete
      _events.clear();
      await db.delete('Test');
      expect(_events.toMapListNoSw(), [
        {'db': dbId, 'sql': 'DELETE FROM Test', 'result': 1},
      ]);

      event = _events[0];
      expect(event, isA<SqfliteLoggerSqlCommandDelete>());
      expect(event, isA<SqfliteLoggerSqlEvent>());
      sqlEvent = event as SqfliteLoggerSqlEvent;
      expect(sqlEvent.type, SqliteSqlCommandType.delete);

      // Execute
      _events.clear();
      await db.execute('DROP TABLE IF EXISTS Dummy');
      expect(_events.toMapListNoSw(), [
        {'db': dbId, 'sql': 'DROP TABLE IF EXISTS Dummy'},
      ]);

      event = _events[0];
      expect(event, isA<SqfliteLoggerSqlCommandExecute>());
      expect(event, isA<SqfliteLoggerSqlEvent>());
      sqlEvent = event as SqfliteLoggerSqlEvent;
      expect(sqlEvent.type, SqliteSqlCommandType.execute);
    });

    test('batch insert/update/query/delete', () async {
      _events.clear();
      var batch = db.batch();
      batch.insert('Test', {'value': 1});
      batch.update('Test', {'value': 2}, where: '_id = ?', whereArgs: [1]);
      batch.query('Test');
      batch.delete('Test');
      batch.execute('DROP TABLE IF EXISTS Dummy');
      await batch.apply();

      expect(_events.toMapListNoSw(), [
        {
          'db': dbId,
          'operations': [
            {
              'sql': 'INSERT INTO Test (value) VALUES (?)',
              'arguments': [1],
              'result': 1,
            },
            {
              'sql': 'UPDATE Test SET value = ? WHERE _id = ?',
              'arguments': [2, 1],
              'result': 1,
            },
            {
              'sql': 'SELECT * FROM Test',
              'result': [
                {'_id': 1, 'value': 2},
              ],
            },
            {'sql': 'DELETE FROM Test', 'result': 1},
            {'sql': 'DROP TABLE IF EXISTS Dummy'},
          ],
        },
      ]);
      var operationEvent = _events[0];
      var operations = (operationEvent as SqfliteLoggerBatchEvent).operations;
      var operation = operations[0];
      expect(operation, isA<SqfliteLoggerSqlCommandInsert>());
      expect(operation.type, SqliteSqlCommandType.insert);

      operation = operations[1];
      expect(operation, isA<SqfliteLoggerSqlCommandUpdate>());
      expect(operation.type, SqliteSqlCommandType.update);

      operation = operations[2];
      expect(operation, isA<SqfliteLoggerSqlCommandQuery>());
      expect(operation.type, SqliteSqlCommandType.query);

      operation = operations[3];
      expect(operation, isA<SqfliteLoggerSqlCommandDelete>());
      expect(operation.type, SqliteSqlCommandType.delete);

      operation = operations[4];
      expect(operation, isA<SqfliteLoggerSqlCommandExecute>());
      expect(operation.type, SqliteSqlCommandType.execute);
      expect(operationEvent.databaseId, dbId);
      expect(operationEvent.transactionId, isNull);
    });

    test('crud', () async {
      _events.clear();
      var key1 = await db.insert('Test', {'value': 1});
      late int key2;
      await db.query('Test');
      await db.transaction((txn) async {
        key2 = await txn.insert('Test', {'value': 2});
        await txn.query('Test');
        await txn.update(
          'Test',
          {'value': 3},
          where: '_id = ?',
          whereArgs: [key1],
        );
        await txn.delete('Test', where: '_id = ?', whereArgs: [key1]);
      });
      await db.update(
        'Test',
        {'value': 4},
        where: '_id = ?',
        whereArgs: [key2],
      );
      await db.delete('Test', where: '_id = ?', whereArgs: [key2]);
      var batch = db.batch();
      batch.insert('Test', {'value': 5});
      await batch.commit();

      expect(_events.toMapListNoSw(), [
        {
          'db': dbId,
          'sql': 'INSERT INTO Test (value) VALUES (?)',
          'arguments': [1],
          'result': 1,
        },
        {
          'db': dbId,
          'sql': 'SELECT * FROM Test',
          'result': [
            {'_id': 1, 'value': 1},
          ],
        },
        {
          'db': dbId,
          'sql': 'BEGIN IMMEDIATE',
          'result': {'transactionId': 2},
        },
        {
          'db': dbId,
          'txn': 2,
          'sql': 'INSERT INTO Test (value) VALUES (?)',
          'arguments': [2],
          'result': 2,
        },
        {
          'db': dbId,
          'txn': 2,
          'sql': 'SELECT * FROM Test',
          'result': [
            {'_id': 1, 'value': 1},
            {'_id': 2, 'value': 2},
          ],
        },
        {
          'db': dbId,
          'txn': 2,
          'sql': 'UPDATE Test SET value = ? WHERE _id = ?',
          'arguments': [3, 1],
          'result': 1,
        },
        {
          'db': dbId,
          'txn': 2,
          'sql': 'DELETE FROM Test WHERE _id = ?',
          'arguments': [1],
          'result': 1,
        },
        {'db': dbId, 'txn': 2, 'sql': 'COMMIT'},
        {
          'db': dbId,
          'sql': 'UPDATE Test SET value = ? WHERE _id = ?',
          'arguments': [4, 2],
          'result': 1,
        },
        {
          'db': dbId,
          'sql': 'DELETE FROM Test WHERE _id = ?',
          'arguments': [2],
          'result': 1,
        },
        {
          'db': dbId,
          'sql': 'BEGIN IMMEDIATE',
          'result': {'transactionId': 3},
        },
        {
          'db': dbId,
          'txn': 3,
          'operations': [
            {
              'sql': 'INSERT INTO Test (value) VALUES (?)',
              'arguments': [5],
              'result': 1,
            },
          ],
        },
        {'db': dbId, 'txn': 3, 'sql': 'COMMIT'},
      ]);
      var event = _events[4] as SqfliteLoggerSqlEvent;
      expect(event.databaseId, dbId);
      expect(event.transactionId, 2);

      _events.clear();

      await db.transaction((txn) async {
        var batch = txn.batch();
        batch.insert('Test', {'value': 5});
        await batch.commit(noResult: true);
      });

      expect(_events.toMapListNoSw(), [
        {
          'db': dbId,
          'sql': 'BEGIN IMMEDIATE',
          'result': {'transactionId': 4},
        },
        {
          'db': dbId,
          'txn': 4,
          'operations': [
            {
              'sql': 'INSERT INTO Test (value) VALUES (?)',
              'arguments': [5],
            },
          ],
        },
        {'db': dbId, 'txn': 4, 'sql': 'COMMIT'},
      ]);

      await db.close();
      _events.clear();
      expect(_events.toMapListNoSw(), isEmpty);
    });
  });
}
