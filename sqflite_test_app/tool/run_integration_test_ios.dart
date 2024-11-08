import 'package:sqflite_support/test_project.dart';

import 'run_integration_test.dart';

Future<void> main() async {
  var iosDeviceId = await findFirstIOSDeviceId();
  await runIntegrationTest(deviceId: iosDeviceId);
}
