import 'dart:io';

import 'package:process_run/shell.dart';

String getEnvDeviceArg() {
  var deviceId = getEnvSqfliteTestDeviceId();
  var deviceArg = deviceId != null ? ' -d $deviceId' : '';
  return deviceArg;
}

String? getEnvSqfliteTestDeviceId() {
  var deviceId = ShellEnvironment().vars['SQFLITE_TEST_DEVICE_ID'];
  if (deviceId == null) {
    // ignore: avoid_print
    stdout.writeln(
      'To run on a specific device set SQFLITE_TEST_DEVICE_ID=<deviceId>,'
      ' for example \'emulator-5554\' typically for android emulator',
    );
  }
  return deviceId;
}

Future<void> main() async {
  var deviceId = getEnvSqfliteTestDeviceId();
  await runIntegrationTest(deviceId: deviceId);
}

Future<void> runIntegrationTest({String? deviceId}) async {
  final shell = Shell();

  var deviceArg = deviceId != null ? ' -d $deviceId' : '';
  await shell.run(
    'flutter test integration_test/sqflite_test.dart$deviceArg --no-pub',
  );
}

Future<void> runIntegrationTestLegacy({String? deviceId}) async {
  final shell = Shell();

  var deviceArg = deviceId != null ? ' -d $deviceId' : '';
  await shell.run(
    'flutter drive$deviceArg'
    ' --no-pub'
    ' --driver=test_driver/integration_test.dart'
    ' --target=integration_test/sqflite_test.dart',
  );
}
