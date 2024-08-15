// ignore_for_file: avoid_print

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_async/sqflite_ffi_async.dart';

Future main() async {
  // Init ffi loader if needed.
  sqfliteFfiInit();

  var databaseFactory = databaseFactoryFfiAsync;
  var db = await databaseFactory.openDatabase('example.db');
  await db.execute('''
  CREATE TABLE Product (
      id INTEGER PRIMARY KEY,
      title TEXT
  )
  ''');
  await db.insert('Product', <String, Object?>{'title': 'Product 1'});
  await db.insert('Product', <String, Object?>{'title': 'Product 1'});

  var result = await db.query('Product');
  print(result);
  // prints [{id: 1, title: Product 1}, {id: 2, title: Product 1}]
  await db.close();
}
