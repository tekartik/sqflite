import 'package:sqflite_example_common/main.dart';
import 'package:sqflite_test_app/main_dev.dart';
import 'package:sqflite_test_app/src/import.dart';

Future main() async {
  sqliteFfiWebDebugWebWorker = true;
  // ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
  // debugAutoStartRouteName = testExceptionRoute;
  // debugAutoStartRouteName = testOpenRoute;
  debugAutoStartRouteName = testManualRoute;
  // debugAutoStartRouteName = testRawRoute;
  // debugAutoStartRouteName = testTypeRoute;
  // debugAutoStartRouteName = testBatchRoute;
  // debugAutoStartRouteName = testExpRoute;

  await mainDev();
}
