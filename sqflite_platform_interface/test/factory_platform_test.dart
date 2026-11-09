import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_platform_interface/sqflite_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  // The method channel factory, as registered by sqflite_android and
  // sqflite_darwin.
  final factory = SqflitePlatform.databaseFactoryMethodChannel;
  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('sqflite_platform_interface');
    await factory.setDatabasesPath(dir.path);
  });
  tearDownAll(() async {
    await dir.delete(recursive: true);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.tekartik.sqflite'),
          null,
        );
  });

  test('relative database bytes path in the databases path', () async {
    final name = 'sqflite_platform_interface_bytes.db';
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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('com.tekartik.sqflite'), (
          call,
        ) async {
          throw PlatformException(code: 'sqlite_error', message: null);
        });
    try {
      await factory.openDatabase('no_message.db');
      fail('should fail');
    } on DatabaseException catch (e) {
      expect(e, isA<DatabaseException>());
    }
  });
}
