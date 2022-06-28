//
// @dart = 2.9
//
// This is to allow running this file without null experiment
// In the future, remove this 2.9 command and run using: dart --enable-experiment=non-nullable --no-sound-null-safety run tool/travis.dart
import 'package:process_run/shell.dart';

Future<void> main() async {
  await buildIos();
}

Future<void> buildIos() async {
  final shell = Shell();
  await shell.run('flutter build ios --no-codesign');
}
