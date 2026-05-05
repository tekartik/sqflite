import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:test/test.dart';

/// Run iterate tests.
void run(SqfliteTestContext context) {
  var factory = context.databaseFactory;
  group('iterate', () {
    late Database db;

    setUpAll(() async {
      db = await factory.openDatabase(inMemoryDatabasePath);
      await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
      await db.insert('Test', {'id': 1, 'name': 'item 1'});
      await db.insert('Test', {'id': 2, 'name': 'item 2'});
      await db.insert('Test', {'id': 3, 'name': 'item 3'});
    });

    tearDownAll(() async {
      await db.close();
    });

    test('rawIterate', () async {
      var count = 0;
      var ids = <int>[];
      await db.rawQueryIterate(
        'SELECT * FROM Test ORDER BY id',
        null,
        onRow: (row) {
          count++;
          ids.add(row['id'] as int);
          return true;
        },
      );
      expect(count, 3);
      expect(ids, [1, 2, 3]);
    });

    test('rawIterate stop early', () async {
      var count = 0;
      await db.rawQueryIterate(
        'SELECT * FROM Test ORDER BY id',
        null,
        onRow: (row) {
          count++;
          return count < 2;
        },
      );
      expect(count, 2);
    });

    test('iterate', () async {
      var count = 0;
      var ids = <int>[];
      await db.queryIterate(
        'Test',
        orderBy: 'id',
        onRow: (row) {
          count++;
          ids.add(row['id'] as int);
          return true;
        },
      );
      expect(count, 3);
      expect(ids, [1, 2, 3]);
    });

    test('iterate stop early', () async {
      var count = 0;
      await db.queryIterate(
        'Test',
        orderBy: 'id',
        onRow: (row) {
          count++;
          return count < 2;
        },
      );
      expect(count, 2);
    });

    test('iterate in transaction', () async {
      await db.readTransaction((txn) async {
        var count = 0;
        await txn.queryIterate(
          'Test',
          orderBy: 'id',
          onRow: (row) {
            count++;
            return true;
          },
        );
        expect(count, 3);
      });
    });
  });
}
