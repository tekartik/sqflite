//
// @dart = 2.9
//
// This is to allow running this file without null experiment
// In the future, remove this 2.9 comment or run using: dart --enable-experiment=non-nullable --no-sound-null-safety run tool/travis.dart

import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';

import 'linux_setup.dart' as linux_setup;

bool get runningOnTravis => Platform.environment['TRAVIS'] == 'true';

Future main() async {
  // print(Directory.current);
  var shell = Shell();

  if (runningOnTravis) {
    await linux_setup.main();
  }

  final nnbdEnabled = dartVersion > Version(2, 12, 0, pre: '0');
  if (nnbdEnabled) {
    await shell.run('''

dart analyze --fatal-warnings --fatal-infos .
dart format -o none --set-exit-if-changed .
dart test -p vm,chrome


''');
  } else {
    stderr.writeln('nnbd tests skipped on dart $dartVersion');
  }
}
