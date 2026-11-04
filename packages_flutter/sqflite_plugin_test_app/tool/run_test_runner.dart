import 'package:dev_build/shell.dart';
import 'package:sqflite_support/flutter_device.dart';

import 'flutter_create.dart';

/// Runs lib/main_sqflite_plugin_test_runner.dart (results in the console) on
/// a phone, an emulator or a simulator: SQFLITE_TEST_DEVICE_ID when set, the
/// only one connected, or the one picked.
Future<void> main() async {
  await flutterCreate();
  var deviceId = await selectFlutterDeviceId();
  await run(
    'flutter run -d $deviceId -t lib/main_sqflite_plugin_test_runner.dart',
  );
}
