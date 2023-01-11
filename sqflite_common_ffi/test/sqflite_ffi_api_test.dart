@TestOn('vm')
library sqflite_common_ffi.test.sqflite_ffi_doc_test;

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  // Init ffi loader if needed.
  sqfliteFfiInit();
  test('MyUnitTest', () async {
    var factory = databaseFactoryFfi;
    var db = await factory.openDatabase(inMemoryDatabasePath);

    // Should fail table does not exists
    try {
      await db.query('Test');
    } on DatabaseException catch (e) {
      // no such table: Test
      expect(e.isNoSuchTableError('Test'), isTrue);
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
}
