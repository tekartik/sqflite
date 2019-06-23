import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/src/factory_impl.dart';
import 'package:sqflite_example/utils.dart';
import 'package:test/test.dart';

// ignore: deprecated_member_use
class TestSqfliteOptions extends SqfliteOptions {}

void main() {
  final factory = sqlfliteDatabaseFactory as SqfliteDatabaseFactoryImpl;
  group('impl', () {
    if (Platform.isAndroid) {
      group('android_debug_info', () {
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

        test('simple', () async {
          var path = 'simple.db';
          await deleteDatabase(path);

          var info = await factory.getDebugInfo();
          expect(info.databases, isNull);

          var db = await openDatabase(path);
          try {
            info = await factory.getDebugInfo();
            expect(info.databases.length, 1);
            var dbInfo = info.databases.values.first;
            expect(dbInfo.singleInstance, isTrue);
            expect(dbInfo.path, join(await factory.getDatabasesPath(), path));
            expect(dbInfo.logLevel, isNull);
          } finally {
            await db?.close();
          }

          info = await factory.getDebugInfo();
          expect(info.databases, isNull);
        });

        test('logLevel', () async {
          var path = 'log_level.db';
          await deleteDatabase(path);

          // ignore: deprecated_member_use
          await Sqflite.devSetOptions(
              // ignore: deprecated_member_use
              SqfliteOptions()..logLevel = sqfliteLogLevelVerbose);
          var info = await factory.getDebugInfo();
          expect(info.logLevel, sqfliteLogLevelVerbose);

          var db = await openDatabase(path);
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
