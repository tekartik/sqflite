import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/exception.dart';
import 'package:test/test.dart';

import 'test_scenario.dart';

void main() {
  group('transaction', () {
    final transactionBeginStep = [
      'execute',
      {
        'sql': 'BEGIN IMMEDIATE',
        'id': 1,
        'inTransaction': true,
        'transactionId': null,
      },
      null,
    ];

    // ignore: unused_local_variable
    final readTransactionBeginStep = [
      'execute',
      {'sql': 'BEGIN', 'id': 1, 'inTransaction': true, 'transactionId': null},
      null,
    ];
    final transactionBeginFailureStep = [
      'execute',
      {
        'sql': 'BEGIN IMMEDIATE',
        'id': 1,
        'inTransaction': true,
        'transactionId': null,
      },
      SqfliteDatabaseException('failure', null),
    ];
    final transactionEndStep = [
      'execute',
      {'sql': 'COMMIT', 'id': 1, 'inTransaction': false},
      1,
    ];
    final readTransactionEndStep = [
      'execute',
      {'sql': 'ROLLBACK', 'id': 1, 'inTransaction': false},
      1,
    ];
    test('basic', () async {
      final scenario = startScenario([
        protocolOpenStep,
        transactionBeginStep,
        transactionEndStep,
        transactionBeginStep,
        transactionEndStep,
        protocolCloseStep,
      ]);
      final factory = scenario.factory;
      final db = await factory.openDatabase(inMemoryDatabasePath);

      await db.transaction((txn) async {});
      await db.transaction((txn) async {});
      await db.close();
      scenario.end();
    });
    test('read only', () async {
      final scenario = startScenario([
        protocolOpenStep,
        // readTransactionBeginStep, // one day this will work
        transactionBeginStep,
        readTransactionEndStep,
        protocolCloseStep,
      ]);
      final factory = scenario.factory;
      final db = await factory.openDatabase(inMemoryDatabasePath);

      await db.readTransaction((txn) async {});
      await db.close();
      scenario.end();
    });
    test('error in begin after open', () async {
      final scenario = startScenario([
        protocolOpenStep,
        transactionBeginFailureStep,
        transactionBeginStep,
        transactionEndStep,
        protocolCloseStep,
      ]);
      final factory = scenario.factory;
      final db = await factory.openDatabase(inMemoryDatabasePath);

      try {
        await db.transaction((txn) async {});
        fail('should fail');
      } on DatabaseException catch (_) {}
      await db.transaction((txn) async {});
      await db.close();
      scenario.end();
    });
    test('error in begin during open', () async {
      final scenario = startScenario([
        protocolOpenStep,
        [
          'query',
          {'sql': 'PRAGMA user_version', 'id': 1},
          // ignore: inference_failure_on_collection_literal
          {},
        ],
        [
          'execute',
          {
            'sql': 'BEGIN EXCLUSIVE',
            'id': 1,
            'inTransaction': true,
            'transactionId': null,
          },
          SqfliteDatabaseException('failure', null),
        ],
        [
          'execute',
          {
            'sql': 'ROLLBACK',
            'id': 1,
            'transactionId': -1,
            'inTransaction': false,
          },
          null,
        ],
        protocolCloseStep,
      ]);
      final factory = scenario.factory;
      try {
        await factory.openDatabase(
          inMemoryDatabasePath,
          options: OpenDatabaseOptions(version: 1, onCreate: (db, version) {}),
        );
      } on DatabaseException catch (_) {}
      scenario.end();
    });
    test('simple rolled back', () async {
      final causingRollbackStep = [
        'execute',
        {'sql': 'SOME ERROR CAUSING ROLLBACK', 'id': 1},
        SqfliteDatabaseException('failure', null, transactionClosed: true),
      ];
      final scenario = startScenario([
        protocolOpenStep,
        transactionBeginStep,
        causingRollbackStep,
        protocolCloseStep,
      ]);
      final factory = scenario.factory;
      final db = await factory.openDatabase(inMemoryDatabasePath);

      await db.transaction((txn) async {
        try {
          await txn.execute('SOME ERROR CAUSING ROLLBACK');
        } catch (_) {
          // Catch
        }
      });

      await db.close();
      scenario.end();
    });
    group('failed commit', () {
      final transactionV2BeginStep = [
        'execute',
        {
          'sql': 'BEGIN IMMEDIATE',
          'id': 1,
          'inTransaction': true,
          'transactionId': null,
        },
        {'transactionId': 1},
      ];
      List commitStep(Object? response) => [
        'execute',
        {'sql': 'COMMIT', 'id': 1, 'transactionId': 1, 'inTransaction': false},
        response,
      ];
      List rollbackStep(Object? response) => [
        'execute',
        {
          'sql': 'ROLLBACK',
          'id': 1,
          'transactionId': 1,
          'inTransaction': false,
        },
        response,
      ];
      final queryStep = [
        'query',
        {'sql': 'SELECT 1', 'id': 1},
        <String, Object?>{},
      ];

      Future<void> expectCommitFailure(Database db) async {
        try {
          await db.transaction((txn) async {});
          fail('should fail');
        } on DatabaseException catch (e) {
          expect(e.toString(), contains('busy'));
        }
      }

      test('rolled back', () async {
        final scenario = startScenario([
          protocolOpenStep,
          transactionV2BeginStep,
          commitStep(SqfliteDatabaseException('busy', null)),
          // Still in the transaction, it is rolled back.
          rollbackStep(null),
          queryStep,
          protocolCloseStep,
        ]);
        final db = await scenario.factory.openDatabase(inMemoryDatabasePath);
        await expectCommitFailure(db);
        await db.rawQuery('SELECT 1');
        await db.close();
        scenario.end();
      });

      test('rollback error ignored', () async {
        final scenario = startScenario([
          protocolOpenStep,
          transactionV2BeginStep,
          commitStep(SqfliteDatabaseException('busy', null)),
          rollbackStep(
            SqfliteDatabaseException('no transaction is active', null),
          ),
          queryStep,
          protocolCloseStep,
        ]);
        final db = await scenario.factory.openDatabase(inMemoryDatabasePath);
        await expectCommitFailure(db);
        await db.rawQuery('SELECT 1');
        await db.close();
        scenario.end();
      });

      test('transaction closed', () async {
        final scenario = startScenario([
          protocolOpenStep,
          transactionV2BeginStep,
          // Already rolled back by SQLite, no ROLLBACK.
          commitStep(
            SqfliteDatabaseException('busy', null, transactionClosed: true),
          ),
          queryStep,
          protocolCloseStep,
        ]);
        final db = await scenario.factory.openDatabase(inMemoryDatabasePath);
        await expectCommitFailure(db);
        await db.rawQuery('SELECT 1');
        await db.close();
        scenario.end();
      });
    });
  });
}
