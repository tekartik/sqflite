import 'package:dev_build/package.dart';
import 'package:path/path.dart';

Future main() async {
  for (var dir in [
    'sqflite_common',
    'sqflite_common_test',
    'sqflite_common_ffi',
    join('sqflite', 'example'),
    'sqflite',
    'sqflite_darwin',
    'sqflite_android',
    'sqflite_platform_interface',
    join('packages', 'console_test_app'),
    join('packages_flutter', 'sqflite_example_common'),
  ]) {
    await packageRunCi(join('..', dir));
  }

  // These projects perform build in their test and sometimes fails, at least
  // more frequently that the other standard format/analyze/test.
  for (var dir in ['sqflite_support', 'sqflite_test_app']) {
    await packageRunCi(
      join('..', dir),
      options: PackageRunCiOptions(noTest: true),
    );
  }
}
