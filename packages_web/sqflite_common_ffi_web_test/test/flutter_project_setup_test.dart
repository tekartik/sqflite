// ignore_for_file: avoid_print

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:test/test.dart';

import 'dart_project_setup_test.dart';

void main() {
  group('flutter project', () {
    test('full flutter setup', () async {
      var path = join('.dart_tool', 'sqflite_common_ffi_web_test', 'test',
          'flutter_project_setup');
      ensureEmptyDirSync(path);
      var shell = Shell(workingDirectory: path);
      await shell.run('flutter create . --platforms web --no-pub');
      await shell.run('flutter pub add sqflite_common_ffi_web');
      await shell.run('dart run sqflite_common_ffi_web:setup');
      var sw = Stopwatch()..start();
      print('elapsed: ${sw.elapsed}');
    });
  },
      skip: !isFlutterSupportedSync,
      timeout: const Timeout(Duration(minutes: 5)));
}
