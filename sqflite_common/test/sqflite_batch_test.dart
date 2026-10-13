import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/value_utils.dart';
import 'package:test/test.dart';

import 'test_scenario.dart';

void main() {
  group('sqflite', () {
    var startCommands = [protocolOpenStep];
    var endCommands = [protocolCloseStep];
    test('raw arguments check', () async {
      final scenario = startScenario([...startCommands, ...endCommands]);
      final db = await scenario.factory.openDatabase(inMemoryDatabasePath);
      // Debug check, like rawQuery, rawUpdate and rawDelete.
      checkThrowException = true;
      try {
        expect(() => db.rawInsert('_', [true]), throwsArgumentError);
        var batch = db.batch();
        expect(() => batch.rawInsert('_', [true]), throwsArgumentError);
        expect(() => batch.rawQuery('_', [true]), throwsArgumentError);
        expect(() => batch.rawUpdate('_', [true]), throwsArgumentError);
        expect(() => batch.rawDelete('_', [true]), throwsArgumentError);
        expect(batch.length, 0);
      } finally {
        checkThrowException = false;
      }
      await db.close();
      scenario.end();
    });
    test('batch commit', () async {
      final scenario = startScenario([
        ...startCommands,
        [
          'execute',
          {
            'sql': 'BEGIN IMMEDIATE',
            'id': 1,
            'inTransaction': true,
            'transactionId': null,
          },
          null,
        ],
        [
          'batch',
          {
            'operations': [
              {'method': 'execute', 'sql': 'PRAGMA dummy'},
            ],
            'id': 1,
          },
          null,
        ],
        [
          'execute',
          {'sql': 'COMMIT', 'id': 1, 'inTransaction': false},
          null,
        ],
        ...endCommands,
      ]);
      final factory = scenario.factory;
      final db = await factory.openDatabase(inMemoryDatabasePath);
      var batch = db.batch();
      expect(batch.length, 0);
      batch.execute('PRAGMA dummy');
      expect(batch.length, 1);
      expect(await batch.commit(), isEmpty); // Mock return values
      await db.close();
      scenario.end();
    });
    test('batch apply', () async {
      final scenario = startScenario([
        ...startCommands,
        [
          'batch',
          {
            'operations': [
              {'method': 'execute', 'sql': 'PRAGMA dummy'},
            ],
            'id': 1,
          },
          null,
        ],
        ...endCommands,
      ]);
      final factory = scenario.factory;
      final db = await factory.openDatabase(inMemoryDatabasePath);
      var batch = db.batch();
      batch.execute('PRAGMA dummy');
      await batch.apply();
      await db.close();
      scenario.end();
    });
  });
}
