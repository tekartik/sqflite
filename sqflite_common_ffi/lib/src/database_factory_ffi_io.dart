import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi/src/sqflite_import.dart';
import 'package:synchronized/synchronized.dart';

import 'isolate.dart';
import 'sqflite_ffi_impl.dart';

/// The Ffi database factory.
var databaseFactoryFfiImpl = createDatabaseFactoryFfiImpl();

/// The Ffi database factory.
var databaseFactoryFfiNoIsolateImpl = createDatabaseFactoryFfiImpl(
  noIsolate: true,
);

/// Creates an FFI database factory
DatabaseFactory createDatabaseFactoryFfiImpl({
  SqfliteFfiInit? ffiInit,
  bool noIsolate = false,
  String? tag = 'ffi',
}) {
  var noIsolateInitialized = false;
  return buildDatabaseFactory(
    tag: tag,
    invokeMethod: (String method, [Object? arguments]) {
      final methodCall = FfiMethodCall(method, arguments);
      if (noIsolate) {
        if (!noIsolateInitialized) {
          if (ffiInit != null) {
            ffiInit();
          }
        }
        return ffiMethodCallHandleNoIsolate(methodCall);
      } else {
        return ffiMethodCallhandleInIsolate(methodCall, ffiInit: ffiInit);
      }
    },
  );
}

bool _debug = false; // devWarning(true); // false

SqfliteIsolate? _isolate;
final _isolateLock = Lock();

// ignore: avoid_print
void _log(Object? object) => print(object);

/// Extension on MethodCall
/// Handle a method call in a background isolate
Future<dynamic> ffiMethodCallhandleInIsolate(
  FfiMethodCall methodCall, {
  SqfliteFfiInit? ffiInit,
}) async {
  try {
    if (_debug) {
      _log('main_send: $methodCall');
    }
    var result = await _isolateHandle(methodCall, ffiInit);
    if (_debug) {
      _log('main_recv: $result');
    }
    return result;
  } catch (e, st) {
    if (_debug) {
      _log(e);
      _log(st);
    }
    rethrow;
  }
}

/// Handle a method call
Future<dynamic> ffiMethodCallHandleNoIsolate(FfiMethodCall methodCall) async {
  try {
    if (_debug) {
      _log('handle $methodCall');
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

/// Create the isolate if needed
Future<dynamic> _isolateHandle(
  FfiMethodCall methodCall,
  SqfliteFfiInit? ffiInit,
) async {
  if (_isolate == null) {
    await _isolateLock.synchronized(() async {
      _isolate ??= await createIsolate(ffiInit);
    });
  }
  return await _isolate!.handle(methodCall);
}
