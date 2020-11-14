//
// @dart = 2.9
//
// This is to allow running this file without null experiment
// In the future, remove this 2.9 command or run using: dart --enable-experiment=non-nullable --no-sound-null-safety run tool/travis.dart
import 'flutter_run.dart' as flutter_run;

Future<void> main() async {
  await flutter_run.main('-d linux'.split(' '));
}
