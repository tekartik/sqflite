import 'package:sqflite_common_ffi_web/src/setup/setup.dart';

Future<void> main() async {
  await setupExampleForce();
}

Future<void> setupExampleForce() async {
  await setupBinaries(
      options: SetupOptions(dir: 'example', force: true, verbose: true));
}
