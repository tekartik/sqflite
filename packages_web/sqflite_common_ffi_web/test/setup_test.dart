@TestOn('vm')
import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:sqflite_common_ffi_web/src/constant.dart';
import 'package:sqflite_common_ffi_web/src/setup/setup.dart';
import 'package:test/test.dart';

void deleteFileSync(String path) {
  try {
    File(path).deleteSync();
  } catch (_) {}
}

void main() {
  late String dir;
  void checkBuiltFilesSync({bool exists = true}) {
    expect(File(join(dir, sqfliteSharedWorkerJsFile)).existsSync(), exists);
    expect(File(join(dir, sqlite3WasmFile)).existsSync(), exists);
  }

  void deleteBuiltFilesSync() {
    deleteFileSync(join(dir, sqfliteSharedWorkerJsFile));
    deleteFileSync(join(dir, sqlite3WasmFile));
    checkBuiltFilesSync(exists: false);
  }

  group('setup', () {
    test('setup', () async {
      dir = join('.dart_tool', packageName, 'test', 'bin_setup');
      deleteBuiltFilesSync();
      await run(
          'dart run sqflite_common_ffi_web:setup --verbose --dir ${shellArgument(dir)}');
      checkBuiltFilesSync();
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
