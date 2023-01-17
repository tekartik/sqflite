import 'package:sqflite_common/sqflite_logger.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

import 'sqflite_logger_test.dart';

var _events = <SqfliteLoggerEvent>[];
var _factory =
    SqfliteDatabaseFactoryLogger(createDatabaseFactoryFfi(noIsolate: true),
        options: SqfliteLoggerOptions(
            type: SqfliteDatabaseFactoryLoggerType.all,
            log: (e) {
              print(e);
              _events.add(e);
            }));

Future<void> main() async {
  /// Initialize ffi loader
  sqfliteFfiInit();
  // Add _no_isolate suffix to the path
  var dbsPath = await _factory.getDatabasesPath();
  await _factory.setDatabasesPath('${dbsPath}_all_logger_various_no_isolate');

  setUp(() async {
    _events.clear();
  });
  test('crud', () async {
    var db = await _factory.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute(
                  'CREATE TABLE Test (_id INTEGER PRIMARY KEY, value INTEGER)');
            }));

    expect(_events.toMapListNoSw(), [
      {
        'db': 1,
        'sql': 'PRAGMA user_version',
        'result': [
          {'user_version': 0}
        ]
      },
      {
        'db': 1,
        'sql': 'BEGIN EXCLUSIVE',
        'result': {'transactionId': 1}
      },
      {
        'db': 1,
        'txn': 1,
        'sql': 'PRAGMA user_version',
        'result': [
          {'user_version': 0}
        ]
      },
      {
        'db': 1,
        'txn': 1,
        'sql': 'CREATE TABLE Test (_id INTEGER PRIMARY KEY, value INTEGER)'
      },
      {'db': 1, 'txn': 1, 'sql': 'PRAGMA user_version = 1'},
      {'db': 1, 'txn': 1, 'sql': 'COMMIT'},
      {
        'path': ':memory:',
        'options': {'readOnly': false, 'singleInstance': true, 'version': 1},
        'id': 1
      }
    ]);
    _events.clear();
    var key1 = await db.insert('Test', {'value': 1});
    late int key2;
    await db.query('Test');
    await db.transaction((txn) async {
      key2 = await txn.insert('Test', {'value': 2});
      await txn.query('Test');
      await txn.update('Test', {'value': 3},
          where: '_id = ?', whereArgs: [key1]);
      await txn.delete('Test', where: '_id = ?', whereArgs: [key1]);
    });
    await db.update('Test', {'value': 4}, where: '_id = ?', whereArgs: [key2]);
    await db.delete('Test', where: '_id = ?', whereArgs: [key2]);
    var batch = db.batch();
    batch.insert('Test', {'value': 5});
    await batch.commit();

    expect(_events.toMapListNoSw(), [
      {
        'db': 1,
        'sql': 'INSERT INTO Test (value) VALUES (?)',
        'arguments': [1],
        'result': 1
      },
      {
        'db': 1,
        'sql': 'SELECT * FROM Test',
        'result': [
          {'_id': 1, 'value': 1}
        ]
      },
      {
        'db': 1,
        'sql': 'BEGIN IMMEDIATE',
        'result': {'transactionId': 2}
      },
      {
        'db': 1,
        'txn': 2,
        'sql': 'INSERT INTO Test (value) VALUES (?)',
        'arguments': [2],
        'result': 2
      },
      {
        'db': 1,
        'txn': 2,
        'sql': 'SELECT * FROM Test',
        'result': [
          {'_id': 1, 'value': 1},
          {'_id': 2, 'value': 2}
        ]
      },
      {
        'db': 1,
        'txn': 2,
        'sql': 'UPDATE Test SET value = ? WHERE _id = ?',
        'arguments': [3, 1],
        'result': 1
      },
      {
        'db': 1,
        'txn': 2,
        'sql': 'DELETE FROM Test WHERE _id = ?',
        'arguments': [1],
        'result': 1
      },
      {'db': 1, 'txn': 2, 'sql': 'COMMIT'},
      {
        'db': 1,
        'sql': 'UPDATE Test SET value = ? WHERE _id = ?',
        'arguments': [4, 2],
        'result': 1
      },
      {
        'db': 1,
        'sql': 'DELETE FROM Test WHERE _id = ?',
        'arguments': [2],
        'result': 1
      },
      {
        'db': 1,
        'sql': 'BEGIN IMMEDIATE',
        'result': {'transactionId': 3}
      },
      {
        'db': 1,
        'txn': 3,
        'operations': [
          {
            'sql': 'INSERT INTO Test (value) VALUES (?)',
            'arguments': [5],
            'result': 1
          }
        ]
      },
      {'db': 1, 'txn': 3, 'sql': 'COMMIT'}
    ]);
    _events.clear();

    await db.transaction((txn) async {
      var batch = txn.batch();
      batch.insert('Test', {'value': 5});
      await batch.commit(noResult: true);
    });

    expect(_events.toMapListNoSw(), [
      {
        'db': 1,
        'sql': 'BEGIN IMMEDIATE',
        'result': {'transactionId': 4}
      },
      {
        'db': 1,
        'txn': 4,
        'operations': [
          {
            'sql': 'INSERT INTO Test (value) VALUES (?)',
            'arguments': [5]
          }
        ]
      },
      {'db': 1, 'txn': 4, 'sql': 'COMMIT'}
    ]);

    await db.close();
    _events.clear();
    expect(_events.toMapListNoSw(), isEmpty);
  });
}
