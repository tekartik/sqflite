import 'dart:typed_data';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:test/test.dart';

import 'sqflite_open_test.dart';

void main() {
  group('sqflite', () {
    test('open insert', () async {
      final scenario = startScenario([
        [
          'openDatabase',
          {'path': ':memory:', 'singleInstance': true},
          1
        ],
        [
          'insert',
          {
            'sql': 'INSERT INTO test (blob) VALUES (?)',
            'arguments': [
              [1, 2, 3]
            ],
            'id': 1
          },
          null
        ],
        [
          'closeDatabase',
          {'id': 1},
          null
        ],
      ]);
      final db = await scenario.factory.openDatabase(inMemoryDatabasePath);
      await db.insert('test', {
        'blob': Uint8List.fromList([1, 2, 3])
      });
      await db.close();
      scenario.end();
    });
    test('open batch insert', () async {
      final scenario = startScenario([
        [
          'openDatabase',
          {'path': ':memory:', 'singleInstance': true},
          1
        ],
        [
          'execute',
          {
            'sql': 'BEGIN IMMEDIATE',
            'arguments': null,
            'id': 1,
            'inTransaction': true
          },
          null
        ],
        [
          'batch',
          {
            'operations': [
              {
                'method': 'insert',
                'sql': 'INSERT INTO test (blob) VALUES (?)',
                'arguments': [
                  [1, 2, 3]
                ]
              }
            ],
            'id': 1
          },
          null
        ],
        [
          'execute',
          {'sql': 'COMMIT', 'arguments': null, 'id': 1, 'inTransaction': false},
          null
        ],
        [
          'closeDatabase',
          {'id': 1},
          null
        ],
      ]);
      final db = await scenario.factory.openDatabase(inMemoryDatabasePath);
      final batch = db.batch();
      batch.insert('test', {
        'blob': Uint8List.fromList([1, 2, 3])
      });
      await batch.commit();
      await db.close();
      scenario.end();
    });
  });
}
