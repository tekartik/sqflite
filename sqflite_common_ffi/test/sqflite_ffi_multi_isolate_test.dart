@TestOn('vm')
library;

import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:test/test.dart';

/// Without a port server, each isolate using [createDatabaseFactoryFfi] runs
/// its own sqflite isolate. A database opened from one isolate must keep
/// working when another isolate opens a database, while it runs and after it
/// ends.
///
/// The problem only shows with a SQLite library that has shared cache (a
/// custom build or `source: system`). The library bundled by package:sqlite3
/// is built with SQLITE_OMIT_SHARED_CACHE, so these tests are skipped with it.
///
/// On Linux, the easy way to run them is `source: system` in the pubspec hooks
/// (the distribution libsqlite3 has shared cache):
///
/// ```yaml
/// hooks:
///   user_defines:
///     sqlite3:
///       source: system
/// ```
///
/// On Windows, to run them with a custom library, use `source: process` and
/// set SQFLITE_TEST_SQLITE3_LIBRARY to the library to load. This only works on
/// Windows: on Linux and macOS `DynamicLibrary.open` loads the library with
/// local symbols, so the process lookup does not find them.
void main() {
  var library = Platform.environment['SQFLITE_TEST_SQLITE3_LIBRARY'];
  if (library != null) {
    library = absolute(library);
    // Its dependencies may sit next to it, Windows looks for them in the
    // current directory.
    var previous = Directory.current;
    Directory.current = dirname(library);
    try {
      DynamicLibrary.open(library);
    } finally {
      Directory.current = previous;
    }
  }
  var sharedCache = !sqlite3.sqlite3
      .openInMemory()
      .select('PRAGMA compile_options')
      .any((row) => row.columnAt(0) == 'OMIT_SHARED_CACHE');
  var skip = sharedCache
      ? null
      : 'the SQLite library is built without shared cache';

  late String dir;

  setUp(() async {
    dir = (await Directory.systemTemp.createTemp(
      'sqflite_multi_isolate_',
    )).path;
  });

  tearDown(() async {
    // A connection left open in another isolate keeps its file in use.
    try {
      await Directory(dir).delete(recursive: true);
    } catch (_) {}
  });

  Future<int> count(Database db) async =>
      (await db.rawQuery('SELECT COUNT(*) AS c FROM t')).first['c'] as int;

  Future<Database> open(String path) =>
      createDatabaseFactoryFfi().openDatabase(path);

  for (var closeInOther in [true, false]) {
    test(
      'another isolate opening the same database '
      '(${closeInOther ? 'closing it' : 'not closing it'}) '
      'leaves this connection open',
      skip: skip,
      () async {
        var path = join(dir, 'shared.db');
        var db = await open(path);
        await db.execute('CREATE TABLE t (v INTEGER)');
        await db.insert('t', {'v': 1});

        await Isolate.run(() async {
          var other = await open(path);
          await other.insert('t', {'v': 2});
          if (closeInOther) {
            await other.close();
          }
        });

        await db.insert('t', {'v': 3});
        expect(await count(db), 3);
        await db.close();
      },
    );
  }

  test(
    'another isolate opening a different database leaves this one open',
    skip: skip,
    () async {
      var db = await open(join(dir, 'a.db'));
      await db.execute('CREATE TABLE t (v INTEGER)');
      await db.insert('t', {'v': 1});

      var otherPath = join(dir, 'b.db');
      await Isolate.run(() async {
        var other = await open(otherPath);
        await other.execute('CREATE TABLE t (v INTEGER)');
        await other.close();
      });

      await db.insert('t', {'v': 2});
      expect(await count(db), 2);
      await db.close();
    },
  );

  test(
    'isolates writing the same database at the same time lose nothing',
    skip: skip,
    () async {
      var path = join(dir, 'shared.db');
      var db = await open(path);
      await db.execute('PRAGMA busy_timeout = 5000');
      await db.execute('CREATE TABLE t (v INTEGER)');

      var others = [
        for (var n = 0; n < 3; n++)
          Isolate.run(() async {
            var other = await open(path);
            await other.execute('PRAGMA busy_timeout = 5000');
            for (var i = 0; i < 50; i++) {
              await other.insert('t', {'v': n * 1000 + i});
            }
            await other.close();
          }),
      ];
      for (var i = 0; i < 50; i++) {
        await db.insert('t', {'v': -i});
      }
      await Future.wait(others);

      expect(await count(db), 200);
      await db.close();
    },
  );
}
