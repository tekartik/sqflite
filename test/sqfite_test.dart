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
      expect(log, equals(<MethodCall>[new MethodCall('debugMode', true)]));
    });
  });
}
