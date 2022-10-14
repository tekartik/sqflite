import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi/src/env_utils.dart';
import 'package:test/test.dart';

void main() {
  group('import', () {
    test('io', () {
      try {
        databaseFactoryFfi;
        if (isRunningAsJavascript) {
          fail('should fail');
        }
      } on UnsupportedError catch (_) {}
    });
  });
}
