// To run using: dart --enable-experiment=non-nullable --no-sound-null-safety run tool/travis.dart

import 'flutter_run.dart' as flutter_run;

Future<void> main() async {
  await flutter_run.main('-d linux'.split(' '));
}
