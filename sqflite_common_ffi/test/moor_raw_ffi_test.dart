import 'dart:io';

import 'package:sqflite_common_ffi/src/windows/setup.dart';
import 'package:test/test.dart';
import 'package:moor_ffi/database.dart';

void main() {
  test('moor_ffi simple test', () {
    if (Platform.isWindows) {
      windowsInit();
    }
    final database = Database.memory();
    var version = database.userVersion();
    expect(version, 0);
    database.close();
  });
}
