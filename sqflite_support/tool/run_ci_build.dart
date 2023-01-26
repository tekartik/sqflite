import 'package:dev_test/package.dart';
import 'package:path/path.dart';

Future main() async {
  // We are the only project we use that should work on all platforms but sometimes fails.
  for (var dir in ['sqflite_support']) {
    await packageRunCi(join('..', dir));
  }
}
