import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util';
import 'dart:math';

import 'package:service_worker/window.dart' as sw;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/utils/utils.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi_web/src/sw/constants.dart';
import 'package:sqflite_common_ffi_web/src/web/load_sqlite_web.dart'
    show SqfliteFfiWebContextExt;

import 'ui.dart';

var swOptions = SqfliteFfiWebOptions(serviceWorkerUri: Uri.parse('sw.dart.js'));

Future incrementPrebuilt() async {
  await incrementSqfliteValueInDatabaseFactory(databaseFactoryWebPrebuilt,
      tag: 'prebuilt');
}

Future incrementWork() async {
  await incrementSqfliteValueInDatabaseFactory(databaseFactoryWebLocal,
      tag: 'work');
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
        'CREATE TABLE IF NOT EXISTS Test (id INTEGER PRIMARY KEY AUTOINCREMENT, value INTEGER)');
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
      tag: 'ui');
}

Future<void> main() async {
  initUi();
  // sqliteFfiWebDebugWebWorker = devWarning(true);
  write('running');
  // await devWarning(bigInt());
  //await devWarning(exceptionWork());
  // await devWarning(incrementWork());
  //await devWarning(incrementPrebuilt());
  // await incrementVarInServiceWorker();
  // await incrementSqfliteValueInDatabaseFactory(
  //     databaseFactoryWebNoWebWorkerLocal);
  // await incrementSqfliteValueInDatabaseFactory(databaseFactoryWebLocal);
  //await devWarning(
  //  incrementSqfliteValueInDatabaseFactory(databaseFactoryWebPrebuilt));
}

var _registerAndReady = sqfliteFfiWebStartWebWorker(swOptions);

Future<sw.ServiceWorker> registerAndReady() async =>
    (await _registerAndReady).serviceWorker!;

var databaseFactoryWebPrebuilt = databaseFactoryFfiWeb;
var databaseFactoryWebNoWebWorkerLocal = databaseFactoryFfiWebNoWebWorker;
var databaseFactoryWebLocal = createDatabaseFactoryFfiWeb(options: swOptions);

/// Returns response
Future<Object?> sendRawMessage(sw.ServiceWorker sw, Object message) {
  var completer = Completer<Object?>();
  // This wraps the message posting/response in a promise, which will resolve if the response doesn't
  // contain an error, and reject with the error if it does. If you'd prefer, it's possible to call
  // controller.postMessage() and set up the onmessage handler independently of a promise, but this is
  // a convenient wrapper.
  var messageChannel = html.MessageChannel();
  //var receivePort =ReceivePort();

  messageChannel.port1.onMessage.listen((event) {
    // print('Receiving from sw:  ${event.data}');
    completer.complete(event.data);
  });

  // This sends the message data as well as transferring messageChannel.port2 to the service worker.
  // The service worker can then use the transferred port to reply via postMessage(), which
  // will in turn trigger the onmessage handler on messageChannel.port1.
  // See https://html.spec.whatwg.org/multipage/workers.html#dom-worker-postmessage
  sw.postMessage(jsify(message), (jsify([messageChannel.port2]) as List));
  return completer.future;
}

var key = 'testValue';

Future<Object?> getTestValue(sw.ServiceWorker sw) async {
  var response = await sendRawMessage(sw, [
    commandVarGet,
    {'key': key}
  ]) as Map;
  return (response['result'] as Map)['value'] as Object?;
}

Future<void> setTestValue(sw.ServiceWorker sw, Object? value) async {
  await sendRawMessage(sw, [
    commandVarSet,
    {'key': key, 'value': value}
  ]);
}

Future<void> incrementVarInServiceWorker() async {
  var sw = await registerAndReady();
  var value = await getTestValue(sw);
  write('var before $value');
  if (value is! int) {
    value = 0;
  }

  await setTestValue(sw, value + 1);
  value = await getTestValue(sw);
  write('var after $value');
}

Future<void> incrementSqfliteValueInDatabaseFactory(DatabaseFactory factory,
    {String? tag}) async {
  tag ??= 'db';
  try {
    write('/$tag accessing db...');
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
    rethrow;
  }
}

void initUi() {
  addButton('load sqlite', () async {});
  addButton('increment var in service worker', () async {
    await incrementVarInServiceWorker();
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
}
