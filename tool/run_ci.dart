//
// @dart = 2.9
//
// This is to allow running this file without null experiment
// In the future, remove this 2.9 comment or run using: dart --enable-experiment=non-nullable --no-sound-null-safety run tool/travis.dart

import 'package:process_run/shell.dart';
import 'package:dev_test/package.dart';

Future main() async {
  var shell = Shell();

  await shell.run('flutter doctor');

  for (var dir in [
    // 'sqflite/example',
    // 'sqflite',
    // 'sqflite_test_app',
    'sqflite_common',
    'sqflite_common_test',
    'sqflite_common_ffi',
  ]) {
    shell = shell.pushd(dir);
    await packageRunCi(dir);
    shell = shell.popd();
  }
}
