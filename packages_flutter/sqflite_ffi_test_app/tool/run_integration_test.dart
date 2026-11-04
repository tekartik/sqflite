import 'package:dev_build/shell.dart';
import 'package:sqflite_support/flutter_device.dart';

/// Runs integration_test/sqflite_ffi_test.dart (results and exit code on the
/// host) on a phone, an emulator or a simulator: SQFLITE_TEST_DEVICE_ID when
/// set, the only one connected, or the one picked.
Future<void> main() async {
  var deviceId = await selectFlutterDeviceId();
  await run('flutter test integration_test -d $deviceId');
}
