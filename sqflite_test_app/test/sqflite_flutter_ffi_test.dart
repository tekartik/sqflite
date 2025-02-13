import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future main() async {
  // Setup sqflite_common_ffi for flutter test
  setUpAll(() {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory
    databaseFactory = databaseFactoryFfi;
  });
  test('Simple test', () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)',
        );
      },
    );
    // Insert some data
    await db.insert('Test', {'value': 'my_value'});
    // Check content
    expect(await db.query('Test'), [
      {'id': 1, 'value': 'my_value'},
    ]);

    await db.close();
  });
}
