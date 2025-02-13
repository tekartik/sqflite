import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/utils/utils.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi_web/src/sw/constants.dart';
import 'package:sqflite_common_ffi_web/src/web/load_sqlite_web.dart'
    show SqfliteFfiWebContextExt;
import 'package:web/web.dart' as web;

import 'ui.dart';

/// quick test open for basic web worker (as we cannot have both shared and simple worker)
var _useBasicWebWorker = false; // devWarning(true);

var _debugVersion = 1;
var _shc = '/_shc$_debugVersion';

var swOptions = SqfliteFfiWebOptions(
  sharedWorkerUri: Uri.parse('sw.dart.js'),
  // ignore: invalid_use_of_visible_for_testing_member
  forceAsBasicWorker: _useBasicWebWorker,
);
var swBasicOptions = SqfliteFfiWebOptions(
  sharedWorkerUri: Uri.parse('sw.dart.js'),
  // ignore: invalid_use_of_visible_for_testing_member
  forceAsBasicWorker: true,
);
Future incrementPrebuilt() async {
  await incrementSqfliteValueInDatabaseFactory(
    databaseFactoryWebPrebuilt,
    tag: 'prebuilt',
  );
}

Future incrementWork() async {
  await incrementSqfliteValueInDatabaseFactory(
    databaseFactoryWebLocal,
    tag: 'work',
  );
}

Future exceptionWork() async {
  try {
    var factory = databaseFactoryWebLocal;
    var db = await factory.openDatabase('test_missing');
    await db.query('Test');
  } catch (e) {
    write('exception $e');
  }
}

class _Data {
  late Database db;
}

/// Out internal data.
// ignore: library_private_types_in_public_api
final _Data data = _Data();

/// Get the value field from a given id
Future<dynamic> getValue(int id) async {
  return ((await data.db.query('Test', where: 'id = $id')).first)['value'];
}

/// insert the value field and return the id
Future<int> insertValue(dynamic value) async {
  return await data.db.insert('Test', {'value': value});
}

/// insert the value field and return the id
Future<int> updateValue(int id, dynamic value) async {
  return await data.db.update('Test', {'value': value}, where: 'id = $id');
}

Future bigInt() async {
  try {
    var factory = databaseFactoryWebLocal;
    var db = data.db = await factory.openDatabase('test_big_int');
    await db.execute(
      'CREATE TABLE IF NOT EXISTS Test (id INTEGER PRIMARY KEY AUTOINCREMENT, value INTEGER)',
    );
    await db.query('Test');
  } catch (e) {
    write('exception $e');
  }
  var id = await insertValue(-1);
  assert(await getValue(id) == -1);

  // less than 32 bits
  id = await insertValue(pow(2, 31));
  assert(await getValue(id) == pow(2, 31));

  // more than 32 bits
  id = await insertValue(pow(2, 33));
  //devPrint('2^33: ${await getValue(id)}');
  assert(await getValue(id) == pow(2, 33));

  id = await insertValue(pow(2, 62));
  //devPrint('2^62: ${pow(2, 62)} ${await getValue(id)}');
  assert(await getValue(id) == pow(2, 62));
  /*
  var value = pow(2, 63).round() - 1;
  id = await insertValue(value);
  //devPrint('${value} ${await getValue(id)}');
  expect(await getValue(id), value, reason: '$value ${await getValue(id)}');

  value = -(pow(2, 63)).round();
  id = await insertValue(value);
  //devPrint('${value} ${await getValue(id)}');
  expect(await getValue(id), value, reason: '$value ${await getValue(id)}');
  */
}

Future incrementNoWebWorker() async {
  await incrementSqfliteValueInDatabaseFactory(
    databaseFactoryWebNoWebWorkerLocal,
    tag: 'ui',
  );
}

Future<void> main() async {
  // sqliteFfiWebDebugWebWorker = true;
  initUi();

  write('$_shc running $_debugVersion');
  // devWarning(incrementVarInSharedWorker());
  // await devWarning(bigInt());
  // await devWarning(exceptionWork());
  // await devWarning(incrementWork());
  // await devWarning(incrementPrebuilt());
  // await incrementVarInServiceWorker();
  // await incrementSqfliteValueInDatabaseFactory(
  // databaseFactoryWebNoWebWorkerLocal);
  // await incrementSqfliteValueInDatabaseFactory(databaseFactoryWebLocal);
  // await devWarning(
  //  incrementSqfliteValueInDatabaseFactory(databaseFactoryWebPrebuilt));
}

