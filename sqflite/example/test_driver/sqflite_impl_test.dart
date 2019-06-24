import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/src/database_mixin.dart' as impl;
import 'package:sqflite/src/factory_mixin.dart' as impl;

import 'package:sqflite_example/utils.dart';
import 'package:test/test.dart';

// ignore: deprecated_member_use
class TestSqfliteOptions extends SqfliteOptions {}

@deprecated
Future devVerbose() async {
  // ignore: deprecated_member_use
  await Sqflite.devSetOptions(
      // ignore: deprecated_member_use
      SqfliteOptions()..logLevel = sqfliteLogLevelVerbose);
}

void main() {
  final factory = databaseFactory as impl.SqfliteDatabaseFactoryMixin;
  group('impl', () {
    if (Platform.isIOS || Platform.isAndroid) {
      group('debug_info', () {
        test('open null', () async {
          var info = await factory.getDebugInfo();
          expect(info.databases, isNull);
          expect(info.logLevel, isNull);
          var exception;
          try {
            await factory.openDatabase(null);
          } catch (e) {
            exception = e;
          }
          expect(exception, isNotNull);

          info = await factory.getDebugInfo();
          expect(info.databases, isNull);
        });

        // test('verbose')

        test('simple', () async {
          // await devVerbose();
          var path = 'simple.db';
          await deleteDatabase(path);

          var info = await factory.getDebugInfo();
          expect(info.databases, isNull);

          var sw = Stopwatch()..start();
          var db = await openDatabase(path) as impl.SqfliteDatabaseMixin;
          expect(db.id, greaterThan(0));
          print('Sqflite opening database: ${sw.elapsed}');
          try {
            info = await factory.getDebugInfo();
            expect(info.databases.length, 1);
            var dbInfo = info.databases.values.first;
            expect(dbInfo.singleInstance, isTrue);
            expect(dbInfo.path, join(await factory.getDatabasesPath(), path));
            // expect(dbInfo.logLevel, isNull);

            // open again
            var previousDb = db;
            var id = db.id;
            db = await openDatabase(path) as impl.SqfliteDatabaseMixin;
            expect(db.id, id);
            expect(db, previousDb);
          } finally {
            sw = Stopwatch()..start();
            await db?.close();
            print('Sqflite closing database: ${sw.elapsed}');
          }

          info = await factory.getDebugInfo();
          expect(info.databases, isNull);

          // reopen
          var id = db.id;
          sw = Stopwatch()..start();
          var db3 = await openDatabase(path) as impl.SqfliteDatabaseMixin;
          print('Sqflite opening database: ${sw.elapsed}');
          try {
            expect(db3.id, id + 1);
          } finally {
            sw = Stopwatch()..start();
            await db3?.close();
            print('Sqflite closing database: ${sw.elapsed}');

            // close again
            print('Sqflite closing again');
            await db3.close();
          }
        });

        test('logLevel', () async {
          var path = 'log_level.db';
          await deleteDatabase(path);

          // ignore: deprecated_member_use
          await Sqflite.devSetOptions(
              // ignore: deprecated_member_use
              SqfliteOptions()..logLevel = sqfliteLogLevelNone);

          var db = await openDatabase(path);
          var info = await factory.getDebugInfo();

          expect(info.databases.length, 1);
          var dbInfo = info.databases.values.first;
          expect(dbInfo.singleInstance, isTrue);
          expect(dbInfo.path, join(await factory.getDatabasesPath(), path));
          expect(dbInfo.logLevel, isNull);
          await db.close();

          // ignore: deprecated_member_use
          await Sqflite.devSetOptions(
              // ignore: deprecated_member_use
              SqfliteOptions()..logLevel = sqfliteLogLevelVerbose);
          info = await factory.getDebugInfo();
          expect(info.logLevel, sqfliteLogLevelVerbose);

          db = await openDatabase(path);
          // ignore: deprecated_member_use
          await Sqflite.devSetOptions(
              // ignore: deprecated_member_use
              SqfliteOptions()..logLevel = sqfliteLogLevelNone);

          try {
            info = await factory.getDebugInfo();
            expect(int.parse(info.databases.keys.first), isNotNull);
            // The id is a number
            expect(info.databases.length, 1);
            var dbInfo = info.databases.values.first;
            expect(dbInfo.singleInstance, isTrue);
            expect(dbInfo.path, join(await factory.getDatabasesPath(), path));
            expect(dbInfo.logLevel, sqfliteLogLevelVerbose);
          } finally {
            await db?.close();
          }

          info = await factory.getDebugInfo();
          expect(info.databases, isNull);
          expect(info.logLevel, isNull);
        });
      });
    }
  });
}
