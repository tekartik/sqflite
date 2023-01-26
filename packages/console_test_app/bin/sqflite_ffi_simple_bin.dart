import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main(List<String> arguments) async {
  sqfliteFfiInit();
  var db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  await db.setVersion(1);
  await db.close();
}
