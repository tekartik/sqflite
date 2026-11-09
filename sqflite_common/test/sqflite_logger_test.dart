import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/internals.dart';
import 'package:sqflite_common/src/logger/sqflite_logger.dart';
import 'package:test/test.dart';

import 'src_mixin_test.dart';

void main() {
  group('sqflite_logger', () {
    test('invoke', () async {
      var events = <SqfliteLoggerEvent>[];
      var lines = <String>[];
      final factory = SqfliteDatabaseFactoryLogger(
        MockDatabaseFactoryEmpty(),
        options: SqfliteLoggerOptions(
          type: SqfliteDatabaseFactoryLoggerType.invoke,
          log: (event) {
            event.dump(
              print: (msg) {
                lines.add(msg?.toString() ?? '<null>');
                // ignore: avoid_print
                print(msg);
              },
              noStopwatch: true,
            );
            events.add(event);
          },
        ),
      );
      try {
        await factory.internalsInvokeMethod<Object?>('test', {'some': 'param'});
      } catch (_) {
        // unimplemented
      }
      var event = events.first as SqfliteLoggerInvokeEvent;
      expect(event.method, 'test');
      expect(event.arguments, {'some': 'param'});
      expect(event.sw!.isRunning, isFalse);
      // is currently an error
      //  'invoke:({method: test, arguments: {some: param}, error: UnimplementedError: test {some: param}})'
      expect(
        lines.first,
        startsWith('invoke:({method: test, arguments: {some: param}'),
      );
    });
    test('all', () async {
      var events = <SqfliteLoggerEvent>[];
      var lines = <String>[];
      final factory = SqfliteDatabaseFactoryLogger(
        MockDatabaseFactoryEmpty(),
        options: SqfliteLoggerOptions(
          type: SqfliteDatabaseFactoryLoggerType.all,
          log: (event) {
            event.dump(
              print: (msg) {
                lines.add(msg?.toString() ?? '<null>');
                // ignore: avoid_print
                print(msg);
              },
              noStopwatch: true,
            );
            events.add(event);
          },
        ),
      );
      var db = await factory.openDatabase(inMemoryDatabasePath);
      var batch = db.batch();
      batch.rawQuery('PRAGMA user_version');
      await batch.commit();
      var event = events.first as SqfliteLoggerDatabaseOpenEvent;
      expect(event.path, inMemoryDatabasePath);
      expect(event.options?.readOnly, false);
      expect(event.sw!.isRunning, isFalse);
      await db.close();
      expect(lines, [
        'openDatabase:({path: :memory:, options: {readOnly: false, singleInstance: true}})',
        'execute:({db: 1, sql: BEGIN IMMEDIATE})',
        'batch:({db: 1})',
        '  query({sql: PRAGMA user_version})',
        'execute:({db: 1, sql: COMMIT})',
        'closeDatabase:({db: 1})',
      ]);
    });
    test('batch', () async {});
    test('deleteDatabase removes the single instance', () async {
      var events = <SqfliteLoggerEvent>[];
      final factory = SqfliteDatabaseFactoryLogger(
        MockDatabaseFactory(),
        options: SqfliteLoggerOptions(log: events.add),
      );
      const path = 'logger_delete_single_instance.db';
      var db1 = await factory.openDatabase(path);
      await factory.deleteDatabase(path);
      expect(
        events.whereType<SqfliteLoggerDatabaseDeleteEvent>().single.path,
        path,
      );
      // The deleted database must not be returned again
      var db2 = await factory.openDatabase(path);
      expect(db2, isNot(same(db1)));
      expect(await factory.openDatabase(path), same(db2));
      await db2.close();
    });
  });
}
