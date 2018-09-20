import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_example/model/test.dart';

void main() {
  group("model", () {
    test("test_sync", () async {
      bool ran = false;
      Test test = Test("test", () {
        ran = true;
      });
      await test.fn();
      expect(ran, isTrue);
    });

    test("test_async", () async {
      bool ran = false;
      Test test = Test("test", () async {
        ran = true;
      });
      await test.fn();
      expect(ran, isTrue);
    });
  });
}
