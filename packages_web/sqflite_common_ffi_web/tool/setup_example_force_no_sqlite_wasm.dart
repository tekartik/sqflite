import 'package:sqflite_common_ffi_web/src/setup/setup.dart';

Future<void> main() async {
  await setupExample();
}

Future<void> setupExample() async {
  await setupBinaries(
      options: SetupOptions(dir: 'example', noSqlite3Wasm: true, force: true));
}
