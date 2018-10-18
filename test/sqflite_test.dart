import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  group("sqflite", () {
    const MethodChannel channel = MethodChannel('com.tekartik.sqflite');

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
      db?.transaction<dynamic>((Transaction txt) => null);

      Transaction transaction;
      transaction?.execute(null, null);

      expect(ConflictAlgorithm.abort, isNotNull);
    });

    test('firstIntValue', () {
      expect(
          Sqflite.firstIntValue(<Map<String, dynamic>>[
            <String, dynamic>{'test': 1}
          ]),
          1);
      expect(
          Sqflite.firstIntValue(<Map<String, dynamic>>[
            <String, dynamic>{'test': 1},
            <String, dynamic>{'test': 1}
          ]),
          1);
      expect(
          Sqflite.firstIntValue(<Map<String, dynamic>>[
            <String, dynamic>{'test': null}
          ]),
          null);
      expect(Sqflite.firstIntValue(<Map<String, dynamic>>[<String, dynamic>{}]),
          isNull);
      expect(Sqflite.firstIntValue(<Map<String, dynamic>>[]), isNull);
      expect(Sqflite.firstIntValue(<Map<String, dynamic>>[<String, dynamic>{}]),
          isNull);
    });

    test('hex', () {
      expect(
          Sqflite.hex(<int>[
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10,
            11,
            12,
            13,
            14,
            15,
            16,
            17,
            255
          ]),
          '000102030405060708090A0B0C0D0E0F1011FF');
      expect(Sqflite.hex(<int>[]), '');
      expect(Sqflite.hex(<int>[32]), '20');

      try {
        Sqflite.hex(<int>[-1]);
        fail('should fail');
      } on FormatException catch (_) {}

      try {
        Sqflite.hex(<int>[256]);
        fail('should fail');
      } on FormatException catch (_) {}
    });
  });
}
