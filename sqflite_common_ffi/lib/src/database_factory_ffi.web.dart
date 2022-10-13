import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi/src/method_call.dart';
import 'package:sqflite_common_ffi/src/sqflite_import.dart';

import 'sqflite_ffi_impl.dart';

/// The Ffi database factory.
var databaseFactoryFfiImpl = createDatabaseFactoryFfiImpl();

/// The Ffi database factory.
var databaseFactoryFfiNoIsolateImpl = createDatabaseFactoryFfiImpl(noIsolate: true);

/// Creates an FFI database factory
DatabaseFactory createDatabaseFactoryFfiImpl({SqfliteFfiInit? ffiInit, bool noIsolate = false, String? tag = 'ffi'}) {
  return buildDatabaseFactory(
      tag: tag,
      invokeMethod: (String method, [dynamic arguments]) {
        final methodCall = FfiMethodCall(method, arguments);
        return methodCall.rawHandle();
      });
}
