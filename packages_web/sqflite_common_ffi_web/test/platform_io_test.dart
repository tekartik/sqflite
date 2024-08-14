@TestOn('vm')
library;

import 'package:sqflite_common/src/mixin/platform.dart';
import 'package:test/test.dart';

void main() {
  test('isWeb', () {
    expect(platform.isWeb, isFalse);
  });
}
