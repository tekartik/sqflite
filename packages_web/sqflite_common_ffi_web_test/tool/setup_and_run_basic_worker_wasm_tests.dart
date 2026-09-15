import 'package:dev_build/shell.dart';
import 'setup_web_tests.dart';

/// Basic web worker tests with the test code compiled with dart2wasm
/// (the worker itself is always compiled with dart2js).
Future<void> main() async {
  await setupWebTests(force: true);
  await run(
    'dart test -p chrome -c dart2wasm test/sqflite_ffi_web_basic_web_worker_test.dart',
  );
}
