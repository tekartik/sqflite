@TestOn('vm')
library;

// ignore: implementation_imports
import 'package:sqflite_common/src/env_utils.dart';
// ignore: implementation_imports
import 'package:sqflite_common/src/mixin/platform.dart';
import 'package:test/test.dart';

void main() {
  test('isWeb', () {
    expect(platform.isWeb, isFalse);
    expect(kSqfliteIsWeb, isFalse);
  });
}
