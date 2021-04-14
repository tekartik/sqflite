import 'package:dev_test/package.dart';
import 'package:path/path.dart';

Future main() async {
  for (var dir in [
    'sqflite_common',
    'sqflite_common_test',
    'sqflite_common_ffi',
    'sqflite/example',
    'sqflite',
    'sqflite_test_app',
    'sqflite_support',
  ]) {
    await packageRunCi(join('..', dir));
  }
}
