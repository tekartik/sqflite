import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi/src/method_call.dart';
import 'package:sqflite_common_ffi/src/sqflite_import.dart';
import 'package:synchronized/synchronized.dart';

import 'isolate.dart';
import 'mixin/handler_mixin.dart';
import 'sqflite_ffi_impl.dart';

/// The Ffi database factory.
var databaseFactoryFfiImpl = createDatabaseFactoryFfiImpl();

/// The Ffi database factory.
var databaseFactoryFfiNoIsolateImpl =
    createDatabaseFactoryFfiImpl(noIsolate: true);

/// Creates an FFI database factory
DatabaseFactory createDatabaseFactoryFfiImpl(
    {SqfliteFfiInit? ffiInit, bool noIsolate = false, String? tag = 'ffi'}) {
  var noIsolateInitialized = false;
  return buildDatabaseFactory(
      tag: tag,
      invokeMethod: (String method, [dynamic arguments]) {
        final methodCall = FfiMethodCall(method, arguments);
        if (noIsolate) {
          if (!noIsolateInitialized) {
            if (ffiInit != null) {
              ffiInit();
            }
          }
          return methodCall.handleNoIsolate();
        } else {
          return methodCall.handleInIsolate(ffiInit: ffiInit);
        }
      });
}

bool _debug = false; // devWarning(true);

SqfliteIsolate? _isolate;
final _isolateLock = Lock();

/// Extension on MethodCall
extension FfiMethodCallHandler on FfiMethodCall {
  /// Handle a method call in a background isolate
  Future<dynamic> handleInIsolate({SqfliteFfiInit? ffiInit}) async {
    try {
      if (_debug) {
        print('main_send: $this');
      }
      var result = await _isolateHandle(ffiInit);
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
  Future<dynamic> handleNoIsolate() async {
    try {
      if (_debug) {
        print('handle $this');
      }
      dynamic result = await rawHandle();

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
      throw wrapAnyExceptionNoIsolate(e);
    }
  }

  /// Create the isolate if needed
  Future<dynamic> _isolateHandle(SqfliteFfiInit? ffiInit) async {
    if (_isolate == null) {
      await _isolateLock.synchronized(() async {
        _isolate ??= await createIsolate(ffiInit);
      });
    }
    return await _isolate!.handle(this);
  }
}
