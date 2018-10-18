import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/src/sqflite_impl.dart';

void main() {
  group("sqflite", () {
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

    test("supportsConcurrency", () async {
      expect(supportsConcurrency, isFalse);
    });

    test('Rows', () {
      final List<dynamic> raw = <dynamic>[
        <dynamic, dynamic>{'col': 1}
      ];
      final Rows rows = Rows.from(raw);
      final Map<String, dynamic> row = rows.first;
      expect(rows, raw);
      expect(row, <String, dynamic>{"col": 1});
    });

    test('ResultSet', () {
      final Map<dynamic, dynamic> raw = <dynamic, dynamic>{
        "columns": <dynamic>["column"],
        "rows": <dynamic>[
          <int>[1]
        ]
      };
      final QueryResultSet queryResultSet = QueryResultSet(<dynamic>[
        "column"
      ], <dynamic>[
        <dynamic>[1]
      ]);
      expect(queryResultSet.columnIndex("dummy"), isNull);
      expect(queryResultSet.columnIndex("column"), 0);
      final Map<String, dynamic> row = queryResultSet.first;
      //expect(rows, raw);
      expect(row, <String, dynamic>{"column": 1});

      final Map<dynamic, dynamic> queryResultSetMap = <dynamic, dynamic>{
        "columns": <dynamic>["id", "name"],
        "rows": <List<dynamic>>[
          <dynamic>[1, "item 1"],
          <dynamic>[2, "item 2"]
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

    test('lockWarning', () {});
  });
}
