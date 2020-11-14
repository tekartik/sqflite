//
// @dart = 2.9
//
// This is to allow running this file without null experiment
// In the future, remove this 2.9 comment or run using: dart --enable-experiment=non-nullable --no-sound-null-safety run tool/travis.dart

import 'package:dev_test/package.dart';

Future main() async {
  await packageRunCi('.');
}
