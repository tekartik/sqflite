@TestOn('vm')
library;

// ignore: unused_import
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_common_ffi_async_test/all_test.dart';
import 'package:test/test.dart';

import 'sqflite_ffi_async_test.dart';

var ffiAsyncTestContext = SqfliteFfiAsyncTestContext();

void main() {
  /// Initialize ffi loader
  runFfiAsyncTests(ffiAsyncTestContext, all: true);
}
