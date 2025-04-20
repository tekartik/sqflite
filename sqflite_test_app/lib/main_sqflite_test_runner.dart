import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:sqflite_test_app/test/io_tests_io.dart';

/// Use ffi on windows and linux only
var useFfi = !kIsWeb && (Platform.isWindows || Platform.isLinux);

/// Test runner context
class SqfliteRunnerTestContext extends SqfliteLocalTestContext {
  /// Test runner context
  SqfliteRunnerTestContext()
    : super(databaseFactory: useFfi ? databaseFactoryFfi : databaseFactory);

  @override
  bool get isPlugin {
    return !useFfi;
  }

  @override
  bool get supportsRecoveredInTransaction => true;

  /// Only tested on ffi linux for now.
  @override
  bool get supportsUri => useFfi ? true : false;
}

/// Test runner context
var testContext = SqfliteRunnerTestContext();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var testContext = SqfliteRunnerTestContext();
  all.run(testContext);
  runIoTests(testContext);
}
