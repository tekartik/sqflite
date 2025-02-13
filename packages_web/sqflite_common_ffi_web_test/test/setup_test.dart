@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:sqflite_common_ffi_web/src/constant.dart';
import 'package:sqflite_common_ffi_web/src/setup/setup_io.dart';
import 'package:test/test.dart';

void deleteFileSync(String path) {
  try {
    File(path).deleteSync();
  } catch (_) {}
}

var expectedSharedWorkerJsFiled =
    'sqflite_sw_v1.js'; // not sqfliteSharedWorkerJsFile since overriden

void main() {
  late String dir;
  void checkBuiltFilesSync({bool exists = true}) {
    expect(File(join(dir, expectedSharedWorkerJsFiled)).existsSync(), exists);
    expect(File(join(dir, sqlite3WasmFile)).existsSync(), exists);
    expect(File(join(dir, sqlite3WasmFile)).existsSync(), exists);
  }

  void deleteBuiltFilesSync() {
    deleteFileSync(join(dir, expectedSharedWorkerJsFiled));
    deleteFileSync(join(dir, sqlite3WasmFile));
    checkBuiltFilesSync(exists: false);
  }

  group('setup', () {
    test('force setup', () async {
      dir = join('.dart_tool', packageName, 'test', 'force_setup');
      deleteBuiltFilesSync();
      await setupBinaries(
        options: SqfliteWebSetupOptions(dir: dir, force: true),
      );
      checkBuiltFilesSync();
    });
    test('normal setup', () async {
      dir = join('.dart_tool', packageName, 'test', 'normal_setup');
      deleteBuiltFilesSync();
      await setupBinaries(options: SqfliteWebSetupOptions(dir: dir));
      checkBuiltFilesSync();
    });
    test('bin setup', () async {
      dir = join('.dart_tool', packageName, 'test', 'bin_setup');
      deleteBuiltFilesSync();
      await run(
        'dart run sqflite_common_ffi_web:setup --verbose --dir ${shellArgument(dir)}',
      );
      checkBuiltFilesSync();
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
