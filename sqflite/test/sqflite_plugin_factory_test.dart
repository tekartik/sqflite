import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
// ignore: implementation_imports
import 'package:sqflite_common/src/utils.dart' as impl;

const _channel = MethodChannel('com.tekartik.sqflite');

void _setMockHandler(Future<Object?>? Function(MethodCall call)? handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, handler);
}

/// `databaseFactorySqflitePlugin` (sqflite's own method channel factory) must
/// behave as the one of sqflite_platform_interface (registered by
/// sqflite_android and sqflite_darwin).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final factory = databaseFactorySqflitePlugin;
  late Directory dir;
  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('sqflite_plugin_factory');
    await factory.setDatabasesPath(dir.path);
  });
  tearDownAll(() async {
    await dir.delete(recursive: true);
  });
  tearDown(() {
    _setMockHandler(null);
  });

  test('relative database bytes path in the databases path', () async {
    const name = 'sqflite_plugin_factory_bytes.db';
    final cwdFile = File(name);
    try {
      final bytes = Uint8List.fromList([1, 2, 3]);
      await factory.writeDatabaseBytes(name, bytes);
      expect(
        File('${dir.path}${Platform.pathSeparator}$name').readAsBytesSync(),
        bytes,
      );
      expect(cwdFile.existsSync(), isFalse);
      expect(await factory.readDatabaseBytes(name), bytes);
    } finally {
      if (cwdFile.existsSync()) {
        cwdFile.deleteSync();
      }
    }
  });

  test('sqlite_error without message', () async {
    _setMockHandler((call) async {
      throw PlatformException(code: 'sqlite_error', message: null);
    });
    try {
      await factory.openDatabase('no_message.db');
      fail('should fail');
    } on DatabaseException catch (e) {
      expect(e, isA<DatabaseException>());
    }
  });

  group('setLockWarningInfo', () {
    final duration = impl.lockWarningDuration;
    final callback = impl.lockWarningCallback;
    tearDown(() {
      impl.lockWarningDuration = duration;
      impl.lockWarningCallback = callback;
    });
    test('duration only', () {
      Sqflite.setLockWarningInfo(duration: const Duration(seconds: 3));
      expect(impl.lockWarningDuration, const Duration(seconds: 3));
      expect(impl.lockWarningCallback, callback);
    });
    test('callback only', () {
      void silent() {}
      Sqflite.setLockWarningInfo(callback: silent);
      expect(impl.lockWarningDuration, duration);
      expect(impl.lockWarningCallback, silent);
    });
  });
}
