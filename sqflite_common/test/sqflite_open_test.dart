import 'package:sqflite_common/sqlite_api.dart';
import 'package:test/test.dart';

import 'test_scenario.dart';

void main() {
  group('sqflite', () {
    test('open', () async {
      final scenario = startScenario([
        [
          'openDatabase',
          {'path': ':memory:', 'singleInstance': true},
          1
        ],
        [
          'closeDatabase',
          {'id': 1},
          null
        ],
      ]);
      final factory = scenario.factory;
      final db = await factory.openDatabase(inMemoryDatabasePath);
      await db.close();
      scenario.end();
    });
    test('open with version', () async {
      final scenario = startScenario([
        [
          'openDatabase',
          {'path': ':memory:', 'singleInstance': true},
          1
        ],
        [
          'query',
          {'sql': 'PRAGMA user_version', 'arguments': null, 'id': 1},
          {}
        ],
        [
          'execute',
          {
            'sql': 'BEGIN EXCLUSIVE',
            'arguments': null,
            'id': 1,
            'inTransaction': true
          },
          null
        ],
        [
          'query',
          {'sql': 'PRAGMA user_version', 'arguments': null, 'id': 1},
          {}
        ],
        [
          'execute',
          {'sql': 'PRAGMA user_version = 1', 'arguments': null, 'id': 1},
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
      final db = await scenario.factory.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(version: 1, onCreate: (db, version) {}));
      await db.close();
      scenario.end();
    });
  });
}
