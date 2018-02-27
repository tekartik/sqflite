import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/src/sqflite_impl.dart';

main() {
  group("sqflite", () {
    const MethodChannel channel = const MethodChannel('com.tekartik.sqflite');

    final List<MethodCall> log = <MethodCall>[];
    String response;

    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
      return response;
    });

    tearDown(() {
      log.clear();
    });

    test("supportsConcurrency", () async {
      expect(supportsConcurrency, isFalse);
    });

    test('Rows', () {
      var raw = [
        {'col': 1}
      ];
      var rows = new Rows.from(raw);
      var row = rows.first;
      expect(rows, raw);
      expect(row, {"col": 1});
    });
  });
}
