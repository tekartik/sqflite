// ignore_for_file: avoid_print

import 'package:process_run/shell.dart';
import 'package:sqflite_common_ffi_web/src/setup/setup.dart';

import 'setup_example_force.dart';

Future<void> main(List<String> args) async {
  if (true) {
    await setupExampleForce();
    await run('''
      dart pub get
      webdev build -o example:build
  ''');
  }
  await dhttpdReady;
  print('http://localhost:8080');
  await Shell(workingDirectory: 'build').run('dhttpd');
}
