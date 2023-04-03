import 'dart:html' as html;

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi_web/src/debug/debug.dart';
import 'package:sqflite_common_ffi_web/src/sqflite_ffi_impl_web.dart'
    show SqfliteFfiHandlerWeb;
import 'package:sqflite_common_ffi_web/src/utils.dart';
import 'package:sqflite_common_ffi_web/src/web/load_sqlite_web.dart'
    show
        SqfliteFfiWebContextExt,
        SqfliteFfiWebWorkerException,
        defaultSharedWorkerUri;
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
      invokeMethod: (String method, [Object? arguments]) async {
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
          if (context == null) {
            await _initLock.synchronized(() async {
              context ??= await sqfliteFfiWebStartSharedWorker(webOptions);
              sqfliteFfiHandler = SqfliteFfiHandlerWeb(context!);
            });
          }

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
    var map = dataToEncodable(methodCall.toDataMap())!;
    var response = await context.sendRawMessage(map);
    if (_debug) {
      print('main_recv: $response');
    }
    return dataFromEncodable(responseToResultOrThrow(response));
  } catch (e, st) {
    if (_debug) {
      print(e);
      print(st);
    }
    if (e is SqfliteFfiWebWorkerException) {
      html.window.console.error('''
An error occurred while initializing the web worker.
This is likely due to a failure to find the worker javascript file at ${context.options.sharedWorkerUri ?? defaultSharedWorkerUri}

Please check the documentation at https://github.com/tekartik/sqflite/tree/master/packages_web/sqflite_common_ffi_web#setup-binaries to setup the needed binaries.
''');
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
