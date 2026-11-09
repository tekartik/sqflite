@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:sqflite_common_ffi_web/src/constant.dart';
import 'package:sqflite_common_ffi_web/src/setup/setup_io.dart';
import 'package:test/test.dart';

void main() {
  test('copyBinaries fetches sqlite3WasmUri', () async {
    var server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      request.response
        ..add('custom wasm'.codeUnits)
        ..close();
    });
    var dir = join('.dart_tool', packageName, 'test', 'setup_wasm_uri');
    try {
      try {
        await Directory(dir).delete(recursive: true);
      } catch (_) {}
      // A built worker, as after a build.
      await File(
        join(dir, 'build', 'sqflite_sw.dart.js'),
      ).create(recursive: true);
      var context = SetupContext(
        options: SqfliteWebSetupOptions(
          path: dir,
          sqlite3WasmUri: Uri.parse(
            'http://127.0.0.1:${server.port}/custom.wasm',
          ),
        ),
        ffiWebPath: dir,
        version: Version(1, 0, 0),
        overridenSwJsFile: null,
      );
      await context.copyBinaries();
      expect(
        await File(join(dir, 'web', sqlite3WasmFile)).readAsString(),
        'custom wasm',
      );
      expect(
        File(join(dir, 'web', sqfliteSharedWorkerJsFile)).existsSync(),
        isTrue,
      );
    } finally {
      await server.close(force: true);
    }
  });
}
