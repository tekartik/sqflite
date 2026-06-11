// ignore_for_file: unnecessary_statements

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('import', () {
    try {
      sqfliteDatabaseFactoryFfi;
      if (kIsWeb) {
        fail('should fail');
      }
    } on UnsupportedError catch (_) {}

    SqfliteFfiIsolatePortServer;
    SqfliteFfiInit;
    sqfliteFfiInit;
    createDatabaseFactoryFfi;
  });
}
