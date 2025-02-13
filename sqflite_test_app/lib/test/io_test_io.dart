import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:test/test.dart';

/// sqflite io tests only
void runIoTests(SqfliteTestContext context) {
  var factory = context.databaseFactory;
  if (context.isPlugin && Platform.isIOS) {
    test('darwinCreateUnprotectedFolder', () async {
      var path = join(
        await factory.getDatabasesPath(),
        'darwinCreateUnprotectedFolder',
      );
      var unprotected = 'unprotected';

      await Directory(path).delete(recursive: true);
      var unprotectedPath = join(path, unprotected);
      expect(Directory(unprotectedPath).existsSync(), isFalse);
      await SqfliteDarwin.createUnprotectedFolder(path, unprotected);
      expect(Directory(unprotectedPath).existsSync(), isTrue);
    });
  }
}
