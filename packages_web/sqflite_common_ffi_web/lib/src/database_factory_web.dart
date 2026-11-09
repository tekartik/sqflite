import 'dart:js_interop';

import 'package:sqflite_common/sqlite_api.dart';
// ignore: implementation_imports
import 'package:sqflite_common/src/constant.dart' show methodOpenDatabase;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi_web/src/open_options_check.dart';
import 'package:sqflite_common_ffi_web/src/sqflite_ffi_impl_web.dart'
    show SqfliteFfiHandlerWeb;
import 'package:sqflite_common_ffi_web/src/sw/constants.dart';
import 'package:sqflite_common_ffi_web/src/utils.dart';
import 'package:sqflite_common_ffi_web/src/web/load_sqlite_web.dart'
    show
        SqfliteFfiWebContextExt,
        SqfliteFfiWebWorkerException,
        defaultSharedWorkerUri;
import 'package:sqflite_common_ffi_web/src/web_path.dart';
import 'package:synchronized/synchronized.dart';
import 'package:web/web.dart' as web;

import 'import.dart';

/// The Ffi database factory.
var databaseFactoryFfiWebNoWebWorkerImpl = () {
  return createDatabaseFactoryFfiWeb(noWebWorker: true);
}();

/// The Ffi database factory with basic worker
var databaseFactoryFfiWebBasicWorkerImpl = () {
  return createDatabaseFactoryFfiWeb(
    // ignore: invalid_use_of_visible_for_testing_member
    options: SqfliteFfiWebOptions(forceAsBasicWorker: true),
  );
}();

/// The Ffi database factory.
var databaseFactoryFfiWebImpl = () {
  return createDatabaseFactoryFfiWeb();
}();

final _initLock = Lock();

/// The web factory: the sqflite_common factory with the web path resolution.
class _SqfliteDatabaseFactoryFfiWeb with SqfliteDatabaseFactoryMixin {
  _SqfliteDatabaseFactoryFfiWeb(this._invokeMethod, {required String tag}) {
    this.tag = tag;
  }

  final Future<dynamic> Function(String method, [Object? arguments])
  _invokeMethod;

  @override
  Future<T> invokeMethod<T>(String method, [Object? arguments]) async =>
      (await _invokeMethod(method, arguments)) as T;

  /// `x.db` and `/x.db` are the same database (the same file for sqlite),
  /// see [sqfliteFfiWebFixPath].
  @override
  Future<String> fixPath(String path) async =>
      sqfliteFfiWebFixPath(await super.fixPath(path));
}

/// Creates a web database factory with its own [options] (sqlite3.wasm and
/// worker urls, IndexedDB name).
///
/// SQLite runs in a shared worker (`sqflite_sw.js`), or in the page when
/// [noWebWorker] is true (only `sqlite3.wasm` needed, not safe across tabs).
/// [tag] names the factory in the logs.
///
/// Web only: throws [UnsupportedError] on io.
DatabaseFactory createDatabaseFactoryFfiWeb({
  SqfliteFfiWebOptions? options,
  bool noWebWorker = false,
  String? tag,
}) {
  var webOptions = options ??= SqfliteFfiWebOptions();
  SqfliteFfiWebContext? context;
  return _SqfliteDatabaseFactoryFfiWeb(tag: tag ?? 'ffi_web', (
    String method, [
    Object? arguments,
  ]) async {
    if (method == methodOpenDatabase) {
      // singleInstance: false is not supported on the web
      checkOpenDatabaseArgumentsWeb(arguments);
    }
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
var _log = print;

/// Handle method call not to call the web worker.
Future<dynamic> ffiMethodCallSendToWebWorker(
  FfiMethodCall methodCall,
  SqfliteFfiWebContext context,
) async {
  try {
    if (_debug) {
      // ignore: avoid_print
      _log('main_send: $methodCall');
    }
    var map = dataToEncodable(methodCall.toDataMap())!;
    var response = await context.sendRawMessage(map);
    if (_debug) {
      _log('main_recv: $response');
    }
    return dataFromEncodable(responseToResultOrThrow(response));
  } catch (e, st) {
    if (_debug) {
      _log(e);
      _log(st);
    }
    if (e is SqfliteFfiWebWorkerException) {
      web.console.error(
        '''
An error occurred while initializing the web worker.
This is likely due to a failure to find the worker javascript file at ${context.options.sharedWorkerUri ?? defaultSharedWorkerUri}

Please check the documentation at https://github.com/tekartik/sqflite/tree/master/packages_web/sqflite_common_ffi_web#setup-binaries to setup the needed binaries.
'''
            .toJS,
      );
    }
    rethrow;
  }
}

/// Handle a method call
Future<dynamic> ffiMethodCallHandleNoWebWorker(
  FfiMethodCall methodCall,
  SqfliteFfiWebContext context,
) async {
  try {
    if (_debug) {
      _log('handle $methodCall');
    }

    /// Handle web options (get only)
    var method = methodCall.method;
    if (method == methodGetWebOptions) {
      return context.options.toMap();
    }
    dynamic result = await methodCall.rawHandle();

    if (_debug) {
      _log('result: $result');
    }

    // devPrint('result: $result');
    return result;
  } catch (e, st) {
    if (_debug) {
      _log(e);
      _log(st);
    }
    throw methodCall.wrapAnyExceptionNoIsolate(e);
  }
}
