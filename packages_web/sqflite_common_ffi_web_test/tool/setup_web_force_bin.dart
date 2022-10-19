import 'package:process_run/shell.dart';

Future<void> main() async {
  await run('dart run sqflite_common_ffi_web:setup --verbose --force');
}
