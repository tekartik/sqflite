import 'package:process_run/shell.dart';

Future<void> main() async {
  await runIntegrationTest();
}

Future<void> runIntegrationTest({String? deviceId}) async {
  final shell = Shell();

  await shell.run('flutter drive${deviceId != null ? ' -d $deviceId ' : ''}'
      ' --driver=test_driver/integration_test.dart'
      ' --target=integration_test/sqflite_test.dart');
}
