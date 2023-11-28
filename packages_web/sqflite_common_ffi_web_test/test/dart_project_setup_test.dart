// ignore_for_file: avoid_print

@TestOn('vm')
import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:test/test.dart';

void ensureEmptyDirSync(String path) {
  try {
    Directory(path).deleteSync(recursive: true);
  } catch (_) {}
  try {
    Directory(path).createSync(recursive: true);
  } catch (_) {}
}

void main() {
  group('dart project', () {
    test('full dart setup', () async {
      var path = join('.dart_tool', 'sqflite_common_ffi_web_test', 'test',
          'dart_project_setup');
      ensureEmptyDirSync(path);
      var shell = Shell(workingDirectory: path);
      await shell.run('dart create . --force --no-pub');
      await shell.run('dart pub add sqflite_common_ffi_web');
      await shell.run('dart run sqflite_common_ffi_web:setup');
      var sw = Stopwatch()..start();
      print('elapsed: ${sw.elapsed}');
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
