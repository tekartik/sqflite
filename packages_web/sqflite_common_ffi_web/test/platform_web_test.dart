@TestOn('browser')
library;

// ignore: implementation_imports
import 'package:sqflite_common/src/env_utils.dart';
// ignore: implementation_imports
import 'package:sqflite_common/src/mixin/platform.dart';
import 'package:test/test.dart';

void main() {
  test('isWeb', () {
    expect(platform.isWeb, isTrue);
    // Must be true with both dart2js and dart2wasm
    expect(kSqfliteIsWeb, isTrue);
  });
}
