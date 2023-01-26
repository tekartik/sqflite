import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:test/test.dart';

void main() {
  test('activate and run', () async {
    var shell = Shell();
    await shell.run('''
        dart pub global activate -s path . --overwrite  
        ''');
    var tmpPath = Directory.systemTemp.path;
    shell = shell.cd(tmpPath);
    await shell.run('''
        dart pub global run sqflite_ffi_console_test_app:sqflite_ffi_simple_bin
        ''');
  }, timeout: Timeout(Duration(seconds: 60)));
  test('compile exe and run', () async {
    var shell = Shell();
    await shell.run('''
        dart compile exe bin/sqflite_ffi_simple_bin.dart --output .dart_tool/sqflite_ffi_simple_bin.exe  
        ''');
    await shell.run('''
       .dart_tool/sqflite_ffi_simple_bin.exe
        ''');
  }, timeout: Timeout(Duration(seconds: 60)));
}
