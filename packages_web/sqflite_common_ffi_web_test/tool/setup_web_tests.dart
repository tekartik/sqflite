import 'package:sqflite_common_ffi_web/src/setup/setup.dart';

Future<void> main() async {
  await setupBinaries(options: SetupOptions(verbose: true, dir: 'test'));
}
