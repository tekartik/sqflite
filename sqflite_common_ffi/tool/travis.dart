import 'dart:io';

import 'package:process_run/shell.dart';
import 'linux_setup.dart' as linux_setup;

bool get runningOnTravis => Platform.environment['TRAVIS'] == 'true';
Future main() async {
  // print(Directory.current);
  var shell = Shell();

  if (runningOnTravis) {
    await linux_setup.main();
  }

  await shell.run('''

dartanalyzer --fatal-warnings --fatal-infos .
dartfmt -n --set-exit-if-changed .
pub run test

''');
}
