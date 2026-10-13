import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

/// True on the web, dart2js and dart2wasm (identical(1, 1.0) is false with
/// dart2wasm).
const _isWeb = bool.fromEnvironment('dart.library.js_interop');

void main() {
  group('import', () {
    test('io', () {
      try {
        databaseFactoryFfi;
        if (_isWeb) {
          fail('should fail');
        }
      } on UnsupportedError catch (_) {}
    });
  });
}
