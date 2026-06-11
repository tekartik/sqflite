import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfi, sqfliteFfiInit;

/// Check that the sandbox extension is visible through the sqflite import.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  test('sandbox extension', () async {
    // databaseFactoryFfi is statically typed as the sqflite DatabaseFactory.
    DatabaseFactory factory;
    factory = databaseFactoryFfi;
    var sandboxed = factory.sandbox(path: 'sandbox');
    expect(await sandboxed.getDatabasesPath(), 'sandbox');
  });
}
