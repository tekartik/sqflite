import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/logger/sqflite_logger.dart';
import 'package:sqflite_common_test/sqflite_protocol_test.dart';
import 'package:sqflite_common_test/src/test_scenario.dart';
import 'package:test/test.dart';

extension SqfliteLoggerEventTestExt on SqfliteLoggerEvent {
  Map<String, Object?> toMap() {
    return (this as SqfliteLoggerEventView).toMap();
  }

  Map<String, Object?> toMapNoSw() {
    return (this as SqfliteLoggerEventView).toMap()..remove('sw');
  }
}

extension SqfliteLoggerEventListTestExt on List<SqfliteLoggerEvent> {
  List<Map<String, Object?>> toMapList() => map((e) => e.toMap()).toList();

  List<Map<String, Object?>> toMapListNoSw() =>
      map((e) => e.toMapNoSw()).toList();
}

void main() {
  group('sqflite_logger', () {
    test('invoke', () async {
      final delegate = createMockFactoryFromData(transactionScenarioData);

      var events = <SqfliteLoggerEvent>[];
      final factory = SqfliteDatabaseFactoryLogger(delegate,
          options: SqfliteLoggerOptions(
              type: SqfliteDatabaseFactoryLoggerType.invoke,
              log: (event) {
                print(event);
                events.add(event);
              }));
      await runProtocolTransactionSteps(factory);
      expect(events.toMapListNoSw(), [
        {
          'method': 'openDatabase',
          'arguments': {'path': ':memory:', 'singleInstance': true},
          'result': {'id': 1}
        },
        {
          'method': 'execute',
          'arguments': {
            'sql': 'BEGIN IMMEDIATE',
            'id': 1,
            'transactionId': null,
            'inTransaction': true
          },
          'result': {'transactionId': 1}
        },
        {
          'method': 'execute',
          'arguments': {
            'sql': 'COMMIT',
            'id': 1,
            'transactionId': 1,
            'inTransaction': false
          }
        },
        {
          'method': 'closeDatabase',
          'arguments': {'id': 1}
        },
      ]);
    });
    test('all', () async {
      final delegate = createMockFactoryFromData(transactionScenarioData);

      var events = <SqfliteLoggerEvent>[];
      var lines = <String>[];
      final factory = SqfliteDatabaseFactoryLogger(delegate,
          options: SqfliteLoggerOptions(
              type: SqfliteDatabaseFactoryLoggerType.all,
              log: (event) {
                event.dump(
                    print: (line) {
                      lines.add(line?.toString() ?? '<null>');
                      print(line);
                    },
                    noStopwatch: true);
                print(event);
                events.add(event);
              }));
      await runProtocolTransactionSteps(factory);
      expect(
          events.toMapListNoSw(),
          [
            {
              'path': ':memory:',
              'options': {'readOnly': false, 'singleInstance': true},
              'id': 1
            },
            {
              'db': 1,
              'sql': 'BEGIN IMMEDIATE',
              'result': {'transactionId': 1}
            },
            {'db': 1, 'txn': 1, 'sql': 'COMMIT'},
            {'db': 1}
          ],
          reason: '$events');
      expect(lines, [
        'openDatabase:({path: :memory:, options: {readOnly: false, singleInstance: true}})',
        'execute:({db: 1, sql: BEGIN IMMEDIATE, result: {transactionId: 1}})',
        'execute:({db: 1, txn: 1, sql: COMMIT})',
        'closeDatabase:({db: 1})'
      ]);
    });
    var events = <SqfliteLoggerEvent>[];
    late SqfliteDatabaseFactoryLogger factory;
    void initFactoryAll(DatabaseFactory delegate) {
      events.clear();
      factory = SqfliteDatabaseFactoryLogger(delegate,
          options: SqfliteLoggerOptions(
              type: SqfliteDatabaseFactoryLoggerType.all,
              log: (event) {
                print(event);
                events.add(event);
              }));
    }

    test('allOnCreate', () async {
      final delegate =
          createMockFactoryFromData(transactionOnCreateScenarioData);
      initFactoryAll(delegate);

      await runProtocolTransactionOnCreateSteps(factory);
      expect(
          events.toMapListNoSw(),
          [
            {
              'path': ':memory:',
              'options': {
                'version': 1,
                'readOnly': false,
                'singleInstance': true
              },
              'id': 1
            },
            {
              'db': 1,
              'sql': 'PRAGMA user_version',
              'result': [
                {'user_version': 0}
              ]
            },
            {
              'db': 1,
              'sql': 'BEGIN EXCLUSIVE',
              'result': {'transactionId': 1}
            },
            {
              'db': 1,
              'txn': 1,
              'sql': 'PRAGMA user_version',
              'result': [
                {'user_version': 0}
              ]
            },
            {'db': 1, 'txn': 1, 'sql': 'PRAGMA user_version = 1'},
            {'db': 1, 'txn': 1, 'sql': 'COMMIT'},
            {'db': 1}
          ],
          reason: '$events');
    });
  });
}
