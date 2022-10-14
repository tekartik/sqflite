import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi_web/src/sqflite_ffi_impl_web.dart';
import 'package:synchronized/synchronized.dart';

import 'import.dart';

/// The Ffi database factory.
var databaseFactoryFfiWebNoWebWorkerImpl = () {
  sqfliteFfiHandler = SqfliteFfiHandlerWeb();
  return createDatabaseFactoryFfiWeb(noWebWorker: true);
}();

/// The Ffi database factory.
var databaseFactoryFfiWebImpl = () {
  sqfliteFfiHandler = SqfliteFfiHandlerWeb();
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
            });
          }
          return ffiMethodCallHandleNoWebWorker(methodCall, context!);
        } else {
          await _initLock.synchronized(() async {
            context ??= await sqfliteFfiWebStartWebWorker(webOptions);
          });

          return ffiMethodCallHandleInWebWorker(methodCall, context!);
        }
      });
}

bool _debug = false; // devWarning(true);

/// Handle method call not in a web worker.
Future<dynamic> ffiMethodCallHandleInWebWorker(
    FfiMethodCall methodCall, SqfliteFfiWebContext context) async {
  try {
    if (_debug) {
      print('main_send: $methodCall');
    }
    var result = {'TODO': 1}; // TODO await _isolateHandle();
    if (_debug) {
      print('main_recv: $result');
    }
    return result;
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
