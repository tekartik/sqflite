import 'package:dev_build/shell.dart';
import 'package:sqflite_support/flutter_device.dart';

/// Runs lib/main_sqflite_ffi_test_runner.dart (results in the console) on a
/// phone, an emulator or a simulator: SQFLITE_TEST_DEVICE_ID when set, the
/// only one connected, or the one picked.
Future<void> main() async {
  var deviceId = await selectFlutterDeviceId();
  await run(
    'flutter run -d $deviceId -t lib/main_sqflite_ffi_test_runner.dart',
  );
}