var _webContextRegisterAndReady = sqfliteFfiWebStartSharedWorker(swOptions);

var _webBasicContextRegisterAndReady = sqfliteFfiWebStartSharedWorker(
  swBasicOptions,
);

Future<web.SharedWorker> sharedWorkerRegisterAndReady() async =>
    (await _webContextRegisterAndReady).sharedWorker!;

Future<SqfliteFfiWebContext> webContextRegisterAndReady() async =>
    (await _webContextRegisterAndReady);

Future<SqfliteFfiWebContext> webBasicContextRegisterAndReady() async =>
    (await _webBasicContextRegisterAndReady);
var databaseFactoryWebPrebuilt = databaseFactoryFfiWeb;
var databaseFactoryWebNoWebWorkerLocal = databaseFactoryFfiWebNoWebWorker;
var databaseFactoryWebLocal = createDatabaseFactoryFfiWeb(options: swOptions);
var databaseFactoryWebBasicWorkerLocal = createDatabaseFactoryFfiWeb(
  options: swBasicOptions,
);

var key = 'testValue';

Future<Object?> getTestValue(SqfliteFfiWebContext context) async {
  var response =
      await context.sendRawMessage([
            commandVarGet,
            {'key': key},
          ])
          as Map;
  return (response['result'] as Map)['value'] as Object?;
}

Future<void> setTestValue(SqfliteFfiWebContext context, Object? value) async {
  await context.sendRawMessage([
    commandVarSet,
    {'key': key, 'value': value},
  ]);
}

Future<void> incrementVarInSharedWorker() async {
  var context = await webContextRegisterAndReady();
  write('shared worker ready');
  var value = await getTestValue(context);
  write('var before $value');
  if (value is! int) {
    value = 0;
  }

  await setTestValue(context, value + 1);
  value = await getTestValue(context);
  write('var after $value');
}

Future<void> incrementVarInBasicWorker() async {
  var context = await webBasicContextRegisterAndReady();
  write('basic worker ready');
  var value = await getTestValue(context);
  write('var before $value');
  if (value is! int) {
    value = 0;
  }

  await setTestValue(context, value + 1);
  value = await getTestValue(context);
  write('var after $value');
}

Future<void> incrementSqfliteValueInDatabaseFactory(
  DatabaseFactory factory, {
  String? tag,
}) async {
  tag ??= 'db';
  try {
    write('/$tag accessing db...');
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
    rethrow;
  }
}

Future<void> readWiteDatabase(DatabaseFactory factory, int size) async {
  try {
    var path = 'read_write.db';
    var bytes = Uint8List.fromList(List.generate(size, (index) => index % 256));
    await factory.writeDatabaseBytes(path, bytes);
    var readBytes = await factory.readDatabaseBytes(path);
    write('wrote ${bytes.length}, read ${readBytes.length}');
  } catch (e) {
    write('Exception $e');
  }
}

void initUi() {
  addButton('load sqlite', () async {});
  addButton('increment var in shared worker', () async {
    await incrementVarInSharedWorker();
  });
  addButton('increment var in basic worker', () async {
    await incrementVarInBasicWorker();
  });
  addButton('increment sqflite value in main thread', () async {
    await incrementNoWebWorker();
  });
  addButton('increment sqflite value in web worker', () async {
    await incrementWork();
  });
  addButton('exception in web worker', () async {
    await exceptionWork();
  });
  addButton('increment sqflite value in pre-built web worker', () async {
    await incrementPrebuilt();
  });
  addButton('read write file', () async {
    for (var factory in [
      databaseFactoryWebNoWebWorkerLocal,
      databaseFactoryWebPrebuilt,
      databaseFactoryWebLocal,
    ]) {
      write('factory: $factory');
      await readWiteDatabase(factory, 3);
      await readWiteDatabase(factory, 1024 * 1024);
    }
  });
}
