import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:test/test.dart';

/// Run sql command tests.
void run(SqfliteTestContext context) {
  var factory = context.databaseFactory;
  group('sql_command', () {
    late Database db;

    setUpAll(() async {
      db = await factory.openDatabase(inMemoryDatabasePath);
      await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
    });

    tearDownAll(() async {
      await db.close();
    });

    test('execute', () async {
      final command = SqfliteSqlCommand.execute('DROP TABLE IF EXISTS Test2');
      await command.execute(db);
      final command2 = SqfliteSqlCommand.execute(
        'CREATE TABLE Test2 (id INTEGER PRIMARY KEY, name TEXT)',
      );
      await command2.execute(db);
    });

    test('insert', () async {
      final command = SqfliteSqlCommand.insert('Test', {
        'id': 1,
        'name': 'item 1',
      });
      final id = await command.insert(db);
      expect(id, 1);

      final rawCommand = SqfliteSqlCommand.rawInsert(
        'INSERT INTO Test (id, name) VALUES (?, ?)',
        [2, 'item 2'],
      );
      final id2 = await rawCommand.insert(db);
      expect(id2, 2);
    });

    test('query', () async {
      final command = SqfliteSqlCommand.query('Test', orderBy: 'id');
      final rows = await command.query(db);
      expect(rows.length, 2);
      expect(rows[0]['id'], 1);
      expect(rows[1]['id'], 2);

      final rawCommand = SqfliteSqlCommand.rawQuery(
        'SELECT * FROM Test WHERE id = ?',
        [1],
      );
      final rows2 = await rawCommand.query(db);
      expect(rows2.length, 1);
      expect(rows2[0]['name'], 'item 1');
    });

    test('iterate', () async {
      final command = SqfliteSqlCommand.query('Test', orderBy: 'id');
      var count = 0;
      await command.iterate(
        db,
        onRow: (row) {
          count++;
          return true;
        },
      );
      expect(count, 2);

      count = 0;
      await command.queryIterate(
        db,
        onRow: (row) {
          count++;
          return count < 1;
        },
      );
      expect(count, 1);
    });

    test('update', () async {
      final command = SqfliteSqlCommand.update(
        'Test',
        {'name': 'item 1 updated'},
        where: 'id = ?',
        whereArgs: [1],
      );
      final count = await command.update(db);
      expect(count, 1);

      final rawCommand = SqfliteSqlCommand.rawUpdate(
        'UPDATE Test SET name = ? WHERE id = ?',
        ['item 2 updated', 2],
      );
      final count2 = await rawCommand.update(db);
      expect(count2, 1);
    });

    test('delete', () async {
      final command = SqfliteSqlCommand.delete(
        'Test',
        where: 'id = ?',
        whereArgs: [1],
      );
      final count = await command.delete(db);
      expect(count, 1);

      final rawCommand = SqfliteSqlCommand.rawDelete(
        'DELETE FROM Test WHERE id = ?',
        [2],
      );
      final count2 = await rawCommand.delete(db);
      expect(count2, 1);

      final rows = await db.query('Test');
      expect(rows.length, 0);
    });
  });
}
