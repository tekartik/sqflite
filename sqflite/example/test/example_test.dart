import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_example_common/utils.dart';

void main() {
  group('example', () {
    test('sleep', () async {
      await sleep(1).timeout(const Duration(milliseconds: 100));
      try {
        await sleep(100).timeout(const Duration(milliseconds: 1));
        fail('should fail');
      } on TimeoutException catch (_) {}
    });
  });
}
