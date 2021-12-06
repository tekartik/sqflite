@TestOn('vm')
library sqflite_common_ffi.test.setup_impl_test;

import 'dart:io';

import 'package:sqflite_common_ffi/src/windows/setup.dart';
import 'package:test/test.dart';

void main() {
  group('setup', () {
    test('findWindowsDllPath', () {
      expect(File(findWindowsDllPath()!).existsSync(), isTrue);
    });
  });
}
