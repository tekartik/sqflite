import 'package:sqflite_example/main.dart';
import 'package:sqflite_test_app/main_dev.dart';

Future main() async {
  var noWorker = true; // devWarning(true);
  // debugAutoStartRouteName = testExceptionRoute;
  // ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
  debugAutoStartRouteName = testOpenRoute;
  // debugAutoStartRouteName = testManualRoute;
  // debugAutoStartRouteName = testRawRoute;
  // debugAutoStartRouteName = testTypeRoute;
  // debugAutoStartRouteName = testExpRoute;
  // debugAutoStartRouteName = testBatchRoute;

  await mainDev(noWorker: noWorker);
}
