@TestOn('vm')
import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi/src/windows/sqlite3_info.dart';
import 'package:test/test.dart';

void main() {
  if (Platform.isWindows) {
    sqfliteFfiInit();
    group('windows', () {
      test('version', () async {
        final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
        final results = await db.rawQuery('select sqlite_version()');

        var version = results.first.values.first;
        expect(version, sqlite3Info.version);
      });
    });
  }
}
