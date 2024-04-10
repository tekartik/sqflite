import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/utils/utils.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'ui.dart';

Future<void> main() async {
  // sqliteFfiWebDebugWebWorker = true;
  // Use the ffi web factory in web apps (flutter or dart) with an overriden file name for testing
  var factory = createDatabaseFactoryFfiWeb(
      options:
          SqfliteFfiWebOptions(sharedWorkerUri: Uri.parse('sqflite_sw_v1.js')));

  // test: custom uri dummy
  // ignore: dead_code
  if (false) {
    // devWarning(true)) {
    factory = createDatabaseFactoryFfiWeb(
        options: SqfliteFfiWebOptions(
            sharedWorkerUri: Uri.parse('sqflite_sw_v2.js')));
  }
  if (true) {
    // devWarning(true)) {
    factory = createDatabaseFactoryFfiWeb(
        options: SqfliteFfiWebOptions(
            // ignore: invalid_use_of_visible_for_testing_member
            forceAsBasicWorker: true,
            sharedWorkerUri: Uri.parse('sqflite_sw_v1.js')));
  }

  var db = await factory.openDatabase(inMemoryDatabasePath);
  var sqliteVersion =
      (await db.rawQuery('select sqlite_version()')).first.values.first;
  write(sqliteVersion.toString());

  await incrementSqfliteValueInDatabaseFactory(factory);
}

Future<void> incrementSqfliteValueInDatabaseFactory(DatabaseFactory factory,
    {String? tag}) async {
  tag ??= 'db';
  try {
    // await factory.debugSetLogLevel(sqfliteLogLevelVerbose);
    var db = await factory.openDatabase('test.db',
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute(
                  'CREATE TABLE Test(id INTEGER PRIMARY KEY, value INTEGER)');
            }));
    Future<int?> readValue() async {
      var value = firstIntValue(
              await db.query('Test', columns: ['value'], where: 'id = 1')) ??
          0;

      return value;
    }

    var value = await readValue();
    write('/$tag read before $value');
    await db.insert('Test', {'id': 1, 'value': (value ?? 0) + 1},
        conflictAlgorithm: ConflictAlgorithm.replace);
    value = await readValue() ?? 0;
    write('/$tag read after $value');
  } catch (e) {
    write('/$tag error: $e');
    write(
        'Try running `dart run sqflite_common_ffi_web:setup` on the commnad line');
    rethrow;
  }
}
