import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/src/mixin/handler_mixin.dart';

/// Use `sqflite_ffi` as the mock implementation for unit test or regular
///
/// application using `sqflite`
void sqfliteFfiInitAsMockMethodCallHandler() {
  const channel = MethodChannel('com.tekartik.sqflite');

  channel.setMockMethodCallHandler((MethodCall methodCall) async {
    try {
      return await FfiMethodCall(methodCall.method, methodCall.arguments)
          .handleInIsolate();
    } on SqfliteFfiException catch (e) {
      // Re-convert to a Platform exception to make flutter services happy
      throw PlatformException(
          code: e.code, message: e.message, details: e.details);
    }
  });
}
