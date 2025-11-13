import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:test/test.dart';

void main() {
  test('run directly', () async {
    var shell = Shell();
    var bin = normalize(absolute(join('bin', 'sqflite_ffi_simple_bin.dart')));
    // Try running from a different path
    var tmpPath = Directory.systemTemp.path;
    shell = shell.cd(tmpPath);
    await shell.run('''
        dart run ${shellArgument(bin)}
        ''');
  }, timeout: Timeout(Duration(seconds: 60)));
  test('activate and run', () async {
    var shell = Shell();
    await shell.run('''
        dart pub global activate -s path . --overwrite  
        ''');
    var tmpPath = Directory.systemTemp.path;
    shell = shell.cd(tmpPath);
    // This is failing on CI on dart 3.10.0. Are build hooks ran properly
    await shell.run('''
        dart pub global run sqflite_ffi_console_test_app:sqflite_ffi_simple_bin
        ''');
  }, timeout: Timeout(Duration(seconds: 60)));
  test('compile exe and run', () async {
    var shell = Shell();
    await shell.run('''
        dart build cli bin/sqflite_ffi_simple_bin.dart --output .local/sqflite_ffi_simple_bin  
        ''');
    await shell.run('''
       .local/sqflite_ffi_simple_bin/bundle/bin/sqflite_ffi_simple_bin
        ''');
  }, timeout: Timeout(Duration(seconds: 60)));
}
