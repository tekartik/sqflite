@TestOn('vm')
library;

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
