@TestOn('vm')

// ignore: unused_import
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:sqflite_common_ffi_async/sqflite_ffi_async.dart';
import 'package:sqflite_common_ffi_async_test/all_test.dart';
import 'package:test/test.dart';

var debugFfiAsync = false; //devWarning(true); // false
DatabaseFactory get testFfiAsyncFactory => debugFfiAsync
    // ignore: deprecated_member_use
    ? databaseFactoryFfiAsync.debugQuickLoggerWrapper()
    : databaseFactoryFfiAsync;

class SqfliteFfiAsyncTestContext extends SqfliteLocalTestContext {
  SqfliteFfiAsyncTestContext() : super(databaseFactory: testFfiAsyncFactory);
  @override
  bool get supportsUri => false;

  @override
  bool get supportsConcurrentRead => true;
}

var ffiAsyncTestContext = SqfliteFfiAsyncTestContext();

void main() {
  /// Initialize ffi loader
  // sqfliteFfiInit();

  test('setup', () {
    expect(ffiAsyncTestContext.supportsConcurrentRead, true);
  });
  runFfiAsyncTests(ffiAsyncTestContext);
}
