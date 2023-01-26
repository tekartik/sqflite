import 'package:dev_test/package.dart';
import 'package:path/path.dart';

Future main() async {
  // These projects perform build in their test and sometimes fails, at least
  // more frequently that the other standard format/analyze/test.
  for (var dir in ['sqflite_support', 'sqflite_test_app']) {
    await packageRunCi(join('..', dir),
        options: PackageRunCiOptions(testOnly: true));
  }
}
