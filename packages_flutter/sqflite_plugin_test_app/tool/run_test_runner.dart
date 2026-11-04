import 'dart:io';

import 'package:sqflite_support/flutter_device.dart';
import 'package:sqflite_support/flutter_test_runner.dart';

import 'flutter_create.dart';

/// Runs lib/main_sqflite_plugin_test_runner.dart (results in the console) on
/// a phone, an emulator or a simulator: SQFLITE_TEST_DEVICE_ID when set, the
/// only one connected, or the one picked.
///
/// Quits once the tests are done (exit code 1 if some failed), unless
/// `--no-quit` is given.
Future<void> main(List<String> arguments) async {
  await flutterCreate();
  var deviceId = await selectFlutterDeviceId();
  exitCode = await runFlutterTestRunner(
    deviceId: deviceId,
    target: 'lib/main_sqflite_plugin_test_runner.dart',
    quitWhenDone: !arguments.contains(flutterTestRunnerNoQuitArg),
  );
}
