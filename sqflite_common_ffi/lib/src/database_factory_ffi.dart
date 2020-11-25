import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi/src/method_call.dart';
import 'package:sqflite_common_ffi/src/sqflite_import.dart';

import 'package:synchronized/synchronized.dart';

import 'isolate.dart';

DatabaseFactory? _databaseFactoryFfiImpl;

/// The Ffi database factory.
DatabaseFactory get databaseFactoryFfiImpl =>
    _databaseFactoryFfiImpl ??= createDatabaseFactoryFfiImpl();

/// Creates an FFI database factory
DatabaseFactory createDatabaseFactoryFfiImpl({SqfliteFfiInit? ffiInit}) {
  return buildDatabaseFactory(
      invokeMethod: (String method, [dynamic arguments]) {
    final methodCall = FfiMethodCall(method, arguments);
    return methodCall.handleInIsolate(ffiInit: ffiInit);
  });
}

bool _debug = false; // devWarning(true);

SqfliteIsolate? _isolate;
final _isolateLock = Lock();

/// Extension on MethodCall
extension FfiMethodCallHandler on FfiMethodCall {
  /// Handle a method call
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
