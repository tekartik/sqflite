//
// @dart = 2.9
//
// This is to allow running this file without null experiment
// In the future, remove this 2.9 command and run using: dart --enable-experiment=non-nullable --no-sound-null-safety run tool/travis.dart
import 'package:process_run/shell.dart';

Future<void> main() async {
  await runIntegrationTest();
}

Future<void> runIntegrationTest({String deviceId}) async {
  final shell = Shell();

  await shell.run('flutter drive${deviceId != null ? ' -d $deviceId ' : ''}'
      ' --driver=test_driver/integration_test.dart'
      ' --target=integration_test/sqflite_test.dart');
}
