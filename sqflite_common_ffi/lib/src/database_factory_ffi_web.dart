import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'method_call.dart';

/// The Ffi database factory.
var databaseFactoryFfiImpl = throw UnsupportedError(
  'Unsupported on the web, use sqflite_common_ffi_web',
);

/// The Ffi database factory.
var databaseFactoryFfiNoIsolateImpl = throw UnsupportedError(
  'Unsupported on the web, use sqflite_common_ffi_web',
);

/// Handle a method call in a background isolate
Future<dynamic> ffiMethodCallhandleInIsolate(
  FfiMethodCall methodCall, {
  SqfliteFfiInit? ffiInit,
}) => throw UnsupportedError(
  'ffiMethodCallhandleInIsolate unsupported on the web',
);

/// Handle a call not in an isolate
Future<dynamic> ffiMethodCallHandleNoIsolate(FfiMethodCall methodCall) =>
    throw UnsupportedError(
      'ffiMethodCallHandleNoIsolate unsupported on the web',
    );
