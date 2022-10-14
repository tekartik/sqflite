import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util';

import 'package:service_worker/window.dart' as sw;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi_web/src/web/load_sqlite_web.dart'
    show SqfliteFfiWebContextExt;
import 'package:sqflite_common_ffi_web_support/src/constants.dart';

import 'ui.dart';

var swOptions = SqfliteFfiWebOptions(serviceWorkerUri: Uri.parse('sw.dart.js'));

Future<void> main() async {
  initUi();
  write('running');
  // await incrementVarInServiceWorker();
}

var _registerAndReady = sqfliteFfiWebStartWebWorker(swOptions);
Future<sw.ServiceWorker> registerAndReady() async =>
    (await _registerAndReady).serviceWorker!;

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
    print('Receiving from sw:  ${event.data}');
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
  write('read before $value');
  if (value is! int) {
    value = 0;
  }

  await setTestValue(sw, value + 1);
  value = await getTestValue(sw);
  write('read after $value');
}

void initUi() {
  addButton('load sqlite', () async {});
  addButton('increment var in service worker', () async {
    await incrementVarInServiceWorker();
  });
}
