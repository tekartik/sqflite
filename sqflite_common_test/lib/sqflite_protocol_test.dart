import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_test/src/core_import.dart';
import 'package:sqflite_common_test/src/test_scenario.dart';
import 'package:test/test.dart';

/// Common open step
var openStep = [
  'openDatabase',
  {'path': ':memory:', 'singleInstance': true},
  {'id': 1}
];

/// Common close step
var closeStep = [
  'closeDatabase',
  {'id': 1},
  null
];

/// Test with a mock implementation by default
void main() {
  run(null);
}

/// Run open test.
void run(SqfliteTestContext? context) {
  var factory = context?.databaseFactory;
  group('protocol', () {
    test('open close', () async {
      final scenario = wrapStartScenario(factory, [openStep, closeStep]);
      final db = await scenario.factory.openDatabase(inMemoryDatabasePath);
      await db.close();
      scenario.end();
    });
    test('execute', () async {
      final scenario = wrapStartScenario(factory, [
        openStep,
        [
          'execute',
          {'sql': 'PRAGMA user_version = 1', 'id': 1},
          null,
        ],
        closeStep
      ]);
      final db = await scenario.factory.openDatabase(inMemoryDatabasePath);
      await db.setVersion(1);

      await db.close();
      scenario.end();
    });

    test('transaction', () async {
      final scenario = wrapStartScenario(factory, [
        openStep,
        [
          'execute',
          {
            'sql': 'BEGIN IMMEDIATE',
            'id': 1,
            'inTransaction': true,
            'transactionId': null
          },
          {'transactionId': 1},
        ],
        [
          'execute',
          {
            'sql': 'COMMIT',
            'id': 1,
            'inTransaction': false,
            'transactionId': 1
          },
          null,
        ],
        closeStep
      ]);
      final db = await scenario.factory.openDatabase(inMemoryDatabasePath);
      await db.transaction((txn) async {});

      await db.close();
      scenario.end();
    });

    test('manual begin transaction', () async {
      final scenario = wrapStartScenario(factory, [
        openStep,
        [
          'execute',
          {'sql': 'BEGIN TRANSACTION', 'id': 1, 'inTransaction': true},
          null,
        ],
        [
          'execute',
          {
            'sql': 'ROLLBACK',
            'id': 1,
            'inTransaction': false,
            'transactionId': -1
          },
          null,
        ],
        closeStep
      ]);
      final db = await scenario.factory.openDatabase(inMemoryDatabasePath);
      await db.execute('BEGIN TRANSACTION');

      await db.close();
      scenario.end();
    });

    test('manual begin end transaction', () async {
      final scenario = wrapStartScenario(factory, [
        openStep,
        [
          'execute',
          {'sql': 'BEGIN TRANSACTION', 'id': 1, 'inTransaction': true},
          null,
        ],
        [
          'execute',
          {'sql': 'ROLLBACK', 'id': 1, 'inTransaction': false},
          null,
        ],
        closeStep
      ]);
      final db = await scenario.factory.openDatabase(inMemoryDatabasePath);
      await db.execute('BEGIN TRANSACTION');
      await db.execute('ROLLBACK');

      await db.close();
      scenario.end();
    });
  });
}
