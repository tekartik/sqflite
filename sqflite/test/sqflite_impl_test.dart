import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/src/exception.dart';
import 'package:sqflite/src/factory_impl.dart';
import 'package:sqflite/src/mixin/factory.dart';
import 'package:sqflite/src/sqflite_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('sqflite', () {
    const MethodChannel channel = MethodChannel('com.tekartik.sqflite');

    final List<MethodCall> log = <MethodCall>[];
    String response;

    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
      return response;
    });

    tearDown(() {
      log.clear();
    });

    test('databaseFactory', () async {
      expect(databaseFactory is SqfliteInvokeHandler, isTrue);
    });

    test('supportsConcurrency', () async {
      expect(supportsConcurrency, isFalse);
    });

    test('Rows', () {
      final List<dynamic> raw = <dynamic>[
        <dynamic, dynamic>{'col': 1}
      ];
      final Rows rows = Rows.from(raw);
      final Map<String, dynamic> row = rows.first;
      expect(rows, raw);
      expect(row, <String, dynamic>{'col': 1});
    });

    test('fromRawOperationResult', () async {
      expect(fromRawOperationResult(<String, dynamic>{'result': 1}), 1);
      expect(
          fromRawOperationResult(<String, dynamic>{
            'result': <dynamic, dynamic>{
              'columns': <dynamic>['column'],
              'rows': <dynamic>[
                <int>[1]
              ]
            }
          }),
          <Map<String, dynamic>>[
            <String, dynamic>{'column': 1}
          ]);
      final SqfliteDatabaseException exception =
          fromRawOperationResult(<dynamic, dynamic>{
        'error': <dynamic, dynamic>{
          'code': 1234,
          'message': 'hello',
          'data': <dynamic, dynamic>{'some': 'data'}
        }
      }) as SqfliteDatabaseException;
      expect(exception.message, 'hello');
      expect(exception.result, <dynamic, dynamic>{'some': 'data'});
    });
    test('ResultSet', () {
      final Map<dynamic, dynamic> raw = <dynamic, dynamic>{
        'columns': <dynamic>['column'],
        'rows': <dynamic>[
          <int>[1]
        ]
      };
      final QueryResultSet queryResultSet = QueryResultSet(<dynamic>[
        'column'
      ], <dynamic>[
        <dynamic>[1]
      ]);
      expect(queryResultSet.columnIndex('dummy'), isNull);
      expect(queryResultSet.columnIndex('column'), 0);
      final Map<String, dynamic> row = queryResultSet.first;
      //expect(rows, raw);
      expect(row, <String, dynamic>{'column': 1});

      // read only
      try {
        row['column'] = 2;
        fail('should have failed');
      } on UnsupportedError catch (_) {}
      final Map<String, dynamic> map = Map<String, dynamic>.from(row);
      // now can modify
      map['column'] = 2;

      final Map<dynamic, dynamic> queryResultSetMap = <dynamic, dynamic>{
        'columns': <dynamic>['id', 'name'],
        'rows': <List<dynamic>>[
          <dynamic>[1, 'item 1'],
          <dynamic>[2, 'item 2']
        ]
      };
      final List<Map<String, dynamic>> expected = <Map<String, dynamic>>[
        <String, dynamic>{'id': 1, 'name': 'item 1'},
        <String, dynamic>{'id': 2, 'name': 'item 2'}
      ];
      expect(queryResultToList(queryResultSetMap), expected);
      expect(queryResultToList(expected), expected);
      expect(queryResultToList(raw), <Map<String, dynamic>>[
        <String, dynamic>{'column': 1}
      ]);

      expect(queryResultToList(<String, dynamic>{}), <dynamic>[]);
    });

    test('duplicated key', () {
      final QueryResultSet queryResultSet = QueryResultSet(<dynamic>[
        'col',
        'col'
      ], <dynamic>[
        <dynamic>[1, 2]
      ]);
      // last one wins...
      expect(queryResultSet.columnIndex('col'), 1);
      final Map<String, dynamic> row = queryResultSet.first;
      expect(row['col'], 2);

      expect(row.length, 1);
      expect(row.keys, <String>['col']);
      expect(row.values, <dynamic>[2]);
      expect(row, <String, dynamic>{'col': 2});
    });

    test('lockWarning', () {});
  });
}
