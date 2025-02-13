import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_example_common/test_page.dart';

// ignore_for_file: avoid_print

/// Raw test page.
class PluginTestPage extends TestPage {
  /// Raw test page.
  PluginTestPage({Key? key}) : super('Plugin tests', key: key) {
    final factory = databaseFactory;

    if (Platform.isIOS) {
      test('darwinCreateUnprotectedFolder', () async {
        print('darwinCreateUnprotectedFolder');
        var parent = join(
          await factory.getDatabasesPath(),
          'darwinUnprotectedParent',
        );
        var unprotected = 'unprotected';

        if (Directory(parent).existsSync()) {
          await Directory(parent).delete(recursive: true);
        }
        var unprotectedPath = join(parent, unprotected);
        expect(Directory(unprotectedPath).existsSync(), isFalse);
        await SqfliteDarwin.createUnprotectedFolder(parent, unprotected);
        expect(Directory(unprotectedPath).existsSync(), isTrue);

        // Doc

        /// Default location for database (or use path_provider)
        var databasesPath = await factory.getDatabasesPath();

        late String dir;

        /// If you want to allow opening the db while your device is locked
        /// (push notification, background fetch) create an unprotected folder
        /// where the db will be created.
        if (Platform.isIOS) {
          dir = join(databasesPath, 'unprotected');
          if (!Directory(dir).existsSync()) {
            await SqfliteDarwin.createUnprotectedFolder(parent, unprotected);
          }
        } else {
          // ok for other platforms
          dir = databasesPath;
        }

        var db = await factory.openDatabase(
          join(dir, 'my_database.db'),
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              // ...
            },
          ),
        );

        await db.close();
      });
    } else {
      test('-- none --', () async {});
    }
  }
}
