import 'package:dev_build/shell.dart';
import 'setup_web_tests.dart';

Future<void> main() async {
  await setupWebTests(force: true);
  await run(
    'dart test -p chrome test/sqflite_ffi_web_basic_web_worker_test.dart',
  );
}
