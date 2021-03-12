import 'dart:typed_data';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:test/test.dart';

import 'test_scenario.dart';

var openStep = [
  'openDatabase',
  {'path': ':memory:', 'singleInstance': true},
  1
];
var closeStep = [
  'closeDatabase',
  {'id': 1},
  null
];

void main() {
  group('sqflite', () {
    test('open insert', () async {
      final scenario = startScenario([
        openStep,
        [
          'insert',
          {
            'sql': 'INSERT INTO test (blob) VALUES (?)',
            'arguments': [
              [1, 2, 3]
            ],
            'id': 1
          },
          1
        ],
        closeStep
      ]);
      final db = await scenario.factory.openDatabase(inMemoryDatabasePath);
      expect(
          await db.insert('test', {
            'blob': Uint8List.fromList([1, 2, 3])
          }),
          1);
      await db.close();
      scenario.end();
    });

    test('open insert conflict', () async {
      final scenario = startScenario([
        openStep,
        [
          'insert',
          {
            'sql': 'INSERT OR IGNORE INTO test (value) VALUES (?)',
            'arguments': [1],
            'id': 1
          },
          1
        ],
        closeStep
      ]);
      final db = await scenario.factory.openDatabase(inMemoryDatabasePath);
      expect(
          await db.insert('test', {'value': 1},
              conflictAlgorithm: ConflictAlgorithm.ignore),
          1);
      await db.close();
      scenario.end();
    });

    test('open batch insert', () async {
      final scenario = startScenario([
        openStep,
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
        closeStep
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
