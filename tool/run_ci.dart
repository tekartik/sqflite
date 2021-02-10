//
// @dart = 2.9
//
// This is to allow running this file without null experiment
// In the future, remove this 2.9 comment or run using: dart --enable-experiment=non-nullable --no-sound-null-safety run tool/travis.dart
import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:process_run/shell.dart';
import 'package:dev_test/package.dart';

Future main() async {
  var shell = Shell();

  await shell.run('flutter doctor');

  final nnbdEnabled = dartVersion > Version(2, 12, 0, pre: '0');
  if (nnbdEnabled) {
    for (var dir in [
      'sqflite_common',
      'sqflite_common_test',
      'sqflite_common_ffi',
      'sqflite/example',
      'sqflite',
      'sqflite_test_app',
      'sqflite_support',
    ]) {
      shell = shell.pushd(dir);
      await packageRunCi(dir);
      shell = shell.popd();
    }
  } else {
    stderr.writeln('ci test skipped for $dartVersion');
  }
}
