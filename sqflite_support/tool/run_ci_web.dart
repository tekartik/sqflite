import 'package:dev_build/package.dart';
import 'package:path/path.dart';

Future main() async {
  for (var dir in [join('packages_web', 'sqflite_common_ffi_web')]) {
    await packageRunCi(join('..', dir));
  }
}
