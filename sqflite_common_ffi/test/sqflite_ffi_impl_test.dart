import 'dart:io';

import 'package:test/test.dart';
import 'package:sqflite_common_ffi/src/windows/setup.dart';

void main() {
  group('sqflite_ffi_impl', () {
    test('toFilePath', () {
      if (Platform.isWindows) {
        expect(
            toFilePath('dummy',
                'file:///C:/opt/app/flutter/beta/flutter/.pub-cache/git/sqflite_more-f89bc2b3f92fa35b7c027c8862d3a7eb35128600/sqflite_common_ffi/lib/'),
            'C:\\opt\\app\\flutter\\beta\\flutter\\.pub-cache\\git\\sqflite_more-f89bc2b3f92fa35b7c027c8862d3a7eb35128600\\sqflite_common_ffi\\lib\\');
        expect(toFilePath('dummy', 'lib/'), 'dummy\\lib\\');
      }
    });
  });
}
