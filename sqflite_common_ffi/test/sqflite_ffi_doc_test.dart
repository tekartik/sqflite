@TestOn('vm')
library;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  // Init ffi loader if needed.
  sqfliteFfiInit();
  test('Simple test', () async {
    var factory = databaseFactoryFfi;
    var db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)',
          );
        },
      ),
    );
    // Insert some data
    await db.insert('Test', {'value': 'my_value'});

    // Check content
    expect(await db.query('Test'), [
      {'id': 1, 'value': 'my_value'},
    ]);

    await db.close();
  });
  test('MyUnitTest', () async {
    var factory = databaseFactoryFfi;
    var db = await factory.openDatabase(inMemoryDatabasePath);

    // Should fail table does not exists
    try {
      await db.query('Test');
    } on DatabaseException catch (e) {
      // no such table: Test
      expect(e.isNoSuchTableError('Test'), isTrue);
      // ignore: avoid_print
      print(e.toString());
    }

    // Ok
    await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY)');
    await db.execute('ALTER TABLE Test ADD COLUMN name TEXT');
    // should succeed, but empty
    expect(await db.query('Test'), isEmpty);

    await db.close();
  });
  test('simple sqflite example', () async {
    var db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    expect(await db.getVersion(), 0);
    await db.close();
  });
  for (var noIsolate in [false, true]) {
    test('handle a constraint error (noIsolate: $noIsolate)', () async {
      var factory = noIsolate
          ? databaseFactoryFfiNoIsolate
          : databaseFactoryFfi;
      var db = await factory.openDatabase(inMemoryDatabasePath);
      try {
        await db.execute(
          'CREATE TABLE Product (id INTEGER PRIMARY KEY, title TEXT NOT NULL)',
        );
        await db.insert('Product', {'id': 1, 'title': 'Product 1'});
        try {
          await db.insert('Product', {'id': 1, 'title': 'Another product'});
          fail('The duplicate primary key should fail');
        } on DatabaseException catch (e) {
          expect(e.isUniqueConstraintError(), isTrue);
          expect(e.getResultCode(), 1555); // SQLITE_CONSTRAINT_PRIMARYKEY
        }
        expect(await db.query('Product'), [
          {'id': 1, 'title': 'Product 1'},
        ]);
      } finally {
        await db.close();
      }
    });
  }
}
