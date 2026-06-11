import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_ffi/sqflite_ffi.dart';

/// Check that the sandbox extension is visible through the sqflite_ffi
/// import.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  test('sandbox extension', () async {
    var factory = sqfliteDatabaseFactoryFfi;
    var sandboxed = factory.sandbox(path: 'sandbox');
    expect(await sandboxed.getDatabasesPath(), 'sandbox');
  });
}
