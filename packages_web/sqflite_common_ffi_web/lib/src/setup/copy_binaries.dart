import 'package:sqflite_common_ffi_web/src/setup/setup.dart';

Future<void> main() async {
  var context = await getSetupContext();
  await context.copyBinaries();
}
