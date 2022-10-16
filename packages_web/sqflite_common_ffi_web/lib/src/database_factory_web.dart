import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi_web/src/debug/debug.dart';
import 'package:sqflite_common_ffi_web/src/sqflite_ffi_impl_web.dart'
    show SqfliteFfiHandlerWeb, sendRawMessage;
import 'package:sqflite_common_ffi_web/src/utils.dart';
import 'package:sqflite_common_ffi_web/src/web/load_sqlite_web.dart'
    show SqfliteFfiWebContextExt;
import 'package:synchronized/synchronized.dart';

import 'import.dart';

/// The Ffi database factory.
var databaseFactoryFfiWebNoWebWorkerImpl = () {
  return createDatabaseFactoryFfiWeb(noWebWorker: true);
}();

/// The Ffi database factory.
var databaseFactoryFfiWebImpl = () {
  return createDatabaseFactoryFfiWeb();
}();

final _initLock = Lock();

/// Creates an FFI database factory
DatabaseFactory createDatabaseFactoryFfiWeb(
    {SqfliteFfiWebOptions? options, bool noWebWorker = false, String? tag}) {
  var webOptions = options ??= SqfliteFfiWebOptions();
  SqfliteFfiWebContext? context;
  return buildDatabaseFactory(
      tag: tag ?? 'ffi_web',
      invokeMethod: (String method, [dynamic arguments]) async {
        final methodCall = FfiMethodCall(method, arguments);
        if (noWebWorker) {
          if (context == null) {
            await _initLock.synchronized(() async {
              context ??= await sqfliteFfiWebLoadSqlite3Wasm(webOptions);
              sqfliteFfiHandler = SqfliteFfiHandlerWeb(context!);
            });
          }
          return ffiMethodCallHandleNoWebWorker(methodCall, context!);
        } else {
          await _initLock.synchronized(() async {
            context ??= await sqfliteFfiWebStartWebWorker(webOptions);
            sqfliteFfiHandler = SqfliteFfiHandlerWeb(context!);
          });

          return ffiMethodCallSendToWebWorker(methodCall, context!);
        }
      });
}

// Debug database factory web
bool get _debug => sqliteFfiWebDebugWebWorker;

/// Handle method call not to call the web worker.
Future<dynamic> ffiMethodCallSendToWebWorker(
    FfiMethodCall methodCall, SqfliteFfiWebContext context) async {
  try {
    if (_debug) {
      print('main_send: $methodCall');
    }
    var sw = context.serviceWorker!;
    //var result = context.serviceWorker{'TODO': 1}; // TODO await _isolateHandle();
    Object? response; // = {'TODO': 1}; // TODO await _isolateHandle();
    var map = dataToEncodable(methodCall.toDataMap())!;
    response = await sendRawMessage(sw, map);
    if (_debug) {
      print('main_recv: $response');
    }
    return dataFromEncodable(responseToResultOrThrow(response));
  } catch (e, st) {
    if (_debug) {
      print(e);
      print(st);
    }
    rethrow;
  }
}

/// Handle a method call
Future<dynamic> ffiMethodCallHandleNoWebWorker(
    FfiMethodCall methodCall, SqfliteFfiWebContext context) async {
  try {
    if (_debug) {
      print('handle $methodCall');
    }
    dynamic result = await methodCall.rawHandle();

    if (_debug) {
      print('result: $result');
    }

    // devPrint('result: $result');
    return result;
  } catch (e, st) {
    if (_debug) {
      print(e);
      print(st);
    }
    throw methodCall.wrapAnyExceptionNoIsolate(e);
  }
}
