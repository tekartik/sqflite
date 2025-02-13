import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common/sqflite.dart';

import 'src/common_import.dart';
import 'test_page.dart';

/// Open test page.
class IoTestPage extends TestPage {
  /// Open test page.
  IoTestPage({Key? key}) : super('IO tests', key: key) {
    // ignore: unused_local_variable
    final factory = databaseFactory;

    test('Delete database', () async {
      //await factory.setLogLevel(sqfliteLogLevelVerbose);
      final path = await initDeleteDb('delete_io_database.db');
      // print(path);
      Future<List<String>> findDbRelatedFiles() async {
        var dir = io.Directory(dirname(path));
        var files =
            await dir
                .list()
                .map((e) => basename(e.path))
                .where((e) => e.startsWith(basename(path)))
                .toList();
        // print('files: $files');
        return files;
      }

      expect(await findDbRelatedFiles(), isEmpty);

      var db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY)');
        },
      );
      expect(await findDbRelatedFiles(), isNotEmpty);
      await db.close();

      expect(await findDbRelatedFiles(), isNotEmpty);
      await deleteDatabase(path);
      expect(await findDbRelatedFiles(), isEmpty);

      // try wal mode
      db = await openDatabase(
        path,
        version: 1,
        onConfigure: (db) async {
          try {
            await db.execute('PRAGMA journal_mode = WAL');
          } catch (e) {
            if (kDebugMode) {
              print('Error setting WAL mode: $e');
            }
          }
        },
        onCreate: (db, version) async {
          await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY)');
        },
      );
      expect(await findDbRelatedFiles(), isNotEmpty);
      await deleteDatabase(path);
      expect(await findDbRelatedFiles(), isEmpty);
    });
  }
}
