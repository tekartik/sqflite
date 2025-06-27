import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main(List<String> arguments) async {
  sqfliteFfiInit();
  var db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  var sqliteVersion = (await db.rawQuery(
    'select sqlite_version()',
  )).first.values.first;
  print('sqlite version: $sqliteVersion');
  await db.setVersion(1);
  await db.close();
}
