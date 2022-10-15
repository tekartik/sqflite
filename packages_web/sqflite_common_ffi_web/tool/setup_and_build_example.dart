import 'package:process_run/shell.dart';
import 'package:sqflite_common_ffi_web/src/setup/setup.dart';

import 'setup_example.dart';

Future<void> main(List<String> args) async {
  await setupBinaries();
  await copyBinaries();
  await run('''
      dart pub get
      webdev build -o example:build
  ''');
}
