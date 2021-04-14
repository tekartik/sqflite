//
// @dart = 2.9
//
// This is to allow running this file without null experiment
// In the future, remove this 2.9 command or run using: dart --enable-experiment=non-nullable --no-sound-null-safety run tool/travis.dart
import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';

Future main() async {
  var shell = Shell(workingDirectory: '..');

  await shell.run('flutter doctor');

  final nnbdEnabled = dartVersion > Version(2, 12, 0, pre: '0');
  if (nnbdEnabled) {
    for (var dir in [
      'sqflite_common',
      'sqflite_common_ffi',
      'sqflite_common_test',
    ]) {
      shell = shell.pushd(dir);
      await shell.run('''
    
    dart pub get
    dart run tool/travis.dart
    
        ''');
      shell = shell.popd();
    }
    for (var dir in [
      'sqflite',
      'sqflite/example',
      'sqflite_test_app',
    ]) {
      shell = shell.pushd(dir);
      await shell.run('''
    
    flutter pub get
    dart run tool/travis.dart
    
        ''');
      shell = shell.popd();
    }
  } else {
    stderr.writeln('ci test skipped for $dartVersion');
  }
}
