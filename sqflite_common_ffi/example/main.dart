// ignore_for_file: avoid_print

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future main() async {
  // Init ffi (Windows specific setup, no-op on other platforms).
  sqfliteFfiInit();

  var factory = databaseFactoryFfi;
  // In memory database, see persistent_example.dart for a database file.
  var db = await factory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
  CREATE TABLE Product (
      id INTEGER PRIMARY KEY,
      title TEXT NOT NULL
  )
  ''');
      },
    ),
  );
  // Insert
  var id = await db.insert('Product', <String, Object?>{'title': 'Product 1'});
  await db.insert('Product', <String, Object?>{'title': 'Product 2'});

  // Update
  await db.update(
    'Product',
    {'title': 'Product 1 updated'},
    where: 'id = ?',
    whereArgs: [id],
  );

  // Query
  var result = await db.query('Product', orderBy: 'id');
  print(result);
  // prints [{id: 1, title: Product 1 updated}, {id: 2, title: Product 2}]

  // Delete
  await db.delete('Product', where: 'id = ?', whereArgs: [id]);
  print(await db.query('Product'));
  // prints [{id: 2, title: Product 2}]

  await db.close();
}
