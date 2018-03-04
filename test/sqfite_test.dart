import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

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
      expect(log.first.method, "debugMode");
      expect(log.first.arguments, true);
    });

    // Check that public api are exported
    test("exported", () {
      Database db;

      db?.batch();
      db?.update(null, null);
      db?.transaction((Transaction txt) => null);
      // ignore: deprecated_member_use
      db?.inTransaction(null);

      Transaction transaction;
      transaction?.execute(null, null);

      expect(ConflictAlgorithm.abort, isNotNull);
    });
  });
}
