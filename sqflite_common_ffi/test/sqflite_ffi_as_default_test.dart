@TestOn('vm')
library;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  // Init ffi loader if needed.
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  test('basic', () async {
    var db = await openDatabase(
      inMemoryDatabasePath,
      onCreate: (db, version) {
        return db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY)');
      },
      version: 1,
    );
    expect(await db.getVersion(), 1);
    await db.close();
  });
}
