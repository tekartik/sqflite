@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
// ignore: implementation_imports
import 'package:sqflite_common/src/internals.dart';
// ignore: implementation_imports
import 'package:sqflite_common/src/mixin/import_mixin.dart'
    show buildDatabaseFactory, SqfliteDatabaseFactory;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_example_common/exception_test_page.dart';

/// A broken implementation: the version always reads 1, a downgrade from 2
/// to 1 is never seen.
DatabaseFactory _brokenVersionFactory() {
  var ffi = databaseFactoryFfiNoIsolate as SqfliteDatabaseFactory;
  return buildDatabaseFactory(
    tag: 'broken',
    invokeMethod: (String method, [Object? arguments]) async {
      if (method == 'query' &&
          arguments is Map &&
          arguments['sql'] == 'PRAGMA user_version') {
        return <String, Object?>{
          'columns': ['user_version'],
          'rows': [
            [1],
          ],
        };
      }
      // ignore: invalid_use_of_visible_for_testing_member
      return ffi.internalsInvokeMethod<Object?>(method, arguments);
    },
  );
}

void main() {
  sqfliteFfiInit();
  late Directory dir;
  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('sqflite_example_common');
  });
  tearDownAll(() async {
    await dir.delete(recursive: true);
  });

  Future<void> runPageTest(DatabaseFactory factory, String name) async {
    databaseFactory = factory;
    await factory.setDatabasesPath(dir.path);
    var page = ExceptionTestPage();
    await page.tests.firstWhere((test) => test.name == name).fn();
  }

  test('Open onDowngrade fail', () async {
    await runPageTest(databaseFactoryFfiNoIsolate, 'Open onDowngrade fail');
    // The page test fails when the downgrade open succeeds.
    try {
      await runPageTest(_brokenVersionFactory(), 'Open onDowngrade fail');
      fail('should fail');
    } on TestFailure {
      rethrow;
    } catch (e) {
      // The page TestFailure (its own class).
      expect(e.toString(), contains('Expected'));
    }
  });
}
