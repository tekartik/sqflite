import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/src/method_call.dart';
import 'package:sqflite_common_ffi/src/sqflite_import.dart';

import 'package:synchronized/synchronized.dart';

import 'isolate.dart';

DatabaseFactory? _databaseFactoryFfiImpl;

/// The Ffi database factory.
DatabaseFactory get databaseFactoryFfiImpl =>
    _databaseFactoryFfiImpl ??= createDatabaseFactoryFfiImpl();

DatabaseFactory createDatabaseFactoryFfiImpl({void Function() ffiInit}) {
  return buildDatabaseFactory(
        invokeMethod: (String method, [dynamic arguments]) {
      //FfiMethodCall methodCall = FfiMethodCall(method, arguments);
      var methodCall = FfiMethodCall(method, arguments);
      return methodCall.handleInIsolate(ffiInit);
    });
}

bool _debug = false; // devWarning(true);

SqfliteIsolate? _isolate;
final _isolateLock = Lock();

/// Extension on MethodCall
extension FfiMethodCallHandler on FfiMethodCall {
  /// Handle a method call
  Future<dynamic> handleInIsolate(void Function() ffiInit) async {
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

  /// Create the isolate if needed
  Future<dynamic> _isolateHandle(void Function() ffiInit) async {
    if (_isolate == null) {
      await _isolateLock.synchronized(() async {
        _isolate ??= await createIsolate(ffiInit);
      });
    }
    return await _isolate!.handle(this);
  }
}
