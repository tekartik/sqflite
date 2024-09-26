@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/src/windows/setup.dart';
import 'package:test/test.dart';

void main() {
  group('sqflite_ffi_impl', () {
    test('findPackagePath', () {
      // Find our path
      var path = findPackageLibPath(Directory.current.path)!;
      // print(path);

      expect(Directory(path).existsSync(), isTrue);
      expect(File(packageGetSqlite3DllPath(path)).existsSync(), isTrue);
    });
    test('dummy path findPackageLibPath', () {
      // bad location
      expect(findPackageLibPath(join(Directory.current.path, 'test')), null);
      // dummy location
      expect(findPackageLibPath(join(Directory.current.path, '.dummy')), null);
    });
    test('findWindowsDllPath', () {
      expect(File(findWindowsDllPath()!).existsSync(), isTrue);
    });
  });
}
