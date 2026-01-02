import 'dart:convert';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/utils/utils.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi_web_test/src/import.dart';
import 'package:sqflite_common_ffi_web_test/src/ui.dart';

Future<void> main() async {
  // sqliteFfiWebDebugWebWorker = true;
  // Use the ffi web factory in web apps (flutter or dart) with an overriden file name for testing
  var factory = createDatabaseFactoryFfiWeb(
    options: SqfliteFfiWebOptions(
      sharedWorkerUri: Uri.parse('sqflite_sw_example_web1.js'),
      indexedDbName: 'sqflite_databases_example_web1',
      sqlite3WasmUri: Uri.parse('sqlite3_example_web1.wasm'),
    ),
  );

  var options = await factory.getWebOptions();
  write('Web options:');
  write(const JsonEncoder.withIndent('  ').convert(options.toMap()));
  var db = await factory.openDatabase(inMemoryDatabasePath);
  var sqliteVersion = (await db.rawQuery(
    'select sqlite_version()',
  )).first.values.first;
  write('SQLite version:');
  write(sqliteVersion.toString());

  await incrementSqfliteValueInDatabaseFactory(factory);
}

Future<void> incrementSqfliteValueInDatabaseFactory(
  DatabaseFactory factory, {
  String? tag,
}) async {
  tag ??= 'db';
  try {
    // await factory.debugSetLogLevel(sqfliteLogLevelVerbose);
    var db = await factory.openDatabase(
      'test.db',
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE Test(id INTEGER PRIMARY KEY, value INTEGER)',
          );
        },
      ),
    );
    Future<int?> readValue() async {
      var value =
          firstIntValue(
            await db.query('Test', columns: ['value'], where: 'id = 1'),
          ) ??
          0;

      return value;
    }

    var value = await readValue();
    write('/$tag read before $value');
    await db.insert('Test', {
      'id': 1,
      'value': (value ?? 0) + 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    value = await readValue() ?? 0;
    write('/$tag read after $value');
  } catch (e) {
    write('/$tag error: $e');
    write(
      'Try running `dart run sqflite_common_ffi_web:setup` on the commnad line',
    );
    rethrow;
  }
}
