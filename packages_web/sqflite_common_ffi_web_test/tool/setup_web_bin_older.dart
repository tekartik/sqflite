import 'package:process_run/shell.dart';

Future<void> main() async {
  await run(
    'dart run sqflite_common_ffi_web:setup --verbose --sqlite3-wasm-url https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-2.4.5/sqlite3.wasm',
  );
}
