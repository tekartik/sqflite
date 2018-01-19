import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sql.dart';

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

    test("setDebugModeOn", () async {
      await Sqflite.setDebugModeOn();
      //expect(log, equals(<MethodCall>[new MethodCall('debugMode', true)]));
    });

    test("exported", () {
      try {
        Database db;
        db.update(null, null, conflictAlgorithm: ConflictAlgorithm.abort);
      } catch (_) {}
    });

    test("escapeName_export", () {
      expect(escapeName("group"), '"group"');
    });

    test("unescapeName_export", () {
      expect(unescapeName('"group"'), "group");
    });
  });
}
