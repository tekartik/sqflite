//
// @dart = 2.9
//
// This is to allow running this file without null experiment
// In the future, remove this 2.9 comment or run using: dart --enable-experiment=non-nullable --no-sound-null-safety run tool/travis.dart

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:sqflite_example/utils.dart';

import 'run_integration_test.dart' as integration_test;

Future<void> main() async {
  final shell = Shell();

  await shell.run('''

flutter analyze

''');

  Object exception;
  try {
    await integration_test.main();
  } catch (e) {
    exception = e;
  }

  // For android look for some kind of generated file
  // ignore: avoid_slow_async_io
  if (await Directory(join('build', 'sqflite', 'generated')).exists()) {
    if (exception != null) {
      throw exception;
    }
  }
}
