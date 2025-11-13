import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future main() async {
  // Init ffi loader if needed.
  sqfliteFfiInit();

  var databaseFactory = databaseFactoryFfi;
  var db = await databaseFactory.openDatabase(inMemoryDatabasePath);
  stdout.writeln(
    (await db.rawQuery('SELECT sqlite_version()')).first.values.first,
  );
  await db.close();
}
