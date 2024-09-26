@TestOn('vm')
library;

import 'package:sqflite_common_ffi/src/mixin/handler_mixin.dart';
import 'package:test/test.dart';

void main() {
  group('handler_mixin', () {
    // Check that public api are exported
    test('exported', () {
      for (dynamic value in <dynamic>[
        FfiMethodCall,
        SqfliteFfiException,
        ffiMethodCallhandleInIsolate(const FfiMethodCall('dummy')),
      ]) {
        expect(value, isNotNull);
      }
    });
  });
}
