import 'package:path/path.dart';
import 'package:sqflite_common_ffi_web/src/setup/setup.dart';

Future<void> main() async {
  await copyBinaries();
}

Future<void> copyBinaries() async {
  var context = await getSetupContext();
  await context.copyBinaries(outputDir: join('example'));
}
