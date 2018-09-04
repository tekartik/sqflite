import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/src/sqflite_impl.dart';

void main() {
  group("sqflite", () {
    const MethodChannel channel = const MethodChannel('com.tekartik.sqflite');

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
      var raw = <dynamic>[
        <dynamic, dynamic>{'col': 1}
      ];
      var rows = new Rows.from(raw);
      var row = rows.first;
      expect(rows, raw);
      expect(row, {"col": 1});
    });

    test('ResultSet', () {
      var raw = {
        "columns": ["column"],
        "rows": [
          [1]
        ]
      };
      var queryResultSet = new QueryResultSet(<dynamic>[
        "column"
      ], <dynamic>[
        [1]
      ]);
      expect(queryResultSet.columnIndex("dummy"), isNull);
      expect(queryResultSet.columnIndex("column"), 0);
      var row = queryResultSet.first;
      //expect(rows, raw);
      expect(row, {"column": 1});

      var queryResultSetMap = {
        "columns": ["id", "name"],
        "rows": [
          [1, "item 1"],
          [2, "item 2"]
        ]
      };
      var expected = [
        {'id': 1, 'name': 'item 1'},
        {'id': 2, 'name': 'item 2'}
      ];
      expect(queryResultToList(queryResultSetMap), expected);
      expect(queryResultToList(expected), expected);
      expect(queryResultToList(raw), [
        {'column': 1}
      ]);

      expect(queryResultToList(<String, dynamic>{}), <dynamic>[]);
    });

    test('lockWarning', () {});
  });
}
