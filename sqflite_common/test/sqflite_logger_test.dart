import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/internals.dart';
import 'package:sqflite_common/src/logger/sqflite_logger.dart';
import 'package:test/test.dart';

import 'src_mixin_test.dart';

void main() {
  group('sqflite_logger', () {
    test('invoke', () async {
      var events = <SqfliteLoggerEvent>[];
      final factory = SqfliteDatabaseFactoryLogger(MockDatabaseFactoryEmpty(),
          options: SqfliteLoggerOptions(
              type: SqfliteDatabaseFactoryLoggerType.invoke,
              log: (event) {
                print(event);
                events.add(event);
              }));
      await factory.internalsInvokeMethod<Object?>('test', {'some': 'param'});
      var event = events.first as SqfliteLoggerInvokeEvent;
      expect(event.method, 'test');
      expect(event.arguments, {'some': 'param'});
      expect(event.sw!.isRunning, isFalse);
    });
    test('all', () async {
      var events = <SqfliteLoggerEvent>[];
      final factory = SqfliteDatabaseFactoryLogger(MockDatabaseFactoryEmpty(),
          options: SqfliteLoggerOptions(
              type: SqfliteDatabaseFactoryLoggerType.all,
              log: (event) {
                print(event);
                events.add(event);
              }));
      await factory.openDatabase(inMemoryDatabasePath);

      var event = events.first as SqfliteLoggerDatabaseOpenEvent;
      expect(event.path, inMemoryDatabasePath);
      expect(event.options, isNull);
      expect(event.sw!.isRunning, isFalse);
    });
  });
}
