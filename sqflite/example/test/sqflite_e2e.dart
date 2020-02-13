// Copyright 2019, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:e2e/e2e.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
// import 'sqflite_impl_test.dart' show devVerbose;

void main() {
  E2EWidgetsFlutterBinding.ensureInitialized();

  group('sqflite', () {
    group('open', () {
      test('missing directory', () async {
        //await devVerbose();
        var path = join('test_missing_sub_dir', 'simple.db');
        try {
          await Directory(join(await getDatabasesPath(), dirname(path)))
              .delete(recursive: true);
        } catch (_) {}
        var db =
            await openDatabase(path, version: 1, onCreate: (db, version) async {
          expect(await db.getVersion(), 0);
        });
        expect(await db.getVersion(), 1);
        await db.close();
      });
      test('failure', () {
        // This one seems ignored
        // fail('regular test failure');
      });
      test('in_memory', () async {
        var db = await openDatabase(inMemoryDatabasePath, version: 1,
            onCreate: (db, version) async {
          expect(await db.getVersion(), 0);
        });
        expect(await db.getVersion(), 1);
        await db.close();
      });
    });
  });

  testWidgets('widget_test', (WidgetTester tester) async {
    //await devVerbose();
    var path = join('widget_test_missing_sub_dir', 'simple.db');
    try {
      await Directory(join(await getDatabasesPath(), dirname(path)))
          .delete(recursive: true);
    } catch (_) {}
    var db =
        await openDatabase(path, version: 1, onCreate: (db, version) async {
      expect(await db.getVersion(), 0);
    });
    expect(await db.getVersion(), 1);
    await db.close();
  });
  testWidgets('widget_test_failure', (WidgetTester tester) async {
    // This fails
    // fail('widget test_failure');
  });
}
