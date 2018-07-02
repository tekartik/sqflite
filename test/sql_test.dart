import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sql.dart';

void main() {
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

    test("exported", () {
      expect(ConflictAlgorithm.abort, isNotNull);
    });

    test("escapeName_export", () {
      expect(escapeName("group"), '"group"');
    });

    test("unescapeName_export", () {
      expect(unescapeName('"group"'), "group");
    });
  });
}
