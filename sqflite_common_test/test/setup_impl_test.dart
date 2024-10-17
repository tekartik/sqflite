@TestOn('vm')
library;

import 'dart:io';

import 'package:sqflite_common_ffi/windows/sqflite_ffi_setup.dart';
import 'package:test/test.dart';

void main() {
  group('setup', () {
    test('findWindowsDllPath', () {
      expect(File(findWindowsSqlite3DllPath()!).existsSync(), isTrue);
    });
  });
}
