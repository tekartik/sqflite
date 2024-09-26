@TestOn('vm')
library;

import 'dart:io';

import 'package:sqflite_common_ffi/src/windows/setup.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  test('sqlite3 simple test', () {
    if (Platform.isWindows) {
      windowsInit();
    }
    final database = sqlite3.openInMemory();
    var version = database.userVersion;
    expect(version, 0);
    database.dispose();
  });
}
