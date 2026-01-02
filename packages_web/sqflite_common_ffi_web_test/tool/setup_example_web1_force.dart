import 'package:path/path.dart';
import 'package:sqflite_common_ffi_web/setup.dart';

Future<void> main() async {
  await setupSqfliteWebBinaries(
    options: SqfliteWebSetupOptions(
      dir: join('example', 'web1'),
      verbose: true,
      force: true,
      sqfliteWebWorkerFilename: 'sqflite_sw_example_web1.js',
      sqlite3WasmFilename: 'sqlite3_example_web1.wasm',
    ),
  );
}
