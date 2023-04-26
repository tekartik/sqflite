import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future main() async {
  // Init ffi loader if needed.
  sqfliteFfiInit();

  var databaseFactory = databaseFactoryFfi;
  // Pick a path on your file system
  var path = normalize(absolute(join('.dart_tool', 'sqflite_common_ffi',
      'databases', 'sqflite_ffi_example.db')));
  // Create parent directory
  await Directory(dirname(path)).create(recursive: true);
  var db = await databaseFactory.openDatabase(path,
      options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
    CREATE TABLE Product (
        id INTEGER PRIMARY KEY,
        title TEXT
    )
    ''');
          }));

  // Each time you run the example, a new record is added with a different timestamp.
  await db.insert(
      'Product', <String, Object?>{'title': 'Product ${DateTime.now()}'});

  var result = await db.query('Product');

  for (var row in result) {
    print(row);
  }
  await db.close();
}
