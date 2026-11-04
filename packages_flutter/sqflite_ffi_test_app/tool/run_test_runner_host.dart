import 'dart:io';

import 'package:sqflite_support/flutter_device.dart';
import 'package:sqflite_support/flutter_test_runner.dart';

/// Runs lib/main_sqflite_ffi_test_runner.dart (results in the console) on
/// the host: linux, macos or windows (its platform folder is created when
/// missing).
///
/// Quits once the tests are done (exit code 1 if some failed), unless
/// `--no-quit` is given.
Future<void> main(List<String> arguments) async {
  var platform = flutterHostPlatform;
  await flutterCreatePlatforms([platform]);
  exitCode = await runFlutterTestRunner(
    deviceId: platform,
    target: 'lib/main_sqflite_ffi_test_runner.dart',
    quitWhenDone: !arguments.contains(flutterTestRunnerNoQuitArg),
  );
}
