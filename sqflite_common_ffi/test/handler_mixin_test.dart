import 'package:sqflite_common_ffi/src/mixin/handler_mixin.dart';
import 'package:test/test.dart';

void main() {
  group('handler_mixin', () {
    // Check that public api are exported
    test('exported', () {
      <dynamic>[
        FfiMethodCall,
        SqfliteFfiException,
        const FfiMethodCall('dummy').handleInIsolate,
      ].forEach((dynamic value) {
        expect(value, isNotNull);
      });
    });
  });
}
