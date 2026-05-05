import 'package:sqflite_common/sqlite_api.dart';

import 'package:test/test.dart';

void main() {
  group('SqfliteSqlCommand', () {
    test('raw factories', () {
      var command = SqfliteSqlCommand.rawQuery('SELECT * FROM Test', [1]);
      expect(command.type, SqliteSqlCommandType.query);
      expect(command.sql, 'SELECT * FROM Test');
      expect(command.arguments, [1]);

      command = SqfliteSqlCommand.rawInsert(
        'INSERT INTO Test (name) VALUES (?)',
        ['item'],
      );
      expect(command.type, SqliteSqlCommandType.insert);
      expect(command.sql, 'INSERT INTO Test (name) VALUES (?)');
      expect(command.arguments, ['item']);

      command = SqfliteSqlCommand.rawUpdate('UPDATE Test SET name = ?', [
        'new',
      ]);
      expect(command.type, SqliteSqlCommandType.update);
      expect(command.sql, 'UPDATE Test SET name = ?');
      expect(command.arguments, ['new']);

      command = SqfliteSqlCommand.rawDelete('DELETE FROM Test');
      expect(command.type, SqliteSqlCommandType.delete);
      expect(command.sql, 'DELETE FROM Test');
      expect(command.arguments, isNull);

      command = SqfliteSqlCommand.execute('PRAGMA user_version = 1');
      expect(command.type, SqliteSqlCommandType.execute);
      expect(command.sql, 'PRAGMA user_version = 1');
    });

    test('builder factories', () {
      var command = SqfliteSqlCommand.query(
        'Test',
        where: 'id = ?',
        whereArgs: [1],
      );
      expect(command.type, SqliteSqlCommandType.query);
      expect(command.sql, 'SELECT * FROM Test WHERE id = ?');
      expect(command.arguments, [1]);

      command = SqfliteSqlCommand.insert('Test', {'name': 'item'});
      expect(command.type, SqliteSqlCommandType.insert);
      expect(command.sql, 'INSERT INTO Test (name) VALUES (?)');
      expect(command.arguments, ['item']);

      command = SqfliteSqlCommand.update(
        'Test',
        {'name': 'new'},
        where: 'id = ?',
        whereArgs: [1],
      );
      expect(command.type, SqliteSqlCommandType.update);
      expect(command.sql, 'UPDATE Test SET name = ? WHERE id = ?');
      expect(command.arguments, ['new', 1]);

      command = SqfliteSqlCommand.delete(
        'Test',
        where: 'id = ?',
        whereArgs: [1],
      );
      expect(command.type, SqliteSqlCommandType.delete);
      expect(command.sql, 'DELETE FROM Test WHERE id = ?');
      expect(command.arguments, [1]);
    });
  });
}
