import 'dart:async';
import 'dart:collection';
import 'dart:core';

import 'package:flutter/src/services/platform_channel.dart';
import 'package:sqflite/src/utils.dart';

const String channelName = 'com.tekartik.sqflite';

const MethodChannel channel = const MethodChannel(channelName);

// Temp flag to test concurrent reads
final bool supportsConcurrency = false;

// Make it async safe for dart 2.0.0-dev28+ preview dart 2
Future<T> invokeMethod<T>(String method, [dynamic arguments]) async {
  T result = await channel.invokeMethod(method, arguments);
  return result;
}

// Starting Dart preview 2, wrap the result
class Rows extends PluginList<Map<String, dynamic>> {
  Rows.from(List list) : super.from(list);

  @override
  Map<String, dynamic> operator [](int index) {
    Map item = rawList[index];
    if (item is Map<String, dynamic>) {
      return item;
    }
    return item.cast<String, dynamic>();
  }
}

Map newQueryResultSetMap(List<String> columns, List<List<dynamic>> rows) {
  Map map = {"columns": columns, "rows": rows};
  return map;
}

QueryResultSet queryResultSetFromMap(Map queryResultSetMap) {
  return new QueryResultSet(
      queryResultSetMap["columns"] as List, queryResultSetMap["rows"] as List);
}

List<Map<String, dynamic>> queryResultToList(dynamic queryResult) {
  // New 0.7.1 format
  // devPrint("queryResultToList: $queryResult");
  if (queryResult == null) {
    return null;
  }
  if (queryResult is Map) {
    return queryResultSetFromMap(queryResult);
  }
  // dart1
  if (queryResult is List<Map<String, dynamic>>) {
    return queryResult;
  }
  // dart2 support <= 0.7.0 - this is a list
  // to remove once done on iOS and Android
  Rows rows = new Rows.from(queryResult as List);
  return rows;
}

class QueryResultSet extends ListBase<Map<String, dynamic>> {
  List<List<dynamic>> _rows;
  List<String> _columns;
  Map<String, int> _columnIndexMap;

  QueryResultSet(List rawColumns, List rawRows) {
    _columns = rawColumns?.cast<String>();
    _rows = rawRows?.cast<List>();
    if (_columns != null) {
      _columnIndexMap = <String, int>{};

      for (int i = 0; i < _columns.length; i++) {
        _columnIndexMap[_columns[i]] = i;
      }
    }
  }

  @override
  int get length => _rows?.length ?? 0;

  @override
  Map<String, dynamic> operator [](int index) {
    return new QueryRow(this, _rows[index]);
  }

  @override
  void operator []=(int index, Map<String, dynamic> value) {
    throw new UnsupportedError("read-only");
  }

  @override
  set length(int newLength) {
    throw new UnsupportedError("read-only");
  }

  int columnIndex(String name) {
    return _columnIndexMap[name];
  }
}

class QueryRow extends MapBase<String, dynamic> {
  final QueryResultSet queryResultSet;
  final List row;

  QueryRow(this.queryResultSet, this.row);

  @override
  operator [](Object key) {
    int columnIndex = queryResultSet.columnIndex(key as String);
    if (columnIndex != null) {
      return row[columnIndex];
    }
    return null;
  }

  @override
  void operator []=(String key, value) {
    throw new UnsupportedError("read-only");
  }

  @override
  void clear() {
    throw new UnsupportedError("read-only");
  }

  @override
  Iterable<String> get keys => queryResultSet._columns;

  @override
  remove(Object key) {
    throw new UnsupportedError("read-only");
  }
}

class BatchResult {
  final result;

  BatchResult(this.result);
}

class BatchResults extends PluginList<dynamic> {
  BatchResults.from(List list) : super.from(list);

  @override
  dynamic operator [](int index) {
    var result = _list[index];

    // list or map, this is a result
    if (result is Map) {
      return queryResultToList(result);
    } else if (result is List) {
      return queryResultToList(result);
    }

    return result;
  }
}

abstract class PluginList<T> extends ListBase<T> {
  final List _list;

  PluginList.from(List list) : _list = list;

  List get rawList => _list;

  dynamic rawElementAt(int index) => _list[index];

  @override
  int get length => _list.length;

  @override
  set length(int newLength) {
    throw new UnsupportedError("read-only");
  }

  @override
  void operator []=(int index, T value) {
    throw new UnsupportedError("read-only");
  }
}
