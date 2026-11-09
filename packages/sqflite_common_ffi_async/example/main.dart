// ignore_for_file: avoid_print

import 'package:sqflite_common_ffi/sqflite_ffi.dart' show sqfliteFfiInit;
import 'package:sqflite_common_ffi_async/sqflite_ffi_async.dart';

Future<void> main() async {
  // Init ffi loader if needed.
  sqfliteFfiInit();

  var databaseFactory = databaseFactoryFfiAsync;
  // In databaseFactory.getDatabasesPath(), kept between runs.
  var db = await databaseFactory.openDatabase(
    'example.db',
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        // Only the first time.
        await db.execute('''
  CREATE TABLE Product (
      id INTEGER PRIMARY KEY,
      title TEXT
  )
  ''');
      },
    ),
  );
  await db.insert('Product', <String, Object?>{'title': 'Product 1'});

  // Reads run on a reader connection, concurrently with writes.
  var count = await db.readTransaction((txn) async {
    var rows = await txn.rawQuery('SELECT COUNT(*) AS count FROM Product');
    return rows.first['count'] as int;
  });
  print('$count product(s)'); // one more at each run
  print(await db.query('Product', orderBy: 'id DESC', limit: 1));
  await db.close();
}
