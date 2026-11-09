@TestOn('browser')
library;

import 'package:sqflite_common/sqlite_api.dart';
// ignore: implementation_imports
import 'package:sqflite_common/src/factory_mixin.dart'
    show SqfliteDatabaseFactoryMixin;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:test/test.dart';

void main() {
  test('fixPath', () async {
    // No sqlite3.wasm needed: the path is resolved before any call.
    for (var factory in [
      databaseFactoryFfiWeb,
      databaseFactoryFfiWebNoWebWorker,
    ]) {
      var mixin = factory as SqfliteDatabaseFactoryMixin;
      // One database for all these spellings, the file sqlite opens.
      for (var path in ['x.db', './x.db', '/x.db', '/dir/../x.db']) {
        expect(await mixin.fixPath(path), '/x.db', reason: path);
      }
      expect(await mixin.fixPath('dir/x.db'), '/dir/x.db');
      expect(await mixin.fixPath(inMemoryDatabasePath), inMemoryDatabasePath);
      expect(await mixin.fixPath('file::memory:'), inMemoryDatabasePath);
      expect(await mixin.fixPath('file:x.db'), 'file:x.db');
    }
  });
}
