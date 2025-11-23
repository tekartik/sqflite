import 'package:process_run/shell.dart';

import 'run_integration_test.dart';

Future<void> main() async {
  var deviceArg = getEnvDeviceArg();
  await run('flutter run -t lib/test/test_main_plugin.dart$deviceArg --no-pub');
}
