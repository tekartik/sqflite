import 'package:dev_build/shell.dart';

Future<void> main() async {
  await run('flutter run -d linux -t lib/main_sqflite_ffi_test_runner.dart');
}
